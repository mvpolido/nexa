import { Router } from "express";
import { HabilidadeController } from "../controllers/HabilidadeController";
import { authMiddleware } from "../middlewares/authMiddleware";

const router = Router();

router.get("/", authMiddleware, HabilidadeController.getAll);
router.post("/", authMiddleware, HabilidadeController.create);
router.post("/seed", authMiddleware, HabilidadeController.seed);

export default router;
