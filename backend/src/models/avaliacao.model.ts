/**
 * AVALIACAO - Avaliação do aluno sobre a empresa
 * Tabela: avaliacao
 * Relacionamento: N:1 com Aluno, N:1 com Empresa
 * Restrição: nota entre 1 e 5
 */
export interface IAvaliacao {
  id: number;
  aluno_id: number;
  empresa_id: number;
  nota: number; // 1 a 5
  comentario?: string;
  criado_em: Date;
}
