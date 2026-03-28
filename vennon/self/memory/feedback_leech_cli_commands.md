---
name: feedback_leech_cli_commands
description: Com host_attached=1, sempre usar comandos leech (deck stow, leech switch) em vez de comandos raw. Consultar yaa man para referência completa.
type: feedback
---

Com `host_attached=1` (`leech --host`), nunca usar comandos raw quando há equivalente `yaa`.

**Why:** O CLI leech unifica operações de host (stow, nh os, hyprctl) com tratamento correto de container vs host via `_leech_host_exec`. Comandos raw não funcionam dentro do container ou são menos seguros.

**How to apply:** Ao sugerir operações de host com host_attached, usar sempre a tabela abaixo. Para ver lista completa: `yaa man`.

| Operação | Usar | Nunca |
|----------|------|-------|
| Deploy dotfiles | `deck stow` | `stow -d ~/nixos/stow -t ~ .` |
| Deploy + reload Hyprland | `deck stow --reload` | `stow ... && hyprctl reload` |
| Build/validar NixOS | `leech switch test` | `nh os test .` |
| Aplicar NixOS | `leech switch` | `nh os switch .` |
| Regenerar CLI | `yaa update` (no host) | `bashly generate` (quebra no container por encoding) |
| Status dotfiles | `deck stow status` | — |
