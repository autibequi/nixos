Name = "shortcuts"
NamePretty = "Shortcuts"
Icon = "input-keyboard"
Description = "Hyprland keybind cheatsheet"
SearchName = true
Cache = false
FixedOrder = true
HideFromProviderlist = true

-- Dump gerado por show_shortcuts() (hypr/ui/hyprshortcuts.lua) a cada SUPER+/.
local TSV = os.getenv("HOME") .. "/.cache/hypr-shortcuts.tsv"
local EXEC = os.getenv("HOME") .. "/.config/hypr/scripts/walker-shortcut-exec.sh"

function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function GetEntries()
  local f = io.open(TSV, "r")
  if not f then
    return {
      {
        Text = "Cheatsheet não gerado",
        Subtext = "abra via SUPER+/ (gera o dump antes do walker)",
        Icon = "dialog-warning",
      },
    }
  end

  local entries = {}
  for line in f:lines() do
    local group, combo, desc = line:match("^([^\t]*)\t([^\t]*)\t(.*)$")
    if combo and combo ~= "" then
      table.insert(entries, {
        Text = (desc ~= "" and desc) or combo,
        Subtext = string.format("[%s]  %s", group, combo),
        Value = combo,
        Icon = "input-keyboard-symbolic",
        Actions = { activate = EXEC .. " " .. quote(combo) },
      })
    end
  end
  f:close()
  return entries
end
