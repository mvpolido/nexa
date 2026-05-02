import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  Check
} from "typeorm";
import { Aluno } from "./Aluno";
import { Empresa } from "./Empresa";

@Entity("avaliacao")
@Check(`nota >= 1 AND nota <= 5`)
export class Avaliacao {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: "aluno_id", nullable: false })
  aluno_id!: number;

  @Column({ name: "empresa_id", nullable: false })
  empresa_id!: number;

  @Column({ type: "smallint", nullable: false })
  nota!: number;

  @Column({ type: "text", nullable: true })
  comentario?: string;

  @CreateDateColumn()
  criado_em!: Date;

  // Relacionamento N:1 com Aluno
  @ManyToOne(() => Aluno, { onDelete: "CASCADE" })
  @JoinColumn({ name: "aluno_id" })
  aluno!: Aluno;

  // Relacionamento N:1 com Empresa
  @ManyToOne(() => Empresa, { onDelete: "CASCADE" })
  @JoinColumn({ name: "empresa_id" })
  empresa!: Empresa;
}
