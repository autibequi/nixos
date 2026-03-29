# Vennon — Container Orchestration Platform

Workspace Rust com 3 binários para orquestração de containers de desenvolvimento:

| Binário | Responsabilidade | Config |
|---------|-----------------|--------|
| **vennon** | Container management (podman) | `containers/*/vennon.yaml` |
| **yaa** | Sessões, agentes, utilities | `~/.yaa.yaml` |
| **deck** | TUI dashboard + host ops | — |

## Quick Start

```bash
just install                    # instala vennon + yaa + deck em ~/.local/bin

yaa init                        # cria ~/.yaa.yaml com defaults
yaa .                           # abre claude no diretório atual
yaa --engine=cursor ~/projects  # abre cursor no ~/projects
yaa continue                    # continua última sessão
yaa shell                       # zsh no container

deck                            # TUI dashboard
deck stow                      # deploy dotfiles
deck os switch                 # nixos rebuild

vennon list                    # lista containers disponíveis
vennon monolito serve --env=sand
vennon claude build            # rebuilda imagem
```

## Arquitetura

```
vennon/
├── Cargo.toml                 # workspace
├── justfile                   # build + install (nix-shell)
├── self/                      # engine (skills, hooks, agents, scripts)
├── containers/                # Dockerfiles + vennon.yaml (IDEs)
│   ├── vennon/                 # base image (nix + tools)
│   ├── claude/                # FROM vennon + claude-code
│   ├── opencode/              # FROM vennon + opencode
│   └── cursor/                # FROM vennon + cursor
├── crates/
│   ├── vennon/                # container management
│   ├── yaa/                   # session + agent orchestrator
│   └── deck/                  # TUI + host utilities
└── stow/.config/vennon/containers/  # service containers (monolito, bo, front, proxy)
```

## Hierarquia de Imagens Docker

```
vennon-vennon:latest              ← base: nixos/nix + tools + zsh + entrypoint
  ├─ vennon-claude:latest        ← + claude-code
  ├─ vennon-opencode:latest      ← + opencode
  └─ vennon-cursor:latest        ← + cursor (já na base)
```

Todas as imagens usam **podman** (não docker).

## Volumes Montados (IDE containers)

| Host | Container | Sempre |
|------|-----------|--------|
| `~/` | `/workspace/home` | sim |
| `~/projects` | `/workspace/projects` | sim |
| `~/nixos` | `/workspace/host` | sim |
| `{vennon}/self` | `/workspace/self` | sim |
| `{obsidian}` | `/workspace/obsidian` | sim |
| `~/.claude` | `/home/claude/.claude` | sim |

O diretório target é resolvido via `cd` no exec (não via volume mount) — isso permite múltiplas sessões no mesmo container sem recriação.

## Fluxo: yaa → vennon → container

```
yaa ~/projects/app --engine=claude --model=haiku
  │
  ├─ Lê ~/.yaa.yaml (engine, model, paths, tokens)
  ├─ Resolve: engine=claude, model=haiku, target=~/projects/app
  ├─ Seta env vars: YAA_TARGET_DIR, YAA_MODEL, YAA_DANGER, etc
  └─ exec_replace("vennon", ["claude", "start"])
       │
       ├─ Gera docker-compose.yml (estável, não muda entre sessões)
       ├─ podman-compose up -d (skip se já running)
       ├─ Encontra container ID
       └─ podman exec -it <cid> "cd /workspace/home/projects/app && exec claude --enable-auto-mode --model haiku"
```

## Configuração

### ~/.yaa.yaml

```yaml
session:
  engine: claude        # default: claude | opencode | cursor
  host: false           # mount ~/nixos at /workspace/host
  danger: false         # --dangerously-skip-permissions

models:
  claude: opus          # modelo default por engine
  opencode: opus
  cursor: ""

agents:
  model: haiku
  steps: 30

paths:
  vennon: ~/nixos/vennon
  obsidian: ~/.ovault/Work
  projects: ~/projects
  host: ~/nixos

tokens:
  gh_token: ""
  anthropic_api_key: ""
  npm_token: ""
```

### containers/*/vennon.yaml

Cada serviço define seus comandos, enums e scripts:

```yaml
name: monolito
aliases: [mono]
source: ~/projects/estrategia/monolito

enums:
  env:
    values: [local, sand, devbox, qa, prod]
    default: local
    map:
      sand: sandbox

commands:
  serve:
    args:
      - name: env
        enum: env
    compose:
      files: [docker-compose.yml, docker-compose.deps.yml]
      env_file: "env/{{ env | map }}.env"
      action: up -d
  stop:
    compose:
      action: down
```

## Build

Requer nix-shell com rustc + cargo:

```bash
just build      # cargo build --release
just install    # build + install 3 binários
just clean      # cargo clean
```
