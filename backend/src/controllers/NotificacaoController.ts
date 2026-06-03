import { Request, Response } from "express";
import { AppDataSource } from "../data-source";
import { Notificacao } from "../entities/Notificacao";

export class NotificacaoController {
  static async listar(req: Request, res: Response) {
    try {
      const usuarioId = (req as any).usuarioId;
      const notificacaoRepository = AppDataSource.getRepository(Notificacao);

      const notificacoes = await notificacaoRepository.find({
        where: { usuario_id: usuarioId },
        order: { data_criacao: "DESC" }
      });

      return res.status(200).json(notificacoes);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao listar notificações.",
        error: error.message
      });
    }
  }

  static async marcarComoLida(req: Request, res: Response) {
    try {
      const usuarioId = (req as any).usuarioId;
      const notificacaoId = Number(req.params.id);
      const notificacaoRepository = AppDataSource.getRepository(Notificacao);

      const notificacao = await notificacaoRepository.findOne({
        where: {
          id: notificacaoId,
          usuario_id: usuarioId
        }
      });

      if (!notificacao) {
        return res.status(404).json({ message: "Notificação não encontrada." });
      }

      notificacao.lida = true;

      const notificacaoAtualizada = await notificacaoRepository.save(notificacao);

      return res.status(200).json(notificacaoAtualizada);
    } catch (error: any) {
      return res.status(500).json({
        message: "Erro ao marcar notificação como lida.",
        error: error.message
      });
    }
  }
}
