---
name: code/analysis/componentes
description: Gera diagrama ASCII de componentes da feature atual — dividido em PRODUCE QUEUE, CONSUME QUEUE e ENDPOINTS. Cada caixa tem emoji de camada, comentário descritivo de produto e estilo visual diferenciado por tipo. Output no terminal.
---

# code/analysis/componentes — Diagrama de Componentes ASCII

Gera um diagrama estruturado com 3 seções separadas por ruler, explicando o fluxo da feature em termos de produto — não só código.

## Argumentos

```
/code:analysis:componentes [--repo monolito|bo|front] [--branch <branch>]
```

Defaults: repo inferido pelo cwd, branch atual.

## Passo 1 — Detectar arquivos modificados por camada

```bash
git diff origin/main --name-only
```

Classificar por camada:
- `apps/bff/` ou `apps/bo/` → HANDLER
- `internal/services/` → SERVICE
- `internal/repositories/` → REPO
- `internal/handlers/` + `event_container` → HANDLER (worker/consumer)
- `libs/worker/` ou `config_sqs` → SQS
- `migration/` → DB
- `structs/` → tipos compartilhados (não exibir como caixa própria)

## Passo 2 — Inferir seções

| Seção | O que entra |
|---|---|
| **PRODUCE QUEUE** | Gatilhos (serviços mutação) → SERVICE.TriggerX → SQS send |
| **CONSUME QUEUE** | SQS receive → HANDLER worker → SERVICE build → REPO → DB |
| **ENDPOINTS** | HANDLER BFF/BO → SERVICE read/write → REPO |

Se a feature não tem fila, omitir PRODUCE/CONSUME e usar só ENDPOINTS.

## Passo 3 — Montar o diagrama

### Regras de estilo por tipo de caixa

| Camada | Emoji | Estilo de borda | Exemplo header |
|---|---|---|---|
| Gatilhos/Eventos | ⚡ | `┌─┐` simples | `┌ ⚡ GATILHOS ───┐` |
| Service | ⚙️ | `┌─┐` arredondada | `┌ ⚙️  SERVICE ───┐` |
| Handler (worker/BFF/BO) | 🔌 | `┌─┐` simples | `┌ 🔌 HANDLER ───┐` |
| SQS / Queue | 📨 | `╔═╗` dupla | `╔ 📨 SQS ════╗` |
| Repo | 🗃️ | `┌─┐` simples | `┌ 🗃️  REPO ────┐` |
| DB | 🗄️ | `┌─┐` simples | `┌ 🗄️  DB ─────┐` |

### Regras de conteúdo das caixas

- **Linha 1:** nome do método/função/rota principal
- **Linha 2 (itálico conceitual):** comentário curto de produto — o que essa caixa faz em termos de negócio
- **Separador interno** `├──┤` quando há sub-itens (ex: resolveCourseIDs com branches)
- **Setas entre caixas:** `─▶` para sync, `go X()` na seta para async/goroutine

### Seções separadas por ruler

```
NOME DA SEÇÃO
________________________________________________________________________________
```

### Toggler / branches condicionais (ENDPOINTS)

Quando há bifurcação (ex: toggler ON/OFF, cache HIT/MISS):

```
  └──────────┬──────────────────────┬───────────┘
             │                      │
   label A   │                      │  label B
             ▼                      ▼
  ┌ ⚙️  SERVICE ──────┐  ┌ ⚙️  SERVICE ──────────────┐
  │  caminhoA()       │  │  caminhoB()               │
  └───────────────────┘  └──────────────┬────────────┘
```

## Passo 4 — Adicionar comentários de produto

Cada caixa deve ter uma linha descritiva **em termos de produto**, não de código:

- ❌ "chama courseRepository.UpdateProperties com ContentTreeCache"
- ✅ "snapshot da árvore salvo junto ao curso, evita queries no read"

Exemplos por camada:
- GATILHOS: "eventos que disparam remontagem da árvore de conteúdo"
- SERVICE trigger: "resolve qual(is) curso(s) precisam de rebuild a partir do evento"
- SQS produce: `LDI.BuildCourseToc   >>>`
- SQS consume: `>>> LDI.BuildCourseToc` + "fila com cursos aguardando rebuild do TOC"
- HANDLER worker: "consome a fila e delega o rebuild para o service"
- SERVICE build: "monta a árvore flat e persiste no campo JSONB do curso"
- DB: "snapshot da árvore salvo junto ao curso, evita queries no read"
- HANDLER BFF: "endpoint existente de retorno dos dados de curso pro aluno"
- SERVICE cache: "lê o JSONB sem queries extras"
- SERVICE fallback: "caminho original, mantido como fallback"

