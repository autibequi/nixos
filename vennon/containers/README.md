# containers/ — Dockerfiles e Configs

## Hierarquia de Imagens

```
vennon-vennon (base, arquivo vennon.container)
├── vennon-claude     (+ claude-code via nix)
├── vennon-opencode   (+ opencode via nix)
└── vennon-cursor     (+ cursor CLI via stage Debian / glibc)
```

## vennon/ — Base Image (`vennon-vennon`)

Contexto de build usado por `vennon <ide> build` e `just images`:

```
vennon/
├── vennon.container  # Nix (nixos/nix:latest) + ferramentas; tag `vennon-vennon`
└── entrypoint.sh     # nix-daemon, dynamic UID/GID, session hooks, setpriv
```

**Pacotes instalados (3 layers para cache):**
- Layer 1 (core): coreutils, sed, awk, jq, util-linux, gosu, docker-client, gh, curl
- Layer 2 (extras): python3, wl-clipboard, sox, systemd, espeak-ng, yt-dlp
- Layer 3 (shell): zsh, powerlevel10k, autosuggestions, syntax-highlighting, fzf, eza, bat, ripgrep, fd

**Entrypoint features:**
- `VENNON_UID`/`VENNON_GID` env vars para UID/GID dinâmico (evita root ownership)
- nix-daemon em background
- Source `~/.vennon` (canal host ↔ container)
- Session-start hook execution
- `setpriv` para drop de privilégios

## claude/ — Claude Code

```
claude/
├── Dockerfile      # FROM vennon-vennon + nix install claude-code-nix
└── vennon.yaml     # type: ide, image: vennon-claude
```

## opencode/ — OpenCode

```
opencode/
├── Dockerfile      # FROM vennon-vennon + nix install opencode
└── vennon.yaml     # type: ide, image: vennon-opencode
```

## cursor/ — Cursor

```
cursor/
├── Dockerfile      # FROM vennon-vennon + stage Debian com cursor-agent + libs glibc
└── vennon.yaml     # type: ide, image: vennon-cursor
```

## Build

```bash
vennon claude build   # rebuilda vennon (base) + claude
vennon opencode build # rebuilda vennon (base) + opencode
vennon cursor build   # rebuilda vennon (base) + cursor
```

A base é sempre rebuildada (podman layer cache cuida de pular unchanged steps).

## Serviços (no stow)

Serviços ficam em `stow/.config/vennon/containers/` (symlinked para `~/.config/vennon/containers/`):

```
monolito/       — Go backend (14.4 CPUs, postgres/redis/localstack deps)
bo-container/   — Vue/Quasar admin (Node 14, port 9090)
front-student/  — Nuxt student frontend (Node 20, port 3005)
reverseproxy/   — nginx SSL proxy (host network)
```

Cada um tem `vennon.yaml` com comandos (serve, stop, logs, shell, install, build, flush, etc).
