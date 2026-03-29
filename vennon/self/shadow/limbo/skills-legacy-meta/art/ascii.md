---
name: meta/art/ascii
description: Catalogo completo de representacoes ASCII para terminal. Fluxos, caixas, tabelas, arvores, graficos. Referencia central — qualquer skill que precise desenhar no terminal usa estes templates.
---

# ASCII — Representacoes no Terminal

---

## 1. Fluxo de Handler (mini-guia + deep-dive)

### 1a. Mini-guia horizontal (overview)

Uma linha compacta no topo. O dev bate o olho e entende o caminho antes de mergulhar.

**Read com cache (cache-aside):**
```
── GET /rota ─────────────────────────────────────────────────
  Handler → [cache?] ──HIT──→ Response
                     └─MISS─→ Service.Build → [Redis] + [JSONB] → Response
```

**Read com cache multi-nivel:**
```
── GET /rota ─────────────────────────────────────────────────
  Handler → [JSONB?] ──HIT──→ Response
                     └─MISS─→ [Redis?] ──HIT──→ Response
                                       └─MISS─→ Build → save ambos → Response
```

**Write com SQS (async):**
```
── POST /rota ────────────────────────────────────────────────
  Handler → Service.Trigger → [JobTrack] → [SQS msg] → (async Worker)
```

**CRUD simples:**
```
── PUT /rota ─────────────────────────────────────────────────
  Handler → [bind+validate] → Service.Update → Repo.Save → Response
```

**Guard (protecao antes de acao):**
```
── POST /rota (com guard) ────────────────────────────────────
  Handler → [CheckRebuild] ──active──→ 409 + jobs
                            └─clear──→ Service.Publish → Response
```

**Pipeline (cadeia):**
```
── POST /rota ────────────────────────────────────────────────
  Handler → Parse → Validate → Transform → Persist → Notify → Response
```

**Fan-out (1 entrada, N saidas):**
```
── POST /rota ────────────────────────────────────────────────
  Handler → Service ─┬─→ [SQS: queue-a]
                     ├─→ [SQS: queue-b]
                     └─→ [Redis: invalidate]
```

### 1b. Deep-dive vertical (caixas)

Abaixo do mini-guia, expandir cada passo:

```
  ┌─────────────────────────────────────────────────────────────┐
  │  HANDLER: NomeFuncao                                        │
  │  path/relativo/arquivo.go                                   │
  │                                                             │
  │  L31  res := getAndValidate(c)                              │
  │  L40  cached := GetCachedStructure(&res.course)             │
  │           │                                                 │
  │           ├── HIT (cached != nil)                           │
  │           │     └─ structure = cached ──────────┐           │
  │           │                                     │           │
  │           └── MISS                              │           │
  │                 │                               │           │
  │                 ▼                               │           │
  │  L44  built := BuildAndSave(courseID)  ──▶      │           │
  │           └─ structure = &built ────────┤       │           │
  │                                         ▼       │           │
  │  L88  return JSON(200, structure) ◄─────────────┘           │
  └─────────────────────────────────────────────────────────────┘
      │
      │ MISS → chama:
      ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  SERVICE: BuildAndSaveContentTree                           │
  │  ...                                                        │
  └─────────────────────────────────────────────────────────────┘
```

---

## 2. Mapa de Caixas (black boxes)

Para mostrar uma funcao/componente como caixa preta:

```
┌─────────────────────────────────────────────────┐
│  [+] NomeFuncao              camada/path/       │
│                                                 │
│  IN:  ctx, courseID string, slug string          │
│  OUT: *CourseStructureResponse, error            │
│                                                 │
│  Faz: busca TOC no cache. Se nao tem, builda    │
│       e salva pro proximo request.              │
│                                                 │
│  Chama: → GetCachedStructure (repo)             │
│         → BuildAndSaveContentTree (service)     │
└─────────────────────────────────────────────────┘
```

Para mapa completo com tabela + fluxo:

