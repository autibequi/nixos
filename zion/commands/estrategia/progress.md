---
name: estrategia/progress
description: Snapshot do estado atual de trabalho no workspace estrategia — agrega tasks, STATE.md dos repos, histórico recente e branches ativas
---

# /progress — Estado Atual do Workspace

Agregar e apresentar um dashboard compacto do estado atual de trabalho. Executar todas as coletas em paralelo.

## 1. Tasks pendentes

Usar `TaskList` para listar tasks com status `todo` ou `in_progress`. Se não houver, mostrar "(sem tasks ativas)".

## 2. STATE.md dos projetos

Ler em paralelo:
- `/workspace/mnt/estrategia/monolito/STATE.md`
- `/workspace/mnt/estrategia/bo-container/STATE.md`
- `/workspace/mnt/estrategia/front-student/STATE.md`

Extrair apenas `## Posição atual` e `## Blockers` de cada um. Se o arquivo não existir: "(sem STATE.md)".

## 3. Histórico recente

Ler as últimas 15 linhas de `/workspace/mnt/claude-history.md`.

## 4. Branches ativas

Para cada repo, executar:

```bash
cd /workspace/mnt/estrategia/<repo> && HOME=/tmp git branch --show-current 2>/dev/null || echo "?"
```

Repos: monolito, bo-container, front-student.

## 5. Features em andamento

Listar pastas de feature ativas (padrão `FUK2-*/` ou `<JIRA-ID>/`) na raiz do workspace:

```bash
ls /workspace/mnt/estrategia/ 2>/dev/null | grep -E "^[A-Z]+-[0-9]+" || echo "(nenhuma)"
```

---

## Formato de saída

Apresentar como dashboard compacto. Usar separadores horizontais — sem bordas externas fixas:

```
── progress: workspace estrategia ──

Tasks ativas
  [status] descrição
  (ou: sem tasks ativas)

Repos
  monolito      branch: <branch-atual>
  bo-container  branch: <branch-atual>
  front-student branch: <branch-atual>

Estado dos repos
  monolito      → <posição atual do STATE.md>
  bo-container  → <posição atual do STATE.md>
  front-student → <posição atual do STATE.md>

Blockers
  monolito      → <blockers ou "nenhum">
  bo-container  → <blockers ou "nenhum">
  front-student → <blockers ou "nenhum">

Features em andamento
  <lista de pastas FUK2-* ou "nenhuma">

Histórico recente
  <últimas 5 entradas do claude-history.md>
```

Adaptar ao que existir — omitir seções vazias. Manter compacto.
