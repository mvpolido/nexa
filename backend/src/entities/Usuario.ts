import { 
  Entity, 
  PrimaryGeneratedColumn, 
  Column, 
  CreateDateColumn, 
  UpdateDateColumn,
  OneToOne
} from "typeorm";
import { Aluno } from "./Aluno";
import { Empresa } from "./Empresa";

export enum UsuarioPerfil {
  ALUNO = "aluno",
  EMPRESA = "empresa"
}

@Entity("usuario")
export class Usuario {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ type: "varchar", unique: true, nullable: false })
  email!: string;

  @Column({ type: "varchar", nullable: false, select: false })
  senha_hash!: string;

  @Column({ type: "varchar", length: 255, nullable: false })
  nome_exibicao!: string;

  @Column({
    type: "enum",
    enum: UsuarioPerfil,
    nullable: false
  })
  perfil!: UsuarioPerfil;

  @CreateDateColumn()
  criado_em!: Date;

  @UpdateDateColumn()
  atualizado_em!: Date;

  @OneToOne(() => Aluno, aluno => aluno.usuario, { cascade: true, nullable: true })
  aluno?: Aluno;

  @OneToOne(() => Empresa, empresa => empresa.usuario, { cascade: true, nullable: true })
  empresa?: Empresa;
}