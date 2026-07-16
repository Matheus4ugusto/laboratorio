# ADR-009 — Docker + Docker Compose com Nginx para implantação

| Campo | Valor |
|---|---|
| **Status** | Aceita |
| **Data** | 2026-07-13 |
| **Decisores** | Equipe de arquitetura do projeto |
| **Requisitos relacionados** | RNF02, RNF06, RNF08, RE02, RE04 |

## Contexto

O sistema será hospedado em infraestrutura institucional (RE04), com orçamento restrito (RE02) e uptime mínimo de 99% mensal (RNF08). A solução envolve seis processos (Nginx, Next.js, Spring Boot, PostgreSQL, MinIO, Vault) que precisam ser implantados de forma reproduzível em ambientes que a equipe não controla totalmente, com TLS 1.2+ obrigatório (RNF02).

## Decisão

Adotaremos **Docker** para empacotamento de todos os componentes e **Docker Compose** para orquestração em servidor único, com **Nginx** como proxy reverso: terminação TLS 1.2+/HSTS, roteamento (`/` → Next.js, `/api` → Spring Boot), compressão e cache de estáticos. Rede interna do Compose isola os serviços — apenas o Nginx expõe a porta 443. `restart: unless-stopped` e health checks em todos os serviços; backups agendados de PostgreSQL, MinIO e snapshot do Vault.

## Alternativas Consideradas

| Alternativa | Prós | Contras | Motivo da rejeição |
|---|---|---|---|
| Kubernetes | Auto-healing, escala, padrão de mercado | Complexidade operacional alta para equipe pequena e servidor único; RE02 | Desproporcional à escala (RNF07) |
| Instalação direta no host (systemd) | Sem camada extra | Ambientes irreproduzíveis; conflitos de dependências; migração de servidor difícil | Frágil frente a RE04 (servidor da instituição) |
| PaaS em nuvem (Heroku/Render) | Operação mínima | Dados fora da instituição (RE04); custo recorrente (RE02) | Conflita com RE04 |

## Justificativa

Compose entrega reprodutibilidade (mesma definição em desenvolvimento, homologação e produção), isolamento de rede (defesa em profundidade: banco, MinIO e Vault inacessíveis de fora) e operação simples o suficiente para um laboratório — um `docker compose up -d` documentado atende RNF08 com restart automático e health checks, sem o custo cognitivo de um orquestrador distribuído que a escala do sistema (100 usuários) não justifica.

## Consequências

### Positivas

- Ambientes idênticos e versionados junto ao código (RNF10).
- Superfície de exposição mínima (somente 443 via Nginx).
- Migração de servidor institucional = mover volumes + compose file.

### Negativas / Trade-offs

- Servidor único é ponto único de falha (aceito: 99% mensal permite ~7h de indisponibilidade).
- Escala horizontal futura exigirá evolução (Swarm/Kubernetes) — facilitada pelos contêineres já existentes.

### Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Falha do host | Backups diários testados; procedimento de restauração documentado e ensaiado |
| Certificado TLS expirado | Renovação automatizada (ACME/certbot ou PKI institucional) com alerta |
| Atualizações de imagens com vulnerabilidades | Varredura de imagens no CI; janela mensal de atualização |

## Referências

- Documento de Definição Arquitetural, seção 10
- ADR-001 (monólito modular)
