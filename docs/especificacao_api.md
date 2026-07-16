# Especificação de Endpoints da API

## Sistema Web para Laboratório de Pesquisa

**Versão:** 1.0
**Data:** 13/07/2026
**Documentos base:** Requisitos v1.4 · Definição Arquitetural v1.1

---

## Convenções

- Prefixo base: `/api`. Endpoints públicos ficam sob `/api/public` (sem autenticação); os demais exigem sessão autenticada (cookie de sessão — ADR-008).
- **Respostas comuns a todos os endpoints autenticados** (omitidas das listas abaixo): `[401]` Sessão ausente ou expirada (RNF13); `[500]` Erro interno.
- **Step-up WebAuthn (RN03):** endpoints marcados com 🔐 interagem com artigo não público e exigem prova WebAuthn recente (UC05). Sem ela, respondem `[428]` Step-up WebAuthn exigido — o cliente deve executar o desafio (`/api/webauthn/*`) e repetir a chamada.
- `[423]` indica bloqueio temporário de 15 minutos após 5 falhas consecutivas de autenticação WebAuthn (RN08).
- O módulo autenticado rejeita user-agents móveis com `[403]` no login (RNF01/RE05).

---

## 1. Área Pública (RF01, RF14, UC02)

[GET] /api/public/publicacoes
Respostas:
[200] Lista paginada das publicações públicas, com metadados e autoria (membros e externos).

[GET] /api/public/publicacoes/{id}
Respostas:
[200] Detalhe da publicação pública.
[404] Publicação inexistente ou não pública (não revela a existência de artigos não públicos — RF05).

[GET] /api/public/publicacoes/{id}/arquivo
Respostas:
[302] Redirecionamento para URL pré-assinada de download do arquivo (ADR-005).
[404] Publicação inexistente ou não pública.

## 2. Autenticação e Sessão (RF02, RNF13, UC01)

[POST] /api/auth/login
Respostas:
[200] Login realizado; cookie de sessão emitido.
[400] Payload inválido.
[401] Credenciais inválidas.
[403] Acesso a partir de dispositivo móvel bloqueado (RNF01/RE05) ou usuário desativado.

[POST] /api/auth/logout
Respostas:
[204] Sessão encerrada.

[GET] /api/auth/me
Respostas:
[200] Dados do usuário autenticado, perfil ativo (RN09) e estado do step-up WebAuthn.

[POST] /api/auth/recuperar-senha
Respostas:
[202] Solicitação registrada; e-mail enviado se o endereço existir (resposta uniforme contra enumeração de usuários).
[400] E-mail em formato inválido.

[POST] /api/auth/redefinir-senha
Respostas:
[204] Senha redefinida (hash Argon2id — RNF03).
[400] Nova senha fora da política.
[410] Token de redefinição inválido ou expirado.

## 3. Step-up WebAuthn (RF09, RF10, RF11, RNF04, UC05)

[POST] /api/webauthn/desafio
Respostas:
[200] Opções de assertion WebAuthn (desafio, credenciais elegíveis, `userVerification: required`).
[404] Usuário sem credencial WebAuthn ativa registrada.
[423] Usuário temporariamente bloqueado (RN08).

[POST] /api/webauthn/verificar
Respostas:
[200] Assertion válida; janela de step-up aberta na sessão. Registrado em auditoria (RF11).
[400] Assertion malformada.
[401] Assinatura inválida, credencial revogada ou desafio expirado. Falha registrada em auditoria (RF11).
[423] Usuário temporariamente bloqueado após 5 falhas consecutivas (RN08).

## 4. Artigos (RF03, RF04, RF05, RF17, RF19, UC03, UC10)

[GET] /api/artigos
Respostas:
[200] Lista dos artigos acessíveis ao usuário conforme RN02 (autor principal, coautor membro, orientador vinculado, co-orientador designado); metadados apenas, sem conteúdo.

[POST] /api/artigos
Respostas:
[201] Artigo criado no estado "Rascunho (não público)" (RN01/RF04), com autor principal, coautores membros e externos (RF19); conteúdo cifrado (RNF12).
[400] Dados inválidos (ex.: coautor membro inexistente).
[403] Perfil sem permissão de cadastro (apenas aluno e orientador — RF03).

