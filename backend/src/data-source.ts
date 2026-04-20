import "reflect-metadata";
import { DataSource } from "typeorm";
import { Usuario } from "./entities/Usuario";
import { Aluno } from "./entities/Aluno";
import { Empresa } from "./entities/Empresa";

export const AppDataSource = new DataSource({
    type: "postgres",
    host: process.env.POSTGRES_HOST || "db",
    port: parseInt(process.env.POSTGRES_PORT || "5432"),
    username: process.env.POSTGRES_USER || "nexa_user",
    password: process.env.POSTGRES_PASSWORD || "nexa",
    database: process.env.POSTGRES_DB || "nexa_db",
    synchronize: true,
    logging: true,
    entities: [Usuario, Aluno, Empresa],
    migrations: [],
    subscribers: [],
});