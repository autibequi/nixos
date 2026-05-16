-- ============================================================
--  UTILS — portado de hyprutils.sh
--  Usa APIs nativas do Hyprland 0.55 Lua onde possível
-- ============================================================

-- ── State em memória (substitui arquivos ~/.cache/hyprland/) ─
-- Perdido em reload — aceitável (mesmo comportamento de arquivos em /tmp em novos boots)
local _last_special_ws = {}  -- { monitor_name = ws_name }

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

-- ── Workspace Switch ─────────────────────────────────────────

function workspace_switch(ws)
    if ws:sub(1, 8) == "special:" then
        local name = ws:sub(9)
        _last_special_ws[active_monitor_name()] = name
        local was_active = active_special_name() == name
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        if was_active then hl.exec_cmd("pkill -x rofi") end
    else
        hide_active_special_workspaces()
        hl.dispatch(hl.dsp.focus({ workspace = ws }))
    end
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
