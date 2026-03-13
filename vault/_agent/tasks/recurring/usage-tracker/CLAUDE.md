---
timeout: 300
model: haiku
schedule: always
---
# Task: Usage Tracker

## Objetivo
Rastrear uso de tokens e custos da API Anthropic ao longo do tempo.

## O que fazer

### 1. Coletar dados
Execute `/workspace/scripts/api-usage.sh --json` e salve o resultado em `.ephemeral/usage/api-usage-YYYY-MM.jsonl`.

Se a chave não estiver configurada, registre isso no contexto e não falhe — apenas anote que precisa de configuração.

### 2. Analisar tendência
Se já houver dados históricos em `.ephemeral/usage/api-usage-*.jsonl`:
- Calcule média de tokens/dia
- Compare com o período anterior
- Estime custo mensal projetado

### 3. Atualizar contexto
Salve no `contexto.md`:
- Último snapshot de uso coletado
- Tendência (subindo, estável, descendo)
- Custo acumulado no mês (se disponível via Admin API)
- Alertas: se uso parecer anormalmente alto

### 4. Alertas
Se o uso diário médio projetar custo mensal > $50 USD, registre alerta no contexto.

## Notas
- Task recorrente — roda a cada hora
- Dados ficam em `.ephemeral/usage/`
- Sem Admin Key, só consegue rate limits (ainda útil pra ver tier e headroom)
