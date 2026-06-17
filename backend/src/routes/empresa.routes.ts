import { Router } from 'express';
import { EmpresaController } from '../controllers/EmpresaController';
import { authMiddleware } from '../middlewares/authMiddleware';

const empresaRoutes = Router();
const empresaController = new EmpresaController();

// Rota para criar/validar uma empresa
empresaRoutes.post('/', empresaController.create.bind(empresaController));

// Rotas de perfil da empresa (Issue #88)
empresaRoutes.get('/me', authMiddleware, empresaController.getMe.bind(empresaController));
empresaRoutes.get('/me/dashboard', authMiddleware, empresaController.dashboard.bind(empresaController));
empresaRoutes.put('/me', authMiddleware, empresaController.updateMe.bind(empresaController));
empresaRoutes.get('/candidatos/:alunoId/perfil', authMiddleware, empresaController.perfilCandidato.bind(empresaController));

// 🛠️ ROTAS DO ESTUDANTE (Para ver e avaliar o perfil da empresa via Chat)
empresaRoutes.get('/by-candidatura/:candidaturaId', authMiddleware, empresaController.getByCandidatura.bind(empresaController));
empresaRoutes.post('/avaliar', authMiddleware, empresaController.avaliar.bind(empresaController));

export { empresaRoutes };
