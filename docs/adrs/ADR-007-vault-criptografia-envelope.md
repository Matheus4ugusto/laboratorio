# ADR-007 — Criptografia envelope AES-256-GCM com HashiCorp Vault (Transit)

| Campo | Valor |
|---|---|
| **Status** | Aceita |
| **Data** | 2026-07-13 |
| **Decisores** | Equipe de arquitetura do projeto |
| **Requisitos relacionados** | RF05, RF15, RNF12, RN02, RN07, RN10, US04 |

## Contexto

O conteúdo de artigos não públicos deve ser criptografado em repouso com algoritmo forte, com gestão de chaves que **impeça o acesso ao conteúdo até pelo administrador do sistema** (RF15, RNF12, RN02, RN10). Cifrar tudo com uma única chave na configuração da aplicação não atende: quem administra o servidor leria a chave. É preciso separar quem armazena dados (banco/objetos), quem executa a decifragem (aplicação, somente após autorização + WebAuthn) e quem guarda a chave-mestra. Na reversão de visibilidade (RN07), o conteúdo volta a ser cifrado.

## Decisão

Adotaremos **criptografia envelope**: cada artigo não público recebe uma **DEK** (Data Encryption Key) AES-256-GCM exclusiva, usada para cifrar o arquivo (MinIO) e campos sensíveis (PostgreSQL). A DEK é armazenada **apenas cifrada** pela **KEK** (Key Encryption Key) mantida no **HashiCorp Vault (engine Transit)** — a KEK nunca sai do Vault. A aplicação decifra a DEK via Vault somente após verificar autorização (RN02) e assertion WebAuthn válida (RN03). Publicação decifra o conteúdo para a área pública; reversão gera nova DEK e recifra.

## Alternativas Consideradas

| Alternativa | Prós | Contras | Motivo da rejeição |
|---|---|---|---|
| Chave única no application.properties/env | Simples | Administrador do servidor lê a chave → viola RNF12 | Viola o requisito central |
| Criptografia nativa do banco (pgcrypto/TDE) | Transparente | Chave acessível a quem opera o banco; não distingue administrador de usuário autorizado | Viola RNF12 |
| KMS de nuvem (AWS KMS) | Gerenciado, HSM | Dependência de nuvem pública conflita com RE04 | Infraestrutura institucional |
| Cifragem client-side (E2E no navegador) | Confidencialidade máxima | Inviabiliza fluxos do sistema (avaliação por orientador, publicação); gestão de chaves nos clientes impraticável | Incompatível com UC06/UC07 |

## Justificativa

A criptografia envelope com KEK externa é o único desenho avaliado que satisfaz RNF12 de fato: o banco e o MinIO contêm apenas dados cifrados e DEKs cifradas; o Vault contém a KEK mas não os dados; e a aplicação só junta as duas pontas mediante autorização de negócio + prova WebAuthn com verificação de usuário. DEK por artigo limita o impacto de vazamento a um único artigo e torna a reversão (RN07) barata — basta recifrar com nova DEK. O acesso da aplicação ao Vault usa AppRole com políticas mínimas, e as políticas do Vault são administradas separadamente do administrador funcional do sistema (segregação de deveres — RN10).

## Consequências

### Positivas

- RNF12 atendido com segregação real: nenhum papel isolado acessa conteúdo não público.
- Rotação de KEK sem recifrar dados (rewrap das DEKs no Vault Transit).
- Auditoria própria do Vault complementa a trilha da aplicação.

### Negativas / Trade-offs

- Vault é componente crítico: indisponível, artigos não públicos ficam inacessíveis (área pública não é afetada).
- Operação adicional: unseal, backup de snapshot, políticas.

### Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Perda do Vault/KEK = perda irreversível do conteúdo | Snapshots regulares; chaves de unseal distribuídas (Shamir) entre membros distintos do laboratório |
| Vault indisponível | Health check com alerta; área pública e fluxos sem artigos não públicos continuam operando |
| Conluio administrador da aplicação + operador do Vault | Risco residual aceito e documentado; auditoria imutável (RNF05) como detecção |

## Referências

- Documento de Definição Arquitetural, seção 8.2
- ADR-004 (PostgreSQL), ADR-005 (MinIO), ADR-006 (WebAuthn)
