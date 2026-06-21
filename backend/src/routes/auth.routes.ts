import jwt from "jsonwebtoken";
import { Router } from "express";
import bcrypt from "bcrypt";
import { In } from "typeorm";
import { cpf as cpfValidator, cnpj as cnpjValidator } from "cpf-cnpj-validator";
import { AppDataSource } from "../data-source";
import { Usuario, UsuarioPerfil } from "../entities/Usuario";
import { Aluno } from "../entities/Aluno";
import { AlunoHabilidade } from "../entities/AlunoHabilidade";
import { Empresa } from "../entities/Empresa";
import { Habilidade } from "../entities/Habilidade";
import { uploadConfig } from "../config/multer";
import {
  coordenadasValidas,
  geocodificarEndereco,
} from "../utils/geocoding";

const router = Router();

function onlyNumbers(value: string | undefined): string {
  return (value || "").replace(/\D/g, "");
}

function parseArrayField(value: any): any[] {
  if (Array.isArray(value)) return value;
  if (typeof value !== "string" || !value.trim()) return [];

  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return value
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean);
  }
}

const CURSOS_PERMITIDOS = [
  "Administração",
  "Agronomia",
  "Análise e Desenvolvimento de Sistemas",
  "Arquitetura e Urbanismo",
  "Biomedicina",
  "Ciência da Computação",
  "Ciências Biológicas",
  "Ciências Contábeis",
  "Comunicação Social",
  "Design",
  "Design Gráfico",
  "Direito",
  "Economia",
  "Educação Física",
  "Enfermagem",
  "Engenharia Ambiental",
  "Engenharia Civil",
  "Engenharia da Computação",
  "Engenharia de Alimentos",
  "Engenharia de Controle e Automação",
  "Engenharia de Produção",
  "Engenharia de Software",
  "Engenharia Elétrica",
  "Engenharia Eletrônica",
  "Engenharia Mecânica",
  "Engenharia Química",
  "Farmácia",
  "Física",
  "Fisioterapia",
  "Gestão da Tecnologia da Informação",
  "Jornalismo",
  "Letras",
  "Logística",
  "Marketing",
  "Matemática",
  "Medicina Veterinária",
  "Nutrição",
  "Pedagogia",
  "Psicologia",
  "Publicidade e Propaganda",
  "Química",
  "Recursos Humanos",
  "Relações Internacionais",
  "Sistemas de Informação",
  "Técnico em Administração",
  "Técnico em Desenvolvimento de Sistemas",
  "Técnico em Edificações",
  "Técnico em Eletrotécnica",
  "Técnico em Informática",
  "Técnico em Mecânica",
  "Técnico em Química",
];

const INSTITUICOES_PERMITIDAS = [
  "UTFPR - Universidade Tecnológica Federal do Paraná",
  "IFPR - Instituto Federal do Paraná",
  "UFPR - Universidade Federal do Paraná",
  "UEM - Universidade Estadual de Maringá",
  "UEL - Universidade Estadual de Londrina",
  "UEPG - Universidade Estadual de Ponta Grossa",
  "UNESPAR - Universidade Estadual do Paraná",
  "UNICENTRO - Universidade Estadual do Centro-Oeste",
  "PUCPR - Pontifícia Universidade Católica do Paraná",
  "UniCesumar",
  "Uningá",
  "Unicesumar",
  "Unipar",
  "Universidade Positivo",
  "Universidade Tuiuti do Paraná",
  "FAG",
  "Univel",
  "Unioeste - Universidade Estadual do Oeste do Paraná",
  "Campo Real",
  "FAE Centro Universitário",
  "Estácio",
  "Anhanguera",
  "Unopar",
  "UniBrasil",
  "UniDomBosco",
  "SENAI",
  "SENAC",
  "Fatec",
  "ETEC",
  "IFSP - Instituto Federal de São Paulo",
  "USP - Universidade de São Paulo",
  "UNESP - Universidade Estadual Paulista",
  "UNICAMP - Universidade Estadual de Campinas",
  "UFSCar - Universidade Federal de São Carlos",
  "UFMG - Universidade Federal de Minas Gerais",
  "UFSC - Universidade Federal de Santa Catarina",
  "UFRGS - Universidade Federal do Rio Grande do Sul",
  "UFSM - Universidade Federal de Santa Maria",
];

