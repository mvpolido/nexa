import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware";
import { ChatController } from "../controllers/ChatController";

const router = Router();

router.get("/chats", authMiddleware, ChatController.listarChats);
router.get("/chats/contagem", authMiddleware, ChatController.contagemChats);
// NOVA ROTA
router.get("/chats/:candidaturaId/perfil-aluno", authMiddleware, ChatController.getPerfilAluno);

export default router;