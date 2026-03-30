---
name: webview/mermaid/template/feature-diagram
description: Diagrama de funcionalidade completo — 3 mega blocos TD (FRONTEND / BACKEND / ASYNC), BACKEND interno LR com sub-caixas TB por camada (Handlers | Services | Repos | JobTracking), nós individuais por método/arquivo, emojis por tipo, cores Catppuccin. Usar quando: diff de branch, PR review, mapeamento de feature cross-repo.
---

# Template — Feature Diagram (mega blocos)

## Quando usar

Usuário pede qualquer um destes:
- "faça um diagrama da funcionalidade"
- "mapeie o diff da branch com a main"
- "mostre como os componentes se conectam"
- "arquitetura dessa feature"

Gerar **exatamente** este padrão. Adaptar nós/labels ao conteúdo real, manter estrutura e estilo.

---

## Estrutura obrigatória

```
flowchart TD                          ← mega blocos empilham TD

  FRONTEND (direction LR)             ← pages e components lado a lado
    └── pages/ (direction TB)
        └── nó por arquivo .vue
    └── components/ (direction TB)
        └── nó por componente relevante
        └── nó por modal de estado

  BACKEND (direction LR)              ← camadas lado a lado horizontalmente
    └── HTTP Handlers (direction TB)  ← nós empilham dentro da caixa
    └── services/ (direction TB)
    └── repositories/ (direction TB)
    └── JobTracking (direction TB)    ← se existir

  ASYNC (direction LR)                ← fila e worker lado a lado
    └── SQS/fila (direction TB)
    └── worker (direction TB)
```

**Regra crítica de layout:**
- `flowchart TD` no topo — mega blocos um abaixo do outro
- Mega blocos FRONT e ASYNC: `direction LR` (sub-caixas lado a lado)
- Mega bloco BACK: `direction LR` — as 4 camadas ficam lado a lado horizontalmente
- Dentro de cada camada: `direction TB` — nós empilham verticalmente
- **Nunca** conectar subgraph→subgraph (`MONO_H --> MONO_SVC`) — isso quebra o layout. Só conexões nó→nó.

---

## Regras de estilo

### Cores dos mega blocos (via `style`)

```
style FRONT fill:#0d1f3a,stroke:#89b4fa,stroke-width:2px,color:#cdd6f4
style BACK  fill:#0a2010,stroke:#a6e3a1,stroke-width:3px,color:#cdd6f4
style ASYNC fill:#1a0d2e,stroke:#cba6f7,stroke-width:2px,color:#cdd6f4
```

### Cores por camada (classDef)

| Camada | classDef | fill | stroke |
|--------|----------|------|--------|
| page Vue | `boPage` | `#1e3a5f` | `#89b4fa` azul |
| component/modal Vue | `boComp` | `#2a1f4e` | `#cba6f7` lilás |
| HTTP handler | `handler` | `#0d4a2a` | `#a6e3a1` verde |
| service Go | `service` | `#3d3200` | `#f9e2af` amarelo |
| repository Go | `repo` | `#3d1a00` | `#fab387` laranja |
| JobTracking | `jt` | `#003a4d` | `#74c7ec` ciano |
| SQS/fila | `sqs` | `#251a35` | `#cba6f7` lilás |
| worker | `worker` | `#3a1a1a` | `#f38ba8` vermelho |

### Emojis por tipo de nó

| Tipo | Emoji |
|------|-------|
| Página Vue | 📄 |
| Componente Vue | 🧩 |
| Modal de estado | 🪟 |
| HTTP Handler POST | ➕ |
| HTTP Handler PUT/PATCH | 🔀 |
| HTTP Handler publish | 📢 |
| Service check/validate | 🔍 |
| Service trigger/dispatch | 🚀 |
| Service goroutine | ⚙️ |
| Service resolver interno | 🔎 |
| Service build/compute | 🌳 |
| Repository novo | 🆕 |
| Repository list/get | 📋 |
| Repository join/relation | 🔗 |
| JobTracking Create | ➕ |
| JobTracking Search | 🔍 |
| SQS producer | 📤 |
| SQS consumer | 📥 |
| Worker handler | ⚡ |
| Worker DLQ | 💀 |

