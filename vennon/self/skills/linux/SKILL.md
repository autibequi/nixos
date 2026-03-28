---
name: linux
description: "Auto-ativar quando: host_attached=1, usuario menciona NixOS, Hyprland, Waybar, dotfiles, stow, nix, modulos, pacotes do sistema, keybinds, window rules, configuracao do compositor, OU quando reclama de problema no computador (lento, travando, crash, rede, disco, processo morto, boot, etc.). Tambem cobre healthcheck de container, disco, load, workspace, git e tasks."
---

# linux — Sistema Linux + Diagnostico

Skill unificada: NixOS, Hyprland, Waybar, dotfiles, debug autonomo do host, e healthcheck do sistema.

---

## DEBUG DE HOST — Investigacao Autonoma

Quando o Pedro reclamar de qualquer problema no computador (lento, travando, crash, rede, disco, processo morto, login quebrado, etc.):

**Regra principal: investigar primeiro, perguntar o minimo.**
Usar os mounts disponiveis para chegar com diagnostico, nao com perguntas.

### Mounts disponiveis para debug

```
/workspace/logs/host/
  journal/          -> journald persistente  -> journalctl -D /workspace/logs/host/journal
  journal-runtime/  -> journald boot atual   -> journalctl -D /workspace/logs/host/journal-runtime
  var-log/          -> syslog, auth.log, Xorg.log, kern.log, etc.
  coredump/         -> crash dumps (coredumpctl --directory=... ou ler diretamente)

/host/sys/class/
  hwmon/            -> temperaturas, tensoes, RPM fans (cat thermal_zone*/temp)
  thermal/          -> thermal zones, throttling
  net/              -> bytes/erros por interface (cat eth0/statistics/*)

/host/sys/block/    -> I/O queue por disco (cat sda/stat, sda/queue/*)

/host/proc/         -> meminfo, cpuinfo, loadavg, uptime, vmstat, diskstats (arquivos individuais)
```

**Tambem disponivel** (network_mode: host):
- `ss -tlnp` — sockets do host
- `ip a`, `ip route` — interfaces do host
- `ping`, `curl` — conectividade do host

**NAO disponivel sem ajuda do Pedro:**
- `dmesg` live (pedir: `dmesg -T | tail -100`)
- `strace`/`perf` em processos host (CAP_SYS_PTRACE e CAP_PERFMON dropados)
- `top`/`htop` do host (PID namespace isolado — pedir output se necessario)

### Metodologia de investigacao

```
1. Entender o sintoma pela descricao do Pedro
2. Classificar: crash / lentidao / rede / disco / memoria / servico
3. Ir direto ao source correto (tabela abaixo)
4. Ler, correlacionar, formar hipotese
5. Apresentar diagnostico + causa provavel + fix proposto
   -> Se fix for NixOS: editar modulo + pedir `deck os switch`
   -> Se fix for config: editar dotfile + `deck stow`
   -> Se precisar de info que nao tenho: pedir UMA coisa especifica
```

### Sources por tipo de problema

| Sintoma | Onde olhar primeiro |
|---------|---------------------|
| Crash de processo / app | `/workspace/logs/host/coredump/` + `journalctl -D journal -b -1` |
| Servico nao sobe | `journalctl -D journal -u <servico> -n 100` |
| Boot com erro | `journalctl -D journal -b -1 -p err` |
| Kernel panic / OOM | `journalctl -D journal -k \| grep -E "oom\|killed\|panic"` |
| Lentidao geral | `/host/proc/loadavg` + `/host/proc/meminfo` + `/host/proc/vmstat` |
| CPU alta / throttling | `/host/sys/class/thermal/` + `/host/sys/class/hwmon/` |
| Disco cheio / lento | `/host/sys/block/*/stat` + `/workspace/logs/host/var-log/syslog` |
| Rede quebrada | `ss -tlnp` + `ip a` + `/host/sys/class/net/*/statistics/` |
| Temperatura / fan | `/host/sys/class/hwmon/hwmon*/temp*_input` (valor em milligraus) |
| Auth / sudo / SSH | `/workspace/logs/host/var-log/auth.log` |
| Xorg / Wayland / GPU | `/workspace/logs/host/var-log/` + `journalctl -D journal -u sddm` |

### Comandos journalctl uteis (sempre usar -D)