```
══════════════════════════════════════════════════════
  TITULO / PR / FEATURE
══════════════════════════════════════════════════════

── MAPA DE CAIXAS ───────────────────────────────────

  #   Camada       Nome                    Status
  1   Migration    add_content_tree        + nova
  2   Repository   GetCachedStructure      + nova
  3   Service      BuildAndSave            + nova
  4   Handler      GET /toc                + novo

── FLUXO ────────────────────────────────────────────

  [Browser] → [4: Handler] → [3: Service]
                                   │
                 ┌─────────────────┼──────────────┐
                 v                                v
            Cache HIT                        Cache MISS
            [2: Repo]                     [3: Build+Save]
                 │                                │
                 v                                v
              Response                     [Save] → Response
```

---

## 3. Logica Interna (dentro de caixas)

**If/else:**
```
  L25  resultado := BuscaAlgo(id)
           │
           ├── resultado != nil ──▶ return resultado
           │
           └── resultado == nil
                 │
                 ▼
  L30  resultado = ConstroiDoZero(id)
```

**Errgroup / goroutines paralelas:**
```
  L30  errgroup (limit=3):
           │
           ├── go: ProcessaItem(items[0])
           ├── go: ProcessaItem(items[1])
           └── go: ProcessaItem(items[2])
           │
           ▼
  L80  Wait() → consolida resultados
```

**Loop com falha parcial:**
```
  L50  for _, id := range ids {
           │
           ├── Marshal(msg)
           │     └── err? → failedCount++ → continue
           │
           └── sqsClient.Send(msg)
                 └── err? → failedCount++ → continue
       }
```

**Graceful degradation:**
```
  L36  SaveCache(Redis, key, data)
           └── err? → loga e continua  (graceful)

  L49  UpdateProperties(JSONB, course)
           └── err? → loga e continua  (graceful)

  L54  return structure, nil   ◄── sempre retorna sucesso
```

**Switch/precedencia:**
```
  L16  switch {
           ├── len(itemIDs) > 0    → usa itemIDs direto
           ├── len(courseIDs) > 0   → resolve → itemIDs
           └── len(chapterIDs) > 0  → resolve → itemIDs
       }
```

---

## 4. Diagrama Multi-Path

Para features com read + write + guard:

```
══════════════════════════════════════════════════════
  FEATURE: Cache de TOC
══════════════════════════════════════════════════════

  === READ PATH (usuario pede TOC) ===

    [Browser] → [Handler GET /toc] → [Service]
                                        │
                      ┌─────────────────┼──────────────┐
                      v                                v
                 Cache HIT                        Cache MISS
                 [Repo.Get]                    [Service.Build]
                      │                                │
                      v                                v
                   Response                  [Redis+JSONB] → Response

  === WRITE PATH (rebuild async) ===

    [BO trigger] → [Service.Trigger] → [SQS] → [Worker] → [Build+Save]

  === GUARD PATH (protege publicacao) ===

    [BO handler] → [CheckRebuild] ──active──→ 409 + jobs
                                  └─clear──→ prossegue
```

---

## 5. Tabelas de Status

**Checklist de inspecao:**
```
  [ok] ctx propagado — passado em GetCachedStructure (L22)
  [ok] Error handling — if err != nil em L23 e L35
  [XX] Goroutine sem sync — go SaveToJSONB (L38)
  [!!] log.Printf em vez de elogger — 2 ocorrencias
```

**Resumo de veredito:**
```
  XX Blockers:    2
  !! Warnings:    4
  ok Clean:       12 checks OK
```

**Tabela de caixas com status:**
```
  #   Camada       Nome                    Status
  1   Migration    add_content_tree        [ok]
  2   Repository   GetCachedStructure      [ok]
  3   Service      BuildAndSave            [XX] goroutine
  4   Handler      GET /toc                [ok]
  5   Worker       HandleBuildCourseToc    [!!] sem teste
```

---

## 6. Grafico de Barra Horizontal

```
  Migration    [████████████] ok
  Repository   [████████████] ok
  Service TOC  [████████░░░░] XX goroutine
  Service Build[████████████] ok
  Handler      [████████████] ok
  Worker       [██████░░░░░░] !! sem teste
```

Barra proporcional (12 chars = 100%):
- `█` preenchido (checks ok)
- `░` vazio (checks falhando)

---

## 7. Arvore de Arquivos

```
  monolito/
  ├── migration/
  │   └── + 2026030512_add_content_tree.sql
  ├── apps/ldi/
  │   ├── entities/
  │   │   └── ~ course.go
  │   ├── internal/services/course/
  │   │   ├── + build_and_save_content_tree.go
  │   │   ├── + get_course_toc_complete.go
  │   │   └── ~ getCourseChapters.go
  │   └── internal/handlers/course/
  │       └── + worker.go
  └── apps/bff/
      └── + get_course_structure.go
```

