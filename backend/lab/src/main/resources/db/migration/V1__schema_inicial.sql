CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    hash_senha VARCHAR(255) NOT NULL,
    perfil VARCHAR(20) NOT NULL CHECK (perfil IN ('ADMIN', 'ORIENTADOR', 'ORIENTADO')),
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vinculo_orientador_orientado(
    orientado_id INT NOT NULL,
    orientador_id INT NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (orientado_id, orientador_id),
    FOREIGN KEY (orientado_id) REFERENCES usuarios(id),
    FOREIGN KEY (orientador_id) REFERENCES usuarios(id)
);

-- Um usuário pode ter várias credenciais (substituição/revogação — RF16/RN11),
-- por isso a PK é a credencial, não o usuário.
CREATE TABLE credenciais_webauthn(
    credencial_id VARCHAR(255) PRIMARY KEY,
    usuario_id INT NOT NULL REFERENCES usuarios(id),
    public_key TEXT NOT NULL,
    contador BIGINT NOT NULL,
    tipo_autenticador VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ATIVO' CHECK (status IN ('ATIVO', 'REVOGADO')),
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_credenciais_usuario ON credenciais_webauthn (usuario_id);

CREATE TABLE artigos(
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    resumo TEXT NOT NULL,
    palavras_chave VARCHAR(255) NOT NULL,
    evento_alvo VARCHAR(255) NOT NULL,
    deadline_submissao TIMESTAMP NOT NULL,
    estado VARCHAR(32) NOT NULL CHECK (estado IN ('RASCUNHO', 'AGUARDANDO', 'APROVADO', 'APROVADO COM RESSALVAS', 'REPROVADO', 'PUBLICO', 'EXCLUIDO')),
    visibilidade VARCHAR(32) NOT NULL CHECK (visibilidade IN ('PUBLICO', 'PRIVADO', 'RESTRITO')),
    primeiro_autor_id INT NOT NULL REFERENCES usuarios(id),
    coautores_externos JSONB DEFAULT '[]'::jsonb,
    dek_cifrada BYTEA NOT NULL,
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Coautores membros: N:N com usuarios (RN12). Coautores externos ficam
-- no JSONB de artigos (FK em coluna array não é suportada pelo Postgres).
CREATE TABLE artigo_coautores(
    artigo_id INT NOT NULL REFERENCES artigos(id),
    usuario_id INT NOT NULL REFERENCES usuarios(id),
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (artigo_id, usuario_id)
);

CREATE TABLE submissao(
    artigo_id INT PRIMARY KEY REFERENCES artigos(id),
    evento_alvo VARCHAR(255) NOT NULL,
    deadline_submissao TIMESTAMP NOT NULL,
    prazo_sugerido TIMESTAMP NOT NULL,
    orientador_id INT NOT NULL REFERENCES usuarios(id),
    coorientador_id INT REFERENCES usuarios(id)
);

-- PK composta: uma submissão pode ter um parecer decisório (orientador)
-- e um complementar (co-orientador) — RN05/RN13.
CREATE TABLE pareceres(
    submissao_id INT NOT NULL REFERENCES submissao(artigo_id),
    tipo VARCHAR(32) NOT NULL CHECK (tipo IN ('DECISORIO', 'COMPLEMENTAR')),
    conteudo TEXT NOT NULL,
    autor_id INT NOT NULL REFERENCES usuarios(id),
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (submissao_id, tipo)
);

-- id próprio: um artigo tem mais de um documento (arquivo + carta de aceite).
CREATE TABLE documentos(
    id SERIAL PRIMARY KEY,
    artigo_id INT NOT NULL REFERENCES artigos(id),
    tipo VARCHAR(32) NOT NULL CHECK (tipo IN ('ARQUIVO', 'ACEITE')),
    ponteiro_minio TEXT NOT NULL,
    formato VARCHAR(32) NOT NULL CHECK (formato IN ('PDF', 'DOCX', 'TXT', 'MD')),
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_documentos_artigo ON documentos (artigo_id);

CREATE TABLE evento_auditoria (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    acao VARCHAR(100) NOT NULL,          -- ex.: 'ARTIGO_PUBLICADO', 'WEBAUTHN_FALHA'
    entidade VARCHAR(50) NOT NULL,       -- ex.: 'ARTIGO', 'CREDENCIAL'
    entidade_id VARCHAR(100),
    usuario_id INT REFERENCES usuarios(id),  -- NULL para eventos do sistema
    detalhe TEXT,
    momento TIMESTAMPTZ NOT NULL,
    hash_anterior CHAR(64) UNIQUE,       -- NULL só no primeiro registro (gênesis)
    hash_atual CHAR(64) NOT NULL UNIQUE
);

-- Reversão público -> não público (UC07/RF18): nasce PENDENTE e o decisor
-- (orientador ou admin) só é preenchido quando aprova/rejeita.
CREATE TABLE reversao(
    id SERIAL PRIMARY KEY,
    artigo_id INT NOT NULL REFERENCES artigos(id),
    solicitante INT NOT NULL REFERENCES usuarios(id),
    justificativa TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDENTE' CHECK (status IN ('PENDENTE', 'APROVADA', 'REJEITADA')),
    decisor INT REFERENCES usuarios(id),
    criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    decidido_em TIMESTAMP,
    CHECK ((status = 'PENDENTE') = (decisor IS NULL))
);

CREATE INDEX idx_reversao_artigo ON reversao (artigo_id);

CREATE INDEX idx_auditoria_entidade ON evento_auditoria (entidade, entidade_id);
CREATE INDEX idx_auditoria_momento ON evento_auditoria (momento);

-- Spring Session JDBC (ADR-008) — esquema oficial para PostgreSQL.
-- Criado na migration porque lab_app não pode criar tabelas
-- (SPRING_SESSION_JDBC_INITIALIZE_SCHEMA=never no compose).
CREATE TABLE spring_session (
    primary_id CHAR(36) NOT NULL,
    session_id CHAR(36) NOT NULL,
    creation_time BIGINT NOT NULL,
    last_access_time BIGINT NOT NULL,
    max_inactive_interval INT NOT NULL,
    expiry_time BIGINT NOT NULL,
    principal_name VARCHAR(100),
    CONSTRAINT spring_session_pk PRIMARY KEY (primary_id)
);

CREATE UNIQUE INDEX spring_session_ix1 ON spring_session (session_id);
CREATE INDEX spring_session_ix2 ON spring_session (expiry_time);
CREATE INDEX spring_session_ix3 ON spring_session (principal_name);

CREATE TABLE spring_session_attributes (
    session_primary_id CHAR(36) NOT NULL,
    attribute_name VARCHAR(200) NOT NULL,
    attribute_bytes BYTEA NOT NULL,
    CONSTRAINT spring_session_attributes_pk PRIMARY KEY (session_primary_id, attribute_name),
    CONSTRAINT spring_session_attributes_fk FOREIGN KEY (session_primary_id)
        REFERENCES spring_session (primary_id) ON DELETE CASCADE
);

-- acesso padrão da aplicação
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO lab_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO lab_app;

-- auditoria: append-only (ADR-004)
REVOKE UPDATE, DELETE, TRUNCATE ON evento_auditoria FROM lab_app;
