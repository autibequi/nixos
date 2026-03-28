# Template do Changelog Visual

Formato de saída do changelog. Substituir os valores de exemplo pelos dados reais extraídos do diff. Omitir categorias vazias e repositórios sem mudanças.

**Status icons:** ✅ Novo, ✏️ Modificado, ❌ Deletado

---

```
# 📋 Changelog — Branch: `<nome-da-branch>`

---

## 🔧 monolito (N arquivos alterados, N commits)

### 🗄️ Migrations
| Status | Migration | Descrição |
|--------|-----------|-----------|
| ✅ Nova | `20240301_add_column_cpf.sql` | Adiciona coluna `cpf` (VARCHAR) na tabela `alunos` |

### 📦 Entities / Models
| Status | Struct | Campos |
|--------|--------|--------|
| ✅ Nova | `AlunoEntity` | `ID int64`, `Nome string`, `CPF string` |
| ✏️ Modificada | `PedidoEntity` | + `Status string`, + `DataCancelamento *time.Time` |

### 📂 Repositories
| Status | Interface | Método | Assinatura |
|--------|-----------|--------|------------|
| ✅ Novo | `AlunoRepositoryInterface` | `BuscarPorCPF` | `(ctx context.Context, cpf string) (*entities.Aluno, error)` |
| ✏️ Modificado | `PedidoRepositoryInterface` | `Cancelar` | `(ctx context.Context, id int64) error` |

### ⚙️ Services
| Status | Service | Método | Assinatura |
|--------|---------|--------|------------|
| ✅ Novo | `AlunoService` | `BuscarHistorico` | `(ctx context.Context, alunoID int64, filtros FiltroHistorico) ([]Historico, error)` |

### 🌐 Handlers / Endpoints
| Status | Método HTTP | Rota | Handler |
|--------|-------------|------|---------|
| ✅ Novo | `POST` | `/bo/alunos/historico` | `GetHistorico` |
| ✏️ Modificado | `PUT` | `/bo/pedidos/:id/cancelar` | `CancelarPedido` |

### 👷 Workers
| Status | Worker | Descrição |
|--------|--------|-----------|
| ✅ Novo | `ProcessarPagamentoWorker` | Consome fila `pagamentos.processar` |

### 🧪 Testes
- `TestBuscarHistorico_Sucesso`
- `TestBuscarHistorico_AlunoNaoEncontrado`

### 📄 Outros
- `config/routes.go` — registro de nova rota

---

## 🖥️ bo-container (N arquivos alterados, N commits)

### 🔌 Services
| Status | Service | Método | Endpoint |
|--------|---------|--------|----------|
| ✅ Novo | `AlunoService` | `fetchHistorico(alunoId, filtros)` | `POST /bo/alunos/historico` |

### 🗺️ Routes
| Status | Path | Name | Page |
|--------|------|------|------|
| ✅ Nova | `/alunos/historico` | `alunos-historico` | `HistoricoPage` |

### 📄 Pages
| Status | Page | Props/Data | Métodos |
|--------|------|------------|---------|
| ✅ Nova | `HistoricoPage.vue` | `filtros`, `historico[]` | `fetchData()`, `handleFiltrar()` |

### 🧩 Components
| Status | Componente | Props | Eventos |
|--------|------------|-------|---------|
| ✅ Novo | `HistoricoModal.vue` | `isOpen: Boolean`, `alunoId: Number` | `@close`, `@confirm` |
| ✏️ Modificado | `AlunoCard.vue` | + `showHistorico: Boolean` | + `@click-historico` |

### 📄 Outros
- `src/modules/alunos/index.js` — registro do novo módulo

---

## 📱 front-student (N arquivos alterados, N commits)

### 🔌 Services
| Status | Service | Método | Endpoint |
|--------|---------|--------|----------|
| ✅ Novo | `historicoService` | `getHistorico(page, perPage)` | `GET /bff/alunos/historico` |

### 📄 Pages
| Status | Page | Rota (implícita) | Layout | Middleware |
|--------|------|-------------------|--------|------------|
| ✅ Nova | `pages/historico/index.vue` | `/historico` | `navigation` | `authenticated` |

### 📦 Containers
| Status | Container | Métodos | Estado |
|--------|-----------|---------|--------|
| ✅ Novo | `HistoricoContainer.vue` | `fetchData()`, `handlePageChange()` | `items[]`, `currentPage` |

### 🧩 Components
| Status | Componente | Props | Eventos |
|--------|------------|-------|---------|
| ✅ Novo | `HistoricoCard.vue` | `item: Object` | `@click` |

### 📄 Outros
- `modules/historico/index.js` — registro do módulo

---

## 📊 Resumo

| Repositório | Arquivos | Novos | Modificados | Deletados |
|-------------|----------|-------|-------------|-----------|
| monolito | 12 | 8 | 3 | 1 |
| bo-container | 6 | 5 | 1 | 0 |
| front-student | 4 | 4 | 0 | 0 |
| **Total** | **22** | **17** | **4** | **1** |
```
