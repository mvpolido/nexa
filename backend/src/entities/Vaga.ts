import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from "typeorm";
import { Empresa } from "./Empresa";

@Entity("vagas")
export class Vaga {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  titulo!: string;

  @Column("text")
  descricao!: string;

  @Column("text")
  requisitos!: string;

  @Column({
    type: "enum",
    enum: ["PRESENCIAL", "REMOTO", "HIBRIDO"],
    default: "PRESENCIAL"
  })
  modalidade!: string;

  // Campos para Geolocalização (latitude e longitude)
  @Column("decimal", { precision: 10, scale: 8, nullable: true })
  latitude!: number;

  @Column("decimal", { precision: 11, scale: 8, nullable: true })
  longitude!: number;

  // Para habilidades, como é uma lista, podemos usar o tipo 'simple-array'
  @Column("simple-array", { nullable: true })
  habilidades!: string[];

  // O relacionamento que liga a vaga à empresa
  @ManyToOne(() => Empresa, (empresa) => empresa.vagas)
  empresa!: Empresa;
}