Simbolos: `+` novo, `~` modificado, `x` removido

---

## 8. Header de Secao

```
══════════════════════════════════════════════════════
  TITULO PRINCIPAL
══════════════════════════════════════════════════════

── SECAO ────────────────────────────────────────────

  conteudo...

─────────────────────────────────────────────────────
```

- `═` duplo: header principal (topo e fundo do output)
- `─` simples com titulo: secao interna
- `─` simples sem titulo: separador

---

## 9. Tabela Comparativa (antes/depois)

```
  Campo          Antes              Depois
  ─────────────  ─────────────────  ─────────────────
  Cache          nenhum             JSONB + Redis
  Endpoint       GET /course        GET /course + GET /toc
  Latencia       ~800ms             ~50ms (cache hit)
  Worker         nao existia        HandleBuildCourseToc
```

Usar para changelogs, reviews, explicar impacto de mudancas.

---

## 10. Sequencia Temporal (timeline)

```
  t0  [Browser]     GET /toc
  t1  [Handler]     getInteractiveCourse ─── 12ms
  t2  [Handler]     GetCachedStructure ───── 3ms  (HIT)
  t3  [Handler]     filtro trial ─────────── 1ms
  t4  [Response]    200 OK ───────────────── 16ms total
      ├────────────┼────────────┼────────────┤
      0           5ms         10ms         16ms
```

Usar para explicar latencia, debug de performance, sequencia de eventos.

---

## 11. Diagrama de Entidade/Struct

```
  ┌─────────────────────────────────┐
  │  Course (ldi.courses)           │
  ├─────────────────────────────────┤
  │  id                    string   │
  │  name                  string   │
  │  slug                  string   │
  │  published             bool     │
  │+ content_tree_cache    JSONB    │ ◄── novo
  │+ cache_updated_at      TSTZ    │ ◄── novo
  └─────────────────────────────────┘
       │ 1:N
       ▼
  ┌─────────────────────────────────┐
  │  CourseChapter                  │
  ├─────────────────────────────────┤
  │  chapter_id            string   │
  │  course_id             string   │
  │  name                  string   │
  └─────────────────────────────────┘
```

Simbolos: `+` campo novo, `~` campo alterado, `-` campo removido.
Relacoes: `1:N`, `1:1`, `N:N` com setas `│ ▼`.

---

## 12. Mapa de Dependencias (quem chama quem)

```
  BuildAndSaveContentTree
    ├── GetCourseChapters
    │     ├── courseRepo.GetOne
    │     ├── chapterRepo.GetAllFromCourse
    │     └── getChapterItems  (x3 parallel)
    │           ├── chapterItemRepo.GetAllFromChapters
    │           └── itemRepo.GetBlockTypeCounts
    ├── courseRepo.SaveCache (Redis)
    └── courseRepo.UpdateProperties (JSONB)
```

Usar para entender profundidade de chamadas, identificar N+1, mapear blast radius.

---

## 13. Diff Inline (antes/depois no mesmo bloco)

```
  services/course/service.go
  ┊ 45 │- func NewService(repo, chapterRepo) Service {
  ┊ 45 │+ func NewService(repo, chapterRepo, toggler) Service {
  ┊ 48 │+   toggler: toggler,
  ┊ 52 │  }
```

Simbolos: `-` linha removida, `+` linha adicionada, ` ` (espaco) linha inalterada.
Usar para mostrar mudancas pontuais sem abrir diff inteiro.

---

## 14. Matriz de Cobertura (testes vs objetos)

```
                           unit  integ  mock
  BuildAndSave              ✓      ·      ✓
  GetOrBuildCachedTOC       ✓      ·      ✓
  TriggerByCourseIDs        ✓      ·      ✓
  CheckTocRebuild           ✓      ·      ✓
  HandleBuildCourseToc      ✓      ·      ·
  GetCourseStructure        ·      ·      ·   ◄── gap
```

Simbolos: `✓` tem, `·` nao tem. Marcar gaps com `◄──`.
Usar em pr-inspector fase validacao, code review fase testes.

---

## 15. Fluxo de Estado (state machine)

