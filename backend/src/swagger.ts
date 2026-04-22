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
                  required: ["nome_exibicao", "email", "senha", "perfil"], // 👈 Corrigido para 'senha'
                  properties: {
                    nome_exibicao: { type: "string", example: "Maria Vitória" },
                    email: { type: "string", example: "maria@email.com" },
                    senha: { type: "string", example: "123456" },           // 👈 Corrigido
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
                      criado_em: { type: "string", format: "date-time" },
                      atualizado_em: { type: "string", format: "date-time" },
                    },
                  },
                },
              },
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
                  required: ["nome_exibicao", "email", "senha", "perfil"], // 👈 Corrigido
                  properties: {
                    nome_exibicao: { type: "string", example: "Felipe Salazar" },
                    email: { type: "string", example: "felipe@teste.com" },
                    senha: { type: "string", example: "senha123" },           // 👈 Corrigido
                    perfil: {
                      type: "string",
                      enum: ["aluno", "empresa"],
                      example: "aluno"
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
          responses: { 
            200: { 
              description: "Lista de usuários retornada com sucesso",
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
          parameters: [
            {
              name: "id",
              in: "path",
              required: true,
              schema: { type: "integer" }, // 👈 Corrigido para integer (conforme sua entidade Usuario)
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
              schema: { type: "integer" }, // 👈 Corrigido
            },
          ],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    nome_exibicao: { type: "string", example: "Felipe Atualizado" },
                    perfil: { type: "string", enum: ["aluno", "empresa"], example: "empresa" },
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
              schema: { type: "integer" }, // 👈 Corrigido
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