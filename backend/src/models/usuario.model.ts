//Tabela Usuario - Armazena informações básicas de todos os usuários (alunos e empresas)
export interface IUsuario {
  id: number;                          
  email: string;                       
  senha_hash: string;                 
  nome_exibicao: string;               
  perfil: "aluno" | "empresa";         
  criado_em: Date;                     
  atualizado_em: Date;                 
}

//Perfis
export enum PerfilUsuario {
  ALUNO = "aluno",
  EMPRESA = "empresa"
}
