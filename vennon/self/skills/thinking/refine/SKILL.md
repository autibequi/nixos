---
name: thinking/refine
description: "Usar quando receber um problema grande/spec complexa para implementar. Ensina a investigar, mapear, e quebrar em tasks pequenas antes de escrever qualquer codigo. Generico — funciona para app, backend, CLI, agent card."
---

# refinar — Quebrar Problema Grande em Tasks Pequenas

> Investigar antes de planejar. Planejar antes de implementar.
> Uma task mal dimensionada gera retrabalho. Uma task bem dimensionada gera progresso.

---

## Quando usar (gatilhos)

| Situacao | Acao |
|----------|------|
| Criar card de agente com implementacao | Obrigatorio — refinar antes de criar |
| Feature com mais de 2 arquivos | Obrigatorio |
| Pedido vago ("faz um app de X", "implementa Y") | Obrigatorio — nao sair fazendo |
| Task simples (<1h, 1 arquivo) | Opcional |
| Hotfix urgente | Dispensavel |

**Madrugada (21h-6h UTC) = janela de execucao ideal.** Tokens nao utilizados, quota livre, sem interrupcao. Cards pesados devem ser agendados para madrugada — o refinamento feito agora queima tokens que seriam desperdicados de qualquer forma.

---

## Principio

**Nunca sair fazendo.** Qualquer problema com mais de 2 arquivos envolvidos ou mais de 1 hora de trabalho estimado precisa passar pelo processo de refinamento primeiro.

O output do refinamento é um **backlog ordenado** de tasks atômicas — cada uma executável de forma independente, em uma única sessão, com resultado verificável.

---

## Processo de refinamento

### Passo 0 — Entrar em Plan Mode

Chamar `EnterPlanMode` imediatamente.
Nenhum arquivo criado, nenhum codigo escrito, nenhuma branch criada até o plano estar aprovado.

### Passo 1 — Investigar o estado atual

Antes de planejar, entender o que ja existe.

```
Perguntas a responder:
- Qual é a estrutura de pastas do projeto?
- O que ja foi implementado? O que é esqueleto vazio?
- Quais dependencias ja estão no pubspec/go.mod/package.json?
- Qual é o padrão de código existente (arquitetura, naming, estilo)?
- Onde estão os pontos de extensão (providers, routers, DB schemas)?
```

Ferramentas:
- `Glob` para mapear arquivos
- `Read` nos arquivos de entrada do projeto (main, app, schema, rotas)
- `Bash` para inspecionar dependencias (`cat pubspec.yaml`, `go list ./...`)

**Regra:** nunca planejar sem ter lido pelo menos: arquivo de entrada, schema/modelo de dados, e um provider/service existente. O padrão existente é a lei.

### Passo 2 — Mapear as camadas de dependência

Todo sistema tem camadas com dependências unidirecionais. Identificar as camadas ANTES de criar tasks, porque a ordem das tasks segue as camadas.

**App mobile/frontend:**
```
Dados (entidades, DB, migrations)
  ↓
Repositório (CRUD, streams)
  ↓
Estado (providers, store, BLoC)
  ↓
UI básica (pages, navigation, layout)
  ↓
Features core (fluxos principais)
  ↓
Edge cases (validação, erros, loading)
  ↓
Polish (animações, empty states, acessibilidade)
```

**Backend API:**
```
Entidade + tabela (migration)
  ↓
Repositório (queries, CRUD)
  ↓
Service (lógica de negócio, validações)
  ↓
Handler/endpoint (HTTP, serialização)
  ↓
Testes (unitário → integração)
  ↓
Integração (wiring, DI, rotas registradas)
```

**CLI / agent card:**
```
Estrutura de dados (config, estado persistente)
  ↓
Lógica core (processamento, decisões)
  ↓
I/O (leitura de fontes, escrita de outputs)
  ↓
Protocolo (scheduling, reagenda, fallbacks)
  ↓
Polimento (logging, feedback visual, edge cases)
```

**Regra:** tasks de camada N só podem começar após camada N-1 estar concluída.

