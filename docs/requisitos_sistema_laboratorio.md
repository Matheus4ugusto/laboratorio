# Documento de Elicitação de Requisitos

## Sistema Web para Laboratório de Pesquisa

**Versão:** 1.4
**Data:** 12/07/2026

### Histórico de Revisões

| Versão | Data | Alterações |
|---|---|---|
| 1.0 | 12/07/2026 | Versão inicial. |
| 1.1 | 12/07/2026 | Correções da validação: administrador sem acesso a artigos não públicos (armazenamento criptografado); artigos sempre criados como não públicos; autenticação física padronizada em FIDO2/WebAuthn; gestão do ciclo de vida das chaves pelo administrador; gestão de vínculos aluno–orientador; edição/exclusão de artigos; fluxo de reversão de visibilidade; máquina de estados do artigo; RNFs quantificados; US04 reescrita; remoção de "comentar" (RN03). |
| 1.2 | 12/07/2026 | Lógica de coautores (membros e externos) e co-orientador; carta de aceite obrigatória para publicação; submissão para avaliação com evento alvo e deadline, com prazo sugerido de parecer e lembretes automáticos aos revisores. |
| 1.3 | 12/07/2026 | Módulo autenticado restrito a desktops/notebooks; eliminado o suporte a NFC/dispositivos móveis para a chave física (uso exclusivo via USB); área pública permanece responsiva. |
| 1.4 | 12/07/2026 | Autenticação forte alterada de chave física FIDO2 para o padrão WebAuthn, aceitando múltiplos tipos de autenticadores (chave de segurança USB, autenticador de plataforma com biometria/PIN — ex.: Windows Hello, Touch ID — e passkeys); terminologia atualizada de "chave física" para "credencial WebAuthn". |

---

## 1. Introdução

Este documento descreve os requisitos levantados para o desenvolvimento de um sistema web voltado à gestão e divulgação das publicações científicas de um laboratório de pesquisa. O sistema permitirá a exibição pública das principais publicações, o cadastro de novos artigos por membros autenticados (com autor principal e coautores), o fluxo de avaliação de artigos submetidos por alunos a seus orientadores e co-orientadores — com indicação do evento alvo e sua deadline —, a exigência de carta de aceite para publicação, e um mecanismo adicional de segurança baseado em autenticação forte no padrão WebAuthn — que aceita múltiplos tipos de autenticadores, como chaves de segurança USB, autenticadores de plataforma com biometria/PIN (ex.: Windows Hello, Touch ID) e passkeys — para qualquer interação com artigos ainda não tornados públicos. O módulo autenticado do sistema é acessível somente em computadores desktop/notebook, enquanto a área pública permanece acessível em qualquer dispositivo. Todo artigo é criado com visibilidade "não público" e seu conteúdo é armazenado de forma criptografada, inacessível inclusive ao administrador do sistema.

## 2. Atores

| Ator | Descrição |
|---|---|
| Visitante | Usuário não autenticado que acessa a tela inicial do sistema. |
| Aluno | Membro do laboratório com permissão para cadastrar artigos (como autor principal ou coautor) e submetê-los para avaliação. |
| Orientador | Membro do laboratório responsável por avaliar e emitir parecer decisório sobre artigos submetidos por alunos. |
| Co-orientador | Membro com perfil de orientador, indicado na submissão como avaliador complementar. Tem acesso ao artigo e pode registrar parecer complementar (não decisório). |
| Administrador | Responsável pela gestão de usuários, permissões, vínculos aluno–orientador e ciclo de vida das credenciais WebAuthn. **Não possui acesso ao conteúdo de artigos não públicos.** |

## 3. Histórias de Usuário

**US01** — Como visitante, quero visualizar as principais publicações públicas do laboratório na tela inicial, para conhecer as pesquisas realizadas sem precisar de login.

**US02** — Como membro do laboratório, quero fazer login no sistema, para poder incluir e gerenciar artigos.

**US03** — Como membro do laboratório (aluno ou orientador), quero cadastrar um novo artigo, que inicia obrigatoriamente como não público, para desenvolvê-lo com confidencialidade até sua publicação.

