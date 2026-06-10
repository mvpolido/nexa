import { Router } from "express";
import { UserController } from "../controllers/UserController";
import { PerfilController } from "../controllers/PerfilController"; // Importe o novo controller
import { uploadConfig } from "../config/multer"; // Importe a configuração do multer
import { authMiddleware } from "../middlewares/authMiddleware";
import { adminMiddleware } from "../middlewares/adminMiddleware";

const router = Router();

// Rotas do CRUD
router.post("/", UserController.create);
router.get("/", authMiddleware, adminMiddleware, UserController.getAll);
router.get("/:id", authMiddleware, adminMiddleware, UserController.getById);
router.put("/:id", authMiddleware, adminMiddleware, UserController.update);
router.delete("/:id", authMiddleware, adminMiddleware, UserController.delete);

// Nova rota para completar o perfil do Aluno (Upload de PDF + Skills)
// O campo no formulário deve se chamar 'curriculo'
router.patch("/:id/perfil", uploadConfig.single("curriculo"), PerfilController.update);

export default router;