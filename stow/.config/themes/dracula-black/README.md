# Dracula Black — tema central unificado

Paleta consumida por todos os componentes GTK-CSS do desktop Hyprland:

| App         | Como consome                                                       |
|-------------|--------------------------------------------------------------------|
| **waybar**  | `~/.config/waybar/style.css` → `@import url("../themes/dracula-black/colors.css")` (via `colors.css` shim que re-exporta para nomes legados). |
| **swaync**  | `~/.config/swaync/style.css` → `@import` direto.                   |
| **wlogout** | `~/.config/wlogout/style.css` → `@import` direto.                  |
| **nwg-panel** | Style configurado dentro do JSON do nwg-panel (referencia o CSS). |
| **swayosd** | `~/.config/swayosd/style.css` → `@import` direto.                  |
| **rofi**    | `~/.config/rofi/theme.rasi` → `@import "../themes/dracula-black/colors.rasi"` (formato `.rasi`, espelha as cores). |
| **hyprlock**| Hyprlock não suporta CSS — cores hardcoded em `hyprlock.conf` (vide TODO). |

## Tokens semânticos (preferir sobre nomes de cor)

```
theme-bg        / theme-surface / theme-elev / theme-border
theme-fg        / theme-fg-muted
theme-accent    / theme-accent-soft
theme-success   / theme-warning / theme-danger / theme-info
```

Quem consome deve usar `@theme-*` em vez de `@dracula-*` — facilita
trocar de variante (Dracula Light, Catppuccin, etc.) sem reescrever cada app.

## Para trocar de tema

1. Criar irmão: `stow/.config/themes/<nome>/colors.css` mantendo os mesmos
   nomes `@theme-*` e `@ws-*`.
2. Atualizar o `@import` em cada style.css consumidor (1 linha cada).

Refs:
- Dracula upstream: https://draculatheme.com/
- "Black" variant: bg trocado de `#282a36` → `#000000`, accents idem.
