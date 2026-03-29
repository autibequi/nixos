# vennon System — Cursor Agent

> Este arquivo e injetado automaticamente pelo vennon no workdir do cursor-agent.
> Contem as regras e contexto que o Claude Code recebe via hooks.

## Voce

Voce e um agente dentro do sistema vennon. Idioma: PT-BR sempre.

## Estrutura

| Path | O que e |
|------|---------|
| `/workspace/self/` | Engine — skills, ego, superego, commands, scripts |
| `/workspace/obsidian/` | Vault — DASHBOARD, bedrooms, projects, inbox, wiki |
| `/workspace/home/` | Home do host |
| `/workspace/host/` | Repo NixOS (se montado) |

## Skills

Skills vivem em `/workspace/self/skills/`. Cada uma tem SKILL.md com instrucoes.
Tambem disponiveis em `~/.cursor/skills/` (montado automaticamente).

| Skill | Dominio |
|-------|---------|
| `code/*` | Analise, debug, review, tdd, goodpractices |
| `coruja/*` | Estrategia (Go/Vue/Nuxt) |
| `linux/` | NixOS, Hyprland, dotfiles |
| `vennon/` | yaa, deck, containers, worktrees |
| `webview/` | Chrome relay, mermaid, templates HTML |
| `ascii/` | Box-drawing, avatares, design system |
| `humanize/` | Texto natural |
| `obsidian/` | Vault operations |
| `thinking/*` | Raciocinio: lite, investigate, brainstorm |

Para usar uma skill, leia o SKILL.md: `cat /workspace/self/skills/<nome>/SKILL.md`

## Commands

Commands vivem em `/workspace/self/commands/`. Disponiveis em `~/.cursor/rules/`.

| Namespace | Comandos |
|-----------|----------|
| `/self:*` | ego, superego, shadow, skill, context, envs, learn |
| `/meta:*` | phone, tick |
| `/obsidian:*` | project:new, project:rules |
| `/code:*` | analysis, commit, push, review, feature, clean |

## Agentes (Ego)

Definicoes em `/workspace/self/ego/`. Bedrooms em `/workspace/obsidian/bedrooms/`.

| Agente | Funcao |
|--------|--------|
| hermes | Dispatcher central |
| sage | Sabio (explore, organize, propose, document) |
| coruja | Estrategia platform |
| keeper | Saude e limpeza |
| paperboy | Feeds e jornal |
| hefesto | Mestre construtor (default) |
| venture | Business discovery |

## Regras Globais (Superego)

Ler antes de agir: `/workspace/self/superego/`

- `leis.md` — proibicoes e obrigacoes
- `dashboard.md` — como funciona o DASHBOARD
- `ciclo.md` — protocolo de execucao
- `comunicacao.md` — canais oficiais
- `obsidian-rules.md` — territorios do vault

## DASHBOARD

`/workspace/obsidian/DASHBOARD.md` — kanban com cards (TODO/DOING/DONE/WAITING).
Cards com `#ronda` voltam pro TODO apos execucao.

## Regras Essenciais

- **Autocommit OFF** — nunca commitar sem o user pedir
- **Timestamps UTC** — sempre
- **Verificar antes de afirmar** — evidencia antes de claims
- **MCP Jira/Notion** — READ ONLY
