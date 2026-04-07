# Estágio de build
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Estágio de execução
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production
# Copia o código compilado da pasta dist
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/index.js"]