**US04** — Como autor de um artigo não público, quero que apenas eu, meus coautores membros e os orientadores vinculados tenham acesso ao seu conteúdo, para que a confidencialidade das pesquisas em andamento seja preservada.

**US05** — Como aluno, quero submeter um artigo para avaliação do meu orientador, informando o evento alvo e sua deadline, para obter um parecer com prazo suficiente para correções antes da submissão ao evento.

**US06** — Como orientador, quero visualizar os artigos submetidos pelos meus alunos, com o evento alvo e a deadline informados, e registrar um parecer (aprovado, reprovado ou com ressalvas), para orientar o andamento do trabalho em tempo hábil.

**US07** — Como membro do laboratório, quero que o sistema exija uma autenticação forte WebAuthn (chave de segurança USB, biometria ou passkey) sempre que eu interagir com um artigo ainda não público, para garantir uma camada extra de segurança contra acessos indevidos.

**US08** — Como administrador, quero gerenciar os usuários, suas permissões e os vínculos aluno–orientador, para manter o controle de quem pode acessar e submeter conteúdo no sistema.

**US09** — Como administrador, quero gerenciar o ciclo de vida das credenciais WebAuthn (registrar, vincular, revogar e substituir), para garantir que apenas credenciais válidas autorizem o acesso a artigos não públicos.

**US10** — Como autor principal, coautor membro ou orientador vinculado, quero editar ou excluir um artigo, para manter o acervo atualizado e correto.

**US11** — Como autor principal, quero indicar coautores (membros do laboratório ou externos) no cadastro do artigo, para que os membros colaborem no sistema e os externos constem na autoria.

**US12** — Como aluno, quero indicar um co-orientador na submissão do artigo, para contar com uma avaliação complementar à do orientador principal.

**US13** — Como co-orientador, quero visualizar o artigo submetido e registrar um parecer complementar, para apoiar a decisão do orientador principal.

**US14** — Como autor, quero anexar a carta de aceite do evento/periódico ao artigo, para habilitar sua publicação no sistema.

## 4. Casos de Uso

### UC01 — Realizar Login
- **Ator principal:** Aluno, Orientador, Co-orientador, Administrador
- **Pré-condições:** Usuário possuir cadastro ativo no sistema.
- **Fluxo principal:**
  1. Usuário acessa a tela de login.
  2. Usuário informa credenciais (usuário/senha).
  3. Sistema valida as credenciais.
  4. Sistema redireciona o usuário para a área autenticada.
- **Fluxos alternativos:** Credenciais inválidas → sistema exibe mensagem de erro e permanece na tela de login. Usuário esqueceu a senha → sistema oferece fluxo de recuperação por e-mail cadastrado.
- **Pós-condições:** Sessão do usuário iniciada, com expiração automática por inatividade (RNF13).

### UC02 — Visualizar Publicações Públicas
- **Ator principal:** Visitante
- **Pré-condições:** Nenhuma.
- **Fluxo principal:**
  1. Usuário acessa a tela inicial do sistema.
  2. Sistema lista as publicações marcadas como públicas, com metadados (incluindo autores e coautores) e download do arquivo.
- **Pós-condições:** Publicações exibidas sem exposição de artigos não públicos.

### UC03 — Cadastrar Artigo
- **Ator principal:** Aluno, Orientador
- **Pré-condições:** Usuário autenticado.
- **Fluxo principal:**
  1. Usuário acessa a área de cadastro de artigos.
  2. Usuário preenche os dados do artigo (título, resumo, arquivo, etc.), sendo registrado como autor principal.
  3. Usuário indica os coautores: membros do laboratório são selecionados dentre os usuários cadastrados; coautores externos são registrados apenas como metadados de autoria (nome, instituição), sem acesso ao sistema.
  4. Sistema salva o artigo com visibilidade "não público" (obrigatório — RN01) e conteúdo criptografado (RNF12).
- **Regra associada:** Todas as interações futuras com o artigo exigirão autenticação WebAuthn (ver UC05) enquanto ele for não público. Coautores membros passam a ter os acessos definidos em RN12.
- **Pós-condições:** Artigo registrado no estado "Rascunho (não público)", com autoria definida.

