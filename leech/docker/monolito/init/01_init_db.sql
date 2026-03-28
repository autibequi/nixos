-- Init script para o postgres do monolito.
-- Roda automaticamente na primeira vez que o container sobe (via docker-entrypoint-initdb.d).
-- Adicione extensoes ou schemas necessarios aqui.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
