# Documento de Definição Arquitetural

## Sistema Web para Laboratório de Pesquisa

**Versão:** 1.1
**Data:** 13/07/2026
**Documento base:** Documento de Elicitação de Requisitos v1.4

### Histórico de Revisões

| Versão | Data | Alterações |
|---|---|---|
| 1.0 | 13/07/2026 | Versão inicial (requisitos v1.3). |
| 1.1 | 13/07/2026 | Adequação aos requisitos v1.4: autenticação forte generalizada de chave física USB FIDO2 para o padrão WebAuthn com múltiplos autenticadores (chave USB, autenticador de plataforma com biometria/PIN, passkeys); removida a restrição de transporte USB nas cerimônias; terminologia atualizada de "chave física" para "credencial WebAuthn"; ADR-006 revisada. |

---

## 1. Introdução

### 1.1 Objetivo

Este documento define a arquitetura de software do Sistema Web para Laboratório de Pesquisa, descrevendo o estilo arquitetural, a decomposição em módulos, as visões de contexto, contêineres e componentes, a arquitetura de segurança e de dados, e o mapeamento entre decisões arquiteturais e os requisitos elicitados (v1.3).

Cada tecnologia adotada possui um Registro de Decisão de Arquitetura (ADR) correspondente na pasta `adrs/`, seguindo o template `adrs/ADR-000-template.md`.

### 1.2 Escopo

Cobre a área pública (catálogo de publicações), o módulo autenticado (cadastro, submissão, avaliação e publicação de artigos), a gestão administrativa (usuários, vínculos, credenciais WebAuthn) e a infraestrutura de segurança (WebAuthn, criptografia em repouso, auditoria).

## 2. Direcionadores Arquiteturais

Os requisitos que mais influenciam a arquitetura (architectural drivers):

| Direcionador | Origem | Impacto arquitetural |
|---|---|---|
| Confidencialidade de artigos não públicos, inclusive contra o administrador | RF05, RF15, RNF12, RN02, RN10 | Criptografia envelope por artigo com gestão de chaves externa à aplicação; liberação de chave condicionada à autorização + prova WebAuthn |
| Autenticação forte WebAuthn (múltiplos autenticadores: chave USB, biometria/PIN de plataforma, passkey) para toda interação com artigo não público | RF09, RF10, RNF04, RN03, US07 | Camada de *step-up authentication* no backend; cerimônias WebAuthn no frontend, agnósticas ao tipo de autenticador; ciclo de vida de credenciais (UC09) |
| Auditoria imutável (≥ 12 meses) | RF11, RNF05, RN08 | Trilha de auditoria *append-only* com encadeamento de hash |
| Área pública responsiva e rápida; módulo autenticado somente desktop | RNF01, RNF06, RE05 | Separação de renderização: páginas públicas com SSR/cache; bloqueio de dispositivos móveis no módulo autenticado |
| Escala moderada (100 usuários simultâneos, p95 < 3 s) | RNF06, RNF07 | Não justifica microsserviços; monólito modular com cache atende com folga |
| Máquina de estados do artigo e fluxos de aprovação | Seção 5 dos requisitos, RN01–RN15 | Lógica de domínio centralizada; transições validadas no servidor |
| Notificações e lembretes automáticos | RF08, RF22, RN15 | Envio de e-mail assíncrono e agendador de tarefas |
| Infraestrutura conforme políticas da instituição | RE04 | Conteinerização para portabilidade entre ambientes institucionais |

## 3. Restrições Arquiteturais

Derivadas da seção 8 dos requisitos e da decisão de stack do laboratório: frontend em **Next.js** e backend em **Java + Spring Boot** (definição do cliente); autenticação forte com autenticadores compatíveis com WebAuthn suportados pela estação — chave USB, autenticador de plataforma ou passkey (RE01, RE05); compatibilidade com Chrome, Firefox, Edge e Safari atualizados (RE03); hospedagem em infraestrutura institucional (RE04); comunicação exclusivamente via HTTPS/TLS 1.2+ (RNF02).

## 4. Estilo Arquitetural