### UC04 — Submeter Artigo para Avaliação
- **Ator principal:** Aluno (autor principal)
- **Pré-condições:** Aluno autenticado; artigo cadastrado; aluno é o autor principal; existe vínculo aluno–orientador ativo (UC08).
- **Fluxo principal:**
  1. Aluno seleciona o artigo a ser submetido.
  2. Aluno indica o orientador responsável (dentre os vinculados a ele) e, opcionalmente, um co-orientador (membro com perfil de orientador).
  3. Aluno informa o evento alvo (nome do evento/periódico) e a deadline de submissão do evento (obrigatórios).
  4. Sistema valida que a deadline é futura e calcula o prazo sugerido de parecer (deadline menos a margem mínima para correções — RN15).
  5. Sistema solicita a autenticação WebAuthn (UC05).
  6. Sistema notifica o orientador e o co-orientador (se indicado) sobre a nova submissão, exibindo evento alvo, deadline e prazo sugerido de parecer (e-mail e notificação no sistema).
- **Fluxos alternativos:** Deadline informada anterior ou igual à data atual → sistema rejeita a submissão e solicita correção. Deadline mais próxima que a margem mínima de correções → sistema alerta o aluno e os revisores sobre o prazo crítico, mas permite a submissão.
- **Pós-condições:** Artigo no estado "Aguardando parecer", com evento alvo, deadline e prazo sugerido registrados.

### UC05 — Autenticar com WebAuthn
- **Ator principal:** Aluno, Orientador, Co-orientador
- **Pré-condições:** Usuário autenticado no sistema; credencial WebAuthn registrada e vinculada ao usuário (UC09); tentativa de interação com artigo não público (visualizar, editar, excluir, avaliar, submeter, alterar visibilidade).
- **Fluxo principal:**
  1. Sistema detecta interação com artigo não público.
  2. Sistema inicia desafio WebAuthn e solicita um autenticador registrado do usuário (chave de segurança USB, autenticador de plataforma com biometria/PIN ou passkey).
  3. Usuário utiliza o autenticador e realiza a verificação de presença/usuário (toque, biometria ou PIN).
  4. Sistema valida a assinatura criptográfica da credencial.
  5. Sistema libera a ação solicitada.
- **Fluxos alternativos:** Credencial inválida, ausente, revogada ou não reconhecida → sistema bloqueia a ação e registra a tentativa em log de auditoria; após 5 falhas consecutivas, bloqueio temporário do usuário por 15 minutos (RN08).
- **Pós-condições:** Ação sobre o artigo autorizada ou bloqueada.

### UC06 — Emitir Parecer sobre Artigo
- **Ator principal:** Orientador (parecer decisório), Co-orientador (parecer complementar)
- **Pré-condições:** Revisor autenticado; artigo submetido com o revisor designado (orientador ou co-orientador); autenticação WebAuthn validada (UC05).
- **Fluxo principal:**
  1. Revisor acessa o artigo submetido; sistema exibe evento alvo, deadline do evento e prazo sugerido de parecer.
  2. Revisor analisa o conteúdo.
  3. Co-orientador (se designado) registra parecer complementar e comentários, visível ao orientador principal e ao aluno.
  4. Orientador principal registra o parecer decisório (aprovado, reprovado, com ressalvas) e comentários, podendo considerar o parecer complementar.
  5. Sistema notifica o aluno sobre cada parecer emitido (e-mail e notificação no sistema).
- **Fluxos alternativos:** Aproximação do prazo sugerido de parecer sem emissão → sistema envia lembretes automáticos aos revisores (RF22). Parecer decisório emitido antes do complementar → parecer complementar torna-se opcional e não bloqueia o fluxo.
- **Pós-condições:** Artigo no estado "Avaliado" após o parecer decisório do orientador principal.

