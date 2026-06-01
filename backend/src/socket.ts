import { Server as SocketIOServer } from "socket.io";
import { Server as HttpServer } from "http";
import { AppDataSource } from "./data-source";
import { Mensagem } from "./entities/Mensagem";

let io: SocketIOServer;

export const initializeSocket = (httpServer: HttpServer) => {
  io = new SocketIOServer(httpServer, {
    cors: {
      origin: "*", 
      methods: ["GET", "POST"],
      credentials: true
    }
  });

  io.on("connection", (socket) => {
    console.log(`🔌 Novo cliente conectado: ${socket.id}`);

    socket.on("join_chat", (data: { candidaturaId: number }) => {
      const room = `chat_${data.candidaturaId}`;
      socket.join(room);
      console.log(`👤 Usuário ${socket.id} entrou na sala ${room}`);
    });

    // 🛠️ AGORA SALVAMOS A MENSAGEM NO BANCO ANTES DE REPASSAR!
    socket.on("send_message", async (data: { candidaturaId: number, remetente_id: number, conteudo: string }) => {
      const room = `chat_${data.candidaturaId}`;
      
      try {
        const mensagemRepository = AppDataSource.getRepository(Mensagem);
        
        const novaMensagem = mensagemRepository.create({
          candidatura_id: data.candidaturaId,
          remetente_id: data.remetente_id,
          conteudo: data.conteudo
        });
        
        const mensagemSalva = await mensagemRepository.save(novaMensagem);

        // Repassa a mensagem salva para todos na sala (incluindo a data oficial do banco)
        io.to(room).emit("receive_message", {
          id: mensagemSalva.id,
          candidatura_id: mensagemSalva.candidatura_id,
          remetente_id: mensagemSalva.remetente_id,
          conteudo: mensagemSalva.conteudo,
          enviado_em: mensagemSalva.enviado_em.toISOString()
        });
      } catch (error) {
        console.error("❌ Erro ao salvar mensagem no socket:", error);
      }
    });

    socket.on("disconnect", () => {
      console.log(`🔌 Cliente desconectado: ${socket.id}`);
    });
  });

  return io;
};

export const getIO = () => {
  if (!io) {
    throw new Error("Socket.io não inicializado!");
  }
  return io;
};