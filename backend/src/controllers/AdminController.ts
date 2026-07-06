import { Request, Response } from "express";
import fs from "fs";
import path from "path";
import { Brackets } from "typeorm";
import { AppDataSource } from "../data-source";
import { Aluno } from "../entities/Aluno";
import { AlunoHabilidade } from "../entities/AlunoHabilidade";
import { Candidatura } from "../entities/Candidatura";
import { Empresa, EmpresaStatusVerificacao } from "../entities/Empresa";
import { Habilidade } from "../entities/Habilidade";
import { Mensagem } from "../entities/Mensagem";
import { Usuario, UsuarioPerfil } from "../entities/Usuario";
import { Vaga } from "../entities/Vaga";
import { VagaHabilidade } from "../entities/VagaHabilidade";
import { Avaliacao } from "../entities/Avaliacao";
import { Notificacao } from "../entities/Notificacao";
import { HabilidadeController } from "./HabilidadeController";
import { verificacaoEmpresaUploadPath } from "../config/verificacaoEmpresaMulter";

function parseBooleanFilter(value: unknown): boolean | null {
  if (value === "true") return true;
  if (value === "false") return false;
  return null;
}

function parsePerfil(value: unknown): UsuarioPerfil | null {
  if (typeof value !== "string") return null;
  return Object.values(UsuarioPerfil).includes(value as UsuarioPerfil)
    ? (value as UsuarioPerfil)
    : null;
}

function parseId(value: unknown): number | null {
  const id = Number(value);
  return Number.isInteger(id) && id > 0 ? id : null;
}

function parseStatusVerificacao(value: unknown): EmpresaStatusVerificacao | null {
  if (typeof value !== "string") return null;
  return Object.values(EmpresaStatusVerificacao).includes(
    value as EmpresaStatusVerificacao
  )
    ? (value as EmpresaStatusVerificacao)
    : null;
}

