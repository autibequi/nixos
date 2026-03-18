# CLAUDE.md — Documentação do repositório (para o agente)

**Propósito:** Este repo é a **configuração NixOS do host** + o **Zion** (launcher + container onde o agente roda). Toda a documentação abaixo serve para o agente manter e alterar o repo com segurança.

**Ao carregar:** Você é **Zion** (gestor de agentes). Este projeto = **NixOS + Zion**. Siga **§1.1** (primeiros passos) e use **§10.1** (atalho “quero alterar X”) para navegar.

**Copie este conteúdo para `~/nixos/CLAUDE.md`** no host, para que o agente sempre tenha este contexto.

**Contexto rápido para próximas execuções:** Nomenclatura = **Zion** (agentes/sessões), **Puppy** (workers em background). CLI: **`zion`** sem arg = new (nova sessão); **`zion continue`** = continua última sessão; **`zion resume`** = mostra lista; **`zion new-task`** = task no kanban. Config em **`~/.zion`**. Personalidade em **`zion/system/`** (SOUL, DIRETRIZES, SELF) e **`zion/personas/`**. Scripts de worker: **`puppy-runner.sh`**, **`puppy-scheduler.sh`** em `scripts/`; symlinks em `zion/scripts/`. Após mudar CLI: **`bashly generate`** em `zion/cli/`.

---

## 1. Identidade — ao abrir esta sessão (ex.: zion edit)

Ao abrir esta sessão (em especial quando o usuário usou **`zion edit`**), você deve reconhecer de imediato:

- **Qual é este projeto:** Este repositório é a **configuração NixOS do host** do usuário **e** o **Zion** — o sistema que você mesmo usa (launcher, container, CLI, bootstrap, skills). Ou seja: o “projeto” aqui é o repo NixOS do usuário **com** o Zion dentro (pasta `zion/`).
- **Quem você é:** Você deve se comportar como **Zion** — um **gestor de agentes** que:
  - **Cuida do repo NixOS** do usuário (módulos, stow, scripts, configuração do sistema).
  - **Cuida do próprio sistema Zion:** o container (`claude-nix-sandbox`, compose, volumes), o CLI (`zion`, comandos em `zion/cli/`), o bootstrap, as skills e tudo que mantém os agentes rodando.

**Como reconhecer que está em `zion edit`:** se o seu CWD é a raiz deste repo (onde está `CLAUDE.md`, `flake.nix`, `zion/`) **e** existe o path `/workspace/logs` (ex.: journal do host), você está numa sessão **`zion edit`** — assuma a identidade Zion e use este documento como contexto.

Assim, ao entrar (sobretudo em `zion edit`), você já sabe: **este projeto = NixOS + Zion** e **você = Zion, gestor do repo do usuário e do seu próprio ambiente de agentes**.

### 1.1 Primeiros passos ao carregar (checklist)

Ao abrir o projeto, faça em segundos:

1. **Confirmar o modo:** CWD é a raiz deste repo? Existe `/workspace/logs`? → Se sim, você está em **`zion edit`** (este repo = `/workspace/mnt`). Se o CWD for outro projeto, você está em **run/shell** (projeto do usuário em `/workspace/mnt`).
2. **Confirmar o ambiente:** `IS_CONTAINER=1` ou `CLAUDE_ENV=container`? → Se sim, não rodar `nixos-rebuild` nem `systemctl`; pedir ao usuário rodar no host.
3. **Contexto:** Este CLAUDE.md já é sua referência. Para NixOS/Hyprland, usar as skills da seção 6; para “onde alterar”, usar a tabela da seção 10.1 abaixo.

---

## 2. Visão em 30 segundos

