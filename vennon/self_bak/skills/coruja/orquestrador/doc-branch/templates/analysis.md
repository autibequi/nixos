# Template: Análise Interna do Diff

Formato interno usado durante o Passo 2 para registrar o que foi extraído de cada arquivo.
Não é apresentado ao dev — serve como estrutura de trabalho durante a análise.

---

## Estrutura da Análise

```
## Análise — <repo> (<N> arquivos, <N> commits)

| Arquivo | Status | Categoria | Resumo |
|---------|--------|-----------|--------|
| `internal/domain/entities/matricula.go` | M | 📦 Entidades | + campo `Status string`, + campo `DataVencimento *time.Time` |
| `internal/infra/database/migrations/20260315_add_status_matriculas.sql` | A | 🗄️ Banco de Dados | Nova coluna `status VARCHAR(50) NOT NULL DEFAULT 'ativa'` em `matriculas` |
| `internal/domain/services/matricula_service.go` | M | ⚙️ Lógica de Negócio | + método `Cancelar(ctx, id, motivo)`, + método `calcularDesconto(valor, tipo)` |
| `internal/infra/http/handlers/matricula_handler.go` | M | 🔌 Endpoints | + POST /bo/matriculas, + GET /bo/matriculas/:id, M GET /bo/matriculas (filtro status) |
| `src/services/MatriculaService.js` | A | 🔌 Endpoints Consumidos | + `criar(payload)` → POST /bo/matriculas, + `buscar(id)` → GET /bo/matriculas/:id |
| `src/pages/matriculas/index.vue` | A | 🖥️ Telas | Nova tela Listagem de Matrículas, filtros por status |
```

**Status:** `A` = Adicionado, `M` = Modificado, `D` = Deletado

---

## Detalhamento por Categoria

### 🗄️ Banco de Dados

```
Migration: 20260315_add_status_matriculas.sql
  Tabela: matriculas
  Ação: ADD COLUMN status VARCHAR(50) NOT NULL DEFAULT 'ativa'
  Ação: ADD COLUMN data_vencimento TIMESTAMP NULL
  Constraint: CHECK status IN ('ativa', 'cancelada', 'concluida')
```

### 📦 Entidades

```
Struct: MatriculaEntity (internal/domain/entities/matricula.go)
  + Status         string     `json:"status"`
  + DataVencimento *time.Time `json:"data_vencimento,omitempty"`
```

### 📂 Repositories

```
Interface: MatriculaRepositoryInterface
  + BuscarPorStatus(ctx context.Context, status string) ([]entities.Matricula, error)
  + Cancelar(ctx context.Context, id int64, motivo string) error
```

### ⚙️ Lógica de Negócio

```
Service: MatriculaService
  + Cancelar(ctx context.Context, id int64, motivo string) error
    Regra: valida se status atual é 'ativa' antes de cancelar
    Regra: registra motivo no campo obs_cancelamento
  + calcularDesconto(valor float64, tipo string) float64  [privado]
    Regra: tipo 'antecipado' → 10%, tipo 'fidelidade' → 15%, default → 0%
```

### 🔌 Endpoints (Go — handlers)

```
Handler: MatriculaHandler
  + POST   /bo/matriculas           body: {aluno_id, curso_id, tipo_desconto?}  response: MatriculaResponse
  + GET    /bo/matriculas/:id       response: MatriculaResponse com status
  M GET    /bo/matriculas           + query param: ?status=ativa|cancelada|concluida
```

### 🔌 Endpoints Consumidos (Frontend)

```
Service: MatriculaService (bo-container)
  + criar(payload)   → POST /bo/matriculas
  + buscar(id)       → GET  /bo/matriculas/:id
  + listar(filtros)  → GET  /bo/matriculas?status=...
```

### 🖥️ Telas / Fluxos

```
Page: /matriculas/index.vue (bo-container)
  Rota: /matriculas
  Fluxo: lista matrículas com filtro por status, botão "Nova Matrícula" abre modal
  Props consumidas: nenhuma (standalone page)

Page: /matriculas/_id.vue (bo-container) [se houver detalhe]
  Rota: /matriculas/:id
  Fluxo: detalhe da matrícula com botão "Cancelar"
```

### 🧩 Componentes

```
Component: MatriculaStatusBadge.vue
  Props: status (String, required) — 'ativa' | 'cancelada' | 'concluida'
  Emits: nenhum
  Uso: badge colorido por status

Component: ModalNovaMatricula.vue
  Props: visible (Boolean), cursos (Array)
  Emits: close, saved
```

### ⏱️ Workers

```
Worker: MatriculaVencimentoWorker
  Trigger: cron diário 08:00
  Job: busca matrículas com data_vencimento < now(), atualiza status para 'vencida'
```

---

## Legenda

- **A** — Arquivo novo (adicionado)
- **M** — Arquivo existente modificado
- **D** — Arquivo deletado
- Arquivos de teste/mock: listar mas não detalhar
- Arquivos de config sem mudança semântica (ex: go.sum, yarn.lock): ignorar
