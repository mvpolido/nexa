import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Usuario, UsuarioPerfil } from "../entities/Usuario";
import bcrypt from "bcrypt";
import * as nodemailer from "nodemailer";

function usuarioSeguro(usuario: Usuario) {
  const {
    senha_hash: _senhaHash,
    token_recuperacao: _tokenRecuperacao,
    expiracao_token_recuperacao: _expiracaoTokenRecuperacao,
    ...seguro
  } = usuario as any;

  return seguro;
}

function getSmtpConfig() {
  const required = [
    "SMTP_HOST",
    "SMTP_PORT",
    "SMTP_SECURE",
    "SMTP_USER",
    "SMTP_PASS",
    "SMTP_FROM",
  ];
  const missing = required.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    return { missing, config: null };
  }

  return {
    missing,
    config: {
      host: process.env.SMTP_HOST!,
      port: Number(process.env.SMTP_PORT),
      secure: process.env.SMTP_SECURE === "true",
      auth: {
        user: process.env.SMTP_USER!,
        pass: process.env.SMTP_PASS!,
      },
      from: process.env.SMTP_FROM!,
    },
  };
}

export class UserController {
  // 1. ROTA PÚBLICA: Cadastro de Alunos e Empresas (Bloqueado para Admin)
  static async create(req: Request, res: Response): Promise<Response> {
    const { nome_exibicao, email, senha, perfil } = req.body;
    const userRepository = AppDataSource.getRepository(Usuario);

    if (!nome_exibicao || !email || !senha || !perfil) {
      return res.status(400).json({ message: "Campos obrigatórios faltando" });
    }

    // Regra de Segurança: Impede que usuários comuns se cadastrem como ADMIN
    if (perfil === UsuarioPerfil.ADMIN) {
      return res.status(403).json({ 
        message: "Não é permitido criar um usuário Administrador por esta rota." 
      });
    }

    try {
      const userExists = await userRepository.findOneBy({ email });
      if (userExists) {
        return res.status(400).json({ message: "E-mail já cadastrado" });
      }

      const hashedPassword = await bcrypt.hash(senha, 10);
      
      const newUser = userRepository.create({
        nome_exibicao,
        email,
        senha_hash: hashedPassword, 
        perfil,
      });

      await userRepository.save(newUser);
      
      return res.status(201).json(usuarioSeguro(newUser));
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao criar usuário", error: error.message });
    }
  }

  // 2. ROTA PRIVADA: Criação de novos Administradores (Apenas Admins logados podem acessar)
  static async createAdmin(req: Request, res: Response): Promise<Response> {
    const { nome_exibicao, email, senha } = req.body;
    const userRepository = AppDataSource.getRepository(Usuario);

    if (!nome_exibicao || !email || !senha) {
      return res.status(400).json({ message: "Nome, email e senha são obrigatórios." });
    }

    try {
      const userExists = await userRepository.findOneBy({ email });
      if (userExists) {
        return res.status(400).json({ message: "E-mail já cadastrado" });
      }

      const hashedPassword = await bcrypt.hash(senha, 10);
      
      const newAdmin = userRepository.create({
        nome_exibicao,
        email,
        senha_hash: hashedPassword, 
        perfil: UsuarioPerfil.ADMIN, // Força o perfil a ser ADMIN
      });

      await userRepository.save(newAdmin);
      
      return res.status(201).json({
        message: "Novo administrador criado com sucesso!",
        user: usuarioSeguro(newAdmin)
      });
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao criar administrador", error: error.message });
    }
  }

  static async getAll(req: Request, res: Response): Promise<Response> {
    try {
      const userRepository = AppDataSource.getRepository(Usuario);
      const usuarios = await userRepository.find({
        order: { criado_em: "DESC" },
      });

      return res.status(200).json(usuarios.map(usuarioSeguro));
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao listar usuários", error: error.message });
    }
  }