```
  [IDLE] ──publish──→ [REBUILDING] ──done──→ [CACHED]
    ▲                      │                    │
    │                      │ fail               │ invalidate
    │                      ▼                    │
    └──────────────── [FAILED] ◄────────────────┘
```

Estados em `[COLCHETES]`, transicoes com setas nomeadas.
Usar para explicar ciclos de vida, workflows, feature flags.

---

## 16. Calendario/Sprint (timeline horizontal)

```
  Sprint 42
  ├── Seg  migration + entity
  ├── Ter  repo + service core
  ├── Qua  handler BFF + worker
  ├── Qui  triggers + guards nos BO handlers
  └── Sex  testes + fix CI
```

Usar para planejamento, breakdown de tarefas, retrospectiva.

---

## 17. Kanban Compacto

```
  TODO              DOING             DONE
  ─────────────     ─────────────     ─────────────
  teste integ       fix CI flaky      migration
  doc swagger       worker DLQ        entity
                                      repo cache
                                      service core
                                      handler BFF
```

3 colunas fixas. Itens empilhados. Usar para status de feature, tasks de agentes.

---

## 18. Grafico de Proporcao (pizza horizontal)

```
  Distribuicao dos 117 arquivos:
  ██████████████████░░░░  services    40%  (47)
  ████████░░░░░░░░░░░░░░  structs     18%  (21)
  ██████░░░░░░░░░░░░░░░░  handlers    14%  (16)
  ████░░░░░░░░░░░░░░░░░░  tests       10%  (12)
  ████░░░░░░░░░░░░░░░░░░  mocks        9%  (11)
  ██░░░░░░░░░░░░░░░░░░░░  outros       9%  (10)
```

Barra de 22 chars. `█` proporcional ao %. Usar para distribuicao de arquivos, cobertura, risco.

---

## Palette de Emojis (cores no terminal)

O terminal Catppuccin Mocha renderiza tudo em amber monocromo EXCETO alguns emojis que mantem cor propria. Esta palette foi testada e validada — so usar emojis desta lista.

### REGRA: emojis que NAO funcionam (viram listrado/amber)

NAO usar: 🟢 🟡 🟠 🟣 🟥 🟧 🟨 🟩 🟦 🟪 ❗ ❓ ⭐ ‼️

### Status / Resultado

| Emoji | Cor real | Significado | Quando usar |
|-------|---------|-------------|-------------|
| 💚 | verde | OK / passou / limpo | Check que passou, item completo |
| 🧡 | laranja | Warning / atencao | Nao bloqueia mas merece revisao |
| 🔴 | vermelho | Blocker / erro | Deve ser corrigido, bloqueia aprovacao |
| ⚪ | neutro | Pendente / nao verificado | Ainda nao inspecionado |
| 💙 | azul | Novo / adicionado | Arquivo ou funcao nova |
| 🔶 | laranja | Modificado | Arquivo ou funcao alterada |
| 🔵 | teal | Info / referencia | Contexto, sem acao necessaria |

### Camadas / Tipos

| Emoji | Significado | Quando usar |
|-------|-------------|-------------|
| 🔹 | Migration / DB | Tabelas, colunas, SQL |
| 🔸 | Entity / struct | Tipos, modelos de dados |
| 🔹 | Repository / repo | Acesso a dados, queries |
| ⚙️ | Service | Logica de negocio |
| 🚪 | Handler / endpoint | Porta de entrada HTTP |
| 👷 | Worker / async | Jobs SQS, background |
| 🧪 | Teste | Test files, cobertura |
| 📋 | Config | YAML, env, feature flags |

### Recursos / Infra

| Emoji | Significado | Quando usar |
|-------|-------------|-------------|
| ⚡ | Redis / cache rapido | Cache volatil |
| 💾 | JSONB / persist | Cache duradouro, banco |
| 📨 | SQS / fila | Mensagens async |
| 🔒 | Guard / protecao | Locks, checks antes de acao |

### Barras coloridas

Usar diamantes coloridos + quadrado preto para barras com cor real:
```
  🔷🔷🔷🔷🔷⬛⬛⬛  62%  (azul)
  🔶🔶🔶⬛⬛⬛⬛⬛  37%  (laranja)
  🔴🔴⬛⬛⬛⬛⬛⬛  25%  (vermelho)
```

