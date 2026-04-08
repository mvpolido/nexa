import express from 'express';
import swaggerUi from 'swagger-ui-express';
import { swaggerSpec } from './swagger';
import healthRoutes from './routes/health.routes';

const app = express();

app.use(express.json());

// 1. Swagger primeiro (boa prática)
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// 2. Rotas simples
app.get('/', (req, res) => {
  res.send('API rodando hehehe');
});

// 3. Suas rotas importadas
app.use(healthRoutes);

// 4. Iniciar o servidor
app.listen(3000, () => {
  console.log('Servidor rodando em http://localhost:3000');
  console.log('Documentação disponível em http://localhost:3000/docs');
});