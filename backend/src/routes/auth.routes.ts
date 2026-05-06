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
    const {
      nome_exibicao,
      email,
      password,
      perfil,
      cpf,
      curso,
      instituicao,
      url_curriculo,
      skills,
      endereco,
      logradouro,
      cep,
      numero,
      bairro,
      cidade,
      estado,
      latitude,
      longitude,
    } = req.body;

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
      const cepLimpo = typeof cep === "string" ? cep.replace(/[^0-9]/g, "") : undefined;
      const estadoNormalizado = typeof estado === "string" ? estado.trim().toUpperCase().substring(0, 2) : undefined;

      const aluno = alunoRepository.create({
        id: usuarioSalvo.id,
        cpf: typeof cpf === "string" ? cpf.replace(/[^0-9]/g, "") : undefined,
        curso: typeof curso === "string" ? curso : undefined,
        instituicao: typeof instituicao === "string" ? instituicao : undefined,
        url_curriculo: typeof url_curriculo === "string" ? url_curriculo : undefined,
        skills: Array.isArray(skills) ? JSON.stringify(skills) : (typeof skills === "string" ? skills : undefined),
        endereco: typeof endereco === "string" ? endereco : undefined,
        logradouro: typeof logradouro === "string" ? logradouro : undefined,
        cep: cepLimpo && cepLimpo.length > 0 ? cepLimpo : undefined,
        numero: typeof numero === "string" ? numero : undefined,
        bairro: typeof bairro === "string" ? bairro : undefined,
        cidade: typeof cidade === "string" ? cidade : undefined,
        estado: estadoNormalizado && estadoNormalizado.length > 0 ? estadoNormalizado : undefined,
        latitude: typeof latitude === "number" ? latitude : undefined,
        longitude: typeof longitude === "number" ? longitude : undefined,
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
    const { cpf, password } = req.body;

    if (!cpf || !password) {
      return res.status(400).json({
        message: "Campos obrigatórios faltando: CPF e senha",
      });
    }

    // Limpar CPF/CNPJ (apenas números)
    const cpfLimpo = cpf.replace(/[^0-9]/g, "");

    if (cpfLimpo.length === 0) {
      return res.status(400).json({
        message: "CPF/CNPJ inválido",
      });
    }

    const usuarioRepository = AppDataSource.getRepository(Usuario);
    const alunoRepository = AppDataSource.getRepository(Aluno);
    const empresaRepository = AppDataSource.getRepository(Empresa);

    console.log(`🔍 Buscando login para CPF/CNPJ: ${cpfLimpo}`);

    // Tentar buscar como Aluno
    let aluno = await alunoRepository.findOne({
      where: { cpf: cpfLimpo },
    });

    // Tentar buscar como Empresa se não encontrar Aluno
    let empresa = null;
    let usuarioId = null;

    if (aluno) {
      usuarioId = aluno.id;
      console.log(`✅ Aluno encontrado: ${usuarioId}`);
    } else {
      empresa = await empresaRepository.findOne({
        where: { cnpj: cpfLimpo },
      });
      if (empresa) {
        usuarioId = empresa.id;
        console.log(`✅ Empresa encontrada: ${usuarioId}`);
      }
    }

    if (!usuarioId) {
      console.log(`❌ CPF/CNPJ não encontrado: ${cpfLimpo}`);
      return res.status(401).json({
        message: "CPF/CNPJ ou senha inválidos",
      });
    }

    // Buscar o usuario
    const usuario = await usuarioRepository
      .createQueryBuilder("usuario")
      .addSelect("usuario.senha_hash")
      .where("usuario.id = :id", { id: usuarioId })
      .getOne();

    if (!usuario) {
      console.log(`❌ Usuário não encontrado para ID: ${usuarioId}`);
      return res.status(401).json({
        message: "CPF/CNPJ ou senha inválidos",
      });
    }

    const senhaCorreta = await bcrypt.compare(password, usuario.senha_hash);

    if (!senhaCorreta) {
      console.log(`❌ Senha incorreta para usuário: ${usuario.id}`);
      return res.status(401).json({
        message: "CPF/CNPJ ou senha inválidos",
      });
    }

    console.log(`✅ Autenticação bem-sucedida para: ${usuario.email}`);

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