Para barras sem cor: `██░░░░` (unicode block chars)

### Exemplos com emojis testados

**Mapa de caixas:**
```
  #   Camada  Nome                     Status
  1   🔹     add content_tree_cache   💙 nova
  2   🔸     Course (2 campos)        🔶 mod
  3   🔹     cache.go + SaveCache     💙 nova
  4   ⚙️     BuildAndSaveContentTree  💙 nova
  5   🚪     GET /toc                 💙 novo
  6   👷     HandleBuildCourseToc     💙 novo
  7   🧪     build_test.go           💙 novo
```

**Checklist de inspecao:**
```
  💚 ctx propagado ate o repo (L22)
  💚 Error handling em todos os paths (L23, L35)
  🔴 Goroutine sem sync — go SaveToJSONB (L38)
  🧡 log.Printf em vez de elogger (2 ocorrencias)
```

**Veredito:**
```
  🔴 Blockers:    2
  🧡 Warnings:    4
  💚 Clean:       12 checks OK
```

**Fluxo com emojis:**
```
  🚪 Handler GET /toc
    │
    ├── ⚡ cache HIT → Response
    │
    └── ⚡ cache MISS
          │
          ▼
        ⚙️ BuildAndSaveContentTree
          ├── ⚡ save Redis (graceful)
          ├── 💾 save JSONB (graceful)
          └── Response
```

**Matriz de cobertura:**
```
                          🧪unit  🧪integ  mock
  ⚙️ BuildAndSave          💚      ⚪       💚
  ⚙️ GetOrBuildCachedTOC   💚      ⚪       💚
  ⚙️ TriggerByCourseIDs    💚      ⚪       💚
  👷 HandleBuildCourseToc   💚      ⚪       ⚪
  🚪 GetCourseStructure    ⚪      ⚪       ⚪  ◄── 🔴 gap
```

**Arvore de arquivos:**
```
  apps/ldi/
  ├── 🔹 migration/
  │   └── 💙 2026030512_add_content_tree.sql
  ├── 🔸 entities/
  │   └── 🔶 course.go
  ├── ⚙️ services/course/
  │   ├── 💙 build_and_save_content_tree.go
  │   ├── 💙 get_course_toc_complete.go
  │   └── 🔶 getCourseChapters.go
  ├── 🚪 handlers/
  │   └── 💙 get_course_structure.go
  └── 👷 handlers/course/
      └── 💙 worker.go
```

**State machine:**
```
  ⚪ IDLE ──publish──→ 🔶 REBUILDING ──done──→ 💚 CACHED
    ▲                       │                     │
    │                       │ fail                │ invalidate
    │                       ▼                     │
    └─────────────────── 🔴 FAILED ◄─────────────┘
```

**Kanban:**
```
  ⚪ TODO            🔵 DOING           💚 DONE
  ─────────────      ─────────────      ─────────────
  🧪 teste integ    🔧 fix CI flaky    🔹 migration
  📋 doc swagger    👷 worker DLQ      🔸 entity
                                        🔹 repo cache
                                        ⚙️ service core
                                        🚪 handler BFF
```

**Grafico de proporcao:**
```
  ⚙️ services  🔷🔷🔷🔷🔷🔷🔷🔷⬛⬛  40%  (47)
  🔸 structs   🔷🔷🔷🔷⬛⬛⬛⬛⬛⬛  18%  (21)
  🚪 handlers  🔶🔶🔶⬛⬛⬛⬛⬛⬛⬛  14%  (16)
  🧪 tests     🔷🔷⬛⬛⬛⬛⬛⬛⬛⬛  10%  (12)
  📋 outros    🔷⬛⬛⬛⬛⬛⬛⬛⬛⬛   9%  (10)
```

---

## 19. Stacked Bar Vertical (Termômetro)

Para mostrar proporção de budget/capacidade com múltiplas camadas empilhadas.

### Variante A — escala grossa (visão geral, 1 linha = 10k)

```
╔════╗ 200k
║    ║
║    ║
║    ║  livre / disponível
║    ║  ~176k  88%
║    ║
╠════╣ ←24k
║▓▓▓▓║  camada pesada    18k   9%
╠════╣ ←6k ─────────────────────
║░░░░║  sub-camada A     2.9k  1.5%
║▒▒▒▒║  sub-camada B     1.5k  0.8%
║····║  sub-camada C     0.8k  0.4%
║····║  sub-camada D     0.7k  0.4%
╚════╝ 0k
       ──────────────────────────
       grupo inferior    ~6k   3%
       overhead total   ~24k  12%
```

