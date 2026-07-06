import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn
} from "typeorm";
import { Usuario } from "./Usuario";

@Entity("notificacao")
export class Notificacao {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: "usuario_id", nullable: false })
  usuario_id!: number;

  @Column({ type: "varchar", nullable: false })
  tipo!: string;

  @Column({ type: "varchar", nullable: false })
  titulo!: string;

  @Column({ type: "text", nullable: false })
  mensagem!: string;

  @Column({ type: "boolean", default: false })
  lida!: boolean;

  @Column({ type: "int", nullable: true })
  link_id?: number | null;

  @CreateDateColumn()
  data_criacao!: Date;

  @ManyToOne(() => Usuario, { onDelete: "CASCADE" })
  @JoinColumn({ name: "usuario_id" })
  usuario!: Usuario;
}
