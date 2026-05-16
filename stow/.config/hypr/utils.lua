-- ============================================================
--  UTILS — portado de hyprutils.sh
--  Usa APIs nativas do Hyprland 0.55 Lua onde possível
-- ============================================================

local HOME = os.getenv("HOME")

-- ── State em memória (substitui arquivos ~/.cache/hyprland/) ─
-- Perdido em reload — comportamento aceitável (era o mesmo com arquivos em /tmp em novos boots)
local _last_special_ws = {}  -- { monitor_name = ws_name }

-- ── Helpers ──────────────────────────────────────────────────

local function focused_monitor_name()
    local m = hl.get_active_monitor()
    return m and m.name or ""
end

local function active_special_name()
    -- Retorna o nome do special workspace ativo no monitor focado (sem prefixo "special:").
    -- Retorna "" se nenhum special estiver visível.
    local m = hl.get_active_monitor()
    if not m then return "" end
    local sw = m.specialWorkspace
    if sw and sw.name and sw.name ~= "" then
        return sw.name:gsub("^special:", "")
    end
    return ""
end

-- ── Workspace Switch ─────────────────────────────────────────

function workspace_switch(ws)
    local monitor = focused_monitor_name()

    if ws:sub(1, 8) == "special:" then
        local name = ws:sub(9)
        _last_special_ws[monitor] = name
        local active = active_special_name()
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        -- Se estava visível → foi escondido → fecha rofi para não ficar pendurado
        if active == name then
            hl.exec_cmd("pkill -x rofi")
        end
    else
        hide_active_special_workspaces()
        hl.dispatch(hl.dsp.focus({ workspace = ws }))
    end
end

function toggle_last_special_workspace()
    local monitor = focused_monitor_name()
    local last = _last_special_ws[monitor]
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

-- Chamado pelo bind SUPER (release) — apenas oculta sem reabrir
function toggle_or_hide_special_workspace()
    hide_active_special_workspaces()
end

-- ── Focus sem wrap ────────────────────────────────────────────
-- Não vai para outro monitor — para na coluna mais à esquerda/direita

function focus_no_wrap(direction)
    local ok, win = pcall(hl.get_active_window)
    if not ok or not win or not win.at then
        hl.dispatch(hl.dsp.layout("focus " .. direction))
        return
    end

    local ws_id = win.workspace and win.workspace.id
    local win_x = win.at[1] or 0

    local ok2, windows = pcall(hl.get_windows)
    if not ok2 or type(windows) ~= "table" then
        hl.dispatch(hl.dsp.layout("focus " .. direction))
        return
    end

    local count = 0
    for _, w in ipairs(windows) do
        local wx = w.at and w.at[1]
        if wx and w.workspace and w.workspace.id == ws_id then
            if direction == "r" and wx > win_x then count = count + 1
            elseif direction ~= "r" and wx < win_x then count = count + 1
            end
        end
    end

    if count == 0 then return end
    hl.dispatch(hl.dsp.layout("focus " .. direction))
end

-- ── Colresize sem wrap ────────────────────────────────────────
-- Para no mínimo (0.2) e máximo (0.85) em vez de cyclar

function colresize_no_wrap(direction)
    local ok1, win = pcall(hl.get_active_window)
    local ok2, mon = pcall(hl.get_active_monitor)

    -- só aplica no-wrap se conseguir ler tamanho da janela E do monitor
    if ok1 and ok2 and win and mon and win.size and win.size[1] and mon.width and mon.scale then
        local ratio = (win.size[1]) / (mon.width / mon.scale)
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
    -- bongocat só sobe se AC estiver conectado
    hl.exec_cmd("sh -c '[ -f /sys/class/power_supply/ADP0/online ] && [ \"$(cat /sys/class/power_supply/ADP0/online)\" = \"1\" ] && uwsm app -- bongocat --config ~/.config/bongocat/bongocat.conf || true'")
end

function quickshell_restart()
    hl.exec_cmd("pkill quickshell")
    hl.timer(function()
        hl.exec_cmd("uwsm app -- qs")
    end, { timeout = 300, type = "oneshot" })
