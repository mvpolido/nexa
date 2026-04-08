import swaggerJSDoc from 'swagger-jsdoc';
import path from 'path'; // Adicione este import

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'API Nexa',
      version: '1.0.0',
      description: 'Documentação da API',
    },
  },
  // Usar path.join garante que funcione no Windows e no Linux/Docker
  apis: [
    path.join(__dirname, './index.ts'),
    path.join(__dirname, './index.js'),
    path.join(__dirname, './routes/*.ts'),
    path.join(__dirname, './routes/*.js'),
  ],
};

export const swaggerSpec = swaggerJSDoc(options);