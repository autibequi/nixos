# Select Font — Teste iterativo de fontes para box-drawing

Itera sobre fontes do terminal, desenhando padrões de teste com box-drawing chars, para encontrar a fonte que renderiza corretamente.

## Instruções

1. Explicar o processo: vou desenhar um padrão de teste, user manda print, avalio e ajusto.

2. Começar com um **padrão de teste completo** que exercita todos os chars relevantes:

```
╔══════════════════════════════════╗
║  Teste de Fonte — Box Drawing   ║
╠══════════════════════════════════╣
║                                  ║
║  ┌────────┬────────┬────────┐   ║
║  │ Light  │ Lines  │  OK?   │   ║
║  ├────────┼────────┼────────┤   ║
║  │ ────── │ │││││  │  ✓     │   ║
║  └────────┴────────┴────────┘   ║
║                                  ║
║  ╭──────────────────────────╮   ║
║  │  Rounded corners         │   ║
║  ╰──────────────────────────╯   ║
║                                  ║
║  ┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐   ║
║  ╎  Dashed / light dashed   ╎   ║
║  └╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘   ║
║                                  ║
║  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━┓   ║
║  ┃  Heavy lines              ┃   ║
║  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━┛   ║
║                                  ║
║  Nerd Font:       ║
║  Arrows: ➜ ➤ ► ▶ → ⟶ ⟹          ║
║  Checks: ✓ ✗ ● ○ ◆ ◇            ║
║                                  ║
╚══════════════════════════════════╝
```

3. Pedir pro user:
   - Tirar um **print/screenshot** de como renderizou no terminal
   - Informar qual **fonte atual** está usando (se souber)

4. Ao receber o print, analisar:
   - **Alinhamento**: colunas batem? cantos conectam com linhas?
   - **Caracteres faltando**: algum char renderizou como `?`, `□`, ou espaço vazio?
   - **Largura**: chars CJK/wide estão quebrando o grid? (Nerd Font icons são comuns aqui)
   - **Dashed**: `╌` e `╎` renderizaram diferente de `─` e `│`?
   - **Heavy**: `━┃┏┓┗┛` se distinguem dos light?

5. Dar feedback específico sobre o que funcionou e o que não:
   - Se tudo OK → confirmar a fonte como boa e encerrar
   - Se tem problemas → sugerir próxima fonte pra testar

6. **Ordem de fontes pra sugerir** (prioridade):
   - JetBrainsMono Nerd Font Mono
   - FiraCode Nerd Font Mono
   - Hack Nerd Font Mono
   - CaskaydiaCove Nerd Font Mono (Cascadia Code)
   - Iosevka Nerd Font Mono
   - MesloLGS Nerd Font Mono
   - Victor Mono (com Nerd Font patch)
   - DejaVu Sans Mono
   - Ubuntu Mono
   - Monospace genérica do sistema

7. A cada troca, repetir o padrão de teste e pedir novo print.

8. Quando encontrar a fonte ideal, salvar na memória (`feedback_ascii_art_font.md`) e sugerir config para o terminal do user (alacritty, kitty, wezterm, etc).

## Notas
- Nerd Font Mono (não Nerd Font sem Mono) é preferível — a versão Mono garante largura fixa pros glyphs
- Se o user está no Alacritty, a config fica em `stow/.config/alacritty/alacritty.toml`
- Se nenhuma fonte resolver 100%, documentar quais chars evitar na memória
