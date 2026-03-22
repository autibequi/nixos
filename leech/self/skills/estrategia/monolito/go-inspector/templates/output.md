# Template de Output — Go Inspector

## Pasta de artefatos

```
vault/inspections/<tarefa>/
├── README.md              ← índice com ASCII charts (criar PRIMEIRO)
├── 00-contexto.md         ← dados do PR, JIRA e Notion
├── 01-claude.md           ← qualidade geral Go (correctness, concurrency, error handling)
├── 02-documentation.md    ← swagger, godoc, comentários, migrations
├── 03-qa.md               ← contratos API, breaking changes, frontends
├── 04-namer.md            ← nomenclatura (arquivos, funções, tipos, variáveis)
├── 05-simplifier.md       ← simplificações aplicadas + sugeridas
├── 06-consolidado.md      ← visão unificada, deduplicada, priorizada
└── 07-contrato.md         ← contrato frontend ← → backend (omitir se diff não toca handlers)
```

Onde `<tarefa>` = slug da branch/PR (ex: `cached-ldi-toc`, `add-delta-lake`).

**Sem subpasta de data** — uma inspeção por tarefa. Re-inspeção após correções: adicionar nota no README existente.

---

## README.md

**Criar PRIMEIRO. Inclui tabela-resumo + ASCII charts obrigatórios.**

```markdown
---
task: <tarefa>
branch: <branch-name>
pr: "#<número>" (se disponível)
jira: "<ticket>" (se disponível)
date: YYYY-MM-DD
status: done
inspectors: [claude, documentation, qa, namer, simplifier]
tags: [trabalho, <area>]
related:
  - "[[vault/inspections/BOARD|Board de Inspeções]]"
---

# Inspeção — <branch ou PR title>

<1-2 frases descrevendo o escopo inspecionado>

## Resumo

| Inspector | Findings | Blockers | Média | Baixa | Info |
|-----------|:--------:|:--------:|:-----:|:-----:|:----:|
| claude | N | N | N | N | N |
| documentation | N | N | N | N | N |
| qa | N | N | N | N | N |
| namer | N | N | N | N | N |
| simplifier | N sugeridas | — | — | — | — |
| **Total** | **N** | **N** | **N** | **N** | **N** |

---

## Visão Geral

```
Findings por Inspector                   Severidade Total (N)
──────────────────────────────────────   ──────────────────────────────────────
claude        ████████████  N           🔴 Blocker  ████              N  (N%)
documentation ███████████   N           🟠 Média    █████████████████ N  (N%)
qa            ██████████    N           🟡 Baixa    ███████████       N  (N%)
namer         ████████████  N           ⬜ Info     ████              N  (N%)
simplifier    ███████        N suger.   🔧 Simplif  ███████           N  (N%)
              0    4    8   12
```

```
Blockers por Inspector                   Distribuição por Inspector
──────────────────────────────────────   ──────────────────────────────────────
claude        ███  N                     claude        ███░░░░░░░  NB NM NL Ni
qa            ██   N                     documentation ░░░░████░░  NB NM NL Ni
documentation ·    0                     qa            ██░░░░░░░░  NB NM NL Ni
namer         ·    0                     namer         ░░░███░░░░  NB NM NL Ni
              0    1    2    3           legenda: B=blocker M=média L=baixa i=info
```

(incluir apenas se diff tocou em handlers HTTP)
```
Risco de Deploy
──────────────────────────────────────────────────────
backend solo   ███████████████████░░░░░░  ALTO   — <motivo>
backend+front  █████████████░░░░░░░░░░░  MÉDIO  — <motivo>
tudo alinhado  ████████░░░░░░░░░░░░░░░░  BAIXO  — <motivo>
               0%                    100% seguro
```

(incluir apenas se contrato inspecionado)
```
Contrato Frontend ← → Backend
──────────────────────────────────────
bo-container   ████████████████░░  N✅ N⚠️ N🔴
front-student  ████░░░░░░▓▓░░░░░  N✅ N⚠️ N🔴
               █ alinhado  ░ risco  ▓ quebrado
```

---

## Blockers prioritários

1. **<descrição>** — <arquivo> (<inspector>)
...

## Índice

- [00 - Contexto (Jira/PR)](00-contexto.md)
- [01 - Qualidade Geral Go](01-claude.md)
- [02 - Documentação](02-documentation.md)
- [03 - Contratos QA](03-qa.md)
- [04 - Nomenclatura](04-namer.md)
- [05 - Simplificações](05-simplifier.md)
- [06 - Consolidado](06-consolidado.md)
- [07 - Contrato Frontend](07-contrato.md)  ← omitir se não aplicável
```

---

## 00-contexto.md

```markdown
---
task: <tarefa>
date: YYYY-MM-DD
type: contexto
jira: <ticket>
branch: <branch>
---

# Contexto — <tarefa>

## Card Jira

- **ID**: <ticket>
- **Título**: <título>
- **Status**: <status>
- **Assignee**: <nome>
- **Estimativa**: <pontos>
- **Labels**: <labels>

## Problema

<descrição do problema que motivou a feature>

## Solução implementada

<o que foi implementado — bullet points>

## Branch

`<branch>`

## Diff

- N arquivos, +X -Y linhas
- <resumo dos arquivos principais>

## Reviews do PR (se existir)

<comentários e reviews inline relevantes>

## Notion

<link e resumo da página, se encontrada. "Não encontrada." se ausente>
```

---

## Artefatos de cada Inspector (01 a 05)

