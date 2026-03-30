---
name: code:clean
description: "Limpa bookmarks jj que já foram deletados no remoto (gone). Equivalente ao clean de branches [gone] do git, mas para jj."
allowed-tools: Bash(jj bookmark *)
---

## Contexto

- Bookmarks atuais: !`jj bookmark list 2>/dev/null`

## Sua tarefa

No jj, bookmarks "gone" são os que têm `@origin` (tracking remoto) mas o remoto foi deletado — aparecem como `bookmark (deleted)` após um `jj git fetch`.

1. Faça fetch para atualizar o estado dos remotos:
   ```bash
   jj git fetch
   ```

2. Liste bookmarks que o remoto deletou (aparecem com `(deleted)` ou sem par remoto):
   ```bash
   jj bookmark list
   ```

3. Delete bookmarks locais que o remoto não tem mais:
   ```bash
   jj bookmark delete <nome>
   ```

Se o repo usar git (sem `.jj`), executar o equivalente git:
```bash
git branch -v | grep '\[gone\]' | awk '{print $1}' | xargs -r git branch -D
```

Reporte quais bookmarks foram removidos, ou informe que não havia nada para limpar.
