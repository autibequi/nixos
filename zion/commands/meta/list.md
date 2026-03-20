# List — Lista personas ou avatares disponíveis

## Uso
```
/meta:list personas
/meta:list avatars
```

Se `$ARGUMENTS` estiver vazio → listar ambos.

## personas

1. Ler `SOUL.md` para extrair persona ativa (linha `Arquivo: personas/...`)
2. Listar todos os `.persona.md` em `personas/`
3. Exibir tabela: `[x]`/`[ ]` | Nome | Descrição (frontmatter `description` ou primeira linha útil)

## avatars

1. Listar todos os `.avatar.md` em `personas/`
2. Para cada um extrair: nome, persona associada, preview de uma expressão
3. Exibir tabela: `[x]`/`[ ]` | Nome | Persona associada | Preview
4. Marcar `[x]` se vinculado à persona ativa
