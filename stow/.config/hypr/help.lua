-- ============================================================
--  HELP — manual completo do config em SUPER+,
--
--  Gera markdown a partir de:
--    1. keymap.cheatsheet() (binds dinâmicos com desc/group)
--    2. Seções estáticas das features (profiles, pomodoro, etc)
--  Salva em /tmp/hyprland-help.md e abre em alacritty + bat/less.
-- ============================================================

local km   = require("keymap")
local core = require("core")
local km_ok = true  -- agora sempre disponível (compat com bloco abaixo)

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

Cicla modos de uso com `SUPER+SHIFT+P` (era control panel antes — control panel foi pra `MOD3+SHIFT+P`).

| Profile  | Gaps | Border | Animations | Side effects                          |
|----------|------|--------|------------|---------------------------------------|
| default  | 5    | 3      | on         | —                                     |
| focus    | 0    | 1      | off        | DND on, sem distração                 |
| meeting  | 12   | 4      | on, blur   | mic on, brilho 80%                    |
| battery  | 3    | 2      | off        | animações off, bordas finas              |

Programático: `require("profiles").apply("focus")` ou `.cycle()` ou `.current()`.

---

### 2. **Pomodoro** (`pomodoro.lua`)

`SUPER+SHIFT+T` cicla: idle → work(25min) → break(5min) → idle.
- Work: aplica profile=focus + notif
- Break: aplica profile=default + notif "break"
- Status em `~/.cache/hyprland/pomodoro` via `core.state_file` (waybar pode ler).
- 2ª pressão durante work/break: cancela (invalida `_cycle_id`).

---

### 3. **HUD** (`hud.lua`)

`SUPER+;` mostra peek do estado atual via `core.notify` (notify-send com escape):
- Monitor + workspace ativo + contagem janelas (via `core.clients_cached`)
- Special workspace ativo
- Profile corrente
- Top 3 apps por contagem
- Total de clients

---

### 4. **Window picker** (`picker.lua`)

Alt-Tab Wayland-friendly via rofi (usa `core.rofi_menu`):
- `MOD3+Tab` — todas as janelas
- `MOD3+SHIFT+Tab` — só workspace atual

---

### 5. **Cycler por aplicação** (`cycler.lua`)

`MOD3+I` cicla janelas do **mesmo class** que está focada (caso de uso: 4 Chromes, quero ir pra próxima sem abrir picker).
- `MOD3+SHIFT+I` — backward.

---

### 7. **Swallow** (`swallow.lua`)

Terminal "engole" filho GUI (estilo dwm):
- Roda `nautilus` em Alacritty → terminal vai pra `special:_swallowed`
- Filho fecha → terminal volta no mesmo lugar/workspace
- Funciona pra: Alacritty, Ghostty
- Skip: portal, eww-whisper-ptt, clipboard popup, rofi
- Implementação: `io.open("/proc/<pid>/status")` (não `io.popen ps` — não bloqueia)

---

### 8. **Smart actions** (`submaps.lua`)

Atalhos context-aware (despacham keypress via `wtype` baseado no app focado, via `core.focused`):
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

Poll periódico (1500ms) em `~/.cache/vennon/last-applied`. Conteúdo mudou → `hyprctl reload` + notif.
- Implementação: `io.open` + comparar conteúdo (não `io.popen stat` — não bloqueia).
- `vennon-theme-apply` precisa tocar o marker no post-hook (`date +%s > ~/.cache/vennon/last-applied`).

---

### 12. **REPL** (`repl.lua`)

Debug live sem reload do Hyprland (timer 500ms). Protocolo file-based:
```bash
echo 'return #hl.get_clients()' > /tmp/hyprlua.in
sleep 0.3
cat /tmp/hyprlua.out
```

---

### 13. **Events reativos** (`events.lua`)

Hooks declarativos — políticas opt-in via `define_special({ on_active = fn, auto_route_classes = {...} })`. `events.lua` só consome o registry.

| Evento Hyprland       | Ação                                                              |
|-----------------------|-------------------------------------------------------------------|
| `workspace.active`    | dispatch `core.workspace_active_handlers[ws_name]` (popular via define_special); fallback: DND off em 1-3 |
| `window.open`         | lookup `core.workspace_auto_route_classes[class]` → movetoworkspacesilent |
| `monitor.added`       | Notif + `hyprctl reload` + waybar refresh                          |
| `monitor.removed`     | Notif + waybar refresh                                             |
| `window.urgent`       | Notif "Urgent: <class>"                                            |

---

### 14. **DSL Lua-first**

- `core.lua` — helpers compartilhados: `notify`, `on(ev,fn)` com pcall, `timer(ms,fn)`, `state_file(name)`, `focused`, `clients_cached`, `other_monitor`, `escape_sh`, `trunc`, `rofi_menu`. Registries: `workspace_active_handlers`, `workspace_auto_route_classes`.
- `keymap.lua` — registry de binds com `desc/group/icon`. Use `km.bind/app/fn/dispatch`. Cheatsheet (`SUPER+/`) e manual (`SUPER+,`) consomem do registry.
- `launcher.lua` — wrapper unificado: `L.build/chrome/term`. Todos os spawns passam por aqui (autostart, special-workspaces, services, application). Kill-switch:
  - `HYPR_NO_UWSM=1` — spawn direto, sem `uwsm app --`
