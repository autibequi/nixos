---
name: feedback_hyprctl_pixels
description: hyprctl monitors[].width é pixels físicos; activewindow.size[] é pixels lógicos — dividir pelo scale antes de comparar frações
type: feedback
---

`hyprctl -j monitors[].width` (e `.height`) retornam **pixels físicos** (resolução real do monitor).
`hyprctl -j activewindow` `.size[0]` e `.at[0]` retornam **pixels lógicos** (após aplicar o scale).

Se comparar os dois diretamente para calcular fração de tela, o resultado estará errado sempre que `scale != 1.0`. Exemplo: monitor 2560px em scale 1.5 → janela em 100% reporta 1707px → 1707/2560 = 0.667, não 1.0.

**Why:** Bug descoberto ao implementar `colresize_no_wrap` em hyprutils.sh: o threshold de max (0.85) nunca era atingido porque a fração calculada era menor que o esperado.

**How to apply:** Sempre que calcular fração `win / monitor`, usar:
```sh
mon_phys=$(hyprctl -j monitors | jaq -r '.[] | select(.focused == true) | .width')
mon_scale=$(hyprctl -j monitors | jaq -r '.[] | select(.focused == true) | .scale')
mon_w=$(awk "BEGIN { printf \"%d\", $mon_phys / $mon_scale }")
# Ou em um só call:
mon_info=$(hyprctl -j monitors | jaq -r '.[] | select(.focused == true) | "\(.width) \(.scale)"')
mon_w=$(awk "BEGIN { split(\"$mon_info\", a); printf \"%d\", a[1] / a[2] }")
```
