import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany
} from "typeorm";
import { AlunoHabilidade } from "./AlunoHabilidade";
import { VagaHabilidade } from "./VagaHabilidade";

@Entity("habilidade")
export class Habilidade {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ type: "varchar", length: 100, unique: true, nullable: false })
  nome!: string;

  // Relacionamento N:M com Aluno (via tabela intermediária)
  @OneToMany(() => AlunoHabilidade, ah => ah.habilidade)
  alunoHabilidades?: AlunoHabilidade[];

  // Relacionamento N:M com Vaga (via tabela intermediária)
  @OneToMany(() => VagaHabilidade, vh => vh.habilidade)
  vagaHabilidades?: VagaHabilidade[];
}
