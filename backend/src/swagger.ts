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
          responses: { 200: { description: 'OK' } }
        }
      },
      // 👇 AS NOVAS ROTAS DE USUÁRIO APARECEM AQUI 👇
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
                    name: { type: 'string', example: 'Felipe Salazar' },
                    email: { type: 'string', example: 'felipe@teste.com' },
                    password: { type: 'string', example: 'senha123' },
                    role: { type: 'string', example: 'aluno' }
                  }
                }
              }
            }
          },
          responses: {
            201: { description: 'Usuário criado com sucesso' },
            400: { description: 'E-mail já cadastrado' }
          }
        },
        get: {
          summary: 'Lista todos os usuários',
          tags: ['Users'],
          responses: { 200: { description: 'OK' } }
        }
      },
      '/users/{id}': {
        get: {
          summary: 'Busca um usuário pelo ID',
          tags: ['Users'],
          parameters: [
            { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
          ],
          responses: { 200: { description: 'OK' }, 404: { description: 'Não encontrado' } }
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
                    name: { type: 'string', example: 'Felipe Atualizado' },
                    role: { type: 'string', example: 'empresa' }
                  }
                }
              }
            }
          },
          responses: { 200: { description: 'OK' } }
        },
        delete: {
          summary: 'Deleta um usuário',
          tags: ['Users'],
          parameters: [
            { name: 'id', in: 'path', required: true, schema: { type: 'string' } }
          ],
          responses: { 200: { description: 'OK' } }
        }
      }
    }
  },
  apis: [], 
};

export const swaggerSpec = swaggerJSDoc(options);