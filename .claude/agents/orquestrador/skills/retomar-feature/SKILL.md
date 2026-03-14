---
name: orquestrador/retomar-feature
description: Use when resuming work on a feature that was started in a previous session. Reads the feature folder, identifies what was completed vs pending by analyzing feature.md and feature.X.md files, checks git state of each repo, and resumes from where it stopped.
---

# retomar-feature: Retomar Feature Interrompida

## Inputs

Recebe o identificador da feature de uma das formas:
- Jira ID (ex: `FUK2-1234`)
- Nome da pasta (ex: `FUK2-bloqueio-edicao-toc-rebuild`)
- Ou nenhum — se houver apenas uma pasta de feature ativa, usar essa

## Passo 1 — Localizar a pasta da feature

Buscar a pasta dentro de `vault/_agent/tasks/`:

```bash
ls vault/_agent/tasks/
```

Se o dev forneceu um Jira ID, procurar `vault/_agent/tasks/FUK2-<Codigo>/`. Se forneceu nome, procurar `vault/_agent/tasks/<nome>/`. Se não forneceu nada e houver apenas uma pasta, usar essa. Se houver múltiplas, listar e pedir que o dev escolha.

**Se a pasta não existir:** informar o dev e perguntar se quer iniciar uma feature nova (redirecionar para `orquestrador/orquestrar-feature`).

## Passo 2 — Ler todos os arquivos de controle

Ler em paralelo todos os arquivos da pasta:

| Arquivo | Informação extraída |
|---|---|
| `feature.md` | Visão geral, progresso centralizado, branch, repositórios envolvidos |
| `feature.monolito.md` | Entregas do monolito — quais `[x]` e quais `[ ]` |
| `feature.bo.md` | Entregas do bo-container — quais `[x]` e quais `[ ]` |
| `feature.frontstudent.md` | Entregas do front-student — quais `[x]` e quais `[ ]` |

Nem todos os arquivos existirão — apenas os repositórios envolvidos terão seu `feature.X.md`.

## Passo 3 — Verificar estado do git em cada repositório envolvido

Para cada repositório que tem `feature.X.md`:

```bash
cd /home/claude/projects/estrategia/<repo>/
HOME=/tmp git branch --show-current
HOME=/tmp git status --short
HOME=/tmp git log --oneline -10
```

Verificar:
1. **Branch correta?** — A branch registrada no `feature.md` está checked out?
2. **Mudanças não commitadas?** — Há trabalho em andamento que não foi commitado?
3. **Commits existentes?** — Os commits batem com as entregas marcadas `[x]`?

## Passo 4 — Diagnosticar o estado da feature

Classificar a feature em um dos estados:

### Estado A — Plano não aprovado
O `feature.md` existe mas os `feature.X.md` não foram criados. A sessão anterior parou durante a negociação (Passos 1-4 do `orquestrar-feature`).

**Ação:** Apresentar o `feature.md` ao dev e perguntar se o plano continua válido ou precisa de ajustes. Após aprovação, retomar do Passo 5 do `orquestrar-feature`.

### Estado B — Arquivos criados, subagentes não lançados
Os `feature.X.md` existem mas nenhuma entrega está marcada `[x]`. As branches podem ou não existir.

**Ação:** Verificar se as branches existem. Se não, criá-las (Passo 5.5 do `orquestrar-feature`). Confirmar com o dev e lançar os subagentes na ordem correta.

### Estado C — Implementação parcial
Algumas entregas estão `[x]`, outras `[ ]`. Um ou mais repositórios foram parcialmente implementados.

**Ação:** Este é o caso mais comum. Seguir o Passo 5 desta skill.

### Estado D — Implementação concluída, sem review/changelog
Todas as entregas estão `[x]` mas os passos finais (review, changelog, relatório) não foram executados.

**Ação:** Pular direto para o Passo 6.5 (code review) ou Passo 7 (changelog) do `orquestrar-feature`.

## Passo 5 — Retomar implementação parcial (Estado C)

### 5a — Montar o mapa de progresso

Construir uma tabela resumo para o dev:

```
## Retomada: [JIRA-ID]

### Progresso atual

| Repositório | Concluídas | Pendentes | Status |
|---|---|---|---|
| monolito | 3/5 | migration ✓, entity ✓, repo ✓, service ✗, handler ✗ | parcial |
| bo-container | 0/4 | service ✗, route ✗, component ✗, page ✗ | não iniciado |
| front-student | — | — | não envolvido |

### Mudanças não commitadas
- monolito: [lista ou "limpo"]
- bo-container: [lista ou "limpo"]
```

### 5b — Identificar ponto de retomada

Determinar qual é o **próximo repositório e próxima entrega** a implementar, respeitando a ordem:
1. monolito (se tiver entregas pendentes)
2. bo-container (se tiver entregas pendentes)
3. front-student (se tiver entregas pendentes)

**Se o monolito tem entregas pendentes:** retomar pelo monolito primeiro, mesmo que os frontends também tenham pendências.

**Se o monolito está concluído mas os endpoints nos `feature.bo.md`/`feature.frontstudent.md` ainda têm placeholders:** atualizar com os endpoints reais antes de lançar os frontends (Passo "Após 6a" do `orquestrar-feature`).

### 5c — Lidar com mudanças não commitadas

Se algum repositório tem mudanças não commitadas:
1. Verificar se as mudanças correspondem à próxima entrega pendente (trabalho em andamento)
2. Se sim: informar o dev e perguntar se quer commitá-las ou descartá-las
3. Se não faz sentido: alertar o dev sobre os arquivos modificados antes de prosseguir

### 5d — Confirmar e retomar

Apresentar o mapa de progresso ao dev e perguntar:

```
Retomar a implementação a partir de [próximo repo / próxima entrega]?
```

Após confirmação, lançar o subagente com instrução de retomada:

```
[prompt padrão do subagente]

RETOMADA: algumas entregas já foram concluídas (marcadas com [x] no feature.X.md).
Comece a partir da primeira entrega ainda marcada como [ ] e siga em diante.
```

Seguir o fluxo normal do `orquestrar-feature` a partir do ponto de retomada (6a, 6b ou 6c), incluindo os passos intermediários de atualização.

## Passo 6 — Após retomada concluir

Seguir os passos finais do `orquestrar-feature`:
- Passo 6.5 — Code review automatizado
- Passo 7 — Gerar changelog
- Passo 8 — Consolidar e reportar

## Regras

- **Nunca assumir estado** — sempre ler os arquivos e verificar o git
- **Nunca relançar entregas já concluídas** — respeitar os `[x]` existentes
- **Manter a ordem** — monolito antes de frontends, mesmo na retomada
- **Confirmar com o dev** antes de lançar qualquer subagente
- **Se o plano original ficou obsoleto** (ex: requisitos mudaram), sugerir ao dev ajustar o `feature.md` e os `feature.X.md` antes de retomar
- **Mudanças não commitadas são tratadas com cuidado** — nunca descartar sem confirmação
