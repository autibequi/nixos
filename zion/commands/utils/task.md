# Task — Gerenciar tarefas

Sistema de cards em kanban TODO/DOING/DONE em `/workspace/obsidian/tasks/`.

## Entrada
- `$ARGUMENTS`: subcomando + args (texto livre)

## Roteamento

| Input | Ação |
|-------|------|
| *(vazio)* | **Dashboard** — overview completo |
| `list` ou `ls` | Listar cards por pasta |
| `tick` | Mostrar o que rodaria agora (`zion task tick --dry-run`) |
| `run <nome>` | Rodar card específico |
| `new <desc>` ou texto livre | Criar novo card |
| `log` | Últimas execuções (`obsidian/tasks/log.md`) |

---

## Sistema de Cards

### Estrutura
```
obsidian/tasks/
  TODO/    ← agendado: YYYYMMDD_HH_MM_nome.md
  DOING/   ← em execução (locked)
  DONE/    ← concluído/arquivado
  log.md   ← histórico de execuções
```

### Formato do card
```markdown
---
model: haiku          # haiku | sonnet | opus
timeout: 1800         # segundos (default 30min — max_turns controla na prática)
max_turns: 12         # turns claude CLI (default 12; sobrescrito por #stepsN no tick)
mcp: false            # false = desabilita MCP servers
agent: nome           # carrega memory de vault/agents/nome/memory.md
---

Instruções para o agente...

#steps30              ← tag no corpo: controla max_turns no `zion task tick`
```

### Prefixo de data
`YYYYMMDD_HH_MM_nome.md` — define quando o card vence.
O daemon e o `tick` processam cards com data `<= agora + 10min`.

---

## Comandos CLI

### `zion tasks tick`
Roda um tick local. Detecta cards vencidos e executa serialmente.

```bash
zion task tick              # roda tudo que está vencido
zion task tick --dry-run    # só lista, não executa
zion task tick --steps 5    # sobrescreve #stepsN de todos
```

- Lê `#stepsN` do corpo do card como `max_turns` (fallback: **30**)
- Passa `TASK_DIR` e `TASK_MEMORY_DIR` para o runner funcionar fora do container

### `zion tasks run <nome>`
Roda um card específico pelo nome (sem prefixo de data, sem `.md`).

```bash
zion task run scheduler
zion task run scheduler --max-turns 5   # override de turns
zion task run doctor -t 1               # -t é alias de --max-turns
```

### `zion tasks list`
Lista cards em TODO/DOING/DONE com timestamps e status.

### `zion tasks new <nome>`
Cria novo card interativamente com frontmatter preenchido.

---

## task-runner.sh — como funciona

1. Acha o card em TODO/ ou DOING/
2. Cria lock atômico em `/tmp/zion-locks/<nome>.lock`
3. Move para DOING/
4. Checa cota (`claude-ai-usage.sh`) — se ≥70%, reagenda +60min e sai
5. Monta prompt com: instruções do card + memória do agente + contexto
6. Invoca `claude --max-turns N --model M -p PROMPT`
7. Agente pode se reagendar (mover card de volta para TODO/ com nova data)
8. Runner move para DONE/ ao final

### Variáveis de override (env)
| Var | Efeito |
|-----|--------|
| `TASK_MAX_TURNS` | Sobrescreve max_turns do frontmatter |
| `TASK_DIR` | Caminho da pasta tasks (padrão: `/workspace/obsidian/tasks`) |
| `TASK_AGENTS_DIR` | Caminho de vault/agents (padrão: derivado de TASK_DIR) |

---

## Dashboard (sem argumentos)

Ler dados reais e montar overview:

```
╔══════════════════════════════════════════════════╗
║             TASK DASHBOARD                        ║
╠══════════════════════════════════════════════════╣
║ TODO: N  │  DOING: N  │  DONE hoje: N            ║
╠══════════════════════════════════════════════════╣
║ PRÓXIMOS A VENCER                                 ║
║ HH:MM  nome              model   #steps          ║
╠══════════════════════════════════════════════════╣
║ EM ANDAMENTO (DOING/)                             ║
║ nome  (lock age)                                  ║
╠══════════════════════════════════════════════════╣
║ ÚLTIMAS EXECUÇÕES (log.md)                        ║
║ status  nome  model  tempo                        ║
╚══════════════════════════════════════════════════╝
```

Para montar: ler `obsidian/tasks/TODO/*.md` (frontmatter + data prefix), `DOING/*.md`, últimas linhas de `log.md`.

---

## Criar novo card

Fluxo para `new <desc>` ou texto livre:

1. Inferir modelo adequado (haiku para manutenção, sonnet para análise/implementação)
2. Sugerir data de agendamento (próxima janela 21h-06h BRT se não urgente)
3. Gerar arquivo `TODO/YYYYMMDD_HH_MM_nome.md` com frontmatter + instruções
4. Incluir `#stepsN` no corpo se o escopo for claro

### Boas práticas
- Janela preferencial de agentes: **21h-06h BRT** (economiza cota)
- Mínimo 30min no futuro para novas tarefas
- Se nada urgente, agendar mais tarde para conservar quota
- `#steps5-10` para tarefas de manutenção rápida
- `#steps20-30` para implementações
- `mcp: false` para tasks que não precisam de Notion/Jira (mais rápido)
