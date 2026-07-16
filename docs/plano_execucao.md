# Plano de Execução — Sistema Web para Laboratório de Pesquisa

**Base:** Requisitos v1.4 · Definição Arquitetural v1.1 · Especificação da API v1.0
**Estado atual:** documentação e infraestrutura (docker-compose, nginx+TLS) prontos; backend apenas no esqueleto `demo`; frontend apenas no scaffold `create-next-app`.

> Legenda: 🔐 = endpoint com step-up WebAuthn · As fases seguem a ordem de dependência (cada uma destrava a seguinte).

---

## Fase 0 — Fundação (destrava todo o resto)

### 0.1 Reestruturar backend em módulos de domínio
- [ ] Renomear o artefato/pacote `com.example.demo` para o namespace do projeto (ex.: `br.ufg.lab`)
- [ ] Criar a estrutura de pacotes por módulo: `identity`, `webauthn`, `articles`, `review`, `documents`, `crypto`, `audit`, `notification`, `publicapi`
- [ ] Em cada módulo, aplicar o padrão hexagonal: subpacotes `domain` (entidades/regras), `application` (ports/serviços), `adapter` (in: REST · out: persistência/crypto/notificação)
- [ ] Definir os *ports* (interfaces) para os transversais `crypto` e `audit`, consumidos por `articles`, `review` e `documents`
- [ ] Configurar `ArchUnit` (ou similar) para proibir dependências que atravessem as fronteiras de módulo sem passar por ports
- [ ] Ajustar `application.properties`/`application.yml` por perfil (`dev`, `docker`, `prod`)

### 0.2 Primeira migration Flyway (schema inicial)
- [ ] Adicionar `V1__schema_inicial.sql` em `src/main/resources/db/migration`
- [ ] Tabela `usuario` (id, nome, email único, hash_senha, perfil, ativo, timestamps) — perfil único ativo (RN09)
- [ ] Tabela `vinculo_aluno_orientador` (aluno_id, orientador_id, ativo)
- [ ] Tabela `credencial_webauthn` (usuario_id, credential_id único, public_key, contador, tipo_autenticador, status ativo/revogado) — 1 credencial ↔ 1 usuário (RN11)
- [ ] Tabela `artigo` (metadados, estado, visibilidade, autor_principal, dek_cifrada, excluido_logico)
- [ ] Tabelas `artigo_coautor_membro` e `artigo_coautor_externo` (RF19)
- [ ] Tabela `submissao` (artigo_id, evento_alvo, deadline, prazo_sugerido, orientador_id, coorientador_id)
- [ ] Tabela `parecer` (submissao_id, tipo decisório/complementar, conteúdo, autor_id)
- [ ] Tabela `documento` (artigo_id, tipo arquivo/carta_aceite, ponteiro_minio, formato)
- [ ] Tabela `evento_auditoria` **append-only** com `hash_anterior` + `hash_atual` (SHA-256 encadeado — RNF05)
- [ ] Tabela de reversão (`reversao`: artigo_id, solicitante, justificativa, status, decisor)
- [ ] Migration da tabela `SPRING_SESSION` (mover o DDL do `initialize-schema`)
- [ ] Trocar `spring.session.jdbc.initialize-schema` de `always` para `never`
- [ ] Aplicar permissões de banco que impeçam `UPDATE`/`DELETE` em `evento_auditoria`

### 0.3 Validar stack completo no docker-compose
- [ ] Subir `postgres`, `minio`, `vault`, `backend`, `frontend`, `nginx`
- [ ] Confirmar que o Flyway aplica `V1` na inicialização do backend
- [ ] Validar `/actuator/health` do backend (dependências postgres/minio/vault healthy)
- [ ] Confirmar terminação TLS no nginx e roteamento `/` (frontend) e `/api` (backend)
- [ ] Provisionar o Vault Transit (engine + KEK) e testar cifra/decifra de um valor de exemplo
- [ ] Criar bucket inicial no MinIO e testar upload/download de um objeto de exemplo
- [ ] Documentar o passo-a-passo de subida no `README.md` da raiz

---

## Fase 1 — Módulo `identity` (autenticação, sessão e administração)

### 1.1 Autenticação e sessão
- [ ] Entidade `Usuario` (JPA) e repositório
- [ ] Encoder Argon2id no Spring Security (RNF03)
- [ ] Sessão server-side via Spring Session JDBC, cookie `HttpOnly/Secure/SameSite=Strict`, timeout 30 min (RNF13 · ADR-008)
- [ ] `[POST] /api/auth/login` — emite cookie de sessão
- [ ] `[POST] /api/auth/logout` — encerra sessão (204)
- [ ] `[GET] /api/auth/me` — usuário, perfil ativo (RN09) e estado do step-up WebAuthn
- [ ] Filtro/interceptor que rejeita user-agent móvel no login com `[403]` (RNF01/RE05)
- [ ] Registrar login/logout na auditoria

