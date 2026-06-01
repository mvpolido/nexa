import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, CreateDateColumn } from "typeorm";
import { Empresa } from "./Empresa";
import { Usuario } from "./Usuario";

@Entity("avaliacao")
export class Avaliacao {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: "empresa_id" })
  empresa_id!: number;

  @Column({ name: "aluno_id" })
  aluno_id!: number;

  @Column({ type: "int" })
  nota!: number;

  @Column({ type: "text" })
  comentario!: string;

  @CreateDateColumn()
  criado_em!: Date;

  @ManyToOne(() => Empresa, empresa => empresa.avaliacoes, { onDelete: "CASCADE" })
  @JoinColumn({ name: "empresa_id" })
  empresa!: Empresa;

  @ManyToOne(() => Usuario, { onDelete: "CASCADE" })
  @JoinColumn({ name: "aluno_id" })
  alunoUsuario!: Usuario;
}