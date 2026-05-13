import {
  Entity,
  PrimaryColumn,
  Column,
  OneToOne,
  OneToMany,
  JoinColumn
} from "typeorm";
import { Usuario } from "./Usuario";
import { AlunoHabilidade } from "./AlunoHabilidade";

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

  @Column({ type: "decimal", precision: 10, scale: 8, nullable: true })
  latitude?: number;

  @Column({ type: "decimal", precision: 11, scale: 8, nullable: true })
  longitude?: number;

  //Relacionamento 1:1 com Usuario
  @OneToOne(() => Usuario, usuario => usuario.aluno, { onDelete: "CASCADE" })
  @JoinColumn({ name: "id" })
  usuario?: Usuario;

  // Relacionamento N:M com Habilidade (via tabela intermediária)
  @OneToMany(() => AlunoHabilidade, ah => ah.aluno)
  alunoHabilidades?: AlunoHabilidade[];
}