### Labels padrão das setas

| Seta | Label |
|------|-------|
| FE → BE | `"HTTP req"` |
| BE → FE (erro) | `"409 + Jobs[]"` |
| Handler → service (check) | `"① verifica conflito"` |
| Handler → service (trigger) | `"② dispara rebuild"` |
| Goroutine | `"go"` |
| BACK → ASYNC | `"1 msg / <entidade>ID"` |
| Consumer → DLQ | `"falha → DLQ"` |
| Resolve path | `"via <campo>"` |

---

## Template completo (copiar e adaptar)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': {'primaryColor': '#313244', 'primaryTextColor': '#cdd6f4', 'primaryBorderColor': '#585b70', 'lineColor': '#6c7086', 'secondaryColor': '#1e1e2e', 'tertiaryColor': '#181825', 'background': '#1e1e2e', 'mainBkg': '#313244', 'nodeBorder': '#585b70', 'clusterBkg': '#181825', 'clusterBorder': '#45475a', 'titleColor': '#cdd6f4', 'edgeLabelBackground': '#1e1e2e', 'fontFamily': 'JetBrains Mono, monospace'}}}%%

flowchart TD

    subgraph FRONT["🖥️  FRONTEND — bo-container"]
        direction LR

        subgraph BO_PAGES["📂 pages/ldi/"]
            direction TB
            P1["📄 PageA\noperação X"]
            P2["📄 PageB\noperação Y"]
        end

        subgraph BO_COMP["🧩 components/"]
            direction TB
            C1["🧩 ComponentA\ndescrição"]
            M1["🪟 ModalEstado\nprops: isOpen, data[]\n@finished → re-executa\n@close → limpa estado"]
        end

        P1 -->|"renderiza"| C1
        P1 & P2 & C1 -->|"HTTP 409 { data[] }"| M1
    end

    subgraph BACK["⚙️  BACKEND — monolito"]
        direction LR

        subgraph MONO_H["🌐 HTTP Handlers"]
            direction TB
            H1["➕ handler_a.go\nPOST /resource/:id/sub\nin: id, payload\nout: 201 | 409+data"]
            H2["🔀 handler_b.go\nPUT /resource/:id\nin: id, body\nout: 200 | 409+data"]
        end

        subgraph MONO_SVC["🔧 services/domain/"]
            direction TB
            S1["🔍 CheckConflict\nin: ctx, Opts\nout: nil | ErrConflict{Data}"]
            S2["🔎 resolveIDs\n• FieldA → direto\n• FieldB → GetByX\nout: []id"]
            S3["🚀 TriggerAction\nin: ctx, Opts → goroutine\nout: void (async)"]
            S4["⚙️ doAction (goroutine)\n① resolveIDs\n② GetRelatedIDs\n③ JobTracking.Create\n④ Queue.Send × id"]
            S1 --> S2
            S3 -->|"go"| S4
        end

        subgraph MONO_REPO["🗄️  repositories/domain/"]
            direction TB
            R1["🆕 GetRelatedIDsByIDs\nJOIN: table_a → table_b\n→ table_c\nout: []relatedID DISTINCT"]
            R2["📋 GetIDsByRelatedIDs\nin: []relatedID\nout: []id"]
        end

        subgraph JT["📊 JobTracking"]
            direction TB
            JT_C["➕ JobTracking.Create\ntype: DOMAIN_ACTION\nRelatedIDs: []id\nout: Job{ID}"]
            JT_S["🔍 JobTracking.Search\nstatus: running\nrelatedIDs: []id\nout: []Job"]
        end

        %% handlers → services (só nó→nó, nunca subgraph→subgraph)
        H1 & H2 -->|"① verifica conflito"| S1
        H1 & H2 -->|"② dispara ação"| S3

        %% services → repos
        S2 -->|"via FieldB"| R2
        S4 -->|"[]id"| R1

        %% services → jobt
        S1 -->|"busca ativos"| JT_S
        S4 -->|"cria job"| JT_C
    end

    subgraph ASYNC["📬  ASYNC — fila + worker"]
        direction LR

        subgraph QUEUE["📬 Fila — DOMAIN.ActionName"]
            direction TB
            Q_S["📤 Queue.Send\npayload: { entity_id, job_id }"]
            Q_R["📥 Consumer\nDOMAIN.ActionHandlerName"]
            Q_S -->|"enfileira"| Q_R
        end

        subgraph WORKER["👷  worker — handlers/domain/worker.go"]
            direction TB
            W1["⚡ HandleAction\nin: ctx, Message\n→ Service.Execute\nout: error"]
            W2["🌳 Execute\nin: ctx, entityID\n→ processa e persiste\nout: result, error"]
            W3["💀 HandleActionDLQ\n→ registra falha\nout: nil"]
            W1 -->|"entityID"| W2
        end

        Q_R --> W1
        Q_R -->|"falha → DLQ"| W3
    end

    %% conexões entre mega blocos
    P1 & P2 -->|"HTTP req"| H1
    S1 -->|"409 + Data[]"| M1
    S4 -->|"1 msg / entityID"| Q_S

    %% mega bloco backgrounds
    style FRONT fill:#0d1f3a,stroke:#89b4fa,stroke-width:2px,color:#cdd6f4
    style BACK  fill:#0a2010,stroke:#a6e3a1,stroke-width:3px,color:#cdd6f4
    style ASYNC fill:#1a0d2e,stroke:#cba6f7,stroke-width:2px,color:#cdd6f4

    classDef boPage   fill:#1e3a5f,stroke:#89b4fa,color:#cdd6f4
    classDef boComp   fill:#2a1f4e,stroke:#cba6f7,color:#cdd6f4
    classDef handler  fill:#0d4a2a,stroke:#a6e3a1,color:#cdd6f4
    classDef service  fill:#3d3200,stroke:#f9e2af,color:#cdd6f4
    classDef repo     fill:#3d1a00,stroke:#fab387,color:#cdd6f4
    classDef jt       fill:#003a4d,stroke:#74c7ec,color:#cdd6f4
    classDef sqs      fill:#251a35,stroke:#cba6f7,color:#cdd6f4
    classDef worker   fill:#3a1a1a,stroke:#f38ba8,color:#cdd6f4

    class P1,P2 boPage
    class C1,M1 boComp
    class H1,H2 handler
    class S1,S2,S3,S4 service
    class R1,R2 repo
    class JT_C,JT_S jt
    class Q_S,Q_R sqs
    class W1,W2,W3 worker
```

---

## Como gerar a partir de um diff

1. `git diff main...HEAD --stat` → lista arquivos alterados
2. `git diff main...HEAD -- <arquivo>` → mudanças por arquivo
3. Ler arquivos modificados para mapear assinaturas, novos métodos, structs
4. Montar:
   - **FRONT** → arquivos `.vue` em pages/ e components/
   - **BACK Handlers** → arquivos em `handlers/` com rota + in/out
   - **BACK Services** → funções novas/alteradas com assinatura resumida
   - **BACK Repos** → métodos novos com JOINs se relevante
   - **ASYNC** → se houver SQS, worker, fila
5. Aplicar `classDef` e `style` da tabela acima
6. **Nunca** conectar subgraph→subgraph — só nó→nó
7. Subir no relay: `mermaid_live_server.py` + `mermaid-push` + `relay-nav`

## Exemplo real

Ver: `projects/coruja/tarefas/FUK2-11748-toc-builder.md`
