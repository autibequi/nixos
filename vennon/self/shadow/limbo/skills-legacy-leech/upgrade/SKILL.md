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
├── rust/                       CLI Rust (fonte da verdade)
│   ├── Cargo.toml              workspace
│   ├── justfile                build targets (just build, just install)
│   └── crates/leech-cli/
│       └── src/
│           ├── main.rs         Clap enum + dispatch (4 dominios: Session/Agents/Services/System)
│           ├── help.rs         Banner, man page, before_help blocks
│           ├── config.rs       Figment config (defaults → YAML → env → CLI)
│           ├── commands/       handlers (session, agents, runner, docker, host, tools, config_cmd, ...)
│           ├── tui/            TUI dashboard (ratatui)
│           └── *.rs            core logic (paths, session, model, agents, compose, executor, ...)
├── bash/                       legado (mantido para referencia, NAO e o ativo)
├── docker/                     docker-compose por servico
└── self/                       self-knowledge do sistema

/workspace/self/                runtime engine (sempre rw, sem worktree necessario)
├── skills/                     namespace de skills
├── agents/                     cards de agentes (frontmatter + instrucoes)
├── hooks/                      hooks (Claude + Cursor + ENGINE)
└── scripts/                    scripts utilitarios bash/python

~/.config/leech/config.yaml     config estruturado (Figment YAML provider)
~/.leech                        tokens + env vars (bash-sourceable, legado)
```

### Arquitetura de config — Figment layered

```
Built-in defaults → config.yaml → LEECH_* env vars → CLI flags
        ↑                ↑              ↑                ↑
   config.rs         ~/.config/    Env::prefixed     Clap args
   Default impl      leech/        ("LEECH_")        (Option<T>)
```

Struct unificada: `LeechConfig` com sub-structs `session`, `runner`, `agents`, `paths`, `system`, `secrets`.

---

## Tipo de mudanca — onde trabalhar

| Tipo | Onde editar | Worktree? |
|------|-------------|-----------|
| CLI — novo comando ou flag | `/workspace/host/leech/rust/crates/leech-cli/src/` | Sim |
| CLI — logica de comando existente | `/workspace/host/leech/rust/crates/leech-cli/src/commands/` | Sim |
| Docker — compose, Dockerfile | `/workspace/host/leech/docker/` | Sim |
| Agente — comportamento, schedule, model | `/workspace/self/ego/<nome>/agent.md` | Nao |
| Skill — criar ou atualizar | `/workspace/self/skills/` | Nao |
| Hook — pre/post-tool, session-start | `/workspace/self/hooks/` | Nao |
| Script utilitario | `/workspace/self/scripts/` | Nao |

---

## Workflow A — CLI / Docker / Rust (worktree recomendado)

### 1. Criar worktree isolado

```bash
git -C /workspace/host worktree add /tmp/leech-upgrade-<feature> -b feat/leech-<feature>
```

### 2. Mapear o que precisa mudar

Para CLI Rust, identificar:
- Novo comando? Adicionar variante em `enum Commands` em `main.rs` + dispatch + funcao em `commands/`
- Nova flag global? Adicionar em `Cli` struct
- Logica de comando existente? Editar o `.rs` correspondente em `commands/`
- Atualizar exemplos em `help.rs` (DIRECTIVE: obrigatorio a cada mudanca)

Ler o comando mais proximo para entender padrao:
```bash
ls /tmp/leech-upgrade-<feature>/leech/rust/crates/leech-cli/src/commands/
```

### 3. Implementar

Editar os arquivos no worktree em `/tmp/leech-upgrade-<feature>/leech/rust/crates/leech-cli/src/`.

### 4. Testar

```bash
# Compilar
nix-shell -p rustc cargo --run \
  "cd /tmp/leech-upgrade-<feature>/leech/rust && cargo build --release -p leech-cli 2>&1 | tail -5"

