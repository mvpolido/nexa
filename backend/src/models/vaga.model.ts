/**
 * VAGA - Vagas de emprego/estágio publicadas por empresas
 * Tabela: vaga
 * Relacionamento: N:1 com Empresa, 1:M com Candidatura, N:M com Habilidade
 */
export interface IVaga {
  id: number;
  empresa_id: number;
  titulo: string;
  descricao: string;
  requisitos?: string;
  modalidade: "PRESENCIAL" | "REMOTO" | "HIBRIDO";
  latitude?: number;
  longitude?: number;
  cursos_destinados?: string[] | null;
  ano_conclusao_min?: number | null;
  ano_conclusao_max?: number | null;
  ativo: number;
  criado_em: Date;
}

export interface IVagaComEmpresa extends IVaga {
  empresa?: {
    id: number;
    usuario?: {
      nome_exibicao: string;
    };
  };
}
