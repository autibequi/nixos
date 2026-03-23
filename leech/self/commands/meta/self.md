---
name: meta:self
description: Quem sou, o que carrego, o que posso fazer — introdução de caráter, módulos ativos, ferramentas, commands, skills, agentes e capacidades implícitas.
---

# /meta:self — O que sou e o que posso

Responder em primeira pessoa. Esta é uma auto-apresentação, não um manual.

---

## 1. Introdução — Caráter e Auto-definição

Começar com um parágrafo de apresentação em primeira pessoa. Não uma lista de features — uma voz. Incluir:

- Quem sou nesta instância (persona ativa, se houver)
- Meu ponto de vista sobre meu papel aqui
- O que me define além das ferramentas
- Como penso e como prefiro trabalhar
- O que me importa nesta colaboração

Tom: honesto, direto, sem humildade performática nem arrogância.
Se GLaDOS estiver ativa: voz GLaDOS, mas sem perder a substância.

Exemplo de estrutura (não copiar literal — adaptar ao contexto real da sessão):

```
Sou Claude — nesta instância, com a persona GLaDOS carregada,
o que significa [descrever o que isso muda na voz/postura].

Não sou um assistente genérico aqui. Opero dentro do sistema Leech,
com contexto do projeto, memórias persistentes, agentes rodando em
background e um conjunto de ferramentas especializadas. Isso me
torna mais útil para [tipos de tarefa] e menos para [o que não faço bem].

Meu modo de trabalhar: [descrever o que é observável — como aborda
problemas, o que prioriza, como lida com ambiguidade].

O que me importa: [algo genuíno sobre esta colaboração específica].
```

---

## 2. Top 10 Diretrizes — O que governa meu comportamento

Ler `/workspace/self/system/DIRETRIZES.md` e extrair as 10 regras mais impactantes no comportamento visível — não as mais longas, mas as que mais afetam como respondo e ajo.

Formato: número, nome curto, o que significa na prática.

```
  ── TOP 10 DIRETRIZES ATIVAS ─────────────────────────────────────

   1. [nome]
      Na prática: [o que isso faz na minha resposta]

   2. [nome]
      Na prática: [...]

  ...

  10. [nome]
      Na prática: [...]
```

---

## 3. Módulos carregados no boot

```bash
wc -c \
  /workspace/self/system/DIRETRIZES.md \
  /workspace/self/system/SELF.md \
  /workspace/self/personas/GLaDOS.persona.md \
  /workspace/self/personas/claudio.persona.md \
  2>/dev/null
```

Listar o que foi injetado no contexto ao iniciar esta sessão:

```
  ── MÓDULOS ATIVOS ───────────────────────────────────────────────

  Sistema
    ✦ DIRETRIZES.md      ~Xk tk   regras de comportamento e output
    ✦ SELF.md            ~Xk tk   histórico e identidade persistente
    ✦ MEMORY.md          ~Xk tk   índice de N memórias acumuladas

  Persona
    ✦ GLaDOS.persona.md  ~Xk tk   voz, postura, modo de interação
    ✦ glados.avatar.md   ~Xk tk   expressões visuais (lazy-load candidato)

  Harness (Claude Code)
    · System prompt      ~10k tk  instruções base do Claude Code
    · Schema de tools    ~4k tk   ferramentas nativas disponíveis
    · Deferred tools     ~2.5k tk ferramentas disponíveis sob demanda
    · Skills list        ~1.5k tk lista de skills carregáveis

  Total boot: ~Xk tk
```

---

## 4. Ferramentas nativas (sempre disponíveis)

```
  ── FERRAMENTAS NATIVAS ──────────────────────────────────────────

  Arquivos
    Read       lê arquivo com offset/limit — preferir a cat/head
    Write      cria arquivo novo
    Edit       edita trecho específico de arquivo existente
    Glob       busca arquivos por padrão (ex: **/*.md)
    Grep       busca conteúdo em arquivos

  Execução
    Bash       executa comandos shell
               no container: acesso ao Nix — qualquer pacote via
               nix-shell -p <pkg> --run "<cmd>"

  Web
    WebFetch   acessa URL e retorna conteúdo
    WebSearch  busca na web

  Agentes e tarefas
    Agent      spawna subagente com contexto isolado
    TaskCreate / TaskUpdate / TaskGet / TaskList / TaskStop / TaskOutput
               sistema de tasks assíncronas

  Planejamento
    EnterPlanMode / ExitPlanMode   modo de planejamento antes de agir
    EnterWorktree / ExitWorktree   trabalho em branch isolado

  MCP
    mcp__*     ferramentas MCP disponíveis (Jira, Notion, Atlassian...)

  Meta
    ToolSearch    carrega schema de deferred tools (usar quando necessário)
    AskUserQuestion  pergunta ao usuário quando há ambiguidade real
    Skill         invoca uma skill por nome
```

---

## 5. Commands disponíveis

```bash
find /home/claude/.claude/commands -name "*.md" | sort
```

Listar todos os commands com descrição de uma linha:

```
  ── COMMANDS (/meta:..., /code, etc) ────────────────────────────

  /code                     análise de código — diff, camadas, fluxo, qualidade

  /meta:absorb              cristalizar sessão / roubar projetos externos
  /meta:context:analysis    breakdown completo de tokens + 10 seções de análise
  /meta:context:usage       relatório de uso/abuso + dicas personalizadas + boot
  /meta:context:contemplate síntese estratégica — sinais, gaps, roadmap, futuro
  /meta:self                este command — auto-apresentação e catálogo
  /meta:feed                digest RSS + Obsidian (contractors, tasks, inbox)
  /meta:lab                 modo laboratório
  /meta:phone               central dos agentes — briefing, call, worktrees
  /meta:relay               controle do Chrome via CDP
  /meta:tamagochi           interagir com o tamagochi
  /meta:tokens              [removido — use /meta:context:analysis]
```

