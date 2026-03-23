---
name: meta:feed
description: "Digest unificado: feeds RSS por categoria (linux, IA, tech) + digest de trabalho (Obsidian: contractors, tasks, inbox). Substitui meta:rss."
---

# meta:feed — Digest Unificado

```
/meta:feed               → digest completo (trabalho + todos os feeds)
/meta:feed linux         → só feeds linux/nix
/meta:feed ia            → só feeds IA/ML
/meta:feed estrategia    → digest de trabalho (Obsidian: contractors, tasks, inbox)
/meta:feed fetch         → forçar fetch dos feeds RSS
/meta:feed config        → editar feeds no SETTINGS.md
```

---

## Roteamento

| Argumento | Ação |
|-----------|------|
| vazio | digest completo: estratégia + linux + ia + tech |
| `linux` | só feeds tag:linux,nix |
| `ia` | só feeds tag:ia,ml,llm |
| `estrategia` | só digest de trabalho (Obsidian) |
| `fetch` | forçar rss-fetcher e mostrar resultado |
| `config` | listar e editar feeds no SETTINGS.md |

---

## Digest de Trabalho — `estrategia`

Coletar em paralelo:

### Inbox dos contractors
```bash
tail -50 /workspace/obsidian/inbox/feed.md 2>/dev/null
ls /workspace/obsidian/inbox/ALERTA_*.md 2>/dev/null
```

### Tasks ativas e pendentes
```bash
ls /workspace/obsidian/tasks/DOING/ 2>/dev/null
ls /workspace/obsidian/tasks/AGENTS/ 2>/dev/null | wc -l
ls -t /workspace/obsidian/bedrooms/*/done/ 2>/dev/null | head -5
```

### Outputs recentes de contractors (últimas 24h)
```bash
find /workspace/obsidian/contractors/*/outputs/ -newer /tmp/feed_24h_mark -name "*.md" 2>/dev/null \
  || find /workspace/obsidian/contractors/*/outputs/ -mtime -1 -name "*.md" 2>/dev/null
```
Para cada output encontrado: ler primeiras 15 linhas e sumarizar.

### Outbox pendente (aguardando hermes)
```bash
ls /workspace/obsidian/outbox/ 2>/dev/null
```

### Formato de saída
```
── Trabalho (estratégia) ──────────────────────────

 Inbox contractors (últimas mensagens)
  [HH:MM] [contractor] mensagem

 Alertas
  ALERTA_xxx: título

 Tasks
  DOING: nome-da-task
  TODO: N na fila | Concluídas hoje: N

 Outputs recentes
  contractor/outputs/arquivo.md — resumo 1 linha

 Outbox pendente
  N items aguardando hermes
```

---

## Feeds RSS — `linux`, `ia`, default

### Carregar digest atual
```bash
cat /workspace/obsidian/FEED.md 2>/dev/null
```
Mostrar idade do último fetch e total de items.

### Filtrar por tag
- `linux` → items com tag `linux` ou `nix`
- `ia` → items com tag `ia`, `ml`, `llm`, `ai`
- sem argumento → todos os items

### Formato de saída
```
── Feeds [categoria] ──────────────────────────────

  [tech]  Título do item — fonte (Hh atrás)
  [linux] Título do item — NixOS Weekly (2d atrás)
  [ia]    Título do item — fonte (30min atrás)

  Atualizado: HH:MM | N items | Próximo fetch: HH:MM
```

---

## fetch — Forçar atualização RSS

```bash
python3 /workspace/mnt/self/scripts/rss-fetcher.py \
  --config /workspace/obsidian/SETTINGS.md \
  --data /workspace/obsidian/.ephemeral/rss/items.json \
  --dashboard /workspace/obsidian/.ephemeral/rss/dashboard.txt \
  --vault-feed /workspace/obsidian/FEED.md
```

Exibir: new/pruned/total/errors. Se sucesso, mostrar digest atualizado.

---

## config — Gerenciar feeds

Ler seção `## 6. Sistema FEED` do SETTINGS.md e exibir feeds ativos por categoria.

Para adicionar feed: editar SETTINGS.md diretamente na tabela de feeds.
Para desativar: remover linha da tabela.

Categorias de tags usadas:
- `linux`, `nix` — Linux/NixOS/open source
- `ia`, `ml`, `llm` — IA/ML/LLMs
- `tech`, `news` — tech geral
- `programming` — engenharia de software
