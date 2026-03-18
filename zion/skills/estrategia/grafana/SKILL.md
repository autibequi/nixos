---
name: estrategia/grafana
description: Navegar logs e dashboards Grafana da Estrategia. Datasources: Loki (K8s workers) + CloudWatch (ECS apps). Use apos deploy, debug de bugs, ou investigacao de erros.
---

# Estrategia / Grafana

## Instancia

- **URL:** `https://grafana.platform.estrategia.io`
- **Infraestrutura:** Híbrida — ECS (apps principais) + K8s (workers/search)

## Datasources

| UID | Nome | Tipo | Onde roda |
|-----|------|------|-----------|
| `loki` | Loki | loki | K8s workers e serviços |
| `cloudwatch` | CloudWatch | cloudwatch | ECS apps (backend, front-student, etc.) |
| `prometheus` | Prometheus | prometheus | Métricas K8s (SQS workers, search) |

---

## Mapa de serviços por datasource

### ECS → CloudWatch (apps principais)

Queries usam **CloudWatch Insights (CWLI)**, não LogQL.
Account AWS: `253386313515`, região: `us-east-1`.

| Serviço | Log Group | Notas |
|---------|-----------|-------|
| **Monolito API server** | `/ecs/backend-prod` | Go, API HTTP principal |
| **Front Student** | `/ecs/front-student-prod` | Nuxt.js |
| Accounts | `/ecs/accounts-prod` | |
| E-commerce ECS | `/ecs/e-commerce-prod` | |
| Coaching | `/ecs/coaching-prod` | |
| CNAB | `/ecs/cnab-prod` | |
| Coruja AI | `/ecs/coruja-ai-prod` | |
| Discursivas | `/ecs/discursivas-prod` | |
| Landing Pages | `/ecs/frontend-landing-pages-prod` | |
| MCI | `/ecs/mci-prod` | possível bo-container? a confirmar |
| Questions | `/ecs/questions-prod` | |
| Strapi | `/ecs/strapi-prod` | CMS |
| Toggler | `/ecs/toggler-prod` | feature flags |
| User Access ECS | `/ecs/user-access-prod` | |
| User Events | `/ecs/user-events-prod` | |
| User Preferences | `/ecs/user-preferences-prod` | |
| Worker Study Time | `/ecs/worker-study-time-prod` | |
| Publisher Auditlogs | `/ecs/publisher-auditlogs-prod` | |
| Text Analysis | `/ecs/text-analysis-prod` | |
| Sync Videos Cron | `/ecs/sync-videos-cron-prod` | |
| Delete Questions Task | `/ecs/delete-questions-task-prod` | |

> **bo-container NÃO encontrado** — não está na lista ECS nem no K8s com esse nome.
> Hipótese: `/ecs/mci-prod` ou ainda não migrado. Investigar se necessário.

### K8s → Loki (workers)

Queries usam **LogQL**. Todos os workers Go usam zerolog JSON.

| Serviço | LogQL | Namespace | Formato | Campos-chave |
|---------|-------|-----------|---------|-------------|
| **Monolito Worker** (SQS) | `{app="monolito-worker", namespace="monolito-worker"}` | `monolito-worker` | JSON zerolog | `level`, `time`, `worker_id`, `message_id`, `appctx.user_id`, `handler`, `duration_ms`, `alloc_kb` |
| **Ecommerce Worker** (SQS) | `{app="ecommerce", namespace="ecommerce"}` | `ecommerce` | JSON zerolog | `level`, `time`, `appctx.vertical`, `appctx.user_id`, `appctx.order_id`, `appctx.worker_handler_name` |
| **User Access Worker** (SQS) | `{app="user-access", namespace="user-access"}` | `user-access` | JSON zerolog | `level`, `time`, `worker_id`, `message_id` |
| **Accounts Jobs** (cron) | `{app="accounts", namespace="accounts"}` | `accounts` | JSON zerolog | `level`, `time`, `method` |
| **Search Workers** (Kafka/Debezium) | `{app="search", namespace="debezium"}` | `debezium` | JSON zerolog | `level`, `version`, `ldi_id`, `time`, `caller`, `message`, `messages_received_by_topic` |
| PDF Kit | `{app="pdf-kit-consumer-app", namespace="pdf-kit"}` | `pdf-kit` | Python plaintext | `[INFO] mensagem` |
| PDF Kit Long Running | `{app="pdf-kit-long-running-consumer-app", namespace="pdf-kit"}` | `pdf-kit` | Python plaintext | |
| Webcast API | `{app="webcast-api", namespace="webcasts"}` | `webcasts` | JSON Echo | `method`, `uri`, `status`, `latency_human`, `remote_ip` |

