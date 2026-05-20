import jwt from "jsonwebtoken";
import { Router } from "express";
import bcrypt from "bcrypt";
import { cpf as cpfValidator, cnpj as cnpjValidator } from "cpf-cnpj-validator";
import { AppDataSource } from "../data-source";
import { Usuario, UsuarioPerfil } from "../entities/Usuario";
import { Aluno } from "../entities/Aluno";
import { Empresa } from "../entities/Empresa";

const router = Router();

function onlyNumbers(value: string | undefined): string {
  return (value || "").replace(/\D/g, "");
}

router.post("/register", async (req, res) => {
  try {
    const {
      nome_exibicao,
      email,
      perfil,
      cpf,
      cnpj,
      curso,
      descricao,
      latitude,
      longitude,
      instituicao,
      ano_conclusao,
      cep,
      endereco,
      numero,
      url_curriculo
    } = req.body;

    const senha = req.body.senha ?? req.body.password;

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

    const cpfLimpo = onlyNumbers(cpf);
    const cnpjLimpo = onlyNumbers(cnpj);

    if (perfil === UsuarioPerfil.ALUNO) {
      if (!cpfLimpo) {
        return res.status(400).json({
          message: "CPF é obrigatório para cadastro de aluno",
        });
      }

      if (!cpfValidator.isValid(cpfLimpo)) {
        return res.status(400).json({
          message: "CPF inválido",
        });
      }

      const alunoComCpf = await alunoRepository.findOne({
        where: { cpf: cpfLimpo },
      });

      if (alunoComCpf) {
        return res.status(409).json({
          message: "CPF já cadastrado",
        });
      }
    }

    if (perfil === UsuarioPerfil.EMPRESA) {
      if (!cnpjLimpo) {
        return res.status(400).json({
          message: "CNPJ é obrigatório para cadastro de empresa",
        });
      }

      if (!cnpjValidator.isValid(cnpjLimpo)) {
        return res.status(400).json({
          message: "CNPJ inválido",
        });
      }

      const empresaComCnpj = await empresaRepository.findOne({
        where: { cnpj: cnpjLimpo },
      });

      if (empresaComCnpj) {
        return res.status(409).json({
          message: "CNPJ já cadastrado",
        });
      }
    }

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
        cpf: cpfLimpo,
        curso: curso || null,
        instituicao: instituicao || null,
        ano_conclusao: ano_conclusao || null,
        cep: cep || null,
        endereco: endereco || null,
        numero: numero || null,
        latitude: latitude ?? null,
        longitude: longitude ?? null,
        url_curriculo: url_curriculo || null
      });

      await alunoRepository.save(aluno);
    }

    if (perfil === UsuarioPerfil.EMPRESA) {
      const empresa = empresaRepository.create({
        id: usuarioSalvo.id,
        cnpj: cnpjLimpo,
        descricao: descricao || null,
        latitude: latitude ?? null,
        longitude: longitude ?? null,
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
    const { email } = req.body;
    const senha = req.body.senha ?? req.body.password;

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

    const senhaCorreta = await bcrypt.compare(senha, usuario.senha_hash);

    if (!senhaCorreta) {
      return res.status(401).json({
        message: "Credenciais inválidas",
      });
    }

    const secret = process.env.JWT_SECRET || "sua_chave_secreta_aqui";

    const token = jwt.sign(
      {
        id: usuario.id,
        userId: usuario.id,
        perfil: usuario.perfil,
      },
      secret,
      { expiresIn: "1d" }
    );

    return res.status(200).json({
      token,
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