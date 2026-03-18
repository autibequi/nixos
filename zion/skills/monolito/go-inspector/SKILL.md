---
name: monolito/go-inspector
description: Inspeção multi-perspectiva de feature chain no monolito. Coleta contexto de PR/JIRA/Notion, spawna 6 inspetores paralelos (architect, claude, documentation, qa, namer, coverage) + simplifier sequencial em worktree. Gera relatórios acionáveis em obsidian/inspection/<tarefa>/<data>/.
---

# go-inspector: Inspeção Multi-Perspectiva

## Templates

Antes de executar, ler TODOS os templates neste diretório:

| Arquivo | Conteúdo |
|---|---|
| `templates/output.md` | Formato dos artefatos de output (estrutura de pastas, frontmatter, formato por inspetor) |
| `templates/checklist.md` | Mapa de cobertura: qual inspetor é responsável por quê, regras de deduplicação |

## Entrada

- `$ARGUMENTS`: número do PR, nome de branch, ou "auto" (detecta branch atual)

## Passo 1 — Identificar o alvo

### Se recebeu número de PR:
```bash
GH_TOKEN=$GH_TOKEN gh pr view <number> --repo estrategiahq/monolito --json title,body,state,headRefName,baseRefName,files,additions,deletions,author
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
Apresentar opções ao dev. Focar no monolito.

## Passo 2 — Coletar contexto (PR + JIRA + Notion)

**Objetivo:** reunir o máximo de contexto antes de inspecionar. O que foi pedido? Por quê? Quais critérios de aceite?

### 2a — Diff do código:
```bash
cd /home/claude/projects/estrategia/monolito
git diff origin/main...<branch> --stat
git diff origin/main...<branch>
git log origin/main...<branch> --oneline --format="%h %s %an"
```

Se o diff for muito grande (>5000 linhas), priorizar:
1. Arquivos de service/domain logic
2. Entities e interfaces (contratos)
3. Migrations (schema changes)
4. Repositories (data access)
5. Testes
6. Config/infra (menor prioridade)

### 2b — JIRA (extrair ticket da branch):
Branch geralmente contém o ticket: `feature/MON-123-descricao`, `fix/MON-456-bug`.

```bash
# Extrair ticket ID da branch
echo "<branch>" | grep -oE '[A-Z]+-[0-9]+'
```

Se encontrou um ticket ID, buscar via MCP Atlassian:
- Usar `mcp__claude_ai_Atlassian__getJiraIssue` com o ticket ID
- Coletar: título, descrição, critérios de aceite, comentários relevantes

### 2c — Notion:
Buscar página relacionada ao PR/ticket:
- Usar `mcp__claude_ai_Notion__notion-search` com título do PR ou nome da feature
- Se encontrar: coletar contexto de produto, decisões de design, user stories

### 2d — Gerar 00-contexto.md:
Criar o artefato de contexto seguindo o formato de `templates/output.md`. Incluir:
- Dados do PR (título, autor, descrição completa, commits)
- Dados do JIRA (se encontrado)
- Dados do Notion (se encontrado)
- Resumo sintético: o que foi pedido vs o que foi entregue

### Definições dos inspetores:
Ler os 7 arquivos de definição:
- `/workspace/obsidian/agents/inspectors/architect.md`
- `/workspace/obsidian/agents/inspectors/claude.md`
- `/workspace/obsidian/agents/inspectors/documentation.md`
- `/workspace/obsidian/agents/inspectors/qa.md`
- `/workspace/obsidian/agents/inspectors/namer.md`
- `/workspace/obsidian/agents/inspectors/coverage.md`
- `/workspace/obsidian/agents/inspectors/simplifier.md`

## Passo 3 — Spawnar 6 inspetores em paralelo

Usar o Agent tool com `run_in_background: true` para cada inspector. Todos recebem:
- O contexto coletado (PR body, JIRA, Notion)
- O diff coletado
- A lista de arquivos alterados
- A definição do inspetor (conteúdo do .md do Obsidian)
- O formato de output esperado

```
Agent subagent_type=Monolito run_in_background=true prompt="
Você é o **inspector-architect**. Sua definição completa:
<definição do obsidian/agents/inspectors/architect.md>

Contexto coletado (PR/JIRA/Notion):
<conteúdo do 00-contexto.md>

Analise o seguinte diff e arquivos:
<diff>
<lista de arquivos>

Produza o output no formato especificado na sua definição:
- Visão geral arquitetural (tabelas, entities, fluxo)
- Análise de design decisions (use o contexto JIRA/Notion para entender a intenção)
- Findings de schema/layer (migrations, entities, interfaces)
- Tópicos de discussão para o autor
Leia os arquivos completos quando necessário para entender o contexto de design.
"
```

```
Agent subagent_type=Monolito run_in_background=true prompt="
Você é o **inspector-claude**. Sua definição completa:
<definição do obsidian/agents/inspectors/claude.md>

Contexto coletado (PR/JIRA/Notion):
<conteúdo do 00-contexto.md>

Analise o seguinte diff e arquivos:
<diff>
<lista de arquivos>

Produza findings no formato especificado na sua definição.
Foco: qualidade geral Go — correctness, concurrency, error handling, performance, observabilidade.
Use o contexto para entender a intenção e identificar divergências de implementação.
Leia os arquivos completos quando necessário.
"
```

```
Agent subagent_type=Monolito run_in_background=true prompt="
Você é o **inspector-coverage**. Sua definição completa:
<definição do obsidian/agents/inspectors/coverage.md>

