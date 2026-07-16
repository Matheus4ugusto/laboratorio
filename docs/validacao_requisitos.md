# Relatório de Validação da Elicitação de Requisitos

**Documento avaliado:** requisitos_sistema_laboratorio.md (v1.0, 12/07/2026)
**Data da validação:** 12/07/2026
**Critérios:** completude, consistência, ambiguidade, testabilidade, viabilidade e rastreabilidade.

---

## 1. Avaliação Geral

O documento tem boa estrutura (atores, US, UC, RF, RNF, restrições e regras de negócio) e cobre os cenários centrais descritos na introdução. A rastreabilidade geral US → UC → RF é adequada. Foram identificados, porém, **3 inconsistências**, **5 ambiguidades** e **7 omissões** que devem ser tratadas antes da fase de projeto.

**Veredito: aprovado com ressalvas** — revisar os itens de severidade alta antes de prosseguir.

## 2. Inconsistências

| ID | Severidade | Descrição |
|---|---|---|
| I01 | Alta | **Administrador ausente do UC05/RF09.** RN02 permite ao administrador visualizar artigos não públicos, e RF09/RN03 exigem chave física para *qualquer* interação — mas o administrador não é ator do UC05. Não está definido se ele precisa de chave física ou é isento. |
| I02 | Média | **"Comentar" sem requisito correspondente.** RN03 cita a ação "comentar", mas não existe RF, US ou UC de comentários (UC06 menciona comentários apenas dentro do parecer). Ou falta um requisito, ou a regra referencia funcionalidade inexistente. |
| I03 | Média | **RF03 vs US03/UC03.** RF03 diz "membros autenticados" cadastram artigos; UC03 lista apenas aluno e orientador. O administrador pode cadastrar artigos? Alinhar os escopos. |

## 3. Ambiguidades e conflitos potenciais

| ID | Severidade | Descrição |
|---|---|---|
| A01 | Alta | **RN06 pode ser burlada pelo UC03.** RN06 exige parecer antes de tornar público "quando submetido para avaliação", mas UC03 permite cadastrar o artigo já como público, sem nenhum parecer. Se a intenção é controle de qualidade, há brecha; se cadastro público direto é aceitável, explicitar. |
| A02 | Alta | **Viabilidade do "pen-drive" via navegador.** Navegadores não leem pen-drives genéricos; a implementação viável é token FIDO2/U2F via WebAuthn. RNF04 aponta a direção certa, mas RE01/RE05/UC05 seguem falando em "pen-drive", o que cria expectativa tecnicamente inviável. Padronizar a terminologia (ex.: "token de segurança USB compatível com FIDO2/WebAuthn"). |
| A03 | Média | **RN07 sem fluxo correspondente.** "Reverter para não público exige aprovação do orientador/administrador" — UC07 e RF13 não descrevem esse fluxo de aprovação (quem solicita, como aprova, notificações). |
| A04 | Média | **US04 mal formada.** História negativa ("não quero conseguir") não é boa prática; o ator está rotulado "visitante", mas o texto abrange membros sem permissão. Converter em requisito de segurança (já coberto por RF05) ou reescrever de forma positiva. |
| A05 | Baixa | **Estados do artigo não formalizados.** UC04 cita "aguardando parecer" e UC06 gera aprovado/reprovado/com ressalvas, mas não há máquina de estados definida (cadastrado → submetido → avaliado → público...). Recomenda-se diagrama de estados. |

## 4. Omissões

| ID | Severidade | Descrição |
|---|---|---|
| O01 | Alta | **Ciclo de vida da chave física:** provisionamento, vínculo chave↔usuário, perda/roubo, revogação e substituição não são tratados. É o ponto mais crítico do mecanismo de segurança. |
| O02 | Alta | **Vínculo aluno–orientador:** RN04 depende desse vínculo, mas nenhum UC/RF define quem o cadastra e mantém (UC08 trata apenas de perfis). |
| O03 | Média | **Edição e exclusão de artigos:** UC05 cita "editar" como interação, mas não há UC/RF de edição ou exclusão de artigos. |
| O04 | Média | **Recuperação de senha e gestão de sessão** (expiração, logout) não especificadas. |
| O05 | Média | **Coautoria:** UC03 e RN02 mencionam múltiplos autores, mas RN04 restringe submissão ao "aluno autor" — direitos de coautores indefinidos. |
| O06 | Baixa | **Canal de notificação** (RF08, UC04): e-mail, in-app, ambos? |
| O07 | Baixa | **Escopo da visualização pública:** o visitante vê apenas metadados ou também baixa o PDF (RF14)? |

## 5. Testabilidade (RNF e regras)

| Item | Problema | Recomendação |
|---|---|---|
| RNF07 | "Sem perda de desempenho perceptível" não é mensurável | Definir nº de usuários simultâneos e tempo de resposta alvo (ex.: 50 usuários, p95 < 2s) |
| RNF06 | "Condições normais de uso" vago | Especificar carga e ambiente de referência |
| RNF09 | Nível WCAG não indicado | Fixar nível (ex.: WCAG 2.1 AA) |
| RNF05 | Período de retenção "a definir" | Definir valor com o laboratório antes do projeto |
| RN08 | "Número definido de tentativas" em aberto | Parametrizar (ex.: 5 tentativas / bloqueio 15 min) |
| RE02 | Orçamento e prazo "a definir" | Aceitável nesta fase, mas registrar como pendência |

## 6. Rastreabilidade US → UC → RF

| US | UC | RF | Situação |
|---|---|---|---|
| US01 | UC02 | RF01 | OK |
| US02 | UC01 | RF02 | OK |
| US03 | UC03, UC07 | RF03, RF04, RF13, RF14 | OK (ver I03) |
| US04 | UC02 | RF05 | OK (ver A04) |
| US05 | UC04 | RF06 | OK |
| US06 | UC06 | RF07, RF08 | OK |
| US07 | UC05 | RF09, RF10, RF11 | OK (ver I01, A02) |
| US08 | UC08 | RF12 | OK (ver O02) |

Sem requisitos órfãos ou US sem cobertura. Sugere-se adicionar coluna de RNs relacionadas na versão 1.1.

## 7. Recomendações prioritárias

1. Definir a política de chave física para o administrador (I01) e o ciclo de vida das chaves (O01).
2. Resolver o conflito RN06 × UC03 sobre publicação direta (A01).
3. Substituir "pen-drive" por token FIDO2/WebAuthn em todo o documento (A02).
4. Especificar a gestão do vínculo aluno–orientador (O02).
5. Adicionar UC/RF de edição e exclusão de artigos e o fluxo de reversão de visibilidade (O03, A03).
6. Quantificar RNF06, RNF07, RNF09 e RN08.
7. Criar diagrama de estados do artigo (A05).
