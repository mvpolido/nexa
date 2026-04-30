import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
  CreateDateColumn
} from "typeorm";
import { Empresa } from "./Empresa";
import { Candidatura } from "./Candidatura";
import { VagaHabilidade } from "./VagaHabilidade";

export enum VagaModalidade {
  PRESENCIAL = "PRESENCIAL",
  REMOTO = "REMOTO",
  HIBRIDO = "HIBRIDO"
}

@Entity("vaga")
export class Vaga {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ name: "empresa_id", nullable: false })
  empresa_id!: number;

  @Column({ type: "varchar", length: 255, nullable: false })
  titulo!: string;

  @Column({ type: "text", nullable: false })
  descricao!: string;

  @Column({ type: "text", nullable: true })
  requisitos?: string;

  @Column({
    type: "enum",
    enum: VagaModalidade,
    nullable: false
  })
  modalidade!: VagaModalidade;

  @Column({ type: "decimal", precision: 10, scale: 8, nullable: true })
  latitude?: number;

  @Column({ type: "decimal", precision: 11, scale: 8, nullable: true })
  longitude?: number;

  @Column({ type: "smallint", default: 1 })
  ativo!: number;

  @CreateDateColumn()
  criado_em!: Date;

  // Relacionamento N:1 com Empresa
  @ManyToOne(() => Empresa, { onDelete: "CASCADE" })
  @JoinColumn({ name: "empresa_id" })
  empresa!: Empresa;

  // Relacionamento 1:M com Candidatura
  @OneToMany(() => Candidatura, candidatura => candidatura.vaga)
  candidaturas?: Candidatura[];

  // Relacionamento N:M com Habilidade (via tabela intermediária)
  @OneToMany(() => VagaHabilidade, vh => vh.vaga)
  vagaHabilidades?: VagaHabilidade[];
}
