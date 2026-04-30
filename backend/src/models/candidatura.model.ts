/**
 * CANDIDATURA - Candidatura de aluno a uma vaga
 * Tabela: candidatura
 * Relacionamento: N:1 com Aluno, N:1 com Vaga, 1:M com Mensagem
 */
export interface ICandidatura {
  id: number;
  aluno_id: number;
  vaga_id: number;
  status: "PENDENTE" | "ACEITA" | "REJEITADA";
  pontuacao_compatibilidade?: number;
  data_candidatura: Date;
}

export interface ICandidaturaDetalhada extends ICandidatura {
  aluno?: {
    id: number;
    usuario?: {
      nome_exibicao: string;
      email: string;
    };
  };
  vaga?: {
    id: number;
    titulo: string;
  };
}
