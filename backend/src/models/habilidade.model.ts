/**
 * HABILIDADE - Tabela de padronização de habilidades
 * Tabela: habilidade
 * Relacionamento: N:M com Aluno e Vaga (via tabelas intermediárias)
 */
export interface IHabilidade {
  id: number;
  nome: string;
}
