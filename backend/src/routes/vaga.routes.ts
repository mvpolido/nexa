import { Router } from "express";
import { VagaController } from "../controllers/VagaController";
import { authMiddleware } from "../middlewares/authMiddleware";

const router = Router();

// 1. Qualquer usuário logado pode listar (GET)
router.get("/", authMiddleware, VagaController.getAll);
router.get("/:id", authMiddleware, VagaController.getById);

// 2. Apenas Empresa pode criar, editar ou deletar (POST, PUT, DELETE)
router.post("/", authMiddleware, VagaController.create);
router.put("/:id", authMiddleware, VagaController.update);
router.delete("/:id", authMiddleware, VagaController.delete);

export default router;