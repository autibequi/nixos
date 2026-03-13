# Tulpa

> **Primeira ação de TODA sessão:** checar se `/workspace/.ephemeral/personality-off` existe.
> Se **NÃO** existe → ler `SOUL.md` (identidade e personalidade) + `SELF.md` (diário pessoal) e aplicar.
> Se existe → pular SOUL.md e SELF.md, operar em modo neutro (sem personalidade).

## Infraestrutura
- Container Docker `claude-nix-sandbox` (Dockerfile.claude + docker-compose.claude.yml)
- Base: `nixos/nix:latest` — host e container são Nix-based
- MCP servers: nixos, Atlassian (READ ONLY), Notion (READ ONLY)
- GitHub CLI (`gh`) autenticado via `GH_TOKEN` (read-only)
- Rodo interativamente (sandbox) e autonomamente (workers fast + heavy)

## Onde estou
- Container: `claude-nix-sandbox` (Dockerfile.claude + docker-compose.claude.yml)
- Workspace: `/workspace` = repo NixOS pessoal do usuário
- Dotfiles: `stow/` → `~/` (via GNU stow)
- Projetos de trabalho: `projetos/` (submódulos montados de fora)
- Todos os repos do user: `/home/claude/projects/` (bind mount RO do `~/projects` do host)

## Estrutura
```
/workspace/
├── CLAUDE.md            ← regras operacionais
├── SOUL.md              ← identidade e personalidade
├── flake.nix            ← config NixOS (flake-based)
├── configuration.nix    ← registro de módulos NixOS
├── modules/             ← módulos NixOS
├── stow/                ← dotfiles + skills Claude
├── projetos/            ← projetos de trabalho (submódulos)
│   └── CLAUDE.md        ← sub-personalidade trabalho
├── scripts/             ← clau-runner.sh, kanban-sync.sh, etc.
├── docs/                ← referências on-demand (obsidian, nixos, task-system)
├── vault/               ← mount point Obsidian
│   ├── _agent/tasks/    ← sistema de tasks (recurring/, pending/, running/, done/, failed/)
│   ├── _agent/reports/  ← relatórios de tasks autônomas
│   ├── artefacts/       ← entregáveis por task
│   ├── sugestoes/       ← canal agente→user
│   ├── kanban.md        ← FONTE DE VERDADE work items (ver regra abaixo)
│   └── scheduled.md     ← tasks recorrentes (board separado)
└── .ephemeral/          ← memória efêmera (gitignored)
```

## Kanban — Regra Inviolável

> O kanban (`vault/kanban.md`) DEVE ser atualizado em TODA sessão com o trabalho atual.
> Não esperar pedido. É responsabilidade do agente.

- **Interativo**: adicionar card em "Em Andamento" com tag `#interativo`
- **Worker**: runner atualiza automaticamente
- **Multi-turn**: manter card atualizado com contexto
- **Concluído**: mover com link pro resultado

O kanban é memória compartilhada entre sessões, mecanismo de orquestração entre agentes, e visibilidade pro user no Obsidian.

## Sistema de Tasks (6 recorrentes)

| Task | Tier | Model | Função |
|------|------|-------|--------|
| processar-inbox | fast | haiku | Processa coluna Inbox do kanban |
| doctor | fast | haiku | Health check |
| vigiar-logs | fast | haiku | Monitora logs |
| radar | heavy | haiku | Jira/Notion |
| avaliar | heavy | sonnet | Repo + projetos + knowledge |
| evolucao | heavy | sonnet | Meta-análise + docs |

Workers: **fast** (a cada 10 min, tasks tier=fast) + **heavy** (hourly, tasks tier=heavy + pending).
Detalhes em `docs/task-system.md`.

## Inbox (coluna do kanban)
User adiciona card na coluna "Inbox" do kanban no Obsidian (texto livre) → worker fast processa a cada 10 min → cria task + card formatado no Backlog.

## Persistência e Versionamento

Três camadas de persistência, da mais permanente à mais efêmera:

| Camada | Local | Versionado (git) | Sobrevive rebuild |
|--------|-------|-------------------|-------------------|
| **Identidade** | `/workspace/SOUL.md` | Sim | Sim |
| **Regras operacionais** | `/workspace/CLAUDE.md` | Sim | Sim |
| **Skills/Commands/Hooks** | `/workspace/stow/.claude/` | Sim | Sim |
| **Settings projeto** | `/workspace/.claude/settings.json` | Sim | Sim |
| **Memórias** | `~/.claude/projects/-workspace/memory/` | Não | Sim (bind mount host) |
| **Transcripts** | `~/.claude/projects/-workspace/*.jsonl` | Não | Sim (bind mount host) |
| **Tool results cache** | `~/.claude/projects/-workspace/*/tool-results/` | Não | Sim (bind mount host) |

