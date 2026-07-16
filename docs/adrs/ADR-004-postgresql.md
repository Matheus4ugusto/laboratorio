# ADR-004 — PostgreSQL como banco de dados relacional (com Flyway para migrações)

| Campo | Valor |
|---|---|
| **Status** | Aceita |
| **Data** | 2026-07-13 |
| **Decisores** | Equipe de arquitetura do projeto |
| **Requisitos relacionados** | RF11, RF12, RF16, RF17, RNF05, RNF07, RNF10, RNF11, RN08, RN09, RN11 |

## Contexto

O domínio é fortemente relacional: usuários com perfil único (RN09), vínculos aluno–orientador, credenciais WebAuthn 1-para-1 com usuários (RN11), artigos com coautores, submissões, pareceres e estados com transições controladas. A auditoria exige trilha imutável por 12 meses (RNF05) e a exclusão de artigos é sempre lógica (RF17). É preciso integridade referencial, transações ACID e controle de permissões por tabela (para tornar a auditoria append-only). O esquema evoluirá com o sistema (RNF10).

## Decisão

Adotaremos **PostgreSQL 16** como banco de dados único do sistema, com **Flyway** para versionamento de esquema. A tabela de auditoria terá permissões apenas de `INSERT`/`SELECT` para o usuário da aplicação (sem `UPDATE`/`DELETE`), com hash encadeado por registro. DEKs cifradas e metadados de artigos residem no banco; arquivos binários ficam no MinIO (ADR-005).

## Alternativas Consideradas

| Alternativa | Prós | Contras | Motivo da rejeição |
|---|---|---|---|
| MySQL/MariaDB | Popular, leve | Row-level security e tipos avançados mais limitados; permissões menos granulares para o append-only | PostgreSQL cobre melhor a auditoria |
| MongoDB (NoSQL) | Flexibilidade de esquema | Domínio é relacional; integridade referencial e transações multi-documento mais frágeis | Modelo de dados não combina |
| Oracle/SQL Server | Recursos corporativos | Licenciamento incompatível com RE02 (orçamento) | Custo |

## Justificativa

PostgreSQL é open source (compatível com RE02/RE04), oferece transações ACID para a máquina de estados, permissões granulares que materializam a imutabilidade da auditoria no próprio banco (defesa em profundidade além da aplicação) e recursos úteis ao domínio (constraints ricas, `JSONB` para metadados de coautores externos, índices parciais para a área pública). Flyway garante evolução de esquema rastreável e reproduzível entre ambientes (RNF10).

## Consequências

### Positivas

- Integridade referencial nativa para vínculos, coautorias e credenciais.
- Auditoria append-only imposta por permissão de banco, não apenas por código.
- Backups e réplicas bem suportados na infraestrutura institucional.

### Negativas / Trade-offs

- Operação do banco (tuning, vacuum, backups) fica com a equipe/instituição.
- Um único banco concentra dados: exige política de backup rigorosa.

### Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Crescimento da tabela de auditoria | Particionamento por mês; arquivamento após 12 meses (RNF05) |
| Migração destrutiva acidental | Flyway com revisão obrigatória; backups pré-migração |

## Referências

- Documento de Definição Arquitetural, seções 8.3 e 9
- ADR-005 (MinIO), ADR-007 (criptografia)