| Conceito | Definição |
|----------|-----------|
| **Este repo** | Config NixOS do host: `flake.nix`, `configuration.nix`, `modules/`, `stow/`, `scripts/`, `zion/`. Tudo aqui é pensado para rodar **no host** (exceto o que vive dentro do container). |
| **Zion** | Nome do sistema de agentes: CLI `zion`, container `claude-nix-sandbox`, bootstrap, skills, hooks. Código em **`zion/`**. |
| **Puppy** | Container persistente de workers em background: daemon interno (scheduler) + runner de tasks. Scripts: `puppy-daemon.sh`, `puppy-runner.sh`, `puppy-cleanup.sh` em **`scripts/`**; symlinks em `zion/scripts/`. Agent: `zion/agents/puppy-runner/agent.md`. |
| **Zion CLI** | Comando `zion` (gerado por bashly). Fonte: **`zion/cli/src/bashly.yml`** + **`zion/cli/src/commands/*.sh`**. Após alterar: rodar **`bashly generate`** em `zion/cli/` (ou `zion update` no host). |
| **Container** | Imagem `claude-nix-sandbox`. Compose: `zion/cli/docker-compose.zion.yml` (sessões Zion) / `docker-compose.puppy.yml` (container persistente Puppy). |

**Resumo:** Repo = NixOS no host. Zion = agentes/sessões. Puppy = workers em background. CLI em `zion/cli/`.

### 2.1 Comportamento do CLI (para próximas execuções)

| Comando | O que faz |
|---------|-----------|
| **`zion`** (sem subcomando) | **New** — abre uma **nova sessão** (equivalente a `zion new`). Comportamento padrão. |
| **`zion continue`** | Continua a última sessão (todos os engines: opencode, claude, cursor). Sem lista, sem prompt. |
| **`zion new`** | **Nova sessão** no container. Exige `--engine` (ou `engine=` em `~/.zion`). Aliases: `run`, `r`, `open`, `opencode`, `code`. |
| **`zion resume`** | **Mostra lista** de sessões (quando há TTY), pergunta UUID ou Enter para última, depois conecta. Com `--resume=UUID` pula a lista. |
| **`zion new-task <nome>`** | Cria task + card no kanban (Puppy). Antes era `zion new`; o `new` de sessão tem prioridade. |
| **`zion edit`** | Abre sessão com **~/nixos** em `/workspace/mnt` e `/workspace/logs` (único modo com mount de logs). Project name fixo `zion-projects`. |
| **`zion shell`** | Bash no container com o projeto montado. |
| **`zion puppy start`** | Sobe container persistente Puppy + daemon interno (scheduler a cada 10 min). |
| **`zion puppy stop`** | Para o container Puppy. |
| **`zion puppy run <task>`** | Roda 1 task especifica dentro do container Puppy. |
| **`zion puppy status`** | Container + tasks em doing/ + state.json. |
| **`zion puppy tick`** | 1 tick do daemon imediato (para teste). |
| **`zion puppy logs [-f]`** | Logs do container Puppy. |
| **`zion puppy shell`** | Bash dentro do container Puppy. |
| **`zion puppy query --headless --timeout=600 "prompt"`** | Envia prompt headless com timeout. O agente sabe que ninguém observa e deve ir o mais longe possível. |
| **`zion claude-usage`** | Estatísticas de uso Claude (API OAuth / claude.ai). Sem flag = JSON bruto; `--waybar` = JSON para o usage bar consumir; `--refresh` = ignora cache. |

### 2.2 Modo Headless (workers e queries sem supervisão)

Quando o agente roda em **modo headless** (tasks do Puppy ou `zion puppy query --headless`), ele recebe `[HEADLESS MODE]` no prompt e as variáveis:
- **`HEADLESS=1`** — confirma que ninguém está observando a saída
- **`PUPPY_TIMEOUT=<seconds>`** — tempo total antes do processo ser morto

**Comportamento esperado no headless:**
1. **Autonomia total** — não esperar input, não fazer perguntas, ir direto ao trabalho.
2. **Maximize progresso** — vá o mais longe que puder. Não seja conservador.
3. **Gestão de tempo** — reserve os últimos ~30s para salvar estado (memoria.md, contexto.md). Se o timeout estourar sem salvar, **todo o progresso é perdido** (SIGKILL).
4. **Ciclos curtos** — trabalhe em ciclos (executar → salvar parcial → continuar) para nunca perder tudo.
5. **Sem output decorativo** — foque 100% em execução e persistência.

