import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Candidatura, CandidaturaStatus } from "../entities/Candidatura";
import { Vaga } from "../entities/Vaga";
import { Aluno } from "../entities/Aluno";
import { UsuarioPerfil } from "../entities/Usuario";

export class CandidaturaController {
  static async candidatar(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;
      const vagaId = Number(req.params.id);

      if (perfilLogado !== UsuarioPerfil.ALUNO) {
        return res.status(403).json({
          message: "Apenas alunos podem se candidatar a vagas.",
        });
      }

      if (!vagaId || Number.isNaN(vagaId)) {
        return res.status(400).json({
          message: "ID da vaga inválido.",
        });
      }

      const alunoRepository = AppDataSource.getRepository(Aluno);
      const vagaRepository = AppDataSource.getRepository(Vaga);
      const candidaturaRepository = AppDataSource.getRepository(Candidatura);

      const aluno = await alunoRepository.findOne({
        where: { id: usuarioLogadoId },
      });

      if (!aluno) {
        return res.status(404).json({
          message: "Perfil de aluno não encontrado para este usuário.",
        });
      }

      const vaga = await vagaRepository.findOne({
        where: { id: vagaId, ativo: 1 },
      });

      if (!vaga) {
        return res.status(404).json({
          message: "Vaga não encontrada ou inativa.",
        });
      }

      const candidaturaExistente = await candidaturaRepository.findOne({
        where: {
          aluno_id: aluno.id,
          vaga_id: vaga.id,
        },
      });

      if (candidaturaExistente) {
        return res.status(409).json({
          message: "Você já se candidatou a esta vaga.",
          candidatura: candidaturaExistente,
        });
      }

      const candidatura = candidaturaRepository.create({
        aluno_id: aluno.id,
        vaga_id: vaga.id,
        status: CandidaturaStatus.PENDENTE,
        pontuacao_compatibilidade: null,
      });

      const candidaturaSalva = await candidaturaRepository.save(candidatura);

      return res.status(201).json({
        message: "Candidatura realizada com sucesso.",
        candidatura: candidaturaSalva,
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao realizar candidatura.",
        error: error.message,
      });
    }
  }

  static async minhasCandidaturas(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.ALUNO) {
        return res.status(403).json({
          message: "Apenas alunos podem visualizar suas candidaturas.",
        });
      }

      const candidaturaRepository = AppDataSource.getRepository(Candidatura);

      const candidaturas = await candidaturaRepository.find({
        where: {
          aluno_id: usuarioLogadoId,
        },
        relations: ["vaga", "vaga.empresa", "vaga.empresa.usuario"],
        order: {
          data_candidatura: "DESC",
        },
      });

      return res.status(200).json(candidaturas);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao listar candidaturas.",
        error: error.message,
      });
    }
  }

  static async candidaturasDaVaga(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;
      const vagaId = Number(req.params.id);

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({
          message: "Apenas empresas podem visualizar candidaturas da vaga.",
        });
      }

      const vagaRepository = AppDataSource.getRepository(Vaga);
      const candidaturaRepository = AppDataSource.getRepository(Candidatura);

      const vaga = await vagaRepository.findOne({
        where: { id: vagaId },
      });

      if (!vaga) {
        return res.status(404).json({
          message: "Vaga não encontrada.",
        });
      }

      if (vaga.empresa_id !== usuarioLogadoId) {
        return res.status(403).json({
          message: "Você só pode visualizar candidaturas das suas próprias vagas.",
        });
      }

      const candidaturas = await candidaturaRepository.find({
        where: {
          vaga_id: vagaId,
        },
        relations: ["aluno", "aluno.usuario"],
        order: {
          data_candidatura: "DESC",
        },
      });

      return res.status(200).json(candidaturas);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao listar candidaturas da vaga.",
        error: error.message,
      });
    }
  }
}
