Name = "shaders"
NamePretty = "Shaders"
Icon = "preferences-desktop-display"
Description = "Hyprshade screen shaders"
SearchName = true
Cache = false
FixedOrder = true
HideFromProviderlist = true

function sh(cmd)
  local handle = io.popen(cmd)
  if not handle then
    return ""
  end
  local out = handle:read("*a")
  handle:close()
  return out or ""
end

function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- hyprshade só fornece os .glsl; aplicar é via shader-set.sh (hyprctl eval)
local SET = os.getenv("HOME") .. "/.config/hypr/shader-set.sh"

function GetEntries()
  local current = trim(sh(SET .. " current 2>/dev/null"))

  local entries = {
    {
      Text = "Nenhum shader",
      Subtext = current == "" and "ativo agora" or "desliga o shader",
      Icon = "window-close-symbolic",
      Actions = { activate = SET .. " off" },
    },
  }

  -- lista .glsl direto do filesystem (`hyprshade ls` engasga com shader ativo
  -- setado fora dele); mesmos dirs que o shader-set.sh resolve
  local raw = sh([[find "$HOME/.config/hyprshade/shaders" "$HOME/.config/hypr/shaders" "$(dirname "$(dirname "$(readlink -f "$(command -v hyprshade)")")")/share/hyprshade/shaders" -name '*.glsl' 2>/dev/null | sort]])
  local seen = {}
  for path in raw:gmatch("[^\n]+") do
    local name = path:match("([^/]+)%.glsl$")
    if name and not seen[name] then
      seen[name] = true
      table.insert(entries, {
        Text = name,
        Subtext = name == current and "ativo agora" or "ativar",
        Icon = name == current and "object-select-symbolic" or "preferences-desktop-display",
        Value = name,
        Actions = { activate = SET .. " " .. name },
      })
    end
  end

  return entries
end
