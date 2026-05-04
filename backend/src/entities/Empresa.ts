import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  OneToMany, 
  JoinColumn
} from "typeorm";
import { Usuario } from "./Usuario";
import { Vaga } from "./Vaga"; 


@Entity("empresa")
export class Empresa {
  @PrimaryGeneratedColumn() // 👈 Troque @PrimaryColumn() por isso
  id!: number;

  @Column({ type: "varchar", length: 14, unique: true, nullable: true })
  cnpj?: string;

  @Column({ type: "text", nullable: true })
  descricao?: string;

  // Use 'numeric' ou 'decimal' - para o TypeORM no Postgres 'numeric' é mais comum
  @Column({ type: "numeric", precision: 10, scale: 8, nullable: true })
  latitude?: number;

  @Column({ type: "numeric", precision: 11, scale: 8, nullable: true })
  longitude?: number;

  // Se você quiser manter o vínculo 1:1, mude o nome da coluna de join para 'usuarioId'
  // para não conflitar com o ID da própria empresa
  @OneToOne(() => Usuario, (usuario) => usuario.empresa, { onDelete: "CASCADE" })
  @JoinColumn({ name: "usuarioId" }) 
  usuario?: Usuario;

  @OneToMany(() => Vaga, (vaga) => vaga.empresa)
  vagas!: Vaga[];
}