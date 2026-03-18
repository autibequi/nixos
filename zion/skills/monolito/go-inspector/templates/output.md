# Template de Output — Go Inspector

## Pasta de artefatos

```
obsidian/artefatos/inspect-<slug>/
├── README.md                  ← índice consolidado com frontmatter
├── 01-claude.md               ← findings do inspector-claude (qualidade geral)
├── 02-documentation.md        ← findings do inspector-documentation
├── 03-qa.md                   ← findings do inspector-qa (contratos)
├── 04-namer.md                ← findings do inspector-namer (nomenclatura)
├── 05-simplifier.md           ← findings + commits do inspector-simplifier
└── 06-consolidado.md          ← visão unificada, deduplicada, priorizada
```

---

## README.md

```markdown
---
task: inspect-<slug>
branch: <branch-name>
date: YYYY-MM-DD
status: done
inspectors: [claude, documentation, qa, namer, simplifier]
---

# Inspeção — <branch ou PR title>

<1-2 frases descrevendo o escopo inspecionado>

## Resumo

| Inspector | Findings | Blockers | Média | Baixa | Info |
|-----------|----------|----------|-------|-------|------|
| claude | N | N | N | N | N |
| documentation | N | N | N | N | N |
| qa | N | N | N | N | N |
| namer | N | N | N | N | N |
| simplifier | N aplicadas, M sugeridas | - | - | - | - |

## Índice

- [01 - Qualidade Geral](01-claude.md)
- [02 - Documentação](02-documentation.md)
- [03 - Contratos QA](03-qa.md)
- [04 - Nomenclatura](04-namer.md)
- [05 - Simplificações](05-simplifier.md)
- [06 - Consolidado](06-consolidado.md)
```

---

## Artefatos de cada Inspector (01 a 05)

```markdown
---
task: inspect-<slug>
date: YYYY-MM-DD
inspector: <nome-do-inspector>
type: inspection
---

# <Inspector Name> — Findings

## Resumo

<1 parágrafo com visão geral dos findings>

## Findings

### 1. [SEVERIDADE] Título
...formato específico do inspector...

### 2. [SEVERIDADE] Título
...

## Tabela de Findings

| # | Severidade | Arquivo | Descrição |
|---|-----------|---------|-----------|
| 1 | **Blocker** | `file.go:L42` | Descrição curta |
| 2 | Média | `file.go:L100` | Descrição curta |
```

---

## 06-consolidado.md

```markdown
---
task: inspect-<slug>
date: YYYY-MM-DD
type: consolidado
---

# Consolidado — inspect-<slug>

## Blockers (ação obrigatória)

Lista deduplicada de todos os blockers, com referência ao inspector que encontrou.

## Pontos de Atenção (ação recomendada)

Lista deduplicada de findings de severidade média.

## Sugestões (nice-to-have)

Lista de findings de severidade baixa, agrupadas por tema.

## Simplificações Aplicadas

Resumo dos commits do simplifier com diff links.

## Simplificações Sugeridas

Oportunidades não aplicadas que o dev pode considerar.

## Métricas

- Total de findings: N
- Blockers: N
- Simplificações aplicadas: N commits, -N linhas
- Arquivos analisados: N
- Inspetores executados: 5/5
```

---

## Frontmatter obrigatório em todos os artefatos

```yaml
---
task: inspect-<slug>
date: YYYY-MM-DD
inspector: <nome> (exceto README e consolidado)
type: inspection | consolidado
---
```
