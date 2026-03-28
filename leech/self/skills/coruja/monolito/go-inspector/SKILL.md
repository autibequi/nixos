---
name: monolito/go-inspector
description: Inspeção multi-perspectiva de feature chain no monolito. Coleta contexto de PR/JIRA/Notion, spawna 5 inspetores paralelos (claude, documentation, qa, namer, coverage) + inspector-contrato + simplifier sequencial em worktree. Gera relatórios acionáveis em vault/inspections/<tarefa>/ e atualiza o BOARD principal em vault/inspections/BOARD.md.
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
echo "<branch>" | grep -oE '[A-Z]+-[0-9]+'
```

Se encontrou um ticket ID, buscar via MCP Atlassian:
- Usar `mcp__claude_ai_Atlassian__getJiraIssue` com o ticket ID
- Coletar: título, descrição, critérios de aceite, comentários relevantes

### 2c — Comentários do PR (se existir PR aberto):

```bash
GH_TOKEN=$GH_TOKEN gh pr list --repo estrategiahq/monolito --head <branch> --json number,title,state
GH_TOKEN=$GH_TOKEN gh pr view <number> --repo estrategiahq/monolito --json reviews,comments,reviewRequests
```

Coletar:
- **Review comments** (inline): threads em arquivos específicos — indicam pontos já contestados pelo time
- **PR comments** (gerais): discussões de design, decisões tomadas, dúvidas levantadas
- **Review status**: quem aprovou, quem pediu changes, o que pediu
- Comentários de revisores humanos têm prioridade — ignorar bots (Codecov, CodeRabbit automático sem customização, etc.)

> Esses dados são críticos: um reviewer pode já ter apontado o mesmo bug que o inspector vai encontrar, ou pode ter aprovado algo que o inspector marcaria como problema — contexto valioso para calibrar o tom dos findings.

### 2d — Notion:
Buscar página relacionada ao PR/ticket:
- Usar `mcp__claude_ai_Notion__notion-search` com título do PR ou nome da feature
- Se encontrar: coletar contexto de produto, decisões de design, user stories

### 2e — Gerar 00-contexto.md:
Criar o artefato de contexto seguindo o formato de `templates/output.md`. Incluir:
- Dados do PR (título, autor, descrição completa, commits)
- **Comentários e reviews do PR** (se existir PR aberto)
- Dados do JIRA (se encontrado)
- Dados do Notion (se encontrado)
- Resumo sintético: o que foi pedido vs o que foi entregue

### Definições dos inspetores:
Ler os arquivos de definição:
- `/workspace/obsidian/bedrooms/inspectors/claude.md`
- `/workspace/obsidian/bedrooms/inspectors/documentation.md`
- `/workspace/obsidian/bedrooms/inspectors/qa.md`
- `/workspace/obsidian/bedrooms/inspectors/namer.md`
- `/workspace/obsidian/bedrooms/inspectors/simplifier.md`

## Passo 2f — Inspector de Contrato Frontend ← → Backend (pré-inspeção paralela)

**Rodar ANTES dos inspetores principais, em paralelo para cada repo frontend afetado.**

Se o diff tocar em handlers BO, BFF ou structs de response, spawnar um `inspector-contrato` por repositório:

```
Agent subagent_type=Explore run_in_background=true prompt="
Você é o inspector-contrato para [bo-container|front-student].
Definição completa: <conteúdo de /workspace/obsidian/bedrooms/inspectors/contrato.md>

Contexto (handlers modificados, structs de response, novos endpoints):
<extraído do diff e do 00-contexto.md>

Repos:
- Monolito: /workspace/mnt/estrategia/monolito
- bo-container: /workspace/mnt/estrategia/bo-container
- front-student: /workspace/mnt/estrategia/front-student

Missão:
1. Ler os services do frontend que chamam os endpoints modificados
2. Cruzar campo a campo: URL, método HTTP, request body, response shape
3. Verificar se o frontend trata os novos status codes (ex: 409 de CheckTOCRebuild)
4. Reportar: ✅ ALINHADO / 🔴 QUEBRADO / ⚠️ RISCO / ❓ NÃO VERIFICÁVEL

Output: tabela por repo (N✅ / N⚠️ / N🔴) + findings detalhados por endpoint.
"
```

**Quando pular este passo:** se o diff não tocar em nenhum handler HTTP (só workers, migrations, services internos).

**Output:** artefato `07-contrato.md` na pasta da inspeção.

---

## Passo 3 — Spawnar 5 inspetores em paralelo

> **IMPORTANTE:** O agente Monolito não tem o skill `go-inspector` disponível como ferramenta registrada. Ler os arquivos de definição dos inspetores diretamente (via Read tool) e executar cada perspectiva manualmente, consolidando no mesmo agente. Ao spawnar inspetores, usar `subagent_type=general-purpose` ou `subagent_type=Explore`.

Usar o Agent tool com `run_in_background: true` para cada inspector. Todos recebem:
- O contexto coletado (PR body, JIRA, Notion)
- O diff coletado
- A lista de arquivos alterados
- A definição do inspetor (conteúdo do .md do Obsidian)
- O formato de output esperado

```
Agent subagent_type=Explore run_in_background=true prompt="
Você é o **inspector-claude**. Sua definição completa:
<definição do obsidian/bedrooms/inspectors/claude.md>

Contexto coletado (PR/JIRA/Notion):
<conteúdo do 00-contexto.md>

