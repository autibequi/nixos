# Arquitetura Docker — Monolito Estratégia

```mermaid
graph TD
    subgraph HOST["🖥️ Host NixOS"]
        ZionCLI["zion CLI\n~/nixos/zion/cli/zion"]
        ZionCFG["~/.zion\nMONOLITO_DIR · engine · keys"]
        LOGS["~/.local/share/zion/logs/monolito/\nservice.log · startup.log · deps.log"]
    end

    subgraph COMPOSE["Docker Compose — zion-dk-monolito"]
        direction TB

        APP["app container\nzion-dk-monolito-app\n:4004 HTTP  :2345 Delve"]

        subgraph DEPS["deps — zion-dk-monolito-deps"]
            PG["postgres :5432"]
            RD["redis :6379"]
            LS["localstack :4566\nSQS · S3"]
        end
    end

    subgraph IMGS["Dockerfiles"]
        DF["Dockerfile\ngolang:1.24.4-alpine → alpine\nCGO_ENABLED=1 -tags musl\nvendor/"]
        DFD["Dockerfile.debug\ngolang:1.24.4-alpine → golang:1.24.4-alpine\n-gcflags all=-N -l\n/go/bin/dlv exec --headless :2345\n--accept-multiclient --continue"]
    end

    subgraph CURSOR["Cursor / VS Code"]
        LC[".vscode/launch.json\n[DOCKER] Attach to monolito\nrequest=attach mode=remote :2345\nsubstitutePath: workspace→/go/app"]
    end

    ZionCFG --> ZionCLI
    ZionCLI -->|"docker run monolito"| APP
    ZionCLI -->|"--debug overlay"| DFD
    APP --> DF
    APP --> PG & RD & LS
    APP -->|"nohup logs"| LOGS
    CURSOR -->|"DAP attach :2345"| APP
```

---

## Fluxo — modo debug

```mermaid
sequenceDiagram
    actor Dev
    participant CLI as zion CLI
    participant Compose as Docker Compose
    participant App as monolito-app
    participant DLV as Delve :2345
    participant Cursor

    Dev->>CLI: zion docker run monolito --debug
    CLI->>Compose: build Dockerfile.debug
    Note over Compose: golang:alpine runtime<br/>go install dlv → /go/bin/dlv<br/>SYS_PTRACE + apparmor:unconfined
    Compose->>App: up --force-recreate
    App->>DLV: dlv exec ./server --headless --listen=:2345<br/>--api-version=2 --accept-multiclient --continue
    DLV-->>App: processo inicia
    App-->>Dev: http server started on [::]:4004

    Dev->>Cursor: F5 → [DOCKER] Attach to monolito
    Cursor->>DLV: DAP attach 127.0.0.1:2345
    DLV-->>Cursor: Debug Console: "Type dlv help" ✓

    Dev->>App: GET localhost:4004/...
    App-->>DLV: breakpoint hit
    DLV->>Cursor: pausa execução na linha
```

---

## Estrutura de arquivos no repo

```mermaid
graph LR
    ROOT["zion/"]

    ROOT --> CLI["cli/"]
    CLI --> SRC["src/commands/"]
    SRC --> DR["docker_run.sh\n--debug flag\n--no-log-prefix"]
    SRC --> DS["docker_status.sh\nárvore colorida"]
    SRC --> DL["docker_logs.sh"]
    CLI --> LIB["src/lib/docker_services.sh\nzion_docker_log_dir()"]
    CLI --> YML["docker-compose.zion.yml\nlogs mount"]

    ROOT --> DKZ["dockerized/monolito/"]
    DKZ --> DOC["Dockerfile"]
    DKZ --> DOCD["Dockerfile.debug"]
    DKZ --> YMD["docker-compose.debug.yml\nSYS_PTRACE"]
    DKZ --> YMDP["docker-compose.deps.yml"]
    DKZ --> ENVD["env/ sand·local·qa·prod"]
    DKZ --> RDM["README.md"]

    ROOT --> SK["skills/dockerizer/SKILL.md"]
```

---

## Mapeamento de portas e logs

| Container | Porta host | Porta container | Log |
|-----------|-----------|-----------------|-----|
| monolito-app | :4004 | :4004 | service.log |
| monolito-app (debug) | :2345 | :2345 | service.log |
| monolito-postgres | :5432 | :5432 | deps.log |
| monolito-redis | :6379 | :6379 | deps.log |
| monolito-localstack | :4566 | :4566 | deps.log |

**Logs no container (zion edit):** `/workspace/logs/docker/monolito/`
**Logs no host:** `~/.local/share/zion/logs/monolito/`
