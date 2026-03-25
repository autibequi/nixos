---
name: meta/tmux
description: "Tmux compartilhado host ↔ container — rodar comandos no shell do host, capturar output, nixos-rebuild, hyprctl, qualquer binário do host."
---

# meta/tmux — Host Shell via Tmux

Acesso ao shell do host através do socket tmux compartilhado.  
Socket: `/run/user/1000/zion-tmux.sock` | Sessão: `main`

---

## Verificar disponibilidade

```bash
leech tmux status
```

Se offline: `leech tmux serve` (no host — comando interativo, mantém sessão aberta).

---

## Rodar comando no host

```bash
leech tmux run <comando>
```

Exemplos:
```bash
leech tmux run "sudo nixos-rebuild switch"
leech tmux run "hyprctl reload"
leech tmux run "systemctl --user restart waybar"
leech tmux run "nvidia-smi"
leech tmux run "pkill -f 'ob sync'"
```

O comando é enviado via `send-keys` e o output capturado automaticamente (~500ms delay).

---

## Capturar output atual do pane

```bash
leech tmux capture
```

Útil depois de comandos longos — captura o estado atual da tela.

---

## Padrão para comandos com output longo

```bash
# Enviar
leech tmux run "sudo nixos-rebuild switch 2>&1 | tail -20"
# Aguardar e capturar novamente se necessário
leech tmux capture
```

---

## Quando usar

| Situação | Comando |
|---|---|
| Aplicar NixOS config | `leech tmux run "sudo nixos-rebuild switch"` |
| Reload Hyprland | `leech tmux run "hyprctl reload"` |
| Matar processo | `leech tmux run "pkill -f <nome>"` |
| Ver GPU | `leech tmux run "nvidia-smi"` |
| Qualquer binário do host | `leech tmux run "<cmd>"` |

---

## Limitações

- Output capturado tem delay fixo de 500ms — comandos longos precisam de `capture` extra
- Comandos interativos (vim, btop) não funcionam via `run` — são para `open` no host
- `leech tmux serve` é para o **host** — inicia servidor + sessão interativa; quando sai, mata o servidor
- `leech tmux open` é para o **container** — conecta a uma sessão serve já rodando no host