- `define_special(name, key, opts)` — single source of truth pra special workspace: rules, borders, bind, label, `on_created_empty`, `on_active`, `auto_route_classes`, `tile`, `no_screen_share`.

---

## 🗂️ ESTRUTURA DE ARQUIVOS

```
~/.config/hypr/
├── hyprland.lua          # entry point + wiring + env vars (autostart em arquivo próprio)
├── autostart.lua         # daemons + cursor + tema em hl.on("hyprland.start")
├── core.lua              # helpers (notify/on/timer/state_file/focused/clients_cached/rofi_menu)
├── keymap.lua            # registry semântico de binds (desc/group/icon)
├── launcher.lua          # spawn wrapper (uwsm app -- + --class/--app)
├── clients.lua           # parse hyprctl clients -j (sem json lib)
├── services.lua          # waybar/quickshell/clipboard/hypr_reload
├── screenshots.lua       # grim/satty/tesseract (4 funcs)
├── utils.lua             # state special workspace + workspace_switch + colresize + monitor moves
├── theme.lua             # dark/light toggle (gtk + alacritty + wallpaper + vennon-theme-apply)
├── theme_watcher.lua     # auto-reload no marker do vennon
├── monitors.lua          # nwg-displays output
├── generated-colors.lua  # vennon-theme-apply output
├── windowrules.lua       # regras de janela (nautilus, file pickers, electron popup, claude borders)
├── special-workspaces.lua# F1-F9, gemini, bleh (declara on_active/auto_route)
├── workspace.lua         # workspaces 1-10 + WASD focus/move/resize + special history
├── application.lua       # apps + binds (terminal/zed/chrome/PWAs/AI)
├── systemtools.lua       # screenshot, lock, multimedia, theme toggle, whisper PTT
├── hyprshortcuts.lua     # rofi cheatsheet (consome keymap + core.rofi_menu)
├── events.lua            # hooks reativos hl.on (consome registries)
├── profiles.lua          # default/focus/meeting/battery
├── picker.lua            # Alt-Tab Wayland (core.rofi_menu)
├── cycler.lua            # cicla por class
├── hud.lua               # SUPER+; peek de estado
├── pomodoro.lua          # SUPER+SHIFT+T timer
├── swallow.lua           # terminal swallowing (via /proc)
├── submaps.lua           # smart actions context-aware
├── followme.lua          # sync workspaces entre monitores
├── specials-feed.lua     # SIGRTMIN+11 → waybar refresh em events
├── repl.lua              # file-based eval (timer 500ms)
└── help.lua              # este manual
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
MOD3+SHIFT+P   control panel       MOD3+ALT+C Claude.ai web

─── Navigation ───────────────────────────────
SUPER+WASD     focus               SUPER+SHIFT+WASD  move window
SUPER+CTRL+WASD resize             SUPER+Q/E         col width
SUPER+1-0      go workspace        SUPER+SHIFT+1-0   move to ws
SUPER+Esc      next monitor        SUPER+SHIFT+Esc   move window to next monitor
MOD3+Tab       picker (all)        MOD3+SHIFT+Tab    picker (current ws)
MOD3+I/SHIFT+I cycle same class

─── Special workspaces ──────────────────────
SUPER+G        gemini              SUPER+`           toggle last special
SUPER+F1-F9    F-key scratchpads   SUPER+[/]         back/forward stack
SUPER+SHIFT+<key>  move window → special
SUPER+ALT+Right    move special → other monitor
SUPER+ALT+Down/Left focus other monitor

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
SUPER+Tab      maximize            SUPER+ALT+Tab     float toggle
SUPER+F11      fullscreen client   SUPER+SHIFT+F11   true fullscreen

─── Screenshots & clipboard ─────────────────
SUPER+U        região → Walker (copiar/salvar/satty/OCR)
SUPER+P        color picker              SUPER+SHIFT+V clip history (terminal)
SUPER+V        Walker clipboard          CTRL+ALT+V    paste sem newlines

─── Power ───────────────────────────────────
CTRL+ALT+DEL   Walker power menu    MOD3+F12   wlogout
```

> Mudanças notáveis vs versão hyprlang antiga:
> - `SUPER+SHIFT+P` → cycle profile (era control panel)
> - `SUPER+Escape` → focus next monitor (era wlogout — agora só `MOD3+F12`)
> - `SUPER+CTRL+U` removido (era duplicado com `SUPER+ALT+U`)
> - control panel → `MOD3+SHIFT+P`

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
        core.notify("help", "Falhou ao escrever " .. path, { urgency = "critical" })
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

km.fn("SUPER + comma", function() show_help() end,
    { desc = "Hyprland manual (markdown)", group = "Help", icon = "📖" })
