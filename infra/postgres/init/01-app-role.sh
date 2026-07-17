#!/bin/sh
# Cria o role da aplicação (ADR-004): sem privilégios de dono, para que o
# REVOKE de UPDATE/DELETE na auditoria (append-only) seja efetivo.
# Executado pelo entrypoint do Postgres apenas na primeira inicialização
# do volume (docker-entrypoint-initdb.d).
set -e

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<-EOSQL
  CREATE ROLE lab_app LOGIN PASSWORD '${LAB_APP_PASSWORD}';
  GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO lab_app;
  GRANT USAGE ON SCHEMA public TO lab_app;
EOSQL
