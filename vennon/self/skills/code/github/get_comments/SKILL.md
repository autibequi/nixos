---
name: code/github:get_comments
description: Extrai TODOS os comentários de uma PR — filtro por autor, severidade, formato. Token automático de ~/.vennon.
type: skill
---

# code/github:get_comments — Extrair Comentários PR

Skill para extrair e organizar **TODOS** os comentários de uma Pull Request no GitHub.

## Uso Rápido

```bash
/code:github:get_comments <repo> <pr_number> [options]
```

### Exemplos

```bash
# Listar todos os comentários
/code:github:get_comments estrategiahq/monolito 4485

# Só CodeRabbit, formato tabela
/code:github:get_comments estrategiahq/monolito 4485 --author coderabbitai[bot]

# Críticos e maiores, JSON
/code:github:get_comments estrategiahq/monolito 4485 --severity critical,major --format json

# Salvar em arquivo
/code:github:get_comments estrategiahq/monolito 4485 --output /tmp/pr_comments.json

# Filtrar por arquivo
/code:github:get_comments estrategiahq/monolito 4485 --path "apps/ldi/**"
```

## Opções

| Flag | Padrão | Descrição |
|------|--------|-----------|
| `--author <name>` | (todos) | Filtrar por author login (ex: `coderabbitai[bot]`, `pedrosmith`) |
| `--severity <list>` | (todos) | Filtrar por severidade: `critical`, `major`, `minor`, `trivial` (separado por vírgula) |
| `--format <type>` | `table` | Formato saída: `table`, `json`, `markdown`, `csv` |
| `--output <file>` | (stdout) | Salvar em arquivo em vez de imprimir |
| `--path <glob>` | (todos) | Filtrar por arquivo (glob pattern) |
| `--resolved` | false | Incluir comentários resolvidos/minimizados |
| `--count-only` | false | Retornar só contagem |

## Formatos de Saída

### Table (padrão)
```
┌─────────────────────────────────────────────────────┐
│ PR #4485 — 37 comentários extraídos                 │
├─────────────────────────────────────────────────────┤
│ [🔴 CRITICAL] check_toc_rebuild_conflict.go:64      │
│ Data race: append concorrente em slice              │
│ Author: coderabbitai[bot] | 2026-03-26 13:45:00Z    │
└─────────────────────────────────────────────────────┘
```

### JSON
```json
{
  "repo": "estrategiahq/monolito",
  "pr": 4485,
  "total": 37,
  "comments": [
    {
      "id": "IC_kwDOEGMlcs...",
      "path": "apps/ldi/internal/services/course/check_toc_rebuild_conflict.go",
      "line": 64,
      "severity": "CRITICAL",
      "author": "coderabbitai[bot]",
      "created_at": "2026-03-26T13:45:00Z",
      "body": "Data race crítico: append concorrente..."
    }
  ]
}
```

### Markdown
```markdown
## PR #4485 — 37 Comentários

### 🔴 Critical (5)

#### check_toc_rebuild_conflict.go:64
- **Severidade**: CRITICAL
- **Autor**: @coderabbitai[bot]
- **Data**: 2026-03-26 13:45:00Z

Data race crítico: append concorrente em slice compartilhado...
```

## Classificação de Severidade

O script detecta automaticamente severidade baseado no body do comentário:

- **🔴 CRITICAL** — Precisa ser corrigido antes de merge (panic, data race, segurança)
- **🟠 MAJOR** — Impacto significativo (lógica, performance, API)
- **🟡 MINOR** — Melhorias recomendadas (validação, edge cases)
- **🔵 TRIVIAL** — Nice-to-have (nitpick, comentários, constants)

## Implementação Técnica

### Autenticação
Token sempre lido de `~/.vennon`:
```bash
export GH_TOKEN=$(grep '^GH_TOKEN=' ~/.vennon | cut -d'=' -f2)
```

### API Endpoint
Usa `gh api repos/<owner>/<repo>/pulls/<pr>/comments --paginate`:
```bash
gh api repos/estrategiahq/monolito/pulls/4485/comments --paginate \
  -q '.[] | select(.user.login == "coderabbitai[bot]")'
```

### Parser de Severidade
Procura keywords no body:
- `Critical|panic|data race|nil pointer|SQL injection` → CRITICAL
- `Major|should|must|deprecated` → MAJOR
- `Minor|could|consider|optional` → MINOR
- Padrão: TRIVIAL

## Integração com Skills

Chamada por:
- `/code:review` — Listar comentários antes de responder
- `/code:peer-reviews` — Análise de reviews CodeRabbit
- `/meta:code:pr:comment-check` — Auditoria completa de PR

## Saída Esperada

```
✅ Extracted 37 comments from estrategiahq/monolito PR #4485

SEVERITY BREAKDOWN:
  🔴 CRITICAL    5 comentários
  🟠 MAJOR       9 comentários
  🟡 MINOR      14 comentários
  🔵 TRIVIAL     9 comentários

AUTHOR BREAKDOWN:
  coderabbitai[bot]   37 (100%)

TOP 5 FILES:
  apps/ldi/internal/services/course/build_and_save_content_tree.go        (6)
  apps/bo/internal/handlers/ldi/**                                        (13)
  libs/utils/testutils/pgtest/options.go                                  (4)
  apps/ldi/internal/services/item/get_blocks_from_item_test.go            (2)
  configuration/config_sqs.yaml                                           (1)

✓ Output saved to: /tmp/pr_comments.json
```

## Exemplos Completos

### Extrair só críticos e maiores de CodeRabbit
```bash
/code:github:get_comments estrategiahq/monolito 4485 \
  --author coderabbitai[bot] \
  --severity critical,major \
  --format json \
  --output /tmp/critical.json
```

### Tabela de comentários em apps/ldi/**
```bash
/code:github:get_comments estrategiahq/monolito 4485 \
  --path "apps/ldi/**" \
  --format table
```

### Contar comentários por severidade
```bash
/code:github:get_comments estrategiahq/monolito 4485 \
  --format json | jq '.comments | group_by(.severity) | map({severity: .[0].severity, count: length})'
```

---

**Skill Author**: Claude Haiku
**Criado**: 2026-03-27
**Última atualização**: 2026-03-27
**Status**: ✅ Pronto para uso
