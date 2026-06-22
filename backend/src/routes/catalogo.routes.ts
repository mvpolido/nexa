import { Router } from "express";
import { CatalogoController } from "../controllers/CatalogoController";

const catalogoRoutes = Router();

catalogoRoutes.get("/instituicoes", CatalogoController.listarInstituicoesPublico);
catalogoRoutes.get("/cursos", CatalogoController.listarCursosPublico);

export default catalogoRoutes;
