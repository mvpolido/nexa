import { Router } from "express";
import { AlunoController } from "../controllers/AlunoController";
import { authMiddleware } from "../middlewares/authMiddleware";

const router = Router();

// Rota para buscar o perfil completo do aluno logado
router.get("/me", authMiddleware, AlunoController.meuPerfil);

// Rota para atualizar os dados gerais do perfil (Nome, Curso, CEP, etc.)
router.put("/me", authMiddleware, AlunoController.atualizarPerfil);

// Rota para atualizar especificamente as habilidades do aluno
router.put(
  "/me/habilidades",
  authMiddleware,
  AlunoController.atualizarHabilidades
);

export default router;