#### Workers por domínio (K8s, sufixo hash)
Formato: `{app=~"<dominio>-worker-v3", namespace="debezium"}` ou via `app="search"`.
Ex.: `materiais-worker-v3`, `questions-worker-v3`, `goals-worker-v3`, `event-tracker-worker-v3`.

---

## Dashboards

| Nome | UID | Datasource | O que monitora |
|------|-----|-----------|----------------|
| **ECS Logs** | `cehsqeou8rtvke` | CloudWatch | Panics + erros em todos ECS (inclui backend-prod, front-student-prod) |
| **SQS Worker** | `fekhajb8lmg3kc` | Prometheus | Métricas SQS: ecommerce, monolito-worker, user-access (latência, rate, WIP) |
| **Erros nos Workers** | `bea6645xc1beoa` | Loki | K8s workers: accounts, ecommerce, google-indexer, monolito-worker, pdf-kit |
| **Worker (Search)** | `be63427ypdloga` | Prometheus | Search worker: latência por `flow_key`, taxa de sucesso, erros |
| **[Search] Kafka Metrics** | `rrE2HgHVz` | Prometheus | Kafka metrics do search-worker |
| **Search** | `be08t0ld8sq9sc` | — | Dashboard principal do serviço search |
| **Falhas em Pods** | `aujpjhs` | K8s | Pod failures em geral |
| Erros nos Workers Copy | `dea68sfcpxs6ob` | Loki | Cópia do Erros nos Workers |

---

## Queries úteis

### CloudWatch — Monolito API / Front Student (ECS)

```cwli
# Erros no backend (monolito API)
fields @timestamp, @message
| filter @message like /(?i)error/
| sort @timestamp desc
| limit 50

# Panics no backend
fields @timestamp, @message
| filter @message like /(?i)panic/
| sort @timestamp desc

# Filtrar por endpoint específico
fields @timestamp, @message
| filter @message like "/api/v1/seu-endpoint"
| sort @timestamp desc | limit 20
```
> Usar `get_dashboard_by_uid("cehsqeou8rtvke")` para ver queries completas do ECS Logs.

### Loki — Monolito Worker (K8s SQS)

```logql
# Erros recentes
{app="monolito-worker"} | json | level="error"

# Por handler específico
{app="monolito-worker"} | json | handler="ldis.print.resolved"

# Panics
{app="monolito-worker"} |= "panic"

# Rate de erros (últimos 5min)
sum(rate({app="monolito-worker"} | json | level="error" [5m]))
```

### Loki — Ecommerce Worker (K8s SQS)

```logql
# Erros por vertical
{app="ecommerce"} | json | level="error"

# Por handler (ex: CreateLeadFromOrder)
{app="ecommerce"} | json | appctx_worker_handler_name="CreateLeadFromOrder"

# Por order_id
{app="ecommerce"} | json | appctx_order_id="<uuid>"
```

### Loki — Search Workers (Kafka/Debezium)

```logql
# Todos os logs de search
{app="search", namespace="debezium"} | json

# Erros
{app="search"} | json | level="error"

# Por worker específico
{app="search", container="questions-worker-v3"} | json

# Estatísticas de mensagens
{app="search"} | json | message="estatísticas atualizadas"
```

### Prometheus — SQS Workers

```promql
# Rate de mensagens por handler (ecommerce, monolito-worker, user-access)
rate(sqs_messages_received{job="monolito-worker"}[$__rate_interval])

# Taxa de sucesso
rate(sqs_messages_deleted{job="ecommerce"}[$__rate_interval])

# Handlers registrados
sqs_handlers_registered{job="user-access"}

# Mensagens em processamento (WIP)
sqs_numer_of_messages_in_worker{job="monolito-worker"}
```

### Prometheus — Search Worker

