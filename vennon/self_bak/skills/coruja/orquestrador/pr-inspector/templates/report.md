# Template — Relatório de Inspeção de PR

## Frontmatter

```yaml
---
pr: <número>
repo: <repositório>
title: "<título do PR>"
author: "<autor>"
date: YYYY-MM-DD
inspector: Claude
categories_inspected: <N>
total_findings: <N>
blockers: <N>
warnings: <N>
suggestions: <N>
hallucinations: <N>
verdict: "<APROVAR | APROVAR COM RESSALVAS | SOLICITAR MUDANÇAS | REJEITAR>"
---
```

## Seções do Relatório

### 1. Resumo Executivo

```markdown
## Resumo

PR #<N> — **<título>** por <autor>

| Métrica | Valor |
|---|---|
| Linhas | +<additions> / -<deletions> |
| Arquivos | <count> |
| Categorias | <list> |
| Blockers | <N> |
| Warnings | <N> |
| Sugestões | <N> |
| Hallucinations | <N> |

**Veredito:** <VEREDITO> — <razão em 1 frase>
```

### 2. Findings por Categoria

```markdown
## Findings

### <Categoria 1> (<N> findings)

#### 🔴 [Blocker] <Título>
- **Arquivo:** `<path>:<line>`
- **Contexto:** <descrição do problema>
- **Impacto:** <o que pode dar errado>
- **Sugestão:** <como resolver>

#### ⚠️ [Warning] <Título>
- **Arquivo:** `<path>:<line>`
- **Contexto:** <descrição>
- **Sugestão:** <como resolver>

#### 💡 [Sugestão] <Título>
- **Arquivo:** `<path>:<line>`
- **Contexto:** <descrição>
```

### 3. Hallucination Report

```markdown
## Hallucination Check

| # | Tipo | Arquivo:Linha | Referência | Existe? |
|---|---|---|---|---|
| 1 | Import | handler.go:5 | `pkg/inexistente` | ❌ |
| 2 | Tipo | service.go:15 | `MyInterface` | ✅ |
| 3 | Componente | Page.vue:3 | `MyComponent` | ❌ |

**Resultado:** <N> hallucinations em <total> referências verificadas
```

### 4. Pattern Compliance

```markdown
## Aderência a Padrões

| Padrão | Status | Nota |
|---|---|---|
| Envelope HTTPResponse | ✅ | Usado corretamente |
| elogger para logging | ⚠️ | 2 funções usam log.Printf |
| Swagger comments | ✅ | Completos |
| Interface-first | ✅ | Declaradas em interfaces/ |
| Test coverage | ⚠️ | 3 services sem teste |
```

### 5. Veredito e Recomendações

```markdown
## Veredito

**<VEREDITO>**

### Blockers a resolver:
1. <blocker 1>
2. <blocker 2>

### Recomendações:
1. <recomendação 1>
2. <recomendação 2>

### O que está bom:
1. <ponto positivo 1>
2. <ponto positivo 2>
```

---

*Usar este template para gerar o relatório no Passo 7 da inspeção.*
