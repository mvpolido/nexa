import { Request, Response } from "express";
import { In } from "typeorm";
import { AppDataSource } from "../data-source";
import { Aluno } from "../entities/Aluno";
import { Vaga, VagaModalidade } from "../entities/Vaga";
import { Empresa } from "../entities/Empresa";
import { Usuario, UsuarioPerfil } from "../entities/Usuario";
import { Habilidade } from "../entities/Habilidade";
import { VagaHabilidade } from "../entities/VagaHabilidade";
import { Notificacao } from "../entities/Notificacao";
import { calcularMatchPercent } from "../services/matchService";
import { geocodificarEndereco } from "../utils/geocoding";

export class VagaController {
  private static textoPreenchido(value: unknown) {
    return typeof value === "string" && value.trim().length > 0;
  }

  private static normalizarTextoOpcional(value: unknown) {
    return typeof value === "string" && value.trim().length > 0
      ? value.trim()
      : undefined;
  }

  private static normalizarTextoBusca(value: unknown) {
    return String(value ?? "")
      .trim()
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/\s+/g, " ");
  }

  private static normalizarCoordenadaOpcional(value: unknown) {
    if (value === undefined) return undefined;
    if (value === null || value === "") return undefined;

    const numero = Number(value);
    return Number.isFinite(numero) ? numero : NaN;
  }

  private static normalizarListaCursos(value: unknown) {
    if (value === undefined) return undefined;
    if (value === null || value === "") return null;

    let lista: unknown = value;

    if (typeof value === "string") {
      const texto = value.trim();
      if (!texto) return null;

      try {
        const parsed = JSON.parse(texto);
        lista = Array.isArray(parsed) ? parsed : texto.split(",");
      } catch {
        lista = texto.split(",");
      }
    }

    if (!Array.isArray(lista)) {
      throw new Error("cursos_destinados deve ser uma lista de cursos.");
    }

    const cursos = new Map<string, string>();

    for (const item of lista) {
      if (typeof item !== "string") {
        throw new Error("cursos_destinados deve ser uma lista de cursos.");
      }

      const curso = item.trim();
      if (!curso) continue;
      cursos.set(VagaController.normalizarTextoBusca(curso), curso);
    }

    return Array.from(cursos.values());
  }

  private static normalizarAnoConclusao(value: unknown) {
    if (value === undefined) return undefined;
    if (value === null || value === "") return null;

    const ano = Number(value);

    if (!Number.isInteger(ano) || ano < 2020 || ano > 2035) {
      throw new Error("Ano de conclusão deve ser um inteiro entre 2020 e 2035.");
    }

    return ano;
  }

  private static validarIntervaloConclusao(
    min?: number | null,
    max?: number | null
  ) {
    if (min !== undefined && max !== undefined && min !== null && max !== null && min > max) {
      throw new Error("Ano de conclusão mínimo não pode ser maior que o máximo.");
    }
  }

  private static bodyTemCampo(body: Record<string, unknown>, ...campos: string[]) {
    return campos.some((campo) => Object.prototype.hasOwnProperty.call(body, campo));
  }

  private static obterCampoBody(
    body: Record<string, unknown>,
    snakeCase: string,
    camelCase: string
  ) {
    if (Object.prototype.hasOwnProperty.call(body, snakeCase)) {
      return body[snakeCase];
    }

    return body[camelCase];
  }

  private static erroValidacaoVaga(message: string) {
    return (
      message.includes("cursos_destinados") ||
      message.includes("Ano de conclusão")
    );
  }

  private static coordenadasValidas(latitude: unknown, longitude: unknown) {
    if (
      latitude === null ||
      latitude === undefined ||
      longitude === null ||
      longitude === undefined ||
      latitude === "" ||
      longitude === ""
    ) {
      return false;
    }

    const lat = Number(latitude);
    const lng = Number(longitude);

    return (
      Number.isFinite(lat) &&
      Number.isFinite(lng) &&
      !(lat === 0 && lng === 0) &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180
    );
  }

  private static coordenadasForamInformadas(latitude: unknown, longitude: unknown) {
    return latitude !== undefined || longitude !== undefined;
  }

  private static enderecoMinimoPreenchido(dados: {
    cep?: unknown;
    endereco?: unknown;
    cidade?: unknown;
    estado?: unknown;
  }) {
    const cep = typeof dados.cep === "string" ? dados.cep.replace(/\D/g, "") : "";

    return (
      cep.length === 8 &&
      VagaController.textoPreenchido(dados.endereco) &&
      VagaController.textoPreenchido(dados.cidade) &&
      VagaController.textoPreenchido(dados.estado)
    );
  }

  private static calcularDistanciaKm(
    origemLat?: unknown,
    origemLng?: unknown,
    destinoLat?: unknown,
    destinoLng?: unknown
  ) {
    if (!VagaController.coordenadasValidas(origemLat, origemLng)) return null;
    if (!VagaController.coordenadasValidas(destinoLat, destinoLng)) return null;

    const lat1 = Number(origemLat);
    const lng1 = Number(origemLng);
    const lat2 = Number(destinoLat);
    const lng2 = Number(destinoLng);
    const toRad = (value: number) => (value * Math.PI) / 180;
    const raioTerraKm = 6371;

    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);

    return raioTerraKm * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
  }

  private static validarLocalizacaoVaga(dados: {
    modalidade: VagaModalidade;
    cep?: unknown;
    endereco?: unknown;
    cidade?: unknown;
    estado?: unknown;
    latitude?: unknown;
    longitude?: unknown;
  }) {
    if (dados.modalidade === VagaModalidade.REMOTO) return null;

    if (VagaController.enderecoMinimoPreenchido(dados)) return null;

    return "Informe CEP válido, endereço, cidade e estado para vagas presenciais ou híbridas.";
  }

  private static async sincronizarHabilidadesDaVaga(
    vagaId: number,
    habilidadeIds: number[]
  ) {
    const habilidadeRepository = AppDataSource.getRepository(Habilidade);
    const vagaHabilidadeRepository = AppDataSource.getRepository(VagaHabilidade);

    const ids = habilidadeIds
      .map((id) => Number(id))
      .filter((id) => Number.isInteger(id) && id > 0);

    const habilidades = ids.length
      ? await habilidadeRepository.find({
          where: { id: In(ids) },
        })
      : [];

    if (habilidades.length !== ids.length) {
      throw new Error("Uma ou mais habilidades informadas não existem.");
    }

    await vagaHabilidadeRepository.delete({
      vaga_id: vagaId,
    });

    if (ids.length > 0) {
      const novasRelacoes = ids.map((habilidadeId) =>
        vagaHabilidadeRepository.create({
          vaga_id: vagaId,
          habilidade_id: habilidadeId,
        })
      );

      await vagaHabilidadeRepository.save(novasRelacoes);
    }

    return habilidades;
  }

  private static async buscarVagaCompleta(vagaId: number) {
    const vagaRepository = AppDataSource.getRepository(Vaga);

    return vagaRepository.findOne({
      where: { id: vagaId },
      relations: [
        "empresa",
        "empresa.usuario",
        "vagaHabilidades",
        "vagaHabilidades.habilidade",
      ],
    });
  }

  static async create(req: Request, res: Response) {
    try {
      const {
        titulo,
        descricao,
        requisitos,
        modalidade,
        cep,
        endereco,
        numero,
        cidade,
        estado,
        latitude,
        longitude,
        habilidadeIds,
      } = req.body;

      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({
          message: "Apenas empresas podem publicar vagas.",
        });
      }

      if (!titulo || !descricao || !modalidade) {
        return res.status(400).json({
          message: "Título, descrição e modalidade são obrigatórios.",
        });
      }

      if (!Object.values(VagaModalidade).includes(modalidade)) {
        return res.status(400).json({
          message: "Modalidade inválida.",
        });
      }

      const latitudeNormalizada =
        VagaController.normalizarCoordenadaOpcional(latitude);
      const longitudeNormalizada =
        VagaController.normalizarCoordenadaOpcional(longitude);

      if (
        Number.isNaN(latitudeNormalizada) ||
        Number.isNaN(longitudeNormalizada)
      ) {
        return res.status(400).json({
          message: "Latitude e longitude devem ser coordenadas válidas.",
        });
      }

      if (
        VagaController.coordenadasForamInformadas(
          latitudeNormalizada,
          longitudeNormalizada
        ) &&
        !VagaController.coordenadasValidas(
          latitudeNormalizada,
          longitudeNormalizada
        )
      ) {
        return res.status(400).json({
          message: "Latitude e longitude devem ser coordenadas válidas.",
        });
      }

      const erroLocalizacao = VagaController.validarLocalizacaoVaga({
        modalidade,
        cep,
        endereco,
        cidade,
        estado,
        latitude: latitudeNormalizada,
        longitude: longitudeNormalizada,
      });

      if (erroLocalizacao) {
        return res.status(400).json({ message: erroLocalizacao });
      }

      let latitudeFinal = latitudeNormalizada;
      let longitudeFinal = longitudeNormalizada;

      if (
        !VagaController.coordenadasForamInformadas(
          latitudeNormalizada,
          longitudeNormalizada
        )
      ) {
        const coordenadas = await geocodificarEndereco({
          cep,
          endereco,
          numero,
          cidade,
          estado,
        });

        latitudeFinal = coordenadas?.latitude;
        longitudeFinal = coordenadas?.longitude;
      }

      if (habilidadeIds !== undefined && !Array.isArray(habilidadeIds)) {
        return res.status(400).json({
          message: "O campo habilidadeIds deve ser um array.",
        });
      }

      const cursosNormalizados = VagaController.normalizarListaCursos(
        VagaController.obterCampoBody(
          req.body,
          "cursos_destinados",
          "cursosDestinados"
        )
      );
      const anoConclusaoMin = VagaController.normalizarAnoConclusao(
        VagaController.obterCampoBody(
          req.body,
          "ano_conclusao_min",
          "anoConclusaoMin"
        )
      );
      const anoConclusaoMax = VagaController.normalizarAnoConclusao(
        VagaController.obterCampoBody(
          req.body,
          "ano_conclusao_max",
          "anoConclusaoMax"
        )
      );

      VagaController.validarIntervaloConclusao(
        anoConclusaoMin,
        anoConclusaoMax
      );

      const empresaRepository = AppDataSource.getRepository(Empresa);

      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } }, // Busca a empresa que PERTENCE a esse usuário
        relations: ["usuario"],
      });

      if (!empresa) {
        return res.status(404).json({
          message: "Perfil de empresa não encontrado para este usuário.",
        });
      }

      const vagaRepository = AppDataSource.getRepository(Vaga);

      const novaVaga = vagaRepository.create({
        empresa_id: empresa.id,
        titulo,
        descricao,
        requisitos: requisitos || null,
        modalidade,
        cep: VagaController.normalizarTextoOpcional(cep),
        endereco: VagaController.normalizarTextoOpcional(endereco),
        numero: VagaController.normalizarTextoOpcional(numero),
        cidade: VagaController.normalizarTextoOpcional(cidade),
        estado: VagaController.normalizarTextoOpcional(estado),
        latitude: latitudeFinal,
        longitude: longitudeFinal,
        habilidades: [],
        cursos_destinados:
          cursosNormalizados && cursosNormalizados.length > 0
            ? cursosNormalizados
            : null,
        ano_conclusao_min: anoConclusaoMin ?? null,
        ano_conclusao_max: anoConclusaoMax ?? null,
        ativo: 1,
      });

      const vagaSalva = await vagaRepository.save(novaVaga);

      const habilidades = await VagaController.sincronizarHabilidadesDaVaga(
        vagaSalva.id,
        Array.isArray(habilidadeIds) ? habilidadeIds : []
      );

      vagaSalva.habilidades = habilidades.map((habilidade) => habilidade.nome);
      await vagaRepository.save(vagaSalva);

      const vagaCompleta = await VagaController.buscarVagaCompleta(vagaSalva.id);

      try {
        const usuarioRepository = AppDataSource.getRepository(Usuario);
        const notificacaoRepository = AppDataSource.getRepository(Notificacao);
        const alunos = await usuarioRepository.find({
          where: { perfil: UsuarioPerfil.ALUNO },
        });
        const nomeEmpresa = empresa.usuario?.nome_exibicao;
        const mensagem = nomeEmpresa
          ? `A empresa ${nomeEmpresa} publicou a vaga "${vagaSalva.titulo}".`
          : `Uma nova vaga foi publicada: "${vagaSalva.titulo}".`;
        const notificacoes = alunos.map((aluno) =>
          notificacaoRepository.create({
            usuario_id: aluno.id,
            tipo: "NOVA_VAGA",
            titulo: "Nova vaga publicada",
            mensagem,
            link_id: vagaSalva.id,
          })
        );

        if (notificacoes.length > 0) {
          await notificacaoRepository.save(notificacoes);
        }
      } catch (error) {
        console.error("Erro ao criar notificações de nova vaga:", error);
      }

      return res.status(201).json(vagaCompleta);
    } catch (error: any) {
      const message = error.message || "Erro ao criar vaga.";

      if (message.includes("habilidades") || VagaController.erroValidacaoVaga(message)) {
        return res.status(400).json({ message });
      }

      return res.status(500).json({
        message: "Erro ao criar vaga.",
        error: message,
      });
    }
  }

  static async getAll(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      const vagaRepository = AppDataSource.getRepository(Vaga);
      const empresaRepository = AppDataSource.getRepository(Empresa); 
      const modalidadeQuery = req.query.modalidade?.toString();
      const distanciaKmQuery = req.query.distanciaKm?.toString();
      const cursoQuery = req.query.curso?.toString();
      const cursoNormalizado = cursoQuery
        ? VagaController.normalizarTextoBusca(cursoQuery)
        : null;
      const anoConclusaoQuery = (
        req.query.anoConclusao ?? req.query.anoConclusaoAte
      )?.toString();
      const anoConclusaoFiltro =
        anoConclusaoQuery !== undefined
          ? VagaController.normalizarAnoConclusao(anoConclusaoQuery)
          : undefined;

      if (
        modalidadeQuery &&
        !Object.values(VagaModalidade).includes(modalidadeQuery as VagaModalidade)
      ) {
        return res.status(400).json({
          message: "Modalidade inválida.",
        });
      }

      const distanciaKm =
        distanciaKmQuery !== undefined ? Number(distanciaKmQuery) : null;

      if (
        distanciaKmQuery !== undefined &&
        (distanciaKm === null || !Number.isFinite(distanciaKm) || distanciaKm < 0)
      ) {
        return res.status(400).json({
          message: "Distância inválida.",
        });
      }

      // Admin pode listar todas as vagas para moderação.
      if (perfilLogado === UsuarioPerfil.ADMIN) {
        const vagas = await vagaRepository.find({
          relations: [
            "empresa",
            "empresa.usuario",
            "vagaHabilidades",
            "vagaHabilidades.habilidade",
          ],
          order: { criado_em: "DESC" },
        });

        return res.status(200).json(vagas);
      }

      // 1. Lógica para a EMPRESA (vê apenas as próprias vagas)
      if (perfilLogado === UsuarioPerfil.EMPRESA) {
        const empresa = await empresaRepository.findOne({
          where: { usuario: { id: usuarioLogadoId } }, // Busca a empresa que PERTENCE a esse usuário
        });

        if (!empresa) {
          return res.status(404).json({ message: "Perfil de empresa não encontrado." });
        }

        const vagas = await vagaRepository.find({
          where: { empresa_id: empresa.id },
          relations: [
            "empresa",
            "empresa.usuario",
            "vagaHabilidades",
            "vagaHabilidades.habilidade",
          ],
          order: { criado_em: "DESC" },
        });

        return res.status(200).json(vagas);
      }

      // 2. Lógica para o ALUNO: carrega perfil + habilidades para calcular match
      const alunoRepository = AppDataSource.getRepository(Aluno);

      const aluno = await alunoRepository.findOne({
        where: { id: usuarioLogadoId },
        relations: ["alunoHabilidades"],
      });

      if (!aluno) {
        return res.status(404).json({ message: "Perfil de aluno não encontrado." });
      }

      const vagas = await vagaRepository.find({
        where: {
          ativo: 1,
          ...(modalidadeQuery
            ? { modalidade: modalidadeQuery as VagaModalidade }
            : {}),
        },
        relations: [
          "empresa",
          "empresa.usuario",
          "vagaHabilidades",
          "vagaHabilidades.habilidade",
        ],
      });

      const habilidadesAluno =
        aluno.alunoHabilidades?.map((ah) => ah.habilidade_id) ?? [];

      const vagasComMatch = vagas
        .map((vaga) => {
          const habilidadesVaga =
            vaga.vagaHabilidades?.map((vh) => vh.habilidade_id) ?? [];

          // Calcular habilidades em comum
          const habilidadesEmComum = habilidadesAluno.filter((h) =>
            habilidadesVaga.includes(h)
          );

          const distancia_km = VagaController.calcularDistanciaKm(
            aluno.latitude,
            aluno.longitude,
            vaga.latitude,
            vaga.longitude
          );
          const distanciaKmFormatada =
            distancia_km === null ? null : Number(distancia_km.toFixed(1));

          const match_percent = calcularMatchPercent(
            habilidadesAluno,
            habilidadesVaga,
            aluno.latitude,
            aluno.longitude,
            vaga.latitude,
            vaga.longitude
          );

          return {
            ...vaga,
            distancia_km: distanciaKmFormatada,
            match_percent,
            skills_required: habilidadesVaga.length,
            skills_matched: habilidadesEmComum.length,
          };
        })
        .filter((vaga) => {
          if (distanciaKm === null) return true;
          if (vaga.modalidade === VagaModalidade.REMOTO) return true;
          if (vaga.distancia_km === null) return false;
          const limiteDistanciaKm = distanciaKm;
          return vaga.distancia_km <= limiteDistanciaKm;
        })
        .filter((vaga) => {
          if (!cursoNormalizado) return true;

          const cursos = vaga.cursos_destinados;
          if (!Array.isArray(cursos) || cursos.length === 0) return true;

          return cursos.some(
            (curso) =>
              VagaController.normalizarTextoBusca(curso) === cursoNormalizado
          );
        })
        .filter((vaga) => {
          if (anoConclusaoFiltro === undefined || anoConclusaoFiltro === null) {
            return true;
          }

          const min = vaga.ano_conclusao_min;
          const max = vaga.ano_conclusao_max;

          return (
            (min === null || min === undefined || min <= anoConclusaoFiltro) &&
            (max === null || max === undefined || max >= anoConclusaoFiltro)
          );
        })
        .sort((a, b) => {
          if (b.match_percent !== a.match_percent) {
            return b.match_percent - a.match_percent;
          }
          return (
            new Date(b.criado_em).getTime() - new Date(a.criado_em).getTime()
          );
        });

      return res.status(200).json(vagasComMatch);
    } catch (error: any) {
      const message = error.message || "Erro ao listar vagas.";

      if (VagaController.erroValidacaoVaga(message)) {
        return res.status(400).json({ message });
      }

      return res.status(500).json({
        message: "Erro ao listar vagas.",
        error: message,
      });
    }
  }

  static async getById(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      const vaga = await VagaController.buscarVagaCompleta(Number(id));

      if (!vaga) {
        return res.status(404).json({ message: "Vaga não encontrada." });
      }

      if (perfilLogado === UsuarioPerfil.ALUNO && vaga.ativo !== 1) {
        return res.status(404).json({ message: "Vaga não encontrada." });
      }

      
      if (perfilLogado === UsuarioPerfil.EMPRESA) {
        const empresaRepository = AppDataSource.getRepository(Empresa);
        const empresa = await empresaRepository.findOne({
          where: { usuario: { id: usuarioLogadoId } },
        });

        if (!empresa || vaga.empresa_id !== empresa.id) {
          return res.status(403).json({
            message: "Você só pode acessar vagas da sua própria empresa.",
          });
        }
      }

      return res.status(200).json(vaga);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao buscar vaga.",
        error: error.message,
      });
    }
  }

  static async update(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({
          message: "Apenas empresas podem editar vagas.",
        });
      }

      const vagaRepository = AppDataSource.getRepository(Vaga);

      const vaga = await vagaRepository.findOne({
        where: { id: Number(id) },
      });

      if (!vaga) {
        return res.status(404).json({
          message: "Vaga não encontrada.",
        });
      }

      // CORREÇÃO: Busca a empresa do usuário logado antes de comparar
      const empresaRepository = AppDataSource.getRepository(Empresa);
      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } },
      });

      if (!empresa || vaga.empresa_id !== empresa.id) {
        return res.status(403).json({
          message: "Você só pode editar vagas da sua própria empresa.",
        });
      }

      if (vaga.ativo !== 1) {
        return res.status(400).json({
          message: "Não é possível editar uma vaga arquivada.",
        });
      }

      const {
        titulo,
        descricao,
        requisitos,
        modalidade,
        cep,
        endereco,
        numero,
        cidade,
        estado,
        latitude,
        longitude,
        habilidadeIds,
      } = req.body;

      if (modalidade && !Object.values(VagaModalidade).includes(modalidade)) {
        return res.status(400).json({
          message: "Modalidade inválida.",
        });
      }

      if (habilidadeIds !== undefined && !Array.isArray(habilidadeIds)) {
        return res.status(400).json({
          message: "O campo habilidadeIds deve ser um array.",
        });
      }

      const latitudeNormalizada =
        VagaController.normalizarCoordenadaOpcional(latitude);
      const longitudeNormalizada =
        VagaController.normalizarCoordenadaOpcional(longitude);

      if (
        Number.isNaN(latitudeNormalizada) ||
        Number.isNaN(longitudeNormalizada)
      ) {
        return res.status(400).json({
          message: "Latitude e longitude devem ser coordenadas válidas.",
        });
      }

      const modalidadeFinal = modalidade ?? vaga.modalidade;
      const cepFinal =
        cep === undefined ? vaga.cep : VagaController.normalizarTextoOpcional(cep);
      const enderecoFinal =
        endereco === undefined
          ? vaga.endereco
          : VagaController.normalizarTextoOpcional(endereco);
      const cidadeFinal =
        cidade === undefined
          ? vaga.cidade
          : VagaController.normalizarTextoOpcional(cidade);
      const estadoFinal =
        estado === undefined
          ? vaga.estado
          : VagaController.normalizarTextoOpcional(estado);
      const latitudeFinal =
        latitudeNormalizada === undefined ? vaga.latitude : latitudeNormalizada;
      const longitudeFinal =
        longitudeNormalizada === undefined ? vaga.longitude : longitudeNormalizada;
      const enderecoFoiAlterado = [
        "cep",
        "endereco",
        "numero",
        "cidade",
        "estado",
      ].some((campo) => Object.prototype.hasOwnProperty.call(req.body, campo));
      let latitudeParaSalvar: number | string | null | undefined =
        latitudeFinal;
      let longitudeParaSalvar: number | string | null | undefined =
        longitudeFinal;

      if (
        VagaController.coordenadasForamInformadas(
          latitudeNormalizada,
          longitudeNormalizada
        ) &&
        !VagaController.coordenadasValidas(latitudeFinal, longitudeFinal)
      ) {
        return res.status(400).json({
          message: "Latitude e longitude devem ser coordenadas válidas.",
        });
      }

      if (
        !VagaController.coordenadasForamInformadas(
          latitudeNormalizada,
          longitudeNormalizada
        ) &&
        enderecoFoiAlterado
      ) {
        const coordenadas = await geocodificarEndereco({
          cep: cepFinal,
          endereco: enderecoFinal,
          numero:
            numero === undefined
              ? vaga.numero
              : VagaController.normalizarTextoOpcional(numero),
          cidade: cidadeFinal,
          estado: estadoFinal,
        });

        latitudeParaSalvar = coordenadas?.latitude ?? null;
        longitudeParaSalvar = coordenadas?.longitude ?? null;
      }
      const cursosForamEnviados = VagaController.bodyTemCampo(
        req.body,
        "cursos_destinados",
        "cursosDestinados"
      );
      const anoMinFoiEnviado = VagaController.bodyTemCampo(
        req.body,
        "ano_conclusao_min",
        "anoConclusaoMin"
      );
      const anoMaxFoiEnviado = VagaController.bodyTemCampo(
        req.body,
        "ano_conclusao_max",
        "anoConclusaoMax"
      );
      const cursosNormalizados = cursosForamEnviados
        ? VagaController.normalizarListaCursos(
            VagaController.obterCampoBody(
              req.body,
              "cursos_destinados",
              "cursosDestinados"
            )
          )
        : undefined;
      const anoConclusaoMin = anoMinFoiEnviado
        ? VagaController.normalizarAnoConclusao(
            VagaController.obterCampoBody(
              req.body,
              "ano_conclusao_min",
              "anoConclusaoMin"
            )
          )
        : undefined;
      const anoConclusaoMax = anoMaxFoiEnviado
        ? VagaController.normalizarAnoConclusao(
            VagaController.obterCampoBody(
              req.body,
              "ano_conclusao_max",
              "anoConclusaoMax"
            )
          )
        : undefined;
      const anoConclusaoMinFinal = anoMinFoiEnviado
        ? anoConclusaoMin
        : vaga.ano_conclusao_min;
      const anoConclusaoMaxFinal = anoMaxFoiEnviado
        ? anoConclusaoMax
        : vaga.ano_conclusao_max;

      const erroLocalizacao = VagaController.validarLocalizacaoVaga({
        modalidade: modalidadeFinal,
        cep: cepFinal,
        endereco: enderecoFinal,
        cidade: cidadeFinal,
        estado: estadoFinal,
        latitude: latitudeFinal,
        longitude: longitudeFinal,
      });

      if (erroLocalizacao) {
        return res.status(400).json({ message: erroLocalizacao });
      }

      VagaController.validarIntervaloConclusao(
        anoConclusaoMinFinal,
        anoConclusaoMaxFinal
      );

      vaga.titulo = titulo ?? vaga.titulo;
      vaga.descricao = descricao ?? vaga.descricao;
      vaga.requisitos = requisitos ?? vaga.requisitos;
      vaga.modalidade = modalidadeFinal;
      vaga.cep = cepFinal ?? undefined;
      vaga.endereco = enderecoFinal ?? undefined;
      vaga.numero =
        numero === undefined
          ? vaga.numero
          : VagaController.normalizarTextoOpcional(numero) ?? undefined;
      vaga.cidade = cidadeFinal ?? undefined;
      vaga.estado = estadoFinal ?? undefined;
      (vaga as any).latitude = latitudeParaSalvar ?? null;
      (vaga as any).longitude = longitudeParaSalvar ?? null;
      if (cursosForamEnviados) {
        vaga.cursos_destinados =
          cursosNormalizados && cursosNormalizados.length > 0
            ? cursosNormalizados
            : null;
      }
      vaga.ano_conclusao_min = anoConclusaoMinFinal ?? null;
      vaga.ano_conclusao_max = anoConclusaoMaxFinal ?? null;

      const vagaAtualizada = await vagaRepository.save(vaga);

      if (Array.isArray(habilidadeIds)) {
        const habilidades = await VagaController.sincronizarHabilidadesDaVaga(
          vagaAtualizada.id,
          habilidadeIds
        );

        vagaAtualizada.habilidades = habilidades.map(
          (habilidade) => habilidade.nome
        );

        await vagaRepository.save(vagaAtualizada);
      }

      const vagaCompleta = await VagaController.buscarVagaCompleta(
        vagaAtualizada.id
      );

      return res.status(200).json(vagaCompleta);
    } catch (error: any) {
      const message = error.message || "Erro ao atualizar vaga.";

      if (message.includes("habilidades") || VagaController.erroValidacaoVaga(message)) {
        return res.status(400).json({ message });
      }

      return res.status(500).json({
        message: "Erro ao atualizar vaga.",
        error: message,
      });
    }
  }

  static async archive(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({
          message: "Apenas empresas podem arquivar vagas.",
        });
      }

      const vagaRepository = AppDataSource.getRepository(Vaga);

      const vaga = await vagaRepository.findOne({
        where: { id: Number(id) },
      });

      if (!vaga) {
        return res.status(404).json({
          message: "Vaga não encontrada.",
        });
      }

      // CORREÇÃO: Busca a empresa do usuário logado antes de comparar
      const empresaRepository = AppDataSource.getRepository(Empresa);
      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } },
      });

      if (!empresa || vaga.empresa_id !== empresa.id) {
        return res.status(403).json({
          message: "Você só pode arquivar vagas da sua própria empresa.",
        });
      }

      if (vaga.ativo !== 1) {
        return res.status(400).json({
          message: "Esta vaga já está arquivada.",
        });
      }

      vaga.ativo = 0;

      const vagaArquivada = await vagaRepository.save(vaga);

      return res.status(200).json({
        message: "Vaga arquivada com sucesso.",
        vaga: vagaArquivada,
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao arquivar vaga.",
        error: error.message,
      });
    }
  }

  static async unarchive(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({
          message: "Apenas empresas podem desarquivar vagas.",
        });
      }

      const vagaRepository = AppDataSource.getRepository(Vaga);

      const vaga = await vagaRepository.findOne({
        where: { id: Number(id) },
      });

      if (!vaga) {
        return res.status(404).json({
          message: "Vaga não encontrada.",
        });
      }

      // CORREÇÃO: Busca a empresa do usuário logado antes de comparar
      const empresaRepository = AppDataSource.getRepository(Empresa);
      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } },
      });

      if (!empresa || vaga.empresa_id !== empresa.id) {
        return res.status(403).json({
          message: "Você só pode desarquivar vagas da sua própria empresa.",
        });
      }

      if (vaga.ativo === 1) {
        return res.status(400).json({
          message: "Esta vaga já está ativa.",
        });
      }

      vaga.ativo = 1;

      const vagaDesarquivada = await vagaRepository.save(vaga);

      return res.status(200).json({
        message: "Vaga desarquivada com sucesso.",
        vaga: vagaDesarquivada,
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao desarquivar vaga.",
        error: error.message,
      });
    }
  }

  static async delete(req: Request, res: Response) {
    return VagaController.archive(req, res);
  }
}
