import swaggerJSDoc from "swagger-jsdoc";

const options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "API Nexa",
      version: "1.0.0",
      description: "Documentação da API do Nexa",
    },
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
        },
      },
      schemas: {
        Habilidade: {
          type: "object",
          properties: {
            id: { type: "integer", example: 1 },
            nome: { type: "string", example: "React" },
            area: {
              type: "string",
              enum: [
                "TECNOLOGIA",
                "ENGENHARIA",
                "EXATAS",
                "SAUDE",
                "QUIMICA",
                "FISICA",
                "BIOLOGIA",
                "COMUNICACAO",
                "GESTAO",
                "DESIGN",
              ],
              example: "TECNOLOGIA",
            },
          },
        },
        HabilidadeInput: {
          type: "object",
          required: ["nome"],
          properties: {
            nome: { type: "string", example: "Node.js" },
            area: { type: "string", example: "TECNOLOGIA" },
          },
        },
      },
    },
    paths: {
      "/health": {
        get: {
          summary: "Verifica se a API está funcionando",
          tags: ["Health"],
          responses: {
            200: {
              description: "API funcionando",
              content: {
                "application/json": {
                  schema: {
                    type: "object",
                    properties: {
                      status: { type: "string", example: "ok" },
                    },
                  },
                },
              },
            },
          },
        },
      },

      "/auth/register": {
        post: {
          summary: "Cadastra um novo usuário",
          tags: ["Auth"],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  required: ["nome_exibicao", "email", "senha", "perfil"],
                  properties: {
                    nome_exibicao: { type: "string", example: "Maria Vitória" },
                    email: { type: "string", example: "maria@email.com" },
                    senha: { type: "string", example: "123456" },
                    perfil: {
                      type: "string",
                      enum: ["aluno", "empresa"],
                      example: "aluno",
                    },
                  },
                },
              },
            },
          },
          responses: {
            201: { 
              description: "Usuário criado com sucesso",
              content: {
                "application/json": {
                  schema: {
                    type: "object",
                    properties: {
                      id: { type: "integer", example: 1 },
                      nome_exibicao: { type: "string" },
                      email: { type: "string" },
                      perfil: { type: "string" },
                    }
                  }
                }
              }
            },
            409: { description: "Email já cadastrado" },
          },
        },
      },

      "/auth/login": {
        post: {
          summary: "Autentica um usuário",
          tags: ["Auth"],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  required: ["email", "senha"],
                  properties: {
                    email: { type: "string", example: "maria@email.com" },
                    senha: { type: "string", example: "123456" },
                  },
                },
              },
            },
          },
          responses: {
            200: { description: "Login realizado com sucesso" },
            401: { description: "Credenciais inválidas" },
          },
        },
      },

      "/habilidades": {
        get: {
          summary: "Lista habilidades cadastradas",
          tags: ["Habilidades"],
          responses: {
            200: {
              description: "Lista de habilidades",
              content: {
                "application/json": {
                  schema: {
                    type: "array",
                    items: { $ref: "#/components/schemas/Habilidade" },
                  },
                },
              },
            },
            500: { description: "Erro interno do servidor" },
          },
        },
        post: {
          summary: "Cadastra uma nova habilidade",
          tags: ["Habilidades"],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: { $ref: "#/components/schemas/HabilidadeInput" },
                examples: {
                  exemplo: {
                    value: { nome: "TypeScript" },
                  },
                },
              },
            },
          },
          responses: {
            201: {
              description: "Habilidade criada com sucesso",
              content: {
                "application/json": {
                  schema: { $ref: "#/components/schemas/Habilidade" },
                },
              },
            },
            400: { description: "Campo nome é obrigatório" },
            409: { description: "Habilidade já cadastrada" },
            500: { description: "Erro interno do servidor" },
          },
        },
      },

      "/vagas": {
        get: {
          summary: "Lista todas as vagas disponíveis",
          tags: ["Vagas"],
          security: [{ bearerAuth: [] }],
          parameters: [
            { name: "modalidade", in: "query", schema: { type: "string" } },
            { name: "distanciaKm", in: "query", schema: { type: "number" } },
            { name: "curso", in: "query", schema: { type: "string" } },
            { name: "anoConclusao", in: "query", schema: { type: "integer" } },
            { name: "anoConclusaoAte", in: "query", schema: { type: "integer" } },
          ],
          responses: {
            200: { description: "Lista retornada com sucesso" },
            401: { description: "Não autorizado" },
          },
        },
        post: {
          summary: "Cria uma nova vaga (Apenas Empresa)",
          tags: ["Vagas"],
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  required: ["titulo", "descricao", "requisitos", "modalidade"],
                  properties: {
                    titulo: { type: "string", example: "Desenvolvedor Node.js" },
                    descricao: { type: "string", example: "Vaga para backend em startup" },
                    requisitos: { type: "string", example: "Node.js, TypeScript e Docker" },
                    modalidade: { 
                      type: "string", 
                      enum: ["PRESENCIAL", "REMOTO", "HIBRIDO"],
                      example: "REMOTO" 
                    },
                    latitude: { type: "number", example: -24.5505 },
                    longitude: { type: "number", example: -45.6333 },
                    cursos_destinados: {
                      type: "array",
                      items: { type: "string" },
                      example: ["Ciência da Computação", "Engenharia de Software"],
                    },
                    ano_conclusao_min: { type: "integer", nullable: true, example: 2026 },
                    ano_conclusao_max: { type: "integer", nullable: true, example: 2029 },
                    habilidades: { 
                      type: "array", 
                      items: { type: "string" },
                      example: ["TypeScript", "SQL", "Jest"]
                    }
                  },
                },
              },
            },
          },
          responses: {
            201: { description: "Vaga criada com sucesso" },
            403: { description: "Acesso negado" },
          },
        },
      },

      "/vagas/{id}": {
        get: {
          summary: "Busca detalhes de uma vaga",
          tags: ["Vagas"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          responses: { 200: { description: "OK" } },
        },
        put: {
          summary: "Atualiza uma vaga (Apenas a própria empresa)",
          tags: ["Vagas"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          requestBody: {
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    titulo: { type: "string" },
                    modalidade: { type: "string", enum: ["PRESENCIAL", "REMOTO", "HIBRIDO"] },
                    cursos_destinados: {
                      type: "array",
                      items: { type: "string" },
                    },
                    ano_conclusao_min: { type: "integer", nullable: true },
                    ano_conclusao_max: { type: "integer", nullable: true },
                  }
                }
              }
            }
          },
          responses: {
            200: { description: "Atualizado com sucesso" },
            403: { description: "Não permitido" },
          },
        },
        delete: {
          summary: "Deleta uma vaga (Apenas a própria empresa)",
          tags: ["Vagas"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          responses: {
            200: { description: "Removido com sucesso" },
            403: { description: "Não permitido" },
          },
        },
      },

      "/users": {
        get: {
          summary: "Lista todos os usuários",
          tags: ["Users"],
          security: [{ bearerAuth: [] }],
          responses: { 
            200: { 
              description: "OK",
              content: {
                "application/json": {
                  schema: {
                    type: "array",
                    items: {
                      type: "object",
                      properties: {
                        id: { type: "integer" },
                        nome_exibicao: { type: "string" },
                        email: { type: "string" },
                        perfil: { type: "string" }
                      }
                    }
                  }
                }
              }
            } 
          },
        },
      },

      "/users/{id}": {
        get: {
          summary: "Busca um usuário pelo ID",
          tags: ["Users"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          responses: { 200: { description: "OK" }, 404: { description: "Não encontrado" } },
        },
        put: {
          summary: "Atualiza um usuário",
          tags: ["Users"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    nome_exibicao: { type: "string" },
                    perfil: { type: "string", enum: ["aluno", "empresa"] },
                  },
                },
              },
            },
          },
          responses: { 200: { description: "OK" } },
        },
        delete: {
          summary: "Deleta um usuário",
          tags: ["Users"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          responses: { 200: { description: "OK" } },
        },
      },
    },
  },
  apis: [],
};

export const swaggerSpec = swaggerJSDoc(options);
