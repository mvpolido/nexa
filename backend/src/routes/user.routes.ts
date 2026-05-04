import { Router } from "express";
import { UserController } from "../controllers/UserController";
import { PerfilController } from "../controllers/PerfilController"; // Importe o novo controller
import { uploadConfig } from "../config/multer"; // Importe a configuração do multer

const router = Router();

// Rotas do CRUD
router.post("/", UserController.create);
router.get("/", UserController.getAll);
router.get("/:id", UserController.getById);
router.put("/:id", UserController.update);
router.delete("/:id", UserController.delete);

// Nova rota para completar o perfil do Aluno (Upload de PDF + Skills)
// O campo no formulário deve se chamar 'curriculo'
router.patch("/:id/perfil", uploadConfig.single("curriculo"), PerfilController.update);

export default router;