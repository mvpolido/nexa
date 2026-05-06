import {
  Entity,
  PrimaryColumn,
  Column,
  OneToOne,
  JoinColumn
} from "typeorm";
import { Usuario } from "./Usuario";

@Entity("empresa")
export class Empresa {
  @PrimaryColumn()
  id!: number;

  @Column({ type: "varchar", length: 14, unique: true, nullable: true })
  cnpj?: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  razao_social?: string;

  @Column({ type: "varchar", length: 8, nullable: true })
  cep?: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  logradouro?: string;

  @Column({ type: "varchar", length: 20, nullable: true })
  numero?: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  bairro?: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  cidade?: string;

  @Column({ type: "varchar", length: 2, nullable: true })
  estado?: string;

  @Column({ type: "text", nullable: true })
  descricao?: string;

  @Column({ type: "decimal", precision: 10, scale: 8, nullable: true })
  latitude?: number;

  @Column({ type: "decimal", precision: 11, scale: 8, nullable: true })
  longitude?: number;

  //Relacionamento 1:1 com Usuario
  @OneToOne(() => Usuario, usuario => usuario.empresa, { onDelete: "CASCADE" })
  @JoinColumn({ name: "id" })
  usuario?: Usuario;
}
