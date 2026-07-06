import { Entity, PrimaryColumn, Column, OneToOne, OneToMany, JoinColumn } from "typeorm";
import { Usuario } from "./Usuario";
import { Vaga } from "./Vaga";
import { Avaliacao } from "./Avaliacao";

export enum EmpresaStatusVerificacao {
  NAO_SOLICITADA = "nao_solicitada",
  PENDENTE = "pendente",
  APROVADA = "aprovada",
  REJEITADA = "rejeitada",
}

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

  @Column({
    type: "varchar",
    length: 20,
    default: EmpresaStatusVerificacao.NAO_SOLICITADA,
  })
  status_verificacao!: EmpresaStatusVerificacao;

  @Column({ type: "varchar", length: 255, nullable: true })
  documento_verificacao_path?: string | null;

  @Column({ type: "varchar", length: 255, nullable: true })
  documento_verificacao_nome_original?: string | null;

  @Column({ type: "timestamp", nullable: true })
  verificacao_solicitada_em?: Date | null;

  @Column({ type: "timestamp", nullable: true })
  verificacao_analisada_em?: Date | null;

  @Column({ type: "text", nullable: true })
  verificacao_motivo_rejeicao?: string | null;

  @OneToOne(() => Usuario, (usuario) => usuario.empresa, { onDelete: "CASCADE" })
  @JoinColumn({ name: "id" })
  usuario?: Usuario;

  @OneToMany(() => Vaga, (vaga) => vaga.empresa)
  vagas!: Vaga[];

  @OneToMany(() => Avaliacao, avaliacao => avaliacao.empresa)
  avaliacoes!: Avaliacao[];
}