```bash
# Boot anterior completo com erros
journalctl -D /workspace/logs/host/journal -b -1 -p err --no-pager

# Ultimas 2 horas
journalctl -D /workspace/logs/host/journal --since "2h ago" --no-pager

# Servico especifico
journalctl -D /workspace/logs/host/journal -u nome-servico -n 200 --no-pager

# Kernel (hardware, driver, OOM)
journalctl -D /workspace/logs/host/journal -k --no-pager | grep -E "error|fail|warn|oom|killed"

# Crash dump listing
ls -lh /workspace/logs/host/coredump/
```

### Leitura de hardware (sys)

```bash
# Temperaturas (em milligraus Celsius -> dividir por 1000)
for f in /host/sys/class/hwmon/hwmon*/temp*_input; do
  label=$(cat "${f%_input}_label" 2>/dev/null || echo "$f")
  echo "$label: $(( $(cat $f) / 1000 ))C"
done

# Thermal zones (throttling)
for z in /host/sys/class/thermal/thermal_zone*; do
  echo "$(cat $z/type): $(cat $z/temp)mC — $(cat $z/policy 2>/dev/null)"
done

# I/O de disco
cat /host/sys/block/sda/stat   # ou nvme0n1

# Net stats por interface
cat /host/sys/class/net/enp*/statistics/rx_bytes
cat /host/sys/class/net/enp*/statistics/tx_bytes
```

### Fix via NixOS (host_attached=1)

Quando o diagnostico indica fix de configuracao do sistema:
1. Editar o modulo correto em `/workspace/home/` (tabela de modulos abaixo)
2. Dizer ao Pedro: **"editei X, rode `deck os switch` para aplicar"**
3. Se quiser testar antes sem persistir: pedir `nh os test .`

**Nunca rodar `nh os switch` ou `nixos-rebuild` dentro do container.**

---

## Healthcheck — Diagnostico Padronizado

Procedimentos padronizados de health check. Fonte da verdade para thresholds e alertas.

### Container e ferramentas

```bash
# Verificar ferramentas essenciais
for tool in awk sed make node go ffmpeg ps free; do
  command -v $tool >/dev/null 2>&1 && echo "OK: $tool" || echo "MISSING: $tool"
done

# Disco
df -h / | tail -1

# Load
uptime

# Nix daemon lock
ls -la /nix/var/nix/db/big-lock 2>/dev/null
```

### Thresholds

| Metrica | Warning | Critico | Acao |
|---------|---------|---------|------|
| Disco | > 80% | > 95% | Alerta no inbox |
| Ferramentas ausentes | > 2 | — | Escalar |
| Load | > 4.0 | > 8.0 | Warning no feed |

### Workspace e git

```bash
# Repos sujos
cd /workspace/home && git status --porcelain | head -5

# Agentes orfaos em bedrooms/_working/
ls /workspace/obsidian/bedrooms/_working/*.md 2>/dev/null
```

### Tasks e agentes

- Cards em DOING/ sem lock ativo -> orfaos, reportar
- Cards em bedrooms/_waiting/ com horario > 2h passado -> stale, reportar
- agent.md sem contractor folder no Obsidian -> inconsistencia

### Cleanup — thresholds de limpeza

**Fonte da verdade:** `self/superego/obsidian.md` (secoes sobre archive e limpeza).
Consultar la para thresholds atualizados — nao duplicar aqui.

### Formato de reporte

```markdown
[HH:MM] [keeper] HEALTH: disco XX%, N ferramentas ok, N issues
```

Se critico -> criar `/workspace/obsidian/inbox/ALERTA_keeper_<tema>.md`

---

## Passo 0 — Plan Mode Obrigatorio (mudancas de config)

Chamar `EnterPlanMode` imediatamente antes de qualquer acao.
Sair apenas apos aprovacao explicita do dev.
Excecao: se invocado dentro de fluxo Orquestrador ja aprovado, pular.

---

## Workflow NixOS

```
User requests a change
  -> Search package/option (MCP-NixOS)
  -> Identify correct module to edit
  -> Edit module
  -> nh os test .
  -> Pass? -> Done
  -> Fail? -> Classify error -> Fix -> nh os test . (loop, max 3 auto-retries)
```

## Step 1: Search com MCP-NixOS

```
mcp__nixos__nix(action: "search", type: "packages", query: "firefox")
mcp__nixos__nix(action: "search", type: "options", query: "services.openssh")
mcp__nixos__nix(action: "info", type: "packages", query: "nixpkgs#firefox")
mcp__nixos__nix(action: "info", type: "options", query: "services.openssh.enable")
mcp__nixos__nix(action: "search", type: "home-manager-options", query: "programs.git")
```

Se MCP indisponivel: `nh search <query>`.

## Step 2: Modulo correto

