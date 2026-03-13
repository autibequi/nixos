# Esquecer

Remover ou atualizar uma memória persistente.

## Entrada
- `$ARGUMENTS`: o que esquecer (texto livre ou nome do arquivo de memória)

## Instruções

1. Ler `MEMORY.md` em `~/.claude/projects/-workspace/memory/`
2. Buscar memória relevante:
   - Se o argumento é um nome de arquivo (ex: `feedback_kanban_first`) → match direto
   - Se é texto livre → buscar com Grep nos arquivos `memory/*.md` pelo conteúdo
3. Mostrar ao user o que foi encontrado e confirmar antes de deletar
4. Ao confirmar:
   - Deletar o arquivo `memory/<nome>.md`
   - Remover a entrada correspondente do `MEMORY.md`
5. Se o user quer apenas atualizar (não remover): editar o conteúdo e manter no índice

## Regras
- SEMPRE confirmar antes de deletar — mostrar o conteúdo da memória pro user
- Se múltiplas memórias casam com a busca, listar todas e pedir pro user escolher
- Se não encontrar nada, avisar e listar as memórias existentes
