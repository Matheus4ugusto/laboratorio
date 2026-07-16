# ADR-005 — MinIO (API S3) para armazenamento de arquivos

| Campo | Valor |
|---|---|
| **Status** | Aceita |
| **Data** | 2026-07-13 |
| **Decisores** | Equipe de arquitetura do projeto |
| **Requisitos relacionados** | RF14, RF15, RF23, RNF12, RE04, UC11 |

## Contexto

O sistema armazena arquivos binários: PDFs de artigos (cifrados quando não públicos — RF15/RNF12) e cartas de aceite (RF23). Guardar binários no PostgreSQL degrada backup e desempenho; guardar em sistema de arquivos local dificulta controle de acesso, versionamento e portabilidade. A hospedagem é on-premises institucional (RE04), o que descarta serviços de nuvem pública como padrão.

## Decisão

Adotaremos **MinIO** como armazenamento de objetos on-premises, acessado pelo backend via API S3 (SDK AWS para Java). Buckets separados: `articles-private` (objetos cifrados pela aplicação com a DEK do artigo — ADR-007, sem acesso público), `articles-public` (artigos públicos, servidos via URLs pré-assinadas de curta duração) e `acceptance-letters`. O frontend nunca acessa o MinIO diretamente para conteúdo não público: todo download passa pelo backend após autorização + WebAuthn.

## Alternativas Consideradas

| Alternativa | Prós | Contras | Motivo da rejeição |
|---|---|---|---|
| BLOBs no PostgreSQL | Sem componente extra; transação única | Infla backups; degrada cache do banco; streaming de arquivos ineficiente | Penaliza operação e desempenho |
| Sistema de arquivos do servidor | Simplicidade | Sem API de acesso controlado; acopla ao host; migração difícil | Frágil para RE04 e evolução |
| AWS S3 (nuvem pública) | Gerenciado, durável | Dados fora da infraestrutura institucional (RE04); custo recorrente (RE02); LGPD exige análise de transferência | Conflita com RE04 |

## Justificativa

MinIO oferece API S3 padrão dentro da infraestrutura institucional: o backend usa o mesmo SDK que usaria com qualquer provedor S3 (portabilidade futura), os objetos não públicos permanecem cifrados pela aplicação (o MinIO nunca vê conteúdo em claro, coerente com RNF12) e URLs pré-assinadas servem a área pública sem sobrecarregar o backend.

## Consequências

### Positivas

- Backups do banco enxutos (binários fora do PostgreSQL).
- Downloads públicos eficientes via URL pré-assinada (RNF06).
- Portabilidade para qualquer armazenamento S3-compatível.

### Negativas / Trade-offs

- Mais um contêiner para operar e fazer backup.
- Consistência banco ↔ objeto exige disciplina (gravar objeto antes de confirmar metadados).

### Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Objetos órfãos (upload sem registro, ou vice-versa) | Rotina de reconciliação; escrita em duas fases (objeto → metadados) |
| Perda de dados | Backup do volume MinIO no mesmo plano do PostgreSQL |

## Referências

- Documento de Definição Arquitetural, seções 6 e 9
- ADR-004 (PostgreSQL), ADR-007 (criptografia)
