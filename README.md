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

Pré-requisitos: Docker Desktop (com Compose v2).

```sh
# 1. Configure as variáveis de ambiente
cp .env.example .env   # ajuste as senhas

# 2. Suba tudo
docker compose up -d

# 3. Acompanhe até os serviços ficarem healthy
docker compose ps
```

Acesso: **https://localhost** (certificado autoassinado em dev — o navegador vai alertar). O Nginx é o único serviço com portas publicadas; ele roteia `/` para o frontend e `/api` para o backend. Postgres, MinIO e Vault ficam em rede interna isolada.

As migrations Flyway rodam automaticamente na subida do backend.

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
