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

## Canal ~/.leech

`~/.leech` e o canal de comunicacao rapida host ↔ agente. Formato `KEY=value`.

| Flag | Default | Significado |
|------|---------|-------------|
| `PERSONALITY` | `ON` | ON=persona ativa, OFF=modo neutro |
| `AUTOCOMMIT` | `OFF` | ON=commita sem perguntar |
| `BETA` | `OFF` | ON=modo observacao |
| `LEECH_DEBUG` | `OFF` | ON=contexto completo no boot |
| `HEADLESS` | `0` | 1=worker autonomo |
| `RELAY_ONLINE` | `false` | Chrome CDP disponivel |
| `MESSAGE` | (vazio) | Mensagem livre pro agente |

## Glossario

| Termo | O que e |
|-------|---------|
| **Vennon** | O sistema como um todo — yaa (launcher), deck (TUI), vennon (orquestrador)
| **yaa** | CLI principal — launcher de sessoes IA |
| **vennon** | Orquestrador de containers Docker |
| **deck** | TUI dashboard do host |
| **~/.leech** | Tokens e env vars (bash-sourceable) |
| **config.yaml** | `~/.config/vennon/config.yaml` — config estruturado |
| **Mini-Agent** | Claude haiku spawned efemero |
| **Worker** | Container persistente em background |
| **Agente** | Claude headless rodando task card |

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
`---BOOT---` (flags) → `---LEECH---` (~/.leech) → `---API_USAGE---` → `---PERSONA---` (se personality=ON)

NAO fazer tool calls para ler esses arquivos — ja estao no contexto injetado.
