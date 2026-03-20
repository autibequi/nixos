# /background:launch — Decompor e lançar subagentes em paralelo

Recebe uma descrição de trabalho, decompõe em subtarefas independentes e lança cada uma como subagente background via `TaskCreate`, sem bloquear a sessão principal.

## Entrada
- `$ARGUMENTS`: descrição da tarefa a ser dividida (texto livre)

## Instruções

### 1. Validar entrada
Se `$ARGUMENTS` estiver vazio, perguntar ao user o que quer executar.

### 2. Decompor em subtarefas
Analisar `$ARGUMENTS` e identificar subtarefas **independentes** entre si (podem rodar em paralelo sem conflito).

Regras de decomposição:
- Máximo **5 subtarefas** por launch
- Cada subtarefa deve ser **autocontida** — o subagente não depende de output de outro
- Subtarefas que precisam ser sequenciais → **não dividir**, manter como uma só
- Nomear cada subtarefa em kebab-case curto (ex: `refactor-auth`, `add-tests`, `update-docs`)

### 3. Montar prompts dos subagentes
Para cada subtarefa, criar um prompt completo que inclua:
- Contexto herdado do `$ARGUMENTS` original
- Escopo específico desta subtarefa (o que fazer e o que **não** tocar)
- Instrução de reportar ao final: "Ao concluir, liste arquivos criados/modificados e resultado."
- Se aplicável: worktree ou branch em que deve trabalhar

### 4. Lançar em paralelo
Chamar `TaskCreate` para **todas as subtarefas ao mesmo tempo** (em paralelo, numa única resposta).

Cada `TaskCreate`:
- `description`: nome da subtarefa
- `prompt`: prompt completo da subtarefa

### 5. Reportar ao user
Após lançar, mostrar resumo:

```
╭─ background:launch ──────────────────────────────╮
  Subtarefas lançadas: N

  [1] nome-da-subtarefa-1  → task_id
  [2] nome-da-subtarefa-2  → task_id
  ...

  Rodando em paralelo. Use TaskOutput <id> para ver progresso.
╰──────────────────────────────────────────────────╯
```

## Regras
- NUNCA executar as subtarefas inline — sempre via `TaskCreate` (background)
- Subtarefas não devem editar os mesmos arquivos (verificar antes de lançar)
- Se o trabalho for claramente sequencial (ex: "criar migration e rodar"), lançar como **uma** task, não N
- Não criar worktrees automaticamente — só se o prompt original pedir isolamento
- Manter a sessão principal limpa: o lançamento é o único output, sem detalhes de implementação aqui
