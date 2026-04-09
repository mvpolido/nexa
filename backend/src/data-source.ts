import "reflect-metadata";
import { DataSource } from "typeorm";
import { User } from "./entities/User"; // Adicione este import manual

export const AppDataSource = new DataSource({
    type: "postgres",
    host: "db",
    port: 5432,
    username: "nexa_user",
    password: "nexa_password",
    database: "nexa_db",
    synchronize: true, // Garante que a tabela seja criada
    logging: true,
    entities: [User], // Coloque a classe diretamente aqui
    migrations: [],
    subscribers: [],
});