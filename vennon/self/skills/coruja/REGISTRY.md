---
name: coruja/registry
description: Leia SEMPRE que for trabalhar num projeto da Estrategia. Contem mapeamento de repos, skills disponiveis, e como descobrir o repo certo.
---

# Estrategia — Registry de Skills e Repos

## Base Path
/home/claude/projects/estrategia/

## GitHub Org
estrategiahq

## Repos e Skills

| Repo | Repo Path | Skills Path | Skills Disponiveis |
|---|---|---|---|
| monolito | /home/claude/projects/estrategia/monolito | `coruja/monolito/` | go-service, go-handler, go-migration, go-repository, go-worker, go-test, go-inspector, make-feature |
| bo-container | /home/claude/projects/estrategia/bo-container | `coruja/bo-container/` | service, route, component, page, make-feature, inspector |
| front-student | /home/claude/projects/estrategia/front-student | `coruja/front-student/` | service, route, component, page, make-feature, inspector |
| orquestrador | (cross-repo coordinator) | `coruja/orquestrador/` | orquestrar-feature, changelog, recommit, refinar-bug, retomar-feature, review-pr, doc-branch, pr-inspector |

## Skills Cross-repo (ferramentas globais)

| Skill | Path | Descricao |
|---|---|---|
| coruja/ecosystem-map | `coruja/ecosystem-map/` | **Mapa de todos os 19 repos** — stack, proposito, paths e tabela de pistas-para-repo. Usar quando o bug/feature envolve repos fora do trio monolito/bo/front-student. |
| coruja/platform-context | `coruja/platform-context/` | Contexto compartilhado dos 3 repos principais (stacks, design system, multi-tenant, convencoes) |
| coruja/glance | `coruja/glance/` | Arvore visual dos arquivos modificados vs main nos 3 repos |
| coruja/jira | `coruja/jira/` | Ler card Jira completo com todos os campos — mapa de custom fields, chamada MCP correta, extracao ADF |
| coruja/grafana | `coruja/grafana/` | Query logs Loki e dashboards Grafana — servicos, patterns de debug, integracao com workflow |
| coruja/opensearch | `coruja/opensearch/` | Consultar cluster OpenSearch sandbox — mapeamento de indices, queries DSL, links Dev Console |

## JJ Flow

> Todos os 3 repos já têm jj colocated (`.jj/` + `.git/`). Nenhum setup necessário.
> Mesmo bookmark name nos 3 repos — features são sempre full-stack.

### 1. Buscar trabalho existente

```bash
for repo in monolito bo-container front-student; do
  echo "=== $repo ===" && jj -R /workspace/projects/estrategia/$repo bookmark list | grep -i "<FUK2-XXXXX>"
done
```

Se ja existir bookmark → `jj edit <bookmark>`, nao criar novo.

### 2. Criar bookmark (mesmo nome nos 3)

```bash
for repo in monolito bo-container front-student; do
  cd /workspace/projects/estrategia/$repo
  jj git fetch
  jj new main -m "FUK2-XXXXX: descricao-curta"
  jj bookmark create FUK2-XXXXX/descricao-curta
done
```

Para bug fix pontual (1 repo só): mesmo fluxo, sem o loop.

### 3. Nomenclatura obrigatoria

Sempre prefixar com o codigo Jira: **`FUK2-XXXXX/descricao-curta-em-kebab`**

Valido para todos os repos: monolito, bo-container, front-student.

---

## Sandbox local (testes)

| Uso | URL completa |
|-----|--------------|
| **App principal (front)** | http://local.estrategia-sandbox.com.br |
| **App principal (porta 3005)** | http://local.estrategia-sandbox.com.br:3005/ |
| **Admin (BO)** | http://admin.local.estrategia-sandbox.com.br |
| **API (monolito)** | http://api.local.estrategia-sandbox.com.br |

## Deteccao de Repo
1. Se cwd esta sob /home/claude/projects/estrategia/<repo>/ → repo identificado
2. `git remote get-url origin` contem `estrategiahq/<repo>`
3. User menciona nome do repo → consultar tabela acima

## Adicionando Novo Repo/Skill
1. Criar diretorio em `coruja/<repo>/skills/<skill-name>/`
2. Cada SKILL.md deve ter `name: coruja/<repo>/<skill-name>`
3. Agentes auto-descobrem skills em seu diretorio `skills/`
