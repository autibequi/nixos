---
name: code/pr-message
description: Gera mensagem de PR estruturada a partir do diff da branch atual contra main — busca card Jira em paralelo para contexto do motivador, lista o que foi implementado como solução, cenários de teste (happy/sad) e dependências. Sempre escopo branch atual → main.
---

# code/pr-message — Mensagem de PR

Gera um documento markdown pronto para colar na descrição do PR, baseado **exclusivamente** no diff `origin/main...HEAD` da branch atual. Nunca mistura escopos de outras branches.

## Processo

### Passo 1 — Identificar branch, ticket e repo (em paralelo com Passo 2)

```bash
cd /workspace/mnt/estrategia/monolito   # ou o repo ativo
git branch --show-current               # extrai o ticket do nome da branch (ex: FUK2-11746)
git log --oneline origin/main..HEAD
```

Extrair o ticket ID do nome da branch (padrão `FUK2-XXXXX/...`).

### Passo 2 — Buscar card Jira (em paralelo com Passo 1)

Usar `mcp__claude_ai_Atlassian__getJiraIssue` com o ticket extraído da branch.

Extrair do card:
- **Título** do card
- **Descrição** / motivador (por que esse card existe — problema, dor, contexto de negócio)
- **URL** do card para a seção de Referências

### Passo 3 — Coletar diff (apenas adições)

```bash
git log --oneline origin/main..HEAD
git diff origin/main...HEAD --stat
git diff origin/main...HEAD -- configuration/ libs/worker/ '*.sql'
```

Focar apenas no que **entra** na main — ignorar mocks e arquivos removidos.

### Passo 4 — Montar seção "Contexto"

Com base no card Jira, escrever 2–4 linhas em prosa descrevendo:
- Qual era o problema ou oportunidade
- Qual era o impacto (performance, UX, consistência, etc.)

Tom: objetivo, sem jargão de processo.

### Passo 5 — Montar seção "Solução"

Listar em bullets agrupados por camada, na ordem:
1. Migration (se houver)
2. Entity / Structs
3. Repository
4. Service
5. Worker / SQS
6. Handler BFF
7. Handler BO
8. Testes unitários relevantes

Tom: "para resolver isso, fizemos X" — conectar cada decisão técnica ao problema descrito no Contexto.

Formato de cada bullet:
```
- **<Camada>**: <o que foi feito e por quê resolve o problema>
```

### Passo 6 — Montar tabela de testes

Incluir apenas Happy Path e Sad Path. Sem testes de integração complexos.

| Cenário | Ação | Esperado |
|---------|------|----------|
| ✅ Happy — <nome> | `<ação concreta>` | `<HTTP status>` + descrição |
| ❌ Sad — <nome> | `<ação concreta>` | `<HTTP status>` + descrição |

Regras:
- Happy path: fluxos que devem funcionar normalmente
- Sad path: erros esperados com tratamento correto (409, 500, fallback, etc.)
- Sem checkboxes — tabela simples e copiável

### Passo 7 — Montar tabela de dependências

Incluir apenas dependências externas ao código (infra, config, toggler).

| Tipo | Item | Necessário antes do deploy? |
|------|------|----------------------------|
| Migration SQL | ... | ✅ Sim |
| Fila SQS | ... | ✅ Sim |
| Toggler | ... | Criar desligado (safe by default) |
| Wiring | ... | Incluso no PR |

### Passo 8 — Output final

Markdown simples, copiável. Sem diagramas.

Estrutura obrigatória:

```markdown
# <TICKET> — <Título>

## Contexto

<2–4 linhas descrevendo o problema/motivador vindo do Jira>

## Solução

- **<Camada>**: <o que foi feito conectado ao problema>

## Como testar

| Cenário | Ação | Esperado |
|---------|------|----------|
...

## Dependências

| Tipo | Item | Necessário antes do deploy? |
|------|------|----------------------------|
...

# Referências

- [<TICKET> — <Título do card>](<URL do Jira>)
```

## Exemplo de output real

```markdown
# FUK2-11746 — TOC Async Builder (content_tree_cache)

## Contexto

A construção do sumário de cursos (TOC) era feita sincronamente a cada request do BFF, consultando múltiplas tabelas do banco para montar a árvore de capítulos e itens. Em cursos grandes isso gerava latência perceptível e carga desnecessária no banco a cada visualização de curso pelo aluno.

## Solução

- **Migration**: Colunas `content_tree_cache` e `content_tree_cache_updated_at` em `ldi.courses` para persistir o TOC pré-computado
- **Entity**: Campo `ContentTreeCache` na entidade `Course` + structs (`CachedContentTree`, `ErrTocRebuildRunning`, `BuildCourseTocMessage`)
- **Repository**: `GetItemIDsByCourseIDs` para resolver IDs de itens de um curso durante o build do cache
- **Service**: `BuildAndSaveContentTree` computa e persiste o TOC; `TriggerTocRebuild` envia rebuild assíncrono via SQS sempre que o conteúdo muda; `CheckTocRebuildConflict` evita rebuilds simultâneos
- **Worker**: Handler `LDI.BuildCourseToc` processa a fila de rebuild em todos os ambientes (local, qa, sandbox, prod)
- **Handler BFF**: Serve o TOC direto do cache quando toggler ativo, eliminando as queries ao banco; build síncrono como fallback se cache vazio; fallback para DB se toggler desligado
- **Handler BO**: Retorna `409 Conflict` com `{"jobs": [...]}` se um rebuild já estiver em andamento, evitando race conditions

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

# Referências

- [FUK2-11746 — TOC Async Builder](https://estrategia.atlassian.net/browse/FUK2-11746)
```

## Flags opcionais

- `--save obsidian` — salva o output em `/workspace/obsidian/<TICKET>-release-notes.md`
- `--repo <nome>` — força um repo específico (default: detecta pelo cwd)
