import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany
} from "typeorm";
import { AlunoHabilidade } from "./AlunoHabilidade";
import { VagaHabilidade } from "./VagaHabilidade";

export enum HabilidadeArea {
  TECNOLOGIA = "TECNOLOGIA",
  ENGENHARIA = "ENGENHARIA",
  EXATAS = "EXATAS",
  SAUDE = "SAUDE",
  QUIMICA = "QUIMICA",
  FISICA = "FISICA",
  BIOLOGIA = "BIOLOGIA",
  COMUNICACAO = "COMUNICACAO",
  GESTAO = "GESTAO",
  DESIGN = "DESIGN"
}

@Entity("habilidade")
export class Habilidade {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ type: "varchar", length: 100, unique: true, nullable: false })
  nome!: string;

  @Column({
    type: "enum",
    enum: HabilidadeArea,
    default: HabilidadeArea.TECNOLOGIA,
    nullable: false
  })
  area!: HabilidadeArea;

  // Relacionamento N:M com Aluno (via tabela intermediária)
  @OneToMany(() => AlunoHabilidade, ah => ah.habilidade)
  alunoHabilidades?: AlunoHabilidade[];

  // Relacionamento N:M com Vaga (via tabela intermediária)
  @OneToMany(() => VagaHabilidade, vh => vh.habilidade)
  vagaHabilidades?: VagaHabilidade[];
}
