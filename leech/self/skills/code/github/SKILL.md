---
name: code/github
description: "Operações GitHub — buscar PRs, comentários, diffs, reviews. Token sempre de ~/.leech. Comentários = ativos por default."
---

# code/github — Operações GitHub

Skill para interagir com GitHub via CLI (`gh`). Padrões, tokens, e convenções.

## Regra Crítica #1: Token sempre de ~/.leech

**SEMPRE** buscar o token de autenticação do arquivo `~/.leech`:

```bash
export GH_TOKEN=$(grep '^GH_TOKEN=' ~/.leech | cut -d'=' -f2)
gh pr view <number> --repo <owner>/<repo> --json title,body,comments
```

Não hardcode tokens. Não assume `$GH_TOKEN` já está setado. Leia sempre do arquivo `.leech` na primeira operação.

Se `.leech` nao existir, pedir ao user para configurar:
```bash
gh auth login
```

## Regra Crítica #2: Comentários = Ativos

Quando o user pede "comentários", significa **comentários ativos** (nao resolvidos):

- Abrir = não foi respondido ainda
- Fechado/resolvido = não incluir

Usar `--json` para filtrar:
```bash
gh pr view <number> --repo <owner>/<repo> --json comments
```

Os comentários retornam com status `isMinimized` e `minimizedReason`. **Não incluir minimizados** (spam, conversas off-topic) na resposta ao user.

**Resposta padrão:** quando user pede comentários, trazer:
1. Autor
2. Data
3. Texto completo
4. Reações (se houver)
5. Status (ativo, mínimizado, etc)

Exemplo:
```
Author: @coderabbitai
Date:   2026-03-26 13:29:43Z
Status: Active (Draft review skipped)

Body:
---
Review skipped — Draft detected. Dispare @coderabbitai review...
```

## Padrões de Comando

### Listar PRs
```bash
export GH_TOKEN=$(grep '^GH_TOKEN=' ~/.leech | cut -d'=' -f2)
gh pr list --repo <owner>/<repo> --state merged --author <username> --limit 10 \
  --json number,title,additions,deletions,changedFiles,createdAt,mergedAt
```

### Ler PR com comentários ativos
```bash
gh pr view <number> --repo <owner>/<repo> --json title,body,comments
```

Filtrar no output:
- Excluir `isMinimized: true`
- Excluir bot comments (a menos que requestado)
- Manter ordem cronológica

### Ler diff
```bash
gh pr diff <number> --repo <owner>/<repo>
```

Opcionalmente excluir vendored files:
```bash
gh pr diff <number> --repo <owner>/<repo> -- ':!vendor' ':!go.sum' ':!*.lock' ':!package-lock.json'
```

### Ler reviews (aprovações/mudanças solicitadas)
```bash
gh pr view <number> --repo <owner>/<repo> --json reviews
```

### Ler comentários deixados por um dev em PRs de outros
```bash
gh api "/repos/<owner>/<repo>/pulls/comments?sort=created&direction=desc&per_page=100" | \
  jq '[.[] | select(.user.login == "<username>")]'
```

## Resposta ao User

Sempre estruturar assim ao retornar comentários:

```
╭──[ PR #<num> — <titulo> ]──────────┬─────┐
│                                     │ 🔵  │  [status]
│ <X comentarios ativos>              │     │
│                                     └─────┘
├──────────────────────────────────────────┤

Comentário 1 (ativo)
├─ Autor: @usuario
├─ Data: 2026-03-26 14:30:00Z
└─ Texto:
   "Seu comentário aqui..."

Comentário 2 (ativo)
├─ Autor: @outro
├─ Data: 2026-03-26 15:00:00Z
└─ Texto:
   "Resposta dele..."

(Total: X ativos | Y mínimizados)
```

## Convenções de Status

- 🔵 **Aberto** — Aguardando ação
- 🟢 **Merged** — Já integrado
- 🔴 **Closed** — Rejeitado sem merge
- ⚪ **Draft** — Trabalho em progresso
- ⚙️ **Checks** — CI rodando

## Troubleshooting

**GraphQL: Resource not accessible by personal access token**
→ Token nao tem escopo suficiente. Checar `/workspace/self/skills/code/github-evaluate/SKILL.md` para o escopo mínimo recomendado.

**404 Not Found**
→ Repo pode ser privado ou nao existe. Verificar permissoes do token + URL do repo.

**No comments returned**
→ Pode estar tudo minimizado ou resolvido. Usar `--json comments` puro pra debug (nao filtra).

---

## Integração com Skills

Esta skill é chamada por:
- `code/github-evaluate` — pra coletar PRs e reviews de um dev
- `code/review` — pra ler comentários antes de responder

Ao integrar, sempre incluir a seção "Regra Crítica #1" no prompt do agente.
