# /code — DevFlow Skill Set

Conjunto de skills para executar tarefas usando DevFlow pipeline.

## Sub-skills Disponíveis

| Skill | Função | Responsabilidade |
|-------|--------|------------------|
| `/code:manager` | **ORQUESTRADOR** | Cria board central, despacha agentes, sincroniza status |
| `/code:refine` | REFINING | Mapeia requisito, scope, impacto |
| `/code:guru` | ATTENTION | Brainstorm design com 3+ opções |
| `/code:plan` | PLANNING | Quebra em subtasks granulares |
| `/code:develop` | DEVELOPING | Implementa + rastreia bugs |
| `/code:qa` | QA | Testes funcionais, edge cases |

## Fluxo Completo

```
0. /code:manager create FUK2-XXXXX
   ↓ Cria board central, dashboard, sincroniza status
   ↓ Despacha agentes conforme necessário

1. /code:refine FUK2-XXXXX
   ↓ Preenche REFINING + identifica questões
   ↓ Manager atualiza dashboard (REFINING ✅)

2. /code:guru FUK2-XXXXX
   ↓ Brainstorm, gera 3+ opções por questão
   ↓ Manager atualiza dashboard (ATTENTION ✅)

3. /code:plan FUK2-XXXXX
   ↓ Quebra em A, B, C, D... com checkboxes
   ↓ Manager atualiza dashboard (PLANNING ✅)

4. /code:develop FUK2-XXXXX-A (ou -B, -C em paralelo)
   ↓ Implementa checkbox por checkbox
   ↓ Manager sincroniza status real-time (DEVELOPING 65%, bugs encontrados, etc)

5. /code:qa FUK2-XXXXX
   ↓ Testa tudo, marca [x] quando pronto
   ↓ Manager rastreia bloqueadores, agrega testes

6. Status: WAITING (você aprova) → DONE
   ↓ Manager summarize (consolida lições, extrai aprendizados)
```

## Como Começar

**Passo 1: Crie arquivo devflow**
```bash
mkdir -p /workspace/obsidian/projects/estrategia/
cp /workspace/obsidian/devflow/template.md \
   /workspace/obsidian/projects/estrategia/FUK2-987213-seu-titulo.md
```

**Passo 2: Refine**
```
/code:refine FUK2-987213
```

**Passo 3: Guru (se complexo)**
```
/code:guru FUK2-987213
```

**Passo 4: Plan**
```
/code:plan FUK2-987213
```

**Passo 5: Develop (paralelo)**
```
/code:develop FUK2-987213-A
/code:develop FUK2-987213-B
/code:develop FUK2-987213-C
```

**Passo 6: QA (você)**
```
/code:qa FUK2-987213
```

**Passo 7: WAITING → DONE (você aprova)**

## Sub-skills em Detalhe

### `/code:manager` — Project Orchestrator ⭐ START HERE
- Cria board central em `/workspace/obsidian/manager/FUK2-XXXXX.md`
- Dashboard com status de cada fase (REFINING, ATTENTION, PLANNING, DEVELOPING, QA, DONE)
- Rastreia agentes atribuídos, bloqueadores globais, timeline macro
- Despacha `/code:refine`, `/code:guru`, `/code:plan`, `/code:develop`, `/code:qa` conforme necessário
- Sincroniza status real-time com board devflow
- Pode summarize boards antigos (consolida lições, extrai aprendizados)

**Usar primeiro**: `Manager cria estrutura, depois dispatcher chama as skills`

### `/code:refine` — Refine Task
- Mapeia requisito exato
- Define scope (inclui/exclui)
- Identifica impacto (quais repos/services)
- Lista unknowns/riscos
- Recomenda: PLANNING ou ATTENTION?

### `/code:guru` — Brainstorm Design
- Usa `/brainstorm` skill
- Gera 3+ opções por questão
- Prós/contras cada opção
- Recomendação final
- Move pra PLANNING

### `/code:plan` — Plan Breakdown
- Recap decisões de ATTENTION
- Quebra em subtasks (A, B, C, D)
- Checkboxes mini em cada subtask
- Define ordem/dependências
- Ready pra DEVELOPING

### `/code:develop` — Execute Development
- Implementa subtask (A, B, C, ou D)
- Checkbox por checkbox
- Se achar bug → anota + fix + retesta
- Marca `[x]` quando pronto
- Atualiza timeline

### `/code:qa` — Manual Testing
- Testa fluxos de usuário
- Edge cases (timeout, erro, concorrência)
- Se achar bug:
  - Trivial → volta DEVELOPING
  - Complexo → adiar se low priority
- Marca checkboxes, roda testes novamente

## Exemplo Real

Veja tarefa completa em `/workspace/obsidian/dev.md`:
- REFINING completo
- ATTENTION com brainstorm Guru
- PLANNING com 4 subtasks
- DEVELOPING com 40+ checkboxes + bugs encontrados/fixos
- QA com testes + problemas resolvidos
- Timeline rastreando tudo

## Dicas

- **1 Jira = 1 pasta** em `/workspace/obsidian/projects/<categoria>/`
- **1 agente principal** por devflow (Coruja pra estratégia, Wanderer pra genérico)
- **Timeline atualizada** — rastreia quando cada coisa aconteceu
- **Bugs in-place** — não mova card, apenas anote no checkbox
- **Lições no DONE** — registra aprendizado pra próxima vez

## Status do Sistema

✅ 5 sub-skills criadas (refine, guru, plan, develop, qa)
✅ DevFlow template pronto
✅ Exemplo vivo (FUK2-987213) com bugs + fixes
✅ HOW-IT-WORKS documentado
✅ Ready pra usar