## Template de referência

```
  PRODUCE QUEUE
  ________________________________________________________________________________

  ┌ ⚡ GATILHOS ─────────────────────────────────────────────────────────┐
  │  eventos que disparam remontagem da árvore de conteúdo               │
  ├──────────────────────────────────────────────────────────────────────┤
  │  MutacaoA · MutacaoB                            opts: ItemID          │
  │  MutacaoC · MutacaoD                            opts: CourseIDs       │
  └──────────────────────────────┬───────────────────────────────────────┘
                                 │
                                 ▼
  ┌ ⚙️  SERVICE ─────────────────────────────────────────────────────────┐
  │  XService.TriggerX(opts)                                             │
  │  resolve qual(is) entidade(s) precisam de rebuild                    │
  ├──────────────────────────────────────────────────────────────────────┤
  │  resolveIDs()                                                        │
  │  ├─ IDs diretos  ─▶  usa direto                                      │
  │  └─ ItemID       ─▶  repo.GetXFromY()                                │
  └──────────────────────────────┬───────────────────────────────────────┘
                                 │  go doTriggerX()
                                 ▼
  ╔ 📨 SQS ═══════════════════════════════════════════╗
  ║  QUEUE.NomeDaFila                            >>>  ║
  ╚═══════════════════════════════════════════════════╝


  CONSUME QUEUE
  ________________________________________________________________________________

  ╔ 📨 SQS ═══════════════════════════════════════════╗
  ║  >>>  QUEUE.NomeDaFila                            ║
  ║  descrição de produto da fila                     ║
  ╚═══════════════════════╦══════════════════════════╝
                          ║
                          ▼
  ┌ 🔌 HANDLER ────────────────────────────────────────────────────────┐
  │  event_container  ─▶  HandleX                                      │
  │  consome a fila e delega para o service                            │
  └────────────────────────────────┬──────────────────────────────────┘
                                   │
                                   ▼
  ┌ ⚙️  SERVICE ─────────────────────────────────────────────────────────┐
  │  XService.BuildAndSave(id)                                          │
  │  descrição de produto do que é construído e persistido              │
  ├─────────────────────────────────────────────────────────────────────┤
  │  GetData() → Convert() → flatten()                                  │
  └─────────────────────────────────┬───────────────────────────────────┘
                                    │
                                    ▼
  ┌ 🗃️  REPO ───────────────────────────────────────────────────────────┐
  │  repo.UpdateProperties()                                            │
  └─────────────────────────────────┬───────────────────────────────────┘
                                    │
                                    ▼
  ┌ 🗄️  DB ─────────────────────────────────────────────────────────────┐
  │  tabela.campo          JSONB                                        │
  │  descrição do dado persistido e seu propósito                       │
  └─────────────────────────────────────────────────────────────────────┘


  ENDPOINTS
  ________________________________________________________________________________

  ┌ 🔌 HANDLER ────────────────────────────────────────────────────────┐
  │  BFF  GET /rota/:param  ─▶  NomeHandler                            │
  │  descrição de produto do endpoint                                  │
  └──────────────────────┬─────────────────────────┬───────────────────┘
                         │                         │
               toggler ON │                         │ toggler OFF
                         ▼                         ▼

  ┌ ⚙️  SERVICE ──────────────────┐  ┌ ⚙️  SERVICE ──────────────────────┐
  │  caminhoCache()               │  │  caminhoDB()                     │
  │  lê o JSONB sem queries extra │  │  caminho original, fallback       │
  ├───────────────────────────────┤  ├───────────────────────────────────┤
  │  ToStructure()                │  │  XService.GetList()              │
  │    └─▶  map para response     │  └───────────────────┬──────────────┘
  └───────────────────────────────┘                      │
                                                         ▼
                                     ┌ 🗃️  REPO ─────────────────────────┐
                                     │  repo.GetList()                   │
                                     └───────────────────────────────────┘
```
