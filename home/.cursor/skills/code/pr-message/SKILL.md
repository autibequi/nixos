---
name: code/pr-message
description: Gera descrição de PR em markdown copiável (O que foi implementado, Como testar, Dependências, JIRA). Estilo fixo alinhado ao template Estrategia. Escopo por repo ou por commit em branch suja.
---

# code/pr-message — Mensagem de PR

Gera **um único markdown** para colar na descrição do PR. Entregar dentro de um fence ` ```markdown ` … ` ``` `.

Base: diff `origin/main...HEAD` no **repo atual** (cwd), ou escopo restrito (`--commit`, paths).

## Formato de saída (obrigatório — template canônico)

Seguir **exatamente** esta ordem e este “look”. Título em H1; **sem** seção “Contexto” salvo pedido explícito.

```markdown
# <TICKET> — <Título curto> (<BO | front-student | Monolito | …>)

## O que foi implementado

- **<Rótulo>**: <uma linha; pode citar componentes com `backticks`>
- ...

## Como testar

| Cenário | Ação | Esperado |
|--------|------|----------|
| Happy — <nome curto> | <ação concreta> | <resultado esperado> |
| Sad — <nome curto> | <ação concreta> | <resultado esperado> |

## Dependências

| Tipo | Item |
|------|------|
| Backend / API | <texto> |
| Front | <texto> |
| … | … |

## JIRA

https://estrategia.atlassian.net/browse/<TICKET>
```

### Regras de estilo

- **Bullets**: uma linha cada; não quebrar frase no meio só por largura do editor.
- **Como testar**: coluna **Cenário** no formato `Happy — …` ou `Sad — …` (**sem** emoji ✅/❌ no template padrão).
- **Dependências**: preferir **duas colunas** (`Tipo` | `Item`). Terceira coluna (“Necessário antes do deploy?”) só em PRs com migration/fila/toggler pesado (monolito / infra).
- **JIRA**: seção final **`## JIRA`** com **URL pura** numa linha (sem link markdown `[texto](url)`), no domínio `estrategia.atlassian.net`.
- **Escopo** (branch com vários tickets): bloco opcional no fim, antes de JIRA:

```markdown
> **Escopo:** apenas `<TICKET>` em `<repo>` (commit/paths …). Outros commits fora.
```

## Processo

### 1) Repo e ticket

```bash
cd /workspace/mnt/estrategia/<monolito|bo-container|front-student>
git branch --show-current
git fetch origin main 2>/dev/null; git log --oneline origin/main..HEAD
```

Ticket: padrão `FUK2-12345` no nome da branch. Branch suja → restringir a um ticket por rodada.

### 2) Jira

Se MCP / browser existir, usar título do card no H1. Se não, título vindo dos commits. **Nunca falhar** sem Jira.

### 3) Diff

```bash
git diff origin/main...HEAD --stat
git diff origin/main...HEAD --name-only
```

Isolar: `git log --grep='<TICKET>'` + `git show <hash>` ou `git diff origin/main...HEAD -- <paths>`.

### 4) O que foi implementado

Rótulos em negrito (**Modal**, **Service**, **409**, **Migration**, …). Ordem backend → front quando os dois existirem.

### 5) Como testar + Dependências + JIRA

Preencher tabelas de verdade; não substituir por listas.

### 6) Entrega

Responder com o **bloco `markdown` completo** copiável (ver template acima).

## Exemplo BO (referência)

```markdown
# FUK2-11746 — TOC Async Builder (BO)

## O que foi implementado

- **Modal** `ModalTocRebuilding`: lista jobs em andamento (`JobResultBox` + polling), botão **Tentar novamente** só libera quando todos terminam.
- **409 Conflict**: `ViewCourse`, `ViewToc`, `PreviewItem` e `ItemEditor` tratam resposta do BO quando o rebuild bloqueia edição; a ação pendente pode ser refeita depois que o modal sinaliza fim dos jobs.
- **Preventivo**: `ViewCourse` no `mounted` consulta jobs ativos e abre o modal se já houver rebuild em curso.
- **Integração com fila**: `PreviewCourse` e modais de adicionar capítulo/item passam `course_id` onde o backend precisa para enfileirar o rebuild (alinhado ao fluxo do monolito).

## Como testar

| Cenário | Ação | Esperado |
|--------|------|----------|
| Happy — edição liberada | Alterar curso/TOC/item sem rebuild ativo | Fluxo normal, sem modal de bloqueio |
| Happy — rebuild em curso | Disparar rebuild e tentar salvar enquanto jobs rodam | `409` → modal com jobs; após conclusão, **Tentar novamente** habilitado e operação pode seguir |
| Happy — já entrou com rebuild | Abrir `ViewCourse` com jobs ativos | Modal preventivo ao carregar a tela |
| Sad — cancelar | Abrir modal e **Cancelar** | Modal fecha; usuário decide quando tentar de novo |

## Dependências

| Tipo | Item |
|------|------|
| Backend / API | Endpoints LDI retornando `409` com payload de jobs (rebuild em andamento) |
| Front | Nenhuma env nova obrigatória além do que o PR já usa com jobs |

## JIRA

https://estrategia.atlassian.net/browse/FUK2-11746
```

## Exemplo front-student (referência)

```markdown
# FUK2-11746 — TOC Async Builder (front-student)

## O que foi implementado

- **ContentAccessWatcher**: passa a usar `course.chapters` com itens em `chapters[].items[]` em vez de `toc_data.toc` recursivo; `findContentById` / `findContentByPath` alinhados ao shape plano da API.
- **Documento atual**: resolve por `content_id` ou `item_id`; nome/posição compatíveis com o novo modelo (`name` / `title`, `path`).
- **Tracking**: `chapter_id` com fallback `chapter_id || id` no payload.
- **LdiApiService**: `getCourseGoals` renomeado para `getGoalsByCourseId`; novo `getGoalsByTrailId` (`/trail-goals`).

## Como testar

| Cenário | Ação | Esperado |
|--------|------|----------|
| Happy — navegação LDI POC | Navegar capítulos/itens com curso no formato `chapters` | Acesso e metadados coerentes com o TOC flat |
| Happy — goals curso | Fluxo que carrega metas por curso | Lista retornada via `getGoalsByCourseId` |
| Happy — goals trilha | Fluxo que carrega metas por trilha | Lista retornada via `getGoalsByTrailId` |
| Sad — payload antigo | Curso só com TOC legado sem `chapters` | Comportamento inválido para o contrato novo — validar com API real |

## Dependências

| Tipo | Item |
|------|------|
| API / BFF | Curso com `chapters` + itens no formato esperado; endpoints de goals e trail-goals |
| Front | Nenhuma env nova obrigatória só por este escopo |

## JIRA

https://estrategia.atlassian.net/browse/FUK2-11746
```

## Flags opcionais

- `--save obsidian` — salvar em `/workspace/obsidian/<TICKET>-release-notes.md`
- `--repo <nome>` — fixar repo antes do git
- `--commit <hash>` — descrever só aquele commit
