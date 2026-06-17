import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware";
import { CandidaturaController } from "../controllers/CandidaturaController";
import { uploadConfig } from "../config/multer"; // NOVO: Importa o multer configurado

const router = Router();

router.post(
  "/vagas/:id/candidatar",
  authMiddleware,
  uploadConfig.single("curriculo"), // NOVO: Intercepta o upload do PDF (campo 'curriculo')
  CandidaturaController.candidatar
);

router.get(
  "/alunos/me/candidaturas",
  authMiddleware,
  CandidaturaController.minhasCandidaturas
);

router.get(
  "/vagas/:id/candidaturas",
  authMiddleware,
  CandidaturaController.candidaturasDaVaga
);

router.patch(
  "/candidaturas/:id/status",
  authMiddleware,
  CandidaturaController.atualizarStatus
);

// NOVO: Rota para listar o histórico de mensagens do chat
router.get(
  "/candidaturas/:id/mensagens",
  authMiddleware,
  CandidaturaController.listarMensagens
);

router.get(
  "/candidaturas/:id/curriculo",
  authMiddleware,
  CandidaturaController.curriculoDaCandidatura
);

export default router;