Adota-se um **monólito modular** (ADR-001): uma única aplicação backend Spring Boot organizada em módulos de domínio com fronteiras explícitas, consumida por uma aplicação frontend Next.js via API REST. Justificativa resumida: a escala exigida (RNF06/RNF07) não demanda distribuição; um monólito reduz custo operacional na infraestrutura institucional (RE04) e simplifica a consistência transacional da máquina de estados do artigo, enquanto a modularização interna preserva manutenibilidade e evolução (RNF10) — incluindo eventual extração futura de serviços.

O padrão interno de cada módulo é **arquitetura hexagonal simplificada** (ports & adapters): domínio isolado de detalhes de persistência, criptografia e notificação, o que facilita testes e a substituição de adaptadores (ex.: provedor de KMS).

## 5. Visão de Contexto (C4 — Nível 1)

```
                        ┌──────────────────────────────┐
  Visitante ───────────►│                              │
  (qualquer dispositivo)│                              │──► Servidor SMTP
                        │   Sistema Web do             │    institucional
  Aluno / Orientador /  │   Laboratório de Pesquisa    │    (notificações RF08/RF22)
  Co-orientador ───────►│                              │
  (desktop + WebAuthn)  │                              │
                        │                              │
  Administrador ───────►│                              │
  (desktop)             └──────────────────────────────┘
```

Não há integrações com sistemas externos além do SMTP institucional. Os autenticadores WebAuthn (chave USB, biometria/PIN de plataforma ou passkey) interagem diretamente com o navegador (API WebAuthn), não com o servidor.

## 6. Visão de Contêineres (C4 — Nível 2)

| Contêiner | Tecnologia | Responsabilidade |
|---|---|---|
| **Frontend Web** | Next.js 15 (React 19, TypeScript) — ADR-002 | Área pública (SSR/ISR, responsiva, WCAG 2.1 AA) e módulo autenticado (desktop-only); cerimônias WebAuthn via API do navegador |
| **Backend API** | Java 21 + Spring Boot 3.x — ADR-003 | API REST, regras de negócio, máquina de estados, autorização, orquestração de criptografia, agendador de lembretes, envio de e-mail |
| **Banco de dados** | PostgreSQL 16 — ADR-004 | Dados relacionais: usuários, vínculos, artigos (metadados), pareceres, credenciais WebAuthn, sessões, auditoria |
| **Armazenamento de objetos** | MinIO (API S3) — ADR-005 | Arquivos de artigos (cifrados) e cartas de aceite |
| **Gestão de segredos/chaves** | HashiCorp Vault (Transit) — ADR-007 | KEK da criptografia envelope; segredos da aplicação |
| **Proxy reverso** | Nginx | Terminação TLS 1.2+, cache de estáticos, roteamento frontend/backend |

Todos os contêineres executam via Docker/Docker Compose (ADR-009) na infraestrutura institucional.

```
[Navegador] ──TLS──► [Nginx] ──► [Next.js] ──► [Spring Boot API] ──► [PostgreSQL]
                        │                            │  ├──► [MinIO]
                        └────────► /api ─────────────┘  ├──► [Vault]
                                                        └──► [SMTP]
```

## 7. Visão de Componentes do Backend (C4 — Nível 3)