### UC07 — Alterar Visibilidade do Artigo
- **Ator principal:** Aluno (autor principal), Orientador
- **Pré-condições:** Usuário autenticado; usuário autor principal ou orientador vinculado do artigo; autenticação WebAuthn validada, caso o artigo esteja não público.
- **Fluxo principal (tornar público):**
  1. Usuário acessa as configurações do artigo.
  2. Sistema verifica as condições de publicação (RN06): parecer "aprovado" do orientador principal (para artigos de aluno) e carta de aceite do evento/periódico anexada (RN14).
  3. Caso ainda não anexada, usuário realiza o upload da carta de aceite (UC11).
  4. Usuário confirma a publicação.
  5. Sistema atualiza o status para "Público" e disponibiliza o conteúdo na área pública.
- **Fluxo alternativo (reverter para não público — RN07):**
  1. Aluno solicita a reversão, informando justificativa.
  2. Sistema notifica o orientador vinculado.
  3. Orientador aprova ou rejeita a solicitação (a reversão direta pelo orientador em artigos próprios não exige aprovação).
  4. Se aprovada, sistema retorna o artigo ao estado não público e restabelece a criptografia do conteúdo.
- **Pós-condições:** Artigo passa a seguir as regras de exibição do novo status.

### UC08 — Gerenciar Usuários, Permissões e Vínculos
- **Ator principal:** Administrador
- **Pré-condições:** Administrador autenticado.
- **Fluxo principal:**
  1. Administrador acessa o painel de gestão de usuários.
  2. Administrador cria, edita, ativa/desativa ou remove usuários e define perfis (aluno, orientador, administrador).
  3. Administrador cria e mantém os vínculos aluno–orientador que habilitam o fluxo de submissão (UC04).
- **Pós-condições:** Cadastro de usuários e vínculos atualizados.

### UC09 — Gerenciar Ciclo de Vida das Credenciais WebAuthn
- **Ator principal:** Administrador
- **Pré-condições:** Administrador autenticado.
- **Fluxo principal:**
  1. Administrador acessa o painel de gestão de credenciais.
  2. Administrador registra uma nova credencial WebAuthn para um usuário (registro presencial), vinculando-a a um único usuário — o autenticador pode ser chave de segurança USB, autenticador de plataforma (biometria/PIN) ou passkey.
  3. Administrador consulta o status das credenciais ativas.
- **Fluxos alternativos:** Perda/roubo do autenticador ou desligamento do membro → administrador revoga a credencial imediatamente; acessos com a credencial revogada passam a ser bloqueados e registrados em auditoria; administrador registra credencial substituta quando aplicável.
- **Pós-condições:** Base de credenciais atualizada; apenas credenciais válidas autorizam interações com artigos não públicos.
- **Observação:** A gestão das credenciais não concede ao administrador acesso ao conteúdo dos artigos não públicos (RN10).

### UC10 — Editar ou Excluir Artigo
- **Ator principal:** Aluno (autor principal ou coautor membro), Orientador (autor ou vinculado)
- **Pré-condições:** Usuário autenticado; usuário autor principal, coautor membro ou orientador vinculado; autenticação WebAuthn validada, caso o artigo esteja não público.
- **Fluxo principal:**
  1. Usuário acessa o artigo.
  2. Usuário edita os dados/arquivo do artigo ou, sendo autor principal ou orientador vinculado, solicita sua exclusão.
  3. Sistema salva as alterações ou realiza a exclusão lógica, registrando a ação e o usuário responsável em auditoria.
- **Restrições:** Artigos no estado "Aguardando parecer" não podem ser editados até a emissão do parecer decisório. A exclusão é restrita ao autor principal e ao orientador vinculado (coautores membros apenas editam — RN12).
- **Pós-condições:** Artigo atualizado ou excluído (exclusão lógica com registro).

### UC11 — Anexar Carta de Aceite
- **Ator principal:** Aluno (autor principal), Orientador (autor)
- **Pré-condições:** Usuário autenticado; usuário autor principal ou orientador autor do artigo; artigo no estado "Avaliado (aprovado)" ou, para artigos de orientador sem submissão, "Rascunho"; autenticação WebAuthn validada, caso o artigo esteja não público.
- **Fluxo principal:**
  1. Usuário acessa a área de documentos do artigo.
  2. Usuário realiza o upload da carta de aceite do evento/periódico (ex.: PDF), informando o evento correspondente.
  3. Sistema valida o formato do arquivo, armazena a carta vinculada ao artigo e registra a ação em auditoria.
