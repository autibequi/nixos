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

| Repo | Repo Path | Agent | Skills Path | Skills Disponiveis |
|---|---|---|---|---|
| monolito | /home/claude/projects/estrategia/monolito | `stow/.claude/agents/monolito/` | `stow/.claude/agents/monolito/skills/` | go-service, go-handler, go-migration, go-repository, go-worker, make-feature, review-code |
| bo-container | /home/claude/projects/estrategia/bo-container | `stow/.claude/agents/bo-container/` | `stow/.claude/agents/bo-container/skills/` | service, route, component, page, make-feature |
| front-student | /home/claude/projects/estrategia/front-student | `stow/.claude/agents/front-student/` | `stow/.claude/agents/front-student/skills/` | service, route, component, page, make-feature |
| orquestrador | (cross-repo coordinator) | `stow/.claude/agents/orquestrador/` | `stow/.claude/agents/orquestrador/skills/` | orquestrar-feature, changelog, recommit, refinar-bug, retomar-feature, review-pr, doc-branch |

## Skills Globais (cross-repo)

| Skill | Path | Descrição |
|---|---|---|
| estrategia/jira | `~/.claude/skills/estrategia/jira/` | Ler card Jira completo com todos os campos — mapa de custom fields, chamada MCP correta, extração ADF |
| estrategia/grafana | `~/.claude/skills/estrategia/grafana/` | Query logs Loki e dashboards Grafana — serviços, patterns de debug, integração com workflow |
| estrategia/opensearch | `~/.claude/skills/estrategia/opensearch/` | Consultar cluster OpenSearch sandbox — mapeamento de índices, queries DSL, links Dev Console |

## Sandbox local (testes)

**Referência:** usar sempre estes domínios quando rodar sandbox localmente para testes.

| Uso | URL completa |
|-----|--------------|
| **App principal (front)** | http://local.estrategia-sandbox.com.br |
| **App principal (porta 3005)** | http://local.estrategia-sandbox.com.br:3005/ |
| **Admin (BO)** | http://admin.local.estrategia-sandbox.com.br |
| **API (monolito)** | http://api.local.estrategia-sandbox.com.br |

Ao documentar fluxos, exemplos de curl ou links para o usuário testar, preferir esses URLs.

## Deteccao de Repo
1. Se cwd esta sob /home/claude/projects/estrategia/<repo>/ → repo identificado
2. `git remote get-url origin` contem `estrategiahq/<repo>`
3. User menciona nome do repo → consultar tabela acima

## Adicionando Novo Repo/Skill
1. Criar diretorio em `stow/.claude/agents/<repo>/skills/<skill-name>/`
2. Cada SKILL.md deve ter `name: <repo>/<skill-name>`
3. Agentes auto-descobrem skills em seu diretorio `skills/`
