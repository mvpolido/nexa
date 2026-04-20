/**
 * EMPRESA - Especialização de usuário para empresas
 * Tabela: empresa
 * Relacionamento: 1:1 com Usuario (cascata delete)
 */
export interface IEmpresa {
  id: number;
  cnpj?: string;
  descricao?: string;
  latitude?: number;
  longitude?: number;
}

export interface IEmpresaComUsuario extends IEmpresa {
  usuario?: {
    email: string;
    nome_exibicao: string;
    criado_em: Date;
  };
}