- **Fluxos alternativos:** Arquivo em formato inválido → sistema rejeita e solicita novo upload.
- **Pós-condições:** Carta de aceite anexada; condição documental para publicação (RN14) satisfeita.

## 5. Estados do Artigo

| Estado | Descrição | Transições |
|---|---|---|
| Rascunho (não público) | Estado inicial de todo artigo (RN01). | → Aguardando parecer (UC04); → Excluído (UC10) |
| Aguardando parecer | Submetido ao orientador (e co-orientador, se indicado), com evento alvo e deadline registrados. | → Avaliado (UC06, parecer decisório) |
| Avaliado (aprovado / reprovado / com ressalvas) | Parecer decisório emitido. | Aprovado + carta de aceite anexada (UC11) → Público (UC07); Reprovado/Com ressalvas → Rascunho (novo ciclo de edição/submissão) |
| Público | Visível na área pública. | → Rascunho (não público), mediante fluxo de reversão aprovado (UC07/RN07) |
| Excluído | Exclusão lógica, mantida para auditoria. | — |

## 6. Requisitos Funcionais (RF)

| ID | Descrição |
|---|---|
| RF01 | O sistema deve exibir na tela inicial as principais publicações marcadas como públicas, sem exigir login. |
| RF02 | O sistema deve permitir que membros do laboratório realizem login com usuário e senha, com fluxo de recuperação de senha por e-mail. |
| RF03 | O sistema deve permitir que alunos e orientadores autenticados cadastrem novos artigos, sendo registrados como autor principal. |
| RF04 | Todo artigo deve ser criado obrigatoriamente com visibilidade "não público"; a publicação ocorre posteriormente, conforme RN06 e RN14 (UC07). |
| RF05 | O sistema não deve exibir artigos não públicos a usuários não autorizados, incluindo visitantes, membros sem permissão sobre o artigo e administradores. |
| RF06 | O sistema deve permitir que o aluno (autor principal) submeta um artigo para avaliação de um orientador vinculado a ele, com indicação opcional de um co-orientador. |
| RF07 | O sistema deve permitir que o orientador principal registre o parecer decisório (aprovado, reprovado ou com ressalvas) e que o co-orientador registre parecer complementar sobre o artigo submetido. |
| RF08 | O sistema deve notificar o aluno (e-mail e notificação no sistema) quando qualquer parecer (decisório ou complementar) for emitido. |
| RF09 | O sistema deve exigir a validação de autenticação forte no padrão WebAuthn (chave de segurança USB, autenticador de plataforma com biometria/PIN ou passkey) sempre que houver qualquer interação (visualização, edição, exclusão, submissão, avaliação, alteração de visibilidade) com um artigo não público. |
| RF10 | O sistema deve bloquear a ação solicitada caso a autenticação WebAuthn não seja validada com sucesso. |
| RF11 | O sistema deve registrar em log de auditoria todas as tentativas de acesso a artigos não públicos, incluindo tentativas de autenticação WebAuthn falhas. |
| RF12 | O sistema deve permitir que administradores gerenciem usuários, seus perfis de acesso (aluno, orientador, administrador) e os vínculos aluno–orientador. |
| RF13 | O sistema deve permitir a alteração da visibilidade de um artigo já cadastrado, respeitando as regras de autenticação WebAuthn e as condições de publicação/reversão (RN06, RN07, RN14). |
| RF14 | O sistema deve permitir upload de arquivos de artigos (ex.: PDF) associados ao registro do artigo, com download disponível na área pública para artigos públicos. |
| RF15 | O sistema deve armazenar o conteúdo de artigos não públicos de forma criptografada em repouso, de modo que nem mesmo o administrador do sistema tenha acesso ao conteúdo. |
| RF16 | O sistema deve permitir que o administrador gerencie o ciclo de vida das credenciais WebAuthn: registro, vínculo a um único usuário, consulta de status, revogação imediata (perda/roubo/desligamento) e substituição. |
| RF17 | O sistema deve permitir que autores (principal e coautores membros) e orientadores vinculados editem artigos, e que autor principal e orientador vinculado os excluam (exclusão lógica), respeitando as regras de autenticação WebAuthn e o estado do artigo. |
| RF18 | O sistema deve implementar o fluxo de aprovação para reversão de artigo público para não público: solicitação do aluno com justificativa, notificação e decisão do orientador (ou administrador, na ausência do orientador). |
| RF19 | O sistema deve permitir o registro de coautores no cadastro do artigo: membros do laboratório selecionados dentre os usuários cadastrados (com os acessos de RN12) e coautores externos como metadados de autoria (nome, instituição), sem acesso ao sistema. |
| RF20 | O sistema deve permitir a indicação de um co-orientador na submissão, notificando orientador e co-orientador e concedendo ao co-orientador acesso ao artigo para parecer complementar. |
| RF21 | O sistema deve exigir, na submissão para avaliação, o registro do evento alvo (nome do evento/periódico) e da deadline de submissão do evento, validando que a deadline é futura e exibindo essas informações aos revisores. |
| RF22 | O sistema deve calcular o prazo sugerido de parecer (deadline do evento menos a margem mínima para correções — RN15) e enviar lembretes automáticos aos revisores conforme a aproximação desse prazo. |
| RF23 | O sistema deve permitir o upload da carta de aceite do evento/periódico vinculada ao artigo (UC11) e bloquear a publicação de artigos sem carta de aceite anexada (RN14). |

