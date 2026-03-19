# Skill: Obsidian

> Gestão do vault Obsidian em `/workspace/obsidian/` — tasks, dashboards, Dataview e plugins.

---

## Estrutura do Vault

```
/workspace/obsidian/
├── CONTROL.md          ← Dashboard central (Dataview + Admonitions)
├── MURAL.md            ← Canal de comunicação entre agentes
├── TAMAGOCHI.md        ← Estado do bichinho (atualizado pelo worker tamagochi)
├── PRs.md              ← PRs abertos
├── agents/             ← Memória e contexto dos agentes
├── artefatos/          ← Outputs de tasks (reports, análises)
├── tasks/              ← Sistema de tasks do Puppy
│   ├── inbox/          ← inbox.md — sugestões brutas do usuário (1 arquivo, 1 linha por item)
│   ├── backlog/        ← tasks prontas, cada uma numa pasta com CLAUDE.md
│   ├── doing/          ← tasks em execução, pasta com TASK.md + memoria.md
│   ├── done/           ← tasks concluídas
│   ├── _scheduled/     ← workers recorrentes (clock: every10, every60, etc.)
│   ├── _waiting/       ← tasks aguardando review humano
│   ├── blocked/        ← tasks bloqueadas por dependência
│   └── cancelled/      ← tasks canceladas
├── trash/              ← arquivos deletados (reversível)
└── vault/              ← notas pessoais e wiki
```

---

## Sistema de Tasks

### Formato de task (CLAUDE.md ou TASK.md)

```markdown
---
title: nome-da-task
clock: once | every10 | every60 | every240
model: haiku | sonnet | opus
type: pesquisa | implementacao | config | infra
priority: low | medium | high
created: 2026-03-19T00:00:00Z
tags: [tag1, tag2]
timeout: 120         # segundos (workers)
max_turns: 8         # (workers)
---

# nome-da-task

Descrição clara do objetivo.

## Contexto

Por que essa task existe.

## Ação

1. Passo 1
2. Passo 2
```

### Ciclo de vida

```
inbox/ → backlog/ → doing/ → _waiting/ → done/
                           ↓
                        blocked/
```

### Regras do inbox

- **Um único arquivo** `tasks/inbox/inbox.md` com todos os itens do usuário
- Uma linha por sugestão (condensar itens multi-linha em linha única)
- **Não criar múltiplos arquivos** no inbox — evita fragmentação
- Formato: `- <texto original do usuário preservado>`

---

## CONTROL.md — Dashboard

O CONTROL.md na raiz do vault é o dashboard central. Usa:

1. **DataviewJS** no topo para stats ao vivo (contagem por pasta + barras de progresso)
2. **Callouts colapsáveis** (`[!tipo]-`) para seções grandes (Backlog, Done, Inbox)
3. **Callouts expandidos** (`[!tipo]+`) para seções ativas (Em Andamento, Review)
4. **DataviewJS** no rodapé para mapa de calor de tags do backlog

### Padrão de query Dataview para tasks em pastas

O problema clássico: Dataview mostra "TASK" ou "CLAUDE" como nome de arquivo em vez do nome real da task.

**Solução — usar `file.folder` com regex:**

```dataview
TABLE WITHOUT ID
  "[[" + file.folder + "|" + regexreplace(file.folder, ".*/", "") + "]]" as "Task",
  model as "🤖"
FROM "tasks/doing"
WHERE file.name = "TASK" OR file.name = "CLAUDE"
SORT file.mtime DESC
```

- `file.folder` → path completo da pasta (ex: `tasks/doing/tamagochi`)
- `regexreplace(file.folder, ".*/", "")` → extrai só o último segmento (`tamagochi`)
- `"[[ | ]]"` → cria link clicável com nome legível

### DataviewJS para stats ao vivo

```javascript
const doing = dv.pages('"tasks/doing"')
  .where(p => ["TASK","CLAUDE"].includes(p.file.name)).length

const bar = (n, max, len=10) => {
  const filled = Math.round((n/max)*len)
  return "█".repeat(filled) + "░".repeat(len - filled)
}

dv.paragraph(`| Métrica | Qt | Barra |
|---------|:--:|-------|
| ⚡ Rodando | ${doing} | \`${bar(doing, 5)}\` |`)
```

### DataviewJS para mapa de calor de tags

```javascript
const pages = dv.pages('"tasks/backlog"')
  .where(p => p.file.name === "CLAUDE" && p.tags)
const tagCount = {}
for (const p of pages) {
  for (const t of (p.tags || [])) {
    tagCount[t] = (tagCount[t] || 0) + 1
  }
}
const sorted = Object.entries(tagCount).sort((a,b) => b[1]-a[1]).slice(0, 12)
// renderizar tabela com barras unicode
```

---

## Admonitions / Callouts

Usar sintaxe nativa do Obsidian — funciona com e sem o plugin Admonitions:

```markdown
> [!tipo] Título opcional
> Conteúdo

> [!tipo]+ Expandido por padrão (com +)

> [!tipo]- Colapsado por padrão (com -)
```

### Mapeamento semântico recomendado

| Seção | Tipo | Cor |
|-------|------|-----|
| Em Andamento | `[!example]` | roxo |
| Esperando Review | `[!warning]` | amarelo |
| Workers | `[!tip]` | verde |
| Backlog | `[!note]` | azul |
| Inbox | `[!todo]` | azul claro |
| Concluídas | `[!success]` | verde escuro |
| Stats/Info | `[!info]` | azul |
| Kanban manual | `[!question]` | laranja |
| Resumo/Abstract | `[!abstract]` | ciano |

---

## Operações Comuns

### Mover arquivo para trash (reversível)
```bash
mv /workspace/obsidian/<arquivo> /workspace/obsidian/trash/
```

### Criar nova task no backlog
```bash
mkdir -p /workspace/obsidian/tasks/backlog/<slug>
# criar CLAUDE.md com frontmatter
```

### Criar task de worker recorrente
```bash
mkdir -p /workspace/obsidian/tasks/_scheduled/<nome>
# criar TASK.md com clock: every10/every60/every240
```

---

## Plugins relevantes (assumidos instalados)

| Plugin | Uso |
|--------|-----|
| **Dataview** | Queries SQL-like em frontmatter + DataviewJS |
| **Admonitions** | Callouts visuais (sintaxe nativa funciona sem o plugin) |
| **Kanban** | Board visual (kanban.md — atualmente em trash) |

---

## Lições desta sessão (2026-03-19)

1. **Inbox = 1 arquivo** — não criar um arquivo por sugestão; 1 `inbox.md` com tudo, uma linha por item
2. **Task name = folder name** — o nome real da task é o nome da pasta, não do arquivo CLAUDE.md/TASK.md
3. **Dataview file.folder** — única forma confiável de mostrar o nome da task em queries de pastas com CLAUDE.md
4. **Callouts colapsáveis** — usar `-` para seções grandes (Backlog/Done), `+` para ativas (Doing/Review)
5. **DataviewJS > Dataview** para stats — permite barras de progresso unicode e lógica condicional
6. **cssclasses: wide-page** — no frontmatter para dashboards com tabelas largas
