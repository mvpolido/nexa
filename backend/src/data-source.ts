import "reflect-metadata";
import { DataSource } from "typeorm";
import { Usuario } from "./entities/Usuario";
import { Aluno } from "./entities/Aluno";
import { Empresa } from "./entities/Empresa";
import { Habilidade } from "./entities/Habilidade";
import { Vaga } from "./entities/Vaga";
import { Candidatura } from "./entities/Candidatura";
import { Mensagem } from "./entities/Mensagem";
import { Avaliacao } from "./entities/Avaliacao";
import { AlunoHabilidade } from "./entities/AlunoHabilidade";
import { VagaHabilidade } from "./entities/VagaHabilidade";
import { Notificacao } from "./entities/Notificacao";
import { Curso } from "./entities/Curso";
import { InstituicaoEnsino } from "./entities/InstituicaoEnsino";

export const AppDataSource = new DataSource({
    type: "postgres",
    // Mantendo a configuração de host que funcionou no seu Docker
    host: process.env.DB_HOST || "nexa_db", 
    port: parseInt(process.env.DB_PORT || "5432"),
    username: process.env.DB_USER || "nexa_user",
    password: process.env.DB_PASS || "nexa_password",
    database: process.env.DB_NAME || "nexa_db",
    synchronize: true, // Isso criará todas as novas tabelas automaticamente
    logging: true,
    entities: [
      Usuario, 
      Aluno, 
      Empresa, 
      Habilidade, 
      Vaga, 
      Candidatura, 
      Mensagem, 
      Avaliacao, 
      AlunoHabilidade, 
      VagaHabilidade,
      Notificacao,
      Curso,
      InstituicaoEnsino
    ],
    migrations: [],
    subscribers: [],
});
