import { Router } from "express";
import { EmpresaController } from "../controllers/EmpresaController";
import { authMiddleware } from "../middleware/auth";

const router = Router();

router.get("/me", authMiddleware, EmpresaController.getMe);
router.put("/me", authMiddleware, EmpresaController.updateMe);

export default router;
