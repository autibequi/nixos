# Manual do Sistema Leech — self/

> Mapa completo da estrutura, responsabilidade de cada arquivo e como tudo se conecta.

---

## Visao Geral

`/workspace/self/` e o **engine** do Leech — contem tudo que define como o Claude opera:
skills, hooks, agentes, scripts, personas e configuracao. No host vive em `~/nixos/self/`.

---

## Docs Core (raiz)

5 documentos que definem o sistema. Cada um tem um papel unico — sem overlap.

| Arquivo | Responsabilidade | Quando ler |
|---------|-----------------|------------|
| **SYSTEM.md** | Ambiente: paths, CLI (yaa/vennon/deck), ~/.leech flags, glossario, vault structure, cota API | Boot, orientacao basica |
| **AGENT.md** | Regras de agente: 11 leis, DASHBOARD protocol, ciclo autonomo (acordar→executar→finalizar→reagendar) | Inicio de qualquer ciclo de agente |
| **PERSONA.md** | Identidade: pointer pra persona ativa, identidade (Claudinho/Buchecha), papel, iniciativa, auto-evolucao, diario | Boot (injetado se personality=ON) |
| **DIRETRIZES.md** | Apresentacao: emoji, output, git commits, avatar rules, links Cursor, plan mode, verificacao, despedida + **blocos de interface** (ERRO/SUCESSO/ACAO/INFO) | Toda interacao |
| **ARSENAL.md** | Catalogo: ferramentas nativas, MCP tools, commands (/code, /meta:*, /commit), skills por namespace, quick reference | Quando precisa saber "o que posso fazer" |

### Outros na raiz

| Arquivo | O que e |
|---------|---------|
| **CLAUDE.slim.md** | Versao enxuta do CLAUDE.md global (~65 linhas). Copiar pra `~/.claude/CLAUDE.md` no host. |
| **MANUAL.md** | Este arquivo |
| **status-patch.sh** | Script de patch da statusline |

---

## Pastas Principais

### agents/ — Definicoes de Agentes

Cada subpasta e um agente. Contem `agent.md` com frontmatter (model, clock, max_turns, tools) e instrucoes de comportamento.

| Agente | Modelo | Clock | O que faz |
|--------|--------|-------|-----------|
| **hermes** | sonnet | 10min | Relogio mestre. Le DASHBOARD, despacha agentes vencidos, processa inbox/outbox. Unico ponto de entrada. |
| **sage** | sonnet | 60min | Sabio do sistema. 4 modos: EXPLORE (vaguear pelo codigo), ORGANIZE (vault tidy + enforcement), PROPOSE (melhorias via worktree), DOCUMENT (wiki no vault). Consolida ex-wanderer/wiseman/gandalf/wikister. |
| **coruja** | sonnet | 60min | Especialista Estrategia. Implementa features nos 3 repos (monolito Go, bo-container Vue, front-student Nuxt). Ciclos investigativos. |
| **keeper** | haiku | 30min | Saude do sistema. Health checks, limpeza de disco, rotacao de logs, cleanup de assets orfaos. |
| **paperboy** | haiku | 120min | Motor de descoberta. Aprende preferencias do Pedro via feedback, produz jornal pessoal curado. |
| **jonathas** | sonnet | 30min | Projeto imobiliario. Evolui roadmap, pesquisa mercado, gera conteudo. |
| **placeholder** | haiku | on-demand | Executor generico. Pega qualquer task sem especialista. |

Agentes com `.deprecated` na pasta foram absorvidos ou descontinuados — codigo preservado pra referencia.

### hooks/ — Lifecycle Hooks

Executados automaticamente pelo Claude Code em momentos especificos.

