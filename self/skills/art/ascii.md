---
name: art/ascii
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
| `+ / ~ / x` | Novo / modificado / removido |
| `[ok] / [!!] / [XX]` | Passou / warning / blocker |
| `█ / ░` | Barra cheia / barra vazia |
