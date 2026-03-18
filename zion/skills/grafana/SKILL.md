---
name: grafana
description: Query Grafana dashboards and Loki logs via MCP. Use when investigating logs, checking dashboards, correlating alerts, or debugging services with observability data.
---

# Grafana — Skill

## Pre-requisitos

O MCP server `mcp-grafana` deve estar registrado (feito automaticamente no bootstrap se `GRAFANA_URL` e `GRAFANA_TOKEN` estiverem em `~/.zion`).

Variaveis necessarias:
- `GRAFANA_URL` — URL da instancia Grafana (ex: `https://grafana.example.com`)
- `GRAFANA_TOKEN` — Service Account Token com role **Viewer** (prefixo `glsa_`)

## Tools MCP disponiveis

| Tool | Descricao |
|------|-----------|
| `search_dashboards` | Buscar dashboards por nome/tag |
| `get_dashboard_by_uid` | Obter dashboard completo por UID |
| `list_datasources` | Listar datasources configurados |
| `query_loki_logs` | Executar query LogQL e retornar logs |
| `query_prometheus` | Executar query PromQL (se disponivel) |
| `list_alert_rules` | Listar regras de alerta |
| `get_alert_rule_by_uid` | Detalhes de um alerta especifico |

## Referencia rapida LogQL

### Stream selectors
```logql
{app="monolito"}                    # label exato
{namespace=~"production|staging"}   # regex
{app!="debug"}                      # negacao
```

### Line filters
```logql
{app="monolito"} |= "error"        # contem string
{app="monolito"} !~ "health.*check" # nao match regex
```

### Parsers
```logql
{app="monolito"} | json                          # parse JSON automatico
{app="monolito"} | json | level="error"           # filtrar campo parseado
{app="monolito"} | logfmt                         # parse logfmt
{app="front"} | pattern "<ip> - <method> <path>"  # parse por pattern
```

### Aggregations (metric queries)
```logql
count_over_time({app="monolito"} |= "error" [5m])         # contagem em janela
rate({app="monolito"} |= "error" [5m])                     # taxa por segundo
sum by (level) (count_over_time({app="monolito"} | json [1h]))  # agrupado
```

## Workflow padrao

1. **Encontrar o dashboard** — `search_dashboards` com query generica
2. **Inspecionar** — `get_dashboard_by_uid` para ver panels e queries existentes
3. **Identificar datasource** — `list_datasources` se necessario
4. **Query logs** — `query_loki_logs` com LogQL (comece simples, refine)
5. **Correlacionar** — cruzar logs com alertas ou metricas

## Seguranca

- O token tem role **Viewer** — somente leitura
- **NUNCA** expor o token em outputs, commits ou logs
- Nao tentar operacoes de escrita (criar/editar dashboards, silenciar alertas)
- Se uma operacao falhar com 403, e esperado — o token e read-only
