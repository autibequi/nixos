# Template de Output — Go Inspector

## Pasta de artefatos

```
obsidian/inspection/<tarefa>/<data>/
├── BOARD.md                   ← resumo visual executivo (abrir primeiro)
├── README.md                  ← índice detalhado com frontmatter
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

## BOARD.md — Resumo Visual Executivo

Este é o primeiro arquivo a ser aberto. Uma página, tudo que importa.

```markdown
---
task: <tarefa>
date: YYYY-MM-DD
type: board
---

# 🔍 Inspeção — <tarefa>

> <1 frase descrevendo o PR>
> **PR:** #N · **Autor:** @username · **JIRA:** [<ticket>](...) · **Data:** YYYY-MM-DD

---

## Veredito

| | Status |
|---|---|
| **Pode mergear?** | 🔴 Não — N blocker(s) · ou · 🟡 Com ressalvas · ou · 🟢 Sim |
| **Testes ok?** | 🔴 N gaps críticos · ou · 🟢 Cobertura adequada |
| **Simplificável?** | N commits aplicados · M sugeridos |

---

## Placar dos Inspetores

| Inspector | 🔴 Blocker | 🟠 Média | 🟡 Baixa | ℹ️ Info | Barra |
|-----------|-----------|---------|---------|--------|-------|
| 🏛️ Architect | N | N | N | N | `██░░░░░░░░` |
| 🐹 Claude | N | N | N | N | `████░░░░░░` |
| 📄 Documentation | N | N | N | N | `██░░░░░░░░` |
| 🤝 QA | N | N | N | N | `███░░░░░░░` |
| 🏷️ Namer | N | N | N | N | `█░░░░░░░░░` |
| 🧪 Coverage | N gaps | N críticos | N médios | — | `████░░░░░░` |
| ✂️ Simplifier | N aplicados | — | N sugeridos | — | `██░░░░░░░░` |

> Barra: `█` por finding (máx 10). Serve pra ter noção do volume por inspector.

---

## 🔴 Blockers — Ação obrigatória antes do merge

> Se vazio: 🟢 Nenhum blocker encontrado.

| # | Inspector | Arquivo | Descrição |
|---|-----------|---------|-----------|
| 1 | claude | `service.go:L42` | Nil panic em retorno de repo sem guard |
| 2 | coverage | `service.go:L80` | Método principal sem nenhum teste |
| 3 | qa | `handler.go:L15` | Breaking change em response struct |

---

## 🧪 Gaps de Cobertura

> O que precisa de teste antes do merge.

| # | Severidade | Método | Cenário não coberto |
|---|-----------|--------|---------------------|
| 1 | 🔴 Crítico | `Service.Create` | Erro do repo não testado |
| 2 | 🟠 Médio | `Service.Get` | Input nil |

---

## 💬 Tópicos para o Autor

> Perguntas que precisam de resposta antes do merge (ou na conversa de review).

1. **[Tópico 1]** — <pergunta direta>
2. **[Tópico 2]** — <pergunta direta>

---

## 🟠 Pontos de Atenção

| # | Inspector | Descrição |
|---|-----------|-----------|
| 1 | claude | Race condition possível em X |
| 2 | qa | Campo novo sem omitempty |

---

## ✂️ Simplificações Aplicadas

> Commits já feitos no worktree. Aguardando aprovação do dev.

| Commit | Descrição | Impacto |
|--------|-----------|---------|
| `abc1234` | simplify: extract validateX | -12 linhas |

> 🟡 Nenhuma simplificação aplicada. / Ver `07-simplifier.md` para sugestões.

---

## 📊 Visualizações ASCII

> **OBRIGATÓRIO:** gerar TODOS os gráficos abaixo com dados reais da inspeção. Usar `█` para cheio, `░` para vazio, `▓` para risco/parcial.

### Placar dos Inspetores (horizontal)

```
architect     ████████████  APROVADO / N findings
claude        ████████░░░░  N findings — descrição curta
documentation ████████████  APROVADO
qa            ██████░░░░░░  N gaps — descrição curta
namer         ████████████  APROVADO
coverage      ██████░░░░░░  N métodos sem teste
simplifier    ██████████░░  N melhorias identificadas
```

> Barra reflete saúde: 12 blocos = limpo, menos = mais issues. Ajustar proporcionalmente.

### Findings por Severidade (vertical)

```
         ▲
       N │  ██
         │  ██
       1 │  ██  ██              ██
         │  ██  ██              ██
       0 │  ██  ██  ░░  ░░  ░░  ██
         └──────────────────────────▶
            🔴  🟠  🟡  🟡  🟡  ⚠️
           (N) (N) (N) (N) (N) (N)
```

> Mostrar cada finding individualmente no eixo X com sua categoria e repo de origem.

### Cobertura de Testes (barras horizontais)

```
                    0%      50%     100%
                    │       │        │
MetodoA             ░░░░░░░░░░░░░░░░  ← sem teste
MetodoB             ████████░░░░░░░░  parcial
MetodoC             ████████████████  ✅ coberto
```

> Um linha por método/fluxo relevante da feature. Priorizar os do caminho crítico.

### Contrato Frontend ← → Backend (quando aplicável)

```
                  ✅ ok   ⚠️ risco   🔴 quebrado
bo-container  ████████████████░░░░░░░  N✅ N⚠️ N🔴
front-student ████░░░░░░░░░░░░▓▓▓▓▓▓▓  N✅ N⚠️ N🔴
bff-mobile    ████████████████████████  N✅ N⚠️ N🔴
```

> Omitir repos não afetados pela feature.

### Risco de Deploy (quando contrato inspecionado)

```
  Backend sozinho   ████████████████████  🔴 ALTO
  Backend + fronts  ████████████░░░░░░░░  🟡 MÉDIO
  Tudo alinhado     ████████████████░░░░  🟢 BAIXO
                    0        50%      100% pronto
```

### Métricas finais

```
Findings totais ............ N
  🔴 Críticos .............. N
  🟠 Médios ................ N
  🟡 Baixos ................ N
  ⬛ Cosméticos ............ N

Cobertura
  Métodos mapeados ......... N
  Com teste ................ N (XX%)
  Gaps críticos ............ N

Contrato (se inspecionado)
  Endpoints verificados .... N
  Alinhados ................ N
  Em risco ................. N
  Quebrados ................ N

Simplificador
  Commits aplicados ........ N
  Linhas removidas ......... -N

Inspetores ................. 7/7 ✅
Arquivos analisados ........ N
```

---

## 🗂️ Artefatos Completos

| Arquivo | Conteúdo |
|---------|----------|
| [00-contexto](00-contexto.md) | PR body, JIRA, Notion |
| [01-architect](01-architect.md) | Visão geral, design, tópicos |
| [02-claude](02-claude.md) | Correctness, concurrency, performance |
| [03-documentation](03-documentation.md) | Swagger, godoc, comentários |
| [04-qa](04-qa.md) | Contratos, breaking changes |
| [05-namer](05-namer.md) | Nomenclatura |
| [06-coverage](06-coverage.md) | Gaps de teste detalhados |
| [07-simplifier](07-simplifier.md) | Refactors aplicados e sugeridos |
| [08-consolidado](08-consolidado.md) | Visão unificada completa |
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
