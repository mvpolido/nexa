import express from 'express';
import swaggerUi from 'swagger-ui-express';
import { swaggerSpec } from './swagger';
import healthRoutes from './routes/health.routes';

const app = express();

app.use(express.json());

app.get('/', (req, res) => {
  res.send('API rodando hehehe');
});

app.listen(3000, () => {
  console.log('Servidor rodando em http://localhost:3000');
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.use(healthRoutes);