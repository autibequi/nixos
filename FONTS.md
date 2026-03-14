# FONTS — Referência de Desenho Terminal

> Fonte do terminal: **JetBrainsMono Nerd Font** (NÃO Mono)
> Ícones Nerd Font ocupam **2 colunas** — contar como 2 chars ao calcular alinhamento.
> Carregar este arquivo no início de toda sessão que envolver desenho de banners, TUI, ou ASCII art.

## Box Drawing

### Light
```
─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴ ┼
```

### Heavy
```
━ ┃ ┏ ┓ ┗ ┛ ┣ ┫ ┳ ┻ ╋
```

### Double
```
═ ║ ╔ ╗ ╚ ╝ ╠ ╣ ╦ ╩ ╬
```

### Rounded
```
╭ ╮ ╰ ╯
```

### Dashed / Dotted
```
┄ ┅ ┆ ┇ ┈ ┉ ┊ ┋ ╌ ╍ ╎ ╏
```

### Mixed (double horizontal + single vertical)
```
╒ ╕ ╘ ╛ ╞ ╡ ╤ ╧ ╪
```

### Mixed (single horizontal + double vertical)
```
╓ ╖ ╙ ╜ ╟ ╢ ╥ ╨ ╫
```

## Arrows & Triangles
```
← → ↑ ↓ ↔ ↕  ◄ ► ▲ ▼  ◁ ▷ △ ▽  ➜ ➤
```

## Bullets & Markers
```
● ○ ◉ ◎  ◆ ◇ ◈  ■ □  ▸ ▹ ◂ ◃  ★ ☆  ✓ ✗ ✔ ✘  ⦿
```

## Separators
```
─────────  (light)
━━━━━━━━━  (heavy)
═════════  (double)
┄┄┄┄┄┄┄┄┄  (dashed)
┈┈┈┈┈┈┈┈┈  (dotted)
⋯⋯⋯⋯⋯⋯⋯⋯⋯  (midline)
```

## Nerd Font — Powerline
```
   right solid       left solid
   right round       left round
   right angle       left angle
   right flame       left flame
   right pixel       left pixel
```

## Nerd Font — Icons (mais usados)
```
  terminal       folder        git-branch
  git-merge      gear          gears
  wrench         code          bug
  fire           bolt          rocket
  chip/cpu       server        database
  cloud          lock          unlock
  key            shield        eye
  search         clock         calendar
  bell           bookmark      link
  download       upload        home
  user           users         comment
  heart          star          warning
  info           check-circle  times-circle
```

## Nerd Font — OS / Brand
```
  nix/nixos      linux/tux     docker
  github         git
```

## Exemplos de Composição

### Rounded box
```
╭──────────────────────────╮
│   TULPA                  │
│   personal dev agent     │
╰──────────────────────────╯
```

### Heavy header + light body
```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃   HEADER                  ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━┩
│   content                 │
└───────────────────────────┘
```

### Double box
```
╔══════════════════════════╗
║   APERTURE SCIENCE       ║
╠══════════════════════════╣
║   content                ║
╚══════════════════════════╝
```

### Powerline segments (com cores ANSI)
```
  TULPA   main   clean
```

### Minimal / clean
```
  TULPA ┄┄ personal dev agent
  13/03/2026  23:51  ☁ 22°C
```

## EVITAR (renderiza mal nesta fonte)
```
░ ▒ ▓ █ ▀ ▄ ▐ ▌   ← block chars: gaps, desalinhamento
╲ ╱ ╳               ← diagonais: não conectam
```

## Regra para Banners Dinâmicos

Quando o conteúdo de uma linha é dinâmico (ex: weather, data), **NUNCA** preencher manualmente com espaços.
Usar função de padding que:
1. Strippa escape codes ANSI para contar largura visual
2. Preenche com espaços até a largura fixa da box
3. Só então adiciona o caractere de borda direita

```bash
# pad_line <border_char> <content> <total_inner_width>
pad_line() {
  local border="$1" content="$2" width="${3:-48}"
  local visible; visible=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
  local vlen; vlen=$(echo -n "$visible" | wc -m)
  local pad=$(( width - vlen ))
  [[ $pad -lt 0 ]] && pad=0
  printf '    %s  ' "$border"
  echo -ne "$content"
  printf "%${pad}s%s\n" "" "$border"
}
```
