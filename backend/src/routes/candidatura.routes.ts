import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware";
import { CandidaturaController } from "../controllers/CandidaturaController";
import { AlunoController } from "../controllers/AlunoController";
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

router.get(
  "/alunos/me",
  authMiddleware,
  AlunoController.meuPerfil
);

router.put(
  "/alunos/me/habilidades",
  authMiddleware,
  AlunoController.atualizarHabilidades
);

export default router;