router.post("/register", (req, res, next) => {
  uploadConfig.single("curriculo")(req, res, (error: any) => {
    if (error) {
      return res.status(400).json({
        message: error.message || "Erro ao enviar currículo.",
      });
    }

    return next();
  });
}, async (req, res) => {
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
      habilidades,
      habilidadeIds,
      skills,
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
    const habilidadeRepository = AppDataSource.getRepository(Habilidade);
    const alunoHabilidadeRepository =
      AppDataSource.getRepository(AlunoHabilidade);

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
    const cursoNormalizado = typeof curso === "string" ? curso.trim() : "";
    const instituicaoNormalizada =
      typeof instituicao === "string" ? instituicao.trim() : "";
    const cepLimpo = onlyNumbers(cep);
    const curriculoArquivo = req.file?.filename;

    if (perfil === UsuarioPerfil.ALUNO) {
      if (!cpfLimpo) {
        return res.status(400).json({
          message: "CPF é obrigatório para cadastro de aluno",
        });
      }

      if (!cpfValidator.isValid(cpfLimpo)) {
        return res.status(400).json({
          message: "CPF inválido. Confira os números informados.",
        });
      }

      if (!CURSOS_PERMITIDOS.includes(cursoNormalizado)) {
        return res.status(400).json({
          message: "Curso inválido. Selecione uma opção da lista.",
        });
      }

      if (!INSTITUICOES_PERMITIDAS.includes(instituicaoNormalizada)) {
        return res.status(400).json({
          message: "Instituição inválida. Selecione uma opção da lista.",
        });
      }

      if (!cepLimpo || cepLimpo.length !== 8) {
        return res.status(400).json({
          message: "CEP inválido. Informe os 8 dígitos.",
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
          message: "CNPJ inválido. Confira os números informados.",
        });
      }

      if (!cepLimpo || cepLimpo.length !== 8) {
        return res.status(400).json({
          message: "CEP inválido. Informe os 8 dígitos.",
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
      let latitudeAluno =
        coordenadasValidas(latitude, longitude) ? Number(latitude) : undefined;
      let longitudeAluno =
        coordenadasValidas(latitude, longitude) ? Number(longitude) : undefined;

      if (latitudeAluno === undefined || longitudeAluno === undefined) {
        const coordenadas = await geocodificarEndereco({
          cep: cepLimpo,
          endereco,
          numero,
        });
        latitudeAluno = coordenadas?.latitude;
        longitudeAluno = coordenadas?.longitude;
      }

      const aluno = alunoRepository.create({
        id: usuarioSalvo.id,
        cpf: cpfLimpo,
        curso: cursoNormalizado || undefined,
        instituicao: instituicaoNormalizada || undefined,
        ano_conclusao: ano_conclusao || undefined,
        cep: cepLimpo || undefined,
        endereco: endereco || undefined,
        numero: numero || undefined,
        latitude: latitudeAluno,
        longitude: longitudeAluno,
        url_curriculo: curriculoArquivo || undefined,
      });

      await alunoRepository.save(aluno);

      const habilidadesRecebidas = [
        ...parseArrayField(habilidadeIds),
        ...parseArrayField(habilidades),
        ...parseArrayField(skills),
      ];
      const idsRecebidos = habilidadesRecebidas
        .map((item) => Number(item))
        .filter((item) => Number.isInteger(item) && item > 0);
      const nomesRecebidos = habilidadesRecebidas
        .filter((item) => typeof item === "string" && Number.isNaN(Number(item)))
        .map((item) => item.trim())
        .filter(Boolean);

      const habilidadesPorId = idsRecebidos.length
        ? await habilidadeRepository.find({ where: { id: In(idsRecebidos) } })
        : [];
      const habilidadesPorNome = nomesRecebidos.length
        ? await habilidadeRepository.find({ where: { nome: In(nomesRecebidos) } })
        : [];
      const habilidadeIdsUnicos = Array.from(
        new Set(
          [...habilidadesPorId, ...habilidadesPorNome].map(
            (habilidade) => habilidade.id
          )
        )
      );

      if (habilidadeIdsUnicos.length > 0) {
        await alunoHabilidadeRepository.save(
          habilidadeIdsUnicos.map((habilidadeId) =>
            alunoHabilidadeRepository.create({
              aluno_id: aluno.id,
              habilidade_id: habilidadeId,
            })
          )
        );
      }
    }

    if (perfil === UsuarioPerfil.EMPRESA) {
      let latitudeEmpresa =
        coordenadasValidas(latitude, longitude) ? Number(latitude) : undefined;
      let longitudeEmpresa =
        coordenadasValidas(latitude, longitude) ? Number(longitude) : undefined;

      if (latitudeEmpresa === undefined || longitudeEmpresa === undefined) {
        const coordenadas = await geocodificarEndereco({
          cep: cepLimpo,
          endereco,
          numero,
        });
        latitudeEmpresa = coordenadas?.latitude;
        longitudeEmpresa = coordenadas?.longitude;
      }

      const empresa = empresaRepository.create({
        id: usuarioSalvo.id,
        cnpj: cnpjLimpo,
        descricao: descricao || undefined,
        latitude: latitudeEmpresa,
        longitude: longitudeEmpresa,
      });

      await empresaRepository.save(empresa);
    }

    const secret = process.env.JWT_SECRET || "sua_chave_secreta_aqui";
    const token = jwt.sign(
      {
        id: usuarioSalvo.id,
        userId: usuarioSalvo.id,
        perfil: usuarioSalvo.perfil,
      },
      secret,
      { expiresIn: "1d" }
    );

    return res.status(201).json({
      token,
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
