import { Request, Response } from "express";
import { In } from "typeorm";
import { AppDataSource } from "../data-source";
import { Aluno } from "../entities/Aluno";
import { AlunoHabilidade } from "../entities/AlunoHabilidade";
import { Habilidade } from "../entities/Habilidade";
import { UsuarioPerfil } from "../entities/Usuario";

export class AlunoController {
  static async meuPerfil(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.ALUNO) {
        return res.status(403).json({
          message: "Apenas alunos podem acessar este recurso.",
        });
      }

      const alunoRepository = AppDataSource.getRepository(Aluno);

      const aluno = await alunoRepository.findOne({
        where: { id: usuarioLogadoId },
        relations: [
          "usuario",
          "alunoHabilidades",
          "alunoHabilidades.habilidade",
        ],
      });

      if (!aluno) {
        return res.status(404).json({
          message: "Perfil de aluno não encontrado.",
        });
      }

      return res.status(200).json(aluno);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao buscar perfil do aluno.",
        error: error.message,
      });
    }
  }

  static async atualizarHabilidades(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;
      const { habilidadeIds } = req.body;

      if (perfilLogado !== UsuarioPerfil.ALUNO) {
        return res.status(403).json({
          message: "Apenas alunos podem alterar habilidades.",
        });
      }

      if (!Array.isArray(habilidadeIds)) {
        return res.status(400).json({
          message: "O campo habilidadeIds deve ser um array de IDs.",
        });
      }

      const ids = habilidadeIds
        .map((id) => Number(id))
        .filter((id) => Number.isInteger(id) && id > 0);

      const idsUnicos = Array.from(new Set(ids));

      const alunoRepository = AppDataSource.getRepository(Aluno);
      const habilidadeRepository = AppDataSource.getRepository(Habilidade);
      const alunoHabilidadeRepository =
        AppDataSource.getRepository(AlunoHabilidade);

      const aluno = await alunoRepository.findOne({
        where: { id: usuarioLogadoId },
      });

      if (!aluno) {
        return res.status(404).json({
          message: "Perfil de aluno não encontrado.",
        });
      }

      const habilidades = idsUnicos.length
        ? await habilidadeRepository.find({
            where: { id: In(idsUnicos) },
          })
        : [];

      if (habilidades.length !== idsUnicos.length) {
        return res.status(400).json({
          message: "Uma ou mais habilidades informadas não existem.",
        });
      }

      await alunoHabilidadeRepository.delete({
        aluno_id: aluno.id,
      });

      if (idsUnicos.length > 0) {
        const novasRelacoes = idsUnicos.map((habilidadeId) =>
          alunoHabilidadeRepository.create({
            aluno_id: aluno.id,
            habilidade_id: habilidadeId,
          })
        );

        await alunoHabilidadeRepository.save(novasRelacoes);
      }

      const alunoAtualizado = await alunoRepository.findOne({
        where: { id: aluno.id },
        relations: [
          "usuario",
          "alunoHabilidades",
          "alunoHabilidades.habilidade",
        ],
      });

      return res.status(200).json({
        message: "Habilidades do aluno atualizadas com sucesso.",
        aluno: alunoAtualizado,
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao atualizar habilidades do aluno.",
        error: error.message,
      });
    }
  }
}