```markdown
---
task: <tarefa>
date: YYYY-MM-DD
inspector: <nome>
type: inspection
---

# Inspector <Nome> — <Especialidade>

## Resumo

<1 parágrafo com visão geral dos findings e tom geral>

## Findings

### 1. [SEVERIDADE] Título

**Arquivo:** `caminho/arquivo.go:LN`
**Problema:** <descrição clara do problema>
**Sugestão:**
```go
// código de exemplo quando aplicável
```

---

## Tabela de Findings

| # | Severidade | Arquivo | Descrição |
|---|-----------|---------|-----------|
| 1 | **Blocker** | `file.go:L42` | Descrição curta |
| 2 | Média | `file.go:L100` | Descrição curta |
```

### Severidades

| Label | Significado |
|-------|-------------|
| `[BLOCKER]` | Obrigatório corrigir antes do merge |
| `[MÉDIA]` | Recomendado corrigir — risco real mas não bloqueia |
| `[BAIXA]` | Nice-to-have — melhoria de qualidade |
| `[INFO]` | Observação / documentação para o autor |

---

## 06-consolidado.md

```markdown
---
task: <tarefa>
date: YYYY-MM-DD
type: consolidado
related:
  - "[[vault/inspections/<tarefa>/README|Índice da Inspeção]]"
---

# Consolidado — <tarefa>

## Blockers (ação obrigatória antes do merge)

### B1. <título>
**Inspector:** <nome> | **Arquivo:** `arquivo.go:LN`
<descrição do problema e ação necessária>

...

---

## Pontos de Atenção (ação recomendada)

### A1. <título>
**Inspectors:** <nomes> | **Arquivo:** `arquivo.go:LN`
<descrição>

...

---

## Sugestões (nice-to-have)

### Nomenclatura
- <lista de sugestões>

### Simplificações
- <lista de oportunidades>

### Qualidade
- <lista de melhorias>

---

## Simplificações Aplicadas

<commits do simplifier, ou "Nenhuma simplificação foi aplicada.">

## Simplificações Sugeridas

<N oportunidades identificadas, ~N linhas de redução total. Destaques:>

---

## O que está correto

- <aspecto aprovado>: APROVADO
- <aspecto aprovado>: APROVADO
...

---

## Métricas

| Métrica | Valor |
|---------|-------|
| Total de findings | N |
| Blockers | N |
| Pontos de atenção (Média) | N |
| Sugestões (Baixa/Info) | N |
| Simplificações aplicadas | N commits |
| Simplificações sugeridas | N oportunidades |
| Arquivos analisados | N |
| Inspetores executados | N/5 |
```

---

## 07-contrato.md

```markdown
---
task: <tarefa>
date: YYYY-MM-DD
type: contrato
repos: [front-student, bo-container]
---

# Inspector Contrato — <tarefa>

## <repo-1> vs Backend

### Resumo: N ✅ / N ⚠️ / N 🔴

| Endpoint | Status | Observação |
|----------|--------|------------|
| `GET /path` | ✅ | alinhado |
| `POST /path` | ⚠️ | <risco> |
| `PUT /path` | 🔴 | <o que quebra> |

### Findings

#### 🔴 <título do problema crítico>

**Arquivo:** `<repo>/path/to/file.js:LN`
<descrição detalhada com código de exemplo>

...

## <repo-2> vs Backend

...

## Checklist de status codes novos

| Status Code | Operação | <repo-1> trata? | <repo-2> trata? |
|-------------|----------|-----------------|-----------------|
| 409 | <operação> | ❓ | ❓ |
```

---

## BOARD principal (`vault/inspections/BOARD.md`)

O BOARD é a página central de todas as inspeções. Manter sempre atualizado.

**Regra de tamanho:**
- ≤5 inspeções: conteúdo de cada inspeção inline com âncoras
- >5 inspeções: apenas tabela índice com links para os README.md individuais

```markdown
---
title: Board de Inspeções
tags: [trabalho, board, code-review]
---

# Board de Inspeções

| Inspeção | Branch | Data | Blockers | Findings |
|----------|--------|------|:--------:|:--------:|
| [<tarefa>](#<tarefa>) | `<branch>` | YYYY-MM-DD | N | N |

---

## <tarefa>

<descrição curta da feature>

| Inspector | Findings | Blockers | Média | Baixa | Info |
|-----------|:--------:|:--------:|:-----:|:-----:|:----:|
| [Claude — Qualidade Geral](#claude--qualidade-geral) | N | N | N | N | N |
| [Documentation — Swagger/Godoc](#documentation--swaggergodoc) | N | N | N | N | N |
| [QA — Contratos API](#qa--contratos-api) | N | N | N | N | N |
| [Namer — Nomenclatura](#namer--nomenclatura) | N | N | N | N | N |
| [Simplifier — Simplificações](#simplifier--simplificações) | N sugeridas | — | — | — | — |
| [Consolidado](#consolidado--<tarefa>) | **N** | **N** | **N** | **N** | **N** |

---

### Claude — Qualidade Geral

(conteúdo resumido dos findings do inspector)

---

### Documentation — Swagger/Godoc

...

(repetir para cada inspector)

---

### Consolidado — <tarefa>

#### Blockers (ação obrigatória antes do merge)

**B1 — <título>** _(<inspector>)_
`arquivo.go:LN` — <descrição>

#### Métricas

| Métrica | Valor |
|---------|-------|
| Arquivos analisados | N |
| Total de findings | N |
| Blockers | N |
```

---

## Frontmatter obrigatório em todos os artefatos

```yaml
---
task: <tarefa>
date: YYYY-MM-DD
inspector: <nome>       # exceto README, contexto e consolidado
type: inspection | contexto | consolidado | contrato
tags: [trabalho, <área>]
---
```