Analise o seguinte diff e arquivos:
<diff>
<lista de arquivos>

Foco: qualidade geral Go — correctness, concurrency, error handling, performance, observabilidade.
Produza findings no formato especificado na sua definição.
Leia os arquivos completos quando necessário.
"
```

Repetir para: `documentation`, `qa`, `namer` — cada um com sua definição, contexto e foco.

**IMPORTANTE:** Os 5 agents devem ser lançados em uma única mensagem (paralelo real).

## Passo 4 — Coletar e consolidar resultados

Aguardar os 5 inspetores + inspector-contrato completarem. Para cada resultado:
1. Extrair findings estruturados
2. Classificar por severidade (BLOCKER > MÉDIA > BAIXA > INFO)
3. Deduplicar usando as regras do `templates/checklist.md`:
   - Mesmo trecho de código reportado por 2+ inspetores → manter do primário
   - Severidades diferentes → usar a maior
4. Agrupar por arquivo para visão consolidada

## Passo 5 — Spawnar simplifier em worktree

Após consolidar findings dos 5 primeiros:

```
Agent subagent_type=Monolito isolation=worktree prompt="
Você é o **inspector-simplifier**. Sua definição completa:
<definição do obsidian/bedrooms/inspectors/simplifier.md>

Contexto: os inspetores anteriores encontraram estes findings:
<findings consolidados>

Arquivos alterados na branch:
<lista de arquivos>

Missão:
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

## Passo 6 — Gerar artefatos

Criar pasta seguindo `templates/output.md`:

```
vault/inspections/<tarefa>/
├── README.md              ← índice com ASCII charts (gerar ESTE PRIMEIRO)
├── 00-contexto.md
├── 01-claude.md
├── 02-documentation.md
├── 03-qa.md
├── 04-namer.md
├── 05-simplifier.md
├── 06-consolidado.md
└── 07-contrato.md         ← só se diff tocou em handlers HTTP
```

Onde `<tarefa>` = slug da branch/PR (ex: `cached-ldi-toc`, `add-delta-lake`).

**README.md é o primeiro arquivo a ser criado** — inclui tabela-resumo + gráficos ASCII obrigatórios:
- Findings por inspector (barras horizontais)
- Distribuição de severidade total (com percentuais)
- Blockers por inspector
- Contrato frontend ← → backend (se contrato inspecionado)
- Risco de deploy (3 cenários)

Ver template completo em `templates/output.md`.

## Passo 7 — Atualizar BOARD principal e INDEX

### BOARD principal (`vault/inspections/BOARD.md`)

O BOARD é a página central de todas as inspeções. Sempre manter atualizado.

**Regra de tamanho:**
- Poucas inspeções (≤5): conteúdo inline com âncoras na mesma página
- Muitas inspeções (>5): só índice com links para cada `README.md`

Estrutura do BOARD:
```markdown
# Board de Inspeções

| Inspeção | Branch | Data | Blockers | Findings |
|----------|--------|------|:--------:|:--------:|
| [<tarefa>](#<tarefa>) | `<branch>` | YYYY-MM-DD | N | N |

---

## <tarefa>

<descrição curta>

| Inspector | Findings | Blockers | Média | Baixa | Info |
|-----------|:--------:|:--------:|:-----:|:-----:|:----:|
| [Claude — Qualidade Geral](#claude--qualidade-geral-<tarefa>) | N | N | N | N | N |
...

(conteúdo de cada inspector com âncoras, ou link para README.md se muitas inspeções)
```

Ao adicionar nova inspeção:
1. Adicionar linha na tabela do topo
2. Adicionar seção com conteúdo da inspeção (inline ou link)

### INDEX (`vault/inspections/INDEX.md`)

Histórico cronológico de todas as inspeções:

```markdown
# Histórico de Inspeções — Monolito

| Data | Tarefa | Branch | JIRA | Findings (🔴/🟠/🟡) | Status |
|------|--------|--------|------|----------------------|--------|
| YYYY-MM-DD | [<tarefa>](<tarefa>/README.md) | `<branch>` | <ticket> | N/N/N | ⏳/✅/🔴 |
```

Status: `✅ merged`, `🔴 revisão`, `⏳ aguardando review`
Sempre inserir no topo (mais recente primeiro).

## Passo 8 — Auto-Evolução (post-hook obrigatório)

**Este passo SEMPRE roda, independente do tamanho da inspeção. Não é opcional.**

Para cada um dos inspetores que rodou:

1. Leia o resultado que o inspector produziu
2. Leia o arquivo atual do inspector em `/workspace/obsidian/bedrooms/inspectors/<nome>.md`
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
- **Paralelo real** — os 5 inspetores + contrato rodam em background simultaneamente
- **Simplifier é sequencial** — só roda após os 5 primeiros completarem, recebe findings como input
- **Worktree isolado** — simplifier opera em cópia isolada, não afeta working directory
- **Tom construtivo** — findings são sugestões, não ordens
- **Responder em PT-BR** — todos os artefatos em português
- **Sempre gerar README + consolidado** — mesmo que a inspeção seja pequena
- **ASCII charts obrigatórios** — README sem charts não está completo
- **Rastreabilidade** — `vault/inspections/<tarefa>/` garante histórico navegável
- **BOARD sempre atualizado** — toda inspeção aparece em `vault/inspections/BOARD.md`
- **Evoluir sempre** — cada inspeção deve deixar os inspetores mais inteligentes
