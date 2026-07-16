# ADR-003 — Java 21 + Spring Boot 3 como plataforma do backend

| Campo | Valor |
|---|---|
| **Status** | Aceita |
| **Data** | 2026-07-13 |
| **Decisores** | Laboratório (definição de stack) + equipe de arquitetura |
| **Requisitos relacionados** | RF02–RF23, RNF03, RNF04, RNF10, RNF13, RN01–RN15 |

## Contexto

O backend concentra as regras de negócio críticas: máquina de estados do artigo, autorização fina por papel e por artigo (RN02, RN12), step-up WebAuthn (RF09), criptografia envelope (RF15), auditoria (RF11), agendamento de lembretes (RF22) e envio de e-mails (RF08). O laboratório definiu Java + Spring Boot como plataforma. A solução precisa de ecossistema maduro de segurança e de manutenção de longo prazo (RNF10).

## Decisão

Adotaremos **Java 21 (LTS) com Spring Boot 3.x**, usando: **Spring Web MVC** (`spring-boot-starter-web`) para a exposição da API REST consumida pelo frontend, Spring Security (autenticação, Argon2id — RNF03, autorização por método), Spring Data JPA (persistência), Spring Session JDBC (ADR-008), Spring Scheduling (`@Scheduled`) para lembretes (RF22/RN15), Spring Mail para notificações via SMTP institucional (RF08) e springdoc-openapi para documentação da API (RNF10). Optamos pelo modelo servlet síncrono (MVC) em vez do reativo (Spring WebFlux): a carga prevista (RNF07) não exige I/O não bloqueante, e o modelo imperativo simplifica o código transacional com JPA e a manutenção (RNF10).

## Alternativas Consideradas

| Alternativa | Prós | Contras | Motivo da rejeição |
|---|---|---|---|
| Node.js/NestJS | Stack única com o frontend | Ecossistema de segurança/criptografia menos padronizado que Spring Security; fora da preferência do laboratório | Preferência do cliente por Java/Spring |
| Quarkus | Startup rápido, menor memória | Ecossistema menor; benefícios (nativo/serverless) irrelevantes para RE04 | Maturidade do Spring pesa mais |
| Jakarta EE puro | Padrão aberto | Menor produtividade e comunidade que Spring Boot | Custo de desenvolvimento maior |

## Justificativa

Spring Boot oferece, integrados e maduros, exatamente os blocos que os requisitos exigem: Spring Security cobre senha com Argon2id, sessões com expiração (RNF13) e autorização declarativa por regra de negócio; o agendador nativo atende os lembretes na escala do sistema sem dependência extra; e o suporte LTS do Java 21 garante manutenção pelo horizonte de vida do sistema (RNF10). É também a escolha declarada do laboratório.

## Consequências

### Positivas

- Blocos de segurança auditados pela comunidade em vez de implementação própria.
- Autorização declarativa próxima do domínio (regras RN02/RN05/RN12 verificáveis em testes).
- Transações declarativas para as transições de estado e escrita de auditoria.

### Negativas / Trade-offs

- Consumo de memória maior que alternativas nativas (aceitável na escala prevista).
- Curva de aprendizado do ecossistema Spring para novos membros do laboratório.

### Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Perda de lembretes com `@Scheduled` em caso de queda | Lembretes idempotentes derivados do estado persistido (recalculados a cada execução), não de fila em memória |
| Upgrade de versões major do Spring | Aderência a APIs estáveis; testes de integração cobrindo fluxos críticos |

## Referências

- Documento de Definição Arquitetural, seções 6–8
- ADR-006 (WebAuthn4J), ADR-007 (criptografia), ADR-008 (sessões)
