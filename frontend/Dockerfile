# Frontend Next.js 16 (React 19). Build multi-stage com saída "standalone".

# ---- Estágio 1: dependências ----
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# ---- Estágio 2: build ----
FROM node:22-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN yarn build

# ---- Estágio 3: runtime ----
FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Usuário não-root por segurança.
RUN addgroup -S app && adduser -S app -G app

# A saída standalone traz o server.js e só as dependências realmente usadas.
# public e .next/static precisam ser copiados à parte (comportamento do standalone).
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static
COPY --from=build /app/public ./public

USER app
EXPOSE 3000
CMD ["node", "server.js"]
