# Template de Output — Go Inspector

## Pasta de artefatos

```
obsidian/artefatos/inspect-<slug>/
├── README.md                  ← índice consolidado com frontmatter
├── 01-architect.md            ← visão geral, design, schema, tópicos de discussão
├── 02-claude.md               ← findings do inspector-claude (qualidade geral Go)
├── 03-documentation.md        ← findings do inspector-documentation
├── 04-qa.md                   ← findings do inspector-qa (contratos)
├── 05-namer.md                ← findings do inspector-namer (nomenclatura)
├── 06-simplifier.md           ← findings + commits do inspector-simplifier
└── 07-consolidado.md          ← visão unificada, deduplicada, priorizada
```

---

## README.md

```markdown
---
task: inspect-<slug>
branch: <branch-name>
date: YYYY-MM-DD
status: done
inspectors: [architect, claude, documentation, qa, namer, simplifier]
---

# Inspeção — <branch ou PR title>

<1-2 frases descrevendo o escopo inspecionado>

## Resumo

| Inspector | Findings | Blockers | Média | Baixa | Info |
|-----------|----------|----------|-------|-------|------|
| architect | N | N | N | N | N |
| claude | N | N | N | N | N |
| documentation | N | N | N | N | N |
| qa | N | N | N | N | N |
| namer | N | N | N | N | N |
| simplifier | N aplicadas, M sugeridas | - | - | - | - |

## Índice

- [01 - Visão Geral e Design](01-architect.md)
- [02 - Qualidade Geral Go](02-claude.md)
- [03 - Documentação](03-documentation.md)
- [04 - Contratos QA](04-qa.md)
- [05 - Nomenclatura](05-namer.md)
- [06 - Simplificações](06-simplifier.md)
- [07 - Consolidado](07-consolidado.md)
```

---

## Artefatos de cada Inspector (01 a 06)

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

### Formato especial: 01-architect.md

O artefato do architect segue o formato definido em `obsidian/agents/inspectors/architect.md`, que inclui:
- Visão Geral (tabelas, entities, fluxo)
- Análise de Design
- Findings de Schema/Layer
- Tópicos de Discussão (com resumo de prioridades)

---

## 07-consolidado.md

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

## Tópicos de Discussão

Reexportar os tópicos do architect (os de maior prioridade), para visibilidade no consolidado.

## Simplificações Aplicadas

Resumo dos commits do simplifier com diff links.

## Simplificações Sugeridas

Oportunidades não aplicadas que o dev pode considerar.

## Métricas

- Total de findings: N
- Blockers: N
- Simplificações aplicadas: N commits, -N linhas
- Arquivos analisados: N
- Inspetores executados: 6/6
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
