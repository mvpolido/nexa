import swaggerJSDoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'API Nexa',
      version: '1.0.0',
      description: 'Documentação da API',
    },
    paths: {
      '/health': {
        get: {
          summary: 'Verifica se a API está funcionando',
          responses: { 200: { description: 'OK' } }
        }
      },
      '/auth/login': {
        post: {
          summary: 'Autentica um usuário',
          responses: { 200: { description: 'OK' } }
        }
      },
      '/users/profile': {
        get: {
          summary: 'Perfil do usuário',
          responses: { 200: { description: 'OK' } }
        }
      }
    }
  },
  apis: [], // DEIXE VAZIO! Assim ele não tenta ler seus arquivos e não crasha.
};

export const swaggerSpec = swaggerJSDoc(options);