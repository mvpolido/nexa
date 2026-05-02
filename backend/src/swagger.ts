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
            201: { description: "Usuário criado com sucesso" },
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

      "/vagas": {
        get: {
          summary: "Lista todas as vagas disponíveis",
          tags: ["Vagas"],
          security: [{ bearerAuth: [] }],
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
                    latitude: { type: "number", example: -23.5505 },
                    longitude: { type: "number", example: -46.6333 },
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
            403: { description: "Acesso negado: Aluno não pode criar vaga" },
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
          responses: { 200: { description: "OK" } },
        },
      },
    },
  },
  apis: [],
};

export const swaggerSpec = swaggerJSDoc(options);