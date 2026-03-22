---
name: code/review
description: Review completo de PR em pipeline automatico — contexto JIRA + escopo por camada + diagrama de fluxo ASCII + validacao de codigo + veredito final. Tudo inline no terminal. Use /code review para rodar.
---

# code/review — Review Completo de PR

Pipeline automatico de 5 fases que responde: por que? o que? como? ta seguro? posso aprovar?

Output inteiro em ASCII no terminal — sem Chrome relay.

## Argumentos

```
/code review [--repo monolito|bo|front|all] [--skip-jira]
```

Defaults: `--repo all`

---

## Fase 0 — Detectar PR e Branch

1. Detectar branch atual:
```bash
git branch --show-current
```

2. Extrair numero do card JIRA do nome da branch (pattern: `FUK2-\d+`):
```bash
git branch --show-current | grep -oP 'FUK2-\d+'
```

3. Se `gh` disponivel e `GH_TOKEN` setado, tentar metadata do PR:
```bash
gh pr list --head "$(git branch --show-current)" --json number,title,author,url --limit 1
```

4. Se nenhum card JIRA detectado e `--skip-jira` nao foi passado, perguntar ao usuario.

5. Imprimir header:
```
================================================================
  REVIEW  <branch-name>   <data-hoje>
================================================================
```

---

## Fase 1 — CONTEXTO ("Por que isso existe?")

**Pular se `--skip-jira` ou nenhum card detectado.**

Buscar card JIRA usando a logica de `estrategia/jira/SKILL.md`:

```
mcp__claude_ai_Atlassian__getJiraIssue:
  cloudId: "9795b90e-d410-4737-a422-a7c15f9eadf0"
  issueIdOrKey: "<CARD-ID>"
  fields: ["*all"]
  expand: "names"
  responseContentFormat: "markdown"
```

Extrair campos relevantes (ver mapa completo em `estrategia/jira/SKILL.md`):
- `summary` — titulo
- `status.name` — status
- `assignee.displayName` — autor
- `customfield_10021` — sprint (extrair `.name`)
- `description` — descricao (ja em markdown)
- `customfield_11246` — Sugestao de Implementacao (ADF → extrair texto)
- `customfield_11258` — DoD Engenharia (ADF → extrair texto)

Output ASCII:
```
-- CONTEXTO (por que isso existe?) ----------------------------

  Card:     FUK2-XXXXX
  Titulo:   <summary>
  Status:   <status>
  Autor:    <assignee>
  Sprint:   <sprint name>

  Descricao:
    <description resumida — primeiros ~500 chars>

  Sugestao de Implementacao:
    <customfield_11246 texto extraido — resumo dos pontos principais>

  DoD Engenharia:
    <customfield_11258 texto extraido>
```

Para extrair texto de campos ADF:
```python
def extract_text(node):
    texts = []
    if isinstance(node, dict):
        if 'text' in node: texts.append(node['text'])
        for v in node.values():
            if isinstance(v, (dict, list)): texts.extend(extract_text(v))
    elif isinstance(node, list):
        for item in node: texts.extend(extract_text(item))
    return texts
```

---

## Fase 2 — ESCOPO ("O que foi tocado?")

Reutilizar logica de `code/analysis/objects/SKILL.md` internamente.

Para cada repo ativo:
```bash
cd /workspace/mnt/estrategia/<repo>/
git diff origin/main --name-status
git diff origin/main --stat
```

Classificar arquivos por camada usando `code/analysis/objects/templates/layers.md`.

Output ASCII:
```
-- ESCOPO (o que foi tocado?) ---------------------------------

  <repo>               +<adds> / -<dels>    <N> arquivos
  ...

  -- <repo> ------------------------------------------------

    <Camada>
      + <arquivo-novo>    <rota ou func>    [NOVO]
      ~ <arquivo-mod>     <rota ou func>

    <Camada>
      ...

    Tests
      ~ <test_file>       <N> novos test cases
      + <test_file>                         [NOVO]
```

Simbolos: `+` novo (A), `~` modificado (M), `x` removido (D).

Repos e paths (mesmo de `code/analysis/objects`):
- `monolito`    → `/workspace/mnt/estrategia/monolito/`
- `bo`          → `/workspace/mnt/estrategia/bo-container/`
- `front`       → `/workspace/mnt/estrategia/front-student/`

---

## Fase 3 — FLUXO ("Como funciona?")

Gerar diagrama ASCII inline (NAO Mermaid, NAO Chrome — puro terminal).

**Ler `skills/meta/art/ascii.md`** (skill `/meta:art`) para padroes e convencoes visuais.

Ler os arquivos novos/modificados dos handlers e services para entender:
- Read path: request → handler → service → cache/repo → response
- Write path: trigger → queue/worker → service → persist