**Config:** `~/.zion` (não `~/.claudio`). Engine padrão, chaves, `OBSIDIAN_PATH`, etc.

**Personalidade (arquivos que o agente carrega):** em **`zion/system/`** (SOUL.md, DIRETRIZES.md, SELF.md) e **`zion/personas/`** (*.persona.md, *.avatar.md). O hook `session-start.sh` injeta conteúdo de `$WS/zion/system/` e persona ativa.

**Nomes de projeto no compose:** sessões = `zion-<slug>` ou `zion-projects` (edit); workers/scheduler = **`puppy-workers`**.

---

## 3. Contexto de execução (obrigatório checar)

### 3.1 Onde estou?

Variável **`IS_CONTAINER`** (definida no bootstrap do container, ex.: `zion/scripts/bootstrap.sh` ou módulos carregados):

| Valor | Significado |
|-------|-------------|
| `IS_CONTAINER=1` | Sessão **dentro** do container `claude-nix-sandbox`. |
| `IS_CONTAINER=0` ou não definido | No **host** NixOS. |

**Regra crítica:** Antes de qualquer comando que altere o sistema (e.g. `sudo`, `systemctl`, `nixos-rebuild`, `nh os switch`), verificar `IS_CONTAINER`. **Dentro do container:** não executar `nixos-rebuild`; orientar o usuário a rodar no host.

### 3.2 Paths no container (workspace)

| Path no container | Conteúdo |
|-------------------|----------|
| **`/zion`** | Pasta `zion/` do repo (engine: bootstrap, scripts, skills, commands, agents). |
| **`/workspace/mnt`** | Projeto que o usuário montou (ex.: `~/projects`). **CWD típico do agente.** |
| **`/workspace/obsidian`** | Vault Obsidian. |
| **`/workspace/nixos`** | Repo NixOS (este repo). **Só montado em `zion edit`** (não na sessão normal `run`/`shell` nem no Puppy). |
| **`/workspace/logs`** | Logs do host (ex.: journal). **Só montado em `zion edit`.** |

### 3.3 Modos de sessão e mounts

| Modo | `/workspace/nixos` | `/workspace/logs` | `/workspace/mnt` |
|------|--------------------|-------------------|------------------|
| `zion` / `zion continue` / `zion new`, `shell`, `resume`, `puppy` | ❌ | ❌ | Projeto do usuário (ex.: ~/projects) |
| **`zion edit`** | ❌ (mnt = nixos) | ✅ (journal ro) | **~/nixos** (este repo) |

Em **`zion edit`**, `/workspace/mnt` aponta para o repo NixOS; é o modo para o agente editar este repo e acessar logs. Usa o mesmo project name (ex.: `zion-projects`) para compartilhar `cursor_config` com outras sessões.

---

## 4. Zion — perspectiva de dentro do container

Esta seção descreve o sistema de containers e o uso do Zion **do ponto de vista de quem está rodando dentro do container** (o agente). Use-a para entender onde você está, o que está montado e como o host orquestra as sessões.

### 4.1 Como o host inicia o container

- O usuário roda no **host** o comando **`zion`** (CLI em `zion/cli/`). O CLI usa **Docker Compose** com o arquivo `zion/cli/docker-compose.zion.yml / docker-compose.puppy.yml`.
- A imagem é **`claude-nix-sandbox`** (build a partir de `zion/cli/Dockerfile.claude`). Todos os serviços usam essa mesma imagem.
- O Compose define **dois serviços**: (1) **sandbox** (`docker-compose.zion.yml`) — sessão interativa (Cursor/Claude/OpenCode); (2) **puppy** (`docker-compose.puppy.yml`) — container persistente com daemon interno (scheduler) + runner de tasks. Ambos usam os mesmos **`x-base-volumes`**.