function nomeArquivoSeguro(value?: string | null) {
  if (!value) return "documento-verificacao.pdf";
  return path.basename(value).replace(/[\r\n"]/g, "_") || "documento-verificacao.pdf";
}

function empresaSemDocumentoPath(empresa: Empresa) {
  const { documento_verificacao_path: _documentoPath, ...segura } = empresa as any;
  return segura;
}

async function aplicarDecisaoVerificacao(
  empresaId: number,
  decisao: "aprovar" | "rejeitar",
  motivo?: string
) {
  const empresaRepository = AppDataSource.getRepository(Empresa);
  const empresa = await empresaRepository.findOne({
    where: { id: empresaId },
    relations: ["usuario"],
  });

  if (!empresa) {
    return { status: 404, body: { message: "Empresa não encontrada." } };
  }

  if (decisao === "aprovar") {
    if (!empresa.documento_verificacao_path) {
      return {
        status: 409,
        body: { message: "Não é possível aprovar sem documento PDF enviado." },
      };
    }

    empresa.verificada = true;
    empresa.status_verificacao = EmpresaStatusVerificacao.APROVADA;
    empresa.verificacao_analisada_em = new Date();
    empresa.verificacao_motivo_rejeicao = null;
  } else {
    const motivoNormalizado = typeof motivo === "string" ? motivo.trim() : "";

    if (!motivoNormalizado) {
      return {
        status: 400,
        body: { message: "Informe o motivo da rejeição." },
      };
    }

    empresa.verificada = false;
    empresa.status_verificacao = EmpresaStatusVerificacao.REJEITADA;
    empresa.verificacao_analisada_em = new Date();
    empresa.verificacao_motivo_rejeicao = motivoNormalizado;
  }

  const atualizada = await empresaRepository.save(empresa);
  return {
    status: 200,
    body: {
      message: "Verificação analisada com sucesso.",
      empresa: empresaSemDocumentoPath(atualizada),
    },
  };
}

export class AdminController {
  static async dashboardStats(req: Request, res: Response): Promise<Response> {
    try {
      const usuarioRepository = AppDataSource.getRepository(Usuario);
      const alunoRepository = AppDataSource.getRepository(Aluno);
      const empresaRepository = AppDataSource.getRepository(Empresa);
      const vagaRepository = AppDataSource.getRepository(Vaga);
      const habilidadeRepository = AppDataSource.getRepository(Habilidade);

      const [
        usuarios,
        alunos,
        empresas,
        empresasVerificadas,
        vagas,
        vagasAtivas,
        habilidades,
      ] = await Promise.all([
        usuarioRepository.count(),
        alunoRepository.count(),
        empresaRepository.count(),
        empresaRepository.count({ where: { verificada: true } }),
        vagaRepository.count(),
        vagaRepository.count({ where: { ativo: 1 } }),
        habilidadeRepository.count(),
      ]);

      return res.status(200).json({
        usuarios,
        alunos,
        empresas,
        empresasVerificadas,
        empresasPendentes: empresas - empresasVerificadas,
        vagas,
        vagasAtivas,
        habilidades,
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao carregar estatísticas do moderador.",
        error: error.message,
      });
    }
  }

  static async listarUsuarios(req: Request, res: Response): Promise<Response> {
    try {
      const { perfil, busca } = req.query;
      const perfilFiltro = perfil === undefined ? null : parsePerfil(perfil);

      if (perfil !== undefined && !perfilFiltro) {
        return res.status(400).json({ message: "Perfil inválido." });
      }

      const query = AppDataSource.getRepository(Usuario)
        .createQueryBuilder("usuario")
        .select([
          "usuario.id",
          "usuario.email",
          "usuario.nome_exibicao",
          "usuario.perfil",
          "usuario.criado_em",
          "usuario.atualizado_em",
        ])
        .orderBy("usuario.criado_em", "DESC");

      if (perfilFiltro) {
        query.andWhere("usuario.perfil = :perfil", { perfil: perfilFiltro });
      }

      if (typeof busca === "string" && busca.trim()) {
        query.andWhere(
          new Brackets((qb) => {
            qb.where("LOWER(usuario.nome_exibicao) LIKE LOWER(:busca)", {
              busca: `%${busca.trim()}%`,
            }).orWhere("LOWER(usuario.email) LIKE LOWER(:busca)", {
              busca: `%${busca.trim()}%`,
            });
          })
        );
      }

      const usuarios = await query.getMany();
      return res.status(200).json({ usuarios });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao listar usuários.",
        error: error.message,
      });
    }
  }

  static async obterUsuario(req: Request, res: Response): Promise<Response> {
    try {
      const usuarioId = parseId(req.params.id);
      if (!usuarioId) {
        return res.status(400).json({ message: "ID de usuário inválido." });
      }

      const usuario = await AppDataSource.getRepository(Usuario).findOne({
        where: { id: usuarioId },
        select: {
          id: true,
          email: true,
          nome_exibicao: true,
          perfil: true,
          criado_em: true,
          atualizado_em: true,
        },
      });

      if (!usuario) {
        return res.status(404).json({ message: "Usuário não encontrado." });
      }

      const dadosComuns = {
        id: usuario.id,
        nome_exibicao: usuario.nome_exibicao,
        nome: usuario.nome_exibicao,
        email: usuario.email,
        perfil: usuario.perfil,
        criado_em: usuario.criado_em,
        atualizado_em: usuario.atualizado_em,
      };

      if (usuario.perfil === UsuarioPerfil.ALUNO) {
        const aluno = await AppDataSource.getRepository(Aluno).findOne({
          where: { id: usuario.id },
          relations: ["alunoHabilidades", "alunoHabilidades.habilidade"],
        });

        return res.status(200).json({
          ...dadosComuns,
          cpf: aluno?.cpf ?? null,
          curso: aluno?.curso ?? null,
          instituicao: aluno?.instituicao ?? null,
          ano_conclusao: aluno?.ano_conclusao ?? null,
          cep: aluno?.cep ?? null,
          endereco: aluno?.endereco ?? null,
          numero: aluno?.numero ?? null,
          habilidades:
            aluno?.alunoHabilidades?.map((relacao) => ({
              id: relacao.habilidade?.id,
              nome: relacao.habilidade?.nome,
              area: relacao.habilidade?.area,
            })) ?? [],
          possui_curriculo: Boolean(aluno?.url_curriculo),
        });
      }

      if (usuario.perfil === UsuarioPerfil.EMPRESA) {
        const empresa = await AppDataSource.getRepository(Empresa).findOne({
          where: { id: usuario.id },
        });
        const quantidadeVagas = await AppDataSource.getRepository(Vaga).count({
          where: { empresa_id: usuario.id },
        });

        return res.status(200).json({
          ...dadosComuns,
          cnpj: empresa?.cnpj ?? null,
          descricao: empresa?.descricao ?? null,
          latitude: empresa?.latitude ?? null,
          longitude: empresa?.longitude ?? null,
          verificada: empresa?.verificada ?? false,
          quantidade_vagas: quantidadeVagas,
        });
      }

      return res.status(200).json(dadosComuns);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao buscar usuário.",
        error: error.message,
      });
    }
  }

  static async listarEmpresas(req: Request, res: Response): Promise<Response> {
    try {
      const { busca, verificada, status_verificacao } = req.query;
      const verificadaFiltro =
        verificada === undefined ? null : parseBooleanFilter(verificada);
      const statusFiltro =
        status_verificacao === undefined
          ? null
          : parseStatusVerificacao(status_verificacao);

      if (verificada !== undefined && verificadaFiltro === null) {
        return res.status(400).json({ message: "Filtro verificada inválido." });
      }

      if (status_verificacao !== undefined && !statusFiltro) {
        return res.status(400).json({
          message: "Filtro status_verificacao inválido.",
        });
      }

      const query = AppDataSource.getRepository(Empresa)
        .createQueryBuilder("empresa")
        .leftJoinAndSelect("empresa.usuario", "usuario")
        .loadRelationCountAndMap("empresa.quantidadeVagas", "empresa.vagas")
        .orderBy("usuario.nome_exibicao", "ASC");

      if (verificadaFiltro !== null) {
        query.andWhere("empresa.verificada = :verificada", {
          verificada: verificadaFiltro,
        });
      }

      if (statusFiltro !== null) {
        query.andWhere("empresa.status_verificacao = :statusVerificacao", {
          statusVerificacao: statusFiltro,
        });
      }

      if (typeof busca === "string" && busca.trim()) {
        const buscaNumerica = busca.replace(/\D/g, "");
        query.andWhere(
          new Brackets((qb) => {
            qb.where("LOWER(usuario.nome_exibicao) LIKE LOWER(:busca)", {
              busca: `%${busca.trim()}%`,
            }).orWhere("LOWER(usuario.email) LIKE LOWER(:busca)", {
                busca: `%${busca.trim()}%`,
              });

            if (buscaNumerica) {
              qb.orWhere("empresa.cnpj LIKE :buscaNumerica", {
                buscaNumerica: `%${buscaNumerica}%`,
              });
            }
          })
        );
      }

      const empresas = await query.getMany();
      return res.status(200).json({
        empresas: empresas.map((empresa: any) => ({
          id: empresa.id,
          nome_exibicao: empresa.usuario?.nome_exibicao ?? null,
          email: empresa.usuario?.email ?? null,
          cnpj: empresa.cnpj,
          descricao: empresa.descricao,
          verificada: empresa.verificada,
          status_verificacao:
            empresa.status_verificacao ?? EmpresaStatusVerificacao.NAO_SOLICITADA,
          documento_enviado: Boolean(empresa.documento_verificacao_path),
          documento_nome_original:
            empresa.documento_verificacao_nome_original ?? null,
          verificacao_solicitada_em: empresa.verificacao_solicitada_em ?? null,
          verificacao_analisada_em: empresa.verificacao_analisada_em ?? null,
          verificacao_motivo_rejeicao:
            empresa.verificacao_motivo_rejeicao ?? null,
          quantidade_vagas: empresa.quantidadeVagas ?? 0,
          criado_em: empresa.usuario?.criado_em ?? null,
          usuario: empresa.usuario
            ? {
                id: empresa.usuario.id,
                nome_exibicao: empresa.usuario.nome_exibicao,
                email: empresa.usuario.email,
              }
            : null,
        })),
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao listar empresas.",
        error: error.message,
      });
    }
  }

  static async obterEmpresa(req: Request, res: Response): Promise<Response> {
    try {
      const empresaId = parseId(req.params.id);
      if (!empresaId) {
        return res.status(400).json({ message: "ID de empresa inválido." });
      }

      const empresa = await AppDataSource.getRepository(Empresa).findOne({
        where: { id: empresaId },
        relations: ["usuario"],
      });

      if (!empresa) {
        return res.status(404).json({ message: "Empresa não encontrada." });
      }

      const vagas = await AppDataSource.getRepository(Vaga).find({
        where: { empresa_id: empresa.id },
        order: { criado_em: "DESC" },
        select: {
          id: true,
          titulo: true,
          modalidade: true,
          ativo: true,
          criado_em: true,
        },
      });

      return res.status(200).json({
        id: empresa.id,
        nome_exibicao: empresa.usuario?.nome_exibicao ?? null,
        email: empresa.usuario?.email ?? null,
        cnpj: empresa.cnpj ?? null,
        descricao: empresa.descricao ?? null,
        latitude: empresa.latitude ?? null,
        longitude: empresa.longitude ?? null,
        verificada: empresa.verificada,
        status_verificacao:
          empresa.status_verificacao ?? EmpresaStatusVerificacao.NAO_SOLICITADA,
        documento_enviado: Boolean(empresa.documento_verificacao_path),
        documento_nome_original:
          empresa.documento_verificacao_nome_original ?? null,
        verificacao_solicitada_em: empresa.verificacao_solicitada_em ?? null,
        verificacao_analisada_em: empresa.verificacao_analisada_em ?? null,
        verificacao_motivo_rejeicao:
          empresa.verificacao_motivo_rejeicao ?? null,
        quantidade_vagas: vagas.length,
        criado_em: empresa.usuario?.criado_em ?? null,
        atualizado_em: empresa.usuario?.atualizado_em ?? null,
        usuario: empresa.usuario
          ? {
              id: empresa.usuario.id,
              nome_exibicao: empresa.usuario.nome_exibicao,
              email: empresa.usuario.email,
              perfil: empresa.usuario.perfil,
              criado_em: empresa.usuario.criado_em,
              atualizado_em: empresa.usuario.atualizado_em,
            }
          : null,
        vagas: vagas.map((vaga) => ({
          id: vaga.id,
          titulo: vaga.titulo,
          modalidade: vaga.modalidade,
          ativo: vaga.ativo,
          criado_em: vaga.criado_em,
        })),
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao buscar empresa.",
        error: error.message,
      });
    }
  }

  static async verificarEmpresa(req: Request, res: Response): Promise<Response> {
    try {
      const empresaId = parseId(req.params.id);
      if (!empresaId) {
        return res.status(400).json({ message: "ID de empresa inválido." });
      }

      if (typeof req.body.verificada !== "boolean") {
        return res.status(400).json({
          message: "Informe o campo verificada como true ou false.",
        });
      }

      const resultado = await aplicarDecisaoVerificacao(
        empresaId,
        req.body.verificada ? "aprovar" : "rejeitar",
        req.body.motivo || "Verificação removida pelo moderador."
      );

      return res.status(resultado.status).json(resultado.body);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao atualizar verificação da empresa.",
        error: error.message,
      });
    }
  }

  static async documentoVerificacaoEmpresa(
    req: Request,
    res: Response
  ): Promise<Response | void> {
    try {
      const empresaId = parseId(req.params.id);
      if (!empresaId) {
        return res.status(400).json({ message: "ID de empresa inválido." });
      }

      const empresa = await AppDataSource.getRepository(Empresa).findOne({
        where: { id: empresaId },
      });

      if (!empresa) {
        return res.status(404).json({ message: "Empresa não encontrada." });
      }

      const filename = empresa.documento_verificacao_path;
      if (!filename || path.basename(filename) !== filename) {
        return res.status(404).json({ message: "Documento não encontrado." });
      }

      const filePath = path.resolve(verificacaoEmpresaUploadPath, filename);
      const basePath = path.resolve(verificacaoEmpresaUploadPath);

      if (!filePath.startsWith(`${basePath}${path.sep}`) || !fs.existsSync(filePath)) {
        return res.status(404).json({ message: "Documento não encontrado." });
      }

      res.setHeader("Content-Type", "application/pdf");
      res.setHeader(
        "Content-Disposition",
        `inline; filename="${nomeArquivoSeguro(
          empresa.documento_verificacao_nome_original
        )}"`
      );

      return res.sendFile(filePath);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao abrir documento de verificação.",
        error: error.message,
      });
    }
  }

  static async decidirVerificacaoEmpresa(
    req: Request,
    res: Response
  ): Promise<Response> {
    try {
      const empresaId = parseId(req.params.id);
      if (!empresaId) {
        return res.status(400).json({ message: "ID de empresa inválido." });
      }

      const { decisao, motivo } = req.body;
      if (decisao !== "aprovar" && decisao !== "rejeitar") {
        return res.status(400).json({
          message: "Decisão inválida. Use aprovar ou rejeitar.",
        });
      }

      const resultado = await aplicarDecisaoVerificacao(empresaId, decisao, motivo);
      return res.status(resultado.status).json(resultado.body);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao analisar verificação da empresa.",
        error: error.message,
      });
    }
  }

  static async listarVagas(req: Request, res: Response): Promise<Response> {
    try {
      const { busca, ativo } = req.query;
      const ativoFiltro = ativo === undefined ? null : parseBooleanFilter(ativo);

      if (ativo !== undefined && ativoFiltro === null) {
        return res.status(400).json({ message: "Filtro ativo inválido." });
      }

      const query = AppDataSource.getRepository(Vaga)
        .createQueryBuilder("vaga")
        .leftJoinAndSelect("vaga.empresa", "empresa")
        .leftJoinAndSelect("empresa.usuario", "usuario")
        .orderBy("vaga.criado_em", "DESC");

      if (ativoFiltro !== null) {
        query.andWhere("vaga.ativo = :ativo", { ativo: ativoFiltro ? 1 : 0 });
      }

      if (typeof busca === "string" && busca.trim()) {
        query.andWhere(
          new Brackets((qb) => {
            qb.where("LOWER(vaga.titulo) LIKE LOWER(:busca)", {
              busca: `%${busca.trim()}%`,
            })
              .orWhere("LOWER(vaga.descricao) LIKE LOWER(:busca)", {
                busca: `%${busca.trim()}%`,
              })
              .orWhere("LOWER(usuario.nome_exibicao) LIKE LOWER(:busca)", {
                busca: `%${busca.trim()}%`,
              });
          })
        );
      }

      const vagas = await query.getMany();
      return res.status(200).json(vagas);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao listar vagas.",
        error: error.message,
      });
    }
  }

  static async deletarVaga(req: Request, res: Response): Promise<Response> {
    try {
      const vagaId = parseId(req.params.id);
      if (!vagaId) {
        return res.status(400).json({ message: "ID de vaga inválido." });
      }

      const vaga = await AppDataSource.getRepository(Vaga).findOne({
        where: { id: vagaId },
      });

      if (!vaga) {
        return res.status(404).json({ message: "Vaga não encontrada." });
      }

      await AppDataSource.transaction(async (manager) => {
        const candidaturas = await manager.find(Candidatura, {
          where: { vaga_id: vagaId },
          select: { id: true },
        });
        const candidaturaIds = candidaturas.map((item) => item.id);

        if (candidaturaIds.length > 0) {
          await manager
            .createQueryBuilder()
            .delete()
            .from(Mensagem)
            .where("candidatura_id IN (:...ids)", { ids: candidaturaIds })
            .execute();
        }

        await manager.delete(Candidatura, { vaga_id: vagaId });
        await manager.delete(VagaHabilidade, { vaga_id: vagaId });
        await manager.delete(Vaga, { id: vagaId });
      });

      return res.status(200).json({ message: "Vaga removida com sucesso." });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao deletar vaga.",
        error: error.message,
      });
    }
  }

  static async listarHabilidades(req: Request, res: Response): Promise<Response> {
    return HabilidadeController.getAll(req, res) as Promise<Response>;
  }

  static async criarHabilidade(req: Request, res: Response): Promise<Response> {
    return HabilidadeController.create(req, res) as Promise<Response>;
  }

  static async atualizarHabilidade(req: Request, res: Response): Promise<Response> {
    return HabilidadeController.update(req, res) as Promise<Response>;
  }

  static async deletarHabilidade(req: Request, res: Response): Promise<Response> {
    try {
      const habilidadeId = parseId(req.params.id);
      if (!habilidadeId) {
        return res.status(400).json({ message: "ID de habilidade inválido." });
      }

      const habilidadeRepository = AppDataSource.getRepository(Habilidade);
      const habilidade = await habilidadeRepository.findOne({
        where: { id: habilidadeId },
      });

      if (!habilidade) {
        return res.status(404).json({ message: "Habilidade não encontrada." });
      }

      const [vinculosAluno, vinculosVaga] = await Promise.all([
        AppDataSource.getRepository(AlunoHabilidade).count({
          where: { habilidade_id: habilidadeId },
        }),
        AppDataSource.getRepository(VagaHabilidade).count({
          where: { habilidade_id: habilidadeId },
        }),
      ]);

      if (vinculosAluno > 0 || vinculosVaga > 0) {
        return res.status(409).json({
          message:
            "Não é possível excluir esta habilidade porque ela está vinculada a alunos ou vagas.",
        });
      }

      await habilidadeRepository.remove(habilidade);
      return res.status(200).json({ message: "Habilidade removida com sucesso." });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao deletar habilidade.",
        error: error.message,
      });
    }
  }

  static async deletarUsuario(req: Request, res: Response): Promise<Response> {
    try {
      const usuarioId = parseId(req.params.id);
      const usuarioLogadoId = (req as any).usuarioId;

      if (!usuarioId) {
        return res.status(400).json({ message: "ID de usuário inválido." });
      }

      if (usuarioId === usuarioLogadoId) {
        return res.status(409).json({
          message: "Você não pode excluir a própria conta de moderador.",
        });
      }

      const usuarioRepository = AppDataSource.getRepository(Usuario);
      const usuario = await usuarioRepository.findOne({
        where: { id: usuarioId },
      });

      if (!usuario) {
        return res.status(404).json({ message: "Usuário não encontrado." });
      }

      if (usuario.perfil === UsuarioPerfil.ADMIN) {
        const totalAdmins = await usuarioRepository.count({
          where: { perfil: UsuarioPerfil.ADMIN },
        });

        if (totalAdmins <= 1) {
          return res.status(409).json({
            message: "Não é possível excluir o último usuário moderador.",
          });
        }
      }

      await AppDataSource.transaction(async (manager) => {
        if (usuario.perfil === UsuarioPerfil.EMPRESA) {
          const vagas = await manager.find(Vaga, {
            where: { empresa_id: usuarioId },
            select: { id: true },
          });

          for (const vaga of vagas) {
            const candidaturas = await manager.find(Candidatura, {
              where: { vaga_id: vaga.id },
              select: { id: true },
            });
            const candidaturaIds = candidaturas.map((item) => item.id);
            if (candidaturaIds.length > 0) {
              await manager
                .createQueryBuilder()
                .delete()
                .from(Mensagem)
                .where("candidatura_id IN (:...ids)", { ids: candidaturaIds })
                .execute();
            }
            await manager.delete(Candidatura, { vaga_id: vaga.id });
            await manager.delete(VagaHabilidade, { vaga_id: vaga.id });
          }

          await manager.delete(Vaga, { empresa_id: usuarioId });
          await manager.delete(Avaliacao, { empresa_id: usuarioId });
          await manager.delete(Empresa, { id: usuarioId });
        }

        if (usuario.perfil === UsuarioPerfil.ALUNO) {
          const candidaturas = await manager.find(Candidatura, {
            where: { aluno_id: usuarioId },
            select: { id: true },
          });
          const candidaturaIds = candidaturas.map((item) => item.id);
          if (candidaturaIds.length > 0) {
            await manager
              .createQueryBuilder()
              .delete()
              .from(Mensagem)
              .where("candidatura_id IN (:...ids)", { ids: candidaturaIds })
              .execute();
          }

          await manager.delete(Candidatura, { aluno_id: usuarioId });
          await manager.delete(AlunoHabilidade, { aluno_id: usuarioId });
          await manager.delete(Avaliacao, { aluno_id: usuarioId });
          await manager.delete(Aluno, { id: usuarioId });
        }

        await manager.delete(Mensagem, { remetente_id: usuarioId });
        await manager.delete(Notificacao, { usuario_id: usuarioId });
        await manager.delete(Usuario, { id: usuarioId });
      });

      return res.status(200).json({ message: "Usuário removido com sucesso." });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao deletar usuário.",
        error: error.message,
      });
    }
  }
}