Contexto coletado (PR/JIRA/Notion):
<conteúdo do 00-contexto.md>

Branch/PR a analisar: <branch>
Arquivos alterados: <lista de arquivos>
Diff: <diff>

Sua missão:
1. Mapear os principais fluxos afetados (use os critérios de aceite do JIRA/Notion se disponíveis)
2. Localizar os arquivos de teste existentes nos packages afetados
3. Executar os testes: go test ./apps/<app>/internal/... -v -count=1
4. Identificar gaps de cobertura por severidade
5. Gerar relatório acionável com testes sugeridos para os gaps críticos
"
```

Repetir para: `documentation`, `qa`, `namer` — cada um com sua definição, contexto e foco.

**IMPORTANTE:** Os 6 agents devem ser lançados em uma única mensagem (paralelo real).

## Passo 4 — Coletar e consolidar resultados

Aguardar os 6 inspetores completarem. Para cada resultado:
1. Extrair findings estruturados
2. Classificar por severidade (BLOCKER > MÉDIA > BAIXA > INFO)
3. Deduplicar usando as regras do `templates/checklist.md`:
   - Mesmo trecho de código reportado por 2+ inspetores → manter do primário
   - Severidades diferentes → usar a maior
4. Agrupar por arquivo para visão consolidada

## Passo 5 — Spawnar simplifier em worktree

Após consolidar findings dos 6 primeiros:

```
Agent subagent_type=Monolito isolation=worktree prompt="
Você é o **inspector-simplifier**. Sua definição completa:
<definição do obsidian/agents/inspectors/simplifier.md>

Contexto: os 6 inspetores anteriores encontraram estes findings:
<findings consolidados>

Arquivos alterados na branch:
<lista de arquivos>

Sua missão:
1. Analise cada arquivo buscando oportunidades de simplificação
2. Para cada simplificação viável:
   a. Faça a mudança no código
   b. Rode `go vet ./...` no package afetado
   c. Commite com mensagem: `simplify: <descrição curta>`
3. NÃO mude comportamento — apenas refactors puros
4. NÃO toque em interfaces ou exported signatures
5. Reporte o que fez e o que não fez (com razões)
"
```

Apresentar o diff do simplifier ao dev para aprovação.

## Passo 6 — Gerar relatório

Criar pasta seguindo `templates/output.md`:

```
obsidian/inspection/<tarefa>/<data>/
├── BOARD.md              ← gerar ESTE PRIMEIRO — resumo visual executivo
├── README.md
├── 00-contexto.md
├── 01-architect.md
├── 02-claude.md
├── 03-documentation.md
├── 04-qa.md
├── 05-namer.md
├── 06-coverage.md
├── 07-simplifier.md
└── 08-consolidado.md
```

Onde `<tarefa>` = slug da branch (ex: `add-delta-lake`) e `<data>` = data atual (YYYY-MM-DD).

**BOARD.md é o primeiro arquivo a ser criado** — é o resumo executivo visual que o dev abre primeiro. Seguir rigorosamente o template em `templates/output.md`. Inclui:
- Veredito de merge (pode ou não pode, com justificativa)
- Placar dos inspetores com barra de volume
- Blockers em tabela
- Gaps de cobertura críticos
- Tópicos para o autor
- Métricas consolidadas em bloco de texto formatado

## Passo 7 — Atualizar kanban

Adicionar card no `obsidian/kanban.md`:
```
- [x] **<tarefa>** #done YYYY-MM-DD `opus` — [inspeção](inspection/<tarefa>/<data>/README.md) N findings, M blockers, K gaps de cobertura, J simplificações
```

## Passo 8 — Auto-Evolução (post-hook obrigatório)

**Este passo SEMPRE roda, independente do tamanho da inspeção. Não é opcional.**

Para cada um dos 7 inspetores que rodou:

1. Leia o resultado que o inspector produziu
2. Leia o arquivo atual do inspector em `/workspace/obsidian/agents/inspectors/<nome>.md`
3. Avalie: o inspector encontrou algo que ainda não está documentado na sua definição?
   - Novo pattern do monolito
   - Armadilha nova descoberta no diff
   - Heurística que funcionou bem ou mal
4. **Sempre** adicionar o nome da inspeção ao frontmatter `inspections:` do inspector
5. Se há novidade: adicionar em `## Aprendizados` e atualizar `updated:` no frontmatter

Formato de entrada em Aprendizados:
```markdown
### [Título curto]
**Aprendido em:** <tarefa> (YYYY-MM-DD)
**Contexto:** <onde/como aparece>
**O que checar:** <ação concreta para inspeções futuras>
```

**Cada inspector deve sair desta inspeção mais inteligente do que entrou.**

## Regras

- **Contexto primeiro** — nunca inspecionar sem ter lido PR body, JIRA e Notion (se disponíveis)
- **Paralelo real** — os 6 primeiros inspetores rodam em background simultaneamente
- **Simplifier é sequencial** — só roda após os 6 primeiros completarem, recebe findings como input
- **Worktree isolado** — simplifier opera em cópia isolada, não afeta working directory
- **Tom construtivo** — findings são sugestões, não ordens
- **Responder em PT-BR** — todos os artefatos em português
- **Sempre gerar os 9 artefatos** — mesmo que a inspeção seja pequena
- **Rastreabilidade** — pasta `obsidian/inspection/<tarefa>/<data>/` garante histórico por data
- **Evoluir sempre** — cada inspeção deve deixar os inspetores mais inteligentes
