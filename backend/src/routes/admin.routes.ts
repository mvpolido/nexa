import { Router } from "express";
import { AdminController } from "../controllers/AdminController";
import { UserController } from "../controllers/UserController";
import { authMiddleware } from "../middlewares/authMiddleware";
import { adminMiddleware } from "../middlewares/adminMiddleware";

const adminRoutes = Router();

// Aplica os middlewares de segurança para todas as rotas deste arquivo
adminRoutes.use(authMiddleware, adminMiddleware);

// 1. Estatísticas para os botões do Dashboard do Moderador
adminRoutes.get("/dashboard/stats", async (req, res) => {
  try {
    const { AppDataSource } = require("../data-source");
    const { Empresa } = require("../entities/Empresa");
    const { Aluno } = require("../entities/Aluno");
    const { Habilidade } = require("../entities/Habilidade");
    const { Vaga } = require("../entities/Vaga");

    const totalEmpresas = await AppDataSource.getRepository(Empresa).count();
    const totalAlunos = await AppDataSource.getRepository(Aluno).count();
    const totalHabilidades = await AppDataSource.getRepository(Habilidade).count();
    const totalVagas = await AppDataSource.getRepository(Vaga).count();

    return res.json({
      empresas: totalEmpresas,
      alunos: totalAlunos,
      habilidades: totalHabilidades,
      vagasTotais: totalVagas,
    });
  } catch (error: any) {
    return res.status(500).json({ message: "Erro no dashboard", error: error.message });
  }
});

adminRoutes.patch("/empresas/:id/verificar", AdminController.verificarEmpresa);

adminRoutes.get("/vagas", AdminController.listarVagas);
adminRoutes.delete("/vagas/:id", AdminController.deletarVaga);

adminRoutes.post("/usuarios/admin", UserController.createAdmin);
adminRoutes.delete("/usuarios/:id", AdminController.deletarUsuario);

adminRoutes.post("/habilidades", AdminController.criarHabilidade);
adminRoutes.delete("/habilidades/:id", AdminController.deletarHabilidade);

export default adminRoutes;