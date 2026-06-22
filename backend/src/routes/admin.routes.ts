import { Router } from "express";
import { AdminController } from "../controllers/AdminController";
import { CatalogoController } from "../controllers/CatalogoController";
import { authMiddleware } from "../middlewares/authMiddleware";
import { adminMiddleware } from "../middlewares/adminMiddleware";

const adminRoutes = Router();

// Aplica os middlewares de segurança para todas as rotas deste arquivo
adminRoutes.use(authMiddleware, adminMiddleware);

adminRoutes.get("/dashboard/stats", AdminController.dashboardStats);

adminRoutes.get("/usuarios", AdminController.listarUsuarios);
adminRoutes.get("/usuarios/:id", AdminController.obterUsuario);
adminRoutes.delete("/usuarios/:id", AdminController.deletarUsuario);

adminRoutes.get("/empresas", AdminController.listarEmpresas);
adminRoutes.get(
  "/empresas/:id/documento-verificacao",
  AdminController.documentoVerificacaoEmpresa
);
adminRoutes.patch(
  "/empresas/:id/verificacao",
  AdminController.decidirVerificacaoEmpresa
);
adminRoutes.patch("/empresas/:id/verificar", AdminController.verificarEmpresa);
adminRoutes.get("/empresas/:id", AdminController.obterEmpresa);

adminRoutes.get("/vagas", AdminController.listarVagas);
adminRoutes.delete("/vagas/:id", AdminController.deletarVaga);

adminRoutes.get("/habilidades", AdminController.listarHabilidades);
adminRoutes.post("/habilidades", AdminController.criarHabilidade);
adminRoutes.patch("/habilidades/:id", AdminController.atualizarHabilidade);
adminRoutes.delete("/habilidades/:id", AdminController.deletarHabilidade);

adminRoutes.get("/instituicoes", CatalogoController.listarInstituicoesAdmin);
adminRoutes.post("/instituicoes", CatalogoController.criarInstituicao);
adminRoutes.patch("/instituicoes/:id", CatalogoController.atualizarInstituicao);
adminRoutes.delete("/instituicoes/:id", CatalogoController.deletarInstituicao);

adminRoutes.get("/cursos", CatalogoController.listarCursosAdmin);
adminRoutes.post("/cursos", CatalogoController.criarCurso);
adminRoutes.patch("/cursos/:id", CatalogoController.atualizarCurso);
adminRoutes.delete("/cursos/:id", CatalogoController.deletarCurso);

export default adminRoutes;
