---
name: code/pr-message
description: Gera mensagem de PR estruturada a partir do diff da branch atual contra main — lista o que foi implementado, cenários de teste (happy/sad) e dependências. Sempre escopo branch atual → main, sem misturar branches.
---

# code/pr-message — Mensagem de PR

Gera um documento markdown pronto para colar na descrição do PR, baseado **exclusivamente** no diff `origin/main...HEAD` da branch atual. Nunca mistura escopos de outras branches.

## Processo

### Passo 1 — Identificar branch e repo

```bash
cd /workspace/mnt/estrategia/monolito   # ou o repo ativo
git branch --show-current
git log --oneline origin/main..HEAD
```

### Passo 2 — Coletar diff (apenas adições)

```bash
# Commits adicionados vs main
git log --oneline origin/main..HEAD

# Arquivos alterados com stats
git diff origin/main...HEAD --stat

# Configs e infra relevantes (SQS, worker, migration)
git diff origin/main...HEAD -- configuration/ libs/worker/ '*.sql'
```

Focar apenas no que **entra** na main — ignorar arquivos removidos ou mocks que não revelam comportamento novo.

### Passo 3 — Montar seção "O que foi implementado"

Listar em bullets agrupados por camada, na ordem:
1. Migration (se houver)
2. Entity / Structs
3. Repository
4. Service
5. Worker / SQS
6. Handler BFF
7. Handler BO
8. Testes unitários relevantes

Formato de cada bullet:
```
- **<Camada>**: <descrição objetiva do que foi adicionado/alterado>
```

### Passo 4 — Montar tabela de testes

Incluir apenas Happy Path e Sad Path. Sem testes de integração complexos.

Formato da tabela:

| Cenário | Ação | Esperado |
|---------|------|----------|
| ✅ Happy — <nome> | `<ação concreta>` | `<HTTP status>` + descrição |
| ❌ Sad — <nome> | `<ação concreta>` | `<HTTP status>` + descrição |

Regras:
- Happy path: fluxos que devem funcionar normalmente
- Sad path: erros esperados com tratamento correto (409, 500, fallback, etc.)
- Sem checkboxes — tabela simples e copiável

### Passo 5 — Montar tabela de dependências

Incluir apenas dependências externas ao código (infra, config, toggler).

| Tipo | Item | Necessário antes do deploy? |
|------|------|----------------------------|
| Migration SQL | ... | ✅ Sim |
| Fila SQS | ... | ✅ Sim |
| Toggler | ... | Criar desligado (safe by default) |
| Wiring | ... | Incluso no PR |

### Passo 6 — Output final

Markdown simples, copiável. Sem diagramas. Sem headers de seção extras além dos três padrão.

Estrutura obrigatória:

```markdown
# <TICKET> — <Título da Feature>

## O que foi implementado

- **<Camada>**: ...

## Como testar

| Cenário | Ação | Esperado |
|---------|------|----------|
...

## Dependências

| Tipo | Item | Necessário antes do deploy? |
|------|------|----------------------------|
...
```

## Exemplo de output real

```markdown
# FUK2-11746 — TOC Async Builder (content_tree_cache)

## O que foi implementado

- **Migration**: Colunas `content_tree_cache` e `content_tree_cache_updated_at` em `ldi.courses`
- **Entity**: Campo `ContentTreeCache` na entidade `Course` + structs (`CachedContentTree`, `ErrTocRebuildRunning`, `BuildCourseTocMessage`)
- **Repository**: `GetItemIDsByCourseIDs` para resolver IDs de itens de um curso
- **Service**: `BuildAndSaveContentTree`, `TriggerTocRebuild`, `CheckTocRebuildConflict` no CourseService; propagação de `TriggerTocRebuild` em mutations de chapter, course_chapter e item
- **Worker**: Handler `LDI.BuildCourseToc` registrado em todos os ambientes (local, qa, sandbox, prod)
- **Handler BFF**: Serve TOC do cache quando toggler ativo; build síncrono se cache vazio; fallback para DB se toggler desligado
- **Handler BO**: Retorna `409 Conflict` com `{"jobs": [...]}` se rebuild em andamento

## Como testar

| Cenário | Ação | Esperado |
|---------|------|----------|
| ✅ Happy — toggler desligado | `GET /curso/:slug` sem toggler | `200` com TOC normal via DB |
| ✅ Happy — cache vazio | Ativar toggler + buscar curso sem cache | `200` + cache salvo no DB |
| ✅ Happy — cache populado | Buscar curso com cache existente | `200` servido do cache (sem query TOC no DB) |
| ✅ Happy — rebuild assíncrono | Editar capítulo via BO (sem rebuild ativo) | Mensagem enfileirada no SQS + cache atualizado |
| ❌ Sad — conflict guard | Editar curso com rebuild em andamento | `409` com `{"data": {"jobs": [...]}}` |
| ❌ Sad — cache corrompido | Cache com JSON inválido no DB | Fallback: build síncrono e salva novamente |

## Dependências

| Tipo | Item | Necessário antes do deploy? |
|------|------|----------------------------|
| Migration SQL | `ldi.courses` — colunas `content_tree_cache`, `content_tree_cache_updated_at` | ✅ Sim |
| Fila SQS | `LDI.BuildCourseToc` + `LDI.BuildCourseTocDLQ` (qa, sandbox, prod) | ✅ Sim |
| Toggler | `vertical/{vertical}/features/ldi_cached_toc_enabled` | Criar desligado (safe by default) |
| Wiring | `sqsClient` injetado no `CourseService`; `courseService` injetado no `ChapterService` | Incluso no PR |
```

## Flags opcionais

- `--save obsidian` — salva o output em `/workspace/obsidian/<TICKET>-release-notes.md`
- `--repo <nome>` — força um repo específico (default: detecta pelo cwd)
