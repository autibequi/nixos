---
name: feedback_zion_cli_commands
description: Em zion lab, sempre usar comandos zion (zion stow, zion switch) em vez de comandos raw. Consultar zion man para referência completa.
type: feedback
---

Em sessão `zion lab`, nunca usar comandos raw quando há equivalente `zion`.

**Why:** O CLI zion unifica operações de host (stow, nh os, hyprctl) com tratamento correto de container vs host via `_zion_host_exec`. Comandos raw não funcionam dentro do container ou são menos seguros.

**How to apply:** Ao sugerir operações de host em zion lab, usar sempre a tabela abaixo. Para ver lista completa: `zion man`.

| Operação | Usar | Nunca |
|----------|------|-------|
| Deploy dotfiles | `zion stow` | `stow -d ~/nixos/stow -t ~ .` |
| Deploy + reload Hyprland | `zion stow --reload` | `stow ... && hyprctl reload` |
| Build/validar NixOS | `zion switch test` | `nh os test .` |
| Aplicar NixOS | `zion switch` | `nh os switch .` |
| Regenerar CLI | `zion update` (no host) | `bashly generate` (quebra no container por encoding) |
| Status dotfiles | `zion stow status` | — |
