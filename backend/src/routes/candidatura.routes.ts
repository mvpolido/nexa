import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware";
import { CandidaturaController } from "../controllers/CandidaturaController";

const router = Router();

router.post(
  "/vagas/:id/candidatar",
  authMiddleware,
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

export default router;