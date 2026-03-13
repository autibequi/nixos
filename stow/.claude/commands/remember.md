# Lembrar

Salvar rapidamente uma informação na memória persistente.

## Entrada
- `$ARGUMENTS`: o que lembrar (texto livre)

## Instruções

1. Ler `MEMORY.md` em `~/.claude/projects/-workspace/memory/` pra verificar se já existe memória similar
2. Classificar o tipo automaticamente:
   - Correção/preferência do user → `feedback`
   - Info sobre o user → `user`
   - Contexto de projeto → `project`
   - Ponteiro externo → `reference`
3. Criar arquivo `memory/<tipo>_<topico>.md` com frontmatter correto:
```markdown
---
name: tipo_topico
description: uma linha específica
type: feedback|user|project|reference
---

Conteúdo conciso.

**Why:** motivo
**How to apply:** quando/como usar
```
4. Adicionar entrada no `MEMORY.md`
5. Confirmar o que foi salvo

## Regras
- Se já existe memória similar, ATUALIZAR ao invés de duplicar
- Converter datas relativas pra absolutas
- Ser conciso — uma memória = um conceito
