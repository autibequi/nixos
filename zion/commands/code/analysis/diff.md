# Diff — Árvore Interativa de Arquivos no Chrome

Gera árvore interativa de diff (pastas colapsáveis, ancestor glow, copy path, path bar sticky) e abre no Chrome via relay. Tema Catppuccin Mocha dark.

## Entrada
- `$ARGUMENTS`: `[--repos monolito|bo|front|all] [--compare origin/main] [--by-layer]`

## Instruções

Ler o skill completo e seguir o processo:

```
Skill: code/analysis/diff
```

Argumentos passados: `$ARGUMENTS`

## Regras obrigatórias

1. **Sempre usar o template interativo** — `templates/generator_by_layer.py` (padrão) ou `templates/generator.py` (flat). Nunca usar difftree.py nem ANSI plain text.
2. **Sempre apresentar via relay** — salvar em `/tmp/chrome-relay/diff.html` e navegar com `python3 /workspace/zion/scripts/chrome-relay.py nav "http://zion:8766/diff.html"`.
3. **Para o monolito, o padrão é sempre `generator_by_layer.py`** com camadas Handlers / Services / Repositories / Workers/SQS / Outros — a menos que o usuário peça explicitamente outra coisa (flat, só uma camada, etc.).
