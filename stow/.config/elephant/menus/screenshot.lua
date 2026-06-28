Name = "screenshot"
NamePretty = "Screenshot"
Icon = "camera-photo"
Description = "Ação após captura de região"
SearchName = false
Cache = true
FixedOrder = true
HideFromProviderlist = true

local HOME = os.getenv("HOME")
local IMG = HOME .. "/.cache/hyprland/screenshot-pending.png"
local SHOTS = HOME .. "/Pictures/Screenshots"
local PRINTS = HOME .. "/Pictures/printscreens"

function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function GetEntries()
  local q = quote(IMG)
  local out_shot = quote(SHOTS .. "/$(date +%Y%m%d_%H%M%S).png")
  local out_print = quote(PRINTS .. "/$(date +%Y%m%d_%H%M%S).png")

  return {
    {
      Text = "Copiar",
      Icon = "edit-copy",
      Actions = {
        activate = "wl-copy --type image/png < " .. q .. " && notify-send -a Screenshot Capturado 'Copiado para clipboard' -u low",
      },
    },
    {
      Text = "Salvar",
      Icon = "document-save",
      Actions = {
        activate = "cp " .. q .. " " .. out_shot .. " && notify-send -a Screenshot Salvo 'Pictures/Screenshots' -u low",
      },
    },
    {
      Text = "Anotar",
      Icon = "draw-brush",
      Actions = {
        activate = "satty -f " .. q .. " --early-exit --fullscreen --copy-command wl-copy --init-tool highlight --annotation-size-factor 0.5 --output-filename " .. out_print,
      },
    },
    {
      Text = "OCR",
      Icon = "font-select",
      Actions = {
        activate = "sh -c 'text=$(tesseract " .. q .. " stdout -l eng 2>/dev/null); if [ -n \"$text\" ]; then printf \"%s\" \"$text\" | wl-copy; notify-send -a OCR \"Texto extraído\" \"$text\" -u low; else notify-send -a OCR \"OCR falhou\" \"Nenhum texto detectado\" -u low; fi'",
      },
    },
  }
end
