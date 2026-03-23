---
name: leech/upgrade
description: Implementar e depurar uma feature do Leech de forma autonoma — worktree isolado do /workspace/host, testes sem supervisao, entrega de branch pronto para merge. Auto-ativar quando usuario pede para adicionar/melhorar/corrigir algo no proprio Leech (CLI, agente, skill, hook, script).
---

# Skill: leech/upgrade

Implementar features no Leech de forma autonoma dentro do container. Criar worktree isolado, codificar, testar e validar sem pedir ao Pedro para rodar nada. Entregar branch pronto.

---

## Mapa do Leech

```
/workspace/host/leech/
├── bash/
│   ├── leech                   entrypoint gerado (executavel diretamente)
│   ├── src/
│   │   ├── bashly.yml          spec de comandos e flags (fonte da verdade)
│   │   ├── commands/           implementacao de cada comando (~40 arquivos .sh)
│   │   └── lib/                bibliotecas compartilhadas
│   └── Justfile                build tasks (bashly generate, etc)
├── docker/                     docker-compose por servico
├── rust/                       componentes TUI (zion-tui)
└── self/                       self-knowledge do sistema

/workspace/self/                runtime engine (sempre rw, sem worktree necessario)
├── skills/                     namespace de skills
├── agents/                     cards de agentes (frontmatter + instrucoes)
├── hooks/claude-code/          hooks pre/pos tool e session-start
└── scripts/                    scripts utilitarios bash/python
```

---

## Tipo de mudanca — onde trabalhar

| Tipo | Onde editar | Worktree? |
|------|-------------|-----------|
| CLI — novo comando ou flag | `/workspace/host/leech/bash/src/` | Sim |
| CLI — logica de comando existente | `/workspace/host/leech/bash/src/commands/` | Sim |
| Docker — compose, Dockerfile | `/workspace/host/leech/docker/` | Sim |
| Rust TUI | `/workspace/host/leech/rust/` | Sim |
| Agente — comportamento, schedule, model | `/workspace/self/agents/<nome>/agent.md` | Nao |
| Skill — criar ou atualizar | `/workspace/self/skills/` | Nao |
| Hook — pre/post-tool, session-start | `/workspace/self/hooks/claude-code/` | Nao |
| Script utilitario | `/workspace/self/scripts/` | Nao |

---

## Workflow A — CLI / Docker / Rust (worktree obrigatorio)

### 1. Criar worktree isolado

```bash
git -C /workspace/host worktree add /tmp/leech-upgrade-<feature> -b feat/leech-<feature>
```

### 2. Mapear o que precisa mudar

Para CLI, identificar:
- Novo comando? Adicionar em `bashly.yml` + criar `src/commands/<nome>.sh`
- Nova flag global? Adicionar em `bashly.yml` em `flags:`
- Logica de comando existente? Editar o `.sh` correspondente em `src/commands/`
- Funcao compartilhada? Editar ou criar em `src/lib/`

Ler o comando mais proximo para entender padrao:
```bash
# ver comandos existentes como referencia
ls /tmp/leech-upgrade-<feature>/leech/bash/src/commands/
```

### 3. Implementar

Editar os arquivos no worktree em `/tmp/leech-upgrade-<feature>/leech/bash/src/`.

Se `bashly.yml` foi alterado (novo comando, nova flag), regenerar o CLI:
```bash
nix-shell -p bashly --run \
  "cd /tmp/leech-upgrade-<feature>/leech/bash && bashly generate"
```

### 4. Testar

```bash
# Executar o CLI gerado diretamente
bash /tmp/leech-upgrade-<feature>/leech/bash/leech <comando> <args>

# Checar sintaxe de um arquivo
bash -n /tmp/leech-upgrade-<feature>/leech/bash/src/commands/<arquivo>.sh

# Testar funcao de lib em isolamento
source /tmp/leech-upgrade-<feature>/leech/bash/src/lib/<lib>.sh
<funcao> <args>

# Ver help do novo comando
bash /tmp/leech-upgrade-<feature>/leech/bash/leech <comando> --help
```

Para testes que precisariam do Docker (ex: `leech docker run`), testar a logica sem side effects:
```bash
# Simular env sem docker real
DOCKER_HOST=invalid bash /tmp/.../leech/bash/leech docker status 2>&1
# Verificar que o codigo correto e executado (error esperado do docker, nao de sintaxe)
```

### 5. Iterar ate funcionar

Corrigir, regenerar se necessario, re-testar. Repetir ate todos os casos passarem.

### 6. Commitar no worktree