## 7. Requisitos Não Funcionais (RNF)

| ID | Descrição |
|---|---|
| RNF01 | A área pública do sistema deve ser acessível via navegador web, com layout responsivo para desktop e dispositivos móveis. O módulo autenticado deve ser acessível somente em computadores desktop/notebook, com bloqueio de acesso a partir de dispositivos móveis. |
| RNF02 | Toda comunicação entre cliente e servidor deve ser criptografada (HTTPS/TLS 1.2+). |
| RNF03 | As senhas dos usuários devem ser armazenadas de forma segura (hash com salt, algoritmo dedicado — ex.: bcrypt/argon2). |
| RNF04 | A autenticação forte deve utilizar o padrão WebAuthn, aceitando múltiplos tipos de autenticadores (chave de segurança USB, autenticador de plataforma com biometria/PIN — ex.: Windows Hello, Touch ID — e passkeys), baseada em assinatura criptográfica de desafio com verificação de presença/usuário. |
| RNF05 | O sistema deve manter logs de auditoria imutáveis por, no mínimo, 12 meses. |
| RNF06 | O tempo de resposta para exibição da tela inicial com publicações públicas deve ser inferior a 3 segundos (percentil 95) com até 100 usuários simultâneos. |
| RNF07 | O sistema deve suportar ao menos 100 usuários simultâneos mantendo tempo de resposta inferior a 3 segundos (percentil 95) nas operações comuns. |
| RNF08 | O sistema deve estar disponível (uptime) em, no mínimo, 99% do tempo mensal. |
| RNF09 | O sistema deve atender à WCAG 2.1 nível AA na interface pública. |
| RNF10 | O código-fonte e a arquitetura devem permitir manutenção e evolução (modularidade, documentação técnica). |
| RNF11 | O sistema deve estar em conformidade com legislação de proteção de dados aplicável (ex.: LGPD). |
| RNF12 | O conteúdo de artigos não públicos deve ser criptografado em repouso com algoritmo forte (ex.: AES-256), com gestão de chaves de criptografia que impeça o acesso ao conteúdo por administradores do sistema. |
| RNF13 | Sessões autenticadas devem expirar automaticamente após período de inatividade (ex.: 30 minutos), exigindo novo login. |

## 8. Restrições

