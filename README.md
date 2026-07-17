# Sistema Web para Laboratório de Pesquisa

Sistema de gestão e divulgação de publicações científicas de um laboratório de pesquisa: área pública com o catálogo de artigos publicados e módulo autenticado para cadastro, submissão, avaliação e publicação de artigos — com autenticação forte WebAuthn e conteúdo criptografado, inacessível inclusive ao administrador.

## Stack

| Camada | Tecnologia | ADR |
|---|---|---|
| Frontend | Next.js (React 19, Tailwind 4) | [ADR-002](docs/adrs/ADR-002-nextjs-frontend.md) |
| Backend | Java 21 + Spring Boot 4 (monólito modular, hexagonal) | [ADR-001](docs/adrs/ADR-001-monolito-modular.md), [ADR-003](docs/adrs/ADR-003-java-spring-boot.md) |
| Banco de dados | PostgreSQL 16 + Flyway | [ADR-004](docs/adrs/ADR-004-postgresql.md) |
| Arquivos (artigos, cartas) | MinIO (S3), conteúdo cifrado | [ADR-005](docs/adrs/ADR-005-minio-objetos.md) |
| Autenticação forte | WebAuthn (WebAuthn4J) | [ADR-006](docs/adrs/ADR-006-webauthn4j-fido2.md) |
| Gestão de chaves | HashiCorp Vault (Transit) — criptografia envelope | [ADR-007](docs/adrs/ADR-007-vault-criptografia-envelope.md) |
| Sessões | Spring Session JDBC (server-side) | [ADR-008](docs/adrs/ADR-008-spring-session.md) |
| Infra | Docker Compose + Nginx (TLS, único ponto exposto) | [ADR-009](docs/adrs/ADR-009-docker-nginx.md) |

## Como rodar (desenvolvimento)

Passo-a-passo de subida a partir de um clone limpo. Pré-requisitos: **Docker Desktop** (com Compose v2) e **OpenSSL** (para gerar o certificado de dev).

### 1. Variáveis de ambiente

```sh
cp .env.example .env
```

Edite o `.env` e troque **todas** as senhas (`POSTGRES_PASSWORD`, `LAB_APP_PASSWORD`, `MINIO_ROOT_PASSWORD`) e o `VAULT_TOKEN`. Ajuste `SMTP_HOST`/`SMTP_PORT` conforme o ambiente. O `.env` é ignorado pelo Git — nunca versione o arquivo real.

> `POSTGRES_USER` **não** pode se chamar `lab_app`: esse nome é reservado para o role de runtime da aplicação (ver [Banco de dados](#banco-de-dados)).

### 2. Certificado TLS de desenvolvimento

O diretório `infra/nginx/certs/` está no `.gitignore`, então um clone novo **não** vem com o certificado. Sem ele o Nginx não sobe. Gere um par autoassinado:

```sh
mkdir -p infra/nginx/certs
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout infra/nginx/certs/server.key \
  -out infra/nginx/certs/server.crt \
  -subj "/CN=localhost"
```

Em produção esse par é substituído por certificados TLS reais.

### 3. (Opcional) Expor Postgres e MinIO no host

O `docker-compose.override.yml` (também ignorado pelo Git) publica o Postgres em `127.0.0.1:5432` (para DBeaver/psql) e o console do MinIO em `127.0.0.1:9001`. É carregado automaticamente pelo `docker compose` quando presente. Pule este passo se não precisar acessar esses serviços direto do host — eles continuam acessíveis pela rede interna dos containers.

### 4. Subir a stack

```sh
docker compose up -d --build
```

Na primeira subida, além dos serviços principais, rodam dois containers one-shot que finalizam sozinhos (`Exited (0)`):

- **`minio-init`** — cria o bucket `${MINIO_BUCKET}`.
- **`vault-init`** — habilita o engine Transit e cria a KEK `${VAULT_KEK_NAME}`.

As migrations Flyway rodam automaticamente na inicialização do backend.

### 5. Verificar

```sh
docker compose ps        # aguarde postgres/minio/vault/backend/nginx "healthy"
docker compose logs -f backend   # opcional: acompanhar migrations e boot do Spring
```

O backend tem `start_period` de 60s no healthcheck; a primeira subida (build do jar + migrations) pode levar alguns minutos. O Nginx só fica `healthy` depois que o backend passa a responder.

### 6. Acessar

- **App:** https://localhost — certificado autoassinado em dev, o navegador vai alertar (aceite a exceção).
- **Console do MinIO** (só com o override do passo 3): http://localhost:9001 — login com `MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD` do `.env`.

O Nginx é o **único** serviço com portas publicadas (443/80; a 80 apenas redireciona para 443); ele roteia `/` para o frontend e `/api` para o backend. Postgres, MinIO e Vault ficam em rede interna isolada.

### Parar e recomeçar

```sh
docker compose down          # para os containers, preserva os volumes (dados)
docker compose down -v       # para e APAGA os volumes (banco, MinIO) — reinício limpo
```

## Banco de dados

### Papéis (ADR-004)

- **`lab_admin`** (`POSTGRES_USER`): superusuário, dono das tabelas. Usado apenas pelo Flyway nas migrations.
- **`lab_app`**: role de runtime da aplicação, criado por [infra/postgres/init/01-app-role.sh](infra/postgres/init/01-app-role.sh) na primeira inicialização do volume. Não é dono de nada — por isso o `REVOKE` de `UPDATE/DELETE` na tabela `evento_auditoria` torna a trilha de auditoria **append-only no próprio banco** (RNF05), não apenas por convenção de código.

### Migrations

Ficam em [backend/lab/src/main/resources/db/migration](backend/lab/src/main/resources/db/migration). Enquanto o esquema inicial (V1) ainda está sendo moldado, alterações no V1 exigem recriar o banco (o Flyway valida por checksum):

```sh
docker compose down -v          # apaga os volumes (dados de dev!)
docker compose up -d --build    # rebuilda o backend (migration vai no jar) e reaplica
```

Após o primeiro deploy real, o V1 congela e mudanças viram `V2__...`, `V3__...`.

## Estrutura do repositório

```
backend/lab/       API Spring Boot (módulos: audit, crypto, ...)
frontend/          Next.js (área pública + módulo autenticado)
infra/nginx/       Proxy reverso, certificados TLS de dev
infra/postgres/    Script de init (role lab_app)
docs/              Requisitos, definição arquitetural, especificação da API
docs/adrs/         Registros de decisão de arquitetura (ADR-001..009)
```

## Documentação

- [Requisitos do sistema](docs/requisitos_sistema_laboratorio.md) — atores, casos de uso, RF/RNF/RN, máquina de estados do artigo
- [Definição arquitetural](docs/definicao_arquitetural.md) — visões C4, módulos, segurança, dados
- [Especificação da API](docs/especificacao_api.md)
- [Plano de execução](docs/plano_execucao.md)

## Segurança (resumo)

- Todo artigo nasce **não público** e seu conteúdo é cifrado por artigo (criptografia envelope: DEK cifrada no banco, KEK no Vault Transit) — nem o administrador acessa conteúdo não público.
- Qualquer interação com artigo não público exige **step-up WebAuthn** (chave USB, biometria/PIN de plataforma ou passkey).
- Auditoria **append-only** com hash SHA-256 encadeado, imposta por permissão de banco.
