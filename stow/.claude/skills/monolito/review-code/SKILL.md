---
name: monolito/review-code
description: Use when the developer wants to do a code review of a PR or branch in the monolito or estrategia projects. Reads the diff, analyzes architecture, identifies issues (race conditions, error handling, performance, testing gaps), generates structured artefacts in obsidian/artefacts/, and provides discussion topics. Evolves knowledge over time via templates/knowledge.md.
---

# review-code: Code Review de PR/Branch

## Templates

Antes de executar, ler TODOS os templates neste diretório:

| Arquivo | Conteúdo |
|---|---|
| `templates/knowledge.md` | **Conhecimento acumulado** — patterns do monolito, armadilhas conhecidas, convenções aprendidas em reviews anteriores. **EVOLUI COM O TEMPO.** |
| `templates/checklist.md` | Checklist de review por camada (entities → interfaces → services → repositories → migrations) |
| `templates/output.md` | Formato dos artefatos de output (visão geral, code review, tópicos de discussão) |

## Entrada

- `$ARGUMENTS`: número do PR, URL do PR, nome de branch, ou "auto" (detecta branch atual)

## Passo 1 — Identificar o alvo

### Se recebeu número de PR:
```bash
GH_TOKEN=$GH_TOKEN gh pr view <number> --repo estrategiahq/monolito --json title,body,state,headRefName,baseRefName,files,additions,deletions
```

### Se recebeu nome de branch:
```bash
cd /home/claude/projects/estrategia/monolito
git log origin/main...<branch> --oneline
```

### Se recebeu "auto" ou nenhum argumento:
Detectar branches ativas nos repos de `/home/claude/projects/estrategia/`:
```bash
for repo in /home/claude/projects/estrategia/*/; do
  branch=$(cd "$repo" && git branch --show-current 2>/dev/null)
  if [ "$branch" != "main" ] && [ -n "$branch" ]; then
    echo "$(basename $repo): $branch"
  fi
done
```
Apresentar opções ao dev.

## Passo 2 — Coletar o diff

```bash
cd /home/claude/projects/estrategia/monolito
git diff origin/main...<branch> --stat
git diff origin/main...<branch>
git log origin/main...<branch> --oneline
```

Se o diff for muito grande (>5000 linhas), priorizar:
1. Arquivos de service/domain logic
2. Entities e interfaces (contratos)
3. Migrations (schema changes)
4. Repositories (data access)
5. Testes
6. Config/infra (menor prioridade)

## Passo 3 — Criar pasta de artefatos

```
obsidian/artefacts/<nome-do-review>/
├── README.md          ← índice com frontmatter
├── 01-visao-geral.md  ← arquitetura, motivação, tabelas/entities novas
├── 02-code-review.md  ← análise técnica, pontos de atenção por severidade
└── 03-topicos-discussao.md ← perguntas pro autor, temas de debate
```

Nome do review: slug baseado na branch ou tema (ex: `review-delta-lake`, `review-auth-middleware`).

## Passo 4 — Análise (ordem obrigatória)

Seguir a ordem do `templates/checklist.md`:

### 4a — Entities e Structs
- Novos tipos? GORM tags corretas? JSON tags?
- Implementam `Value()/Scan()` pra JSONB?
- `TableName()` presente?

### 4b — Interfaces
- Contratos novos? Assinaturas mudaram?
- Return types mudaram (ex: `[]T` → `[]*T`)?

### 4c — Services (core da review)
- Lógica de negócio correta?
- Error handling: erros propagados? silenciados?
- Concorrência: `errgroup`, mutexes, `async.Background`
- Race conditions: goroutines escrevendo no mesmo map/struct?
- Performance: N+1 queries? batch vs loop?
- Nil guards em ponteiros

### 4d — Repositories
- SQL correto? Injection possível?
- Upserts: `OnConflict` correto? Colunas certas?
- Batch size razoável?
- `Delete` antes de `Insert` (idempotência)?

### 4e — Migrations
- `goose Up` e `goose Down` presentes?
- Constraints adequadas (UNIQUE, INDEX)?
- Tipos corretos (TIMESTAMPTZ, JSONB, etc.)?
- Ordem de migrations faz sentido?

### 4f — Testes
- Cobertura: lógica de negócio testada?
- Mocks corretos?
- Edge cases cobertos?
- Gaps identificados?

### 4g — Checklist do knowledge.md
Aplicar todas as armadilhas e patterns conhecidos do `templates/knowledge.md`.

## Passo 5 — Classificar findings

| Severidade | Critério | Ação |
|---|---|---|
| **Blocker** | Pode causar bug, panic, data loss, ou race condition em prod | Reportar como blocker |
| **Média** | Pode causar problema em edge case ou dificultar manutenção | Reportar como ponto de atenção |
| **Baixa** | Melhoria de qualidade, performance marginal, estilo | Reportar como sugestão |
| **Info** | Observação, nota pra contexto | Reportar como informativo |

## Passo 6 — Gerar artefatos

Usar o formato definido em `templates/output.md`. Cada artefato tem frontmatter YAML.

## Passo 7 — Atualizar kanban

Adicionar card em "Aprovado" no `obsidian/kanban.md`:
```
- [x] **<nome-review>** #done YYYY-MM-DD `opus` — [artefatos](artefacts/<nome>/README.md) <descrição curta>
```

## Passo 8 — Evoluir conhecimento

**CRÍTICO: Esta é a parte que faz a skill melhorar ao longo do tempo.**

Após completar a review, perguntar-se:
1. Descobri algum pattern novo do monolito que não está no knowledge.md?
2. Encontrei uma armadilha que deveria checar em reviews futuras?
3. Alguma convenção do projeto que não estava documentada?

Se sim, **atualizar `templates/knowledge.md`** adicionando a nova entrada na seção apropriada. Formato:
```markdown
### [Título curto]
**Aprendido em:** review de <branch> (YYYY-MM-DD)
**Contexto:** <onde/como aparece>
**O que checar:** <ação concreta pra reviews futuras>
```

## Regras

- **Tom construtivo** — é código de colega. Apontar problemas com sugestão de fix.
- **Ler antes de opinar** — nunca criticar baseado só no diff. Ler o arquivo completo quando necessário.
- **Priorizar** — blocker > média > baixa. Não soterrar findings importantes com nitpicks.
- **Contexto > regra** — uma "má prática" pode ser a melhor opção dado o contexto. Perguntar antes de julgar.
- **Sempre gerar os 3 artefatos** — mesmo que o PR seja pequeno. Consistência facilita revisão.
- **Responder em PT-BR** — artefatos e comunicação em português.
