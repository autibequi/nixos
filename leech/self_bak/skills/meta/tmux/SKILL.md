---
name: meta/tty
description: "Controle do shell do host via tmux socket — como pedir acesso, conectar, executar comandos, capturar output, diagnóstico de sistema. Inclui aviso de segurança e lições aprendidas."
---

# meta:tty — Controle do Host via Tmux

Acesso ao shell do host através do socket tmux compartilhado.

```
container (eu, root)                   host (Pedro, uid 1000)
     │                                      │
     │  tmux send-keys → socket  ──────→   │  leech tmux serve
     │  tmux capture-pane ←─────────────   │  (sessão ativa, bloqueada 1 janela)
```

Socket: `/run/user/1000/zion-tmux/tmux.sock` | Sessão: `main`

---

## Como pedir acesso ao host

> "Para isso eu precisaria de acesso ao seu terminal. Você pode rodar `leech tmux serve` em um terminal no host e me avisar? **Atenção: isso me dá controle direto do seu shell — qualquer comando que eu enviar roda com suas permissões. Feche a sessão quando terminar.**"

**Sempre avisar sobre o risco antes de pedir.** Nunca solicitar acesso silenciosamente.

---

## Quando oferecer proativamente

- Diagnosticar problema de CPU, GPU, memória, processos lentos no host
- Aplicar config NixOS (`nixos-rebuild switch`)
- Recarregar Hyprland, Waybar, serviços do desktop
- Matar processo específico no host
- Qualquer binário que só existe no host

**Sempre com o aviso de segurança.** O usuário decide se abre ou não.

---

## Verificar disponibilidade

```bash
nix-shell -p tmux --run \
  "tmux -S /run/user/1000/zion-tmux/tmux.sock list-sessions" 2>/dev/null \
  | grep -v "^copying\|^these\|^warning\|fetched\|/nix/store"
```

- `main: 1 windows ... (attached)` → canal aberto
- `no server running` → pedir ao Pedro: `leech tmux serve`

---

## Executar comando no host

```bash
# Enviar
nix-shell -p tmux --run \
  "tmux -S /run/user/1000/zion-tmux/tmux.sock send-keys -t main 'COMANDO' Enter" \
  2>/dev/null | grep -v "^copying\|^these\|^warning\|fetched\|/nix/store"

# Capturar (aguardar antes: sleep 1-3 conforme complexidade)
sleep 2
nix-shell -p tmux --run \
  "tmux -S /run/user/1000/zion-tmux/tmux.sock capture-pane -t main -p -S -80" \
  2>/dev/null | grep -v "^copying\|^these\|^warning\|fetched\|/nix/store"
```

**Antes de enviar um comando novo**, mandar um Enter vazio para limpar qualquer lixo no buffer:
```bash
nix-shell -p tmux --run \
  "tmux -S /run/user/1000/zion-tmux/tmux.sock send-keys -t main '' Enter" 2>/dev/null
sleep 0.3
```

---

## Controle de panes

```bash
SOCK="/run/user/1000/zion-tmux/tmux.sock"

# Split vertical (cima/baixo)
nix-shell -p tmux --run "tmux -S $SOCK split-window -v -t main"

# Split horizontal (esquerda/direita)
nix-shell -p tmux --run "tmux -S $SOCK split-window -h -t main"

# Matar pane (0 = primeiro, 1 = segundo)
nix-shell -p tmux --run "tmux -S $SOCK kill-pane -t main.1"

# Mandar comando para pane específico
nix-shell -p tmux --run "tmux -S $SOCK send-keys -t main.0 'COMANDO' Enter"
```

---

## Diagnóstico de sistema

