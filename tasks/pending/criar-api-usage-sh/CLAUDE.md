# criar-api-usage-sh

## Objetivo
Criar `scripts/api-usage.sh` que está ausente mas é referenciado pelo makefile em 3 targets: `usage-api`, `usage-api-7d`, `usage-api-30d`.

## Problema
O `makefile` chama `bash /workspace/scripts/api-usage.sh` mas o arquivo não existe.
Apenas `clau-runner.sh`, `init.sh` e `nvme-benchmark.sh` existem em `scripts/`.
Resultado: `make usage-api` falha com "No such file or directory".

## O que fazer

### 1. Criar `scripts/api-usage.sh`
O script deve:
- Consultar a API de usage da Anthropic (`https://api.anthropic.com/v1/usage` ou endpoint equivalente)
- Aceitar argumento opcional: `-- 7d` ou `-- 30d` para range de datas
- Usar `ANTHROPIC_ADMIN_KEY` (disponível no container via env)
- Exibir output formatado: tokens usados, custo estimado, modelos

Referência de API: https://docs.anthropic.com/en/api/usage — usar `ANTHROPIC_ADMIN_KEY` como bearer token.

### 2. Corrigir `.PHONY` no makefile
Adicionar `usage-api-7d` e `usage-api-30d` à lista `.PHONY` (linha 3).

## Regras
- Script deve ser executável (`chmod +x`)
- Usar `curl` + `jq` (disponíveis no container)
- Tratar ausência de `ANTHROPIC_ADMIN_KEY` com mensagem clara
- Não usar Python se `curl`+`jq` resolve
