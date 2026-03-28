---
name: reference_ghostty_config
description: Ghostty features, otimizações e armadilhas — light theme, imagens, single instance, shell integration
type: reference
---

## Light theme

`iTerm2 Light Background` tem palette 7/15 branco/near-white — texto invisível em fundo claro.
Usar `catppuccin-latte` (em `stow/.config/ghostty/themes/catppuccin-latte`) como light theme.
Config: `theme = dark:catppuccin-mocha,light:catppuccin-latte`

## Imagens no terminal (yazi, etc.)

Ghostty suporta Kitty Graphics Protocol nativamente. Yazi detecta automaticamente via `$GHOSTTY_RESOURCES_DIR`.
Sem config extra — só precisa de memória suficiente:
`image-storage-limit = 320000000`

## Performance no Linux

`gtk-single-instance = true` — maior ganho: abre nova aba/janela no processo existente.
Já tem `linux-cgroup = single-instance` para isolamento de cgroups.

## Shell integration

`shell-integration = detect` com `shell-integration-features = no-cursor` dá:
- `ctrl+shift+up/down` para pular entre outputs de comandos
- Working dir tracking automático em splits/tabs
- Sem override do cursor (deixa o terminal controlar)

## Features configuradas (estado atual)

```
link-url = true
resize-overlay = never
font-feature = calt
bold-is-bright = true
image-storage-limit = 320000000
gtk-single-instance = true
shell-integration = detect
shell-integration-features = no-cursor
```