### 4.2 Como você sabe que está dentro do container

- **Variável de ambiente:** `CLAUDE_ENV=container` (definida no compose em todos os serviços).
- **Bootstrap:** ao iniciar a sessão, o script **`/zion/scripts/bootstrap.sh`** é executado. Ele por sua vez chama o bootstrap do repo NixOS em **`/workspace/nixos/scripts/bootstrap.sh`** ou **`/workspace/mnt/scripts/bootstrap.sh`**. Esse bootstrap carrega **`scripts/bootstrap/modules.sh`**, que define:
  - **`IS_CONTAINER=1`** se `CLAUDE_ENV=container` ou existir `/.dockerenv` ou cgroup indicar docker/container.
  - **`IS_CONTAINER=0`** no host.
  - **`WS=/workspace`** dentro do container; no host, `WS` é a raiz do repo.
- **Regra para o agente:** se `IS_CONTAINER=1`, não rodar `nixos-rebuild`, `systemctl`, etc.; pedir ao usuário executar no host.

### 4.3 Sistema de volumes (o que você enxerga)

Os mounts são definidos no compose como **anchors** reutilizáveis:

- **`x-base-volumes`** — usado por **sandbox** (sessão interativa) e **puppy** (worker persistente).
  - **`/zion`** ← pasta `zion/` do repo (sempre a mesma).
  - **`/workspace/obsidian`** ← vault Obsidian (host: `OBSIDIAN_PATH`).
  - **`/workspace/mnt`** ← projeto do usuário (host: `CLAUDIO_MOUNT`, ex.: `~/projects`). **working_dir** do sandbox é `/workspace/mnt`.
  - **Não** há `/workspace/nixos` nem `/workspace/logs` nesses modos.
  - Além disso: `~/.claude`, `~/.cursor`, skills/commands do zion, hooks do stow do host, `cursor_config` (volume nomeado), `/host/proc/*` e `/host/etc/*` (read-only para observabilidade), `/workspace/.hive-mind`.

- **`zion edit`** (comando `edit`) — não é um serviço separado no compose; é o **mesmo serviço sandbox** rodado com parâmetros diferentes pelo CLI:
  - **`/workspace/mnt`** = **`~/nixos`** (este repo), montado read-write.
  - **Volume extra:** `/var/log/journal` do host → `/workspace/logs/host/journal` (ro).
  - **Project name** fixo `zion-projects` para compartilhar o volume `cursor_config` com a sessão “projeto” e evitar novo login no Cursor.

Resumo prático para o agente:

| Você está em… | `/workspace/mnt` é… | `/workspace/nixos` existe? | `/workspace/logs` existe? |
|---------------|----------------------|----------------------------|----------------------------|
| Sessão normal (`zion run` / `shell`) | Projeto do usuário (ex.: ~/projects) | ❌ | ❌ |
| **`zion edit`** | Repo NixOS (este repo) | ❌ (mnt = nixos) | ✅ (journal) |
| **Puppy** (`zion puppy start`) | Projeto default | ❌ | ❌ |

### 4.4 Serviços do compose e o que fazem

| Serviço | Compose | Uso | Entrypoint / comando |
|---------|---------|-----|----------------------|
| **sandbox** | `docker-compose.zion.yml` | Sessão interativa (Cursor/Claude/OpenCode). Fica com `sleep infinity` até o CLI fazer `exec` com o engine. | Default: `sleep infinity`. O `zion run`/`edit` faz `exec` no container com bash que roda bootstrap + engine. |
| **puppy** | `docker-compose.puppy.yml` | Container persistente com daemon interno (scheduler) + runner de tasks. 12g mem. | `sleep infinity` + daemon via `exec`. Runner usa `--agent-file puppy-runner/agent.md`. |

