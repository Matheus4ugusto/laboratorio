package com.lab.audit.application.port.in;

import java.time.Instant;

/**
 * Descrição de um evento a ser auditado. Objeto de transporte da porta:
 * carrega apenas dados, mantendo os módulos chamadores desacoplados das
 * entidades internas do módulo audit.
 *
 * @param acao        código do evento (ex.: "ARTIGO_PUBLICADO", "WEBAUTHN_FALHA")
 * @param entidade    tipo do recurso afetado (ex.: "ARTIGO", "CREDENCIAL")
 * @param entidadeId  identificador do recurso afetado
 * @param usuarioId   quem realizou a ação (pode ser nulo para eventos do sistema)
 * @param detalhe     informação adicional livre (ex.: motivo de uma falha)
 * @param momento     instante do evento
 */
public record RegistroAuditoria(
        String acao,
        String entidade,
        String entidadeId,
        String usuarioId,
        String detalhe,
        Instant momento) {
}
