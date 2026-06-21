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

  @Column({ type: "varchar", length: 9, nullable: true })
  cep?: string;

  @Column({ type: "varchar", length: 255, nullable: true })
  endereco?: string;

  @Column({ type: "varchar", length: 50, nullable: true })
  numero?: string;

  @Column({ type: "varchar", length: 120, nullable: true })
  cidade?: string;

  @Column({ type: "varchar", length: 2, nullable: true })
  estado?: string;

  @Column({ type: "decimal", precision: 10, scale: 8, nullable: true })
  latitude?: number;

  @Column({ type: "decimal", precision: 11, scale: 8, nullable: true })
  longitude?: number;

  // 🛠️ Adicionado: suporte para habilidades simplificadas (opcional)
  // Se o projeto migrar totalmente para VagaHabilidade, este campo pode ser removido depois.
  @Column("simple-array", { nullable: true })
  habilidades?: string[];

  @Column("simple-json", { nullable: true })
  cursos_destinados?: string[] | null;

  @Column({ type: "smallint", nullable: true })
  ano_conclusao_min?: number | null;

  @Column({ type: "smallint", nullable: true })
  ano_conclusao_max?: number | null;

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
