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

export class VagaController {
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

      if (habilidadeIds !== undefined && !Array.isArray(habilidadeIds)) {
        return res.status(400).json({
          message: "O campo habilidadeIds deve ser um array.",
        });
      }

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
        latitude: latitude ?? empresa.latitude ?? null,
        longitude: longitude ?? empresa.longitude ?? null,
        habilidades: [],
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

      if (message.includes("habilidades")) {
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
        where: { ativo: 1 },
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
            match_percent,
            skills_required: habilidadesVaga.length,
            skills_matched: habilidadesEmComum.length,
          };
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
      return res.status(500).json({
        message: "Erro ao listar vagas.",
        error: error.message,
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

      vaga.titulo = titulo ?? vaga.titulo;
      vaga.descricao = descricao ?? vaga.descricao;
      vaga.requisitos = requisitos ?? vaga.requisitos;
      vaga.modalidade = modalidade ?? vaga.modalidade;
      vaga.latitude = latitude ?? vaga.latitude;
      vaga.longitude = longitude ?? vaga.longitude;

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

      if (message.includes("habilidades")) {
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