end

-- ── Clipboard ─────────────────────────────────────────────────

function clipboard_history()
    hl.exec_cmd("uwsm app -- alacritty" ..
        " --class='clipboard-history-popup,clipboard-history-popup'" ..
        " --title='Clipboard History'" ..
        " -o window.dimensions.columns=120" ..
        " -o window.dimensions.lines=30" ..
        " -e sh -c 'cliphist list | fzf" ..
        " --preview \"echo {} | cliphist decode\"" ..
        " --preview-window=right:50%:wrap" ..
        " --layout=reverse" ..
        " --prompt=\"Clipboard History: \"" ..
        " --bind \"enter:execute(echo {} | cliphist decode | wl-copy)+abort\"'")
end

-- ── Screenshots ───────────────────────────────────────────────

function print_screen_to_clipboard()
    hl.exec_cmd("sh -c '" ..
        "mkdir -p ~/Pictures/Screenshots &&" ..
        "outfile=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png &&" ..
        "region=$(slurp) || exit 0 &&" ..
        "grim -g \"$region\" \"$outfile\" &&" ..
        "wl-copy --type image/png < \"$outfile\" &" ..
        "notify-send -a Screenshot Capturado \"Copiado para clipboard\" -u low" ..
        "'")
end

function print_screen_with_notes()
    hl.exec_cmd("sh -c '" ..
        "mkdir -p ~/Pictures/printscreens &&" ..
        "grim -g \"$(slurp)\" - |" ..
        "satty -f - --early-exit --fullscreen --copy-command wl-copy" ..
        " --init-tool highlight --annotation-size-factor 0.5" ..
        " --output-filename ~/Pictures/printscreens/$(date +%Y%m%d_%H%M%S).png" ..
        "'")
end

function print_screen_full_then_crop()
    local mon = hl.get_active_monitor()
    local mon_name = mon and mon.name or ""
    hl.exec_cmd("sh -c '" ..
        "mkdir -p ~/Pictures/printscreens &&" ..
        "tmp=$(mktemp /tmp/screenshot_XXXXXX.png) &&" ..
        "grim -o " .. mon_name .. " $tmp &&" ..
        "satty -f $tmp --early-exit --fullscreen --copy-command wl-copy" ..
        " --init-tool crop --annotation-size-factor 0.5" ..
        " --output-filename ~/Pictures/printscreens/$(date +%Y%m%d_%H%M%S).png &&" ..
        "rm -f $tmp" ..
        "'")
end

function tesseract_region()
    hl.exec_cmd("sh -c '" ..
        "text=$(grim -g \"$(slurp)\" - | tesseract stdin stdout -l eng 2>/dev/null) &&" ..
        "[ -n \"$text\" ] &&" ..
        "printf \"%s\" \"$text\" | wl-copy &&" ..
        "notify-send -a OCR \"Texto extraído\" \"$text\" -u low ||" ..
        "notify-send -a OCR \"OCR falhou\" \"Nenhum texto detectado\" -u low" ..
        "'")
end

-- ── Monitor switching ─────────────────────────────────────────

function move_special_workspace_to_monitor()
    local active = active_special_name()
    if active == "" then
        hl.exec_cmd("notify-send Hyprland 'No special workspace visible' -u low")
        return
    end

    local cur = hl.get_active_monitor()
    local monitors = hl.get_monitors()
    local next_mon = nil
    for _, m in ipairs(monitors) do
        if m.name ~= (cur and cur.name) then
            next_mon = m
            break
        end
    end
    if not next_mon then return end

    hl.dispatch(hl.dsp.workspace.toggle_special(active))
    hl.dispatch(hl.dsp.focus({ monitor = next_mon.name }))
    hl.dispatch(hl.dsp.workspace.toggle_special(active))
end

function move_normal_workspace_to_monitor()
    local cur = hl.get_active_monitor()
    local monitors = hl.get_monitors()
    local next_mon = nil
    for _, m in ipairs(monitors) do
        if m.name ~= (cur and cur.name) then
            next_mon = m
            break
        end
    end
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
