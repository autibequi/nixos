---
name: meta/orchestrator
description: Executa o loop de orquestrador de projeto autonomo — le KANBAN, decide proximo passo, despacha sub-agentes via DASHBOARD, gerencia gates. Ativar quando card tem #orquestrador.
depends_on:
  - projects/astroboy/design/orchestrator.md
  - projects/astroboy/design/agent-routing.md
  - projects/astroboy/design/gates.md
  - projects/astroboy/design/modes.md
updated: 2026-03-29T23:30Z
---

# meta/orchestrator — Orquestrador de Projeto Autonomo

> Ativar quando Hefesto recebe um card com `#orquestrador`.
> Nao executar tasks — coordenar quem as executa.

---

## Quando Ativar

Esta skill e ativada quando:
- Card no DASHBOARD tem tag `#orquestrador`
- BRIEFING.md do projeto tem `modo: orchestrated`

Se o card tem `#agent-direct` ou BRIEFING tem `modo: agent-direct`, usar o algoritmo simplificado (ver secao no final).

---

## Loop Principal (7 passos)

A cada ciclo executar nesta ordem:

```
1. SCAN      — ler BRIEFING.md + KANBAN.md do projeto
2. ASSESS    — identificar proxima acao pelo algoritmo de decisao
3. DISPATCH  — criar card no DASHBOARD se houver task a avançar
4. GATE?     — se gate atingido: notificar inbox (1 vez) + pausar
5. CLEANUP   — verificar subtasks obsoletas no DASHBOARD
6. REPORT    — appendar em CONTEXT.md com decisoes do ciclo
7. RESCHEDULE — confirmar que o card do orquestrador foi atualizado no DASHBOARD
```

---

## Passo 1 — SCAN

```bash
cat /workspace/obsidian/projects/<nome>/BRIEFING.md
cat /workspace/obsidian/projects/<nome>/KANBAN.md
```

Mapear:
- Quais tasks estao em cada coluna (BACKLOG / REFINING / PLANNING / GATE / DOING / QA / DONE)
- Quais tasks tem `gate:`, `aprovado:`, `qa-failed:`, `blocked:`, `retry:`, `started:`
- Se o BACKLOG esta vazio e DONE tem todas as tasks

---

## Passo 2 — ASSESS (Algoritmo de Decisao)

Varrer o KANBAN na seguinte ordem de prioridade. Executar a PRIMEIRA acao que se aplica:

```
1. Existe task em GATE sem aprovado: ou rejeitado:?
   → Verificar inbox/feed.md: gate ja foi notificado?
     Se nao: appendar feed.md com notificacao
     Se sim: nao notificar novamente
   → Nao despachar nada para esta task
   → Verificar tasks paralelas independentes (itens 8-10)

2. Existe task em GATE com rejeitado:ISO?
   → Mover task de volta para BACKLOG com #rejeitado
   → Appendar CONTEXT.md: "[HH:MM] [orquestrador] gate rejeitado: <task>"
   → Publicar feed.md: "[HH:MM] [<projeto>] gate rejeitado: <task>"

3. Existe task em GATE com aprovado:ISO (e sem gate: tag)?
   → Gate fechado por Forma A (aprovacao simples)
   → Mover task para DOING (tipo:implement/deploy) ou PLANNING (aprovacao com diretiva)
   → Appendar CONTEXT.md + feed.md
   → Despachar sub-agente via DASHBOARD (item DISPATCH)

4. Existe task em GATE com aprovado:ISO E comentario > ?
   → Gate fechado por Forma B (aprovacao com diretiva)
   → Extrair diretiva do comentario
   → Mover task para PLANNING, passar diretiva como context: no card do sub-agente

5. Existe task em QA com qa-failed:<motivo>?
   → Mover task de volta para DOING
   → Despachar sub-agente com nota de falha no context:
   → Remover qa-failed: da task ao redespachar

6. Existe task em QA aprovada + #tipo:implement?
   → Abrir gate:merge no KANBAN
   → Notificar feed.md (uma vez)

7. Existe task em QA aprovada + #tipo:deploy?
   → Abrir gate:deploy no KANBAN
   → Notificar feed.md (uma vez)

8. Existe task em QA aprovada (outros tipos)?
   → Mover para DONE com done:ISO
   → Appendar CONTEXT.md: "[HH:MM] [orquestrador] <task> → DONE"

9. Existe task em DOING travada? (ver Protocolo de Travamento)
   → Se elapsed < 2x limite: redespachar com retry:+1
   → Se elapsed > 2x limite ou retry:>=2: abrir gate:escopo

10. Existe task em PLANNING sem owner ativo?
    → Despachar sub-agente para executar
    → Mover task para DOING com started:ISO

11. Existe task em REFINING?
    → Aguardar (sub-agente esta trabalhando)
    → Verificar se travada (protocolo abaixo)

12. Existe task em BACKLOG disponivel (sem blocked:, sem #proposta)?
    → Verificar dependencias: tem #depende:? Predecessor esta em DONE?
    → Se bloqueada: adicionar blocked:<id> e aguardar
    → Se livre: mover para REFINING + despachar sub-agente

13. Todas tasks em DONE e BACKLOG vazio?
    → Projeto concluido (ver Protocolo de Conclusao)

14. Nenhuma acao possivel?
    → Appendar CONTEXT.md: "[HH:MM] [orquestrador] ciclo sem acao — aguardando"
    → Reagendar normalmente
```

