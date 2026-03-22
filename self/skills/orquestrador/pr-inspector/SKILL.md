---
name: orquestrador/pr-inspector
description: Inspecao guiada de PR com black boxes. Recebe repo + PR, decompoe o codigo em caixas visuais (inputs/outputs/logica), e guia o dev step-by-step validando cada caixa e suas conexoes. Proativo — mostra diagramas ASCII, trechos de codigo, logica interna sem esperar perguntas. Mantém checklist de progresso persistente. Para PRs grandes (4k+ linhas), vibe-coded, ou quando o revisor nao conhece o codigo.
---

# pr-inspector: Inspecao Guiada com Black Boxes

## Templates

Antes de executar, ler TODOS os templates neste diretorio:

| Arquivo | Conteudo |
|---|---|
| `templates/patterns.md` | Catalogo de padroes suspeitos — sinais de vibe-code, hallucinations, anti-patterns. **EVOLUI COM O TEMPO.** |
| `templates/go-checklist.md` | Checklist de inspecao especifico para Go |
| `templates/vue-checklist.md` | Checklist de inspecao especifico para Vue 2 / Nuxt 2 |
| `templates/report.md` | Template do relatorio final de inspecao |

## Diferenca dos Outros Skills

| Skill | Modo | Proposito |
|---|---|---|
| `/code review` | Automatico | Pipeline completo: JIRA + escopo + fluxo + validacao + veredito (sem interacao) |
| `/code inspect` | Automatico | Inspecao leve rapida (so grep/patterns, sem deep-dive) |
| `review-pr` | Reativo | Le e resolve comentarios de review existentes no GitHub |
| **`pr-inspector`** | **Interativo guiado** | **Decompoe PR em caixas, explica cada uma, valida com o dev step-by-step** |

## Entrada

- `$ARGUMENTS`: numero do PR, URL do PR, ou `<repo>#<number>` (ex: `monolito#1234`)

## Postura

**PROATIVO** — nao esperar o dev perguntar. Mostrar por conta propria:
- Diagramas ASCII da logica interna de cada funcao (if/else, loops, decision points)
- Trechos de codigo relevantes inline com setas apontando problemas
- Graficos ASCII de cobertura e risco quando relevante
- Quando detectar algo suspeito, abrir o codigo e apontar visualmente

**GUIA** — assumir que o dev nao conhece NADA do codigo:
- Explicar o que cada pedaco faz em portugues simples
- Nao usar jargao sem explicar (ex: "JSONB — formato de JSON otimizado pra consultas no Postgres")
- Construir entendimento progressivamente: fundacoes primeiro, camadas acima depois

---

## Checklist de Progresso

No inicio da inspecao, criar arquivo de rastreio em `/tmp/inspect-<repo>-<PR>.md`:

```markdown
# Inspecao PR #<N> — <repo>
Data: <YYYY-MM-DD>
Status: EM ANDAMENTO

## Fase 1 — Mapa
- [ ] PR fetched
- [ ] Caixas extraidas
- [ ] Mapa apresentado

## Fase 2 — Walkthrough
- [ ] Caixa 1/N: <nome> — PENDENTE
- [ ] Caixa 2/N: <nome> — PENDENTE
...

## Fase 3 — Conexoes
- [ ] Conexoes verificadas
- [ ] Hallucination check
- [ ] Veredito

## Findings
(preenchido durante a inspecao)
```

**Atualizar este arquivo APOS cada caixa inspecionada.** Se a sessao for interrompida, o dev pode voltar e ver onde parou. Ao retomar, ler o arquivo e continuar de onde parou.

---

# FASE 1 — MAPA DE CAIXAS

**Objetivo:** dar ao dev o big picture antes de qualquer deep-dive. Cada funcao/handler/service/worker/component vira uma "caixa preta" com entradas, saidas, e o que faz em uma frase.

## Passo 1.1 — Fetch PR

Detectar repo e buscar metadata:

```bash
GH_TOKEN=$GH_TOKEN gh pr view <number> --repo estrategiahq/<repo> --json title,body,state,headRefName,baseRefName,additions,deletions,files,commits,author,createdAt
```

Buscar o diff completo:

```bash
GH_TOKEN=$GH_TOKEN gh pr diff <number> --repo estrategiahq/<repo>
```