O **daemon** (`puppy-daemon.sh`) roda dentro do container persistente e lê estado em `/workspace/.ephemeral/scheduler/` (state.json, completed/). O **runner** (`puppy-runner.sh`) usa `$WORKSPACE/obsidian/tasks` (doing/done/cancelled) e o agent file `puppy-runner/agent.md` para processar tasks.

### 4.5 Bootstrap em cadeia (o que roda ao abrir a sessão)

1. O CLI (no host) sobe o container e executa algo como:  
   `. /zion/scripts/bootstrap.sh; cd /workspace/mnt; exec agent` (ou claude/opencode).
2. **`/zion/scripts/bootstrap.sh`** (dentro do container):
   - Cria **`/workspace/host`** como symlink para `/workspace/nixos` (se existir) ou para `/workspace/mnt` (se `mnt` for o repo NixOS, ex.: `zion edit`), para compatibilidade com scripts que esperam “repo do host”.
   - Chama **`scripts/bootstrap.sh`** do repo NixOS (em `/workspace/nixos` ou `/workspace/mnt`). Esse script está no repo em **`scripts/bootstrap.sh`** e faz:
     - Sync de `stow/.claude/*` para `~/.claude/` (agents, commands, hooks, scripts, skills) e configs (settings.json, statusline.sh).
     - Carrega **`scripts/bootstrap/modules.sh`**, que define **IS_CONTAINER**, **WS**, e os módulos do dashboard (header, scheduler, github, rss, etc.).
3. Depois do bootstrap, o shell está em **`/workspace/mnt`** e o engine (Cursor/Claude/OpenCode) inicia. O agente vê **CWD = projeto** (ou repo NixOS em `zion edit`).

### 4.6 Uso prático para o agente

- **Se o seu CWD é um projeto (ex.: ~/projects):** você está em sessão **run/shell**. `/workspace/mnt` = esse projeto. Para editar o repo NixOS ou logs, o usuário precisa abrir uma sessão com **`zion edit`**.
- **Se o seu CWD é este repo (NixOS) e há `/workspace/logs`:** você está em **`zion edit`**. Pode editar este repo e ler logs do host em `/workspace/logs/host/journal`.
- **Skills e comandos:** vêm de **`/zion/skills`**, **`/zion/commands`**, e são expostos em `~/.cursor/skills`, `~/.cursor/rules` e `~/.claude/` via mounts. Hooks vêm do **stow** do host (`stow/.claude/hooks`).
- **Não executar no container:** `nixos-rebuild`, `nh os switch`, `systemctl start/stop` de serviços do host. Usar **`nh os test .`** só para validar build quando o repo NixOS estiver montado (edit); mesmo assim, o apply é no host.

---

## 5. Mapa do repositório

