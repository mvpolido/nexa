import { Router } from "express";
import { AlunoController } from "../controllers/AlunoController";
import { authMiddleware } from "../middleware/auth";

const router = Router();

// Rotas protegidas (requerem autenticação)
router.get("/me", authMiddleware, AlunoController.getMe);
router.put("/me", authMiddleware, AlunoController.updateMe);

// Rota pública (buscar perfil de outro aluno)
router.get("/:id", AlunoController.getById);

export default router;
