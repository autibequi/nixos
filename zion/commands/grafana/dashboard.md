Query Grafana dashboards and Loki logs via MCP. Use when investigating logs, checking dashboards, correlating alerts, or debugging services with observability data.

## Entrada
- $ARGUMENTS: busca por dashboard (nome, tag, folder) e/ou time range

## Instruções

1. **Levantar o relay server** se não estiver rodando:
   ```bash
   python3 /workspace/zion/scripts/grafana-relay.py --once &
   ```
   Se acabou de subir, avisar o usuário: *"Relay no ar. Abra **http://zion:8780** no browser."*

2. **Buscar dashboards** usando `mcp__grafana__search_dashboards` com a query do usuário.

3. **Se a busca retornar múltiplos resultados**, mostrar lista compacta para o usuário escolher:
   ```
   1. [folder] Dashboard Name (uid)
   2. [folder] Dashboard Name (uid)
   ```
   Perguntar qual quer abrir. Se for óbvio (1 resultado ou match exato), seguir direto.

4. **Gerar deeplink** com `mcp__grafana__generate_deeplink`:
   - `resourceType`: "dashboard"
   - `dashboardUid`: UID do dashboard escolhido
   - `timeRange`: extrair do argumento do usuário, ou default `{"from": "now-1h", "to": "now"}`
   - Se o usuário mencionou variáveis (ex: "namespace production"), passar como `queryParams`

5. **Enviar para o Chrome** via relay:
   ```bash
   curl -s -X POST http://localhost:8780/navigate \
     -H 'Content-Type: application/json' \
     -d '{"url":"<DEEPLINK>","title":"<DASHBOARD_TITLE>"}'
   ```

6. **Confirmar** com mensagem curta: "Navegando para **<título>**"

## Atalhos de busca

O usuário pode usar termos curtos. Mapear inteligentemente:
- "workers" → buscar "workers" ou "worker"
- "ecs" → buscar "ecs"
- "k8s pods" → buscar "pods" ou "kubernetes pod"
- "oom" → buscar "oomkilled"
- "rds" → buscar "rds"
- "sqs" → buscar "sqs"
- "k6" → buscar "k6"
- "dora" → buscar "dora"
- "airflow" → buscar "airflow"
- "search" → buscar "search"
- "webcasts" → buscar "webcasts"

## Flags opcionais no argumento

- `1h`, `6h`, `24h`, `7d` → time range (from: now-X, to: now)
- `panel:<id>` → navegar direto para um panel específico
- `explore` → abrir no Explore em vez de dashboard

## Exemplos

```
/grafana:dashboard workers
/grafana:dashboard ecs logs 6h
/grafana:dashboard k8s pods oom 24h
/grafana:dashboard dora
```