| Módulo | Responsabilidade | Requisitos |
|---|---|---|
| `identity` | Autenticação (login/senha, recuperação), sessões, perfis (RN09), gestão de usuários e vínculos aluno–orientador | RF02, RF12, UC01, UC08 |
| `webauthn` | Registro e verificação de credenciais WebAuthn (qualquer tipo de autenticador), ciclo de vida das credenciais (registrar/vincular/revogar/substituir), *step-up* por artigo não público | RF09, RF10, RF16, UC05, UC09, RN03, RN11 |
| `articles` | CRUD de artigos, coautores (membros e externos), máquina de estados, visibilidade (criação sempre não pública — RF04) e fluxo de reversão com aprovação (RF18) | RF03, RF04, RF05, RF13, RF17, RF18, RF19, UC03, UC07, UC10, RN01, RN02, RN06, RN07, RN12 |
| `review` | Submissão com evento alvo/deadline obrigatórios (RF21), pareceres decisório e complementar (RF07), prazo sugerido, lembretes | RF06, RF07, RF08, RF20, RF21, RF22, UC04, UC06, RN04, RN05, RN13, RN15 |
| `documents` | Upload/download de arquivos e carta de aceite, validação de formato | RF14, RF23, UC11, RN14 |
| `crypto` | Criptografia envelope (DEK por artigo, KEK no Vault), cifra/decifra de conteúdo | RF15, RNF12 |
| `audit` | Trilha *append-only* com hash encadeado, bloqueio temporário por falhas (RN08) | RF11, RNF05, RN08 |
| `notification` | E-mail assíncrono + notificações no sistema; agendador de lembretes | RF08, RF22, RN15 |
| `publicapi` | Endpoints públicos somente-leitura do catálogo, com cache | RF01, RNF06 |

Dependências entre módulos ocorrem apenas por interfaces (ports); `crypto` e `audit` são transversais, invocados por `articles`, `review` e `documents`.

## 8. Arquitetura de Segurança

### 8.1 Autenticação em duas camadas

1. **Sessão base** — login usuário/senha (hash Argon2id — RNF03), sessão server-side com cookie `HttpOnly/Secure/SameSite=Strict` e expiração por 30 min de inatividade (RNF13), via Spring Session JDBC (ADR-008).
2. **Step-up WebAuthn** — toda requisição que toque artigo não público exige prova WebAuthn recente (janela curta, por artigo/ação), aceitando qualquer autenticador registrado do usuário (chave USB, biometria/PIN de plataforma ou passkey), sempre com verificação de usuário obrigatória (`userVerification: required`). O backend emite o desafio, valida assinatura, origem e contador da credencial (Spring Security + WebAuthn4J — ADR-006) e registra o resultado em auditoria. Falha → HTTP 403 + log (RF10, RF11); 5 falhas consecutivas → bloqueio de 15 min (RN08).

### 8.2 Confidencialidade contra o administrador (RNF12)

Criptografia envelope (ADR-007): cada artigo não público possui uma **DEK** (AES-256-GCM) exclusiva, que cifra arquivo (no MinIO) e campos sensíveis. A DEK é armazenada apenas cifrada pela **KEK** mantida no Vault Transit — a KEK nunca sai do Vault. A decifragem da DEK só é executada pela aplicação após (a) verificação de autorização RN02 e (b) prova WebAuthn válida (RN03). O administrador não possui rota funcional de acesso ao conteúdo, e o acesso direto ao banco/objetos revela apenas dados cifrados. Ao tornar público (UC07), o conteúdo é decifrado para a área pública; na reversão (RN07), é recifrado com nova DEK.

### 8.3 Auditoria (RNF05)

Tabela *append-only* (sem UPDATE/DELETE, garantido por permissão de banco) com hash SHA-256 encadeado ao registro anterior, permitindo detecção de adulteração. Retenção mínima de 12 meses com arquivamento.

### 8.4 Restrição de dispositivo (RNF01, RE05)

O módulo autenticado bloqueia dispositivos móveis em duas camadas: no frontend (detecção de user-agent/viewport com página de aviso) e no backend (rejeição de login a partir de user-agents móveis). As cerimônias WebAuthn não restringem o tipo de autenticador (RE05): o usuário utiliza os autenticadores suportados pelo navegador e sistema operacional da estação, sempre com verificação de presença/usuário (RNF04).

## 9. Arquitetura de Dados

Principais agregados (PostgreSQL — ADR-004):

- **Usuario** (perfil único ativo — RN09), **VinculoAlunoOrientador**, **CredencialWebAuthn** (1 credencial ↔ 1 usuário — RN11, com tipo de autenticador e status ativo/revogado).
- **Artigo** (metadados, estado, visibilidade, autor principal, coautores membros e externos, DEK cifrada), **Submissao** (evento alvo, deadline, prazo sugerido, orientador, co-orientador), **Parecer** (decisório/complementar), **Documento** (arquivo do artigo, carta de aceite — ponteiros para MinIO), **EventoAuditoria**.