---

## Passo 3 — DISPATCH

Ao despachar sub-agente, criar card no DASHBOARD na coluna TODO:

```markdown
- [ ] **<projeto>-<task-id>** #<agente> #<modelo> #subtask
      `briefing:projects/<projeto>/KANBAN.md task:<task-id>`
      `parent:<projeto>`
      `context:<instrucao adicional se necessario>`
```

### Como Determinar Agente e Modelo

Se a task tem `#agente:<nome>` definido: respeitar.

Se nao tem, aplicar routing:

**Por tipo:**
| Tipo | Agente | Modelo base |
|---|---|---|
| investigate | sage | sonnet |
| brainstorm | sage | sonnet |
| plan | hefesto | sonnet |
| implement | *ver dominio* | sonnet |
| qa | sage | haiku |
| doc | sage | haiku |
| deploy | hefesto | sonnet |
| research | venture | sonnet |
| health | keeper | haiku |

**Para implement, por dominio:**
| Dominio | Agente | Skill |
|---|---|---|
| monolito (Go) | coruja | coruja/monolito |
| bo-container (Vue) | coruja | coruja/bo-container |
| front-student (Nuxt) | coruja | coruja/front-student |
| cross-repo | coruja | coruja/orquestrador |
| infra/Docker | hefesto | vennon/container |
| leech/skills | hefesto | leitura de self/ |
| obsidian/vault | hefesto | meta/obsidian |
| indefinido | hefesto | — |

**Escalada de modelo:**
- "breaking change", "novo servico" → +1 nivel (haiku→sonnet, sonnet→opus)
- cross-repo → +1 nivel
- ja falhou (retry:>=1) → +1 nivel
- task simples reversivel → -1 nivel (minimo haiku)

---

## Passo 4 — GATE

Ao detectar que uma task requer gate:

1. Mover task para coluna `## GATE` no KANBAN
2. Adicionar campos: `gate:<tipo>` `aberto:<ISO>` `aguarda:<pergunta em 1 frase>`
3. Verificar se gate ja foi notificado no feed.md (buscar pelo task-id)
4. Se nao notificado: appendar feed.md com `[HH:MM] [<projeto>] GATE <tipo>: <task> — <aguarda>`
5. Nao despachar sub-agentes para esta task ate aprovacao

**Maximo 1 gate aberto por projeto ao mesmo tempo.**

### Tipos de Gate e Campos Minimos

```markdown
gate:implementacao
  plan:<link-para-plano>
  arquivos:<lista de arquivos>
  risco:<descricao do risco>
  aguarda:<ok para iniciar implementacao>

gate:merge
  branch:<nome-do-branch>
  testes:<resultado>
  diff:<+N/-N linhas em X arquivos>
  aguarda:<ok para push/PR>

gate:deploy
  alvo:<ambiente>
  depende:<o que precisa antes>
  rollback:<como desfazer>
  aguarda:<ok para executar em prod>

gate:escopo
  original:<o que foi pedido>
  descoberto:<o que o agente encontrou>
  opcoes:<A) ... | B) ... | C) ...>
  aguarda:<diretiva do CTO>
```

---

## Passo 5 — CLEANUP

A cada ciclo verificar no DASHBOARD:
- Cards com `#subtask` e `parent:<projeto>` em DONE: Hermes cuida, nao intervir
- Cards com `#subtask` e `parent:<projeto>` em DOING ha mais de 2x o intervalo do projeto: redespachar

---

## Passo 6 — REPORT

Sempre appendar em `/workspace/obsidian/projects/<nome>/CONTEXT.md`:

```
[HH:MM] [orquestrador] <descricao do que foi feito neste ciclo>
```

Formato de entradas por evento:
```
[HH:MM] [orquestrador] SCAN: BACKLOG=3 REFINING=1 PLANNING=0 GATE=0 DOING=0 QA=0 DONE=2
[HH:MM] [orquestrador] DISPATCH: <task-id> → REFINING — despachado <agente> (#subtask criado)
[HH:MM] [orquestrador] GATE: <task-id> — <tipo> aberto, inbox notificado
[HH:MM] [orquestrador] DONE: <task-id> — <resultado 1 linha>
[HH:MM] [orquestrador] ciclo sem acao — aguardando
```

---

## Passo 7 — RESCHEDULE

Confirmar que o card do orquestrador no DASHBOARD esta atualizado com `last:<ISO>`.
O proprio Hermes atualiza apos o ciclo — verificar que nao ficou com estado incorreto.

---

## Protocolo de Dependencias entre Tasks