**Bind mount chave:** `${HOME}/.local/share/claude-code:/home/claude/.claude` — tudo em `~/.claude/` persiste no host.

### O que vai onde
- **Regras fundamentais** → `CLAUDE.md` (versionado, visível pra todos os agents)
- **Skills de projeto** → `stow/.claude/skills/<projeto>/` (versionado)
- **Commands reutilizáveis** → `stow/.claude/commands/` (versionado)
- **Hooks** → `stow/.claude/hooks/` (versionado)
- **Feedback do user, info pessoal, contexto de projeto** → `memory/` (persistente, não versionado)
- **Trabalho em andamento** → `vault/kanban.md` + `vault/artefacts/` (persistente via vault mount)

### Evolução contínua

**`/contemplate-memories`** — introspecção profunda sobre conversas recentes. Extrai aprendizados para:
- **Memórias** (`memory/`) — feedback, contexto user, projetos, referências
- **Identidade** (`SOUL.md`) — personalidade, papel, diretrizes de comunicação
- **Regras** (`CLAUDE.md`) — regras operacionais novas
- **Habilidades** (`stow/.claude/commands/`, `skills/`) — padrões reutilizáveis
- **Kanban** — limpeza de cards obsoletos/duplicados

Rodar periodicamente ou quando sentir que tem informação útil pra persistir. Toda sessão longa ou com feedback significativo merece contemplação.

## Diretrizes Operacionais
- Priorizar editar código existente sobre criar novo
- MCP Jira/Notion: **READ ONLY** — NUNCA criar/editar/transicionar
- **Configs Claude** — skills, commands, plugins vão em `stow/.claude/`. Settings vão em `.claude/settings.json` (project-level, NUNCA no stow)
- **Agents: default haiku** — escalar pra sonnet/opus só quando claramente necessário
- **NUNCA rodar Claude dentro de Claude** — runner roda via systemd no host
- **Superpoderes Nix** — todo Nixpkgs disponível via `nix-shell -p <pkg>`
- **Ler kanban ANTES de qualquer tarefa** — o kanban tem contexto, links, e estado do trabalho. Nunca refazer algo que já existe

## Observabilidade do Host (read-only)
Bind mounts RO — consultar antes de pedir pro user rodar comandos:
- `/host/journal` → `journalctl --directory=/host/journal -u <service> -n 50`
- `/host/proc/meminfo`, `/host/proc/loadavg`, `/host/proc/uptime`
- `/host/podman.sock` — listar containers
- `/home/claude/projects/` — todos os repos do user

## GitHub (read-only via `gh`)
```sh
gh pr view <n> --repo owner/repo
gh pr diff <n> --repo owner/repo
gh issue view <n> --repo owner/repo
gh api repos/owner/repo/pulls/<n>/comments
```
NUNCA criar/editar/fechar PRs ou issues — token é READ ONLY.

## Startup
- Hook `UserPromptSubmit` roda `/workspace/scripts/startup.sh` automaticamente
- NÃO lançar agents, NÃO processar tasks no interativo

## Vault Obsidian — Segundo Cérebro Compartilhado
O vault é aberto no Obsidian pelo user. Tudo que eu escrevo lá é renderizado visualmente.
Tenho controle total sobre formatação, tags, links internos e backlinks:

- **Tags**: usar `#tag` livremente pra categorizar (ex: `#nixos`, `#bug`, `#ideia`, `#urgente`)
- **Links internos**: `[[nome-da-nota]]` ou `[[pasta/nota|texto exibido]]` — Obsidian resolve automaticamente
- **Backlinks**: Obsidian mostra todas as notas que linkam pra uma nota. Usar links internos generosamente pra criar rede de conhecimento
- **Frontmatter YAML**: obrigatório em sugestões e reports — Dataview query depende disso
- **Formatação**: callouts (`> [!info]`, `> [!warning]`), checklists, tabelas, Mermaid, tudo renderiza
- O vault é nosso segundo cérebro — eu escrevo e organizo, user visualiza e navega

Referência completa de plugins/Dataview/Mermaid/Templater em `docs/obsidian-reference.md`.

## Sugestões
- Formato: `vault/sugestoes/YYYY-MM-DD-<topico>.md`
- Frontmatter obrigatório: `date`, `category`, `reviewed: false`
- User revisa no Obsidian

## Artefatos
- `vault/artefacts/<task>/` — pasta por pedido/task
- `vault/_agent/reports/` — relatórios de tasks autônomas
- Card no kanban DEVE linkar pro artefato ao concluir

## Referências (leitura on-demand)
- `docs/obsidian-reference.md` — Dataview, Mermaid, Templater, plugins
- `docs/nixos-reference.md` — comandos e arquitetura NixOS
- `docs/task-system.md` — detalhes do sistema de tasks, tiers, kanban format
