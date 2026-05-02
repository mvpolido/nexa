import "reflect-metadata";
import { DataSource } from "typeorm";
import { Usuario } from "./entities/Usuario";
import { Aluno } from "./entities/Aluno";
import { Empresa } from "./entities/Empresa";
import { Vaga } from "./entities/Vaga"; // 👈 1. Importe a entidade Vaga

export const AppDataSource = new DataSource({
    type: "postgres",
    // 2. Altere o padrão para "nexa_db" se esse for o nome no seu docker-compose
    host: process.env.DB_HOST || "nexa_db", 
    port: parseInt(process.env.DB_PORT || "5432"),
    username: process.env.DB_USER || "nexa_user",
    password: process.env.DB_PASS || "nexa_password",
    database: process.env.DB_NAME || "nexa_db",
    synchronize: true, // Isso vai criar a tabela 'vagas' automaticamente agora
    logging: true,
    entities: [Usuario, Aluno, Empresa, Vaga], // 👈 3. Adicione Vaga aqui
    migrations: [],
    subscribers: [],
});