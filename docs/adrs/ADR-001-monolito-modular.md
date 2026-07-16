# ADR-001 — Adoção de monólito modular como estilo arquitetural

| Campo | Valor |
|---|---|
| **Status** | Aceita |
| **Data** | 2026-07-13 |
| **Decisores** | Equipe de arquitetura do projeto |
| **Requisitos relacionados** | RNF06, RNF07, RNF08, RNF10, RE02, RE04; máquina de estados do artigo (seção 5 dos requisitos) |

## Contexto

O sistema atende um único laboratório de pesquisa, com carga alvo de 100 usuários simultâneos e p95 < 3 s (RNF06/RNF07). A hospedagem será em infraestrutura institucional (RE04), com orçamento e prazo restritos (RE02) e equipe pequena. O domínio possui forte consistência transacional: a máquina de estados do artigo, os fluxos de aprovação (RN06, RN07) e a auditoria (RF11) atravessam vários módulos e se beneficiam de transações locais. Ao mesmo tempo, RNF10 exige modularidade e evolutibilidade.

## Decisão

Adotaremos um **monólito modular**: uma única aplicação backend (Spring Boot) organizada em módulos de domínio (`identity`, `webauthn`, `articles`, `review`, `documents`, `crypto`, `audit`, `notification`, `publicapi`) com fronteiras explícitas e comunicação por interfaces (padrão hexagonal simplificado), consumida por um frontend separado via API REST.

## Alternativas Consideradas

| Alternativa | Prós | Contras | Motivo da rejeição |
|---|---|---|---|
| Microsserviços | Escala independente; isolamento de falhas | Complexidade operacional (orquestração, observabilidade, transações distribuídas); custo alto para equipe pequena | Escala exigida não justifica; RE02/RE04 penalizam a complexidade operacional |
| Monólito não modularizado | Simplicidade máxima inicial | Erosão arquitetural; viola RNF10 (manutenibilidade) | Compromete evolução e testabilidade |
| Serverless (FaaS) | Baixo custo ocioso | Infraestrutura institucional on-premises (RE04) sem suporte maduro a FaaS; cold start fere RNF06 | Incompatível com RE04 |

## Justificativa

O monólito modular entrega a consistência transacional que a máquina de estados e a auditoria exigem, com o menor custo operacional possível na infraestrutura institucional, e a modularização interna preserva a manutenibilidade (RNF10) e mantém aberta a extração futura de serviços caso a escala mude.

## Consequências

### Positivas

- Implantação, backup e monitoramento simples (um artefato backend).
- Transações ACID locais para as transições de estado e trilha de auditoria.
- Refatorações e testes de integração mais baratos para equipe pequena.

### Negativas / Trade-offs

- Escala apenas vertical (ou réplicas do monólito inteiro).
- Fronteiras de módulo dependem de disciplina da equipe, não de barreiras físicas.

### Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Erosão das fronteiras entre módulos | Regras de dependência verificadas em build (ex.: ArchUnit); revisão de código |
| Crescimento além da escala prevista | Padrão hexagonal facilita extração de módulos para serviços |

## Referências

- Documento de Definição Arquitetural, seções 4 e 7
- ADR-003 (Spring Boot), ADR-009 (implantação)
