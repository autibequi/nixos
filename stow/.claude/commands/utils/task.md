# Task — Gerenciar tarefas

Sistema completo de gerenciamento de tasks. Dashboard, listagem, filtros e criação.

## Entrada
- `$ARGUMENTS`: subcomando + args (texto livre)

## Roteamento

Interpretar `$ARGUMENTS` e rotear:

| Input | Ação |
|-------|------|
| *(vazio)* | **Dashboard** — overview completo |
| `list` ou `ls` | **Listar** — todas as tasks por status |
| `list <filtro>` | **Filtrar** — por tipo, tag, status, modelo |
| `pending` | Listar só pending |
| `done` | Listar só concluídas |
| `failed` | Listar só falhas |
| `running` | Listar tasks em execução agora |
| `recurring` ou `rec` | Listar recorrentes com último status |
| `stats` | Estatísticas (contagens, taxa sucesso) |
| `create <desc>` ou `new <desc>` | **Criar** nova task (fluxo de criação) |
| `<qualquer texto livre>` | Assume **criar** com esse texto como descrição |

---

## Dashboard (sem argumentos)

Ler dados de TODAS as pastas de tasks e montar infográfico:

```
╔═══════════════════════════════════════════════╗
║              TASK DASHBOARD                    ║
╠═══════════════════════════════════════════════╣
║ Pending: N  │ Running: N  │ Done: N │ Failed: N
╠═══════════════════════════════════════════════╣
║ RECORRENTES          último run    status     ║
║ processar-inbox      HH:MM         ok/fail    ║
║ doctor               HH:MM         ok/fail    ║
║ ...                                           ║
╠═══════════════════════════════════════════════╣
║ PENDING                                       ║
║ slug              tipo     clock    model     ║
║ ...                                           ║
╠═══════════════════════════════════════════════╣
║ EM ANDAMENTO (kanban)                         ║
║ card1, card2, ...                             ║
╚═══════════════════════════════════════════════╝
```

### Como montar o dashboard:
1. Contar arquivos em cada pasta: `vault/_agent/tasks/{pending,running,done,failed}/`
2. Para recorrentes: ler `vault/_agent/tasks/recurring/*/memoria.md` — extrair último ciclo e status
3. Para pending: ler frontmatter de cada `CLAUDE.md` — extrair tipo, clock, model
4. Para em andamento: ler coluna "Em Andamento" do `vault/kanban.md`
5. Apresentar como infográfico formatado (tabelas, indicadores)

---

## Listar / Filtrar

### `list` — Listar tudo
Mostrar tabela com TODAS as tasks organizadas por status:

```
STATUS   │ SLUG                    │ TIPO      │ CLOCK   │ MODEL
─────────┼─────────────────────────┼───────────┼─────────┼────────
pending  │ pesquisar-agentes       │ pesquisa  │ every60 │ sonnet
done     │ pesquisar-subcontainer  │ pesquisa  │ every60 │ sonnet
...
```

### `list <filtro>` — Filtrar
Aceitar filtros por:
- **Tipo**: `list pesquisa`, `list fix`, `list review`
- **Tag**: `list #trabalho`, `list #worktree`
- **Status**: `list pending`, `list done`, `list failed`
- **Modelo**: `list sonnet`, `list haiku`
- **Clock**: `list every10`, `list every60`

Buscar o filtro no frontmatter de cada task e na coluna do kanban.

### `pending`, `done`, `failed`, `running` — Atalhos
Equivalente a `list <status>` — mostra só tasks daquele status.

### `recurring` / `rec` — Recorrentes
Tabela especial para tasks recorrentes:

```
TASK              │ CLOCK   │ MODEL  │ ÚLTIMO CICLO  │ STATUS │ NOTAS
──────────────────┼─────────┼────────┼───────────────┼────────┼──────
processar-inbox   │ every10 │ haiku  │ 22:40Z        │ ok     │ 0 items
doctor            │ every10 │ haiku  │ 22:40Z        │ ok     │ tudo saudável
...
```

Dados vêm de:
- `vault/_agent/tasks/recurring/<task>/CLAUDE.md` → frontmatter (clock, model)
- `vault/_agent/tasks/recurring/<task>/memoria.md` → último ciclo, status
- `.ephemeral/notes/<task>/historico.log` → última linha

### `stats` — Estatísticas
```
Total: N tasks
  Pending: N  │  Done: N  │  Failed: N  │  Recurring: N

Taxa de sucesso: N% (done / (done + failed))

Por tipo:
  pesquisa: N  │  fix: N  │  projeto: N  │  ...

Por modelo:
  haiku: N  │  sonnet: N  │  opus: N
```

---

## Criar (fluxo original)

Ativado por `create <desc>`, `new <desc>`, ou texto livre que não casa com nenhum subcomando.

### Fluxo:

1. **Classificar a task** usando AskUserQuestion com as opções:

   **Tipo:**
   | Tipo | Descrição | Modelo default |
   |------|-----------|----------------|
   | `pesquisa` | Investigar, comparar, gerar relatório | sonnet |
   | `projeto` | Implementar algo novo (feature, script, config) | sonnet |
   | `fix` | Corrigir bug ou problema identificado | haiku |
   | `limpeza` | Remover, simplificar, organizar | haiku |
   | `docs` | Documentação, tutorial, guia | haiku |
   | `review` | Analisar código, PR, arquitetura | sonnet |

   **Flags opcionais (multiSelect):**
   - `worktrees: true` (pode criar worktrees), `#mcp` (precisa de MCP servers), `#trabalho` (projeto Estratégia)

   **Clock:**
   - `every10` — rápida, simples (<2min)
   - `every60` — complexa, precisa pensar (até 10min)

2. **Gerar slug**: lowercase, hifens, sem acentos, max 40 chars.

3. **Criar arquivo** `vault/_agent/tasks/pending/<slug>/CLAUDE.md`:
```markdown
---
title: <slug>
clock: <every10|every60>
model: <haiku|sonnet>
type: <pesquisa|projeto|fix|limpeza|docs|review>
priority: <low|medium|high>
created: <YYYY-MM-DDTHH:MM:SSZ>
tags: [<tipo>, <flags extras>]
---

# <slug>

<descrição expandida>

## Contexto
(extrair do que o user falou)

## Ação
(passos concretos)
```

4. **Adicionar card no THINKINGS** (`vault/kanban.md`) na coluna Backlog:
   ```
   - [ ] **<slug>** — <descrição curta> `#<tipo>` `#<clock>` <flags>
   ```

5. **Confirmar**:
   ```
   Task criada: <slug>
   Tipo: <tipo> | Clock: <clock> | Model: <modelo>
   Flags: <flags ou nenhuma>
   ```

## Regras Gerais
- Slug deve ser único — checar se já existe em pending/
- Descrição no card do kanban: max 80 chars
- Se o user mencionar prioridade (urgente, importante), setar `priority: high`
- Se o tipo for `pesquisa`, incluir na Ação: "Gerar relatório em vault/artefacts/<slug>/"
- Se tiver `worktrees: true`, incluir no frontmatter e na Ação: "Criar worktree com implementação"
- Não inventar contexto — se o user foi vago, perguntar
- Model pode ser overridden pelo user (ex: "usa opus pra isso")
- Dashboard e listagens devem ser apresentados como **infográfico** (tabelas formatadas, indicadores visuais)
- Usar dados reais do filesystem — nunca inventar contagens
