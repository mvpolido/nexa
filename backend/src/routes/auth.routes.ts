import jwt from "jsonwebtoken";
import { Router } from "express";
import bcrypt from "bcrypt";
import { AppDataSource } from "../data-source";
import { Usuario, UsuarioPerfil } from "../entities/Usuario";
import { Aluno } from "../entities/Aluno";
import { Empresa } from "../entities/Empresa";

const router = Router();

router.post("/register", async (req, res) => {
  try {
    // 1. Alterado de 'password' para 'senha' para bater com o Swagger
    const { nome_exibicao, email, senha, perfil } = req.body;

    // 2. Verificação atualizada para 'senha'
    if (!nome_exibicao || !email || !senha || !perfil) {
      return res.status(400).json({
        message: "Campos obrigatórios faltando",
      });
    }

    if (perfil !== UsuarioPerfil.ALUNO && perfil !== UsuarioPerfil.EMPRESA) {
      return res.status(400).json({
        message: "Perfil inválido",
      });
    }

    const usuarioRepository = AppDataSource.getRepository(Usuario);
    const alunoRepository = AppDataSource.getRepository(Aluno);
    const empresaRepository = AppDataSource.getRepository(Empresa);

    const usuarioExistente = await usuarioRepository.findOne({
      where: { email },
    });

    if (usuarioExistente) {
      return res.status(409).json({
        message: "Email já cadastrado",
      });
    }

    // 3. Hash feito sobre a variável 'senha'
    const senhaHash = await bcrypt.hash(senha, 10);

    const novoUsuario = usuarioRepository.create({
      nome_exibicao,
      email,
      senha_hash: senhaHash,
      perfil,
    });

    const usuarioSalvo = await usuarioRepository.save(novoUsuario);

    if (perfil === UsuarioPerfil.ALUNO) {
      const aluno = alunoRepository.create({
        id: usuarioSalvo.id,
      });
      await alunoRepository.save(aluno);
    }

    if (perfil === UsuarioPerfil.EMPRESA) {
      const empresa = empresaRepository.create({
        id: usuarioSalvo.id,
      });
      await empresaRepository.save(empresa);
    }

    return res.status(201).json({
      id: usuarioSalvo.id,
      nome_exibicao: usuarioSalvo.nome_exibicao,
      email: usuarioSalvo.email,
      perfil: usuarioSalvo.perfil,
      criado_em: usuarioSalvo.criado_em,
      atualizado_em: usuarioSalvo.atualizado_em,
    });
  } catch (error: any) {
    return res.status(500).json({
      message: "Erro interno no servidor",
      error: error.message,
    });
  }
});

router.post("/login", async (req, res) => {
  try {
    // 4. Alterado de 'password' para 'senha' aqui também
    const { email, senha } = req.body;

    if (!email || !senha) {
      return res.status(400).json({
        message: "Campos obrigatórios faltando",
      });
    }

    const usuarioRepository = AppDataSource.getRepository(Usuario);

    const usuario = await usuarioRepository
      .createQueryBuilder("usuario")
      .addSelect("usuario.senha_hash")
      .where("usuario.email = :email", { email })
      .getOne();

    if (!usuario) {
      return res.status(401).json({
        message: "Credenciais inválidas",
      });
    }

    // 5. Comparação usando a variável 'senha'
    const senhaCorreta = await bcrypt.compare(senha, usuario.senha_hash);

    if (!senhaCorreta) {
      return res.status(401).json({
        message: "Credenciais inválidas",
      });
    }

    const token = jwt.sign(
      {
        userId: usuario.id,
        perfil: usuario.perfil,
      },
      process.env.JWT_SECRET || "default_secret",
      { expiresIn: "1d" }
    );

    return res.status(200).json({
      token: token,
      user: {
        id: usuario.id,
        nome_exibicao: usuario.nome_exibicao,
        email: usuario.email,
        perfil: usuario.perfil,
      },
    });
  } catch (error: any) {
    return res.status(500).json({
      message: "Erro interno no servidor",
      error: error.message,
    });
  }
});

export default router;