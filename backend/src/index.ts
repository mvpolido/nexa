import cors from "cors";
import "reflect-metadata";
import express from 'express';
import swaggerUi from 'swagger-ui-express';
import path from "path"; // 👈 1. Importação necessária para lidar com caminhos
import { AppDataSource } from "./data-source";
import { swaggerSpec } from './swagger';

// Importação das rotas
import healthRoutes from './routes/health.routes';
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes'; 
import vagaRoutes from './routes/vaga.routes';
import habilidadeRoutes from './routes/habilidade.routes';
import { empresaRoutes } from './routes/empresa.routes';
import candidaturaRoutes from './routes/candidatura.routes';

const app = express();
app.use(cors({
  origin: '*', 
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true
}));
app.use(express.json());


app.use('/files', express.static(path.resolve(__dirname, '..', 'uploads')));

app.use('/empresas', empresaRoutes);

// Rota raiz para teste rápido de vida da API
app.get('/', (req, res) => {
  res.send('API Nexa rodando!');
});

// Configuração do Swagger
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Aplicação das rotas
app.use(healthRoutes);
app.use('/auth', authRoutes);
app.use('/users', userRoutes); 
app.use('/vagas', vagaRoutes);
app.use('/habilidades', habilidadeRoutes);
app.use(candidaturaRoutes);

const startServer = async () => {
  let retries = 5;
  while (retries > 0) {
    try {
      // Inicialização do Banco de Dados (TypeORM)
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
      // console.error("Detalhe do erro:", error); // Removido o excesso de log se quiser limpar o terminal
      if (retries === 0) {
        console.error("FALHA CRÍTICA: Não foi possível conectar ao banco de dados.");
        process.exit(1);
      }
      // Espera 5 segundos antes de tentar novamente
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
};

startServer();