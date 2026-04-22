import swaggerJSDoc from "swagger-jsdoc";

const options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "API Nexa",
      version: "1.0.0",
      description: "Documentação da API do Nexa",
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
                  required: ["nome_exibicao", "email", "password", "perfil"],
                  properties: {
                    nome_exibicao: {
                      type: "string",
                      example: "Maria Vitória",
                    },
                    email: {
                      type: "string",
                      example: "maria@email.com",
                    },
                    password: {
                      type: "string",
                      example: "123456",
                    },
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
                      nome_exibicao: {
                        type: "string",
                        example: "Maria Vitória",
                      },
                      email: {
                        type: "string",
                        example: "maria@email.com",
                      },
                      perfil: {
                        type: "string",
                        example: "aluno",
                      },
                      criado_em: {
                        type: "string",
                        example: "2026-04-20T18:38:22.805Z",
                      },
                      atualizado_em: {
                        type: "string",
                        example: "2026-04-20T18:38:22.805Z",
                      },
                    },
                  },
                },
              },
            },
            400: {
              description: "Campos obrigatórios faltando ou perfil inválido",
            },
            409: {
              description: "Email já cadastrado",
            },
            500: {
              description: "Erro interno no servidor",
            },
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
                  required: ["email", "password"],
                  properties: {
                    email: {
                      type: "string",
                      example: "maria@email.com",
                    },
                    password: {
                      type: "string",
                      example: "123456",
                    },
                  },
                },
              },
            },
          },
          responses: {
            200: {
              description: "Login realizado com sucesso",
            },
            400: {
              description: "Campos obrigatórios faltando",
            },
            401: {
              description: "Credenciais inválidas",
            },
            500: {
              description: "Erro interno no servidor",
            },
          },
        },
      },

      "/users": {
        post: {
          summary: "Cria um novo usuário",
          tags: ["Users"],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    nome_exibicao: {
                      type: "string",
                      example: "Felipe Salazar",
                    },
                    email: {
                      type: "string",
                      example: "felipe@teste.com",
                    },
                    password: {
                      type: "string",
                      example: "senha123",
                    },
                    perfil: {
                      type: "string",
                      example: "aluno",
                    },
                  },
                },
              },
            },
          },
          responses: {
            201: { description: "Usuário criado com sucesso" },
            400: { description: "Requisição inválida" },
          },
        },
        get: {
          summary: "Lista todos os usuários",
          tags: ["Users"],
          responses: { 200: { description: "OK" } },
        },
      },

      "/users/{id}": {
        get: {
          summary: "Busca um usuário pelo ID",
          tags: ["Users"],
          parameters: [
            {
              name: "id",
              in: "path",
              required: true,
              schema: { type: "string" },
            },
          ],
          responses: {
            200: { description: "OK" },
            404: { description: "Não encontrado" },
          },
        },
        put: {
          summary: "Atualiza um usuário",
          tags: ["Users"],
          parameters: [
            {
              name: "id",
              in: "path",
              required: true,
              schema: { type: "string" },
            },
          ],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    nome_exibicao: {
                      type: "string",
                      example: "Felipe Atualizado",
                    },
                    perfil: {
                      type: "string",
                      example: "empresa",
                    },
                  },
                },
              },
            },
          },
          responses: {
            200: { description: "OK" },
          },
        },
        delete: {
          summary: "Deleta um usuário",
          tags: ["Users"],
          parameters: [
            {
              name: "id",
              in: "path",
              required: true,
              schema: { type: "string" },
            },
          ],
          responses: {
            200: { description: "OK" },
          },
        },
      },
    },
  },
  apis: [],
};

export const swaggerSpec = swaggerJSDoc(options);