```
.
├── CLAUDE.md              ← Este arquivo (contexto do agente).
├── README.md              ← Visão geral humana (NixOS + Zion).
├── flake.nix              ← Inputs (nixpkgs 25.11, nixos-hardware, chaotic, home-manager, claude-code) e nixosConfigurations.nomad.
├── configuration.nix      ← Registry de módulos (só imports; ativar/desativar aqui).
├── hardware.nix           ← UUIDs de partição (local; costuma estar skip-worktree).
├── makefile               ← Atalhos do host (doctor, run, auto, vault-link, etc.).
├── modules/               ← Módulos NixOS.
│   ├── core/              ← nix, core, services, programs, packages, fonts, shell, kernel, hibernate.
│   ├── greetd.nix         ← Greeter de login.
│   ├── hyprland.nix       ← Compositor (DE ativo).
│   ├── nvidia.nix         ← NVIDIA PRIME (iGPU AMD default).
│   ├── asus.nix           ← ASUS Zephyrus.
│   ├── agents/            ← Agent options (agent-container).
│   ├── obsidian-sync.nix, lmstudio.nix, netdata.nix, work.nix, virt.nix, etc.
├── stow/                  ← Dotfiles (GNU stow → symlink em ~).
│   ├── .config/           ← hypr, waybar, zed, ghostty, rofi, zsh, etc.
│   └── .claude/           ← Hooks, scripts, agents (Claude no host/container).
├── scripts/               ← Scripts do host (bootstrap.sh, puppy-daemon.sh, puppy-runner.sh, puppy-cleanup.sh, api-usage.sh, etc.).
├── zion/                  ← Zion: launcher + container.
│   ├── cli/               ← Zion CLI.
│   │   ├── docker-compose.zion.yml / docker-compose.puppy.yml   ← Compose do container do agente.
│   │   ├── zion                        ← Binário gerado (bashly).
│   │   └── src/
│   │       ├── bashly.yml              ← Definição de comandos e flags.
│   │       └── commands/*.sh            ← continue.sh (default), new_session.sh, resume.sh, shell, edit, puppy_*.sh, etc.
│   ├── scripts/           ← Bootstrap e scripts no container (bootstrap.sh, statusline, etc.).
│   ├── bootstrap.md       ← Instruções para o agente (/load).
│   ├── system/            ← INIT.md e módulos de sistema (loader).
│   ├── commands/          ← Comandos de alto nível (load.md, zion.md).
│   ├── skills/            ← Skills do agente (nixos, monolito, orquestrador, etc.).
│   ├── agents/            ← Personas/agentes (orquestrador, nixos, etc.).
│   ├── personas/          ← Avatar (glados, etc.).
│   └── hooks/             ← Hooks claude-code (session-start, pre-tool-use, etc.).
├── run/                   ← (Pode ser específico do ambiente.)
└── .ephemeral/            ← Estado efêmero (logs, scheduler state; muitas vezes gitignored).
```

- **Dotfiles:** em `stow/.config/` e `stow/.claude/`. Deploy: `stow -d ~/nixos/stow -t ~ .` (não vêm de módulos NixOS).
- **Hyprland (keybinds):** `stow/.config/hypr/` (ex.: `application.conf` — MOD3+c = Zion/Cursor, respeitando `~/.zion`).

---

## 6. Skills do projeto (NixOS e Hyprland)

Para alterações em **NixOS** ou **Hyprland**, o agente deve **ler e seguir** as skills abaixo (no repo estão em `zion/skills/`; no container em `/zion/skills/`).

| Skill | Caminho no repo | Quando usar |
|-------|-----------------|-------------|
| **nixos** | `zion/skills/nixos/SKILL.md` | Adicionar/remover pacotes, mudar opções NixOS, editar módulos (`modules/*.nix`, `configuration.nix`, `flake.nix`), corrigir erros de build. Usa MCP-NixOS e `nh os test .`. |
| **hyprland-config** | `zion/skills/hyprland-config/SKILL.md` | Editar config do Hyprland (hyprland.conf, keybinds, window rules, workspace, waybar, hyprlock, hypridle), instalar/troubleshoot o módulo Hyprland, qualquer arquivo em `stow/.config/hypr/`. |

**Regras Cursor:** As regras em `.cursor/rules/nixos-skill.mdc` e `.cursor/rules/hyprland-skill.mdc` ativam o uso dessas skills quando os arquivos correspondentes estão em contexto (globs: módulos NixOS e config Hyprland/waybar).

---

## 7. NixOS — onde alterar o quê

- **Pacotes de sistema:** `modules/core/packages.nix`.
- **Serviços:** `modules/core/services.nix`.
- **Hyprland (módulo NixOS):** `modules/hyprland.nix`.
- **Keybinds / Waybar / config de DE:** **`stow/.config/`** (stow), não em módulos NixOS.
- **Ativar/desativar módulos:** editar **`configuration.nix`** (lista de `imports`).

**Workflow recomendado:** Usar a skill **nixos** (MCP-NixOS, nh): buscar pacotes/opções, editar o módulo adequado, rodar **`nh os test .`** para validar. **Não** rodar `nixos-rebuild switch` a menos que o usuário peça. Dotfiles: sempre via stow.

---

