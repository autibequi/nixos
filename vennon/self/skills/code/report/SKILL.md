---
name: code/report
description: Relatório consolidado da branch atual — combina objects (objetos por camada) + contagem de adições/remoções + resumo narrativo em português. Saída em terminal, Chrome ou Obsidian. Use ao final de uma feature para documentar o que foi feito.
---

# code/report — Relatório Consolidado da Branch

## Argumentos

```
/code:report [--branch auto|<nome>] [--format terminal|chrome|obsidian]
```

Defaults: `--branch auto` (detecta branch atual), `--format terminal`

## Processo

### Passo 1 — Detectar branch

```bash
# Para cada repo
cd /workspace/mnt/estrategia/<repo>/
HOME=/tmp git branch --show-current
```

### Passo 2 — Executar code/analysis/objects internamente

Rodar a lógica de `code/analysis/objects` para cada repo (all) e coletar a estrutura categorizada.

### Passo 3 — Calcular stats por repo

```bash
git diff origin/main --shortstat
# → X files changed, Y insertions(+), Z deletions(-)
```

### Passo 4 — Gerar resumo narrativo

Com base nos arquivos tocados, gerar um parágrafo em português descrevendo:
- O que foi implementado (endpoint novo, cache, worker, etc.)
- Quais repos foram tocados
- Quantos arquivos novos vs modificados

Exemplo:
```
Esta branch adiciona suporte a TOC cacheado no endpoint BFF `/toc`, implementando
cache em JSONB com rebuild assíncrono via SQS. Foram criados 3 novos handlers no
monolito, 1 worker e 2 serviços. No front-student, os composables `Course.js` e
`ContentAccessWatcher.js` foram adaptados para consumir o novo formato com toggle
de feature `ldi_cached_toc`.
```

### Passo 5 — Formatar saída

#### Format: terminal

```
╔══════════════════════════════════════════════════╗
║  REPORT  branch-name          2026-03-20         ║
╚══════════════════════════════════════════════════╝

  monolito     +8 A  ~3 M  |  11 files
  bo-container +2 A  ~1 M  |   3 files
  front-student +0 A ~6 M  |   6 files

──────────────────────────────────────────────────
  O que mudou
──────────────────────────────────────────────────

  <resumo narrativo>

──────────────────────────────────────────────────
  Objetos por camada
──────────────────────────────────────────────────

  <output de code/analysis/objects>
```

#### Format: chrome

Encapsular em HTML dark Catppuccin e abrir via:
```bash
python3 /workspace/self/scripts/chrome-relay.py nav "data:text/html;base64,<BASE64>"
```

#### Format: obsidian

Salvar em `/workspace/obsidian/vault/tasks/report-<branch>/report.md`:

```markdown
# Report: <branch-name>

**Data:** 2026-03-20
**Branch:** <branch-name>

## Resumo

<resumo narrativo>

## Stats

| Repo | Novos | Modificados | Total |
|---|---|---|---|
| monolito | 8 | 3 | 11 |
| bo-container | 2 | 1 | 3 |
| front-student | 0 | 6 | 6 |

## Objetos por Camada

<output de code/analysis/objects em markdown>
```
