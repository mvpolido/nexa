import { Router } from "express";
import { AlunoController } from "../controllers/AlunoController";
import { authMiddleware } from "../middlewares/authMiddleware";
import { uploadConfig } from "../config/multer";

const router = Router();

// Rota para buscar o perfil completo do aluno logado
router.get("/me", authMiddleware, AlunoController.meuPerfil);

// Rota para atualizar os dados gerais do perfil (Nome, Curso, CEP, etc.)
router.put("/me", authMiddleware, AlunoController.atualizarPerfil);

// Rota para atualizar especificamente as habilidades do aluno
router.put(
  "/me/habilidades",
  authMiddleware,
  AlunoController.atualizarHabilidades
);

router.put(
  "/me/curriculo",
  authMiddleware,
  (req, res, next) => {
    uploadConfig.single("curriculo")(req, res, (error: any) => {
      if (error) {
        return res.status(400).json({
          message: error.message || "Erro ao enviar currículo.",
        });
      }

      return next();
    });
  },
  AlunoController.atualizarCurriculo
);

router.get("/me/curriculo", authMiddleware, AlunoController.meuCurriculo);
router.get("/:id/curriculo", authMiddleware, AlunoController.curriculoPorAluno);

export default router;