```bash
git -C /tmp/leech-upgrade-<feature> add -A
git -C /tmp/leech-upgrade-<feature> commit -m "feat(leech): <descricao concisa>"
```

---

## Workflow B — Self (agents, skills, hooks, scripts — sem worktree)

Editar diretamente em `/workspace/self/`. Nao precisa de worktree porque `/workspace/self/` e o runtime vivo da sessao.

### Agente

```bash
# Editar card
# Validar frontmatter obrigatorio
grep -E '^(model|max_turns|timeout|description)' /workspace/self/agents/<nome>/agent.md
```

Campos obrigatorios no frontmatter do agente:
- `model:` (haiku | sonnet | opus)
- `max_turns:` (numero)
- `timeout:` (segundos)
- `description:` (resumo)
- `subagent_type:` (nome do agente)

### Skill

Criar `SKILL.md` com frontmatter correto:
```yaml
---
name: <namespace>/<nome>
description: "Quando auto-ativar: ..."
---
```

Atualizar SEMPRE o SKILL.md do namespace pai (adicionar linha na tabela).

### Hook

```bash
# Testar simulando context vars
CLAUDE_TOOL_NAME=Bash \
CLAUDE_TOOL_INPUT='{"command":"ls"}' \
bash /workspace/self/hooks/claude-code/pre-tool-use.sh
```

### Script

```bash
# Testar diretamente
bash /workspace/self/scripts/<nome>.sh <args>
# Checar sintaxe
bash -n /workspace/self/scripts/<nome>.sh
```

---

## Output padrao ao terminar

Sempre reportar neste formato:

```
PRONTO: <nome da feature>

tipo:     cli | agent | skill | hook | script
branch:   feat/leech-<feature>      (N/A para mudancas em self/)
worktree: /tmp/leech-upgrade-<feature>   (N/A para mudancas em self/)
arquivos: lista dos arquivos modificados

testado:
  - bash -n: OK em todos os .sh
  - leech <cmd> --help: output correto
  - leech <cmd> <args>: comportamento esperado
  - [outros testes realizados]

proximo:
  Pedro roda `leech stow` no host para aplicar (mudancas CLI/docker)
  OU merge do branch via /commit-push-pr
```

---

## Regras de ouro

- **Nunca editar main** do `/workspace/host` diretamente — sempre worktree
- **Sempre testar antes de declarar pronto** — minimo: `bash -n` + 1 teste funcional
- **bashly.yml alterado?** Obrigatorio rodar `bashly generate` e testar o binario gerado
- **Nunca chamar** `leech stow`, `leech switch` ou `leech os` de dentro do container
- **Indices de skills**: ao criar/mover skill, atualizar SKILL.md do namespace pai
- **Nao pedir ao usuario para rodar comandos** — se precisar testar algo, encontrar forma de testar autonomamente

---

## Casos comuns

### Adicionar novo comando ao CLI

1. Criar `src/commands/<nome>.sh` com a logica
2. Adicionar entrada em `bashly.yml` sob `commands:`
3. Rodar `bashly generate`
4. Testar: `bash leech <nome> --help` e `bash leech <nome> <args>`

### Modificar comando existente

1. Editar `src/commands/<nome>.sh`
2. Se mudou assinatura: atualizar `bashly.yml` e regenerar
3. Testar comportamento antigo + novo

### Adicionar novo agente

1. Criar `/workspace/self/agents/<nome>/agent.md` com frontmatter completo
2. Testar card: `leech agents run <nome>` (ou dry-run verificando o card)
3. Registrar no vault Obsidian se for agente permanente

### Criar nova skill

1. Criar `/workspace/self/skills/<ns>/<nome>/SKILL.md`
2. Atualizar `/workspace/self/skills/<ns>/SKILL.md` (tabela)
3. Se namespace novo: atualizar REGISTRY se existir

---

## Capacidades disponiveis no container

```bash
# Executar CLI leech do host (worktree ou main)
bash /workspace/host/leech/bash/leech <cmd>

# Regenerar CLI apos mudancas no bashly.yml
nix-shell -p bashly --run "cd <worktree>/leech/bash && bashly generate"

# Instalar qualquer ferramenta on-the-fly
nix-shell -p <pacote> --run "<cmd>"

# Git worktrees
git -C /workspace/host worktree add /tmp/<nome> -b <branch>
git -C /workspace/host worktree remove /tmp/<nome>
git -C /workspace/host worktree list

# Escrever em self/
# /workspace/self/ e sempre rw nesta sessao
```
