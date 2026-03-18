# Template de Output — Go Inspector

## Pasta de artefatos

```
obsidian/inspection/<tarefa>/<data>/
├── README.md                  ← índice consolidado com frontmatter
├── 00-contexto.md             ← dados coletados do PR, JIRA e Notion
├── 01-architect.md            ← visão geral, design, schema, tópicos de discussão
├── 02-claude.md               ← findings do inspector-claude (qualidade geral Go)
├── 03-documentation.md        ← findings do inspector-documentation
├── 04-qa.md                   ← findings do inspector-qa (contratos)
├── 05-namer.md                ← findings do inspector-namer (nomenclatura)
├── 06-coverage.md             ← análise de cobertura de testes e gaps
├── 07-simplifier.md           ← findings + commits do inspector-simplifier
└── 08-consolidado.md          ← visão unificada, deduplicada, priorizada
```

Onde:
- `<tarefa>` = slug da branch/PR (ex: `add-delta-lake`, `cached-ldi-toc`)
- `<data>` = YYYY-MM-DD da inspeção

---

## README.md

```markdown
---
task: <tarefa>
branch: <branch-name>
pr: "#<número>" (se disponível)
jira: "<ticket>" (se disponível)
date: YYYY-MM-DD
status: done
inspectors: [architect, claude, documentation, qa, namer, coverage, simplifier]
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
| coverage | N gaps | N blockers | N | N | - |
| simplifier | N aplicadas, M sugeridas | - | - | - | - |

## Índice

- [00 - Contexto](00-contexto.md)
- [01 - Visão Geral e Design](01-architect.md)
- [02 - Qualidade Geral Go](02-claude.md)
- [03 - Documentação](03-documentation.md)
- [04 - Contratos QA](04-qa.md)
- [05 - Nomenclatura](05-namer.md)
- [06 - Cobertura de Testes](06-coverage.md)
- [07 - Simplificações](07-simplifier.md)
- [08 - Consolidado](08-consolidado.md)
```

---

## 00-contexto.md

```markdown
---
task: <tarefa>
date: YYYY-MM-DD
type: contexto
---

# Contexto — <tarefa>

## PR

- **Título:** <título>
- **Autor:** <username>
- **Branch:** `<branch>` → `main`
- **Arquivos:** N alterados, +X -Y linhas
- **Estado:** open | merged

### Descrição do PR
<body do PR copiado integralmente>

### Commits
<lista de commits do log>

## JIRA

<conteúdo do ticket se encontrado — título, descrição, critérios de aceite, comentários relevantes>

Se não encontrado: `Ticket não localizado. Branch: <nome>`

## Notion

<conteúdo da página se encontrada — contexto de produto, decisões de design, user stories>

Se não encontrado: `Página não localizada.`

## Resumo de Contexto

<2-3 frases sintetizando o contexto: o que foi pedido (JIRA/Notion) vs o que foi entregue (PR)>
```

---

## Artefatos de cada Inspector (01 a 07)

```markdown
---
task: <tarefa>
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

## Tabela de Findings

| # | Severidade | Arquivo | Descrição |
|---|-----------|---------|-----------|
| 1 | **Blocker** | `file.go:L42` | Descrição curta |
| 2 | Média | `file.go:L100` | Descrição curta |
```

### Formato especial: 01-architect.md

Segue o formato definido em `obsidian/agents/inspectors/architect.md` — inclui visão geral, análise de design, findings de schema/layer e tópicos de discussão.

### Formato especial: 06-coverage.md

Segue o formato definido em `obsidian/agents/inspectors/coverage.md` — inclui mapeamento de fluxos, tabela de gaps e testes sugeridos.

---

## 08-consolidado.md

```markdown
---
task: <tarefa>
date: YYYY-MM-DD
type: consolidado
---

# Consolidado — <tarefa>

## Contexto em 1 parágrafo

<resumo do 00-contexto.md: o que foi pedido e o que foi entregue>

## Blockers (ação obrigatória antes do merge)

Lista deduplicada de todos os blockers, com referência ao inspector que encontrou.

## Pontos de Atenção (ação recomendada)

Lista deduplicada de findings de severidade média.

## Gaps de Cobertura

Reexportar os gaps críticos do coverage inspector — o que precisa ser testado antes do merge.

## Tópicos de Discussão

Reexportar os tópicos do architect — perguntas que precisam de resposta do autor.

## Sugestões (nice-to-have)

Lista de findings de severidade baixa, agrupadas por tema.

## Simplificações Aplicadas

Resumo dos commits do simplifier com diff links.

## Simplificações Sugeridas

Oportunidades não aplicadas que o dev pode considerar.

## Métricas

- Total de findings: N
- Blockers: N
- Gaps de cobertura críticos: N
- Simplificações aplicadas: N commits, -N linhas
- Arquivos analisados: N
- Inspetores executados: 7/7
```

---

## Frontmatter obrigatório em todos os artefatos

```yaml
---
task: <tarefa>
date: YYYY-MM-DD
inspector: <nome> (exceto README, contexto e consolidado)
type: inspection | contexto | consolidado
---
```
