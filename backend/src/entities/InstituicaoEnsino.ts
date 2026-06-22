import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from "typeorm";

@Entity("instituicao_ensino")
export class InstituicaoEnsino {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ type: "varchar", length: 255, nullable: false })
  nome!: string;

  @Column({ type: "varchar", length: 50, nullable: true })
  sigla?: string | null;

  @Column({ type: "boolean", default: true })
  ativa!: boolean;

  @CreateDateColumn()
  criado_em!: Date;

  @UpdateDateColumn()
  atualizado_em!: Date;
}
