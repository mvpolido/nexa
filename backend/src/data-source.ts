import "reflect-metadata";
import { DataSource } from "typeorm";

export const AppDataSource = new DataSource({
    type: "postgres",
    host: "db", // Nome do serviço no seu docker-compose
    port: 5432,
    username: "nexa_user",
    password: "nexa_password",
    database: "nexa_db",
    synchronize: true, // CUIDADO: Em produção deve ser false. Aqui ele cria as tabelas sozinho.
    logging: true,
    entities: ["src/entities/*.ts"],
    migrations: ["src/migrations/*.ts"],
    subscribers: [],
});