A máquina de estados do artigo (Rascunho → Aguardando parecer → Avaliado → Público → …) é implementada no domínio do módulo `articles`, com transições validadas exclusivamente no servidor. Exclusão é sempre lógica (RF17). Evolução de esquema versionada com Flyway (ADR-004). Dados pessoais tratados conforme LGPD (RNF11): minimização, exclusão lógica com anonimização programável e registro de finalidade.

## 10. Visão de Implantação

Docker Compose (ADR-009) em servidor institucional único (RE04): contêineres `nginx`, `frontend`, `backend`, `postgres`, `minio`, `vault`, em rede interna isolada — apenas o Nginx expõe portas (443). Backups diários de PostgreSQL e MinIO; *snapshot* do Vault com política de acesso restrita (o operador de infraestrutura não obtém a KEK em claro). Uptime alvo de 99% mensal (RNF08) atendido com *restart policies*, *health checks* e janela de manutenção mensal.

## 11. Atributos de Qualidade — Atendimento

| RNF | Estratégia arquitetural |
|---|---|
| RNF01 | Next.js responsivo na área pública; bloqueio móvel duplo no módulo autenticado |
| RNF02 | TLS 1.2+ terminado no Nginx; HSTS; cookies Secure |
| RNF03 | Argon2id com salt (Spring Security) |
| RNF04 | WebAuthn com múltiplos tipos de autenticador, verificação de usuário obrigatória e validação de assinatura de desafio, origem e contador (ADR-006) |
| RNF05 | Auditoria append-only com hash encadeado, retenção ≥ 12 meses |
| RNF06/07 | SSR + cache (ISR) na área pública; pool de conexões; índices; ~100 usuários simultâneos com folga em instância única |
| RNF08 | Health checks, restart automático, backups testados |
| RNF09 | Componentes acessíveis (WCAG 2.1 AA) na área pública; testes com axe-core |
| RNF10 | Monólito modular hexagonal; ADRs; documentação de API (OpenAPI) |
| RNF11 | Minimização de dados, exclusão lógica/anonimização, consentimento e finalidade registrados |
| RNF12 | Criptografia envelope AES-256-GCM + Vault Transit (ADR-007) |
| RNF13 | Spring Session com timeout de 30 min de inatividade (ADR-008) |

## 12. Tecnologias Adotadas e ADRs

| # | Tecnologia / Decisão | ADR |
|---|---|---|
| 1 | Estilo arquitetural: monólito modular | [ADR-001](adrs/ADR-001-monolito-modular.md) |
| 2 | Frontend: Next.js (React + TypeScript) | [ADR-002](adrs/ADR-002-nextjs-frontend.md) |
| 3 | Backend: Java 21 + Spring Boot 3 | [ADR-003](adrs/ADR-003-java-spring-boot.md) |
| 4 | Banco de dados: PostgreSQL (+ Flyway) | [ADR-004](adrs/ADR-004-postgresql.md) |
| 5 | Armazenamento de objetos: MinIO | [ADR-005](adrs/ADR-005-minio-objetos.md) |
| 6 | Autenticação forte WebAuthn: Spring Security + WebAuthn4J | [ADR-006](adrs/ADR-006-webauthn4j-fido2.md) |
| 7 | Criptografia e chaves: AES-256-GCM + HashiCorp Vault | [ADR-007](adrs/ADR-007-vault-criptografia-envelope.md) |
| 8 | Sessões: Spring Session JDBC (cookies HttpOnly) | [ADR-008](adrs/ADR-008-spring-session.md) |
| 9 | Implantação: Docker + Docker Compose + Nginx | [ADR-009](adrs/ADR-009-docker-nginx.md) |

## 13. Decisões em Aberto

Orçamento e prazo (RE02) permanecem pendentes e podem impor simplificações (ex.: adiar Vault em favor de KEK em arquivo protegido — desaconselhado frente ao RNF12). Políticas específicas de segurança da instituição (RE04) devem ser confirmadas antes da implantação.