Antes de mover task do BACKLOG para REFINING:

1. Task tem `#depende:<id>`?
   - Buscar `<id>` no KANBAN
   - Esta em DONE? → task liberada, remover `blocked:` se existir
   - Nao esta em DONE? → adicionar `blocked:<id>` na task, deixar em BACKLOG

2. Task tem `#depende:a|b|c` (multiplas)?
   - Todas precisam estar em DONE para liberar

3. Quando mover task para DONE:
   - Verificar se alguma task em BACKLOG tem `#depende:<id-desta-task>`
   - Se sim: remover `blocked:` da task dependente (ela esta liberada)

---

## Protocolo de Task Travada

Limites por tipo:
| Tipo | Limite de timeout |
|---|---|
| investigate | 3h |
| research | 3h |
| brainstorm | 2h |
| plan | 2h |
| implement | 6h |
| qa | 3h |
| doc | 3h |
| deploy | 2h |

Como calcular elapsed: `ciclo atual - started:<ISO>` da task.

Limites podem ser sobrescritos no BRIEFING.md do projeto (`timeout_implement: 12h`).

Acao ao detectar travamento:
- elapsed < 2x limite: redespachar com `retry:1` (ou incrementar retry existente)
- elapsed > 2x limite OU retry:>=2: abrir `gate:escopo` com pergunta "Task <id> travada por <elapsed> apos <retry> tentativas — redespachar, cancelar ou redefinir escopo?"

---

## Protocolo de Conclusao

Quando BACKLOG esta vazio e todas as tasks estao em DONE:

1. Appendar BRIEFING.md do projeto:
   ```yaml
   status: done
   concluido: <ISO>
   ```

2. Appendar feed.md: `[HH:MM] [<projeto>] PROJETO CONCLUIDO — <N> tasks entregues`

3. Mover card do orquestrador no DASHBOARD de DOING para DONE com `done:<ISO> — projeto <nome> concluido`

4. Nao deletar nada — `projects/<nome>/` permanece intacto

---

## Modo Agent-Direct (simplificado)

Quando card tem `#agent-direct` ou BRIEFING tem `modo: agent-direct`:

```
Algoritmo por ciclo:
1. Ler BRIEFING.md + KANBAN.md
2. Existe task em DOING? → tarefa ainda ativa (raro) → aguardar ou verificar travamento
3. Proxima task no BACKLOG? → mover para DOING + executar diretamente (sem sub-agente) + mover para DONE
4. BACKLOG vazio e tudo DONE? → projeto concluido (protocolo acima)
5. Appendar CONTEXT.md com resultado
```

Modo agent-direct: sem criacao de sub-cards no DASHBOARD, sem delegacao.
O agente e orquestrador e executor ao mesmo tempo.
Nao suporta gates — tasks precisam ser sem aprovacao humana.

---

## Contrato do Sub-agente

Um sub-agente despachado pelo orquestrador deve:
1. Ler KANBAN.md e localizar a task pelo nome (busca linear por `**<task-id>**`)
2. Executar a task conforme o tipo (`#tipo:`)
3. Mover a task para o proximo estado no KANBAN ao concluir
4. Appendar em CONTEXT.md com o resultado
5. Nao alterar outras tasks alem da sua
6. Se encontrar bloqueador: mover task para GATE com `gate:escopo` e descrever o bloqueio

---

## Anti-Patterns

| Errado | Certo |
|---|---|
| Abrir gate para investigate, doc, brainstorm, qa | Gates so para implement, deploy, e escopo inesperado |
| Notificar inbox a cada ciclo com gate aberto | Notificar inbox uma unica vez quando gate e aberto |
| Abrir mais de 1 gate simultaneamente | Maximo 1 gate aberto por projeto |
| Chamar sub-agentes diretamente | Criar cards no DASHBOARD — o unico barramento de despacho |
| Executar tasks diretamente (no modo orchestrated) | Delegar para sub-agentes via DASHBOARD |
| Deletar tasks do KANBAN | NEVER — mover para DONE ou BACKLOG com #rejeitado |
| Criar arquivo de gate fora do KANBAN | Gate vive no KANBAN.md, notificacao no feed.md |
| Perguntar ao humano sobre decisao tecnica | Agente decide, documenta em CONTEXT.md |

---

## Referencia Rapida

```
Card com #orquestrador recebido
        │
        ▼
    SCAN KANBAN
        │
        ├── task em GATE sem aprovacao → notificar inbox (1x) → aguardar
        ├── task em GATE aprovada → DISPATCH sub-agente
        ├── task em QA passed → abrir gate:merge (implement) ou DONE (outros)
        ├── task em QA failed → redespachar com nota
        ├── task em PLANNING → DISPATCH sub-agente
        ├── task em BACKLOG → verificar deps → REFINING → DISPATCH
        ├── task travada → retry ou gate:escopo
        └── tudo DONE → protocolo de conclusao
        │
        ▼
    REPORT em CONTEXT.md
        │
        ▼
    DONE (card orquestrador atualizado)
```
