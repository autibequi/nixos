---
name: estrategia/grafana
description: Query logs Loki e dashboards Grafana da Estrategia. Use apos deploy, investigacao de bugs, ou quando precisar de logs de monolito/bo-container/front-student.
---

# Estrategia / Grafana — Skill de Negocio

## Instancia

- **URL:** `https://grafana.platform.estrategia.io`
- **Datasource principal:** Loki (logs)
- **Infraestrutura:** Kubernetes (GKE)

## Servicos e Labels Loki

| Servico | Label Loki | Formato de log | Notas |
|---------|-----------|----------------|-------|
| monolito | `{app="monolito"}` | JSON (zerolog) | Campos: `level`, `msg`, `error`, `caller`, `time`, `trace_id` |
| bo-container | `{app="bo-container"}` | Plaintext (Nuxt) | Prefixo `[nuxt]` ou `[vue-renderer]`; erros podem ser multiline |
| front-student | `{app="front-student"}` | Plaintext (Nuxt) | Similar ao bo-container |

### Labels comuns

- `namespace` — `production`, `staging`, `development`
- `pod` — nome do pod Kubernetes
- `container` — nome do container dentro do pod
- `stream` — `stdout` ou `stderr`

## Patterns de debug

### Pos-deploy (verificar saude)
```logql
# Erros nos ultimos 15min do monolito em producao
{app="monolito", namespace="production"} | json | level="error" | __error__=""

# Rate de erros (spike pos-deploy?)
sum(rate({app="monolito", namespace="production"} | json | level="error" [5m]))
```

### Investigar bug do Jira
```logql
# Buscar por trace_id (se disponivel no card)
{app="monolito"} | json | trace_id="abc123"

# Buscar por endpoint especifico
{app="monolito"} | json | msg=~".*\/api\/v1\/endpoint.*"

# Erros com stack trace
{app="monolito"} |= "panic" or |= "fatal"
```

### Erros de API
```logql
# Erros 5xx no monolito
{app="monolito"} | json | status >= 500

# Timeout ou conexao recusada
{app="monolito"} |= "context deadline exceeded" or |= "connection refused"
```

### Problemas de DB
```logql
# Queries lentas ou erros de DB
{app="monolito"} | json | msg=~".*(slow query|deadlock|connection pool).*"
```

### Erros em servicos Node (bo-container, front-student)
```logql
# Erros gerais
{app="bo-container", namespace="production"} |= "error" !~ "favicon"

# Memory/CPU issues
{app="front-student"} |= "FATAL ERROR" or |= "heap out of memory"
```

## Integracao com outras skills

### Apos deploy (estrategia/orq)
Depois de um deploy ou merge, checar logs:
1. `query_loki_logs` com `{app="<servico>", namespace="production"} | json | level="error"` nos ultimos 15min
2. Comparar rate de erros antes/depois do deploy
3. Se spike: investigar os logs de erro especificos

### Apos ler card Jira (estrategia/jira)
Com o contexto do bug:
1. Extrair servico afetado, endpoint, trace_id se disponivel
2. Buscar logs correlacionados no periodo do incidente
3. Incluir trechos relevantes na analise

### Debug com codigo (estrategia/mono, estrategia/bo, estrategia/front)
1. Identificar o handler/service no codigo
2. Buscar logs desse endpoint/funcao
3. Correlacionar erro no log com o codigo-fonte

## Dashboards conhecidos

> Preencher apos primeira conexao com `search_dashboards`.
> Formato: `| Nome | UID | Descricao |`

| Nome | UID | Descricao |
|------|-----|-----------|
| *(executar `search_dashboards` para popular)* | — | — |

## Particularidades do stack

- **Go (monolito):** logs em JSON via zerolog. Campos padrao: `level`, `msg`, `error`, `caller`, `time`. Use `| json` para parsear.
- **Nuxt (bo-container, front-student):** logs em plaintext. Erros podem ser multiline (stack trace JS). Use `|=` para line filter.
- **Kubernetes labels:** alem de `app`, use `namespace` para filtrar ambiente. `pod` para isolar instancia especifica.
- **Rate limiting:** queries Loki pesadas podem demorar. Comece com janelas pequenas (5m, 15m) e expanda se necessario.
