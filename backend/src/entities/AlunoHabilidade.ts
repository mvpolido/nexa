import {
  Entity,
  PrimaryColumn,
  ManyToOne,
  JoinColumn
} from "typeorm";
import { Aluno } from "./Aluno";
import { Habilidade } from "./Habilidade";

@Entity("aluno_habilidade")
export class AlunoHabilidade {
  @PrimaryColumn()
  aluno_id!: number;

  @PrimaryColumn()
  habilidade_id!: number;

  // Relacionamento N:1 com Aluno
  @ManyToOne(() => Aluno, aluno => aluno.alunoHabilidades, { onDelete: "CASCADE" })
  @JoinColumn({ name: "aluno_id" })
  aluno!: Aluno;

  // Relacionamento N:1 com Habilidade
  @ManyToOne(() => Habilidade, habilidade => habilidade.alunoHabilidades, { onDelete: "CASCADE" })
  @JoinColumn({ name: "habilidade_id" })
  habilidade!: Habilidade;
}
