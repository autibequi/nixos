---
name: meta/tmux
description: "Controle do shell do host via tmux socket — como pedir acesso, conectar, executar comandos, capturar output. Inclui aviso de segurança obrigatório ao oferecer acesso."
---

# meta/tmux — Controle do Host via Tmux

Acesso ao shell do host através do socket tmux compartilhado.

```
container (eu)                         host (Pedro)
     │                                      │
     │  tmux send-keys → socket  ──────→   │  leech tmux serve
     │  tmux capture-pane ←─────────────   │  (sessão ativa)
```

Socket: `/run/user/1000/zion-tmux/tmux.sock` | Sessão: `main`

---

## Como pedir acesso ao host

Quando precisar executar algo no host, pedir assim:

> "Para isso eu precisaria de acesso ao seu terminal. Você pode rodar `leech tmux serve` em um terminal no host e me avisar? **Atenção: isso me dá controle direto do seu shell — qualquer comando que eu enviar roda com suas permissões. Feche a sessão quando terminar.**"

**Sempre avisar sobre o risco antes de pedir.** Não pedir silenciosamente.

---

## Quando oferecer proativamente

Oferecer acesso tmux quando:
- Usuário está tentando diagnosticar problema no host (GPU, memória, processos)
- Usuário precisa aplicar config NixOS (`nixos-rebuild switch`)
- Usuário quer recarregar Hyprland, Waybar, etc.
- Usuário quer matar processo específico no host
- Qualquer binário que só existe no host (não no container)

**Sempre com o aviso de segurança.** Nunca solicitar acesso sem avisar o risco.

---

## Verificar se está disponível

```bash
# Dentro do container — via nix-shell (tmux não está instalado nativamente)
nix-shell -p tmux --run \
  "tmux -S /run/user/1000/zion-tmux/tmux.sock list-sessions" 2>/dev/null \
  | grep -v "^copying\|^these\|^warning\|fetched\|/nix/store"
```

Se retornar `main: 1 windows ... (attached)` → canal aberto, pode usar.
Se retornar `no server running` → pedir ao usuário `leech tmux serve`.

---

## Executar comando no host

```bash
# Enviar comando
nix-shell -p tmux --run \
  "tmux -S /run/user/1000/zion-tmux/tmux.sock send-keys -t main 'COMANDO' Enter" \
  2>/dev/null | grep -v "^copying\|^these\|^warning\|fetched\|/nix/store"

# Aguardar e capturar output
sleep 2
nix-shell -p tmux --run \
  "tmux -S /run/user/1000/zion-tmux/tmux.sock capture-pane -t main -p -S -50" \
  2>/dev/null | grep -v "^copying\|^these\|^warning\|fetched\|/nix/store"
```

Para comandos longos (nixos-rebuild, etc.) aumentar o `sleep` ou capturar novamente.

---

## Controle de panes

```bash
SOCK="tmux -S /run/user/1000/zion-tmux/tmux.sock"

# Split vertical
nix-shell -p tmux --run "$SOCK split-window -v -t main"

# Split horizontal
nix-shell -p tmux --run "$SOCK split-window -h -t main"

# Matar pane específico (0 = cima/esquerda, 1 = baixo/direita)
nix-shell -p tmux --run "$SOCK kill-pane -t main.1"

# Mandar comando para pane específico
nix-shell -p tmux --run "$SOCK send-keys -t main.0 'COMANDO' Enter"
```

---

## Exemplos reais

```bash
# Diagnóstico de sistema
send: 'fastfetch'
send: 'nvidia-smi'
send: 'free -h'
send: 'ps aux --sort=-%cpu | head -10'

# NixOS
send: 'sudo nixos-rebuild switch'   # aguardar ~60s antes de capturar

# Hyprland / desktop
send: 'hyprctl reload'
send: 'systemctl --user restart waybar'
send: 'pkill -f "ob sync"'
```

---

## Segurança

O socket tem restrições ativas via hooks tmux:
- `after-new-window` → kill-window (sem janelas ocultas)
- `after-new-session` → kill-session (sem sessões paralelas escondidas)

Ainda assim, **o acesso é irrestrito dentro do pane ativo**. Qualquer `sudo` vai rodar com as permissões do Pedro. Tratar com cuidado — nunca enviar comandos destrutivos sem confirmação explícita.

---

## Limitações

- Delay fixo ~500ms no `run` — comandos longos precisam de `capture` extra depois
- Comandos interativos (vim, btop, top) não funcionam via send-keys
- Container usa `nix-shell -p tmux` em cada chamada — lento na primeira (download), rápido depois (cache)
- `leech tmux install` instala tmux permanentemente no nix profile do container (evita o nix-shell overhead)
