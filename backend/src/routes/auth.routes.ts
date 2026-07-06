import jwt from "jsonwebtoken";
import { Router } from "express";
import bcrypt from "bcrypt";
import { cpf as cpfValidator, cnpj as cnpjValidator } from "cpf-cnpj-validator";
import { AppDataSource } from "../data-source";
import { Usuario, UsuarioPerfil } from "../entities/Usuario";
import { Aluno } from "../entities/Aluno";
import { AlunoHabilidade } from "../entities/AlunoHabilidade";
import { Empresa } from "../entities/Empresa";
import { Habilidade } from "../entities/Habilidade";
import { uploadConfig } from "../config/multer";
import { geocodificarEndereco } from "../utils/geocoding";
import { calcularDistanciaKm, coordenadasValidas } from "../utils/distance";
import {
  mensagemAnoConclusaoInvalido,
  parseAnoConclusao,
} from "../utils/anoConclusao";
import { getJwtSecret } from "../utils/jwtSecret";
import { catalogoAtivoExiste } from "../controllers/CatalogoController";

const router = Router();

function onlyNumbers(value: string | undefined): string {
  return (value || "").replace(/\D/g, "");
}

function alertarCoordenadasEnviadasSuspeitas(
  origem: string,
  latitudeEnviada: unknown,
  longitudeEnviada: unknown,
  latitudeConfirmada: number,
  longitudeConfirmada: number
) {
  if (!coordenadasValidas(latitudeEnviada, longitudeEnviada)) return;

  const diferencaKm = calcularDistanciaKm(
    latitudeEnviada,
    longitudeEnviada,
    latitudeConfirmada,
    longitudeConfirmada
  );

  if (diferencaKm !== null && diferencaKm > 5) {
    console.warn(
      `${origem}: coordenadas enviadas pelo cliente divergem da geocodificação em ${diferencaKm.toFixed(
        1
      )} km. Valor enviado ignorado.`
    );
  }
}

function parseIdArrayField(value: any): { ids: number[]; invalid: boolean } {
  if (value === undefined || value === null || value === "") {
    return { ids: [], invalid: false };
  }

  let parsed = value;
  if (typeof value === "string") {
    try {
      parsed = JSON.parse(value);
    } catch {
      return { ids: [], invalid: true };
    }
  }

  if (!Array.isArray(parsed)) {
    return { ids: [], invalid: true };
  }

  const ids: number[] = [];
  for (const item of parsed) {
    if (
      (typeof item !== "number" && typeof item !== "string") ||
      !/^\d+$/.test(String(item).trim())
    ) {
      return { ids: [], invalid: true };
    }

    const id = Number(item);
    if (!Number.isInteger(id) || id <= 0) {
      return { ids: [], invalid: true };
    }
    ids.push(id);
  }

  return { ids: Array.from(new Set(ids)), invalid: false };
}

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
      habilidadeIds,
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

      if (!(await catalogoAtivoExiste("curso", cursoNormalizado))) {
        return res.status(400).json({
          message: "Curso inválido. Selecione uma opção da lista.",
        });
      }

      if (!(await catalogoAtivoExiste("instituicao", instituicaoNormalizada))) {
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

      const anoConclusaoValidado = parseAnoConclusao(ano_conclusao);
      if (anoConclusaoValidado === null) {
        return res.status(400).json({
          message: mensagemAnoConclusaoInvalido(),
        });
      }

      const habilidadeIdsParsed = parseIdArrayField(habilidadeIds);
      if (habilidadeIdsParsed.invalid) {
        return res.status(400).json({
          message: "O campo habilidadeIds deve ser um array JSON de IDs inteiros positivos.",
        });
      }

      if (habilidadeIdsParsed.ids.length > 0) {
        const habilidadesEncontradas = await habilidadeRepository
          .createQueryBuilder("habilidade")
          .where("habilidade.id IN (:...ids)", { ids: habilidadeIdsParsed.ids })
          .getMany();

        if (habilidadesEncontradas.length !== habilidadeIdsParsed.ids.length) {
          return res.status(400).json({
            message: "Uma ou mais habilidades informadas não existem.",
          });
        }
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
    let usuarioSalvo: Usuario;

    if (perfil === UsuarioPerfil.ALUNO) {
      const coordenadasAluno = await geocodificarEndereco({
        cep: cepLimpo,
        endereco,
        numero,
      });
      const latitudeAluno = coordenadasAluno?.latitude;
      const longitudeAluno = coordenadasAluno?.longitude;

      if (!coordenadasValidas(latitudeAluno, longitudeAluno)) {
        return res.status(422).json({
          message:
            "Não foi possível localizar o endereço do aluno. Confira CEP, endereço e número.",
        });
      }

      alertarCoordenadasEnviadasSuspeitas(
        "Cadastro de aluno",
        latitude,
        longitude,
        Number(latitudeAluno),
        Number(longitudeAluno)
      );

      const anoConclusaoValidado = parseAnoConclusao(ano_conclusao);
      const habilidadeIdsUnicos = parseIdArrayField(habilidadeIds).ids;

      usuarioSalvo = await AppDataSource.transaction(async (manager) => {
        const novoUsuario = manager.create(Usuario, {
          nome_exibicao,
          email,
          senha_hash: senhaHash,
          perfil,
        });
        const usuarioCriado = await manager.save(Usuario, novoUsuario);

        const aluno = manager.create(Aluno, {
          id: usuarioCriado.id,
          cpf: cpfLimpo,
          curso: cursoNormalizado || undefined,
          instituicao: instituicaoNormalizada || undefined,
          ano_conclusao: anoConclusaoValidado || undefined,
          cep: cepLimpo || undefined,
          endereco: endereco || undefined,
          numero: numero || undefined,
          latitude: Number(latitudeAluno),
          longitude: Number(longitudeAluno),
          url_curriculo: curriculoArquivo || undefined,
        });

        await manager.save(Aluno, aluno);

        if (habilidadeIdsUnicos.length > 0) {
          await manager.save(
            AlunoHabilidade,
            habilidadeIdsUnicos.map((habilidadeId) =>
              manager.create(AlunoHabilidade, {
                aluno_id: aluno.id,
                habilidade_id: habilidadeId,
              })
            )
          );
        }

        return usuarioCriado;
      });
    } else {
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

      usuarioSalvo = await AppDataSource.transaction(async (manager) => {
        const novoUsuario = manager.create(Usuario, {
          nome_exibicao,
          email,
          senha_hash: senhaHash,
          perfil,
        });
        const usuarioCriado = await manager.save(Usuario, novoUsuario);

        const empresa = manager.create(Empresa, {
          id: usuarioCriado.id,
          cnpj: cnpjLimpo,
          descricao: descricao || undefined,
          latitude: latitudeEmpresa,
          longitude: longitudeEmpresa,
        });

        await manager.save(Empresa, empresa);
        return usuarioCriado;
      });
    }

    const token = jwt.sign(
      {
        id: usuarioSalvo.id,
        userId: usuarioSalvo.id,
        perfil: usuarioSalvo.perfil,
      },
      getJwtSecret(),
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

    const token = jwt.sign(
      {
        id: usuario.id,
        userId: usuario.id,
        perfil: usuario.perfil,
      },
      getJwtSecret(),
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