### Passo 3 — Fatiar em tasks atômicas

Cada task deve ter:
- **1 responsabilidade** — se tem "e" no nome, provavelmente são 2 tasks
- **Resultado verificável** — `flutter analyze`, `go build`, tela renderiza, teste passa
- **Independência** — não depende de tasks paralelas incompletas
- **Contexto suficiente** — executável a frio, sem precisar de contexto extra
- **Nome como ação** — verbo + substantivo: "Criar tabela Categories", "Implementar CategoryProvider"

### Passo 4 — Dimensionar por tempo de sessão

| Tipo de sessão | Tempo | Critério de corte |
|----------------|-------|-------------------|
| Agente autônomo (sonnet) | ~25-30min | 1 arquivo novo OU 1-3 arquivos editados |
| Sessão interativa | ~45-60min | 1 feature completa de uma camada |
| Worker longo | ~90min | 1 fase completa |

**Teste de dimensionamento:** "Consigo implementar, verificar e marcar done em uma única sessão?"
- Se não → quebrar mais
- Se sim mas é trivial (~5min) → juntar com a próxima task

**Sinais de task mal dimensionada:**
- Nome tem mais de 10 palavras
- Envolve mais de 3 arquivos novos
- Descrição usa "e também" ou "além disso"
- Depende de decisão de design ainda em aberto

### Passo 5 — Ordenar e nomear

Convenções:
- Prefixo `TX:` onde X é número sequencial (T01, T02, ...)
- Agrupadas por fase com header de seção
- Dependências implícitas na ordem (T03 usa o que T01 e T02 criaram)
- Tasks independentes dentro de uma fase podem ser paralelas — marcar com `[paralela]`

```markdown
### Fase 1 — Modelo de dados

- [ ] T01: Criar entidade Foo (campos: id, name, createdAt) + tabela DB + migration
- [ ] T02: Criar FooRepository com watchAll, insert, update, delete

### Fase 2 — Estado

- [ ] T03: Criar FooProvider (ChangeNotifier) com lista reativa do FooRepository
- [ ] T04: Registrar FooProvider no MultiProvider do main.dart
```

### Passo 6 — Montar o backlog

O backlog vai no próprio card/arquivo de controle da feature, não num arquivo separado.

Estrutura mínima de um card com backlog:

```markdown
## Backlog

> N tasks. Uma por sessão. Marcar [x] ao concluir + registrar worktree/branch.

### Fase 1 — [nome da fase]
- [ ] T01: [descrição atômica com contexto suficiente]
- [ ] T02: [...]

### Fase 2 — [nome da fase]
- [ ] T03: [...]

## Progresso

| Task | Status | Branch | Concluída |
|------|--------|--------|-----------|
| T01 | pendente | — | — |
```

### Passo 7 — Revisar antes de executar

Checklist antes de sair do plan mode:

```
[ ] Todas as tasks têm resultado verificável?
[ ] A ordem respeita as camadas de dependência?
[ ] Nenhuma task tem mais de ~30min de trabalho?
[ ] Cada task tem contexto suficiente para ser executada a frio?
[ ] O progresso é rastreável (tabela ou checkboxes)?
[ ] Tasks paralelas estão marcadas como tal?
[ ] Existe uma skill ou arquivo de conhecimento para acumular aprendizados?
```

---

## O que faz uma boa task vs uma ruim

| Boa task | Ruim task |
|----------|-----------|
| "Criar entidade Category com campos id/name/icon/color + tabela Drift + migration" | "Implementar o sistema de categorias" |
| "Criar CategoryRepository com watchAll, insert, delete" | "Fazer o banco funcionar com categorias" |
| "Refatorar HomePage para usar CategoryBottomNav e filtrar todos por categoria ativa" | "Conectar tudo na tela principal" |
| Resultado: `flutter analyze` sem erros | Resultado: "deve funcionar" |

---

## Busca em ondas — investigar codebase antes de planejar

Para projetos existentes, investigar em ondas antes de criar o backlog:

**Onda 1 — Mapa geral:**
- Estrutura de pastas
- Arquivos de entrada (main, app, schema)
- Dependências declaradas

