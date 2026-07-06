import cors from "cors";
import "reflect-metadata";
import express from 'express';
import swaggerUi from 'swagger-ui-express';
import path from "path";
import { createServer } from "http"; // 👈 Importação para o Socket
import { AppDataSource } from "./data-source";
import { swaggerSpec } from './swagger';

// Importação do Socket 
import { initializeSocket } from "./socket"; // 👈 Nosso novo arquivo

// Importação das rotas
import healthRoutes from './routes/health.routes';
import authRoutes from './routes/auth.routes';
import userRoutes from './routes/user.routes'; 
import vagaRoutes from './routes/vaga.routes';
import habilidadeRoutes from './routes/habilidade.routes';
import alunoRoutes from './routes/aluno.routes';
import { empresaRoutes } from './routes/empresa.routes';
import candidaturaRoutes from './routes/candidatura.routes';
import chatRoutes from "./routes/chat.routes"; // 👈 Importação da rota de chat
import notificacaoRoutes from './routes/notificacao.routes';
import adminRoutes from './routes/admin.routes';
import enderecoRoutes from './routes/endereco.routes';
import catalogoRoutes from './routes/catalogo.routes';

const app = express();

// O Segredo: O Express é passado para o servidor HTTP nativo
const httpServer = createServer(app); 

app.use(cors({
  origin: '*', 
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true
}));
app.use(express.json());

app.use('/files', express.static(path.resolve(__dirname, '..', 'uploads')));
app.use('/empresas', empresaRoutes);

app.get('/', (req, res) => {
  res.send('API Nexa rodando com Socket.io!');
});

app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.use(healthRoutes);
app.use('/auth', authRoutes);
app.use(catalogoRoutes);
app.use('/users', userRoutes); 
app.use('/vagas', vagaRoutes);
app.use('/habilidades', habilidadeRoutes);
app.use('/alunos', alunoRoutes);
app.use('/notificacoes', notificacaoRoutes);
app.use('/admin', adminRoutes);
app.use('/enderecos', enderecoRoutes);
app.use(candidaturaRoutes);
app.use(chatRoutes); // 🛠️ O QUE FALTAVA: Registro da rota para o Express reconhecer!

const startServer = async () => {
  let retries = 5;
  while (retries > 0) {
    try {
      await AppDataSource.initialize();
      console.log("✅ Banco de dados conectado com sucesso!");
      
      // Inicializamos o socket passando o servidor HTTP
      initializeSocket(httpServer);
      
      // ATENÇÃO: Agora chamamos listen() no httpServer, e não no app!
      httpServer.listen(3000, () => {
        console.log("🚀 Servidor HTTP/Socket rodando em http://localhost:3000");
        console.log("📄 Documentação em http://localhost:3000/docs");
      });
      break; 
    } catch (error) {
      retries--;
      console.error(`❌ Erro na conexão com o banco. Tentativas restantes: ${retries}`);
      if (retries === 0) {
        console.error("FALHA CRÍTICA: Não foi possível conectar ao banco de dados.");
        process.exit(1);
      }
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
};

startServer();