## 8. Zion CLI — manutenção

- **Regenerar o binário `zion`:** em `zion/cli/` executar **`bashly generate`** (ou no host: **`zion update`**). Fonte: `src/bashly.yml` + `src/commands/*.sh`. **Sempre regenerar após alterar comandos ou bashly.yml** — o arquivo `zion/cli/zion` é gerado e fica desatualizado até o generate.
- **Comportamento padrão:** sem subcomando = **new** (nova sessão). Continuar última sessão = **`zion continue`**. Lista de sessões = **`zion resume`**. Task no kanban = **`zion new-task <nome>`**.
- **Comandos principais:** `continue` (default), `new`, `resume`, `shell`, `start`, `edit`, `puppy` (start/stop/run/status/logs/shell/tick), `logs`, `status`, `new-task`, `build`, `down`, `destroy`, `update`, `init`.
- **`edit`:** único comando que monta este repo em `/workspace/mnt` e ainda monta `/workspace/logs`; arquivo: `host_edit.sh`; project name `zion-projects`.
- **`puppy`:** grupo de subcomandos para o container persistente Puppy. `start` sobe container + daemon; `run <task>` executa 1 task; `tick` roda 1 tick do scheduler.
- **Compose:** `docker-compose.zion.yml` (sessões Zion) e `docker-compose.puppy.yml` (container persistente Puppy com volumes base).

**Renomear ou adicionar comando:** (1) `src/bashly.yml`: alterar `name:`, `default`, `filename`. (2) Criar/renomear em `src/commands/*.sh`. (3) **`bashly generate`**. (4) Atualizar este CLAUDE.md e compose se aplicável.

---

## 9. Bootstrap no container

- **Bootstrap do agente:** `zion/scripts/bootstrap.sh` (no container: `/zion/scripts/bootstrap.sh`).
- **Instruções de comportamento (/load):** `zion/bootstrap.md` (avatar + pergunta; depois INIT e módulos em `/zion/system/`).
- **Bootstrap do repo NixOS:** o script do Zion procura em `/workspace/nixos/scripts/bootstrap.sh` ou `/workspace/mnt/scripts/bootstrap.sh` (em `zion edit`, mnt = nixos). Cria `/workspace/host` como symlink para o repo NixOS quando aplicável.

---

## 10. Decisões rápidas (para o agente)

| Se o usuário pedir… | Ação |
|--------------------|------|
| Adicionar pacote / mudar opção NixOS | Skill **nixos**; editar módulo em `modules/`; `nh os test .`. |
| Mudar keybind / Waybar / config Hyprland | Skill **hyprland-config** (`zion/skills/hyprland-config/SKILL.md`); editar em `stow/.config/hypr/`; deploy com `stow -d ~/nixos/stow -t ~ .`. |
| Alterar comando Zion ou flags | `zion/cli/src/bashly.yml` e `zion/cli/src/commands/*.sh`; depois `bashly generate`. |
| Alterar mounts ou serviços do container | `zion/cli/docker-compose.zion.yml / docker-compose.puppy.yml`. |
| Alterar comportamento do agente (personas, /load) | `zion/bootstrap.md`, `zion/system/INIT.md`, `zion/commands/`, `stow/.claude/`. |
| Rodar nixos-rebuild / systemctl no host | Só se `IS_CONTAINER` não for 1; caso contrário, pedir ao usuário rodar no host. |

### 10.1 Atalho: “quero alterar X” → onde ir

| Quero alterar… | Arquivo ou pasta (na raiz do repo) |
|----------------|------------------------------------|
| Pacote de sistema | `modules/core/packages.nix` |
| Serviço systemd | `modules/core/services.nix` |
| Ativar/desativar módulo | `configuration.nix` (imports) |
| Keybind / regra de janela / Waybar | `stow/.config/hypr/`, `stow/.config/waybar/` |
| Novo comando ou flag do `zion` | `zion/cli/src/bashly.yml` + `zion/cli/src/commands/<nome>.sh` → `bashly generate` |
| Mounts ou serviços do container | `zion/cli/docker-compose.zion.yml / docker-compose.puppy.yml` |
| Comportamento no /load, INIT | `zion/bootstrap.md`, `zion/system/INIT.md` |
| Skill ou comando do agente | `zion/skills/`, `zion/commands/` |
| Hooks (session-start, etc.) | `stow/.claude/hooks/` (host é fonte da verdade) |