🔐 [GET] /api/artigos/{id}
Respostas:
[200] Detalhe do artigo, incluindo estado, autoria, submissões e documentos.
[403] Usuário sem acesso ao artigo (RN02). Tentativa registrada em auditoria (RF11).
[404] Artigo inexistente ou excluído.
[428] Step-up WebAuthn exigido (artigo não público — RN03).

🔐 [PUT] /api/artigos/{id}
Respostas:
[200] Artigo atualizado (autor principal, coautor membro ou orientador vinculado — RF17/RN12).
[400] Dados inválidos.
[403] Usuário sem permissão de edição (RN02/RN12).
[404] Artigo inexistente ou excluído.
[409] Estado "Aguardando parecer" não permite edição (UC10).
[428] Step-up WebAuthn exigido (RN03).

🔐 [DELETE] /api/artigos/{id}
Respostas:
[204] Exclusão lógica realizada e auditada (RF17).
[403] Apenas autor principal ou orientador vinculado podem excluir (RN12).
[404] Artigo inexistente ou já excluído.
[428] Step-up WebAuthn exigido (RN03).

🔐 [GET] /api/artigos/{id}/arquivo
Respostas:
[200] Conteúdo do arquivo, decifrado após autorização (RN02) e step-up (RN03).
[403] Usuário sem acesso ao artigo (RN02).
[404] Artigo ou arquivo inexistente.
[428] Step-up WebAuthn exigido (RN03).

🔐 [PUT] /api/artigos/{id}/arquivo
Respostas:
[200] Arquivo substituído/enviado e cifrado com a DEK do artigo (RF14/RNF12).
[403] Usuário sem permissão de edição (RN12).
[404] Artigo inexistente.
[409] Estado do artigo não permite edição.
[413] Arquivo excede o tamanho máximo.
[415] Formato de arquivo não suportado.
[428] Step-up WebAuthn exigido (RN03).

## 5. Submissão para Avaliação (RF06, RF20, RF21, RF22, UC04)

🔐 [POST] /api/artigos/{id}/submissoes
Respostas:
[201] Submissão criada com evento alvo, deadline, co-orientador opcional e prazo sugerido de parecer (RN15); artigo em "Aguardando parecer"; revisores notificados (RF08). Alerta de prazo crítico incluído na resposta quando a deadline for inferior à margem mínima.
[400] Evento alvo/deadline ausentes ou deadline não futura (RF21).
[403] Usuário não é o aluno autor principal, ou orientador indicado sem vínculo ativo (RN04).
[404] Artigo inexistente.
[409] Estado do artigo não permite submissão.
[428] Step-up WebAuthn exigido (RN03).

[GET] /api/submissoes
Respostas:
[200] Lista de submissões nas quais o usuário é revisor (orientador ou co-orientador) ou autor, com evento alvo, deadline e prazo sugerido (RF21).

🔐 [GET] /api/submissoes/{id}
Respostas:
[200] Detalhe da submissão e pareceres já emitidos.
[403] Usuário não participa da submissão (RN02/RN05).
[404] Submissão inexistente.
[428] Step-up WebAuthn exigido (RN03).

## 6. Pareceres (RF07, RF08, RN05, RN13, UC06)

🔐 [POST] /api/submissoes/{id}/pareceres
Respostas:
[201] Parecer registrado — decisório (aprovado/reprovado/com ressalvas) se orientador principal, complementar se co-orientador (RN05/RN13); aluno notificado (RF08); artigo passa a "Avaliado" após o decisório.
[400] Tipo de parecer ou conteúdo inválido.
[403] Usuário não é o revisor designado (RN05).
[404] Submissão inexistente.
[409] Parecer decisório já emitido para esta submissão.
[428] Step-up WebAuthn exigido (RN03).

## 7. Visibilidade e Publicação (RF13, RF18, RF23, RN06, RN07, RN14, UC07, UC11)

🔐 [PUT] /api/artigos/{id}/carta-aceite
Respostas:
[201] Carta de aceite anexada e auditada (UC11); condição RN14 satisfeita.
[403] Usuário não é autor principal/orientador autor.
[404] Artigo inexistente.
[409] Estado do artigo não permite anexar carta (UC11).
[415] Formato de arquivo inválido.
[428] Step-up WebAuthn exigido (RN03).

