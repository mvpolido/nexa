import swaggerJSDoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'API Nexa',
      version: '1.0.0',
      description: 'Documentação da API do Nexa',
    },
    paths: {
      '/health': {
        get: {
          summary: 'Verifica se a API está funcionando',
          tags: ['Health'],
          responses: { 200: { description: 'OK' } }
        }
      },
      '/auth/login': {
        post: {
          summary: 'Autentica um usuário',
          tags: ['Auth'],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    email: { type: 'string', example: 'felipe@teste.com' },
                    senha: { type: 'string', example: 'senha123' }
                  }
                }
              }
            }
          },
          responses: { 200: { description: 'Login realizado com sucesso' } }
        }
      },
      '/users': {
        post: {
          summary: 'Cria um novo usuário',
          tags: ['Users'],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    nome_exibicao: { type: 'string', example: 'Felipe Salazar' }, // 👈 Corrigido
                    email: { type: 'string', example: 'felipe@teste.com' },
                    senha: { type: 'string', example: 'senha123' },            // 👈 Corrigido
                    perfil: { 
                      type: 'string', 
                      enum: ['aluno', 'empresa'], 
                      example: 'aluno' 
                    }                                                         // 👈 Corrigido
                  }
                }
              }
            }
          },
          responses: {
            201: { 
              description: 'Usuário criado com sucesso',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      id: { type: 'string' },
                      nome_exibicao: { type: 'string' },
                      email: { type: 'string' },
                      perfil: { type: 'string' }
                      // Note que a senha_hash não aparece aqui!
                    }
                  }
                }
              }
            },
            400: { description: 'E-mail já cadastrado' }
          }
        },
        get: {
          summary: 'Lista todos os usuários',
          tags: ['Users'],
          responses: { 
            200: { 
              description: 'Lista de usuários (sem senhas)',
              content: {
                'application/json': {
                  schema: {
                    type: 'array',
                    items: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nome_exibicao: { type: 'string' },
                        email: { type: 'string' },
                        perfil: { type: 'string' }
                      }
                    }
                  }
                }
              }
            } 
          }
        }
      },
      '/users/{id}': {
        get: {
          summary: 'Busca um usuário pelo ID',
          tags: ['Users'],
          parameters: [
            { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
          ],
          responses: { 
            200: { description: 'Usuário encontrado' }, 
            404: { description: 'Não encontrado' } 
          }
        },
        put: {
          summary: 'Atualiza um usuário',
          tags: ['Users'],
          parameters: [
            { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
          ],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    nome_exibicao: { type: 'string', example: 'Felipe Atualizado' },
                    perfil: { type: 'string', enum: ['aluno', 'empresa'], example: 'empresa' }
                  }
                }
              }
            }
          },
          responses: { 200: { description: 'Usuário atualizado com sucesso' } }
        },
        delete: {
          summary: 'Deleta um usuário',
          tags: ['Users'],
          parameters: [
            { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
          ],
          responses: { 200: { description: 'Usuário deletado com sucesso' } }
        }
      }
    }
  },
  apis: [], 
};

export const swaggerSpec = swaggerJSDoc(options);