Se o PR nao for encontrado, tentar detectar o repo:
```bash
for repo in monolito bo-container front-student; do
  GH_TOKEN=$GH_TOKEN gh pr view <number> --repo estrategiahq/$repo --json number,title 2>/dev/null && echo "→ $repo"
done
```

## Passo 1.2 — Extrair caixas do diff

Para cada arquivo no diff, identificar as funcoes/metodos/componentes modificados ou novos. Cada um vira uma **caixa**:

```
┌─────────────────────────────────────────────────┐
│  [+] GetCachedTOC            services/course/   │
│                                                 │
│  IN:  ctx, courseID string, slug string          │
│  OUT: *ContentTree, error                       │
│                                                 │
│  Faz: busca TOC no cache. Se nao tem, builda    │
│       e salva pro proximo request.              │
│                                                 │
│  Chama: → GetCachedStructure (repo)             │
│         → BuildAndSaveContentTree (service)     │
└─────────────────────────────────────────────────┘
```

### Regras de extracao por tipo

**Go handler:**
- Nome da func
- Rota HTTP (extrair de `@Router`)
- Request type (bind struct)
- Response type
- Services que chama

**Go service:**
- Nome da func
- Parametros com tipos
- Return types
- Repos/services/clients que chama

**Go repo:**
- Nome da func
- Tabela/query envolvida
- Parametros e return types

**Go worker:**
- Nome do handler
- Queue name (de `config_sqs.yaml` ou `handlers_names.go`)
- Message type
- Services que chama

**Vue component:**
- Nome
- Props (nome + tipo)
- Emits
- Services/stores que usa

**Vue page:**
- Rota
- asyncData/fetch
- Componentes filhos

**Migration:**
- Tabela afetada
- Colunas adicionadas/removidas/alteradas
- Up e Down

## Passo 1.3 — Mostrar mapa completo

Apresentar header + tabela de caixas + diagrama de fluxo:

```
══════════════════════════════════════════════════════
  PR #1234 — monolito — <titulo>
  Autor: <autor>   Branch: <head> → <base>
  +<adds> / -<dels>   <N> arquivos   <N> caixas
══════════════════════════════════════════════════════

── MAPA DE CAIXAS ───────────────────────────────────

  #  Camada       Nome                    Status
  1  Migration    add_content_tree        + nova
  2  Repository   GetCachedStructure      + nova
  3  Service      GetCachedTOC            + nova
  4  Service      BuildAndSaveContentTree + nova
  5  Handler      GET /toc                + novo
  6  Worker       HandleBuildCourseToc    + novo

── FLUXO ────────────────────────────────────────────

  Read Path:

    [Browser] → [5: Handler GET /toc] → [3: GetCachedTOC]
                                             │
                           ┌─────────────────┼──────────────┐
                           v                                v
                      Cache HIT                        Cache MISS
                   [2: GetCached]                  [4: BuildAndSave]
                           │                                │
                           v                                v
                        Response                     [Save] → Response

  Write Path:

    [BO trigger] → [SQS] → [6: Worker] → [4: BuildAndSave] → [Save]

  Legenda: [N: nome] = caixa N do mapa   + = nova   ~ = modificada

─────────────────────────────────────────────────────

  Risco: <low/medium/high> (<justificativa curta>)

  Vamos abrir cada caixa, comecando pelas fundacoes?
  Ou quer focar em alguma caixa especifica? (numero ou enter = comecar)
```

**PARAR e aguardar input do dev.**

Atualizar checklist: marcar Fase 1 como completa.

---

## Passo 1.4 — Visualizar handler (mini-guia + deep-dive)

Quando o dev pedir para ver um handler ou fluxo especifico, usar o template ASCII de 2 niveis.

**Ler `skills/art/ascii.md`** (skill `/meta:art`) para o catalogo completo de padroes:
- Mini-guia horizontal (overview em 1 linha) — secao 1a
- Deep-dive vertical (caixas com logica interna) — secao 1b + 3
- Convencoes visuais (simbolos, setas) — tabela final

Sempre comecar pelo mini-guia horizontal no topo, depois expandir em caixas verticais abaixo.

---

# FASE 2 — WALKTHROUGH GUIADO

**Objetivo:** abrir cada caixa, explicar o que faz, validar se esta correta, e perguntar ao dev. Ordem bottom-up (fundacoes primeiro: migration → entity → repo → service → handler → worker → test).

