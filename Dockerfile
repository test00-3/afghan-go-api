FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npx tsc src/server.ts --outDir dist --esModuleInterop --resolveJsonModule --skipLibCheck --target ES2020 --module commonjs

EXPOSE 3000

CMD ["node", "dist/server.js"]