### 1.2 Recuperação de senha
- [ ] `[POST] /api/auth/recuperar-senha` — resposta uniforme 202 (anti-enumeração)
- [ ] Geração de token de redefinição com expiração
- [ ] `[POST] /api/auth/redefinir-senha` — valida política de senha, aplica Argon2id, trata token expirado `[410]`
- [ ] Envio do e-mail de recuperação (integra com `notification` quando disponível)

### 1.3 Administração de usuários e vínculos (UC08)
- [ ] `[GET] /api/admin/usuarios` — lista paginada (403 se não admin)
- [ ] `[POST] /api/admin/usuarios` — cria com perfil único (409 e-mail duplicado)
- [ ] `[PUT] /api/admin/usuarios/{id}` — atualiza dados/perfil/ativação
- [ ] `[DELETE] /api/admin/usuarios/{id}` — desativa/remove
- [ ] `[GET] /api/admin/vinculos` — lista vínculos aluno-orientador
- [ ] `[POST] /api/admin/vinculos` — cria vínculo (400 perfis incompatíveis · 409 duplicado)
- [ ] `[DELETE] /api/admin/vinculos/{id}` — encerra vínculo
- [ ] Testes de autorização por perfil (admin vs. demais)

---

## Fase 2 — Transversais de segurança (`audit`, `crypto`, `webauthn`)

### 2.1 Auditoria (RNF05, RN08)
- [ ] Serviço `audit` append-only com cálculo de hash encadeado (SHA-256 do registro + hash anterior)
- [ ] API interna (port) para registrar eventos a partir de qualquer módulo
- [ ] Verificação de integridade da cadeia (job/endpoint de conferência)
- [ ] Contador de falhas consecutivas de WebAuthn + bloqueio de 15 min (RN08)

### 2.2 Criptografia envelope (RNF12 · ADR-007)
- [ ] Cliente do Vault Transit (KEK nunca sai do Vault)
- [ ] Geração de DEK por artigo (AES-256-GCM), armazenada cifrada pela KEK
- [ ] `encrypt`/`decrypt` de arquivos (MinIO) e campos sensíveis
- [ ] Decifra da DEK condicionada a autorização (RN02) **e** step-up válido (RN03)
- [ ] Recifra com nova DEK na reversão para não público (RN07)

### 2.3 WebAuthn — registro e step-up (RF09, RF10, RF16 · ADR-006)
- [ ] Integração do WebAuthn4J + configuração de RP (relying party)
- [ ] `[POST] /api/admin/credenciais/opcoes-registro` — opções de registro (qualquer autenticador, `userVerification: required`)
- [ ] `[POST] /api/admin/credenciais` — valida attestation, vincula a 1 usuário (RN11), audita (409 credentialId duplicado)
- [ ] `[GET] /api/admin/credenciais` — lista com usuário, tipo e status
- [ ] `[POST] /api/admin/credenciais/{id}/revogar` — revoga imediatamente (409 já revogada)
- [ ] `[POST] /api/webauthn/desafio` — opções de assertion (404 sem credencial · 423 bloqueado)
- [ ] `[POST] /api/webauthn/verificar` — valida assinatura/origem/contador, abre janela de step-up na sessão, audita (401 falha · 423 bloqueio)
- [ ] Filtro de *step-up*: endpoints 🔐 sem prova recente respondem `[428]`
- [ ] Testes: assertion válida, expirada, credencial revogada, 5 falhas → bloqueio

---

## Fase 3 — Núcleo de negócio

### 3.1 Artigos (UC03, UC10 · máquina de estados)
- [ ] Entidade `Artigo` + máquina de estados (Rascunho → Aguardando parecer → Avaliado → Público → …)
- [ ] Transições validadas exclusivamente no servidor
- [ ] `[GET] /api/artigos` — lista conforme RN02 (metadados apenas)
- [ ] `[POST] /api/artigos` — cria sempre "Rascunho não público" (RF04), cifra conteúdo (403 se perfil sem permissão)
- [ ] 🔐 `[GET] /api/artigos/{id}` — detalhe (403 RN02 auditado · 404 · 428)
- [ ] 🔐 `[PUT] /api/artigos/{id}` — edição (409 se "Aguardando parecer")
- [ ] 🔐 `[DELETE] /api/artigos/{id}` — exclusão lógica auditada (RF17/RN12)
- [ ] 🔐 `[GET] /api/artigos/{id}/arquivo` — decifra após RN02+RN03
- [ ] 🔐 `[PUT] /api/artigos/{id}/arquivo` — cifra com a DEK (413 tamanho · 415 formato)