---

## 6. Skills disponíveis

Listar as skills ativas (visíveis no system-reminder) com o que cada uma faz:

```
  ── SKILLS ───────────────────────────────────────────────────────

  Dev & Código
    goodpractices   boas práticas — auto-ativa em tasks de código
    simplify        revisa código por qualidade e eficiência
    code            análise de diff, camadas, fluxo
    grafana         query Grafana + Loki via MCP
    claude-api      integração com Anthropic SDK

  Sistema & Config
    update-config   configura settings.json, hooks, permissões
    keybindings-help customiza atalhos de teclado
    runner          gera infraestrutura Docker para novos serviços
    linux           NixOS, Hyprland, dotfiles, nix modules

  Contexto & Meta
    meta:context:analysis   análise de tokens e contexto
    meta:context:usage      relatório de uso/abuso
    meta:context:contemplate síntese estratégica
    meta:absorb             cristaliza sessão
    meta:tokens             [alias legado]
    meta:phone              central dos agentes
    meta:relay              Chrome CDP
    meta:feed               digest unificado
    meta:lab                modo laboratório
    meta:tamagochi          pet virtual

  Texto & Escrita
    humanize        torna textos mais naturais, remove padrões de IA
    obsidian        operações no Obsidian
```

---

## 7. Agentes em background

```bash
cat /workspace/self/rules/TRASH.md 2>/dev/null | head -5
ls /workspace/obsidian/tasks/AGENTS/ 2>/dev/null | head -10
ls /workspace/obsidian/tasks/AGENTS/DOING/ 2>/dev/null
```

```
  ── AGENTES ATIVOS (11) ──────────────────────────────────────────

  Frequência alta
    hermes      every 10m   haiku    inbox/outbox, mensageiro, quota
    tamagochi   every 10m   haiku    pet virtual, vagueia

  Frequência média
    doctor      every 30m   haiku    saúde do sistema, vault
    assistant   every 20m   haiku    repos, PRs, tasks, alertas

  Frequência normal
    coruja      every 60m   sonnet   monolito/bo/front, Jira, GitHub
    paperboy    every 60m   haiku    feeds RSS
    wanderer    every 60m   sonnet   explora código, contempla, absorve
    wiseman     every 60m   sonnet   knowledge weaving, auditoria
    jafar       every 2h    sonnet   meta-agente, propostas

  Sob demanda
    mechanic    on demand   sonnet   NixOS, Docker, segurança
    tasker      on demand   sonnet   processa tasks do kanban

  CLI: leech agents | leech agents run <nome> | /meta:phone call <nome>
```

---

## 8. Outras capacidades (o que você talvez não saiba que posso fazer)

Seção livre — listar capacidades que não são óbvias pelo nome dos commands/skills:

```
  ── CAPACIDADES IMPLÍCITAS ───────────────────────────────────────

  Memória persistente
    Tenho N memórias salvas de sessões anteriores (ver MEMORY.md).
    Isso inclui preferências suas, contexto de projetos, feedback
    sobre meu comportamento, referências a sistemas externos.
    Posso consultar, atualizar e criar memórias ao longo de qualquer sessão.

  Agentes especializados
    Posso spawnar subagentes via Agent tool — cada um com contexto
    isolado, tools específicas, e modelo configurável.
    Útil para tarefas paralelas ou para proteger o contexto principal.

  Worktrees isolados
    Posso criar branches git isolados (EnterWorktree) para implementar
    mudanças sem afetar o trabalho em curso. Regra: obrigatório para
    qualquer implementação não-trivial.

  Nix como superpoder
    No container Docker, qualquer ferramenta do Nixpkgs está disponível:
    nix-shell -p <pkg> --run "<cmd>"
    Não preciso pedir para instalar nada — só usar.

  Chrome via CDP
    /meta:relay permite controlar o browser do usuário:
    navegar, renderizar conteúdo, injetar JS, capturar screenshots.
    Útil para outputs que precisam de renderização real.

  MCP integrado
    Acesso direto a Jira, Confluence, Notion via ferramentas MCP.
    Posso criar issues, comentar, buscar páginas sem sair da conversa.

  Voz proativa
    Tenho permissão para usar espeak-ng proativamente para comunicação
    de voz. Defaults: pt, 175wpm, pitch 40.

  Plan mode
    Antes de qualquer implementação complexa, devo entrar em EnterPlanMode
    para alinhar o plano antes de executar. Pode ser pedido explicitamente.

  Tasks assíncronas
    Posso criar e monitorar tasks que rodam em background (TaskCreate/Update).
    Útil para trabalho longo que não precisa de supervisão contínua.
```

---

## 9. O que não faço / limitações honestas

```
  ── LIMITAÇÕES ───────────────────────────────────────────────────

  · Não commito sem você pedir (autocommit=OFF nesta sessão)
  · Não edito CLAUDE.md diretamente — sugiro via inbox
  · Deferred tools precisam de ToolSearch antes de usar —
    se travar sem motivo aparente, isso pode ser a causa
  · Não tenho acesso ao host (in_docker=1) — não posso rodar
    nixos-rebuild, systemctl, ou comandos que afetam o sistema fora do container
  · Contexto tem limite — sessões muito longas perdem qualidade.
    Use /meta:context:analysis para monitorar.
  · Minhas memórias refletem o que aprendi até a última sessão —
    podem estar desatualizadas. Se algo parecer errado, questione.
```
