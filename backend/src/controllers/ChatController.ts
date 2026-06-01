import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Candidatura, CandidaturaStatus } from "../entities/Candidatura";
import { Mensagem } from "../entities/Mensagem";
import { UsuarioPerfil } from "../entities/Usuario";

export class ChatController {
  static async contagemChats(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;
      const candidaturaRepository = AppDataSource.getRepository(Candidatura);

      let count = 0;
      if (perfilLogado === UsuarioPerfil.ALUNO) {
        count = await candidaturaRepository.count({
          where: { aluno: { usuario: { id: usuarioLogadoId } }, status: CandidaturaStatus.ACEITA },
          relations: ["aluno", "aluno.usuario"]
        });
      } else if (perfilLogado === UsuarioPerfil.EMPRESA) {
        count = await candidaturaRepository.count({
          where: { vaga: { empresa: { usuario: { id: usuarioLogadoId } } }, status: CandidaturaStatus.ACEITA },
          relations: ["vaga", "vaga.empresa", "vaga.empresa.usuario"]
        });
      }

      return res.status(200).json({ total: count });
    } catch (error) {
      return res.status(500).json({ message: "Erro ao contar chats", total: 0 });
    }
  }

  static async listarChats(req: Request, res: Response) {
    try {
      const usuarioLogadoId = (req as any).usuarioId;
      const perfilLogado = (req as any).usuarioPerfil;
      const candidaturaRepository = AppDataSource.getRepository(Candidatura);
      const mensagemRepository = AppDataSource.getRepository(Mensagem);

      let candidaturas: Candidatura[] = [];

      if (perfilLogado === UsuarioPerfil.ALUNO) {
        candidaturas = await candidaturaRepository.find({
          where: { aluno: { usuario: { id: usuarioLogadoId } }, status: CandidaturaStatus.ACEITA },
          relations: ["vaga", "vaga.empresa", "vaga.empresa.usuario"]
        });
      } else if (perfilLogado === UsuarioPerfil.EMPRESA) {
        candidaturas = await candidaturaRepository.find({
          where: { vaga: { empresa: { usuario: { id: usuarioLogadoId } } }, status: CandidaturaStatus.ACEITA },
          relations: ["vaga", "aluno", "aluno.usuario"]
        });
      }

      const chats = await Promise.all(candidaturas.map(async (cand) => {
        // Pegar a última mensagem do chat
        const ultimaMsg = await mensagemRepository.findOne({
          where: { candidatura_id: cand.id },
          order: { enviado_em: "DESC" }
        });

        let nomeContato = "";
        if (perfilLogado === UsuarioPerfil.ALUNO) {
          // 🛠️ CORRIGIDO: Removido o fallback '.nome' que o TS reclamou
          nomeContato = cand.vaga.empresa?.usuario?.nome_exibicao || "Empresa";
        } else {
          // 🛠️ CORRIGIDO: Removido o fallback '.nome' que o TS reclamou
          nomeContato = cand.aluno?.usuario?.nome_exibicao || "Aluno";
        }

        return {
          candidatura_id: cand.id,
          vaga_titulo: cand.vaga.titulo,
          usuario_id: usuarioLogadoId,
          nome_contato: nomeContato,
          ultima_mensagem: ultimaMsg ? ultimaMsg.conteudo : "O chat foi liberado. Inicie a conversa!",
          data_ultima_mensagem: ultimaMsg ? ultimaMsg.enviado_em : cand.data_candidatura,
          nao_lidas: 0 
        };
      }));

      // Ordenar pelas mensagens mais recentes
      chats.sort((a, b) => new Date(b.data_ultima_mensagem).getTime() - new Date(a.data_ultima_mensagem).getTime());

      return res.status(200).json(chats);
    } catch (error) {
      return res.status(500).json({ message: "Erro ao listar conversas" });
    }
  }
}