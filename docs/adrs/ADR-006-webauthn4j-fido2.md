# ADR-006 — Spring Security + WebAuthn4J para autenticação forte WebAuthn

| Campo | Valor |
|---|---|
| **Status** | Aceita (revisada em 2026-07-13 para adequação aos requisitos v1.4) |
| **Data** | 2026-07-13 |
| **Decisores** | Equipe de arquitetura do projeto |
| **Requisitos relacionados** | RF09, RF10, RF11, RF16, RNF04, RE01, RE03, RE05, RN03, RN08, RN10, RN11, UC05, UC09, US07 |

## Contexto

Toda interação com artigo não público exige autenticação forte no padrão WebAuthn (RF09, RNF04), aceitando múltiplos tipos de autenticadores — chave de segurança USB, autenticador de plataforma com biometria/PIN (ex.: Windows Hello, Touch ID) e passkeys (RE01, RE05) —, baseada em assinatura criptográfica de desafio com verificação de presença/usuário, nunca na mera posse do dispositivo. O administrador gerencia o ciclo de vida das credenciais (registrar, vincular a um único usuário, revogar, substituir — RF16, RN11) sem que isso lhe dê acesso a conteúdo (RN10). Falhas devem ser auditadas e 5 falhas consecutivas bloqueiam o usuário por 15 min (RN08). Implementar a validação WebAuthn (attestation, assertion, verificação de origem e contador) manualmente é propenso a erros graves de segurança.

*Nota de revisão:* a versão original desta ADR (requisitos v1.3) restringia a cerimônia a chaves físicas USB (`authenticatorAttachment: cross-platform`, transporte `usb`). Os requisitos v1.4 generalizaram a autenticação forte para qualquer autenticador WebAuthn, e essa restrição foi removida.

## Decisão

Adotaremos **Spring Security com a biblioteca WebAuthn4J** para o servidor de Relying Party WebAuthn, implementando um mecanismo de **step-up authentication**: além da sessão base, endpoints que tocam artigos não públicos exigem uma assertion WebAuthn recente (janela de validade curta, configurável por ação). Registro de credenciais (UC09) restrito a fluxo administrativo presencial, aceitando qualquer tipo de autenticador (chave USB, plataforma ou passkey), com o tipo registrado como metadado da credencial. As cerimônias não fixam `authenticatorAttachment` nem transporte, mas exigem **`userVerification: required`** (toque + biometria/PIN, conforme o autenticador — RNF04). Credenciais persistidas no PostgreSQL com status (ativa/revogada) e verificação de contador quando o autenticador o suportar.

## Alternativas Consideradas

| Alternativa | Prós | Contras | Motivo da rejeição |
|---|---|---|---|
| java-webauthn-server (Yubico) | Biblioteca madura e específica | Integração com Spring Security menos direta; manutenção do projeto menos ativa | WebAuthn4J integra-se nativamente ao ecossistema Spring |
| Implementação própria do protocolo | Controle total | Altíssimo risco de erro criptográfico; custo de manutenção | Inaceitável para requisito de segurança central |
| IdP externo com suporte FIDO2 (Keycloak) | Fluxos prontos | Componente pesado a operar; step-up por artigo exigiria customização profunda; RN10 (admin sem acesso) mais difícil de garantir | Complexidade desproporcional |

## Justificativa

WebAuthn4J é a biblioteca que fundamenta o suporte WebAuthn do próprio ecossistema Spring, cobrindo a validação completa de attestation e assertion (assinatura, origem, RP ID, contador) exigida por RNF04 — de forma agnóstica ao tipo de autenticador, o que atende diretamente a generalização introduzida nos requisitos v1.4 sem mudança de biblioteca. A modelagem como step-up — em vez de segundo login — implementa RN03 com precisão: a prova criptográfica com verificação de usuário é exigida no momento da interação com o artigo não público, e cada verificação (sucesso ou falha) alimenta a auditoria (RF11) e o contador de bloqueio (RN08).

## Consequências

### Positivas

- Validação criptográfica conforme especificação W3C, sem código criptográfico próprio.
- Step-up granular por artigo/ação, alinhado a RN03.
- Revogação imediata: assertion de credencial revogada falha na consulta ao banco (RN11).
- Melhor usabilidade: usuários sem chave USB usam biometria/PIN da própria estação, reduzindo custo de hardware e barreiras de adoção.

### Negativas / Trade-offs

- Fluxo de uso mais oneroso para o usuário (gesto de verificação — toque, biometria ou PIN — a cada janela de step-up).
- Registro presencial de credenciais cria dependência do administrador (aceito: é o modelo de RN10/UC09).
- Heterogeneidade de autenticadores amplia a matriz de testes (chave USB, Windows Hello, Touch ID, passkeys por navegador).

### Riscos e Mitigações

| Risco | Mitigação |
|---|---|
| Perda do autenticador impede acesso do usuário | Registro de mais de uma credencial por usuário quando disponível; fluxo de substituição pelo administrador (RF16); nenhum fallback sem WebAuthn para conteúdo não público |
| Passkeys sincronizadas replicam a credencial para outros dispositivos do usuário via nuvem, fora do controle do administrador | Preferência por credenciais device-bound no registro presencial; sinalização de credenciais sincronizadas (flag BE/BS da assertion) e política do laboratório sobre aceitá-las; revogação imediata cobre comprometimento (RN11) |
| Autenticadores sincronizados podem não incrementar o contador de assinaturas | Verificação de contador aplicada quando suportada; detecção de anomalia complementada por auditoria (RF11) e bloqueio por falhas (RN08) |
| Janela de step-up longa demais enfraquece RN03 | Janela curta (ex.: 5 min) e invalidação ao trocar de artigo |
| Incompatibilidade de navegador | RE03 restringe a navegadores atuais, todos com WebAuthn nativo; testes cross-browser no CI cobrindo os tipos de autenticador |

## Referências

- Especificação W3C WebAuthn Level 2; documento de requisitos UC05/UC09
- Documento de Definição Arquitetural, seção 8.1
- ADR-003 (Spring Boot), ADR-008 (sessões)
