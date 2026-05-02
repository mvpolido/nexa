import {
  Entity,
  PrimaryColumn,
  Column,
  OneToOne,
  OneToMany, 
  JoinColumn
} from "typeorm";
import { Usuario } from "./Usuario";
import { Vaga } from "./Vaga"; 

@Entity("empresa")
export class Empresa {
  @PrimaryColumn()
  id!: number;

  @Column({ type: "varchar", length: 14, unique: true, nullable: true })
  cnpj?: string;

  @Column({ type: "text", nullable: true })
  descricao?: string;

  @Column({ type: "decimal", precision: 10, scale: 8, nullable: true })
  latitude?: number;

  @Column({ type: "decimal", precision: 11, scale: 8, nullable: true })
  longitude?: number;

  // Relacionamento 1:1 com Usuario
  @OneToOne(() => Usuario, (usuario) => usuario.empresa, { onDelete: "CASCADE" })
  @JoinColumn({ name: "id" })
  usuario?: Usuario;

  // Relacionamento 1:N com Vagas (Corrigido)
  @OneToMany(() => Vaga, (vaga) => vaga.empresa)
  vagas!: Vaga[];
}