import { 
  Entity, 
  PrimaryGeneratedColumn, 
  Column, 
  CreateDateColumn, 
  UpdateDateColumn 
} from "typeorm";

export enum UserRole {
  ALUNO = "aluno",
  EMPRESA = "empresa"
}

@Entity("users")
export class User {
  @PrimaryGeneratedColumn("uuid")
  id!: string;

  @Column({ type: "varchar", length: 100 })
  nome_exibicao!: string;

  @Column({ type: "varchar", unique: true })
  email!: string;

  // select: false garante que esse campo não vaze em requisições GET
  @Column({ type: "varchar", select: false })
  senha_hash!: string;

  @Column({
    type: "enum",
    enum: UserRole,
    default: UserRole.ALUNO
  })
  perfil!: UserRole;

  @CreateDateColumn()
  created_at!: Date;

  @UpdateDateColumn()
  updated_at!: Date;
}