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

export const AppDataSource = new DataSource({
    type: "postgres",
    host: process.env.DB_HOST || "db",
    port: parseInt(process.env.DB_PORT || "5432"),
    username: process.env.DB_USER || "nexa_user",
    password: process.env.DB_PASS || "nexa_password",
    database: process.env.DB_NAME || "nexa_db",
    synchronize: true,
    logging: true,
    entities: [Usuario, Aluno, Empresa, Habilidade, Vaga, Candidatura, Mensagem, Avaliacao, AlunoHabilidade, VagaHabilidade],
    migrations: [],
    subscribers: [],
});