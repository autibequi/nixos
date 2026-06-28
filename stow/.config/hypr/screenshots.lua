-- ============================================================
--  SCREENSHOTS — legado / referência
--
--  SUPER+U → print_screen_to_clipboard (região → clipboard direto)
--  SUPER+SHIFT+U → walker-screenshot.sh → menus:screenshot
-- ============================================================

local function active_monitor_name()
    local m = hl.get_active_monitor()
    return m and m.name or ""
end

-- Mantidas para compat; preferir walker-screenshot.sh + menus:screenshot
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
