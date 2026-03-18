---
name: monolito/go-inspector
description: Inspeção multi-perspectiva de feature chain no monolito. Spawna 4 inspetores paralelos + simplifier em worktree.
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
Apresentar opções ao dev. Focar no monolito.

## Passo 2 — Coletar o diff e ler definições

### Diff:
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

### Definições dos inspetores:
Ler os 5 arquivos de definição:
- `/workspace/obsidian/agents/inspectors/claude.md`
- `/workspace/obsidian/agents/inspectors/documentation.md`
- `/workspace/obsidian/agents/inspectors/qa.md`
- `/workspace/obsidian/agents/inspectors/namer.md`
- `/workspace/obsidian/agents/inspectors/simplifier.md`

## Passo 3 — Spawnar 4 inspetores em paralelo

Usar o Agent tool com `run_in_background: true` para cada inspector. Todos recebem:
- O diff coletado
- A lista de arquivos alterados
- A definição do inspetor (conteúdo do .md do Obsidian)
- O formato de output esperado

```
Agent subagent_type=Monolito run_in_background=true prompt="
Você é o **inspector-claude**. Sua definição completa:
<definição do obsidian/agents/inspectors/claude.md>

Analise o seguinte diff e arquivos:
<diff>
<lista de arquivos>

Produza findings no formato especificado na sua definição.
Foco: qualidade geral Go — correctness, concurrency, error handling, performance.
Leia os arquivos completos quando necessário para entender contexto.
"
```

Repetir para: `documentation`, `qa`, `namer` — cada um com sua definição e foco.

**IMPORTANTE:** Os 4 agents devem ser lançados em uma única mensagem (paralelo real).

## Passo 4 — Coletar e consolidar resultados

Aguardar os 4 inspetores completarem. Para cada resultado:
1. Extrair findings estruturados
2. Classificar por severidade (BLOCKER > MÉDIA > BAIXA > INFO)
3. Deduplicar usando as regras do `templates/checklist.md`:
   - Mesmo trecho de código reportado por 2+ inspetores → manter do primário
   - Severidades diferentes → usar a maior
4. Agrupar por arquivo para visão consolidada

## Passo 5 — Spawnar simplifier em worktree

Após consolidar findings dos 4 primeiros:

```
Agent subagent_type=Monolito isolation=worktree prompt="
Você é o **inspector-simplifier**. Sua definição completa:
<definição do obsidian/agents/inspectors/simplifier.md>

Contexto: os 4 inspetores anteriores encontraram estes findings:
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

Criar pasta de artefatos seguindo `templates/output.md`:

```
obsidian/artefatos/inspect-<slug>/
├── README.md
├── 01-claude.md
├── 02-documentation.md
├── 03-qa.md
├── 04-namer.md
├── 05-simplifier.md
└── 06-consolidado.md
```

Onde `<slug>` é derivado do nome da branch (ex: `add-delta-lake` → `inspect-delta-lake`).

## Passo 7 — Atualizar kanban

Adicionar card no `obsidian/kanban.md`:
```
- [x] **inspect-<slug>** #done YYYY-MM-DD `opus` — [artefatos](artefatos/inspect-<slug>/README.md) Inspeção multi-perspectiva: N findings, M blockers, K simplificações
```

## Passo 8 — Evoluir conhecimento

**CRÍTICO: Esta é a parte que faz os inspetores melhorarem ao longo do tempo.**

Para cada inspetor, avaliar:
1. Descobriu algum pattern novo que não está na sua definição?
2. Encontrou uma armadilha que deveria checar em inspeções futuras?
3. Alguma heurística que se mostrou particularmente útil ou inútil?

Se sim, **atualizar a seção "Aprendizados"** do arquivo correspondente em `/workspace/obsidian/agents/inspectors/`. Formato:

```markdown
### [Título curto]
**Aprendido em:** inspect-<slug> (YYYY-MM-DD)
**Contexto:** <onde/como aparece>
**O que checar:** <ação concreta para inspeções futuras>
```

Também atualizar o campo `updated:` no frontmatter do inspector.

## Regras

- **Paralelo real** — os 4 primeiros inspetores rodam em background simultaneamente
- **Simplifier é sequencial** — só roda após os 4 primeiros completarem, recebe findings como input
- **Worktree isolado** — simplifier opera em cópia isolada, não afeta working directory
- **Tom construtivo** — findings são sugestões, não ordens
- **Responder em PT-BR** — todos os artefatos em português
- **Sempre gerar os 6 artefatos** — mesmo que a inspeção seja pequena
- **Evoluir sempre** — cada inspeção deve deixar os inspetores mais inteligentes
