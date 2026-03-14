# Test Page — Página de teste completa do terminal

Gera uma test page abrangente para calibrar e validar a renderização do terminal: fonte, cores, alinhamento, unicode, Nerd Font icons, e layout.

## Instruções

1. Imprimir a test page completa abaixo no terminal (usar `echo` ou output direto).

2. A test page exercita **todas as dimensões** relevantes:

```
╔══════════════════════════════════════════════════════════════════╗
║                    TERMINAL TEST PAGE v1.0                      ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  ┌─ BOX DRAWING ────────────────────────────────────────────┐   ║
║  │                                                          │   ║
║  │  Light:  ┌────────┬────────┐   Heavy:  ┏━━━━━━━┳━━━━━━━┓│   ║
║  │          │ cell A │ cell B │           ┃ cel A ┃ cel B ┃│   ║
║  │          ├────────┼────────┤           ┣━━━━━━━╋━━━━━━━┫│   ║
║  │          │ cell C │ cell D │           ┃ cel C ┃ cel D ┃│   ║
║  │          └────────┴────────┘           ┗━━━━━━━┻━━━━━━━┛│   ║
║  │                                                          │   ║
║  │  Rounded: ╭──────────────╮   Dashed: ┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐  │   ║
║  │           │  soft edges  │           ╎  dashed box   ╎  │   ║
║  │           ╰──────────────╯           └╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘  │   ║
║  │                                                          │   ║
║  │  Double: ╔══════════════╗   Mixed: ╒══════════════╕      │   ║
║  │          ║  double box  ║          │  mixed box   │      │   ║
║  │          ╚══════════════╝          ╘══════════════╛      │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                                                                  ║
║  ┌─ ALIGNMENT ──────────────────────────────────────────────┐   ║
║  │  |123456789|123456789|123456789|123456789|123456789|      │   ║
║  │  ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz   │   ║
║  │  0123456789 !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~            │   ║
║  │  the quick brown fox jumps over the lazy dog             │   ║
║  │  THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG             │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                                                                  ║
║  ┌─ UNICODE ────────────────────────────────────────────────┐   ║
║  │  Arrows:    → ← ↑ ↓ ↔ ↕ ⇒ ⇐ ⇑ ⇓ ⟶ ⟵ ➜ ➤ ► ▶          │   ║
║  │  Math:      ± × ÷ ≠ ≈ ≤ ≥ ∞ √ ∑ ∏ ∫ ∂ ∆ ∇ ∈ ∉        │   ║
║  │  Symbols:   ✓ ✗ ● ○ ◆ ◇ ■ □ ▲ △ ★ ☆ ♠ ♥ ♦ ♣          │   ║
║  │  Latin:     àáâãäå èéêë ìíîï ñ òóôõö ùúûü ÿ ç ß        │   ║
║  │  Greek:     α β γ δ ε ζ η θ ι κ λ μ ν ξ π ρ σ τ        │   ║
║  │  Braille:   ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏ (spinner frames)     │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                                                                  ║
║  ┌─ NERD FONT ICONS ───────────────────────────────────────┐   ║
║  │  Dev:       󰌠       󰎙                        │   ║
║  │  Files:                                        │   ║
║  │  Git:                                         │   ║
║  │  System:    󰍛  󰘚                              │   ║
║  │  Weather:   󰖐 󰖑 󰖒                                       │   ║
║  │  Powerline: ▓▒░                                  │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                                                                  ║
║  ┌─ ANSI COLORS ───────────────────────────────────────────┐   ║
║  │  Normal:  ■ ■ ■ ■ ■ ■ ■ ■  (8 standard)                │   ║
║  │  Bright:  ■ ■ ■ ■ ■ ■ ■ ■  (8 bright)                  │   ║
║  │  Styles:  Bold  Italic  Underline  Strikethrough         │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                                                                  ║
║  ┌─ PROGRESS / UI ELEMENTS ────────────────────────────────┐   ║
║  │  Progress: [████████████████████░░░░░░░░░░] 66%          │   ║
║  │  Spinner:  ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏                        │   ║
║  │  Dividers: ─────────  ━━━━━━━━━  ┄┄┄┄┄┄┄┄┄  ┈┈┈┈┈┈┈┈┈  │   ║
║  │  Bullets:  • item   ◦ sub     ‣ alt    ⁃ hyphen          │   ║
║  └──────────────────────────────────────────────────────────┘   ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

3. Pedir pro user tirar um **screenshot** de como renderizou.

4. Ao receber o screenshot, avaliar cada seção:

   **Box Drawing:**
   - Cantos conectam? Linhas contínuas sem gaps?
   - Light vs Heavy distinguíveis?
   - Rounded corners (╭╮╰╯) renderizam?
   - Dashed (╌╎) diferente de solid?

   **Alignment:**
   - Colunas numéricas batem?
   - Monospacing consistente em toda a página?
   - Chars especiais não quebram o grid?

   **Unicode:**
   - Algum char renderizou como □, ?, ou tofu?
   - Arrows e math symbols todos presentes?
   - Braille spinners renderizam?

   **Nerd Font Icons:**
   - Dev icons (Python, JS, Rust, etc) visíveis?
   - Powerline separators renderizam?
   - Icons com largura consistente (não quebrando alinhamento)?

   **Colors (se visível no screenshot):**
   - 8 cores normais distinguíveis?
   - 8 cores bright distinguíveis?
   - Bold/Italic/Underline funcionam?

   **UI Elements:**
   - Progress bar contínua?
   - Dividers de estilos diferentes?

5. Dar diagnóstico detalhado:
   - O que está perfeito
   - O que tem problemas (com char específico e sugestão de fix)
   - Se a fonte atual é adequada ou precisa trocar

6. Se necessário, sugerir ajustes:
   - Trocar fonte (ver ordem em `/calibrate font`)
   - Ajustar `font.size` ou `font.offset` no alacritty
   - Habilitar/desabilitar `builtin_box_drawing`
   - Instalar Nerd Font patches faltando

## Notas
- Essa test page é mais abrangente que o teste de `/calibrate font` — cobre unicode, cores, e UI elements além de box-drawing
- Usar com `/calibrate font` para um workflow completo de calibração
- A config do terminal está em `stow/.config/alacritty/alacritty.toml`
