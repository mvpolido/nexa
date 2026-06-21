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
          },
        },
        HabilidadeInput: {
          type: "object",
          required: ["nome"],
          properties: {
            nome: { type: "string", example: "Node.js" },
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
          security: [{ bearerAuth: [] }],
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
          summary: "Cadastra uma nova habilidade (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
          tags: ["Habilidades"],
          security: [{ bearerAuth: [] }],
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
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
            409: { description: "Habilidade já cadastrada" },
            500: { description: "Erro interno do servidor" },
          },
        },
      },

      "/habilidades/{id}": {
        delete: {
          summary: "Deleta uma habilidade (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
          tags: ["Habilidades"],
          security: [{ bearerAuth: [] }],
          parameters: [
            { name: "id", in: "path", required: true, schema: { type: "integer" } },
          ],
          responses: {
            200: { description: "Habilidade removida com sucesso" },
            400: { description: "ID inválido" },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
            404: { description: "Habilidade não encontrada" },
            500: { description: "Erro interno do servidor" },
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
                    latitude: { type: "number", example: -24.5505 },
                    longitude: { type: "number", example: -45.6333 },
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
          summary: "Lista todos os usuários (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
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
            },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
          },
        },
      },

      "/users/{id}": {
        get: {
          summary: "Busca um usuário pelo ID (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
          tags: ["Users"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          responses: {
            200: { description: "OK" },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
            404: { description: "Não encontrado" },
          },
        },
        put: {
          summary: "Atualiza um usuário (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
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
          responses: {
            200: { description: "OK" },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
          },
        },
        delete: {
          summary: "Deleta um usuário (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
          tags: ["Users"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          responses: {
            200: { description: "OK" },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
          },
        },
      },

      "/admin/dashboard/stats": {
        get: {
          summary: "Dashboard de estatísticas (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
          tags: ["Admin"],
          security: [{ bearerAuth: [] }],
          responses: {
            200: { description: "Estatísticas retornadas com sucesso" },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
          },
        },
      },

      "/admin/empresas/{id}/verificar": {
        patch: {
          summary: "Aplica selo de empresa verificada (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
          tags: ["Admin"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          responses: {
            200: { description: "Empresa verificada com sucesso" },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
            404: { description: "Empresa não encontrada" },
          },
        },
      },

      "/admin/vagas": {
        get: {
          summary: "Lista vagas para moderação (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
          tags: ["Admin"],
          security: [{ bearerAuth: [] }],
          responses: {
            200: { description: "Lista de vagas retornada com sucesso" },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
          },
        },
      },

      "/admin/vagas/{id}": {
        delete: {
          summary: "Remove vaga suspeita (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
          tags: ["Admin"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          responses: {
            200: { description: "Vaga removida com sucesso" },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
            404: { description: "Vaga não encontrada" },
          },
        },
      },

      "/admin/usuarios/admin": {
        post: {
          summary: "Cria outro administrador (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
          tags: ["Admin"],
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  required: ["nome_exibicao", "email", "senha"],
                  properties: {
                    nome_exibicao: { type: "string", example: "Novo Admin" },
                    email: { type: "string", example: "admin2@nexa.com" },
                    senha: { type: "string", example: "123456" },
                  },
                },
              },
            },
          },
          responses: {
            201: { description: "Administrador criado com sucesso" },
            400: { description: "Dados inválidos" },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
          },
        },
      },

      "/admin/usuarios/{id}": {
        delete: {
          summary: "Remove usuário (Apenas Admin)",
          description: "Requer usuário autenticado com perfil admin.",
          tags: ["Admin"],
          security: [{ bearerAuth: [] }],
          parameters: [{ name: "id", in: "path", required: true, schema: { type: "integer" } }],
          responses: {
            200: { description: "Usuário removido com sucesso" },
            400: { description: "ID inválido" },
            401: { description: "Não autorizado" },
            403: { description: "Apenas administradores" },
            404: { description: "Usuário não encontrado" },
          },
        },
      },

    },
  },
  apis: [],
};

export const swaggerSpec = swaggerJSDoc(options);