# yaa — Session & Agent Orchestrator

Orquestra sessões de desenvolvimento e agentes. Chama `vennon` para container management.

## Sessões

```bash
yaa .                           # nova sessão claude no dir atual
yaa ~/projects/app              # nova sessão em dir específico
yaa --engine=cursor .           # cursor em vez de claude
yaa --engine=opencode .         # opencode
yaa --model=haiku .             # override modelo
yaa --host .                    # monta ~/nixos em /workspace/host
yaa --danger .                  # --dangerously-skip-permissions (claude)
yaa shell                       # zsh interativo no container
yaa continue                    # continua última conversa
yaa resume                      # pick session ID
yaa resume abc123               # resume específico
```

## Agentes

```bash
yaa phone <agent> [message]     # chama agente com timer de ligação
yaa tick                        # = yaa phone ticker "hora de rodar"
```

O `phone` resolve o agent.md em `self/agents/`, parseia frontmatter (model, max_turns), e executa `claude -p` dentro do container com o prompt do agente.

## Tools

```bash
yaa usage [claude|cursor]       # API usage stats
yaa token [claude]              # print OAuth token
yaa holodeck [start|stop|status] # Chrome CDP na porta 9222
yaa tmux [serve|open|run|capture|status] # sessão tmux compartilhada
yaa man                         # documentação completa
yaa init                        # cria ~/.yaa.yaml
yaa update                      # just install (rebuilda tudo)
```

## Config: ~/.yaa.yaml

```yaml
session:
  engine: claude      # default engine
  host: false         # --host por default
  danger: false       # --danger por default

models:
  claude: opus        # modelo default por engine
  opencode: opus
  cursor: ""

paths:
  vennon: ~/nixos/vennon
  obsidian: ~/.ovault/Work
  projects: ~/projects
  host: ~/nixos
```

## Módulos

| Arquivo | O que faz |
|---------|-----------|
| `main.rs` | CLI com subcommands + global flags (--engine, --model, --host, --danger) |
| `config.rs` | ~/.yaa.yaml loading, defaults, model_for_engine() |
| `session.rs` | Resolve engine/model/dir, seta YAA_* env vars, exec vennon |
| `phone.rs` | Parse agent.md frontmatter, timer, exec claude -p no container |
| `usage.rs` | Claude API usage via token |
| `token.rs` | Read ~/.claude/.credentials.json accessToken |
| `holodeck.rs` | Chrome with CDP: start/stop/status (port 9222) |
| `tmux.rs` | Shared tmux via /run/user/1000/yaa-tmux/tmux.sock |
| `man.rs` | GNU-style man page |
| `exec.rs` | run(), capture(), exec_replace() |
