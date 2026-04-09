import express from 'express';
import healthRoutes from './routes/health.routes';
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';

import { swaggerSpec } from './swagger';
import swaggerUi from 'swagger-ui-express';

const app = express();

app.use(express.json());

// 1. Configuração do Swagger (Sempre antes das rotas)
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// 2. Rota raiz para teste rápido
app.get('/', (req, res) => {
  res.send('API Nexa rodando!');
});

// 3. Registro das Rotas (Aqui mantemos as suas rotas novas)
app.use(healthRoutes);
app.use('/auth', authRoutes);
app.use('/users', userRoutes);

// 4. Iniciar o servidor
app.listen(3000, () => {
  console.log('Servidor rodando em http://localhost:3000');
  console.log('Documentação em http://localhost:3000/docs');
});