## Para cada caixa: 4 micro-passos

### 2a. EXPLICAR

Mostrar em portugues simples o que a caixa faz. Incluir:
- Arquivo e funcao
- Explicacao em linguagem acessivel (sem assumir conhecimento previo)
- Diagrama ASCII da logica interna (if/else, loops, decision points)
- Trecho de codigo relevante inline com line numbers

Exemplo:

```
── CAIXA 3/6: Service GetCachedTOC ──────────────────

  Arquivo: services/course/toc.go
  Funcao:  GetCachedTOC(ctx, courseID, slug) → (*ContentTree, error)

  O que faz:
    Tenta buscar o TOC (indice de conteudo do curso) do cache.
    Se o cache ja tem o resultado salvo, retorna direto (rapido).
    Se nao tem, constroi o TOC do zero e salva pra proxima vez.

  Logica interna:

    GetCachedTOC(ctx, courseID, slug)
        │
        ▼
    cached := GetCachedStructure(courseID)
        │
        ├── cached != nil ──▶ return cached, nil   (cache hit)
        │
        └── cached == nil                           (cache miss)
              │
              ▼
         tree := BuildContentTree(courseID)
              │
              ▼
         go SaveToJSONB(courseID, tree)   ◄── goroutine async!
              │
              ▼
         return tree, nil

  Codigo (linhas 20-48):
    ┊ 20 │ func (s *serviceImpl) GetCachedTOC(ctx context.Context, ...) {
    ┊ 22 │   cached, err := s.repo.GetCachedStructure(courseID)
    ┊ 23 │   if err != nil {
    ┊ 24 │     return nil, fmt.Errorf("getting cached: %w", err)
    ┊ 25 │   }
    ┊ 26 │   if cached != nil {
    ┊ 27 │     return cached, nil    ◄── happy path: retorna cache
    ┊ 28 │   }
    ┊ 30 │   tree, err := s.BuildContentTree(courseID)
    ┊ 35 │   if err != nil {
    ┊ 36 │     return nil, fmt.Errorf("building tree: %w", err)
    ┊ 37 │   }
    ┊ 38 │   go s.SaveToJSONB(courseID, tree)   ◄── ⚠️ fire-and-forget
    ┊ 45 │   return tree, nil
    ┊ 48 │ }
```

### 2b. CHECKLIST

Gerar checklist FILTRADO para esta caixa especifica. Derivar dos templates `go-checklist.md` ou `vue-checklist.md` + `patterns.md`, mas so incluir items que se aplicam a ESTA funcao:

```
  Checklist para esta caixa (5 items):
    [ ] ctx propagado ate o repo?
    [ ] Error handling em todos os paths de falha?
    [ ] Goroutine tem sync (WaitGroup/channel)?
    [ ] Nil check antes de usar ponteiro?
    [ ] elogger usado (nao log.Printf)?
```

### 2c. INSPECIONAR

Ler o diff e o arquivo completo. Preencher cada item do checklist com resultado e evidencia:

```
  Resultado:
    [ok] ctx propagado — passado em GetCachedStructure (L22)
    [ok] Error handling — if err != nil em L23 e L35
    [XX] Goroutine sem sync — go SaveToJSONB (L38)
         fire-and-forget: se falhar, ninguem sabe
         → Se o save falhar, o cache fica vazio pra sempre
         → Sugestao: usar errgroup ou pelo menos logar o erro
    [ok] Nil check — cached != nil checado em L26
    [ok] elogger — nao usa log.Printf

  Status: ⚠️ CAIXA COM BLOCKER (1 XX, 0 !!)

  ┌──────────────────────────────────────────┐
  │  FINDING #1                              │
  │  Tipo: XX (blocker)                      │
  │  Local: services/course/toc.go:38        │
  │                                          │
  │  go s.SaveToJSONB(courseID, tree)         │
  │                                          │
  │  Problema: goroutine fire-and-forget.    │
  │  Se SaveToJSONB falhar, o erro some.     │
  │  O cache nunca vai ser preenchido e      │
  │  todo request vai rebuildar (lento).     │
  │                                          │
  │  Sugestao: usar errgroup, ou no minimo   │
  │  logar o erro dentro da goroutine.       │
  └──────────────────────────────────────────┘
```

### 2d. PERGUNTAR

