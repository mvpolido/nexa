import {
  Entity,
  PrimaryColumn,
  Column,
  OneToOne,
  JoinColumn
} from "typeorm";
import { Usuario } from "./Usuario";

@Entity("aluno")
export class Aluno {
  @PrimaryColumn()
  id!: number;

  @Column({ type: "varchar", length: 11, unique: true, nullable: true })
  cpf?: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  curso?: string;

  @Column({ type: "varchar", length: 500, nullable: true })
  url_curriculo?: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  instituicao?: string;

  @Column({ type: "text", nullable: true })
  skills?: string; // armazenará um JSON stringificado

  @Column({ type: "varchar", length: 500, nullable: true })
  endereco?: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  logradouro?: string;

  @Column({ type: "varchar", length: 8, nullable: true })
  cep?: string;

  @Column({ type: "varchar", length: 20, nullable: true })
  numero?: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  bairro?: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  cidade?: string;

  @Column({ type: "varchar", length: 2, nullable: true })
  estado?: string;

  @Column({ type: "text", nullable: true })
  foto_perfil?: string;

  @Column({ type: "decimal", precision: 10, scale: 8, nullable: true })
  latitude?: number;

  @Column({ type: "decimal", precision: 11, scale: 8, nullable: true })
  longitude?: number;

  //Relacionamento 1:1 com Usuario
  @OneToOne(() => Usuario, usuario => usuario.aluno, { onDelete: "CASCADE" })
  @JoinColumn({ name: "id" })
  usuario?: Usuario;
}
