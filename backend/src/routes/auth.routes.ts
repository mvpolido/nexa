import { Router } from "express";
import bcrypt from "bcrypt";
import { AppDataSource } from "../data-source";
import { Usuario, UsuarioPerfil } from "../entities/Usuario";
import { Aluno } from "../entities/Aluno";
import { Empresa } from "../entities/Empresa";

const router = Router();

router.post("/register", async (req, res) => {
  try {
    const { nome_exibicao, email, password, perfil } = req.body;

    if (!nome_exibicao || !email || !password || !perfil) {
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

    const senhaHash = await bcrypt.hash(password, 10);

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

router.post("/login", async (_req, res) => {
  return res.status(501).json({
    message: "Login ainda não implementado",
  });
});

export default router;