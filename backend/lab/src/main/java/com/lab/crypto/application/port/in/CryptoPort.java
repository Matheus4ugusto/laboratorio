package com.lab.crypto.application.port.in;

/**
 * Porta pública (inbound) do módulo de criptografia — API que os demais
 * módulos (articles, review, documents) usam para cifrar/decifrar conteúdo
 * de artigos não públicos (RNF12, ADR-007).
 *
 * O consumidor NÃO conhece Vault, AES-GCM nem o formato da DEK: tudo isso
 * é detalhe da implementação em crypto.adapter. A decifra só deve ocorrer
 * após autorização (RN02) e step-up WebAuthn válido (RN03), controle que
 * o caso de uso chamador é responsável por garantir antes de invocar aqui.
 */
public interface CryptoPort {

    /**
     * Cifra o conteúdo de um artigo. Na primeira chamada gera a DEK do
     * artigo (AES-256-GCM) e a armazena cifrada pela KEK do Vault.
     *
     * @param artigoId  identifica a DEK a ser usada/criada
     * @param textoClaro bytes em claro (arquivo ou campo sensível)
     * @return envelope cifrado (pronto para persistir no MinIO/banco)
     */
    EnvelopeCifrado cifrar(String artigoId, byte[] textoClaro);

    /**
     * Decifra um envelope previamente cifrado com a DEK do artigo.
     */
    byte[] decifrar(String artigoId, EnvelopeCifrado envelope);

    /**
     * Rotaciona a DEK do artigo, gerando uma nova chave e descartando a
     * anterior. Usado na reversão de "Público" para não público (RN07),
     * quando o conteúdo é recifrado com nova DEK.
     */
    void rotacionarChave(String artigoId);
}
