-- ============================================================
--  HELP — manual completo do config em SUPER+,
--
--  Gera markdown a partir de:
--    1. keymap.cheatsheet() (binds dinâmicos com desc/group)
--    2. Seções estáticas das features (profiles, pomodoro, etc)
--  Salva em /tmp/hyprland-help.md e abre em alacritty + bat/less.
-- ============================================================

local km_ok, km = pcall(require, "keymap")

local HEADER = [[
# 🪟 HYPRLAND CONFIG — MANUAL COMPLETO

> Manual gerado dinamicamente. Atalho: `SUPER + ,`
> Source: ~/.config/hypr/*.lua

---

## 📋 ATALHOS REGISTRADOS (keymap registry)

]]

local FEATURES_MD = [[

---

## 🎯 FEATURES DO CONFIG

### 1. **Profiles** (`profiles.lua`)

Cicla modos de uso com `SUPER+SHIFT+P`:

| Profile  | Gaps | Border | Animations | Side effects                          |
|----------|------|--------|------------|---------------------------------------|
| default  | 5    | 3      | on         | —                                     |
| focus    | 0    | 1      | off        | DND on, sem distração                 |
| meeting  | 12   | 4      | on, blur   | mic on, brilho 80%                    |
| battery  | 3    | 2      | off        | desabilita gpu-offload em novos spawns|

Programático: `require("profiles").apply("focus")` ou `.cycle()` ou `.current()`.

---

### 2. **Pomodoro** (`pomodoro.lua`)

`SUPER+SHIFT+T` cicla: idle → work(25min) → break(5min) → idle.
- Work: aplica profile=focus + notif
- Break: aplica profile=default + notif "break"
- Status em `~/.cache/hyprland/pomodoro` (waybar pode ler).
- 2ª pressão durante work/break: cancela.

---

### 3. **HUD** (`hud.lua`)

`SUPER+;` mostra peek do estado atual via notify-send:
- Monitor + workspace ativo + contagem janelas
- Special workspace ativo
- Profile corrente
- Top 3 apps por contagem
- Total de clients

---

### 4. **Window picker** (`picker.lua`)

Alt-Tab Wayland-friendly via rofi:
- `MOD3+Tab` — todas as janelas
- `MOD3+SHIFT+Tab` — só workspace atual

---

### 5. **Cycler por aplicação** (`cycler.lua`)

`MOD3+I` cicla janelas do **mesmo class** que está focada (caso de uso: 4 Chromes, quero ir pra próxima sem abrir picker).
- `MOD3+SHIFT+I` — backward.

---

### 6. **Screenshare guard** (`screenshare_guard.lua`)

Automático via evento `screenshare.state`:
- Entra screenshare → DND on + bordas vermelhas grossas + notif crítica
- Sai screenshare → reverte tudo + notif

---

### 7. **Swallow** (`swallow.lua`)

Terminal "engole" filho GUI (estilo dwm):
- Roda `nautilus` em Alacritty → terminal vai pra `special:_swallowed`
- Filho fecha → terminal volta no mesmo lugar/workspace
- Funciona pra: Alacritty, Ghostty
- Skip: portal, eww-whisper-ptt, clipboard popup, rofi

---

### 8. **Smart actions** (`submaps.lua`)

Atalhos context-aware (despacham keypress via `wtype` baseado no app focado):
- `SUPER+SHIFT+S` — **save smart** (Ctrl+S na maioria; mostra notif se sem rule)
- `SUPER+SHIFT+W` — **close smart** (Ctrl+W em Zed/Cursor/Chrome; fallback = killactive)
- `SUPER+SHIFT+R` — **reload smart** (F5/Ctrl+R em browsers)

---

### 9. **Follow-me** (`followme.lua`)

`MOD3+F` toggle. Pares de workspace entre monitores:
```
DP-2:  1   2   3   4   5  6
eDP-1: 7   8   9   10
       ↕   ↕   ↕   ↕
```
Quando ON, trocar ws em um monitor força o par no outro. Workspaces 5/6 ficam sem par.

---

### 10. **Special workspace stack** (`utils.lua`)

Cada special workspace que você abre é empilhado por monitor (max 16).
- `SUPER+[` — back (volta pro special anterior)
- `SUPER+]` — forward (refaz)

Stack é por-monitor (DP-2 e eDP-1 têm históricos independentes).

---

### 11. **Theme watcher** (`theme_watcher.lua`)

Poll a cada 1.5s em `~/.cache/vennon/last-applied`. Se mtime muda, `hyprctl reload` + notif "Theme refreshed".
- Cria o marker no post-hook do `vennon-theme-apply` pra o ciclo fechar.

---

### 12. **REPL** (`repl.lua`)

Debug live sem reload do Hyprland. Protocolo file-based:
```bash
echo 'return #hl.get_clients()' > /tmp/hyprlua.in
sleep 0.3
cat /tmp/hyprlua.out
```

Helper opcional `~/.local/bin/hyprlua-eval`:
```sh
#!/bin/sh
printf '%s' "$*" > /tmp/hyprlua.in
while [ -s /tmp/hyprlua.in ]; do sleep 0.05; done
cat /tmp/hyprlua.out
```

Log de cada comando em `/tmp/hyprlua.log`.

Exemplos:
```bash
hyprlua-eval 'return require("profiles").current()'
hyprlua-eval 'require("profiles").apply("focus")'
hyprlua-eval 'return #hl.get_clients()'
hyprlua-eval 'pomodoro_status()'
hyprlua-eval 'show_hud()'
```

---

### 13. **Events reativos** (`events.lua`)

Hooks ativos (todos com pcall defensivo):

| Evento Hyprland       | Ação                                                      |
|-----------------------|-----------------------------------------------------------|
| `workspace.active`    | F1 → DND on; F9 → mute mic                                |
| `window.open`         | Slack/Zoom auto-move pra `special:f5`                     |
| `monitor.added`       | Notif + `hyprctl reload` + waybar refresh                 |
| `monitor.removed`     | Notif + waybar refresh                                    |
| `window.urgent`       | Notif "Urgent: <class>"                                   |
| `screenshare.state`   | (em screenshare_guard.lua) DND on + bordas vermelhas      |

---

### 14. **DSL Lua-first**

- `keymap.lua` — registry de binds com `desc/group/icon`. Use `km.bind/app/fn/dispatch`.
- `launcher.lua` — wrapper unificado: `L.build/chrome/term`. Env kill-switches:
  - `HYPR_NO_GPU=1` — desabilita `gpu-offload` em todos os builds
  - `HYPR_NO_UWSM=1` — spawn direto, sem `uwsm app --`

---

## 🗂️ ESTRUTURA DE ARQUIVOS

```
~/.config/hypr/
├── hyprland.lua          # entry point + wiring + env vars + autostart
├── utils.lua             # state, helpers (workspace switch, special stack, screenshots)
├── theme.lua             # dark/light toggle
├── theme_watcher.lua     # auto-reload em mudança de cores
├── monitors.lua          # nwg-displays output
├── generated-colors.lua  # vennon-theme-apply output
├── windowrules.lua       # regras de janela
├── special-workspaces.lua# F1-F9, gemini, bleh
├── workspace.lua         # workspaces 1-10 + WASD focus/move/resize
├── application.lua       # apps + binds (usa keymap+launcher)
├── systemtools.lua       # screenshot, lock, multimedia, theme toggle
├── keymap.lua            # 🆕 registry semântico de binds
├── launcher.lua          # 🆕 wrapper L.build/chrome/term
├── hyprshortcuts.lua     # rofi cheatsheet (consome keymap)
├── events.lua            # 🆕 hooks reativos hl.on
├── profiles.lua          # 🆕 default/focus/meeting/battery
├── picker.lua            # 🆕 Alt-Tab Wayland
├── cycler.lua            # 🆕 cicla por class
├── hud.lua               # 🆕 SUPER+; peek de estado
├── pomodoro.lua          # 🆕 SUPER+SHIFT+T timer
├── screenshare_guard.lua # 🆕 auto-DND
├── swallow.lua           # 🆕 terminal swallowing
├── submaps.lua           # 🆕 smart actions context-aware
├── followme.lua          # 🆕 sync workspaces entre monitores
├── repl.lua              # 🆕 file-based REPL
└── help.lua              # 🆕 este manual
```

---

## ⌨️ CHEAT SHEET (resumo)

```
─── Apps ─────────────────────────────────────
MOD3+Space     rofi launcher       MOD3+T     terminal
MOD3+Z         Zed                 MOD3+B     Chrome
MOD3+G         Gemini PWA          MOD3+A     audio (wiremix)
MOD3+P         vennon REPL         MOD3+C     yaa Haiku
MOD3+SHIFT+C   yaa Sonnet[1M]      MOD3+.     emoji picker

─── Navigation ───────────────────────────────
SUPER+WASD     focus               SUPER+SHIFT+WASD  move window
SUPER+CTRL+WASD resize             SUPER+Q/E         col width
SUPER+1-0      go workspace        SUPER+SHIFT+1-0   move to ws
SUPER+Esc      next monitor        MOD3+Tab          picker

─── Special workspaces ──────────────────────
SUPER+G        gemini              SUPER+`           bleh terminal
SUPER+F1-F9    F-key scratchpads   SUPER+[/]         back/forward stack

─── Cycler & swallow ────────────────────────
MOD3+I         next app instance   MOD3+SHIFT+I      prev app instance

─── Smart actions ───────────────────────────
SUPER+SHIFT+S  save smart          SUPER+SHIFT+W     close smart
SUPER+SHIFT+R  reload smart

─── Modes & timers ──────────────────────────
SUPER+SHIFT+P  cycle profile       SUPER+SHIFT+T     pomodoro toggle
MOD3+F         follow-me toggle

─── System ──────────────────────────────────
SUPER+Space    quickshell overview SUPER+;           HUD peek
SUPER+L        lock                SUPER+N           toggle dark/light
SUPER+Delete   reload hyprland     MOD3+Escape       close window
SUPER+/        shortcuts popup     SUPER+,           THIS HELP

─── Screenshots & clipboard ─────────────────
SUPER+U        region → clip       SUPER+ALT+U       full + crop
SUPER+SHIFT+U  OCR region          SUPER+SHIFT+V     clip history
SUPER+P        color picker

─── Power ───────────────────────────────────
MOD3+F10/11/12 logout/suspend/poweroff
```

---

*Gerado por `show_help()` — bind: `SUPER+,`*
]]

local function escape_md(s)
    return (s or ""):gsub("|", "\\|")
end

function show_help()
    local md = HEADER

    if km_ok and km then
        -- Agrupa por grupo
        local entries = km.cheatsheet()
        local groups = km.groups()
        for _, g in ipairs(groups) do
            md = md .. "\n### " .. g .. "\n\n"
            md = md .. "| Combo | Descrição |\n|---|---|\n"
            for _, e in ipairs(entries) do
                if e.group == g then
                    md = md .. string.format("| `%s` | %s %s |\n",
                        escape_md(e.combo),
                        e.icon ~= "" and e.icon or "",
                        escape_md(e.desc))
                end
            end
        end
    else
        md = md .. "\n_(keymap registry indisponível)_\n"
    end

    md = md .. FEATURES_MD

    local path = "/tmp/hyprland-help.md"
    local f = io.open(path, "w")
    if not f then
        hl.exec_cmd("notify-send 'help' 'Falhou ao escrever " .. path .. "' -u critical")
        return
    end
    f:write(md)
    f:close()

    -- Abre em alacritty flutuante com bat (se houver) ou less
    hl.exec_cmd([[sh -c '
        if command -v bat >/dev/null 2>&1; then
            VIEWER="bat --paging=always --style=plain --language=md --color=always"
        elif command -v glow >/dev/null 2>&1; then
            VIEWER="glow -p"
        else
            VIEWER="less -R"
        fi
        uwsm app -- alacritty \
            --class="hyprland-help,hyprland-help" \
            --title="Hyprland — Manual" \
            -o "window.dimensions.columns=120" \
            -o "window.dimensions.lines=50" \
            -e sh -c "$VIEWER /tmp/hyprland-help.md"
    ']])
end

-- Window rule pra o help abrir flutuante centralizado
hl.window_rule({
    match  = { class = "hyprland-help" },
    float  = true,
    center = true,
    size   = { "monitor_w*0.7", "monitor_h*0.8" },
})

hl.bind("SUPER + comma", function() show_help() end)
