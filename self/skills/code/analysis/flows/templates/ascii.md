# Template: Diagramas ASCII de Fluxo

Referencia para desenhar fluxos de codigo no terminal. Usar quando Chrome nao esta disponivel ou o output precisa ser inline (pr-inspector, code review, explicacoes rapidas).

---

## 1. Mini-guia horizontal (overview)

Sempre comecar com uma linha compacta mostrando a sequencia de chamadas. O dev bate o olho e entende o caminho antes de mergulhar no detalhe.

### Padroes por tipo de fluxo

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

**Pipeline (cadeia de transformacoes):**
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

---

## 2. Deep-dive vertical (caixa por caixa)

Abaixo do mini-guia, expandir cada passo como uma caixa com logica interna.

### Template de caixa

```
  ┌─────────────────────────────────────────────────────────────┐
  │  <CAMADA>: <NomeFuncao>                                     │
  │  <path/relativo/ao/arquivo.go>                              │
  │                                                             │
  │  L<N>  <operacao>                                           │
  │  L<N>  <operacao>                                           │
  │           │                                                 │
  │           ├── <condicao TRUE>                               │
  │           │     └─ <resultado>                              │
  │           │                                                 │
  │           └── <condicao FALSE>                              │
  │                 │                                           │
  │                 ▼                                           │
  │  L<N>  <proxima chamada>  ──▶ (proxima caixa)              │
  │                                                             │
  │  L<N>  return <resultado>                                   │
  └─────────────────────────────────────────────────────────────┘
      │
      ▼
  ┌─────────────────────────────────────────────────────────────┐
  │  <PROXIMA CAIXA>                                            │
  │  ...                                                        │
  └─────────────────────────────────────────────────────────────┘
```

### Template de logica interna (dentro da caixa)

**If/else:**
```
  L25  resultado := BuscaAlgo(id)
           │
           ├── resultado != nil ──▶ return resultado   (happy path)
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
           ├── go: BuscaCapitulo(cap[0])
           ├── go: BuscaCapitulo(cap[1])
           └── go: BuscaCapitulo(cap[2])
           │
           ▼
  L80  Wait() → consolida resultados
```

**Loop com SQS:**
```
  L50  for _, courseID := range courseIDs {
           │
           ├── Marshal(msg)
           │     └── err? → failedCount++ → continue
           │
           └── sqsClient.Send(msg)
                 └── err? → failedCount++ → continue
       }
```

**Graceful degradation (falha tolerada):**
```
  L36  SaveCache(Redis, key, data)
           └── err? → loga e continua  (graceful)

  L49  UpdateProperties(JSONB, course)
           └── err? → loga e continua  (graceful)

  L54  return structure, nil   ◄── sempre retorna sucesso
```

---

## 3. Diagrama de fluxo completo (multi-path)

Para features com read + write + guard, usar secoes separadas:

```
══════════════════════════════════════════════════════
  <TITULO DA FEATURE>
══════════════════════════════════════════════════════

  === READ PATH (<descricao curta>) ===

    [origem] → [handler] → [service] → [repo] → [response]
                               │
                               ├── HIT → response
                               └── MISS → build → save → response

  === WRITE PATH (<descricao curta>) ===

    [trigger] → [service] → [SQS] → [worker] → [build] → [save]

  === GUARD PATH (<descricao curta>) ===

    [handler] → [check] ──active──→ 409
                        └─clear──→ prossegue
```

---

## 4. Convencoes visuais

| Simbolo | Significado |
|---------|-------------|
| `──▶` | Chamada para outra funcao/caixa |
| `◄──` | Anotacao apontando algo relevante |
| `L<N>` | Numero da linha no arquivo |
| `[algo]` | Recurso externo (Redis, JSONB, SQS, DB) |
| `├── / └──` | Branch de if/else ou switch |
| `▼` | Fluxo continua abaixo |
| `(async)` | Operacao assincrona |
| `→` | Seta de fluxo horizontal |
| `──HIT──→ / └─MISS─→` | Resultado de cache check |
| `+ / ~ / x` | Novo / modificado / removido |

---

## 5. Quando usar cada nivel

| Situacao | O que mostrar |
|----------|---------------|
| "me mostra o fluxo" | Mini-guia horizontal so |
| "me explica esse handler" | Mini-guia + deep-dive vertical |
| "quero entender a feature inteira" | Diagrama multi-path completo |
| Inspecao de PR (pr-inspector) | Todos os 3 niveis progressivamente |
| `/code review` | Diagrama multi-path (Fase 3) |
| `/code flows` | Mermaid no Chrome (usar `templates/html.md`) |