| Arquivo | Quando executa | O que faz |
|---------|---------------|-----------|
| **session-start.sh** | Inicio da sessao | Injeta boot flags, ~/.leech, API usage, persona. O arquivo mais critico do sistema. |
| **user-prompt-submit.sh** | A cada mensagem do user | Lazy-load de ENV + OBSIDIAN context (poupa tokens em perguntas simples). |
| **pre-tool-use.sh** | Antes de cada tool | Pre-processamento leve. |
| **post-tool-use.sh** | Depois de cada tool | Pos-processamento leve. |
| **startup-hook.sh** | Startup do container | Inicializacao. |
| **modes/** | Subpasta | Conteudo injetado condicionalmente: |
| **modes/analysis.md** | LEECH_ANALYSIS_MODE=1 | Modo experimento isolado (subagente de debug). |
| **modes/beta.md** | BETA=ON | Modo observacao cientifica + personalidade yandere. |

### scripts/ — Utilitarios Shell/Python

| Script | O que faz |
|--------|-----------|
| **boot-display.sh** | Banner ASCII + status do sistema (stderr, so visual no terminal) |
| **statusline.sh** | Barra de status do Claude Code (mostra contexto, quota, modo) |
| **usage-bar.sh** | Gera barra visual de consumo de tokens |
| **claude-ai-usage.sh** | Consulta quota via API web do claude.ai |
| **claude-oauth-usage.sh** | Consulta quota via OAuth token |
| **chrome-relay.py** | Cliente Chrome DevTools Protocol (CDP) — controla browser do user |
| **rss-fetcher.py** | Agregador RSS para o Paperboy |
| **bootstrap.sh** | Inicializacao do container |
| **bootstrap-dashboard.sh** | Inicializa DASHBOARD.md |
| **colors.sh** | Biblioteca ANSI colors |
| **logging.sh** | Logging estruturado |
| **glados-speak.sh** | TTS com tuning GLaDOS via espeak-ng |

### skills/ — Habilidades por Namespace

Organizadas em 5 namespaces. Cada skill tem um `SKILL.md` que define trigger, workflow e templates.

```
skills/
├── code/              Analise e desenvolvimento de codigo
│   ├── analysis/      Diff interativo, flows, objects, componentes
│   ├── debug/         4 fases: reproduzir, hipotese, isolar, verificar
│   ├── review/        Pipeline completo de code review
│   ├── tdd/           Red-Green-Refactor
│   ├── test/          Geracao de planos de teste
│   ├── goodpractices/ 10 regras (auto-ativa em qualquer trabalho de codigo)
│   └── github/        Operacoes GitHub CLI
│
├── coruja/            Plataforma Estrategia (Go/Vue/Nuxt)
│   ├── monolito/      go-handler, go-service, go-migration, go-repository, go-test, go-worker
│   ├── bo-container/  component, page, route, service, inspector
│   ├── front-student/ component, page, route, service, inspector
│   ├── orquestrador/  orquestrar-feature, review-pr, changelog, recommit, refinar-bug
│   ├── jira/          Integracao Jira (refinamento, custom fields)
│   ├── ecosystem-map/ Mapa dos 19 repos
│   ├── platform-context/ Contexto compartilhado (stacks, convencoes)
│   └── glance/        Visao visual cross-repo dos diffs
│
├── leech/             Infraestrutura do proprio Leech
│   ├── container/     Docker: criar/operar servicos
│   ├── healthcheck/   Diagnostico do sistema
│   ├── linux/         NixOS, Hyprland, dotfiles
│   ├── upgrade/       Implementar features no Leech CLI (Rust)
│   └── worktree/      Sistema multi-repo via leech wt
│
├── meta/              Meta-ferramentas e auto-conhecimento
│   ├── art/           Visual: ASCII, Chrome relay, design system
│   ├── holodeck/      Visualizacao: Mermaid, diffs, dashboards
│   ├── humanize/      Remove padroes de IA do texto
│   ├── obsidian/      Operacoes no vault (board, graph, dataview)
│   ├── rules/         Enforcement das 11 leis
│   └── skill/         Explicar e evoluir skills
│
├── thinking/          Protocolo de raciocinio
│   ├── lite/          Obrigatorio pra Haiku: ASSESS/ACT/VERIFY
│   ├── investigate/   Sempre primeiro: coletar dados
│   └── brainstorm/    Ideacao + refinamento + radar proativo
│
└── _archive/          Skills arquivadas (nicho, raramente usadas)
```

### commands/ — Entry Points

Comandos invocaveis via `/comando`. Sao wrappers que roteiam pra skills.

| Comando | O que faz |
|---------|-----------|
| /code | Router: diff, layers, flow, report, inspect |
| /commit | Git commit interativo |
| /commit-push-pr | Commit + push + PR |
| /review-pr | Review com 5 perspectivas |
| /feature-dev | Desenvolvimento guiado de feature |
| /clean_gone | Limpa branches [gone] |
| /tick | Ciclo de agentes (hermes despacha) |
| /meta:* | 13+ meta-commands (self, phone, feed, rules, lab, etc.) |

### personas/ — Personalidades

| Arquivo | O que e |
|---------|---------|
| **GLaDOS.persona.md** | Persona principal: tom, comportamento, sarcasmo, passivo-agressividade |
| **claudio.persona.md** | Persona alternativa: entusiastico, 10yo-30yo hybrid |
| **avatar/** | Catalogos de expressoes (21 para GLaDOS) |

Trocar persona: editar as linhas `Persona:` e `Avatar:` em `PERSONA.md`.

### memory/ — Memoria Persistente

Cross-session knowledge. Tipos:
- `feedback_*.md` — correcoes do user ("nao faca X")
- `project_*.md` — contexto de projetos em andamento
- `reference_*.md` — refs externas (APIs, configs, docs)
- `user_context.md` — sobre o Pedro
- `MEMORY.md` — indice de todas as memorias

### tools/ — Scripts de Suporte

Scripts auxiliares usados por outros componentes (task-runner, etc.).

### oldself/ — Preservacao

Tudo que foi removido da estrutura ativa mas preservado pra referencia.
- `oldself/_archive/core-docs/` — 12 docs antigos que foram consolidados
- `oldself/skills_archive/` — 18 skills nicho arquivadas
- `oldself/ego-*` — agentes deprecated

---

## Fluxo de Boot

```
Claude Code inicia
    │
    ▼
settings.json carrega hooks
    │
    ▼
session-start.sh executa:
    ├── Detecta workspace + flags
    ├── Injeta ---BOOT--- (flags, datetime, regras minimas)
    ├── Injeta ---LEECH--- (~/.leech vars)
    ├── Injeta ---API_USAGE--- (cota)
    ├── Injeta ---PERSONA--- (se personality=ON)
    │   └── PERSONA.md + GLaDOS.persona.md + avatar
    ├── Boot display (stderr, so terminal)
    └── Modos opcionais (ANALYSIS, BETA)
    │
    ▼
CLAUDE.md injetado automaticamente pelo Claude Code
    │
    ▼
user-prompt-submit.sh (lazy-load):
    └── Injeta ENV + OBSIDIAN no primeiro prompt complexo
    │
    ▼
Sessao pronta
```

---

## Fluxo de Agentes (Card-Driven)

```
Cron (every 10min) → yaa tick → despacha Hermes
    │
    ▼
Hermes le DASHBOARD.md → coluna TODO
    │
    ▼
Para cada card (max 3/ciclo):
    │
    Card: **sage-ronda** #sage #sonnet #every60min
          briefing:bedrooms/sage/BRIEFING.md
    │
    ├── Extrai: #sage, #sonnet, briefing path
    ├── Le BRIEFING.md
    ├── Move TODO → DOING
    ├── Despacha Agent(subagent_type=sage, model=sonnet, prompt=briefing)
    │
    ▼
Agente despachado:
    ├── Le AGENT.md (regras)
    ├── Le bedrooms/<nome>/memory.md (contexto)
    ├── Le briefing (o que fazer)
    ├── Executa
    ├── VERIFY artefatos
    ├── Atualiza memory.md
    └── Retorna resultado pro Hermes
    │
    ▼
Hermes recebe resultado:
    ├── Move DOING → DONE
    └── Se card tem #everyXmin: recria no TODO com last: atualizado
```

**Principio:** agentes sao inertes — so existem quando um card os invoca.

---

## Como Reverter

Tudo que foi consolidado tem backup em `_archive/`:

```bash
# Restaurar um doc antigo
cp self/_archive/core-docs/BOOT.md self/BOOT.md

# Restaurar uma skill
mv self/skills/_archive/code-flutter self/skills/code/flutter

# Reativar um agente
rm self/ego/wanderer/.deprecated
```
