# CONTAINER_INIT

> Contexto de execução do container `claude-nix-sandbox`.
> Fonte de verdade: `docker-compose.claude.yml` — seção `x-base-volumes`.

## Recorrência (scheduler)

A agenda de reexecução não usa mais systemd timer no host. Um **único container** (`scheduler`) fica de pé 24/7; dentro dele um loop executa `clau-scheduler.sh` a cada 10 min (tick + runner in-process). No host: `systemctl start claude-scheduler-container` sobe o container; `systemctl stop claude-scheduler-container` derruba. Reset de tasks presas: `systemctl start claude-scheduler-reset`. Logs do tick: no host em `PROJECT_DIR/.ephemeral/logs/scheduler.log` (ex.: `~/nixos/.ephemeral/logs/scheduler.log`) ou `docker compose logs -f scheduler`.

## Você está dentro de um container Docker

Base: `nixos/nix:latest`. Workspace em `/workspace/` (volume Docker persistente).
Identidade: `CLAUDE_ENV=container` (env var setada no compose).

---

## Mounts — Mapa Completo

### `/workspace/host`
```
${HOME}/nixos → /workspace/host   (RW)
```
Repo NixOS pessoal do usuário. Bind mount read-write.
Contém: `flake.nix`, `modules/`, `stow/`, `scripts/`, `projetos/`, este arquivo.
Editar aqui reflete imediatamente no host. `nixos-rebuild switch` precisa ser rodado pelo user.

---

### `/workspace/mount`
```
${CLAUDIO_MOUNT:-${HOME}/projects} → /workspace/mount   (${CLAUDIO_MOUNT_OPTS:-ro})
```
Projeto externo montado via comando `claudio`. **Read-only por padrão** (RO), a menos que `CLAUDIO_MOUNT_OPTS=rw` seja setado.
- Se `$CLAUDIO_MOUNT` está setado → é um projeto específico, montado de onde o user rodou `claudio`
- Se não está setado → fallback para `${HOME}/projects` (diretório de projetos do user), read-only
- Se vazio ou inexistente → modo meta (trabalha em `/workspace/host`)

> **Atenção:** modo RO significa que edições diretas em `/workspace/mount` vão falhar silenciosamente ou com erro de permissão. Verificar `$CLAUDIO_MOUNT_OPTS` antes de tentar escrever.

---

### `/workspace/obsidian`
```
${OBSIDIAN_PATH:-/tmp} → /workspace/obsidian   (RW)
```
Vault Obsidian do usuário. Scripts usam `/workspace/obsidian/` diretamente.
- Se `$OBSIDIAN_PATH` não está setado → fallback para `/tmp` (Obsidian não configurado!)
- Verificar se o Obsidian está configurado antes de escrever notas

Estrutura interna relevante:
```
obsidian/
├── kanban.md              ← THINKINGS (fonte de verdade de work items)
├── _agent/
│   ├── tasks/             ← ciclo de vida de tasks
│   ├── reports/           ← relatórios de execução
│   ├── sessao.md          ← diário de sessão
│   └── insights.md        ← insights dos agentes
├── artefacts/             ← entregáveis por task
└── sugestoes/             ← canal agente→user
```

---

## Mounts Auxiliares

| Path no container | Fonte no host | Modo | Descrição |
|-------------------|--------------|------|-----------|
| `/home/claude/.claude` | `${HOME}/.claude` | RW | Memórias, transcripts, settings Claude Code |
| `/home/claude/.claude.json` | `${HOME}/.claude.json` | RW | Config global Claude Code |
| `/home/claude/projects` | `${HOME}/projects` | RW | Todos os repos GitHub do user |
| `/workspace/logs/journalctl` | `/var/log/journal` | RO | Logs systemd do host |
| `/workspace/.hive-mind` | `/tmp/claudio-hive-mind` | RW | Canal efêmero entre containers |
| `/host/proc/meminfo` | `/proc/meminfo` | RO | Memória do host |
| `/host/proc/loadavg` | `/proc/loadavg` | RO | Load average do host |
| `/host/proc/uptime` | `/proc/uptime` | RO | Uptime do host |

> Logs: usar `journalctl --directory=/workspace/logs/journalctl -u <service> -n 50`

---

## Decisão rápida

```
Editar config NixOS / dotfiles?      → /workspace/host/
Trabalhar no projeto montado?        → /workspace/mount/  (checar se RW!)
Registrar tarefa / nota / insight?   → /workspace/obsidian/
Ver logs do host?                    → /workspace/logs/journalctl/
Coordenar com outros workers?        → /workspace/.hive-mind/
Repos do user?                       → /home/claude/projects/
```
