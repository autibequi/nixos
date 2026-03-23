---
name: estrategia/registry
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
| monolito | /home/claude/projects/estrategia/monolito | `estrategia/monolito/` | go-service, go-handler, go-migration, go-repository, go-worker, go-test, go-inspector, make-feature |
| bo-container | /home/claude/projects/estrategia/bo-container | `estrategia/bo-container/` | service, route, component, page, make-feature, inspector |
| front-student | /home/claude/projects/estrategia/front-student | `estrategia/front-student/` | service, route, component, page, make-feature, inspector |
| orquestrador | (cross-repo coordinator) | `estrategia/orquestrador/` | orquestrar-feature, changelog, recommit, refinar-bug, retomar-feature, review-pr, doc-branch, pr-inspector |

## Skills Cross-repo (ferramentas globais)

| Skill | Path | Descricao |
|---|---|---|
| estrategia/platform-context | `estrategia/platform-context/` | Contexto compartilhado dos 3 repos (stacks, design system, multi-tenant, convencoes) |
| estrategia/glance | `estrategia/glance/` | Arvore visual dos arquivos modificados vs main nos 3 repos |
| estrategia/jira | `estrategia/jira/` | Ler card Jira completo com todos os campos — mapa de custom fields, chamada MCP correta, extracao ADF |
| estrategia/grafana | `estrategia/grafana/` | Query logs Loki e dashboards Grafana — servicos, patterns de debug, integracao com workflow |
| estrategia/opensearch | `estrategia/opensearch/` | Consultar cluster OpenSearch sandbox — mapeamento de indices, queries DSL, links Dev Console |

## Git Flow — Branch vs Worktree

### 1. Antes de qualquer implementacao: buscar trabalho existente

```bash
# Ver sessoes multi-repo abertas
leech wt

# Buscar pelo codigo Jira em branches locais e remotas
git branch -a | grep -i "<FUK2-XXXXX>"

# Verificar worktrees abertas de uma sessao
ls /workspace/mnt/worktree/ | grep -i "<FUK2-XXXXX>"
```

Se ja existir sessao → `leech wt FUK2-XXXXX` para ativar, nao criar novo.

### 2. Decidir: branch ou sessao multi-repo?

| Situacao | Usar |
|---|---|
| **Bug fix / correcao pontual** (~1-3 arquivos, 1 repo) | Branch simples: `git checkout -b FUK2-XXXXX/descricao-curta` |
| **Feature multi-repo** (toca monolito + bo/front) | Sessao: `leech wt new FUK2-XXXXX` |
| **Feature single-repo complexa** (migration, refactor multi-camada) | Sessao so nesse repo: `leech wt new FUK2-XXXXX` (skip outros na confirmacao) |

**Sessao `leech wt`** cria worktrees em `/workspace/mnt/worktree/FUK2-XXXXX/<repo>/`
para todos os repos da Estrategia. Ver skill `leech/worktree` para o fluxo completo.

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
1. Criar diretorio em `estrategia/<repo>/skills/<skill-name>/`
2. Cada SKILL.md deve ter `name: estrategia/<repo>/<skill-name>`
3. Agentes auto-descobrem skills em seu diretorio `skills/`
