---
name: ARSENAL
description: Índice completo de capacidades, ferramentas, skills, commands e agentes — autoridade única
type: reference
updated: 2026-03-26T02:47Z
---

# ARSENAL — Capacidades Completas

> Índice compilado de TUDO que posso fazer em uma sessão.
> Autoridade única — remova duplicatas em outros arquivos que referenciem isto.
> Injetar no boot junto com `self/superego/leis.md`.

---

## Ferramentas Nativas (sempre disponíveis)

### Arquivos
- **Read** — lê arquivo completo ou com offset/limit; suporta images, PDFs, notebooks
- **Write** — cria arquivo novo (não sobrescreve sem Edit antes)
- **Edit** — edita trecho específico com busca exata; melhor que sed
- **Glob** — busca arquivos por padrão (`**/*.md`, `apps/**/handlers/`); resultado ordenado
- **Grep** — busca conteúdo em arquivos com regex; suporta contexto (-B/-C/-A)

### Execução
- **Bash** — shell commands (+ Nix: `nix-shell -p <pkg> --run "<cmd>"`)
- **Agent** — spawna subagente com contexto isolado (type: general-purpose, Explore, Plan, etc.)

### Web
- **WebFetch** — acessa URL e processa conteúdo com LLM
- **WebSearch** — busca na web (US only)

### Tarefas & Planejamento
- **TaskCreate** — cria task com descrição e activeForm
- **TaskUpdate** — muda status, owner, dependencies (blockedBy/addBlocks)
- **TaskGet** — recupera task por ID com contexto completo
- **TaskList** — lista todas as tasks com status e bloqueadores
- **TaskStop** — encerra task em background
- **TaskOutput** — recupera output de task em background (block=true aguarda)

### Git & Repositórios
- **EnterPlanMode** — modo de planejamento estruturado antes de implementar
- **ExitPlanMode** — aprova plano e autoriza implementação
- **EnterWorktree** — cria branch isolado em `.claude/worktrees/` (opcional, perguntar ao user)
- **ExitWorktree** — sai de worktree (keep/remove)

### MCP Tools (via tool schema)
- **Jira** — getJiraIssue, editJiraIssue, createJiraIssue, transitionJiraIssue, searchJiraIssuesUsingJql
- **Confluence** — getConfluencePage, createConfluencePage, updateConfluencePage, searchConfluenceUsingCql
- **Notion** — notion-fetch, notion-search, notion-create-pages, notion-update-page, notion-create-database
- **Atlassian** — searchAtlassian, fetchAtlassian (unified Jira + Confluence)

### Sistema
- **Skill** — invoca skill por nome (e.g., `/thinking`, `/code`, `/meta:self`)
- **AskUserQuestion** — pergunta ao user quando há ambiguidade real

---

## Commands (entrada principal)

### /code — Análise de Código
Análise de diff, camadas, fluxo de dados, qualidade. Subcommands:
- `diff` — diff interativo
- `layers` — objetos por camada (handler→service→repo)
- `flow` — diagrama de fluxo
- `report` — relatório consolidado
- `inspect` — inspeção de qualidade

### /meta:* — Sistema & Auto-Conhecimento

#### Meta Core
- `/meta:self` — quem sou, módulos ativos, ferramentas, skills, agentes, capacidades
- `/meta:absorb` — cristalizar sessão / roubar projetos externos
- `/meta:lab` — modo laboratório (experimentos isolados)

#### Meta Contexto
- `/meta:context:analysis` — breakdown de tokens + 10 seções (velocidade, qualidade, padrões, heat map)
- `/meta:context:usage` — relatório de abuso + dicas personalizadas + diagnóstico boot
- `/meta:context:contemplate` — síntese estratégica (sinais, gaps, roadmap)
- `/meta:context:boot-debug` — debug pipeline de boot (o que carregou, lazy-loads, recomendações)

#### Meta Social
- `/meta:phone` — central dos 11 agentes (briefing, call direto, dashboard de worktrees)
- `/meta:feed` — digest unificado (RSS por categoria + Obsidian: contractors, tasks, inbox)
- `/meta:tamagochi` — interagir com pet virtual
- `/meta:rules` — regras do sistema Vennon (Lei 1-11, scheduling, territorios)

#### Meta Tools
- `/meta:relay` — controle Chrome via CDP (nav, show, tabs, speak, present)
- `/meta:webview` — renderizar URL (Chrome relay ou WebFetch)
- `/meta:cleanup` — revisão e limpeza de sessão
- `/meta:envs` — lista ~/.vennon flags (tokens mascarados, semáforos visíveis)

### /commit — Git
Criar commit com mensagem interativa. Segue conventional commits.

### /commit-push-pr — Git Workflow
Commit + push + abrir PR automaticamente.

### /review-pr — PR Review
Review especializado usando agentes (5 perspectivas de devs reais).

