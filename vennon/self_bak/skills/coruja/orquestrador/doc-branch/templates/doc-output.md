# Template: Formato dos Documentos Gerados

Formato padrão para cada arquivo de artefato gerado pelo `doc-branch`.
Substituir os valores de exemplo pelos dados reais extraídos do diff.

---

## `README.md` — Overview da Branch/Feature

```markdown
# <Jira ID ou nome da branch> — <título descritivo>

> Documentação gerada automaticamente em <data> via `doc-branch`

## Escopo

<2-3 frases descrevendo o que essa feature/branch implementa>

## Repos Modificados

| Repo | Mudanças |
|------|---------|
| monolito | N arquivos — handlers, services, migrations |
| bo-container | N arquivos — pages, services |
| front-student | N arquivos — pages, services |

## Artefatos

- [API Endpoints](./api.md)
- [Schema / Banco de Dados](./schema.md)
- [Regras de Negócio](./regras.md)
- [Telas e Fluxos](./fluxos.md)

## Resumo das Mudanças

- 🗄️ N migrations (tabelas: `x`, `y`)
- 🔌 N endpoints novos, N alterados
- ⚙️ N regras de negócio implementadas
- 🖥️ N telas novas
```

---

## `api.md` — Endpoints da API

```markdown
# API Endpoints — <Jira ID ou branch>

> Base URL: `https://api.estrategia.com`
> Autenticação: Bearer token (header `Authorization`)

---

## POST /bo/matriculas

**Descrição:** Cria uma nova matrícula para um aluno em um curso.

**Request Body:**
```json
{
  "aluno_id": 123,
  "curso_id": 456,
  "tipo_desconto": "antecipado"  // opcional: "antecipado" | "fidelidade"
}
```

**Response 201:**
```json
{
  "id": 789,
  "aluno_id": 123,
  "curso_id": 456,
  "status": "ativa",
  "data_criacao": "2026-03-15T10:00:00Z"
}
```

**Erros:**
| Código | Condição |
|--------|----------|
| 400 | aluno_id ou curso_id inválidos |
| 409 | Matrícula já existe para esse aluno/curso |

---

## GET /bo/matriculas/:id

**Descrição:** Retorna os dados de uma matrícula pelo ID.

**Path Params:**
| Param | Tipo | Descrição |
|-------|------|-----------|
| id | int64 | ID da matrícula |

**Response 200:**
```json
{
  "id": 789,
  "aluno_id": 123,
  "curso_id": 456,
  "status": "ativa",
  "data_vencimento": null
}
```

---

## GET /bo/matriculas

**Descrição:** Lista matrículas com filtros opcionais.

**Query Params:**
| Param | Tipo | Descrição |
|-------|------|-----------|
| status | string | Filtrar por status: `ativa`, `cancelada`, `concluida` |
| aluno_id | int64 | Filtrar por aluno |
| page | int | Paginação (default: 1) |
| per_page | int | Itens por página (default: 20, max: 100) |
```

---

## `schema.md` — Schema / Banco de Dados

```markdown
# Schema — <Jira ID ou branch>

---

## Tabela: `matriculas`

### Alterações nessa branch

| Migration | Tipo | Coluna | Definição |
|-----------|------|--------|-----------|
| `20260315_add_status_matriculas` | ADD COLUMN | `status` | `VARCHAR(50) NOT NULL DEFAULT 'ativa'` |
| `20260315_add_status_matriculas` | ADD COLUMN | `data_vencimento` | `TIMESTAMP NULL` |
| `20260315_add_status_matriculas` | ADD CONSTRAINT | `chk_status` | `CHECK (status IN ('ativa', 'cancelada', 'concluida'))` |

### Schema Resultante (colunas relevantes)

```sql
CREATE TABLE matriculas (
  id              BIGSERIAL PRIMARY KEY,
  aluno_id        BIGINT NOT NULL REFERENCES alunos(id),
  curso_id        BIGINT NOT NULL REFERENCES cursos(id),
  status          VARCHAR(50) NOT NULL DEFAULT 'ativa',
  data_vencimento TIMESTAMP NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### Índices Adicionados

```sql
CREATE INDEX idx_matriculas_status ON matriculas(status);
CREATE INDEX idx_matriculas_data_vencimento ON matriculas(data_vencimento) WHERE data_vencimento IS NOT NULL;
```
```

---

## `regras.md` — Regras de Negócio

```markdown
# Regras de Negócio — <Jira ID ou branch>

---

## Cancelamento de Matrícula

**Implementado em:** `MatriculaService.Cancelar()` — `internal/domain/services/matricula_service.go`

**Descrição:** Cancela uma matrícula ativa, registrando o motivo.

**Pré-condições:**
- Matrícula deve existir
- Status atual deve ser `ativa` (não permite cancelar `concluida` ou já `cancelada`)

**Fluxo:**
1. Buscar matrícula por ID
2. Validar status atual == 'ativa'
3. Atualizar status → 'cancelada'
4. Registrar motivo em `obs_cancelamento`
5. Disparar evento `MatriculaCancelada` (se houver listeners)

**Erros tratados:**
| Condição | Erro retornado |
|----------|----------------|
| Matrícula não encontrada | `ErrMatriculaNaoEncontrada` |
| Status != 'ativa' | `ErrMatriculaNaoCancelavel` |

---

## Cálculo de Desconto

**Implementado em:** `MatriculaService.calcularDesconto()` (privado)

**Regras:**
| Tipo | Desconto |
|------|---------|
| `antecipado` | 10% sobre o valor |
| `fidelidade` | 15% sobre o valor |
| Qualquer outro / vazio | 0% |
```

---

## `fluxos.md` — Telas e Fluxos

```markdown
# Telas e Fluxos — <Jira ID ou branch>

---

## Listagem de Matrículas (bo-container)

**Rota:** `/matriculas`
**Arquivo:** `src/pages/matriculas/index.vue`

**Descrição:** Tela principal de gerenciamento de matrículas, com filtros e ações.

**Funcionalidades:**
- Lista matrículas com paginação
- Filtro por status (ativa / cancelada / concluida)
- Botão "Nova Matrícula" → abre `ModalNovaMatricula`
- Coluna status exibe `MatriculaStatusBadge` com cor por status
- Ação "Cancelar" disponível para matrículas com status `ativa`

**Fluxo de criação:**
1. Dev clica "Nova Matrícula"
2. Modal abre com form (aluno, curso, desconto)
3. Submit → `MatriculaService.criar(payload)`
4. Sucesso → fecha modal, recarrega lista
5. Erro → exibe mensagem inline no form

---

## Componente: MatriculaStatusBadge

**Arquivo:** `src/components/MatriculaStatusBadge.vue`

**Props:**
| Prop | Tipo | Obrigatório | Descrição |
|------|------|-------------|-----------|
| status | String | Sim | `'ativa'` \| `'cancelada'` \| `'concluida'` |

**Emits:** nenhum

**Visual:**
| Status | Cor |
|--------|-----|
| ativa | verde |
| cancelada | vermelho |
| concluida | cinza |
```
