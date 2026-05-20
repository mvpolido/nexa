import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
  CreateDateColumn
} from "typeorm";
import { Aluno } from "./Aluno";
import { Vaga } from "./Vaga";
import { Mensagem } from "./Mensagem";

export enum CandidaturaStatus {
  PENDENTE = "PENDENTE",
  ACEITA = "ACEITA",
  REJEITADA = "REJEITADA"
}

@Entity("candidatura")
export class Candidatura {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: "aluno_id", nullable: false })
  aluno_id!: number;

  @Column({ name: "vaga_id", nullable: false })
  vaga_id!: number;

  @Column({
    type: "enum",
    enum: CandidaturaStatus,
    default: CandidaturaStatus.PENDENTE
  })
  status!: CandidaturaStatus;

  @Column({ type: "decimal", precision: 5, scale: 2, nullable: true })
  pontuacao_compatibilidade?: number;

  
  @Column({ name: "curriculo_path", type: "varchar", length: 255, nullable: true })
  curriculo_path?: string;

  @CreateDateColumn()
  data_candidatura!: Date;

  // Relacionamento N:1 com Aluno
  @ManyToOne(() => Aluno, { onDelete: "CASCADE" })
  @JoinColumn({ name: "aluno_id" })
  aluno!: Aluno;

  // Relacionamento N:1 com Vaga
  @ManyToOne(() => Vaga, vaga => vaga.candidaturas, { onDelete: "CASCADE" })
  @JoinColumn({ name: "vaga_id" })
  vaga!: Vaga;

  // Relacionamento 1:M com Mensagem
  @OneToMany(() => Mensagem, mensagem => mensagem.candidatura)
  mensagens?: Mensagem[];
}