**Onda 2 — Padrões existentes:**
- Ler 1 entidade existente → entender naming e estrutura
- Ler 1 repositório existente → entender padrão de acesso a dados
- Ler 1 provider/service existente → entender padrão de estado
- Ler 1 page/handler → entender padrão de UI/API

**Onda 3 — Pontos de extensão:**
- Onde registrar o novo provider (main.dart? app.dart?)
- Onde registrar a nova rota (router.go? routes.dart?)
- Existe migration system? Como adicionar?

**Regra das ondas:** não pular onda. Uma task planejada sem ler o padrão existente quase sempre gera conflito na implementação.

---

## Agentes recorrentes — card como backlog vivo

Quando o executor é um agente autônomo recorrente (como doings-auto):

1. **O card é o backlog** — checklist vive no proprio card, não num arquivo separado
2. **Cada ciclo = 1 task** — agente pega o primeiro `- [ ]`, implementa, marca `- [x]`
3. **Worktree por task** — cada task em branch isolada para revisão posterior
4. **Skill de conhecimento** — criar `/workspace/self/skills/<dominio>/SKILL.md` e atualizar a cada ciclo
5. **Reagenda sempre** — mesmo se falhar, reagendar antes de encerrar

Protocolo padrão de ciclo de agente recorrente:
```
1. Ler skill de dominio (ex: skills/flutter/SKILL.md)
2. Identificar primeiro - [ ] no backlog
3. Criar worktree: git worktree add ~/worktrees/<branch> -b <branch>
4. Implementar + verificar (flutter analyze / go build / etc.)
5. Marcar - [x] no card + registrar branch
6. Atualizar skill de dominio com aprendizados do ciclo
7. Postar no feed
8. Reagendar (+N min)
```

---

## Padrões de tamanho por tecnologia

| Tecnologia | Task de ~25min |
|-----------|----------------|
| Flutter/Dart | 1 widget novo OU 1 entidade+tabela OU 1 provider |
| Go backend | 1 handler OU 1 service method OU 1 migration |
| Vue component | 1 componente com props/emits OU 1 store module |
| NixOS module | 1 modulo novo OU set de pacotes de 1 categoria |
| Shell/CLI | 1 subcomando OU 1 script com tratamento de erro |
| Agent card | 1 fase de protocolo (ciclo completo de 1 etapa) |

---

## Anti-patterns

| Anti-pattern | Consequência | Correcao |
|-------------|-------------|---------|
| Planejar sem investigar | Conflito com código existente, retrabalho | Ler pelo menos main + 1 exemplo de cada camada primeiro |
| Task com 2+ responsabilidades | Parcialmente feita, sem resultado verificável | Quebrar no "e" — cada "e" é uma nova task |
| Tasks sem ordem de dependência | Agente tenta T04 antes de T01 existir | Numerar sequencialmente, respeitar camadas |
| Progresso fora do card | Estado perdido entre sessões | Checklist no próprio card, tabela de progresso inline |
| Dimensionar pelo otimismo | Sessão estura, tarefa incompleta | Dimensionar pela pior estimativa, não pela melhor |
| Implementar em main sem worktree | Conflito com trabalho em andamento | Worktree por task, main sempre limpa |

---

## Lições aprendidas

### Doings-auto (2026-03-22)
- **Fase 1 é sempre dados** — tudo que vem depois depende da entidade/tabela existir. Nunca colocar UI antes de modelo de dados.
- **Fase de state management vem antes da UI** — tentar montar uma BottomNav sem o provider pronto é retrabalho garantido.
- **Colocar o backlog no card** — o agente pode ler o proprio card e atualiza-lo sem precisar de arquivo externo. Mais simples, menos dependência.
- **Nomear tasks com TX:** — o prefixo permite referenciar tasks sem ambiguidade na tabela de progresso e no feed.
- **Tabela de progresso inline** — coluna Status + Branch + Data dá visibilidade sem precisar abrir cada worktree.
- **Polish é sempre a última fase** — animações, empty states, e acessibilidade nunca devem bloquear features core.