```bash
# Load geral
send: 'cat /proc/loadavg'
# Retorno: "load1 load5 load15 procs/total pid"
# Ryzen 9 7940HS tem 16 threads — load > 8 já é alto, > 12 preocupante

# Memória
send: 'free -h'

# Top processos por CPU (procs é o alias de ps no host)
send: 'procs --sortd cpu | head -15'

# GPU NVIDIA
send: 'nvidia-smi'

# GPU AMD
send: 'cat /sys/class/hwmon/hwmon*/temp*_input'
# Valores em milli-Celsius (55000 = 55°C)

# Processos suspeitos recorrentes
# ob sync --continuous → 27-35% CPU constante (Obsidian sync)
# pkill -f "ob sync"  → mata se necessário
```

---

## Aliases que quebram no host

O shell do Pedro tem aliases que diferem do Linux padrão:

| Comando padrão | Alias no host | Alternativa |
|---|---|---|
| `ps aux --sort` | `procs` (diferente) | `procs --sortd cpu` |
| `grep -E` | `rg` (ripgrep) | `/run/current-system/sw/bin/grep` ou `rg -e` |
| `jq` | `jaq` em alguns contextos | `jq` direto funciona |

---

## Exemplos reais

```bash
# Identificar lentidão
send: 'procs --sortd cpu | head -12'
send: 'cat /proc/loadavg'

# NixOS — aguardar 60-120s antes de capturar
send: 'sudo nixos-rebuild switch 2>&1 | tail -30'

# Desktop
send: 'hyprctl reload'
send: 'systemctl --user restart waybar'
send: 'pkill -f "ob sync"'

# Hardware
send: 'fastfetch'
send: 'nvidia-smi'
```

---

## Segurança

O socket tem restrições ativas via hooks tmux:
- `after-new-window` → `kill-window` (sem janelas ocultas)
- `after-new-session` → `kill-session` (sem sessões paralelas escondidas)

Ainda assim: **o pane ativo é irrestrito**. `sudo` roda com permissões do Pedro.
- Nunca enviar comandos destrutivos sem confirmação explícita
- Nunca `rm -rf`, `dd`, `mkfs` ou similares sem o Pedro pedir e confirmar
- Preferir comandos read-only para diagnóstico; write só quando necessário

---

## Lições aprendidas (troubleshooting desta implementação)

### Bind mount de arquivo fica stale
Docker bind-mount de **arquivo** (`/run/user/1000/zion-tmux.sock`) fica preso no inode antigo quando o socket é deletado e recriado. **Solução: montar um diretório** (`/run/user/1000/zion-tmux/`). O docker-compose monta o dir; o socket vive dentro.

### Container roda como root, socket como uid 1000
Socket criado pelo `leech tmux serve` (usuário `pedrinho`, uid 1000) com `srw-------` → root do container não acessa. **Solução:** `serve()` faz `chmod 777` no diretório e `chmod 666` no socket após criar a sessão.

### tmux não está no PATH do NixOS por default
`Command::new("tmux")` falha com ENOENT. **Solução:** `tmux_bin()` procura em `/run/current-system/sw/bin/tmux` primeiro. No container: `nix-shell -p tmux --run "tmux ..."` ou `leech tmux install` para instalar permanentemente.

### Container precisa ser reiniciado após mudança no compose
Se o mount mudou (arquivo → diretório), o container precisa de `vennon claude stop && yaa` para aplicar. Não adianta só recriar o socket.

### nix-shell overhead
Primeira execução de `nix-shell -p tmux` baixa ~65 MiB do cache.nixos.org — demora ~10-30s. Depois fica em cache no nix store do container. `leech tmux install` instala permanentemente no nix profile e elimina esse overhead.

### Buffer de pane pode ter lixo pendente
Se o pane tiver texto parcial digitado (input incompleto), o próximo `send-keys` concatena com ele, gerando `asdascat /proc/loadavg`. **Solução:** sempre mandar um Enter vazio antes de enviar o comando real.

---

## Limitações

- Delay fixo no capture — comandos longos precisam de `sleep` maior + `capture` extra
- Comandos interativos (vim, btop, top) não funcionam via send-keys — travam o pane
- `nix-shell -p tmux` é lento na primeira chamada da sessão do container
- O canal fecha quando Pedro sai do `leech tmux serve` — server não persiste (por design)
