import { Router } from "express";
import { AlunoController } from "../controllers/AlunoController";
import { authMiddleware } from "../middlewares/authMiddleware";

const router = Router();

router.get("/me", authMiddleware, AlunoController.meuPerfil);

router.put(
  "/me/habilidades",
  authMiddleware,
  AlunoController.atualizarHabilidades
);

export default router;
