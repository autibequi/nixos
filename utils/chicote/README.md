# chicote 🥁

Overlay modal pro Hyprland: o cursor vira um chicote com física (Verlet). Sacudiu
forte (a ponta estala) → manda `mais rapido` + Enter pra janela focada. Modal —
liga/desliga com `MOD3 + s`, `ESC` também fecha.

## Build (no host, NixOS)

Subprojeto isolado — Makefile próprio. Não compila no container (sem raylib/cargo):

```bash
cd ~/host/utils/chicote
make install         # builda (flake) e instala em ~/.local/bin/chicote
```

**Hyprland exige** a feature `wayland` do raylib (já no `Cargo.toml`). Sem ela o GLFW
só tem GLX/X11 → `GLX: Failed to load GLX` e segfault.

`make run` roda sem instalar; `make build` só compila. `~/.local/bin` precisa estar
no PATH do Hyprland.

## Integração (já aplicada no stow)

- **`~/.config/hypr/chicote.lua`** — window rule + bind `MOD3 + s`. Já tem
  `require("chicote")` no `hyprland.lua`.
- **`~/.config/hypr/chicote-toggle.sh`** — spawn/kill + esconde/restaura cursor +
  refresh da waybar. Dono do estado do cursor (cobre saída por ESC e por toggle).
- **waybar** — módulo `custom/chicote` no `modules-center`: mostra 🥁 (sem texto)
  enquanto roda, via `signal 12`.

Recarregar: `hyprctl reload` + reiniciar a waybar.

## Ajustes

Constantes no topo do `src/main.rs`:

| Const | O que |
|---|---|
| `CRACK_SPEED` | velocidade da ponta que conta como estalo (↑ = precisa sacudir mais forte) |
| `COOLDOWN_S` | silêncio entre disparos |
| `N` / `SEG` | nós e comprimento do chicote |
| `DAMP` / `GRAV` | inércia e peso |

## Limitações

- **Cursor escondido** depende da keyword `cursor:invisible` do Hyprland. Se a tua
  versão não tiver, o chicote só desenha junto do cursor real (vira o cabo) — resto
  funciona igual.
- **Modal de propósito**: enquanto ligado a janela cobre a tela (não é click-through).
  É pra ligar, estalar, sair.
- Se o foco ainda for roubado e o `wtype` não cair no terminal: adicionar `no_focus`
  na window rule do `chicote.lua`.
