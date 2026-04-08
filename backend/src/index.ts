import express from 'express';
import healthRoutes from './routes/health.routes';
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';

import { swaggerSpec } from './swagger';
import swaggerUi from 'swagger-ui-express';

const app = express();

app.use(express.json());

// Rota raiz para teste rápido
app.get('/', (req, res) => {
  res.send('API Nexa rodando!');
});

// Configuração do Swagger - PRECISA VIR ANTES DAS ROTAS SE POSSÍVEL
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Registro das Rotas
app.use(healthRoutes);
app.use('/auth', authRoutes);
app.use('/users', userRoutes);

app.listen(3000, () => {
  console.log('Servidor rodando em http://localhost:3000');
  console.log('Documentação em http://localhost:3000/docs');
});