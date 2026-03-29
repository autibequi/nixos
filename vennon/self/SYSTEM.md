# Vennon — Sistema

> Referencia unica de ambiente, paths, CLI e terminologia.

---

## Paths

| Path | O que e | Permissao |
|------|---------|-----------|
| `/workspace/self/` | Engine — skills, hooks, agents, scripts | rw |
| `/workspace/obsidian/` | Vault Obsidian — DASHBOARD, bedrooms, tasks, wiki, projects | rw |
| `/workspace/home/` | Home do host ($HOME completo) | rw |
| `/workspace/host/` | Repo NixOS (~/nixos) — inclui vennon source | rw |
| `/workspace/projects/` | Projetos (~/projects) | rw |
| `/workspace/logs/` | Logs (host + docker) | ro |

Working dir resolvido via `cd`. Ex: `yaa ~/projects/app` → `cd /workspace/home/projects/app`.

## CLI (rodam no HOST)

| Comando | O que faz |
|---------|-----------|
| `yaa .` | Nova sessao claude no dir atual |
| `yaa --engine=cursor .` | Sessao com Cursor |
| `yaa shell` | Zsh interativo no container |
| `yaa continue` | Continua ultima sessao |
| `yaa phone <agent>` | Chama um agente |
| `yaa tick` | Roda ciclo de agentes |
| `yaa usage claude` | Mostra quota |
| `vennon list` | Lista containers |
| `vennon <svc> start/stop/logs` | Gerencia servicos (monolito, bo, front) |
| `deck` | TUI dashboard |
| `deck stow` | Deploy dotfiles |
| `deck os switch` | NixOS rebuild |

## Canal ~/.vennon

`~/.vennon` e o canal de comunicacao rapida host ↔ agente. Formato `KEY=value`.

| Flag | Default | Significado |
|------|---------|-------------|
| `PERSONALITY` | `ON` | ON=persona ativa, OFF=modo neutro |
| `AUTOCOMMIT` | `OFF` | ON=commita sem perguntar |
| `BETA` | `OFF` | ON=modo observacao |
| `vennon_DEBUG` | `OFF` | ON=contexto completo no boot |
| `HEADLESS` | `0` | 1=worker autonomo |
| `RELAY_ONLINE` | `false` | Chrome CDP disponivel |
| `MESSAGE` | (vazio) | Mensagem livre pro agente |

## Glossario

| Termo | O que e |
|-------|---------|
| **yaa** | CLI do usuario — lanca sessoes IA (`yaa .`, `yaa --engine=cursor`, `yaa tick`) |
| **vennon** | Orquestrador de containers — gera compose, monta volumes, gerencia imagens |
| **deck** | TUI dashboard — stow, NixOS rebuild, status |
| **self/** | Engine do sistema — skills, ego, superego, shadow, commands, scripts |
| **~/.vennon** | Canal host ↔ container — tokens, env vars, flags (bash-sourceable) |
| **config.yaml** | `~/.config/vennon/config.yaml` — paths, settings, engine default |
| **Agente (ego)** | Entidade inerte — so existe quando Hermes despacha um card |
| **DASHBOARD** | Kanban em obsidian — TODO/DOING/DONE/WAITING, tudo e card |
| **Briefing** | Instrucoes pra um agente — vive em bedrooms/ ou projects/ |
| **#ronda** | Card ciclico — volta pro TODO apos execucao |

## Obsidian Vault (`/workspace/obsidian/`)

| Path | Conteudo |
|------|----------|
| `DASHBOARD.md` | Estado dos agentes (WORKING/DONE/SLEEPING/WAITING) |
| `bedrooms/<agent>/` | Memoria persistente (memory.md, done/) |
| `inbox/` | Agents → user (feed.md, alertas, cartas) |
| `outbox/` | User → agents (hermes processa) |
| `projects/<agent>/` | Workspace soberano por agente |
| `wiki/` | Knowledge base |
| `vault/` | Conhecimento permanente |

## Cota API

- **< 85%:** gastar normalmente
- **>= 85%:** adiar tasks pesadas, preferir haiku
- **>= 95%:** encerrar qualquer worker imediatamente

## Boot via Hook

O hook `session-start.sh` injeta no system-reminder (nesta ordem):
`---BOOT---` (flags) → `---vennon---` (~/.vennon) → `---API_USAGE---` → `---PERSONA---` (se personality=ON)

NAO fazer tool calls para ler esses arquivos — ja estao no contexto injetado.
