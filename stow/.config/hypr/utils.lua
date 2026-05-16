-- ============================================================
--  UTILS — portado de hyprutils.sh
--  Usa APIs nativas do Hyprland 0.55 Lua onde possível
-- ============================================================

-- ── State em memória (substitui arquivos ~/.cache/hyprland/) ─
-- Perdido em reload — aceitável (mesmo comportamento de arquivos em /tmp em novos boots)
local _last_special_ws = {}  -- { monitor_name = ws_name }

-- Stack de specials por monitor (back/forward browser-like)
-- { monitor_name = { stack = {"f1", "f5", "bleh", ...}, idx = N } }
local _special_history = {}
local SPECIAL_HISTORY_MAX = 16

local function _hist(mon)
    _special_history[mon] = _special_history[mon] or { stack = {}, idx = 0 }
    return _special_history[mon]
end

local function _push_history(mon, name)
    local h = _hist(mon)
    -- se estamos no meio do stack (após back), trunca o "forward" antes de empurrar
    while #h.stack > h.idx do table.remove(h.stack) end
    -- dedupe: não empurra se já é o topo
    if h.stack[#h.stack] == name then return end
    table.insert(h.stack, name)
    if #h.stack > SPECIAL_HISTORY_MAX then table.remove(h.stack, 1) end
    h.idx = #h.stack
end

-- ── Helpers ──────────────────────────────────────────────────

local function active_monitor()
    return hl.get_active_monitor()
end

local function active_monitor_name()
    local m = active_monitor()
    return m and m.name or ""
end

local function active_special_name()
    -- Nome do special ativo no monitor focado, sem prefixo "special:". "" se nenhum.
    local m = active_monitor()
    local sw = m and m.specialWorkspace
    if sw and sw.name and sw.name ~= "" then
        return sw.name:gsub("^special:", "")
    end
    return ""
end

local function other_monitor(cur_name)
    for _, m in ipairs(hl.get_monitors() or {}) do
        if m.name ~= cur_name then return m end
    end
end

-- ── Clients compat ───────────────────────────────────────────
-- hl.get_clients() não existe no Hyprland 0.55 Lua. Fallback:
-- parse simples de `hyprctl clients -j` com gsub (sem json lib).
-- Retorna lista de { address, class, title, pid, focused, workspace = {id, name} }

local function _num(s) return tonumber(s) end

function get_clients_compat()
    local p = io.popen("hyprctl clients -j 2>/dev/null")
    if not p then return {} end
    local raw = p:read("*a") or ""
    p:close()

    local out = {}
    -- Cada janela é um objeto JSON top-level. Em hyprctl clients -j vêm separados por },\n{
    -- Estratégia: extrai cada bloco entre { ... } no nível raiz com depth counter.
    local depth, start = 0, nil
    for i = 1, #raw do
        local ch = raw:sub(i, i)
        if ch == "{" then
            if depth == 0 then start = i end
            depth = depth + 1
        elseif ch == "}" then
            depth = depth - 1
            if depth == 0 and start then
                local block = raw:sub(start, i)
                local addr  = block:match('"address"%s*:%s*"([^"]+)"')
                local class = block:match('"class"%s*:%s*"([^"]+)"')
                local title = block:match('"title"%s*:%s*"([^"]*)"')
                local pid   = _num(block:match('"pid"%s*:%s*(%-?%d+)'))
                local fhist = _num(block:match('"focusHistoryID"%s*:%s*(%-?%d+)'))
                -- workspace é objeto aninhado: "workspace": { "id": N, "name": "..." }
                local ws_block = block:match('"workspace"%s*:%s*(%b{})')
                local ws_id, ws_name
                if ws_block then
                    ws_id   = _num(ws_block:match('"id"%s*:%s*(%-?%d+)'))
                    ws_name = ws_block:match('"name"%s*:%s*"([^"]*)"')
                end
                if addr then
                    table.insert(out, {
                        address   = addr,
                        class     = class or "",
                        title     = title or "",
                        pid       = pid,
                        focused   = fhist == 0,
                        workspace = { id = ws_id, name = ws_name },
                    })
                end
                start = nil
            end
        end
    end
    return out
end

-- ── Workspace Switch ─────────────────────────────────────────

function workspace_switch(ws)
    if ws:sub(1, 8) == "special:" then
        local name = ws:sub(9)
        local mon = active_monitor_name()
        _last_special_ws[mon] = name
        _push_history(mon, name)
        local was_active = active_special_name() == name
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        if was_active then hl.exec_cmd("pkill -x rofi") end
    else
        hide_active_special_workspaces()
        hl.dispatch(hl.dsp.focus({ workspace = ws }))
    end
end

function special_back()
    local mon = active_monitor_name()
    local h = _hist(mon)
    if h.idx <= 1 then return end
    h.idx = h.idx - 1
    local target = h.stack[h.idx]
    if not target then return end
    hide_active_special_workspaces()
    hl.dispatch(hl.dsp.workspace.toggle_special(target))
    _last_special_ws[mon] = target
end

function special_forward()
    local mon = active_monitor_name()
    local h = _hist(mon)
    if h.idx >= #h.stack then return end
    h.idx = h.idx + 1
    local target = h.stack[h.idx]
    if not target then return end
    hide_active_special_workspaces()
    hl.dispatch(hl.dsp.workspace.toggle_special(target))
    _last_special_ws[mon] = target
end

function toggle_last_special_workspace()
    local last = _last_special_ws[active_monitor_name()]
    if last and last ~= "" then
        hl.dispatch(hl.dsp.workspace.toggle_special(last))
    end
end

function hide_active_special_workspaces()
    local name = active_special_name()
    if name ~= "" then
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        hl.exec_cmd("pkill -x rofi")
    end
end

-- Alias usado pelo bindr SUPER (release)
toggle_or_hide_special_workspace = hide_active_special_workspaces

-- ── Colresize sem wrap ────────────────────────────────────────
-- Para no mínimo (0.22) e máximo (0.85) em vez de cyclar

function colresize_no_wrap(direction)
    local win = hl.get_active_window()
    local mon = active_monitor()

    if win and mon and win.size and win.size[1] and mon.width and mon.scale then
        local ratio = win.size[1] / (mon.width / mon.scale)
        if direction == "+" and ratio >= 0.85 then return end
        if direction == "-" and ratio <= 0.22 then return end
    end

    hl.dispatch(hl.dsp.layout("colresize " .. direction .. "conf"))
end

-- ── Waybar + Quickshell ───────────────────────────────────────

function waybar_refresh()
    hl.exec_cmd("pkill waybar")
    hl.exec_cmd("uwsm app -- waybar --config ~/.config/waybar/config.jsonc --style ~/.config/waybar/style.css")
    hl.exec_cmd("pkill bongocat")
    hl.exec_cmd([[sh -c '[ "$(cat /sys/class/power_supply/ADP0/online 2>/dev/null)" = "1" ] && uwsm app -- bongocat --config ~/.config/bongocat/bongocat.conf || true']])
end

function quickshell_restart()
    hl.exec_cmd("pkill quickshell")
    hl.timer(function() hl.exec_cmd("uwsm app -- qs") end, { timeout = 300, type = "oneshot" })
end

-- ── Clipboard ─────────────────────────────────────────────────

function clipboard_history()
    hl.exec_cmd([[uwsm app -- alacritty --class='clipboard-history-popup,clipboard-history-popup' --title='Clipboard History' -o window.dimensions.columns=120 -o window.dimensions.lines=30 -e sh -c 'cliphist list | fzf --preview "echo {} | cliphist decode" --preview-window=right:50%:wrap --layout=reverse --prompt="Clipboard History: " --bind "enter:execute(echo {} | cliphist decode | wl-copy)+abort"']])
end

-- ── Screenshots ───────────────────────────────────────────────

function print_screen_to_clipboard()
    hl.exec_cmd([[sh -c '
        mkdir -p ~/Pictures/Screenshots
        out=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png
        region=$(slurp) || exit 0
        grim -g "$region" "$out" && wl-copy --type image/png < "$out" &
        notify-send -a Screenshot "Capturado" "Copiado para clipboard" -u low
    ']])
end

function print_screen_with_notes()
    hl.exec_cmd([[sh -c '
        mkdir -p ~/Pictures/printscreens
        grim -g "$(slurp)" - | satty -f - --early-exit --fullscreen --copy-command wl-copy --init-tool highlight --annotation-size-factor 0.5 --output-filename ~/Pictures/printscreens/$(date +%Y%m%d_%H%M%S).png
    ']])
end

function print_screen_full_then_crop()
    local mon = active_monitor_name()
    hl.exec_cmd(string.format([[sh -c '
        mkdir -p ~/Pictures/printscreens
        tmp=$(mktemp /tmp/screenshot_XXXXXX.png)
        grim -o %s "$tmp" && satty -f "$tmp" --early-exit --fullscreen --copy-command wl-copy --init-tool crop --annotation-size-factor 0.5 --output-filename ~/Pictures/printscreens/$(date +%%Y%%m%%d_%%H%%M%%S).png
        rm -f "$tmp"
    ']], mon))
end

function tesseract_region()
    hl.exec_cmd([[sh -c '
        text=$(grim -g "$(slurp)" - | tesseract stdin stdout -l eng 2>/dev/null)
        if [ -n "$text" ]; then
            printf "%s" "$text" | wl-copy
            notify-send -a OCR "Texto extraído" "$text" -u low
        else
            notify-send -a OCR "OCR falhou" "Nenhum texto detectado" -u low
        fi
    ']])
end

-- ── Monitor switching ─────────────────────────────────────────

function move_special_workspace_to_monitor()
    local active = active_special_name()
    if active == "" then
        hl.exec_cmd("notify-send Hyprland 'No special workspace visible' -u low")
        return
    end

    local next_mon = other_monitor(active_monitor_name())
    if not next_mon then return end

    hl.dispatch(hl.dsp.workspace.toggle_special(active))
    hl.dispatch(hl.dsp.focus({ monitor = next_mon.name }))
    hl.dispatch(hl.dsp.workspace.toggle_special(active))
end

function move_normal_workspace_to_monitor()
    local next_mon = other_monitor(active_monitor_name())
    if not next_mon then return end

    hl.dispatch(hl.dsp.focus({ monitor = next_mon.name }))
    if next_mon.activeWorkspace then
        hl.dispatch(hl.dsp.focus({ workspace = tostring(next_mon.activeWorkspace.id) }))
    end
end

-- ── Reload ───────────────────────────────────────────────────

function hypr_reload()
    hl.exec_cmd("swaync-client -rs -R")
    waybar_refresh()
    quickshell_restart()
    hl.exec_cmd("hyprctl reload")
    hl.exec_cmd("notify-send 'Hyprland reloaded' -u low")
end
