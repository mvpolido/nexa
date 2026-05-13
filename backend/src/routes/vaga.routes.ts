import { Router } from "express";
import { VagaController } from "../controllers/VagaController";
import { authMiddleware } from "../middlewares/authMiddleware";

const router = Router();

router.get("/", authMiddleware, VagaController.getAll);
router.get("/:id", authMiddleware, VagaController.getById);

router.post("/", authMiddleware, VagaController.create);
router.put("/:id", authMiddleware, VagaController.update);

router.patch("/:id/arquivar", authMiddleware, VagaController.archive);
router.patch("/:id/desarquivar", authMiddleware, VagaController.unarchive);

// Mantido por compatibilidade: DELETE agora apenas arquiva.
router.delete("/:id", authMiddleware, VagaController.delete);

export default router;