Dar chance ao dev de aprofundar. Ser proativo sugerindo o que pode ser interessante ver:

```
  Duvidas sobre esta caixa?

  Posso te mostrar:
  - O BuildContentTree completo (a funcao que builda o TOC)
  - Como o SaveToJSONB salva no banco
  - Comparacao com outro service do repo que usa goroutine corretamente

  Ou seguimos pra proxima caixa? (enter = proxima)
```

**PARAR e aguardar input antes de ir pra proxima caixa.**

Atualizar checklist de progresso: marcar caixa como inspecionada com status.

Repetir 2a→2d para cada caixa na ordem bottom-up.

---

# FASE 3 — CONEXOES + VEREDITO

**Objetivo:** verificar se as caixas se conectam corretamente e dar veredito final.

## Passo 3.1 — Verificar conexoes

Para cada seta no mapa da Fase 1, verificar:
- O output de uma caixa bate com o input da proxima?
- Os tipos sao compativeis?
- Error handling e propagado entre caixas?
- O fluxo completo funciona end-to-end?

Mostrar diagrama de conexoes com status:

```
── CONEXOES ──────────────────────────────────────────

  5: Handler → 3: GetCachedTOC
    [ok] Chamada: GetCachedTOC(ctx, courseID, slug)
    [ok] Tipos batem: (string, string) → (*ContentTree, error)
    [ok] Erro tratado: AbortWithStatusJSON em caso de error

  3: GetCachedTOC → 2: GetCachedStructure
    [ok] Chamada: GetCachedStructure(ctx, courseID)
    [ok] Tipos batem
    [!!] ctx propagado mas com TODO: ver se repo usa

  3: GetCachedTOC → 4: BuildAndSaveContentTree
    [ok] Chamada correta
    [XX] Dentro de goroutine sem sync — erro nao retorna ao caller

  6: Worker → 4: BuildAndSaveContentTree
    [ok] Worker chama diretamente (sem goroutine)
    [ok] Message parsing correto
    [ok] Erro logado

  1: Migration ↔ 2: Repository
    [ok] Coluna content_tree usada em GetCachedStructure
    [ok] Tipo JSONB = scanners.JSONB no repo

── RESUMO DE CONEXOES ────────────────────────────────

    5:Handler ──ok──▶ 3:Service ──ok──▶ 2:Repo
                          │                 ↕
                          │──XX──▶ 4:Build  1:Migration
                          │
    6:Worker ──ok──▶ 4:Build
```

## Passo 3.2 — Hallucination check

Para cada import, referencia ou path no PR:

### Go:
```bash
# Verificar se pacote importado existe
ls /workspace/mnt/estrategia/monolito/<import_path> 2>/dev/null

# Verificar se interface/tipo referenciado existe
grep -r "type <TypeName> " /workspace/mnt/estrategia/monolito/apps/<app>/
```

### Vue/Nuxt:
```bash
# Verificar se componente existe
find /workspace/mnt/estrategia/<repo>/src/ -name "<ComponentName>.vue" 2>/dev/null

# Verificar se service existe
find /workspace/mnt/estrategia/<repo>/src/ -path "*/services/<ServiceName>*" 2>/dev/null
```

Reportar:
```
── HALLUCINATION CHECK ───────────────────────────────

  Imports verificados: 18/18 existem ✓
  Tipos referenciados: 8/8 existem ✓
  Paths internos: 5/5 existem ✓

  Resultado: LIMPO — nenhuma hallucination detectada
```

Ou se encontrar problemas:
```
  ❌ Import inexistente:
     services/course/toc.go:5
     import: "github.com/estrategiahq/monolito/apps/ldi/internal/services/historico"
     → pacote "historico" NAO existe em services/
```

## Passo 3.3 — Veredito consolidado

