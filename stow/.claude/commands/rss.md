# RSS — Gerenciador de feeds RSS

Controla feeds RSS do dashboard: listar, adicionar, remover, buscar, exibir.

## Entrada
- `$ARGUMENTS`: subcomando — `list`, `add <url> <categoria> [max]`, `remove <url_ou_indice>`, `fetch`, `show`, `config` — default: `show`

## Instruções

### Paths
- Config: `/workspace/stow/.claude/feeds.md`
- Fetcher: `/workspace/stow/.claude/scripts/rss-fetcher.py`
- Data: `/workspace/.ephemeral/rss/items.json`
- Dashboard: `/workspace/.ephemeral/rss/dashboard.txt`

### Subcomandos

#### `show` (default)
Exibir dashboard atual:
```bash
cat /workspace/.ephemeral/rss/dashboard.txt 2>/dev/null || echo "(vazio — rode /rss fetch)"
```
Mostrar idade do cache e total de items.

#### `list`
Ler `/workspace/stow/.claude/feeds.md` e exibir tabela formatada dos feeds configurados.

#### `add <url> <categoria> [max]`
Adicionar linha na tabela de feeds em `/workspace/stow/.claude/feeds.md`:
- `url`: URL do feed RSS/Atom
- `categoria`: tag curta (ex: `tech`, `go`, `nixos`, `security`)
- `max`: máximo de items por feed (default: 5)

Após adicionar, rodar fetch automaticamente.

#### `remove <url_ou_indice>`
Remover feed da tabela em `/workspace/stow/.claude/feeds.md`:
- Aceita URL parcial ou índice numérico (1-based)
- Confirmar antes de remover

#### `fetch`
Rodar o fetcher manualmente:
```bash
python3 /workspace/stow/.claude/scripts/rss-fetcher.py \
  --config /workspace/stow/.claude/feeds.md \
  --data /workspace/.ephemeral/rss/items.json \
  --dashboard /workspace/.ephemeral/rss/dashboard.txt
```
Exibir resultado (novos, podados, total, erros).

#### `config`
Exibir e permitir editar configs em `/workspace/stow/.claude/feeds.md`:
- `max_total_items`: máximo de items guardados
- `item_max_age_days`: dias antes de podar
- `dashboard_items`: quantos items no dashboard

### Formato de saída
- Usar tabela para `list`
- Usar output colorido do fetcher para `fetch`
- Dashboard em formato compacto para `show`