### Variante B — escala fina (1 linha = 2k, zoom no overhead)

```
╔══════╗ 24k
║      ║ 24k
╠══════╣ ←22k
║▓▓▓▓▓▓║ 22k  Claude Code sys
║▓▓▓▓▓▓║ 20k  ·
║▓▓▓▓▓▓║ 18k  ·
║▓▓▓▓▓▓║ 16k  ·
║▓▓▓▓▓▓║ 14k  ·
║▓▓▓▓▓▓║ 12k  ·
║▓▓▓▓▓▓║ 10k  ·
║▓▓▓▓▓▓║  8k  ·   18k total  9%
╠══════╣ ← 6k ──────────────────
║░░░░░░║  6k  MEMORY.md   2.9k
║░░    ║  4k  ·
╠══════╣ ← 3k
║▒▒▒▒  ║  3k  CLAUDE.md   1.5k
╠══════╣ ← 1.5k
║····  ║  1.5k SKILLS      0.8k
║·     ║  0.8k BOOT+vennon  0.7k
╚══════╝  0k
          ──────────────────────
          nosso boot   ~6k   3%
          total        ~24k  12%
          livre        ~176k 88%
```

### Variante C — duplo painel (macro + zoom lado a lado)

```
  200k ╔══╗      24k ╔══════╗
       ║  ║          ║▓▓▓▓▓▓║ CC sys  18k
       ║  ║   zoom   ╠══════╣
       ║  ║  ──────► ║░░░░░░║ MEM    2.9k
       ║  ║          ║▒▒▒▒  ║ CL.MD  1.5k
  24k  ╠══╣          ║····  ║ SKL    0.8k
       ║▓▓║          ║·     ║ BOOT   0.7k
   6k  ╠══╣       0k ╚══════╝
       ║░▒║
    0k ╚══╝
```

**Regras de construção:**
- **Variante A:** visão rápida, 1 linha ≈ 10k — use quando o livre domina e detalhe é secundário
- **Variante B:** zoom no overhead, 1 linha ≈ 2k — use quando quer detalhar os grupos menores
- **Variante C:** duplo painel — macro (escala total) + micro (zoom) lado a lado
- Preenchimento: `▓▓` pesado / `░░` médio / `▒▒` leve / `··` mínimo / vazio = livre/disponível
- Marcadores laterais: `←Nk` nos pontos de divisão entre grupos
- Rodapé: totais por grupo + % do budget total

**Quando usar:** distribuição de tokens, memória, storage, budget de qualquer recurso com escala grande onde 1-2 itens dominam e o restante é detalhe.

---

## Convencoes visuais

| Simbolo | Significado |
|---------|-------------|
| `──▶` | Chamada para outra funcao/caixa |
| `◄──` | Anotacao apontando algo relevante |
| `L<N>` | Numero da linha no arquivo |
| `[algo]` | Recurso externo (Redis, JSONB, SQS, DB) |
| `├── / └──` | Branch de if/else ou switch |
| `▼` | Fluxo continua abaixo |
| `→` | Seta de fluxo horizontal |
| `(async)` | Operacao assincrona |
| `──HIT──→ / └─MISS─→` | Resultado de cache check |
| `+ / ~ / x` | Novo / modificado / removido (modo texto) |
| `[ok] / [!!] / [XX]` | Passou / warning / blocker (modo texto) |
| `█ / ░` | Barra cheia / vazia (monocromo) |
| `🔷 / ⬛` | Barra cheia / vazia (azul) |
| `🔶 / ⬛` | Barra cheia / vazia (laranja) |
| `🔴 / ⬛` | Barra cheia / vazia (vermelho) |
| 💚 🧡 🔴 ⚪ | OK / warning / blocker / pendente |
| 💙 🔶 | Novo / modificado |
| 🔹🔸⚙️🚪👷🧪📋 | Camada (db/entity/svc/handler/worker/test/config) |
| ⚡💾📨🔒 | Recurso (Redis/JSONB/SQS/guard) |
