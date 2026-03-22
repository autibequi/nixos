---
name: reference_hyprscroller_config
description: Opções confirmadas e não-existentes do hyprscroller (layout scrolling do Hyprland)
type: reference
---

## Opções confirmadas (funcionam)

```
scrolling {
    column_width             = 0.25
    fullscreen_on_one_column = true
    focus_fit_method         = 1        # 0 = center, 1 = fit
    follow_focus             = false
    follow_min_visible       = 0.0
    explicit_column_widths   = 0.2, 0.25, 0.333, 0.5, 0.667, 1.0
}
```

## Opções que NÃO existem

- `focus_wrap = false` — **não existe**. Hyprland loga "does not exist" e ignora.

## Workarounds para comportamentos ausentes

### No-wrap no foco (SUPER+A/D)
Implementar em shell: antes de `layoutmsg focus l/r`, checar se existe janela no workspace com `.at[0]` menor/maior que a janela atual via `hyprctl -j clients`.

### No-wrap no colresize (SUPER+Q/E)
Implementar em shell: calcular fração `win_w / mon_logical_w` e não despachar se já estiver no min/max. Ver `feedback_hyprctl_pixels.md` para o cálculo correto com scale.

Código de referência: `stow/.config/hypr/hyprutils.sh` — funções `focus_no_wrap` e `colresize_no_wrap`.
