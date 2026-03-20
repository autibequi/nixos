# Zion — Glossário

Nomenclatura do sistema. Referência rápida para entender os termos usados em skills, hooks e conversas.

## Agentes e instâncias

| Termo | O que é |
|-------|---------|
| **Zion** | O sistema como um todo — CLI, hooks, skills, agentes, scripts |
| **Eu / Claude externo** | Claude sonnet rodando nesta sessão interativa |
| **Mini-Zion** | Claude haiku spawned por mim — efêmero, usado como maquete de desenvolvimento |
| **Puppy** | Container persistente que roda o task-daemon em background |
| **Agente** | Claude headless rodando uma task card específica (scheduler, doctor, radar...) |

## Workflows

| Termo | Significado |
|-------|------------|
| **Lab** | Modo de iteração: eu + Mini-Zion trabalhando em melhorias do sistema |
| **Instalar módulo** | Pegar o que Mini-Zion desenvolveu e aplicar em mim via `/workspace/mnt/zion/` + git commit |
| **Analysis mode** | `ZION_ANALYSIS_MODE=1` — Mini-Zion em postura experimental, máxima autonomia |
| **Tick** | Um ciclo do task-daemon: escaneia TODO/, roda tasks vencidas |

## Persistência

| O que | Vive onde | Morre quando |
|-------|-----------|--------------|
| Source code (hooks, skills, scripts) | `/workspace/mnt/zion/` + GitHub | nunca (se commitado) |
| Memórias cross-session | `/home/claude/.claude/projects/*/memory/` | volume Docker deletado |
| Tasks / kanban | `/workspace/obsidian/` | vault Obsidian do user |
| O que Mini-Zion cria | filesystem compartilhado | restart do container |
| Contexto desta sessão (RAM) | processo Claude Code | fim da conversa — única coisa que realmente some |

## Paths essenciais

| Path | Conteúdo |
|------|---------|
| `/workspace/mnt/zion/` | fonte da verdade — tudo que sou |
| `/workspace/mnt/zion/hooks/claude-code/session-start.sh` | o que recebo no boot |
| `/workspace/mnt/zion/commands/meta/lab.md` | skill /meta:lab |
| `/workspace/mnt/zion/scripts/task-runner.sh` | executor de tasks |
| `/workspace/mnt/zion/scripts/task-daemon.sh` | daemon de tasks |
| `/workspace/obsidian/tasks/` | kanban TODO/DOING/DONE |
| `/workspace/obsidian/agents/memory/` | memória persistente dos agentes |
