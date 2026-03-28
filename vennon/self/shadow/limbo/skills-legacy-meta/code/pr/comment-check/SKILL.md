---
name: meta:code:pr:comment-check
description: Extrai TODOS os comentários CodeRabbit de uma PR, verifica resolução no código e gera relatório detalhado
type: skill
---

# Meta Code PR Comment Check

## Objetivo
Fazer auditoria completa de comentários CodeRabbit em uma PR:
1. Extrair **TODOS** os comentários
2. Verificar se cada um foi **resolvido** no código
3. Gerar **relatório detalhado** com explicações

## Uso

```bash
/meta:code:pr:comment-check <repo> <pr> [--branch] [--detailed]
```

### Exemplos

```bash
# Verificar PR 4485 do monolito
/meta:code:pr:comment-check estrategiahq/monolito 4485

# Modo detalhado com branch info
/meta:code:pr:comment-check estrategiahq/monolito 4485 --detailed

# Verificar front-student
/meta:code:pr:comment-check estrategiahq/front-student 4583
```

## Fluxo de Execução

### 1. Extrair Comentários
```bash
gh pr view $PR --repo $REPO --json comments,reviews \
  -q '.comments[] | select(.author.login == "coderabbit")'
```

### 2. Parsear cada Comentário
- Arquivo/linha
- Severidade (CRITICAL/MAJOR/MINOR)
- Tipo (bug/refactor/docs)
- Descrição completa

### 3. Verificar Resolução
Para cada comentário:
- Ler arquivo mencionado
- Procurar padrões específicos da fix
- Marcar como ✓ (resolvido) ou ✗ (pendente)

### 4. Gerar Relatório
```
📋 RELATÓRIO DE AUDITORIA - PR #4485
=====================================

✅ CRÍTICOS (1/1 resolvido)
───────────────────────────
1. Data Race em check_toc_rebuild_conflict.go:54
   Severidade: CRITICAL
   Tipo: Bug

   Problema:
   > append sem mutex em goroutine concurrent

   Solução Esperada:
   > Adicionar sync.Mutex e proteger allJobs

   Verificação:
   ✓ Encontrado: var mu sync.Mutex (linha 39)
   ✓ Encontrado: mu.Lock() ... mu.Unlock() (linhas 56-57)

   Status: ✅ RESOLVIDO

🟠 MAIORES (4/4 resolvidos)
─────────────────────────────
2. Extension Validation em pgtest/options.go:97-110
   [...]

🟡 MENORES (1/1 resolvido)
──────────────────────────
5. Timeout Error em pgtest/options.go:121
   [...]

🔧 REFACTORING (28/28 resolvidos)
──────────────────────────────────
6. Slice Pre-allocation em get_course.go:162
   [...]

=====================================
📊 RESULTADO FINAL
────────────────────────────────────
Total de Comentários: 34
✅ Resolvidos: 34
❌ Pendentes: 0

Taxa de Resolução: 100% ✓✓✓

Arquivos Modificados: 25
Commits Necessários: 5 (já aplicados)

Status: ✅ AUDITORIA COMPLETA - TUDO OK
```

## Saída Esperada

### JSON Mode (`--format json`)
```json
{
  "pr": "4485",
  "repo": "estrategiahq/monolito",
  "timestamp": "2026-03-27T12:00:00Z",
  "summary": {
    "total": 34,
    "resolved": 34,
    "pending": 0,
    "resolution_rate": 100
  },
  "comments": [
    {
      "id": 1,
      "file": "apps/ldi/internal/services/course/check_toc_rebuild_conflict.go",
      "line": 54,
      "severity": "CRITICAL",
      "author": "coderabbit",
      "problem": "append sem mutex em goroutine",
      "solution": "Adicionar sync.Mutex",
      "resolved": true,
      "evidence": [
        "var mu sync.Mutex (linha 39)",
        "mu.Lock() ... mu.Unlock() (linhas 56-57)"
      ]
    }
  ]
}
```

### Markdown Mode (`--format markdown`)
```markdown
# Auditoria PR #4485

## Summary
- **Total**: 34 comentários
- **Resolvidos**: 34 ✅
- **Pendentes**: 0
- **Taxa**: 100%

## Por Severidade

### Critical (1)
- [x] Data Race em check_toc_rebuild_conflict.go
  - Fix: sync.Mutex + lock/unlock

### Major (4)
- [x] Extension validation
- [x] NewRelic nil check
- [x] HTTP response wrapping (13 handlers)
- [x] [...]
```

## Implementação

### Dependências
- `gh` CLI com autenticação
- `jq` para parsing JSON
- `git` para checkout de branch
- Shell script ou Python

### Função Principal
```bash
check_pr_comments() {
    local repo=$1
    local pr=$2

    # 1. Extrair comentários
    local comments=$(gh pr view "$pr" --repo "$repo" --json comments)

    # 2. Para cada comentário
    echo "$comments" | jq -c '.comments[]' | while read comment; do
        local file=$(echo "$comment" | jq -r '.path')
        local line=$(echo "$comment" | jq -r '.line')
        local body=$(echo "$comment" | jq -r '.body')

        # 3. Verificar arquivo
        check_file_resolution "$file" "$body"
    done

    # 4. Gerar relatório
    generate_report
}
```

## Integração com Claude Code

Quando usuário mencionar:
- "checa os comentários dessa PR"
- "valida os comentários"
- "auditoria de PR"

Automaticamente invoca `/meta:code:pr:comment-check` com a PR mencionada.

## Flags Opcionais

- `--detailed`: Mostra código antes/depois
- `--format [json|markdown|table]`: Formato de saída
- `--branch <branch>`: Branch específica (default: HEAD)
- `--author <name>`: Filtrar por autor (default: coderabbit)
- `--severity [critical|major|minor]`: Filtrar por severidade
- `--export <file>`: Exportar relatório para arquivo

## Status

- [x] Documentação
- [ ] Implementação em script
- [ ] Integração com gh CLI
- [ ] Teste com PR 4485
- [ ] Publicar skill

## Próximos Passos

1. Implementar em `/workspace/self/skills/meta/code/pr/comment-check/script.sh`
2. Testar com PRs reais
3. Integrar resposta automática em Claude
4. Cachear resultados para performance

---

**Skill Author**: Claude Haiku
**Criado**: 2026-03-27
**Versão**: 1.0
