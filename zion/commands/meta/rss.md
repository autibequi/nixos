---
name: meta:rss
description: "RSS — ver digest, forcar fetch, editar preferencias e feeds. Plumbing do sistema de noticias."
---

# meta:rss — RSS Feed Manager

## Uso

```
/meta:rss [show|fetch|prefs|config]
```

Default: `show`

---

## Paths

- Fetcher:     `/workspace/mnt/zion/scripts/rss-fetcher.py`
- Config:      `/workspace/obsidian/SETTINGS.md` (seção feeds)
- Data:        `/workspace/obsidian/.ephemeral/rss/items.json`
- Dashboard:   `/workspace/obsidian/.ephemeral/rss/dashboard.txt`
- Feed board:  `/workspace/obsidian/FEED.md`
- Preferências: `/workspace/obsidian/vault/contractors/wiseman/rss-preferences.md`

---

## Subcomandos

### `show` (default)

Exibir o digest atual do `FEED.md` (seção `## Digest`). Mostrar idade do último fetch e total de items disponíveis.

### `fetch`

Forçar execução do fetcher:

```bash
python3 /workspace/mnt/zion/scripts/rss-fetcher.py \
  --config /workspace/obsidian/SETTINGS.md \
  --data /workspace/obsidian/.ephemeral/rss/items.json \
  --dashboard /workspace/obsidian/.ephemeral/rss/dashboard.txt \
  --vault-feed /workspace/obsidian/FEED.md
```

Exibir resultado (new/pruned/total/errors). Se sucesso, gerar novo digest inline.

### `prefs`

Ler e editar `rss-preferences.md` do wiseman:
- Adicionar/remover tópicos em Priorizar
- Adicionar/remover tópicos em Desprioritizar
- Ver stats de feedback acumulado
- Marcar `#mais` ou `#menos` em items do FEED.md para calibrar

### `config`

Ler e editar a seção de feeds do `SETTINGS.md`. Listar feeds ativos, adicionar novo feed, desativar feed.