# Executar o binario diretamente
/tmp/leech-upgrade-<feature>/leech/rust/target/release/leech <comando> --help
/tmp/leech-upgrade-<feature>/leech/rust/target/release/leech <comando> <args>
```

Para testes que precisariam do Docker (ex: `vennon mono status`), testar a logica sem side effects:
```bash
DOCKER_HOST=invalid /tmp/.../leech/rust/target/release/vennon mono status 2>&1
```

### 5. Iterar ate funcionar

Corrigir, re-compilar, re-testar. Repetir ate todos os casos passarem.

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
grep -E '^(model|max_turns|timeout|description)' /workspace/self/ego/<nome>/agent.md
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
bash /workspace/self/hooks/pre-tool-use.sh
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
  Pedro roda `deck stow` no host para aplicar (mudancas CLI/docker)
  OU merge do branch via /commit-push-pr
```

---

## Regras de ouro

- **Para mudancas em CLI/Docker**, considerar worktree para isolamento — perguntar ao user se prefere
- **Sempre testar antes de declarar pronto** — minimo: compilar + `leech <cmd> --help` + 1 teste funcional
- **main.rs alterado?** Obrigatorio atualizar `help.rs` (DIRECTIVE no topo do arquivo)
- **Nunca chamar** `deck stow`, `leech switch` ou `leech os` de dentro do container
- **Indices de skills**: ao criar/mover skill, atualizar SKILL.md do namespace pai
- **Nao pedir ao usuario para rodar comandos** — se precisar testar algo, encontrar forma de testar autonomamente

---

## Casos comuns

### Adicionar novo comando ao CLI

1. Adicionar funcao em `commands/<modulo>.rs` (ou criar novo modulo + registrar em `commands/mod.rs`)
2. Adicionar variante em `enum Commands` em `main.rs`
3. Se o comando precisa de defaults configuraveis: usar `Option<T>` nos args + fallback `cfg.runner.*` / `cfg.agents.*`
4. Adicionar dispatch no `match` de `main.rs`
5. Adicionar exemplos em `help.rs` (DIRECTIVE obrigatorio)
6. Compilar e testar: `leech <nome> --help` e `leech <nome> <args>`

### Modificar comando existente

1. Editar `commands/<modulo>.rs`
2. Se mudou assinatura: atualizar `main.rs` + `help.rs`
3. Se adicionou flag com default configuravel: trocar `default_value` por `Option` + fallback `LeechConfig`
4. Compilar e testar comportamento antigo + novo

### Adicionar campo ao config

1. Adicionar campo na sub-struct relevante em `config.rs` (SessionConfig, RunnerConfig, etc.)
2. Adicionar `#[serde(default = "...")]` com valor built-in
3. Atualizar `Default impl` e `display()` em `config.rs`
4. Atualizar `DEFAULT_TEMPLATE` em `config.rs`
5. Env var automatica: `LEECH_<SECTION>_<FIELD>` (ex: `LEECH_RUNNER_ENV=sand`)

### Adicionar novo agente

1. Criar `/workspace/self/ego/<nome>/agent.md` com frontmatter completo
2. Testar card: `yaa agents run <nome>` (ou dry-run verificando o card)
3. Registrar no vault Obsidian se for agente permanente

### Criar nova skill

1. Criar `/workspace/self/skills/<ns>/<nome>/SKILL.md`
2. Atualizar `/workspace/self/skills/<ns>/SKILL.md` (tabela)
3. Se namespace novo: atualizar REGISTRY se existir

---

## Capacidades disponiveis no container

```bash
# Compilar e testar CLI Rust (worktree ou main)
nix-shell -p rustc cargo --run \
  "cd <worktree>/leech/rust && cargo build --release -p leech-cli 2>&1 | tail -5"
<worktree>/leech/rust/target/release/leech <cmd>

# Instalar qualquer ferramenta on-the-fly
nix-shell -p <pacote> --run "<cmd>"

# Git worktrees
git -C /workspace/host worktree add /tmp/<nome> -b <branch>
git -C /workspace/host worktree remove /tmp/<nome>
git -C /workspace/host worktree list

# Escrever em self/
# /workspace/self/ e sempre rw nesta sessao
```
