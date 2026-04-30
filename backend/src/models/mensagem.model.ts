/**
 * MENSAGEM - Chat entre aluno e empresa via candidatura
 * Tabela: mensagem
 * Relacionamento: N:1 com Candidatura, N:1 com Usuario (remetente)
 */
export interface IMensagem {
  id: number;
  candidatura_id: number;
  remetente_id: number;
  conteudo: string;
  enviado_em: Date;
}

export interface IMensagemComRemetente extends IMensagem {
  remetente?: {
    id: number;
    nome_exibicao: string;
    perfil: "aluno" | "empresa";
  };
}
