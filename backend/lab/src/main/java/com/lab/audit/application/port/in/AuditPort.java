package com.lab.audit.application.port.in;

/**
 * Porta pública (inbound) do módulo de auditoria — API que os demais módulos
 * usam para registrar eventos na trilha append-only com hash encadeado (RNF05).
 *
 * O consumidor não conhece o cálculo do hash SHA-256 nem a persistência:
 * apenas descreve "o que aconteceu". A imutabilidade e o encadeamento são
 * responsabilidade da implementação em audit.
 */
public interface AuditPort {

    /**
     * Registra um evento na trilha de auditoria. A operação é append-only:
     * nunca atualiza nem remove registros anteriores.
     */
    void registrar(RegistroAuditoria registro);
}
