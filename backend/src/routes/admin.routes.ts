import { Router } from "express";
import { AdminController } from "../controllers/AdminController";
import { authMiddleware } from "../middlewares/authMiddleware";
import { adminMiddleware } from "../middlewares/adminMiddleware";

const adminRoutes = Router();

// Aplica os middlewares de segurança para todas as rotas deste arquivo
adminRoutes.use(authMiddleware, adminMiddleware);

adminRoutes.get("/dashboard/stats", AdminController.dashboardStats);

adminRoutes.get("/usuarios", AdminController.listarUsuarios);
adminRoutes.delete("/usuarios/:id", AdminController.deletarUsuario);

adminRoutes.get("/empresas", AdminController.listarEmpresas);
adminRoutes.patch("/empresas/:id/verificar", AdminController.verificarEmpresa);

adminRoutes.get("/vagas", AdminController.listarVagas);
adminRoutes.delete("/vagas/:id", AdminController.deletarVaga);

adminRoutes.get("/habilidades", AdminController.listarHabilidades);
adminRoutes.post("/habilidades", AdminController.criarHabilidade);
adminRoutes.patch("/habilidades/:id", AdminController.atualizarHabilidade);
adminRoutes.delete("/habilidades/:id", AdminController.deletarHabilidade);

export default adminRoutes;
