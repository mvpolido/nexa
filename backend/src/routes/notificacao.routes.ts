import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware";
import { NotificacaoController } from "../controllers/NotificacaoController";

const router = Router();

router.get("/", authMiddleware, NotificacaoController.listar);
router.patch("/:id/lida", authMiddleware, NotificacaoController.marcarComoLida);

export default router;
