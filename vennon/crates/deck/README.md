# deck — TUI Dashboard + Host Utilities

TUI interativa para gerenciar containers + atalhos para stow e NixOS.

## TUI (default)

```bash
deck                # abre dashboard
```

**Tabs** (Tab key para alternar):
- **IDE** — claude, opencode, cursor
- **Services** — monolito, bo-container, front-student, reverseproxy (do vennon.yaml)

**Keys:**
- `j/k` ou `↑/↓` — navegar containers
- `Enter` — menu de ações (start, stop, shell, build, flush + comandos do vennon.yaml)
- `Tab` — alternar IDE ↔ Services
- `r` — refresh
- `[/]` — scroll logs
- `q` — sair

**Features:**
- Containers mostram status (up/stopped), CPU%, memória
- `▸` indica seleção atual
- Logs trocam automaticamente ao navegar
- Menu dinâmico: IDEs têm actions padrão, services mostram comandos do vennon.yaml
- Services aparecem mesmo sem container rodando (status "stopped")
- Ações interativas (shell, logs) suspendem TUI e restauram ao voltar

**Travamento / “congelou”**: se **nenhuma** tecla responder (incluindo `q`), o processo estava bloqueado em `podman`/`vennon` — com timeouts por comando isso deixa de ser indefinido. Se a UI reage mas os dados parecem velhos, use `r` (refresh em background). O rodapé mostra `refreshing…` ou `stale (podman/vennon timeout)` quando aplicável.

## Host Utilities

```bash
deck stow [restow|delete|status] [-r]  # GNU stow (-r recarrega hyprland+waybar)
deck os [switch|test|boot|build|update] # NixOS via nh
deck update                             # = yaa update
```

## Módulos

| Arquivo | O que faz |
|---------|-----------|
| `main.rs` | CLI: (default=TUI), stow, os, update |
| `stow.rs` | GNU stow wrapper com reload opcional |
| `os.rs` | NixOS ops via `nh` (switch/test/boot/build/update) |
| `tui/mod.rs` | Terminal setup (crossterm), event loop, key bindings |
| `tui/app.rs` | State (tabs, containers, menu, logs), data collection via podman + vennon list |
| `tui/ui.rs` | Render: header+tabs, container table, logs, footer, popup menu (ratatui) |

## Data Collection

O `deck` coleta dados de duas fontes:
1. **podman ps/stats** — containers running com CPU/mem
2. **vennon list** — services descobertos via vennon.yaml (aparecem mesmo parados)

Menu de ações vem do vennon.yaml do serviço (ou actions padrão para IDEs).
