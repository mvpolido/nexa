import { Router } from "express";
import { HabilidadeController } from "../controllers/HabilidadeController";

const router = Router();
router.get("/", HabilidadeController.getAll);
router.post("/", HabilidadeController.create);
export default router;