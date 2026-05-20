import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Candidatura, CandidaturaStatus } from "../entities/Candidatura";
import { Vaga } from "../entities/Vaga";
import { Aluno } from "../entities/Aluno";
import { Empresa } from "../entities/Empresa";
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
        where: { usuario: { id: usuarioLogadoId } }, 
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
          aluno: { id: aluno.id },
          vaga: { id: vaga.id },
        },
      });

      if (candidaturaExistente) {
        return res.status(409).json({
          message: "Você já se candidatou a esta vaga.",
          candidatura: candidaturaExistente,
        });
      }

      // CAPTURA DO ARQUIVO: Se o multer salvou o arquivo, pegamos o nome dele aqui
      const curriculo_path = req.file ? req.file.filename : undefined;

      const novaCandidatura = candidaturaRepository.create({
        aluno,
        vaga,
        status: CandidaturaStatus.PENDENTE,
        curriculo_path, // NOVO CAMPO: Salva o identificador único do PDF se ele foi anexado
      });

      const candidaturaSalva = await candidaturaRepository.save(novaCandidatura);

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

      const alunoRepository = AppDataSource.getRepository(Aluno);
      const candidaturaRepository = AppDataSource.getRepository(Candidatura);

      const aluno = await alunoRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } },
      });

      if (!aluno) {
        return res.status(404).json({ message: "Perfil de aluno não encontrado." });
      }

      const candidaturas = await candidaturaRepository.find({
        where: {
          aluno: { id: aluno.id },
        },
        relations: ["vaga", "vaga.empresa"],
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

      const empresaRepository = AppDataSource.getRepository(Empresa);
      const vagaRepository = AppDataSource.getRepository(Vaga);
      const candidaturaRepository = AppDataSource.getRepository(Candidatura);

      const empresa = await empresaRepository.findOne({
        where: { usuario: { id: usuarioLogadoId } },
      });

      if (!empresa) {
        return res.status(404).json({ message: "Perfil de empresa não encontrado." });
      }

      const vaga = await vagaRepository.findOne({
        where: { id: vagaId },
      });

      if (!vaga) {
        return res.status(404).json({
          message: "Vaga não encontrada.",
        });
      }

      if (vaga.empresa_id !== empresa.id) {
        return res.status(403).json({
          message: "Você só pode visualizar candidaturas das suas próprias vagas.",
        });
      }

      const candidaturas = await candidaturaRepository.find({
        where: {
          vaga: { id: vagaId },
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

  static async atualizarStatus(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;
      const candidaturaId = Number(req.params.id);
      const { status } = req.body;

      if (perfilLogado !== UsuarioPerfil.EMPRESA) {
        return res.status(403).json({
          message: "Apenas empresas podem alterar status de candidaturas.",
        });
      }

      if (!candidaturaId || Number.isNaN(candidaturaId)) {
        return res.status(400).json({
          message: "ID da candidatura inválido.",
        });
      }

      const statusPermitidos = Object.values(CandidaturaStatus);

      if (!status || !statusPermitidos.includes(status)) {
        return res.status(400).json({
          message: "Status inválido.",
          statusPermitidos,
        });
      }

      const candidaturaRepository = AppDataSource.getRepository(Candidatura);

      const candidatura = await candidaturaRepository.findOne({
        where: {
          id: candidaturaId,
        },
        relations: ["vaga", "aluno", "aluno.usuario"],
      });

      if (!candidatura) {
        return res.status(404).json({
          message: "Candidatura não encontrada.",
        });
      }

      // Valida se a empresa logada é a dona da vaga
      if (candidatura.vaga.empresa_id !== usuarioLogadoId) {
        return res.status(403).json({
          message:
            "Você só pode alterar candidaturas de vagas da sua própria empresa.",
        });
      }

      candidatura.status = status;

      const candidaturaAtualizada =
        await candidaturaRepository.save(candidatura);

      return res.status(200).json({
        message: "Status da candidatura updated com sucesso.",
        candidatura: candidaturaAtualizada,
      });
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao atualizar status da candidatura.",
        error: error.message,
      });
    }
  }
}