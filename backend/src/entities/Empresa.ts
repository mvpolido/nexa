import { Entity, PrimaryColumn, Column, OneToOne, OneToMany, JoinColumn } from "typeorm";
import { Usuario } from "./Usuario";
import { Vaga } from "./Vaga";
import { Avaliacao } from "./Avaliacao";

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

  @Column({ type: "boolean", default: false })
  verificada!: boolean;

  @OneToOne(() => Usuario, (usuario) => usuario.empresa, { onDelete: "CASCADE" })
  @JoinColumn({ name: "id" })
  usuario?: Usuario;

  @OneToMany(() => Vaga, (vaga) => vaga.empresa)
  vagas!: Vaga[];

  @OneToMany(() => Avaliacao, avaliacao => avaliacao.empresa)
  avaliacoes!: Avaliacao[];
}