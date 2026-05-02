import {
  Entity,
  PrimaryColumn,
  ManyToOne,
  JoinColumn
} from "typeorm";
import { Vaga } from "./Vaga";
import { Habilidade } from "./Habilidade";

@Entity("vaga_habilidade")
export class VagaHabilidade {
  @PrimaryColumn()
  vaga_id!: number;

  @PrimaryColumn()
  habilidade_id!: number;

  // Relacionamento N:1 com Vaga
  @ManyToOne(() => Vaga, vaga => vaga.vagaHabilidades, { onDelete: "CASCADE" })
  @JoinColumn({ name: "vaga_id" })
  vaga!: Vaga;

  // Relacionamento N:1 com Habilidade
  @ManyToOne(() => Habilidade, habilidade => habilidade.vagaHabilidades, { onDelete: "CASCADE" })
  @JoinColumn({ name: "habilidade_id" })
  habilidade!: Habilidade;
}