🔐 [POST] /api/artigos/{id}/publicar
Respostas:
[200] Artigo tornado público; conteúdo disponibilizado na área pública (UC07).
[403] Usuário não é autor principal ou orientador vinculado.
[404] Artigo inexistente.
[409] Condições de publicação não atendidas: parecer "aprovado" ausente (RN06) e/ou carta de aceite não anexada (RN14/RF23).
[428] Step-up WebAuthn exigido (RN03).

[POST] /api/artigos/{id}/reversoes
Respostas:
[201] Solicitação de reversão para não público registrada com justificativa; orientador notificado (RF18/RN07). Reversão direta (orientador em artigo próprio) aplicada imediatamente com [200].
[400] Justificativa ausente.
[403] Usuário sem permissão para solicitar/reverter (RN07).
[404] Artigo inexistente.
[409] Artigo não está no estado "Público".

[POST] /api/reversoes/{id}/decisao
Respostas:
[200] Decisão registrada (aprovada → artigo retorna a não público e é recifrado com nova DEK; rejeitada → permanece público) (RF18/RN07).
[403] Usuário não é o orientador vinculado (ou administrador na ausência deste).
[404] Solicitação inexistente.
[409] Solicitação já decidida.

## 8. Administração — Usuários e Vínculos (RF12, RN09, UC08)

[GET] /api/admin/usuarios
Respostas:
[200] Lista paginada de usuários com perfil e status.
[403] Usuário não é administrador.

[POST] /api/admin/usuarios
Respostas:
[201] Usuário criado com perfil único ativo (RN09).
[400] Dados inválidos.
[403] Usuário não é administrador.
[409] E-mail já cadastrado.

[PUT] /api/admin/usuarios/{id}
Respostas:
[200] Usuário atualizado (dados, perfil, ativação/desativação).
[400] Dados inválidos.
[403] Usuário não é administrador.
[404] Usuário inexistente.

[DELETE] /api/admin/usuarios/{id}
Respostas:
[204] Usuário removido/desativado.
[403] Usuário não é administrador.
[404] Usuário inexistente.

[GET] /api/admin/vinculos
Respostas:
[200] Lista de vínculos aluno–orientador.
[403] Usuário não é administrador.

[POST] /api/admin/vinculos
Respostas:
[201] Vínculo aluno–orientador criado (habilita UC04).
[400] Perfis incompatíveis (aluno/orientador exigidos).
[403] Usuário não é administrador.
[409] Vínculo já existente.

[DELETE] /api/admin/vinculos/{id}
Respostas:
[204] Vínculo encerrado.
[403] Usuário não é administrador.
[404] Vínculo inexistente.

## 9. Administração — Credenciais WebAuthn (RF16, RN10, RN11, UC09)

[POST] /api/admin/credenciais/opcoes-registro
Respostas:
[200] Opções de registro WebAuthn para o usuário indicado (desafio; qualquer tipo de autenticador — chave USB, plataforma ou passkey; `userVerification: required`).
[403] Usuário não é administrador.
[404] Usuário alvo inexistente.

[POST] /api/admin/credenciais
Respostas:
[201] Credencial registrada e vinculada a um único usuário (RN11), com tipo de autenticador como metadado; registro auditado. Não concede ao administrador acesso a conteúdo (RN10).
[400] Attestation inválida ou desafio expirado.
[403] Usuário não é administrador.
[409] Credencial (credentialId) já registrada.

[GET] /api/admin/credenciais
Respostas:
[200] Lista de credenciais com usuário vinculado, tipo de autenticador e status (ativa/revogada).
[403] Usuário não é administrador.

[POST] /api/admin/credenciais/{id}/revogar
Respostas:
[200] Credencial revogada imediatamente (perda/roubo/desligamento — RN11); usos posteriores bloqueados e auditados.
[403] Usuário não é administrador.
[404] Credencial inexistente.
[409] Credencial já revogada.

## 10. Notificações (RF08, RF22)

[GET] /api/notificacoes
Respostas:
[200] Lista de notificações do usuário (pareceres, submissões, lembretes de prazo, reversões).

[PATCH] /api/notificacoes/{id}
Respostas:
[204] Notificação marcada como lida.
[404] Notificação inexistente ou de outro usuário.
