# ADR-002 — Next.js (React + TypeScript) como framework do frontend

| Campo | Valor |
|---|---|
| **Status** | Aceita |
| **Data** | 2026-07-13 |
| **Decisores** | Laboratório (definição de stack) + equipe de arquitetura |
| **Requisitos relacionados** | RF01, RNF01, RNF06, RNF09, RE03, RE05, US01, US07 |

## Contexto

O sistema possui duas faces com exigências distintas: uma área pública que deve carregar em < 3 s (p95), ser responsiva e atender WCAG 2.1 AA (RF01, RNF01, RNF06, RNF09), favorecida por renderização no servidor e cache; e um módulo autenticado rico em interação (formulários, máquina de estados, cerimônias WebAuthn via API do navegador), restrito a desktops (RE05). O laboratório definiu preferência por Next.js no frontend. É necessária compatibilidade com Chrome, Firefox, Edge e Safari atualizados (RE03).

## Decisão

Adotaremos **Next.js 15 (React 19) com TypeScript** como framework único do frontend: páginas públicas com SSR/ISR (renderização no servidor com cache incremental) e módulo autenticado como aplicação client-side protegida, consumindo a API REST do backend. As cerimônias WebAuthn usam a API nativa do navegador (`navigator.credentials`), compatível com todos os tipos de autenticador exigidos (chave USB, biometria/PIN de plataforma, passkey — RE05).

## Alternativas Consideradas

| Alternativa | Prós | Contras | Motivo da rejeição |
|---|---|---|---|
| React SPA pura (Vite) | Simplicidade de build | Sem SSR: pior tempo de primeiro carregamento e SEO da área pública (RNF06, RF01) | Penaliza a área pública |
| Angular | Framework completo, opinado | Sem SSR trivial equivalente; fora da preferência do laboratório | Preferência do cliente por Next.js |
| Templates server-side no Spring (Thymeleaf) | Um único artefato | Interatividade limitada para WebAuthn e fluxos ricos; acopla frontend ao backend | Insuficiente para o módulo autenticado |

## Justificativa

Next.js atende simultaneamente os dois perfis do sistema: SSR/ISR entrega a área pública rápida, indexável e cacheável, enquanto o ecossistema React + TypeScript suporta o módulo autenticado interativo com tipagem de ponta a ponta dos contratos da API. É a escolha declarada do laboratório, com suporte consolidado nos navegadores exigidos por RE03 (todos com WebAuthn nativo).

## Consequências

### Positivas

- Área pública com SSR/ISR: desempenho (RNF06) e acessibilidade (RNF09) facilitados.
- TypeScript reduz defeitos de integração com a API (RNF10).
- Detecção de dispositivo móvel no servidor Next.js para o bloqueio do módulo autenticado (RE05).

### Negativas / Trade-offs

- Processo Node.js adicional na implantação (mais um contêiner).
- Duas bases de código (frontend/backend) exigem contratos de API versionados (OpenAPI).

### Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Divergência entre contrato da API e cliente | Geração de tipos TypeScript a partir do OpenAPI do backend |
| Regressões de acessibilidade | Testes automatizados com axe-core no CI |

## Referências

- Documento de Definição Arquitetural, seções 6 e 8.4
- ADR-003 (backend), ADR-006 (WebAuthn)