Usar box drawing chars para o diagrama:
```
-- FLUXO (como funciona?) ------------------------------------

  Read Path (<descricao curta>):

    Browser
      |
      v
    [+ HandlerNovo]  GET /rota
      |
      v
    [+ ServiceNovo]
      |
      +---> Cache HIT ---> [RepoMethod] ---> Response
      |
      +---> Cache MISS --> [BuildMethod]
                              |
                              v
                           [SaveMethod] ---> Response

  Write Path (<descricao curta>):

    [Trigger]
      |
      v
    [Queue/SQS]
      |
      v
    [+ WorkerHandler]
      |
      v
    [BuildMethod] ---> [SaveMethod]

  Legenda: [+ novo]  [~ modificado]  [existente]
```

Se nao houver write path separado, mostrar so o read path.
Se houver multiplos fluxos independentes (ex: endpoints distintos), mostrar cada um.

---

## Fase 4 — VALIDACAO ("Ta seguro?")

Combina logica de `code/inspection/SKILL.md` + checklists de `orquestrador/pr-inspector/templates/go-checklist.md` e `orquestrador/pr-inspector/templates/vue-checklist.md`.

Ler cada arquivo novo/modificado e verificar 4 sub-secoes:

### 4a. Happy Path

Tracar o caminho request → response dos fluxos da Fase 3:
- Todos os passos estao conectados?
- Retorno chega ao caller em todos os caminhos?
- Dados fluem corretamente entre camadas?

### 4b. Garantias

**Go (monolito):**
- Error handling: `AbortWithStatusJSON` ou `c.JSON` em todos os error paths?
- Nil checks antes de dereference de ponteiros?
- Goroutines tem `WaitGroup` ou canal de controle?
- `ctx` propagado ate o repositorio?
- Bind de request body com verificacao de erro?

**Vue/JS (bo, front):**
- Props tem `type` e `default`/`required`?
- Optional chaining (`?.`) em dados de API?
- Try/catch em chamadas de API?
- Sem `console.log` esquecido?

### 4c. Patterns

**Go:**
- Naming segue convencoes do app?
- Error handling pattern (`common.Err*`, `elogger`)?
- Import organization: stdlib | external | internal?
- Swagger: `@Router`, `@Summary`, `@Tags` presentes em handlers publicos?

**Vue:**
- `defineEmits` declarados?
- Loading state gerenciado?
- Contratos com BFF batem?

### 4d. Testes

Para cada objeto novo/modificado:
- Tem arquivo de teste correspondente?
- Test cases cobrem happy path?
- Test cases cobrem sad path / error cases?
- Contar: N/M objetos novos tem teste

Output ASCII:
```
-- VALIDACAO (ta seguro?) ------------------------------------

  4a. Happy Path
    <check> <descricao do caminho validado>
    ...

  4b. Garantias
    <check> <descricao>
    ...

  4c. Patterns
    <check> <descricao>
    ...

  4d. Testes
    <check> <objeto> — <N> test cases (<descricao>)
    ...

    Cobertura: N/M objetos novos tem teste (XX%)
```

Indicadores: `ok` para OK, `!!` para warning, `XX` para blocker.

---

## Fase 5 — VEREDITO

Consolidar todos os findings das fases anteriores.

Contar:
- Blockers (XX): problemas que devem ser corrigidos antes de aprovar
- Warnings (!!): merecem revisao mas nao bloqueiam
- Clean (ok): checks que passaram

Output ASCII:
```
-- VEREDITO --------------------------------------------------

  XX Blockers:    <N>
  !! Warnings:    <N>
  ok Clean:       <N> checks OK

  Blockers:
    1. <descricao>    <arquivo:linha>
    2. ...

  Warnings:
    1. <descricao>    <arquivo:linha>
    2. ...

  Recomendacao: <APROVAR | APROVAR COM RESSALVAS | SOLICITAR MUDANCAS>
  Razao: <justificativa curta>

  O que ta bom:
    - <ponto positivo 1>
    - <ponto positivo 2>
    - ...
=============================================================
```

Criterio de recomendacao:
- 0 blockers, 0-2 warnings → APROVAR
- 0 blockers, 3+ warnings → APROVAR COM RESSALVAS
- 1+ blockers → SOLICITAR MUDANCAS

---

## Relacao com outras skills

```
/code review     → este pipeline: contexto + escopo + fluxo + validacao + veredito
                   (roda tudo de uma vez, output ASCII, rapido)

/code inspect    → inspecao leve rapida (so validacao, sem JIRA/fluxo)

pr-inspector     → walkthrough interativo categoria por categoria COM o dev
                   (mais profundo, mais lento, mais colaborativo)

review-pr        → resolver comentarios ja existentes no PR (GitHub)
```

---

## Regras

- Output INTEIRO no terminal — sem Chrome relay, sem Mermaid render
- Nao duplicar codigo das sub-skills — referenciar e reusar a logica internamente
- Se JIRA nao disponivel (sem MCP, sem token), pular Fase 1 e continuar
- Se um repo nao tem diff (branch igual a main), omitir do output
- Manter output compacto — nao repetir informacao entre fases
