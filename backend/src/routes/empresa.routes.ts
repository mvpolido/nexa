import { Router } from 'express';
import { EmpresaController } from '../controllers/EmpresaController';

const empresaRoutes = Router();
const empresaController = new EmpresaController();

// Rota para criar/validar uma empresa
empresaRoutes.post('/', empresaController.create.bind(empresaController));

export { empresaRoutes };