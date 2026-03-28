# Vennon — Guia para Claude Code

## O que é

Workspace Rust com 3 crates: `vennon` (containers), `yaa` (sessões/agentes), `deck` (TUI/host). Substitui o antigo `leech`. Usa **podman** e **podman-compose** (não docker).

## Estrutura do código

```
crates/vennon/src/
├── main.rs           CLI: init, update, list, <container> [action]
├── config.rs         ~/.config/vennon/config.yaml, path resolution, git_env(), user_ids()
├── manifest.rs       Parser vennon.yaml, discovery (repo + stow), template rendering {{ var | map }}
├── container.rs      IDE ops: start/stop/flush/shell/build (podman-compose + exec)
├── service.rs        Service ops: dispatch compose/exec/script from manifest
├── compose.rs        Compose YAML gen via serde_yaml, write-if-changed
├── exec.rs           run(), capture(), exec_replace(), clear_screen()
└── containers/
    ├── mod.rs        is_ide(), get_compose(), start_cmd(), shell_cmd(), container_workdir()
    └── ide.rs        Compose generation for IDE containers (volumes, env, docker-proxy)

crates/yaa/src/
├── main.rs           CLI: [dir], shell, continue, resume, phone, tick, usage, token, man, holodeck, tmux
├── config.rs         ~/.yaa.yaml loading, path expansion, model_for_engine()
├── session.rs        Launch session: resolve engine/model/host/danger, set YAA_* env vars, exec vennon
├── phone.rs          Call agent: parse frontmatter, timer, exec claude -p inside container
├── usage.rs          Claude usage via API token
├── token.rs          Print OAuth token from ~/.claude/.credentials.json
├── man.rs            Full man page
├── holodeck.rs       Chrome CDP: start/stop/status on port 9222
├── tmux.rs           Shared tmux: serve/open/run/capture/status via socket
└── exec.rs           run(), capture(), exec_replace()

crates/deck/src/
├── main.rs           CLI: (default=TUI), stow, os, update
├── stow.rs           GNU stow: restow/delete/status + optional hyprland reload
├── os.rs             NixOS via nh: switch/test/boot/build/update
├── exec.rs           run(), exec_replace()
└── tui/
    ├── mod.rs        Terminal setup, event loop (crossterm), key bindings
    ├── app.rs        State: tabs (IDE/Services), containers, menu, logs, collect_all()
    └── ui.rs         Render: header+tabs, container table, logs panel, action menu (ratatui)
```

## Padrões importantes

### Compose estável
O compose do IDE é gerado uma única vez e NÃO muda entre sessões. Todos os paths vêm do config (não de env vars de sessão). Isso evita recriação do container quando o usuário abre outra pasta.

### Target dir via cd (não mount)
`~/` é montado em `/workspace/home`. O target dir é resolvido no exec: `cd /workspace/home/projects/app`. Isso permite múltiplas sessões no mesmo container.

### YAA_* env vars
yaa passa configuração ao vennon via env vars herdadas pelo exec:
- `YAA_TARGET_DIR` — dir do host (para calcular workdir no container)
- `YAA_MODEL` — modelo (injetado no `claude --model`)
- `YAA_DANGER` — "1" para --dangerously-skip-permissions
- `YAA_RESUME` — session ID ou "continue"

### vennon.yaml discovery
O manifest.rs scana 2 locais:
1. `{vennon_path}/containers/*/vennon.yaml` (IDEs no repo)
2. `~/.config/vennon/containers/*/vennon.yaml` (services do stow)

### Template rendering
`{{ var }}` substitui pelo valor do arg. `{{ var | map }}` aplica o mapeamento do enum (ex: `sand` → `sandbox`).

### Entrypoint dinâmico
`containers/leech/entrypoint.sh` lê `VENNON_UID`/`VENNON_GID` env vars para ajustar user no container (evita root ownership).

## Convenções

- Container names: `vennon-claude`, `vennon-opencode`, `vennon-cursor`, `vennon-docker-proxy`
- Service names: `vennon-dk-monolito-app`, `vennon-dk-bo-container-app`, etc
- Project names: `vennon-claude`, `vennon-dk-monolito`
- Network: `nixos_default` (external)
- Docker proxy: nginx em 127.0.0.1:2375 filtrando socket access

## Ao modificar

- **Novo IDE**: criar `containers/<name>/Dockerfile` (FROM vennon-leech) + `vennon.yaml`
- **Novo serviço**: criar em `stow/.config/vennon/containers/<name>/` com vennon.yaml + docker-compose.yml
- **Novo comando yaa**: adicionar subcommand em `crates/yaa/src/main.rs` + módulo
- **Novo comando deck**: adicionar subcommand em `crates/deck/src/main.rs` + módulo
- **Build**: `just install` (compila + instala 3 binários)
- **Teste rápido**: `cargo build --release -p <crate>` (compila só 1)
