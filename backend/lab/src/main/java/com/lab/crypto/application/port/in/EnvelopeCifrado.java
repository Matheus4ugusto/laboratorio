package com.lab.crypto.application.port.in;

/**
 * Resultado da cifragem envelope: o texto cifrado acompanhado dos metadados
 * necessários para decifrar (IV/nonce do AES-GCM e a DEK já cifrada pela KEK).
 * É um objeto de transporte da porta — sem lógica e sem dependência de framework.
 */
public record EnvelopeCifrado(
        byte[] conteudoCifrado,
        byte[] iv,
        byte[] dekCifrada) {
}
