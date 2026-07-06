import { Router } from "express";
import { HabilidadeController } from "../controllers/HabilidadeController";
import { authMiddleware } from "../middlewares/authMiddleware";
import { adminMiddleware } from "../middlewares/adminMiddleware";

const router = Router();

router.get("/", HabilidadeController.getAll);
router.post("/", authMiddleware, adminMiddleware, HabilidadeController.create);
router.post("/seed", authMiddleware, adminMiddleware, HabilidadeController.seed);
router.patch("/:id", authMiddleware, adminMiddleware, HabilidadeController.update);
router.delete("/:id", authMiddleware, adminMiddleware, HabilidadeController.delete);

export default router;
