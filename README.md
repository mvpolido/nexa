# Nexa
# 📌 Funcionalidades do Sistema

## 1. 🔐 Autenticação de Usuários
- Cadastro de usuário (aluno e empresa)
- Login e logout
- Diferenciação de perfis (aluno / empresa)
- Edição de perfil

---

## 2. 🎓 Perfil do Aluno
- Cadastro de:
  - Dados pessoais
  - Curso
  - Habilidades (padronizadas, com uso de banco de dados e autocomplete)
  - Localização (convertida para latitude/longitude)
- Upload de currículo:
  - Apenas PDF
  - Limite de tamanho
  - Renomeação do arquivo
- Atualização de dados

---

## 3. 🏢 Perfil da Empresa
- Cadastro de empresa
- Informações:
  - Nome
  - CNPJ (com validação)
  - Descrição
  - Localização
- Edição de perfil

---

## 4. 💼 Vagas de Estágio
- Empresa pode:
  - Criar vaga
  - Editar vaga
  - Excluir vaga
- Campos da vaga:
  - Título
  - Descrição
  - Requisitos
  - Habilidades requeridas
  - Localização (latitude/longitude)
  - Modalidade (presencial/remoto)

---

## 5. 🔍 Listagem e Busca de Vagas
- Listar todas as vagas
- Busca por:
  - Título
  - Curso
- Filtros:
  - Distância (5km, 10km, 20km)
  - Modalidade

---

## 6. 📍 Filtro por Proximidade (Principal)
- Cálculo de distância entre:
  - Usuário e vaga
- Exibir apenas vagas dentro do raio selecionado

---

## 7. 🧠 Compatibilidade (Match)
- Comparar:
  - Habilidades do aluno
  - Requisitos da vaga (padronizados, ex: período, carga horária, etc.)
  - Distância
- Exibir percentual de compatibilidade

---

## 8. 📨 Candidatura
- Aluno pode:
  - Se candidatar a vagas
- Empresa pode:
  - Visualizar candidatos
  - Aceitar ou rejeitar candidaturas

---

## 9. 💬 Chat (Comunicação Aluno ↔ Empresa)
- Chat individual entre aluno e empresa após candidatura
- Envio de mensagens
- Histórico de mensagens
- Identificação de remetente (aluno/empresa)

---

## 10. 📊 Dashboard do Aluno
- Total de candidaturas
- Status:
  - Enviadas
  - Aceitas
  - Rejeitadas
- Vagas recomendadas *(funcionalidade avançada)*

---

## 11. 📊 Dashboard da Empresa
- Total de vagas criadas
- Total de candidatos por vaga
- Lista de candidatos

---

## 12. ⭐ Avaliação de Vagas/Empresas
- Aluno pode avaliar:
  - Empresa
  - Experiência
- Avaliação com:
  - Nota
  - Comentário

---

## 13. 🗺️ Mapa de Vagas (Funcionalidade Extra)
- Exibição das vagas em mapa interativo
- Visualização por meio de pins (marcadores)
- Clique no pin para visualizar detalhes da vaga
- Integração com sistema de localização (latitude/longitude)

## 🚀 Tecnologias Utilizadas

### 🎨 Frontend
- Flutter (Web)

### ⚙️ Backend
- TypeScript
- Node.js
- Express

### 🗄️ Banco de Dados
- PostgreSQL
- TypeORM (ORM para integração com o banco)

### 🐳 Infraestrutura
- Docker
- Docker Compose

## 🚀 Tecnologias Utilizadas

### 🎨 Frontend
- Flutter (Web)

### ⚙️ Backend
- TypeScript
- Node.js
- Express

### 🗄️ Banco de Dados
- PostgreSQL
- TypeORM (ORM para integração com o banco)

### 🐳 Infraestrutura
- Docker
- Docker Compose