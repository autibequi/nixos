# CLAUDE.md — Repo NixOS + Zion (launcher/container)

Documentação para **manutenção** deste repositório: configuração Linux NixOS no host, **Zion** (launcher + container onde o agente roda) e Zion CLI.

**Copie este conteúdo para `~/nixos/CLAUDE.md`** (raiz do repo NixOS no host).

---

## O que é o quê

| Conceito | O que é |
|----------|--------|
| **Este repo** | Configuração NixOS do host: `flake.nix`, `modules/`, `stow/`, `scripts/`, `zion/`. Tudo que está aqui roda no **host** do container. |
| **Zion** | Código-fonte do "launcher" que o usuário fez para o agente: CLI (`zion`), container Docker, bootstrap, skills. Fica em **`zion/`** dentro deste repo. |
| **Zion CLI** | Comando `zion` (bashly): `zion run`, `zion edit`, `zion worker`, etc. Código em **`zion/cli/`**. |
| **Container** | Imagem `claude-nix-sandbox` (Docker); o agente roda dentro dele. Compose: **`zion/cli/docker-compose.claude.yml`**. |

Ou seja: **projeto inteiro = config NixOS no host**; **Zion = launcher + container** (pasta `zion/`).

---

## Infraestrutura

- **Container:** `claude-nix-sandbox` (Dockerfile em `zion/cli/Dockerfile.claude`, compose em `zion/cli/docker-compose.claude.yml`).
- **Base:** Nix no container; host NixOS.
- **MCP:** nixos, Atlassian (read-only), Notion (read-only).
- **Git:** `GH_TOKEN` para operações read-only; identidade de commit no container pode vir do host / histórico.

---

## Onde estou (container)

**Booleano:** `IS_CONTAINER` (definido em `bootstrap/modules.sh` ou equivalente).

| Valor | Contexto |
|-------|----------|
| `IS_CONTAINER=1` | Dentro do container `claude-nix-sandbox` |
| `IS_CONTAINER=0` | No host NixOS |

**Regra:** antes de comandos que alteram o sistema (sudo, systemctl, nixos-rebuild), checar `IS_CONTAINER`. Dentro do container: não rodar nixos-rebuild; pedir ao usuário rodar no host.

---

## Mounts no container (o que mudou)

**Sessão normal** (`zion`, `zion run`, `zion shell`, workers):

- **`/zion`** — pasta `zion/` do repo (engine, bootstrap, scripts do agente).
- **`/workspace/obsidian`** — vault Obsidian.
- **`/workspace/mnt`** — projeto que o usuário passou (ex.: `~/projects`); **cwd** do agente.
- **Não** há mount de `/workspace/nixos` nem `/workspace/logs` na sessão normal.

**`zion edit`** (editar este repo + logs no container):

- **`/workspace/mnt`** = **`~/nixos`** (este repo).
- **`/workspace/logs/host/journal`** = `/var/log/journal` (ro).
- Usa o **mesmo project name** que `zion` com ~/projects (`clau-projects`) para compartilhar o volume `cursor_config` e não pedir login de novo no Cursor.

**Scheduler** (container em background):

- Tem **`/workspace/nixos`** (repo NixOS) para tasks/scripts; sem logs.

Resumo:

| Modo | `/workspace/nixos` | `/workspace/logs` | `/workspace/mnt` |
|------|--------------------|-------------------|------------------|
| run / shell / start / resume | ❌ | ❌ | Projeto (ex.: ~/projects) |
| **zion edit** | ❌ | ✅ (journal) | ~/nixos |
| scheduler | ✅ | ❌ | (default) |

---

## Estrutura do repo (host)

```
~/nixos/                          ← este repo (config NixOS)
├── CLAUDE.md                     ← este arquivo
├── flake.nix
├── configuration.nix
├── modules/                      ← módulos NixOS (packages, services, hyprland, etc.)
├── stow/                         ← dotfiles (Hyprland, Waybar, Zed, .claude, etc.)
│   ├── .config/                  ← hypr, waybar, etc. (stow -d ~/nixos/stow -t ~ .)
│   └── .claude/                  ← hooks, scripts, agents (Claude no host/container)
├── scripts/                      ← scripts do host (bootstrap.sh, kanban-sync, etc.)
├── zion/                         ← Zion: launcher + container
│   ├── cli/                      ← Zion CLI (bashly, docker-compose, comandos)
│   │   ├── docker-compose.claude.yml
│   │   ├── zion                  ← binário gerado (bashly)
│   │   └── src/commands/         ← comandos (run.sh, host_edit.sh, etc.)
│   ├── scripts/                  ← bootstrap do container (bootstrap.sh, etc.)
│   ├── bootstrap.md
│   └── ...
└── ...
```

