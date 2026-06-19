import { Request, Response } from "express";
import { In } from "typeorm";
import path from "path";
import fs from "fs";
import { AppDataSource } from "../data-source";
import { Aluno } from "../entities/Aluno";
import { AlunoHabilidade } from "../entities/AlunoHabilidade";
import { Candidatura } from "../entities/Candidatura";
import { Empresa } from "../entities/Empresa";
import { Habilidade } from "../entities/Habilidade";
import { UsuarioPerfil } from "../entities/Usuario";

export class AlunoController {
  private static async empresaPodeAcessarAluno(
    usuarioLogadoId: number,
    alunoId: number
  ) {
    const empresa = await AppDataSource.getRepository(Empresa).findOne({
      where: { usuario: { id: usuarioLogadoId } },
    });

    if (!empresa) return false;

    const candidatura = await AppDataSource.getRepository(Candidatura).findOne({
      where: {
        aluno_id: alunoId,
        vaga: { empresa_id: empresa.id },
      },
      relations: ["vaga"],
    });

    return Boolean(candidatura);
  }

  private static enviarArquivoCurriculo(
    res: Response,
    filename?: string | null
  ) {
    if (!filename) {
      return res.status(404).json({ message: "Currículo não anexado." });
    }

    const filePath = path.resolve(
      __dirname,
      "..",
      "..",
      "uploads",
      "curriculos",
      filename
    );

    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ message: "Arquivo do currículo não encontrado." });
    }

    return res.sendFile(filePath);
  }

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

  // --- NOVO MÉTODO ADICIONADO PARA RESOLVER O ERRO 404 ---
  static async atualizarPerfil(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.ALUNO) {
        return res.status(403).json({ message: "Acesso negado." });
      }

      const alunoRepository = AppDataSource.getRepository(Aluno);
      const aluno = await alunoRepository.findOneBy({ id: usuarioLogadoId });

      if (!aluno) {
        return res.status(404).json({ message: "Perfil não encontrado." });
      }

      // Atualiza os dados recebidos do frontend
      alunoRepository.merge(aluno, req.body);
      await alunoRepository.save(aluno);

      return res.status(200).json({ message: "Perfil atualizado com sucesso!" });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao atualizar perfil.",
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

  static async atualizarCurriculo(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.ALUNO) {
        return res.status(403).json({
          message: "Apenas alunos podem enviar currículo.",
        });
      }

      if (!req.file) {
        return res.status(400).json({
          message: "Envie um currículo em PDF.",
        });
      }

      const alunoRepository = AppDataSource.getRepository(Aluno);
      const aluno = await alunoRepository.findOne({
        where: { id: usuarioLogadoId },
      });

      if (!aluno) {
        return res.status(404).json({
          message: "Perfil de aluno não encontrado.",
        });
      }

      aluno.url_curriculo = req.file.filename;
      await alunoRepository.save(aluno);

      return res.status(200).json({
        message: "Currículo atualizado com sucesso.",
        url_curriculo: aluno.url_curriculo,
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao atualizar currículo.",
        error: error.message,
      });
    }
  }

  static async meuCurriculo(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;

      if (perfilLogado !== UsuarioPerfil.ALUNO) {
        return res.status(403).json({
          message: "Apenas alunos podem acessar o próprio currículo.",
        });
      }

      const aluno = await AppDataSource.getRepository(Aluno).findOne({
        where: { id: usuarioLogadoId },
      });

      if (!aluno) {
        return res.status(404).json({ message: "Perfil de aluno não encontrado." });
      }

      return AlunoController.enviarArquivoCurriculo(res, aluno.url_curriculo);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao buscar currículo.",
        error: error.message,
      });
    }
  }

  static async curriculoPorAluno(req: Request, res: Response) {
    try {
      const usuarioLogadoId = Number((req as any).usuarioId);
      const perfilLogado = (req as any).usuarioPerfil;
      const alunoId = Number(req.params.id);

      if (!alunoId || Number.isNaN(alunoId)) {
        return res.status(400).json({ message: "ID do aluno inválido." });
      }

      if (perfilLogado === UsuarioPerfil.ALUNO && usuarioLogadoId !== alunoId) {
        return res.status(403).json({ message: "Acesso negado ao currículo." });
      }

      if (perfilLogado === UsuarioPerfil.EMPRESA) {
        const podeAcessar = await AlunoController.empresaPodeAcessarAluno(
          usuarioLogadoId,
          alunoId
        );

        if (!podeAcessar) {
          return res.status(403).json({ message: "Acesso negado ao currículo." });
        }
      }

      const aluno = await AppDataSource.getRepository(Aluno).findOne({
        where: { id: alunoId },
      });

      if (!aluno) {
        return res.status(404).json({ message: "Perfil de aluno não encontrado." });
      }

      return AlunoController.enviarArquivoCurriculo(res, aluno.url_curriculo);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao buscar currículo.",
        error: error.message,
      });
    }
  }
}