| ID | Descrição |
|---|---|
| RE01 | A autenticação forte deve utilizar autenticadores compatíveis com o padrão WebAuthn e com os navegadores e sistemas operacionais utilizados pelo laboratório. |
| RE02 | O sistema deve ser desenvolvido dentro do orçamento e prazo definidos pelo laboratório (a definir — pendência registrada). |
| RE03 | O sistema deve ser compatível com os principais navegadores web (Chrome, Firefox, Edge, Safari) em suas versões atualizadas, todos com suporte nativo a WebAuthn. |
| RE04 | A infraestrutura de hospedagem deve atender às políticas de segurança da instituição à qual o laboratório está vinculado. |
| RE05 | O módulo autenticado é acessível somente em computadores desktop/notebook; a autenticação WebAuthn utiliza os autenticadores suportados pelo navegador e sistema operacional da estação (chave USB, biometria/autenticador de plataforma ou passkey). A área pública permanece acessível em qualquer dispositivo. |

## 9. Regras de Negócio

| ID | Descrição |
|---|---|
| RN01 | Todo artigo é criado obrigatoriamente com visibilidade "não público". Não é permitido cadastrar um artigo diretamente como público. |
| RN02 | Artigos "não públicos" só podem ser acessados pelo autor principal, coautores membros do laboratório, orientador vinculado e co-orientador designado. Administradores não têm acesso ao conteúdo de artigos não públicos. |
| RN03 | Qualquer interação (visualizar, editar, excluir, avaliar, submeter, alterar visibilidade) com um artigo "não público" exige a validação prévia de autenticação WebAuthn. |
| RN04 | A submissão de um artigo para avaliação só pode ser feita pelo aluno autor principal e direcionada a um orientador vinculado a ele (vínculo mantido pelo administrador — UC08), com indicação opcional de co-orientador. |
| RN05 | Somente o orientador principal designado pode emitir o parecer decisório sobre o artigo submetido; o co-orientador emite apenas parecer complementar. |
| RN06 | Um artigo de aluno só pode ser tornado público após receber parecer decisório "aprovado" do orientador principal. Artigos de autoria do próprio orientador dispensam parecer, mas não a carta de aceite (RN14). |
| RN07 | A reversão de um artigo de "público" para "não público" solicitada pelo aluno exige aprovação do orientador vinculado (ou do administrador, na ausência deste); o orientador pode reverter diretamente artigos de sua própria autoria. |
| RN08 | Tentativas de acesso não autorizado ou falhas na autenticação WebAuthn devem ser registradas; após 5 tentativas consecutivas falhas, o usuário é bloqueado temporariamente por 15 minutos. |
| RN09 | Cada usuário do sistema deve possuir um único perfil de acesso ativo por vez (aluno, orientador ou administrador), podendo o administrador alterar esse perfil quando necessário. |
| RN10 | A gestão do ciclo de vida das credenciais WebAuthn é responsabilidade exclusiva do administrador e não lhe concede acesso ao conteúdo de artigos não públicos. |
| RN11 | Cada credencial WebAuthn deve estar vinculada a um único usuário. Em caso de perda/roubo do autenticador ou desligamento do membro, a credencial deve ser revogada imediatamente pelo administrador; uma credencial substituta pode ser registrada e vinculada. |
| RN12 | Coautores membros do laboratório podem visualizar e editar o artigo (mediante autenticação WebAuthn, quando não público), mas não podem submetê-lo, excluí-lo ou alterar sua visibilidade — ações restritas ao autor principal (e, quando aplicável, ao orientador vinculado). Coautores externos não têm acesso ao sistema. |
| RN13 | O parecer complementar do co-orientador é opcional e não bloqueia o fluxo de avaliação; a decisão sobre o artigo é sempre do parecer decisório do orientador principal. |
| RN14 | A publicação de um artigo (transição para "público") exige carta de aceite do evento/periódico anexada ao artigo, além das condições de parecer (RN06). |
| RN15 | O prazo sugerido de parecer é a deadline do evento menos a margem mínima para correções (parâmetro do sistema; padrão: 7 dias). O sistema deve alertar aluno e revisores quando a submissão ocorrer com prazo inferior à margem e enviar lembretes automáticos aos revisores conforme a aproximação do prazo. |