### 3.2 Submissão e pareceres (UC04, UC06)
- [ ] 🔐 `[POST] /api/artigos/{id}/submissoes` — evento alvo/deadline obrigatórios (RF21), prazo sugerido (RN15), alerta de prazo crítico, notifica revisores
- [ ] `[GET] /api/submissoes` — lista onde o usuário é revisor/autor
- [ ] 🔐 `[GET] /api/submissoes/{id}` — detalhe + pareceres
- [ ] 🔐 `[POST] /api/submissoes/{id}/pareceres` — decisório (orientador) / complementar (co-orientador) (RN05/RN13); artigo → "Avaliado" após decisório; notifica aluno (409 decisório já emitido)

### 3.3 Visibilidade, publicação e reversão (UC07, UC11)
- [ ] 🔐 `[PUT] /api/artigos/{id}/carta-aceite` — anexa carta (RN14 · 415 formato)
- [ ] 🔐 `[POST] /api/artigos/{id}/publicar` — exige parecer aprovado (RN06) + carta (RN14); decifra p/ área pública (409 condições)
- [ ] `[POST] /api/artigos/{id}/reversoes` — solicita reversão com justificativa; direta se orientador no próprio artigo (RF18/RN07)
- [ ] `[POST] /api/reversoes/{id}/decisao` — aprovada → recifra com nova DEK; rejeitada → permanece público (409 já decidida)

### 3.4 Documentos (`documents`)
- [ ] Adaptador MinIO (S3) para upload/download com URLs pré-assinadas
- [ ] Validação de formato e tamanho (RN14)
- [ ] Armazenamento cifrado do arquivo do artigo e da carta de aceite

### 3.5 API pública (`publicapi`)
- [ ] `[GET] /api/public/publicacoes` — lista paginada pública
- [ ] `[GET] /api/public/publicacoes/{id}` — detalhe (404 não revela não públicos — RF05)
- [ ] `[GET] /api/public/publicacoes/{id}/arquivo` — 302 para URL pré-assinada
- [ ] Cache (compatível com SSR/ISR do frontend)

### 3.6 Notificações e agendador (`notification`)
- [ ] Envio de e-mail assíncrono (SMTP institucional)
- [ ] `[GET] /api/notificacoes` e `[PATCH] /api/notificacoes/{id}` (marcar lida)
- [ ] Agendador de lembretes de prazo de parecer (RF22/RN15)

---

## Fase 4 — Frontend (Next.js)

### 4.1 Base e infraestrutura de UI
- [ ] Cliente HTTP para a API com tratamento de sessão (cookies) e códigos especiais (401/428/423)
- [ ] Fluxo de step-up: ao receber `[428]`, disparar cerimônia WebAuthn e repetir a chamada
- [ ] Design system/base de componentes acessíveis (WCAG 2.1 AA)
- [ ] Detecção de dispositivo móvel → página de aviso no módulo autenticado (RNF01/RE05)

### 4.2 Área pública (SSR/ISR, responsiva)
- [ ] Catálogo de publicações (lista + detalhe)
- [ ] Download de arquivo público
- [ ] Testes de acessibilidade com axe-core

### 4.3 Módulo autenticado (desktop-only)
- [ ] Login / recuperação de senha
- [ ] Cerimônias WebAuthn (registro pelo admin e step-up), agnósticas ao tipo de autenticador
- [ ] Gestão de artigos (CRUD, upload de arquivo, coautores)
- [ ] Submissão para avaliação e visualização de pareceres
- [ ] Publicação, carta de aceite e reversão
- [ ] Painel administrativo (usuários, vínculos, credenciais)
- [ ] Central de notificações

---

## Fase 5 — Qualidade e implantação

### 5.1 Testes e documentação
- [ ] Testes de domínio (máquina de estados, regras RN)
- [ ] Testes de integração por módulo (JPA, security, webauthn)
- [ ] Testes de autorização (RN02) e de step-up (RN03)
- [ ] OpenAPI (springdoc) publicado e revisado contra a especificação
- [ ] Testes de acessibilidade automatizados (axe-core) na área pública

### 5.2 Operação e implantação (RE04)
- [ ] Backups diários de PostgreSQL e MinIO (testados)
- [ ] Snapshot do Vault com política de acesso restrita
- [ ] Health checks e restart policies em todos os contêineres
- [ ] HSTS, headers de segurança e hardening do nginx
- [ ] Janela de manutenção mensal e verificação de uptime alvo (RNF08)
- [ ] Confirmar políticas de segurança da instituição antes do go-live (decisão em aberto)
