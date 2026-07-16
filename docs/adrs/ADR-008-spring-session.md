# ADR-008 — Spring Session JDBC com cookies HttpOnly para gestão de sessões

| Campo | Valor |
|---|---|
| **Status** | Aceita |
| **Data** | 2026-07-13 |
| **Decisores** | Equipe de arquitetura do projeto |
| **Requisitos relacionados** | RF02, RNF02, RNF07, RNF13, RN08, UC01 |

## Contexto

Sessões autenticadas devem expirar após 30 minutos de inatividade (RNF13) e o sistema mantém estado de segurança sensível por sessão: resultado do step-up WebAuthn (janela de validade), contadores de falha para bloqueio temporário (RN08). Com ~100 usuários simultâneos (RNF07), a carga de sessões é baixa. A escolha central é entre sessões server-side e tokens auto-contidos (JWT).

## Decisão

Adotaremos **sessões server-side com Spring Session JDBC** (persistidas no PostgreSQL), entregues ao navegador via cookie `HttpOnly; Secure; SameSite=Strict`. Timeout de inatividade de 30 minutos (RNF13). O estado do step-up WebAuthn (última assertion válida e sua janela) vive na sessão, no servidor. Proteção CSRF habilitada (cookies como credencial). Sem Redis: na escala prevista, o banco existente basta como session store.

## Alternativas Consideradas

| Alternativa | Prós | Contras | Motivo da rejeição |
|---|---|---|---|
| JWT stateless | Sem estado no servidor; escala horizontal fácil | Revogação imediata difícil (logout, bloqueio RN08, revogação de credencial RN11 exigiriam blocklist = estado de novo); expiração por inatividade não natural | Requisitos de revogação e RNF13 pedem estado no servidor |
| Spring Session + Redis | Session store rápido e dedicado | Mais um componente para operar; desnecessário para 100 usuários | Complexidade sem ganho na escala prevista |
| Sessão em memória (Tomcat) | Zero configuração | Sessões perdidas a cada deploy/restart; impede réplica futura | Frágil operacionalmente |

## Justificativa

Os requisitos de segurança do sistema são incompatíveis com tokens auto-contidos: bloqueio temporário após falhas (RN08), revogação imediata de credencial WebAuthn (RN11) e expiração por inatividade (RNF13) exigem que o servidor possa invalidar o acesso a qualquer momento. Sessões server-side no PostgreSQL entregam isso sem componente adicional, e o cookie `HttpOnly` elimina exposição do identificador de sessão a scripts (mitigando XSS), enquanto `SameSite=Strict` + CSRF token mitigam requisições forjadas.

## Consequências

### Positivas

- Invalidação imediata de sessão em logout, bloqueio ou revogação de credencial.
- Estado do step-up WebAuthn inacessível ao cliente.
- Nenhum componente novo de infraestrutura.

### Negativas / Trade-offs

- Cada requisição autenticada consulta o session store (aceitável na escala; índice + cleanup automático do Spring Session).
- Escala horizontal futura exigirá session store compartilhado (já resolvido: o JDBC é compartilhado por natureza).

### Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Fixação de sessão | Rotação do ID de sessão no login (padrão do Spring Security) |
| Crescimento da tabela de sessões | Job de limpeza de sessões expiradas (nativo do Spring Session JDBC) |

## Referências

- Documento de Definição Arquitetural, seção 8.1
- ADR-003 (Spring Boot), ADR-004 (PostgreSQL), ADR-006 (WebAuthn)