  static async getById(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const userRepository = AppDataSource.getRepository(Usuario);
      const usuario = await userRepository.findOneBy({ id: Number(id) });

      if (!usuario) {
        return res.status(404).json({ message: "Usuário não encontrado" });
      }

      return res.status(200).json(usuarioSeguro(usuario));
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao buscar usuário", error: error.message });
    }
  }

  static async update(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const { nome_exibicao, email } = req.body;
      const userRepository = AppDataSource.getRepository(Usuario);

      const usuario = await userRepository.findOneBy({ id: Number(id) });
      if (!usuario) {
        return res.status(404).json({ message: "Usuário não encontrado" });
      }

      if (email && email !== usuario.email) {
        const emailEmUso = await userRepository.findOneBy({ email });
        if (emailEmUso && emailEmUso.id !== usuario.id) {
          return res.status(409).json({ message: "E-mail já cadastrado" });
        }
        usuario.email = email;
      }

      if (nome_exibicao) {
        usuario.nome_exibicao = nome_exibicao;
      }

      const usuarioAtualizado = await userRepository.save(usuario);
      return res.status(200).json(usuarioSeguro(usuarioAtualizado));
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao atualizar usuário", error: error.message });
    }
  }

  static async delete(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const userRepository = AppDataSource.getRepository(Usuario);
      const usuario = await userRepository.findOneBy({ id: Number(id) });

      if (!usuario) {
        return res.status(404).json({ message: "Usuário não encontrado" });
      }

      await userRepository.remove(usuario);

      return res.status(200).json({ message: "Usuário removido com sucesso" });
    } catch (error: any) {
      return res.status(500).json({ message: "Erro ao remover usuário", error: error.message });
    }
  }
  // --- ROTAS DE RECUPERAÇÃO DE SENHA --- //

  static async forgotPassword(req: Request, res: Response): Promise<Response> {
    const { email } = req.body;
    const userRepository = AppDataSource.getRepository(Usuario);

    try {
      const usuario = await userRepository.findOneBy({ email });

      // Retorna a mesma mensagem sempre para não expor quais emails existem (Segurança contra enumeração)
      if (!usuario) {
        return res.status(200).json({ message: "Se o e-mail estiver cadastrado, um código será enviado." });
      }

      const smtp = getSmtpConfig();
      if (!smtp.config) {
        console.error(
          `Configuração SMTP ausente para recuperação de senha. Variáveis faltando: ${smtp.missing.join(", ")}`
        );
        return res.status(500).json({
          message: "Serviço de recuperação de senha indisponível no momento.",
        });
      }

      // Gera código de 6 dígitos
      const token = Math.floor(100000 + Math.random() * 900000).toString();

      // Expira em 1 hora
      const expiracao = new Date();
      expiracao.setHours(expiracao.getHours() + 1);

      usuario.token_recuperacao = token;
      usuario.expiracao_token_recuperacao = expiracao;
      await userRepository.save(usuario);

      const transporter = nodemailer.createTransport({
        host: smtp.config.host,
        port: smtp.config.port,
        secure: smtp.config.secure,
        auth: smtp.config.auth,
      });

      await transporter.sendMail({
        from: smtp.config.from,
        to: usuario.email,
        subject: "Recuperação de Senha - Nexa",
        text: `Seu código de recuperação é: ${token}. Ele expira em 1 hora.`,
        html: `<p>Olá, ${usuario.nome_exibicao}!</p>
               <p>Seu código de recuperação é: <b>${token}</b></p>
               <p>Ele expira em 1 hora. Se você não solicitou a recuperação, ignore este e-mail.</p>`,
      });

      return res.status(200).json({ message: "Se o e-mail estiver cadastrado, um código será enviado." });
    } catch (error: any) {
      console.error("Erro na recuperação de senha:", error?.message || error);
      return res.status(500).json({ message: "Erro interno no servidor" });
    }
  }
  static async resetPassword(req: Request, res: Response): Promise<Response> {
    const { email, token, novaSenha } = req.body;
    const userRepository = AppDataSource.getRepository(Usuario);

    try {
      const usuario = await userRepository
        .createQueryBuilder("usuario")
        .addSelect("usuario.token_recuperacao")
        .addSelect("usuario.expiracao_token_recuperacao")
        .where("usuario.email = :email", { email })
        .getOne();

      // 1. Verifica se o usuário existe
      if (!usuario) {
        return res.status(400).json({ message: "Usuário não encontrado ou e-mail incorreto." });
      }

      // 2. Verifica se o token bate com o que está no banco
      if (usuario.token_recuperacao !== token) {
        return res.status(400).json({ message: "Código de recuperação inválido." });
      }

      // 3. Verifica se o token não passou da validade (1 hora)
      const agora = new Date();
      if (usuario.expiracao_token_recuperacao && agora > usuario.expiracao_token_recuperacao) {
        return res.status(400).json({ message: "Este código expirou. Solicite um novo." });
      }

      // 4. Se passou em todos os testes, criptografa a nova senha
      const hashedPassword = await bcrypt.hash(novaSenha, 10);

      // 5. Atualiza a senha no banco e "limpa" os tokens para não serem usados novamente
      usuario.senha_hash = hashedPassword;
      usuario.token_recuperacao = null as any; 
      usuario.expiracao_token_recuperacao = null as any;

      await userRepository.save(usuario);

      return res.status(200).json({ message: "Senha atualizada com sucesso!" });
    } catch (error: any) {
      console.error("Erro ao redefinir senha:", error?.message || error);
      return res.status(500).json({ message: "Erro interno no servidor" });
    }
  }
}