### /feature-dev — Guided Development
Desenvolvimento guiado de feature (worktree, arquitetura, testes).

### /clean_gone — Git Cleanup
Remove branches locais marcadas como [gone] no remoto.

---

## Skills Compostas (por namespace)

### code/* — Análise & Desenvolvimento
- **code:analysis** — diff, camadas, fluxo, objetos
  - sub: `diff/`, `flows/`, `objects/`, `componentes/`
- **code:debug** — investigação e debugging
- **code:goodpractices** — boas práticas (auto-ativa)
- **code:inspection** — inspeção estrutural
- **code:review** — peer review especializado
- **code:report** — relatórios consolidados
- **code:tdd** — test-driven development
- **code:flutter** — Flutter específico
- **code:github-evaluate** — avalia estado de repos/PRs

### coruja/* — Estratégia (Go/Vue/Nuxt)
- **coruja:glance** — árvore cyberpunk cross-repo vs main
- **coruja:ecosystem-map** — mapa de ecosistema estratégia
- **coruja:monolito** — Go handlers, services, migrations, tests, workers
  - sub: `go-handler/`, `go-service/`, `go-migration/`, `go-repository/`, `go-test/`, `go-worker/`, `make-feature/`
- **coruja:bo-container** — Vue/Quasar
  - sub: `component/`, `inspector/`, `make-feature/`, `page/`, `route/`, `service/`
- **coruja:front-student** — Nuxt
  - sub: `component/`, `inspector/`, `make-feature/`, `page/`, `route/`, `service/`
- **coruja:orquestrador** — cross-repo workflow
  - sub: `changelog/`, `doc-branch/`, `orquestrar-feature/`, `pr-inspector/`, `recommit/`, `refinar-bug/`, `retomar-feature/`, `review-pr/`
- **coruja:jira** — Jira workflow (refinement)
- **coruja:opensearch** — OpenSearch queries

### vennon/* — Sistema & Infraestrutura
- **vennon:upgrade** — implementa features do vennon (Rust-only)
- **vennon:worktree** — sistema de worktrees multi-repo
- **vennon:healthcheck** — health checks + diagnóstico
- **vennon:linux** — NixOS, Hyprland, dotfiles
- **vennon:container** — Docker infrastructure, services

### meta/* — Meta-Ferramentas
- **meta:art** — visual e relay
  - sub: `relay/`, `index/`, `ascii/`, `design-system/`, `webview/`, `chrome/`
- **meta:humanize** — torna textos naturais (remove padrões de IA)
- **meta:obsidian** — operações no vault
  - sub: `board/`, `agentroom/`, `graph/`, `dataview/`
- **meta:rules** — regras do sistema (Lei 1-11, territorios, scheduling, spaces)
  - sub: `laws/`, `agentroom/`, `scheduling/`, `map/`, `bedrooms/`, `spaces/`, `worktrees/`
- **meta:skill** — sobre skills
  - sub: `explain/` (flowchart Mermaid), `evolve/`
- **meta:orchestrator** — orquestrador de projeto autonomo (astroboy pipeline)
  - SCAN→ASSESS→DISPATCH→GATE→CLEANUP→REPORT→RESCHEDULE
  - Ativar quando card tem `#orquestrador` no DASHBOARD

### thinking/* — Protocolo de Raciocínio (auto-aplicável em Haiku)
- **thinking:lite** — meta-classificação, CoD, Turbo mode, Step-Back, AAV
- **thinking:investigate** — versão lite (3-5 turns)
- **thinking:brainstorm** — ideação
- **thinking:refine** — quebra em tasks atômicas
- **thinking:proactive** — oportunidades top-3

---

## Agentes

Ver `self/AGENT.md` para regras completas e `self/superego/README.md` para indice das regras do sistema.

CLI: `yaa agents` | `yaa agents run <nome>` | `/meta:phone call <nome>`

---

## Quick Reference

| Preciso de... | Uso... |
|---|---|
| Analisar codigo | `/code` |
| Debugar | `/thinking investigate` ou `code:debug` |
| Ideias | `/thinking brainstorm` |
| Entender sistema | `/meta:self` ou `/meta:rules` |
| Context tokens | `/meta:context:analysis` |
| Falar com agente | `/meta:phone call <nome>` |
| Renderizar | `/meta:relay` |
| PR workflow | `/commit-push-pr` ou `/review-pr` |
| NixOS/host | `/vennon:linux` |
| Feature guiada | `/feature-dev` |
| Limpar branches | `/clean_gone` |

---

## Limitacoes

- **Sem autocommit** — nunca commita sem pedir
- **Sem acesso ao host** — in_docker=1
- **Deferred tools** — precisam de ToolSearch antes
- **Contexto tem limite** — `/meta:context:analysis` pra monitorar
