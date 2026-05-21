import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn
} from "typeorm";
import { Candidatura } from "./Candidatura";
import { Usuario } from "./Usuario";

@Entity("mensagem")
export class Mensagem {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: "candidatura_id", nullable: false })
  candidatura_id!: number;

  @Column({ name: "remetente_id", nullable: false })
  remetente_id!: number;

  @Column({ type: "text", nullable: false })
  conteudo!: string;

  @CreateDateColumn()
  enviado_em!: Date;

  // Relacionamento N:1 com Candidatura
  @ManyToOne(() => Candidatura, candidatura => candidatura.mensagens, { onDelete: "CASCADE" })
  @JoinColumn({ name: "candidatura_id" })
  candidatura!: Candidatura;

  // Relacionamento N:1 com Usuario (remetente - pode ser aluno ou empresa)
  @ManyToOne(() => Usuario, { onDelete: "CASCADE" })
  @JoinColumn({ name: "remetente_id" })
  remetente!: Usuario;
}