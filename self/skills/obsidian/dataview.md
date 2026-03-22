# Dataview — Queries no Obsidian

## Contar cards

```javascript
const todo = dv.pages('"tasks/TODO"').length
const doing = dv.pages('"tasks/DOING"').length
const done = dv.pages('"tasks/DONE"').length
```

## Tabela de cards

```dataview
TABLE WITHOUT ID file.name as "Card", agent as "Agente", model as "Modelo"
FROM "tasks/DOING" SORT file.mtime DESC
```

## Tabela de agentes (memories)

```dataviewjs
const agents = ["assistant","coruja","doctor","hermes","jafar","mechanic","paperboy","tamagochi","tasker","wanderer","wiseman"]
let rows = []
for (const a of agents) {
  const mem = dv.page(`agents/${a}/memory`)
  rows.push([a, mem ? mem.file.mtime : "sem memoria"])
}
dv.table(["Agent", "Ultima Atualizacao"], rows)
```

## Callouts

| Secao | Tipo |
|-------|------|
| Alertas | `[!warning]` |
| Em Andamento | `[!example]` |
| TODO | `[!tip]` |
| Concluidos | `[!success]` |
| Agentes | `[!abstract]` |
| Feed | `[!quote]` |

Sintaxe: `> [!tipo]+ Expandido` ou `> [!tipo]- Colapsado`
