import { Router } from "express";
import { authMiddleware } from "../middlewares/authMiddleware";
import { ChatController } from "../controllers/ChatController";

const router = Router();

router.get("/chats", authMiddleware, ChatController.listarChats);
router.get("/chats/contagem", authMiddleware, ChatController.contagemChats);

export default router;