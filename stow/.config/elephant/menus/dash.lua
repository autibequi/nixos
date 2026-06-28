Name = "dash"
NamePretty = "Dash"
Icon = "view-grid-symbolic"
Description = "Hub · ferramentas e status"
SearchName = false
Cache = false
FixedOrder = true
HideFromProviderlist = true

local LAUNCHER = os.getenv("HOME") .. "/.config/hypr/walker-launch.sh"
local NIXOS = os.getenv("HOME") .. "/nixos"
local SCREENSHOT = os.getenv("HOME") .. "/.config/hypr/walker-screenshot.sh"
local CACHE = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
local CACHE_FILE = CACHE .. "/elephant/dash-status.cache"
local CACHE_SCRIPT = os.getenv("HOME") .. "/.config/hypr/walker-dash-cache.sh"

function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function sh(cmd)
  local handle = io.popen("timeout 0.45 sh -c " .. quote(cmd) .. " 2>/dev/null")
  if not handle then
    return ""
  end
  local out = handle:read("*a") or ""
  handle:close()
  return trim(out)
end

function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function load_cache()
  local f = io.open(CACHE_FILE, "r")
  if not f then
    return nil
  end
  local data = {}
  for line in f:lines() do
    local k, v = line:match("^([^=]+)=(.*)$")
    if k then
      data[k] = v
    end
  end
  f:close()
  return data
end

function cache_age(data)
  if not data or not data.ts then
    return nil
  end
  local ts = tonumber(data.ts)
  if not ts then
    return nil
  end
  return os.time() - ts
end

function maybe_refresh_cache(data)
  local age = cache_age(data)
  if age == nil or age > 20 then
    os.execute("nohup " .. CACHE_SCRIPT .. " >/dev/null 2>&1 &")
  end
end

function cached_or(key, fallback_fn)
  local cache = load_cache()
  if cache and cache[key] and cache[key] ~= "" then
    return cache[key]
  end
  return fallback_fn()
end

function locale_short()
  os.setlocale("pt_BR.UTF-8", "time")
  local out = trim(os.date("%A, %d %b"))
  if out == "" then
    out = trim(os.date("%A, %d %b"))
  end
  return out
end

