# CLAUDINHO — Infraestrutura

Documentação operacional do sistema NixOS + Docker para rodar o agente Claude.

## Infraestrutura

- Container Docker `claude-nix-sandbox` (`claudinho/Dockerfile.claude` + `claudinho/docker-compose.claude.yml`)
- Base: `nixos/nix:latest` — host e container são Nix-based
- MCP servers: nixos, Atlassian (READ ONLY), Notion (READ ONLY)
- GitHub CLI (`gh`) autenticado via `GH_TOKEN` (read-only)
- Rodo interativamente (sandbox) e autonomamente (workers every10 + every60)

## Onde estou

**Booleano canônico:** `IS_CONTAINER` — setado pelo `bootstrap/modules.sh` e exportado para todos os submodules.

| Valor | Contexto | Fonte de verdade |
|-------|----------|-----------------|
| `IS_CONTAINER=1` | Dentro do container Docker `claude-nix-sandbox` | `CLAUDE_ENV=container` ou `/.dockerenv` |
| `IS_CONTAINER=0` | No host NixOS diretamente | ausência das condições acima |

**Uso em decisões — REGRA:** antes de qualquer comando com efeito no sistema, checar `IS_CONTAINER`:

```bash
if [[ "${IS_CONTAINER:-0}" -eq 1 ]]; then
  # Dentro do container: sem sudo, sem systemctl host, sem nixos-rebuild
  # Pedir pro user rodar no host
else
  # No host: pode rodar nixos-rebuild switch, systemctl, etc.
fi
```

- **Mounts sob /workspace:** repo NixOS = `/workspace/nixos`; opcionalmente `/workspace/host` é symlink para `/workspace/nixos` (compat). Posso editar os arquivos; `nixos-rebuild switch` precisa ser rodado pelo user no host.
- `host.docker.internal` = IP do host a partir do container

## Projeto Montado (/workspace/mnt)

- Quando o user roda `claudio` de um diretório de projeto, esse diretório é montado em `/workspace/mnt`
- Verificar `$CLAUDIO_MOUNT` para saber o path original no host
- Se `/workspace/mnt` não existe ou está vazio → modo meta (trabalhando em `/workspace/nixos`)
- Se existe → o foco é no projeto montado

## Estrutura

```
/workspace/                      ← volume do container (dados persistentes)
├── nixos/                       ← bind mount do repo NixOS (~/nixos no host)
│   ├── CLAUDE.md                ← regras operacionais
│   ├── claudinho/               ← comportamento do agente (personas, prompts, tasks)
│   │   ├── CLAUDE.md            ← comportamento do agente
│   │   ├── SOUL.md              ← identidade e personalidade
│   │   ├── DIRETRIZES.md        ← diretrizes do agente
│   │   └── personas/            ← personas disponíveis
│   ├── flake.nix                ← config NixOS (flake-based)
│   ├── modules/                 ← módulos NixOS
│   ├── stow/                    ← dotfiles + skills Claude
│   ├── scripts/                 ← clau-runner.sh, kanban-sync.sh, etc.
│   └── projetos/                ← projetos de trabalho (submódulos)
├── obsidian/                    ← vault Obsidian (Docker mount) — interface e cérebro
│   ├── _agent/                  ← controle interno dos agentes
│   ├── artefacts/               ← entregáveis por task
│   ├── sugestoes/               ← canal agente→user
│   └── kanban.md                ← THINKINGS
├── logs/host/                   ← logs RO do host
├── mnt/                         ← projeto que o user passou (CLAUDIO_MOUNT); cwd do agente
├── .ephemeral/                  ← memória efêmera (gitignored)
└── .hive-mind/                  ← canal efêmero compartilhado entre containers
```

## Comportamento do Agente

Ver `claudinho/CLAUDE.md` para:
- Boot, avatares, personas, saudações
- Sistema de tasks (14 recorrentes)
- Flags efêmeras (auto-commit, auto-jarvis, personality-off)
- Cota API e controle de créditos
- Diretrizes operacionais
- THINKINGS e regras de atualização

## Startup

- Hook `UserPromptSubmit` roda `/workspace/scripts/bootstrap.sh` automaticamente
- NÃO lançar agents, NÃO processar tasks no interativo

## Referências

- `claudinho/CLAUDE.md` — comportamento completo do agente
- `/workspace/obsidian/docs/operational-reference.md` — git identity, hive-mind, persistência
- `/workspace/obsidian/docs/task-system.md` — detalhes do sistema de tasks
- `/workspace/obsidian/docs/nixos-reference.md` — comandos e arquitetura NixOS
