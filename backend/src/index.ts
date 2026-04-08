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

// 1. Rota raiz para teste rápido
app.get('/', (req, res) => {
  res.send('API Nexa rodando!');
});

// 2. Configuração do Swagger
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// 3. Registro das Rotas
app.use(healthRoutes);
app.use('/auth', authRoutes);
app.use('/users', userRoutes);

// 4. Função para conectar ao banco com tentativas automáticas (Retry)
const startServer = async () => {
  let retries = 5;
  while (retries > 0) {
    try {
      await AppDataSource.initialize();
      console.log("✅ Banco de dados conectado com sucesso!");
      
      // Só inicia o servidor se o banco conectar
      app.listen(3000, () => {
        console.log("🚀 Servidor rodando em http://localhost:3000");
        console.log("📄 Documentação em http://localhost:3000/docs");
      });
      break; // Sai do loop se conectar
    } catch (error) {
      retries--;
      console.error(`❌ Erro na conexão com o banco. Tentativas restantes: ${retries}`);
      console.error(error);
      
      if (retries === 0) {
        console.error("FALHA CRÍTICA: Não foi possível conectar ao banco de dados após várias tentativas.");
        process.exit(1);
      }

      // Espera 5 segundos antes de tentar de novo
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
};

startServer();