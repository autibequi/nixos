---
name: coruja
description: Skill composta da Coruja — cobre monolito (Go), bo-container (Vue/Quasar), front-student (Nuxt), orquestrador (cross-repo) e ferramentas globais da Estrategia. Indice principal: roteie para a sub-skill certa conforme o repo e a acao.
---

# Coruja — Skill Composta

Skill indice. Carregue as sub-skills conforme o repo e a acao solicitada.

## Sub-skills por repo

| Repo | Path no projeto | Indice | Sub-skills |
|---|---|---|---|
| **monolito** | `/home/claude/projects/estrategia/monolito` | `coruja/monolito/SKILL.md` | go-migration, go-repository, go-service, go-handler, go-worker, go-test, go-inspector, make-feature, pr-message |
| **bo-container** | `/home/claude/projects/estrategia/bo-container` | `coruja/bo-container/SKILL.md` | component, page, route, service, make-feature, inspector |
| **front-student** | `/home/claude/projects/estrategia/front-student` | `coruja/front-student/SKILL.md` | component, page, route, service, make-feature, inspector |
| **orquestrador** | (cross-repo coordinator) | `coruja/orquestrador/SKILL.md` | orquestrar-feature, retomar-feature, review-pr, pr-inspector, changelog, recommit, refinar-bug, doc-branch |

## Skills cross-repo (ferramentas globais)

| Skill | Quando usar |
|---|---|
| `coruja/platform-context` | Contexto compartilhado dos 3 repos (stacks, design system, multi-tenant, convencoes) |
| `coruja/glance` | Visao geral dos arquivos modificados nos 3 repos vs main |
| `coruja/grafana` | Logs Loki/CloudWatch, dashboards, debug pos-deploy |
| `coruja/jira` | Ler card Jira completo com custom fields |
| `coruja/opensearch` | Queries no cluster OpenSearch sandbox |
| `coruja/ecosystem-map` | Mapa de todos os 19 repos — stack, proposito, paths |

## Deteccao de repo

1. cwd sob `/home/claude/projects/estrategia/<repo>/` → repo identificado
2. `git remote get-url origin` contem `estrategiahq/<repo>`
3. User menciona nome do repo → ver tabela acima

## VCS — JJ First (todas as repos)

Ver `coruja/REGISTRY.md` → secao **JJ/Git Flow**.

**JJ é obrigatório em todos os repos.** Se repo ainda nao tem `.jj`:
```bash
jj git init --colocate   # inicializar jj no repo git existente — fazer isso primeiro
```

Operações de branch/worktree:
- Nova branch: `jj new main -m "FUK2-XXXXX: descricao"` + `jj bookmark create FUK2-XXXXX/descricao-curta`
- Trocar branch: `jj edit <bookmark>`
- Worktree paralelo: `jj workspace add ../path`
- Push: `jj git push --bookmark FUK2-XXXXX/descricao`

Nomenclatura obrigatoria: `FUK2-XXXXX/descricao-curta-em-kebab`

## Sandbox local

| Uso | URL |
|---|---|
| App (front) | `http://local.estrategia-sandbox.com.br` |
| Admin (BO) | `http://admin.local.estrategia-sandbox.com.br` |
| API (monolito) | `http://api.local.estrategia-sandbox.com.br` |
