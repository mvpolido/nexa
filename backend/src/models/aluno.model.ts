/**
 * ALUNO - Especialização de usuário para estudantes
 * Tabela: aluno
 * Relacionamento: 1:1 com Usuario (cascata delete)
 */
export interface IAluno {
  id: number;
  cpf?: string;
  curso?: string;
  url_curriculo?: string;
  latitude?: number;
  longitude?: number;
}

export interface IAlunoComUsuario extends IAluno {
  usuario?: {
    email: string;
    nome_exibicao: string;
    criado_em: Date;
  };
}
