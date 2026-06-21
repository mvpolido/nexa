import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Usuario, UsuarioPerfil } from "../entities/Usuario";
import bcrypt from "bcrypt";

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
      
      const { senha_hash: _, ...usuarioSemSenha } = newUser;
      return res.status(201).json(usuarioSemSenha);
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
      
      const { senha_hash: _, ...usuarioSemSenha } = newAdmin;
      return res.status(201).json({
        message: "Novo administrador criado com sucesso!",
        user: usuarioSemSenha
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

      return res.status(200).json(usuarios);
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

      return res.status(200).json(usuario);
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
      return res.status(200).json(usuarioAtualizado);
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
}