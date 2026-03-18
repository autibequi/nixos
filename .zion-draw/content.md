# Grafana — Estrategia Overview (18/03/2026)

> Dados coletados via MCP Grafana. Última hora de métricas Prometheus + 2h de erros Loki.

---

## Infraestrutura Híbrida

```mermaid
graph LR
    subgraph ECS["ECS — CloudWatch"]
        BE["/ecs/backend-prod\n(Monolito API)"]
        FS["/ecs/front-student-prod\n(Nuxt.js)"]
        ACC["/ecs/accounts-prod"]
        ECOM_ECS["/ecs/e-commerce-prod"]
        COACH["/ecs/coaching-prod"]
        STRAPI["/ecs/strapi-prod\n(CMS)"]
        TOGGLER["/ecs/toggler-prod\n(Feature Flags)"]
        OUTROS["+ 13 servicos ECS"]
    end

    subgraph K8S["K8s — Loki + Prometheus"]
        MW["monolito-worker\n(SQS)"]
        EW["ecommerce\n(SQS)"]
        UA["user-access\n(SQS)"]
        SEARCH["search\n(Kafka/Debezium)"]
        PDF["pdf-kit\n(Python)"]
        WEB["webcast-api\n(Echo)"]
    end

    BE -->|"handlers"| MW
    ECOM_ECS -->|"orders"| EW
    BE -->|"users"| UA
    SEARCH -->|"CDC"| BE

    style ECS fill:#1a1a2e,stroke:#e94560,color:#eee
    style K8S fill:#1a1a2e,stroke:#0f3460,color:#eee
```

---

## SQS Workers — Taxa de Mensagens (ultima hora)

```mermaid
xychart-beta
    title "SQS msg/s por worker (ultima hora)"
    x-axis ["14:17","14:27","14:37","14:47","14:57","15:07","15:17","15:27","15:37","15:47"]
    y-axis "mensagens/s" 0 --> 8
    line "monolito-worker" [0.34, 0.41, 0.27, 0.76, 0.56, 0.29, 0.79, 1.06, 0.20, 0.19]
    line "ecommerce" [0.01, 0.01, 0.01, 0.01, 0.01, 0.00, 0.01, 0.01, 0.00, 0.00]
    line "user-access" [0.09, 0.04, 1.68, 1.66, 0.32, 0.05, 0.06, 0.03, 0.04, 0.07]
```

### Observacoes SQS

| Worker | Padrao | Rate medio | Pico |
|--------|--------|-----------|------|
| **monolito-worker** | Constante, com ondas | ~0.4 msg/s | 1.1 msg/s |
| **user-access** | Batches periodicos | ~0.3 msg/s | 2.17 msg/s |
| **ecommerce** | Baixo, spike recente | ~0.01 msg/s | **7.0 msg/s** (15:07!) |

> **Spike ecommerce**: as ~15:07 UTC o ecommerce saltou de 0 para **7 msg/s** durante ~5min, depois caiu para ~0.27 msg/s. Possivel batch de pedidos ou reprocessamento.

---

## Erros nos Workers K8s (Loki, ultimas 2h)

```mermaid
xychart-beta
    title "Erros por worker (count a cada 5min)"
    x-axis ["13:00","13:05","13:15","13:30","13:35","13:55","14:00","14:05","14:15","14:30","14:35","14:45","14:50","15:00","15:05"]
    y-axis "erros" 0 --> 13
    bar "monolito-worker" [3, 3, 12, 6, 3, 6, 6, 3, 0, 3, 0, 0, 0, 0, 0]
    bar "ecommerce" [0, 0, 0, 8, 0, 0, 0, 0, 1, 3, 0, 0, 0, 1, 9]
    bar "user-access" [1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1]
```

### Resumo de erros (2h)

| Worker | Total erros | Padrao |
|--------|-------------|--------|
| **monolito-worker** | 45 | Concentrados 13:00-14:05, depois zerou |
| **ecommerce** | 22 | Dois clusters: 13:30 e 15:05 (correlaciona com spike SQS) |
| **user-access** | 10 | 1 erro/intervalo — ruido de fundo constante |

> O monolito-worker parou de gerar erros na ultima hora. Os erros eram `AuditLogRepository.log: User ID is empty` — consistente, nao critico.

---

## Spike Ecommerce — Correlacao SQS x Erros

```mermaid
xychart-beta
    title "Ecommerce: msg/s vs erros (ultima hora)"
    x-axis ["14:30","14:35","14:40","14:45","14:50","14:55","15:00","15:05","15:10","15:15","15:20","15:25","15:30","15:35","15:40","15:45","15:50"]
    y-axis "valor" 0 --> 8
    line "msg/s (SQS)" [0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 1.17, 7.00, 6.18, 5.86, 5.68, 1.38, 0.26, 0.27, 0.28, 0.24]
    line "erros (x1)" [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]
```

> O spike de 7 msg/s no ecommerce nao gerou muitos erros — processamento saudavel. O cluster de 9 erros as 15:05 veio logo antes do spike, possivelmente mensagens com payload invalido que precederam o batch.

---

## Dashboards Disponiveis

| Dashboard | UID | Datasource | O que monitora |
|-----------|-----|-----------|----------------|
| **ECS Logs** | `cehsqeou8rtvke` | CloudWatch | Panics + erros em 21 servicos ECS |
| **SQS Worker** | `fekhajb8lmg3kc` | Prometheus | Metricas SQS: latencia, rate, WIP |
| **Erros nos Workers** | `bea6645xc1beoa` | Loki | K8s workers: accounts, ecommerce, monolito-worker, pdf-kit |
| **Worker Search** | `be63427ypdloga` | Prometheus | Latencia por flow_key, taxa de sucesso |
| **Kafka Metrics** | `rrE2HgHVz` | Prometheus | Kafka metrics do search-worker |
| **Search** | `be08t0ld8sq9sc` | — | Dashboard principal do search |
| **Falhas em Pods** | `aujpjhs` | K8s | Pod failures geral |

---

## Datasources Verificados

```mermaid
graph TD
    G["Grafana\ngrafana.platform.estrategia.io"]
    G -->|"uid: loki"| L["Loki\n8 apps K8s"]
    G -->|"uid: cloudwatch"| C["CloudWatch\n21 log groups ECS"]
    G -->|"uid: prometheus"| P["Prometheus\n3 SQS jobs"]

    L --- L1["monolito-worker"]
    L --- L2["ecommerce"]
    L --- L3["user-access"]
    L --- L4["accounts"]
    L --- L5["search (debezium)"]
    L --- L6["pdf-kit"]

    C --- C1["/ecs/backend-prod"]
    C --- C2["/ecs/front-student-prod"]
    C --- C3["+ 19 log groups"]

    P --- P1["job=monolito-worker"]
    P --- P2["job=ecommerce"]
    P --- P3["job=user-access"]

    style G fill:#ff6600,stroke:#333,color:#fff
    style L fill:#2d5f8a,stroke:#333,color:#fff
    style C fill:#8a2d5f,stroke:#333,color:#fff
    style P fill:#5f8a2d,stroke:#333,color:#fff
```

---

*Skill `estrategia/grafana` reescrita e verificada — todos os labels, UIDs e queries confirmados via MCP.*