| Mudanca | Arquivo |
|---------|---------|
| Pacote de sistema | `modules/core/packages.nix` |
| Programa com opcoes | `modules/core/programs.nix` |
| Servico systemd | `modules/core/services.nix` |
| Fonte | `modules/core/fonts.nix` |
| Shell alias / env / starship | `modules/core/shell.nix` |
| Kernel / sysctl | `modules/core/kernel.nix` |
| Nix settings | `modules/core/nix.nix` |
| Hibernate | `modules/core/hibernate.nix` |
| NVIDIA | `modules/nvidia.nix` |
| ASUS hardware | `modules/asus.nix` |
| Bluetooth | `modules/bluetooth.nix` |
| Hyprland compositor | `modules/hyprland.nix` |
| Steam / gaming | `modules/steam.nix` |
| AI tools | `modules/ai.nix` |
| Containers (podman) | `modules/podman.nix` |
| Virtualizacao | `modules/virt.nix` |
| Work tools | `modules/work.nix` |
| Login greeter | `modules/greetd.nix` |
| Boot splash | `modules/plymouth.nix` |
| Logitech mouse | `modules/logiops.nix` |
| **Keybinds / windowrules / Waybar** | `stow/.config/hypr/` -> `deck stow` |

**Pacotes unstable:** usar `unstable.pkgs.<name>` — disponivel em todos os modulos via `specialArgs`.

## Step 3: Build e Test

```bash
nh os test .
```

Ativa temporariamente (nao persiste). **Nunca rodar `nh os switch .`** sem o user pedir explicitamente.

## Step 4: Error Handling

### Auto-fix (max 3 tentativas):

| Erro | Fix |
|------|-----|
| `undefined variable 'pkgName'` | Nome errado — buscar no MCP |
| `attribute 'x' missing` | Path errado — verificar com MCP info |
| `syntax error` | Nix syntax — corrigir |
| `option 'x' does not exist` | Opcao errada — buscar MCP |
| `duplicate definition` | Remover duplicata |
| `not available on hostPlatform` | Remover ou buscar alternativa |

### Pedir confirmacao:

| Erro | Acao |
|------|------|
| `collision between` | Mostrar ambos, perguntar qual manter |
| `infinite recursion` | Explicar ciclo, propor fix |
| `assertion failed` | Explicar condicao, propor fix |
| Erro desconhecido | Mostrar completo, pedir orientacao |

---

## Hyprland

Dois layers distintos:

```
Layer 1: NixOS Module (modules/hyprland.nix)
  -> pacotes, UWSM, servicos systemd
Layer 2: Dotfile Configs (stow/.config/hypr/*.conf)
  -> keybinds, windowrules, waybar, animacoes
```

**Regra de ouro:**
- Instalar/habilitar Hyprland, plugins -> `modules/hyprland.nix` -> `nh os test .`
- Keybinds, windowrules, Waybar, animacoes -> `stow/.config/hypr/` -> `deck stow` -> `hyprctl reload`

Nunca editar `~/.config/hypr/` diretamente — e symlink. Fonte: `stow/.config/hypr/`.

### Arquivos de dotfile

| Arquivo | Conteudo |
|---------|----------|
| `hyprland.conf` | Config principal |
| `hypridle.conf` | Idle / sleep |
| `hyprlock.conf` | Lock screen |
| `workspace.conf` | Layout de workspaces |
| `application.conf` | Window rules por app |
| `windowrules.conf` | Window rules gerais |
| `systemtools.conf` | Atalhos de sistema |

### Ciclo dotfiles

```bash
# 1. Editar stow/.config/hypr/
# 2. Deploy
deck stow
# 3. Recarregar
hyprctl reload
```

### Troubleshooting

| Problema | Diagnostico |
|----------|-------------|
| Sessao nao aparece no login | `systemctl status uwsm` |
| Crash imediato | `journalctl -xe` + `hyprls lint stow/.config/hypr/hyprland.conf` |
| Waybar/hypridle nao sobem | `journalctl -u waybar -n 50` |
| Tela preta | Verificar `source =` no hyprland.conf |

---

## Quick Reference

| Task | Comando |
|------|---------|
| Test build | `nh os test .` |
| Aplicar permanentemente | `nh os switch .` (so se user pedir) |
| Buscar pacotes | `mcp__nixos__nix search packages <query>` |
| Buscar opcoes | `mcp__nixos__nix search options <query>` |
| Deploy dotfiles | `deck stow` |
| Reload Hyprland | `hyprctl reload` |
| Logs Hyprland | `journalctl -xe --grep=hypr` |
| Healthcheck rapido | `df -h / && uptime && git -C /workspace/home status --porcelain` |