- **Dotfiles:** em `stow/.config/`; deploy com `stow -d ~/nixos/stow -t ~ .` (não são gerenciados por módulos NixOS).
- **Hyprland / atalhos:** `stow/.config/hypr/` (ex.: `application.conf` — MOD3+p = `zion` / Cursor).

---

## Zion CLI — manutenção

- **Regenerar CLI:** na pasta `zion/cli/`, rodar `bashly generate` (ou `zion update` no host); isso regera o script `zion` a partir de `src/bashly.yml` e `src/commands/*.sh`.
- **Comandos principais:** `run`, `shell`, `resume`, `start`, `edit`, `worker`, `scheduler`, `logs`, etc.
- **Edit:** único comando que monta este repo em `/workspace/mnt` e ainda monta `/workspace/logs`; usa project `clau-projects` para compartilhar login do Cursor. **Nome do comando é `edit`** (não host-edit).
- **Compose:** volumes base em `x-base-volumes`; scheduler usa `x-scheduler-volumes` (base + nixos). Não colocar nixos/logs nos volumes base para não expor este repo em toda sessão.

**Renomear um comando CLI:** (1) Em `src/bashly.yml`, alterar `name:` do comando. (2) Em `src/commands/<arquivo>.sh`, atualizar mensagens/echo que citem o nome antigo. (3) Regenerar com `bashly generate` no host; se bashly não estiver disponível (ex.: no container), editar manualmente o binário `zion`: trocar o `case` (ex.: `host-edit)` → `edit)`), `action="..."`, funções `zion_<antigo>_command` / `zion_<antigo>_parse_requirements` → `zion_<novo>_*`, help `printf` e todos os textos user-facing. (4) Atualizar comentários em `docker-compose.claude.yml` e **este CLAUDE.md** para refletir o novo nome.

---

## NixOS — manutenção (skills)

Para alterar **packages, options, módulos NixOS** neste repo:

1. **Usar a skill `nixos`** (NixOS Configuration Management): buscar pacotes/opções via MCP-NixOS, editar o módulo certo, rodar `nh os test .` e iterar em erros.
2. **Módulos comuns:**  
   - Pacotes sistema → `modules/core/packages.nix`  
   - Serviços → `modules/core/services.nix`  
   - Hyprland → `modules/hyprland.nix`  
   - Dotfiles (keybinds, waybar, etc.) → **`stow/.config/`** (stow, não NixOS).
3. **Testar:** `nh os test .` (ativação temporária). **Não** rodar `nixos-rebuild switch` a menos que o usuário peça.
4. **Deploy dotfiles:** `stow -d ~/nixos/stow -t ~ .`

Referência completa: skill **nixos** (MCP-NixOS, nh, tabela de módulos).

---

## Hyprland (keybinds / dotfiles)

- Config em **`stow/.config/hypr/`** (ex.: `application.conf`, `hyprland.conf`).
- **MOD3+p** → abre só `zion` (respeita `~/.zion`, ex.: engine=cursor).
- `$claudinho` e `$claudio` = apenas `zion` (sem `zion start`), para respeitar `.zion`.

---

## Bootstrap no container

- **Arquivo:** `zion/scripts/bootstrap.sh` (dentro do container é também `/zion/scripts/bootstrap.sh`).
- Procura o bootstrap do repo NixOS em **`/workspace/nixos/scripts/bootstrap.sh`** ou **`/workspace/mnt/scripts/bootstrap.sh`** (zion edit: mnt = nixos).
- Cria `/workspace/host` → symlink para `/workspace/nixos` ou `/workspace/mnt` quando for o repo NixOS.

---

## O que você pode alterar a pedido

- Arquivos deste repo (módulos NixOS, stow, scripts, **zion/**).
- Zion CLI: comandos em `zion/cli/src/commands/`, `bashly.yml`, `docker-compose.claude.yml`.
- Comportamento do agente: `stow/.claude/`, `zion/` (bootstrap, personas, etc.).

Sempre que fizer mudanças em NixOS (módulos), usar a skill **nixos** e validar com `nh os test .`. Dotfiles via stow; Cursor/Hyprland via arquivos em `stow/.config/`.

---

## Referências rápidas

| Tema | Onde |
|------|------|
| Comportamento do agente (personas, tasks) | `claudinho/CLAUDE.md` ou equivalente em stow/obsidian |
| Zion CLI (comandos, compose) | `zion/cli/README.md`, `zion/cli/docker-compose.claude.yml` |
| NixOS (packages, options, módulos) | Skill **nixos** + `modules/` |
| Dotfiles / Hyprland | `stow/.config/` |
| Boot do agente (paths, /load) | Skill **load** ou `zion/bootstrap.md` |
