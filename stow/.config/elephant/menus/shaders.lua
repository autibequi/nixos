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

function GetEntries()
  local current = trim(sh("hyprshade current 2>/dev/null"))

  local entries = {
    {
      Text = "Nenhum shader",
      Subtext = current == "" and "ativo agora" or "desliga o shader",
      Icon = "window-close-symbolic",
      Actions = { activate = "hyprshade off" },
    },
  }

  local raw = sh("hyprshade ls 2>/dev/null")
  for line in raw:gmatch("[^\n]+") do
    -- `hyprshade ls` marca o ativo com "* "; normaliza
    local name = trim(line:gsub("^%*", ""))
    if name ~= "" then
      table.insert(entries, {
        Text = name,
        Subtext = name == current and "ativo agora" or "ativar",
        Icon = name == current and "object-select-symbolic" or "preferences-desktop-display",
        Value = name,
        Actions = { activate = "hyprshade on " .. name },
      })
    end
  end

  return entries
end