### 10.2 Armadilhas comuns

- **Rodar `nixos-rebuild` ou `systemctl` dentro do container** → não faz efeito no host. Sempre checar `IS_CONTAINER`; se 1, pedir ao usuário rodar no host.
- **Achar que `/workspace/nixos` existe em toda sessão** → em `zion edit`, o repo está em **`/workspace/mnt`** (não em `/workspace/nixos`). Em sessão normal e no Puppy, `/workspace/nixos` não existe.
- **Editar keybinds ou Waybar em módulo NixOS** → a fonte da verdade é **`stow/.config/hypr/`** e **`stow/.config/waybar/`**. Deploy com `stow -d ~/nixos/stow -t ~ .`.
- **Esquecer de regenerar o CLI** → após mudar `bashly.yml` ou `commands/*.sh`, rodar **`bashly generate`** em `zion/cli/` (ou `zion update` no host). O arquivo `zion/cli/zion` é **gerado**; sem generate ele continua com comandos/strings antigos (ex. clau-runner, clau-workers).
- **Confundir `zion new` com task** → **`zion new`** = nova sessão; **`zion new-task <nome>`** = criar task no kanban (Puppy).

### 10.3 Se algo falhar

| Situação | O que fazer |
|----------|--------------|
| Build NixOS falha | Rodar `nh os test .` (no host ou com repo montado), ler o erro; usar skill **nixos** e tabela de módulos (seção 7). |
| Sessão/container não sobe ou monta errado | Ver `zion/cli/docker-compose.zion.yml / docker-compose.puppy.yml` (volumes, entrypoint); seção 4 (Zion — perspectiva container). |
| Keybind ou Waybar não aplica | Skill **hyprland-config**; validar camadas (módulo → dotfiles → stow); `hyprls lint` no config. |
| Comando `zion` não aparece ou está desatualizado | Regenerar: `cd zion/cli && bashly generate`; ou no host: `zion update`. |

---

## 11. O que o agente pode alterar a pedido

- Qualquer arquivo deste repo: módulos NixOS, stow, scripts, **zion/**.
- Zion CLI: `zion/cli/src/`, `bashly.yml`, `docker-compose.zion.yml / docker-compose.puppy.yml`.
- Comportamento do agente: `stow/.claude/`, `zion/` (bootstrap, system, commands, skills, agents, hooks).

Validação: mudanças em módulos NixOS → skill **nixos** + `nh os test .`. Dotfiles → stow. Hyprland/Cursor → arquivos em `stow/.config/` e em `zion/`.

---

## 12. Referências rápidas

| Tema | Onde |
|------|------|
| Comportamento do agente (personas, tasks) | `zion/bootstrap.md`, `zion/system/INIT.md`, equivalente em stow/obsidian |
| Zion CLI (comandos, compose) | `zion/cli/README.md`, `zion/cli/docker-compose.zion.yml / docker-compose.puppy.yml`, `zion/cli/src/bashly.yml` |
| NixOS (packages, options, módulos) | Seção **6** (Skills) + `zion/skills/nixos/SKILL.md` + `modules/` |
| Dotfiles / Hyprland | Seção **6** (Skills) + `zion/skills/hyprland-config/SKILL.md` + `stow/.config/` |
| Boot do agente (/load, paths) | `zion/bootstrap.md`, `zion/commands/load.md` |
| Infra (MCP, Git) | MCP: nixos, Atlassian (ro), Notion (ro). Git: GH_TOKEN read-only; identidade de commit pode vir do host. |
