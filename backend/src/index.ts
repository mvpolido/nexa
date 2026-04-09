import "reflect-metadata";
import express from 'express';
import swaggerUi from 'swagger-ui-express';
import { AppDataSource } from "./data-source";
import { swaggerSpec } from './swagger';
import healthRoutes from './routes/health.routes';
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes';

const app = express();
app.use(express.json());

app.get('/', (req, res) => {
  res.send('API Nexa rodando!');
});

app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.use(healthRoutes);
app.use('/auth', authRoutes);
app.use('/users', userRoutes);

const startServer = async () => {
  let retries = 5;
  while (retries > 0) {
    try {
      await AppDataSource.initialize();
      console.log("✅ Banco de dados conectado com sucesso!");
      
      app.listen(3000, () => {
        console.log("🚀 Servidor rodando em http://localhost:3000");
        console.log("📄 Documentação em http://localhost:3000/docs");
      });
      break; 
    } catch (error) {
      retries--;
      console.error(`❌ Erro na conexão com o banco. Tentativas restantes: ${retries}`);
      if (retries === 0) process.exit(1);
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
};

startServer();