```promql
# Latência por flow_key
rate(search_worker_processing_time_milliseconds_sum[$__rate_interval])
  / rate(search_worker_processing_time_milliseconds_count[$__rate_interval])

# Taxa de sucesso por flow_key
rate(search_worker_messages_ingested_total{status="success"}[$__rate_interval])
  / rate(search_worker_messages_ingested_total[$__rate_interval])

# Erros por tópico
count by(flow_key) (rate(search_worker_messages_ingested_total{status="error"}[$__rate_interval]))
```

---

## Workflow de debug

### Após deploy — verificar saúde

1. **ECS (monolito API / front-student):** `get_dashboard_by_uid("cehsqeou8rtvke")` → ver panics/errors
2. **K8s workers:** `query_loki_logs` com `{app="monolito-worker"} | json | level="error"` últimos 15min
3. **SQS workers:** `query_prometheus` com `rate(sqs_messages_received{job="monolito-worker"}[5m])` para ver se estão consumindo

### Investigar bug (Jira card)

1. Identificar serviço afetado e se é ECS ou K8s
2. **Se ECS:** usar CloudWatch Insights no log group correspondente
3. **Se K8s worker:** usar LogQL com `app` + `namespace` corretos
4. Filtrar por `user_id`, `order_id`, `trace_id` se disponível

### Search fora do ar

1. `query_prometheus` → `search_worker_messages_ingested_total{status="error"}` subindo?
2. `query_loki_logs` com `{app="search", namespace="debezium"} | json | level="error"`
3. Dashboard `rrE2HgHVz` para métricas Kafka

---

## Integração com outras skills

- **estrategia/orq** (pós-deploy): checar ECS Logs dashboard + rate de erros Loki nos workers
- **estrategia/jira** (debug bug): extrair serviço + período → query no datasource correto
- **estrategia/mono / bo / front**: identificar handler → buscar logs por `handler` ou endpoint

---

## Particularidades do stack

- **Go workers (zerolog JSON):** usar `| json` no LogQL. Campos: `level`, `time`, `message`. `appctx` contém contexto de negócio.
- **ECS apps:** acessar via CloudWatch, não Loki. Datasource `cloudwatch` (uid: `cloudwatch`).
- **Search:** Kafka consumer via Debezium CDC — namespace `debezium`, service_name `search`.
- **SQS workers com Prometheus:** `ecommerce`, `monolito-worker`, `user-access` — usar dashboard `fekhajb8lmg3kc`.
- **bo-container:** não mapeado ainda. Hipótese: `/ecs/mci-prod` no CloudWatch.

---

## Manutenção — Como atualizar esta skill

Se dashboards sumirem ou queries não retornarem resultados, re-executar:

### 1. Re-descobrir dashboards (UIDs podem mudar)
```tool
search_dashboards(query="worker")       # → Workers, SQS
search_dashboards(query="search")       # → Search, Kafka
search_dashboards(query="ecs")          # → ECS Logs
search_dashboards(query="falhas pods")  # → K8s alerts
```
Atualizar tabela de Dashboards com os novos UIDs.

### 2. Verificar se K8s workers ainda existem no Loki
```tool
list_loki_label_values(datasourceUid="loki", labelName="app")
```
Procurar: `monolito-worker`, `ecommerce`, `user-access`, `accounts`, `search`.
Se algum sumiu → namespace pode ter mudado. Checar `labelName="namespace"`.

### 3. Verificar se ECS log groups ainda existem
Abrir dashboard ECS Logs (`get_dashboard_by_uid("cehsqeou8rtvke")`) e inspecionar
os `logGroups` das queries. Se tiver novos serviços, adicionar na tabela ECS.

### 4. Verificar SQS workers no Prometheus
```tool
query_prometheus(datasourceUid="prometheus",
  expr="group by(job) (sqs_handlers_registered)", queryType="instant", startTime="now")
```
Se retornar jobs novos (ex: `bo-container`), adicionar na seção de Prometheus.

### 5. Investigar bo-container (ainda não mapeado)
- Tentar `query_loki_logs` com `{app=~"bo.*"}` e `{app=~"mci.*"}`
- Tentar CloudWatch via dashboard ECS Logs buscando log group `/ecs/bo-container-prod` ou `/ecs/mci-prod`
- Atualizar quando confirmado
