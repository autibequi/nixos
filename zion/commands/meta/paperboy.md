# meta:paperboy — DEPRECATED

> **Paperboy foi aposentado.** Use `/meta:rss` para todas as operações de RSS.
> O wiseman agora gerencia feeds, digest e recomendações contextuais.

---

## Entrada
- `$ARGUMENTS`: subcomando — `show`, `status`, `prefs`, `fetch`, `config` — default: `show`

## Instrucoes

### Paths
- Config feeds: `/workspace/stow/.claude/feeds.md`
- Fetcher: `/workspace/stow/.claude/scripts/rss-fetcher.py`
- Data: `/workspace/.ephemeral/rss/items.json`
- Dashboard: `/workspace/.ephemeral/rss/dashboard.txt`
- Feed board: `/workspace/obsidian/FEED.md`
- Preferences: `/workspace/obsidian/vault/agents/paperboy/preferences.md`
- Memory: `/workspace/obsidian/vault/agents/paperboy/memory.md`

### Subcomandos

#### `show` (default)
Exibir digest atual do FEED.md (secao ## Digest). Mostrar idade do ultimo fetch.

#### `status`
Ler memory.md do paperboy e exibir:
- Ultimo fetch (quando, resultado)
- Feedbacks processados
- Preferencias atuais (resumo)

#### `prefs`
Exibir e permitir editar preferences.md:
- Adicionar/remover topicos em Priorizar
- Adicionar/remover topicos em Desprioritizar
- Ver stats de feedback

#### `fetch`
Forcar execucao do fetcher:
```bash
python3 /workspace/stow/.claude/scripts/rss-fetcher.py \
  --config /workspace/stow/.claude/feeds.md \
  --data /workspace/.ephemeral/rss/items.json \
  --dashboard /workspace/.ephemeral/rss/dashboard.txt \
  --vault-feed /workspace/obsidian/FEED.md
```
Exibir resultado e gerar novo digest.

#### `config`
Proxy para configuracao de feeds — mesmo que antigo `/rss config`.
Ler e editar `/workspace/stow/.claude/feeds.md`.