function wifi_line()
  return cached_or("wifi", function()
    if sh("nmcli radio wifi") ~= "enabled" then
      return "Wi‑Fi desligado"
    end
    local ssid = sh([[nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="802-11-wireless"{print $1; exit}']])
    if ssid == "" then
      return "Wi‑Fi · sem rede"
    end
    return "Wi‑Fi · " .. ssid
  end)
end

function bt_line()
  return cached_or("bt", function()
    if sh("bluetoothctl show | awk '/Powered/{print $2}'") ~= "yes" then
      return "BT off"
    end
    local dev = sh([[bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-]])
    if dev == "" then
      return "BT · nenhum"
    end
    if #dev > 22 then
      dev = dev:sub(1, 19) .. "…"
    end
    return "BT · " .. dev
  end)
end

function audio_line()
  return cached_or("audio", function()
    local raw = sh("wpctl get-volume @DEFAULT_AUDIO_SINK@")
    local muted = raw:find("MUTED") ~= nil
    local pct = raw:match("([%d%.]+)")
    if not pct then
      return "Áudio · —"
    end
    local n = math.floor(tonumber(pct) * 100 + 0.5)
    if muted then
      return "🔇 mudo"
    end
    return "🔊 " .. n .. "%"
  end)
end

function battery_line()
  if load_cache() and load_cache().battery and load_cache().battery ~= "" then
    return load_cache().battery
  end
  local cap = sh("cat /sys/class/power_supply/BAT0/capacity 2>/dev/null")
  if cap == "" then
    return nil
  end
  local ac = sh("cat /sys/class/power_supply/ADP0/online 2>/dev/null")
  if ac == "1" then
    return "🔌 " .. cap .. "%"
  end
  return "🔋 " .. cap .. "%"
end

function notif_line()
  local cache = load_cache()
  if cache and cache.notif and cache.notif ~= "" then
    return cache.notif
  end
  local raw = sh("swaync-client -swb")
  local n = raw:match('"text"%s*:%s*"(%d+)"')
  if n and tonumber(n) > 0 then
    return "🔔 " .. n
  end
  return nil
end

function clip_line()
  local n = sh("cliphist list 2>/dev/null | wc -l")
  n = trim(n)
  if n == "" or n == "0" then
    return "clipboard vazio"
  end
  local last = sh("cliphist list 2>/dev/null | head -1 | cut -f2-")
  if #last > 36 then
    last = last:sub(1, 33) .. "…"
  end
  return n .. " itens · " .. last
end

function window_line()
  local n = sh("hyprctl clients 2>/dev/null | grep -c '^Window'")
  n = tonumber(n) or 0
  local ws = sh("hyprctl activeworkspace -j | grep -o '\"name\":\"[^\"]*\"' | head -1 | cut -d'\"' -f4")
  if ws == "" then
    return n .. " janelas"
  end
  return n .. " janelas · ws " .. ws
end

function status_subtext()
  local cache = load_cache()
  if cache and cache.status and cache.status ~= "" then
    return cache.status
  end
  local parts = { wifi_line(), bt_line(), audio_line() }
  local bat = battery_line()
  if bat then
    table.insert(parts, bat)
  end
  local notif = notif_line()
  if notif then
    table.insert(parts, notif)
  end
  return table.concat(parts, "  ·  ")
end

function noop()
  return {
    Text = "────────",
    Subtext = "",
    Icon = "separator",
    Actions = { activate = "true" },
  }
end

function GetEntries()
  local cache = load_cache()
  maybe_refresh_cache(cache)

  local time = os.date("%H:%M")
  local date = locale_short()
  local status = status_subtext()

  return {
    {
      Text = time .. "  ·  " .. date,
      Subtext = status,
      Icon = "clock-symbolic",
      Actions = { activate = "qs ipc call clock toggle" },
    },
    {
      Text = "Calendário",
      Subtext = "painel Quickshell · scroll",
      Icon = "x-office-calendar",
      Actions = { activate = "qs ipc call clock toggle" },
    },
    noop(),
    {
      Text = "Wi‑Fi",
      Subtext = wifi_line(),
      Icon = "network-wireless",
      Actions = { activate = LAUNCHER .. " --theme neon --provider menus:wifi" },
    },
    {
      Text = "Bluetooth",
      Subtext = bt_line(),
      Icon = "preferences-system-bluetooth",
      Actions = { activate = LAUNCHER .. " --theme neon --provider bluetooth" },
    },
    {
      Text = "Áudio",
      Subtext = audio_line(),
      Icon = "audio-volume-high",
      Actions = { activate = LAUNCHER .. " --provider wireplumber" },
    },
    {
      Text = "Notificações",
      Subtext = notif_line() or "centro swaync",
      Icon = "notification-symbolic",
      Actions = { activate = "swaync-client -t -sw" },
    },
    noop(),
    {
      Text = "Clipboard",
      Subtext = clip_line(),
      Icon = "edit-copy",
      Actions = { activate = LAUNCHER .. " --provider clipboard" },
    },
    {
      Text = "Janelas",
      Subtext = window_line(),
      Icon = "window-restore",
      Actions = { activate = LAUNCHER .. " --provider windows" },
    },
    {
      Text = "Arquivos",
      Subtext = "prefixo /",
      Icon = "folder",
      Actions = { activate = LAUNCHER .. " --provider files" },
    },
    {
      Text = "Comando",
      Subtext = "prefixo >",
      Icon = "utilities-terminal",
      Actions = { activate = LAUNCHER .. " --provider runner" },
    },
    {
      Text = "Calculadora",
      Subtext = "prefixo =",
      Icon = "accessories-calculator",
      Actions = { activate = LAUNCHER .. " --provider calc" },
    },
    {
      Text = "Screenshot",
      Subtext = "região · salvar · OCR",
      Icon = "camera-photo",
      Actions = { activate = SCREENSHOT },
    },
    noop(),
    {
      Text = "Restow dotfiles",
      Subtext = "make restow",
      Icon = "view-refresh",
      Actions = { activate = "make -C " .. NIXOS .. " restow" },
    },
    {
      Text = "Reload Waybar",
      Subtext = "systemctl reload",
      Icon = "view-refresh-symbolic",
      Actions = { activate = "systemctl --user reload waybar.service" },
    },
    {
      Text = "Power",
      Subtext = "lock · suspend · reboot",
      Icon = "system-shutdown",
      Actions = { activate = LAUNCHER .. " --theme neon --provider menus:power" },
    },
  }
end