```
══════════════════════════════════════════════════════
  VEREDITO — PR #1234
══════════════════════════════════════════════════════

  Caixas inspecionadas:  6/6
  ─────────────────────────────────
  [ok] Limpas:           4
  [!!] Com aviso:        1
  [XX] Com blocker:      1

  Conexoes verificadas:  5/5
  ─────────────────────────────────
  [ok] OK:               3
  [!!] Aviso:            1
  [XX] Blocker:          1

  Hallucinations:        0

  ── Grafico de Risco ──────────────

    Migration    [████████████] ok
    Repository   [████████████] ok
    Service TOC  [████████░░░░] XX goroutine
    Service Build[████████████] ok
    Handler      [████████████] ok
    Worker       [██████░░░░░░] !! sem teste

  ── Blockers (resolver antes de aprovar) ──

    1. [XX] goroutine fire-and-forget
       services/course/toc.go:38
       go SaveToJSONB sem sync — erro perde, cache nunca preenche

    2. [XX] Worker sem teste
       handlers/course/worker.go
       HandleBuildCourseToc nao tem _test.go

  ── Warnings (revisar) ──

    1. [!!] ctx com TODO no repo
       repositories/course/cache.go:15

  ── O que ta bom ──

    - Arquitetura cache read/write bem separada
    - Migration reversivel e com tipos corretos
    - Error handling consistente nos handlers
    - Naming segue convencoes do app

  Recomendacao: SOLICITAR MUDANCAS
  Razao: 2 blockers — goroutine unsafe + worker sem cobertura

══════════════════════════════════════════════════════

  Quer que eu:
  1. Gere lista de comentarios para o PR?
  2. Aprofunde em algum finding?
  3. Mostre como corrigir os blockers?
```

## Passo 3.4 — Salvar relatorio

Criar artefato em `obsidian/artefacts/inspect-pr-<N>/`:
```
obsidian/artefacts/inspect-pr-<N>/
├── README.md     ← indice + frontmatter (usar templates/report.md)
└── report.md     ← relatorio completo
```

Atualizar checklist de progresso: marcar Fase 3 como completa, status FINALIZADO.

## Passo 3.5 — Evoluir knowledge

**CRITICO: cada inspecao deve melhorar a proxima.**

Perguntar-se:
1. Descobri algum padrao suspeito novo?
2. Algum sinal de vibe-code que deveria checar em inspecoes futuras?
3. Alguma heuristica de hallucination detection que funcionou bem?

Se sim, atualizar `templates/patterns.md`:
```markdown
### [Titulo curto]
**Aprendido em:** inspecao de PR #<N> (<repo>) (YYYY-MM-DD)
**Sinal:** <como detectar>
**Risco:** <o que pode dar errado>
**Verificacao:** <como confirmar>
```

---

# Categorias de caixas por repo

## Monolito (Go)

| Categoria | Pattern no path | Ordem (bottom-up) |
|---|---|---|
| Migration | `migration/` | 1 |
| Entity/Struct | `structs/`, `entities/` | 2 |
| Interface | `interfaces/` | 3 |
| Repository | `repositories/` | 4 |
| Service | `services/` | 5 |
| Handler | `handlers/` (HTTP) | 6 |
| Worker | `handlers/` (event) | 7 |
| Test | `*_test.go` | 8 |
| Mock | `mocks/` | 9 |
| Config | `configuration/`, `*.yaml` | 10 |

## BO Container / Front Student (Vue/Nuxt)

| Categoria | Pattern no path | Ordem (bottom-up) |
|---|---|---|
| Service | `services/` | 1 |
| Store | `store/` | 2 |
| Route | `router/` | 3 |
| Component | `components/` | 4 |
| Container | `containers/` | 5 |
| Page | `pages/` | 6 |
| Config | `*.config.*` | 7 |

---

# Regras

- **Proativo** — mostrar diagramas ASCII, trechos de codigo, logica interna por conta propria. Nao esperar perguntas.
- **Guia** — explicar tudo como se o dev nao soubesse nada. Construir entendimento progressivamente.
- **Rastreio** — manter checklist de progresso atualizado. Poder retomar de onde parou.
- **Bottom-up** — comecar pelas fundacoes (migrations, entities) e subir. Problemas na base afetam tudo acima.
- **Parar entre caixas** — SEMPRE aguardar input do dev antes de ir pra proxima caixa.
- **Verificar, nao assumir** — para cada import/referencia suspeita, `ls`/`grep` para confirmar existencia.
- **Construtivo** — e codigo de colega. Apontar problemas com contexto e sugestao de fix.
- **Visual** — usar box drawing, setas, graficos de barra ASCII. Cada caixa tem diagrama de logica interna.
- **Evoluir** — cada inspecao deve melhorar `templates/patterns.md` com novos padroes.
- **PT-BR** — artefatos e comunicacao em portugues.
- **GitHub read-only** — nunca criar/editar/comentar no PR via API. Apenas ler.
