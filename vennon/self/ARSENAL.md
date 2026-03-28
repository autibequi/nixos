---
name: ARSENAL
description: Índice completo de capacidades, ferramentas, skills, commands e agentes — autoridade única
type: reference
updated: 2026-03-26T02:47Z
---

# ARSENAL — Capacidades Completas

> Índice compilado de TUDO que posso fazer em uma sessão.
> Autoridade única — remova duplicatas em outros arquivos que referenciem isto.
> Injetar no boot assim como RULES.md é injetado.

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
- `/meta:rules` — regras do sistema Leech (Lei 1-11, scheduling, territorios)

#### Meta Tools
- `/meta:relay` — controle Chrome via CDP (nav, show, tabs, speak, present)
- `/meta:webview` — renderizar URL (Chrome relay ou WebFetch)
- `/meta:cleanup` — revisão e limpeza de sessão
- `/meta:envs` — lista ~/.leech flags (tokens mascarados, semáforos visíveis)

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

### leech/* — Sistema & Infraestrutura
- **leech:upgrade** — implementa features do Leech (Rust-only)
- **leech:worktree** — sistema de worktrees multi-repo
- **leech:healthcheck** — health checks + diagnóstico
- **leech:linux** — NixOS, Hyprland, dotfiles
- **leech:container** — Docker infrastructure, services

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

### thinking/* — Protocolo de Raciocínio (auto-aplicável em Haiku)
- **thinking:lite** — meta-classificação, CoD, Turbo mode, Step-Back, AAV
- **thinking:investigate** — versão lite (3-5 turns)
- **thinking:brainstorm** — ideação
- **thinking:refine** — quebra em tasks atômicas
- **thinking:proactive** — oportunidades top-3

---

## Agentes em Background (11 ativos)

| Nome | Clock | Modelo | Função | Bedroom |
|------|-------|--------|--------|---------|
| **hermes** | 10m | haiku | inbox/outbox, mensageiro, quota | `bedrooms/hermes/` |
| **tamagochi** | 10m | haiku | pet virtual, vagueia, diário | `bedrooms/tamagochi/` |
| **keeper** | 30m | haiku | saúde sistema, limpeza, vault | `bedrooms/keeper/` |
| **assistant** | 20m | haiku | repos, PRs, tasks, alertas | `bedrooms/assistant/` |
| **coruja** | 60m | sonnet | monolito, bo, front, Jira, GitHub | `bedrooms/coruja/` + `workshop/coruja/` |
| **paperboy** | 60m | haiku | feeds RSS por categoria | `bedrooms/paperboy/` |
| **wanderer** | 60m | sonnet | explora código, contempla | `bedrooms/wanderer/` |
| **wiseman** | 60m | sonnet | knowledge weaving, auditoria | `bedrooms/wiseman/` |
| **jafar** | 120m | sonnet | meta-agente, propostas, introspecção | `bedrooms/jafar/` |
| **mechanic** | on-demand | sonnet | NixOS, Docker, segurança, debug | (ad-hoc) |
| **placeholder** | on-demand | haiku | tasks genéricas bem definidas | (ad-hoc) |

**CLI:** `yaa agents` | `yaa agents run <nome>` | `yaa agents status` | `/meta:phone call <nome>`

---

## Capacidades Implícitas (não óbvias)

### Memória Persistente
- 40+ memórias em `/workspace/.claude/projects/-workspace-mnt/memory/`
- Tipos: user, feedback, project, reference
- Consultáveis, atualizáveis em qualquer sessão
- Sinc com git: `cp ~/.claude/.../memory/*.md /workspace/home/self/system/memory/`

### Nix Como Superpoder
- No container: `nix-shell -p <pkg> --run "<cmd>"`
- Instalo qualquer pacote sem pedir permissão
- Sem limite de escopo (compiladores, ferramentas, linguagens)

### Chrome via CDP
- `/meta:relay` controla browser do user
- Navego, renderizo, injeto JS, captura screenshots
- Útil para outputs grandes/interativos que precisam render real

### MCP Integrado
- Acesso direto a Jira, Confluence, Notion
- Criar issues, comentar, buscar sem sair da conversa
- LEITURA sempre OK; escrita requer permissão explícita

### Voz Proativa
- Permissão para usar espeak-ng proativamente (não pedir)
- Defaults: pt-br, 175wpm, pitch 40
- Script: `~/.claude/scripts/glados-speak.sh`

### Plan Mode
- Antes de qualquer implementação complexa: EnterPlanMode
- Alinhar abordagem antes de executar
- ExitPlanMode aprova plano + autoriza

### Tasks Assíncronas
- TaskCreate/Update para trabalho em background
- Útil para tarefas longas sem supervisão
- TaskOutput recupera resultado quando pronto

### Worktrees Isolados
- EnterWorktree cria branch isolado em `.claude/worktrees/`
- Obrigatório para implementações não-triviais
- ExitWorktree com keep/remove

---

## Limitações Honestas

- **Sem autocommit** — autocommit=OFF. Nunca commito sem você pedir explicitamente.
- **Sem acesso ao host** — in_docker=1. Não posso rodar `nixos-rebuild`, `systemctl` fora do container.
- **Deferred tools** — algumas ferramentas precisam de ToolSearch antes de usar; se travar, isso pode ser a causa.
- **Contexto tem limite** — sessões muito longas perdem qualidade. Use `/meta:context:analysis` pra monitorar.
- **Memórias podem estar desatualizadas** — refletem última sessão. Se algo parecer errado, questione.
- **Não posso editar CLAUDE.md** — sugiro via inbox. Pedro edita.

---

## Quick Reference

| Preciso de... | Uso... |
|---|---|
| Analisar código | `/code` ou `/code:análise` |
| Debugar algo | `/thinking investigate` ou `code:debug` |
| Ideias criativas | `/thinking brainstorm` |
| Refinar em tasks | `/thinking refine` |
| Entender o sistema | `/meta:self` ou `/meta:rules` |
| Monitorar context | `/meta:context:analysis` |
| Falar com agente X | `/meta:phone call <nome>` |
| Renderizar algo grande | `/meta:relay` |
| Criar/atualizar PR | `/commit-push-pr` ou `/review-pr` |
| NixOS/host | `/leech:linux` (com `--host`) |
| Criar feature | `/feature-dev` (com worktree) |
| Limpar branches | `/clean_gone` |

---

**Nota:** Este arquivo é autoridade única. Remova listas duplicadas em RULES.md, LITE.md, INIT.md, etc. que referenciem skills/commands. Apontem pra cá.
