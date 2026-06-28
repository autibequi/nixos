Name = "wifi"
NamePretty = "Wi-Fi"
Icon = "network-wireless"
Description = "Manage Wi-Fi networks"
SearchName = true
Cache = false
FixedOrder = true

Actions = {
  rescan = "lua:Rescan",
}

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

function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local HYPR = os.getenv("HOME") .. "/.config/hypr"
local WIFI_CONNECT = HYPR .. "/walker-wifi-connect.sh"

function signal_icon(signal)
  if signal >= 75 then
    return "network-wireless-signal-excellent"
  end
  if signal >= 55 then
    return "network-wireless-signal-good"
  end
  if signal >= 35 then
    return "network-wireless-signal-ok"
  end
  if signal >= 15 then
    return "network-wireless-signal-weak"
  end
  return "network-wireless-signal-none"
end

function Rescan()
  os.execute("nmcli device wifi rescan >/dev/null 2>&1")
  os.execute("notify-send Wi-Fi Rescanning networks")
end

function GetEntries()
  local entries = {}

  local wifi_on = trim(sh("nmcli radio wifi 2>/dev/null")) == "enabled"
  table.insert(entries, {
    Text = wifi_on and "Disable Wi-Fi" or "Enable Wi-Fi",
    Subtext = wifi_on and "turn radio off" or "turn radio on",
    Icon = wifi_on and "network-wireless-disabled" or "network-wireless",
    Actions = { activate = wifi_on and "nmcli radio wifi off" or "nmcli radio wifi on" },
  })

  table.insert(entries, {
    Text = "Rescan",
    Subtext = "refresh nearby networks",
    Icon = "view-refresh",
    Actions = { activate = "lua:Rescan" },
  })

  if not wifi_on then
    return entries
  end

  local active = sh("nmcli -t -f NAME,TYPE,DEVICE,STATE connection show --active 2>/dev/null")
  for line in active:gmatch("[^\n]+") do
    local name, typ, device, state = line:match("([^:]+):([^:]+):([^:]+):([^:]+)")
    if typ == "802-3-ethernet" and state == "activated" then
      table.insert(entries, {
        Text = name,
        Subtext = device .. " · wired · connected",
        Icon = "network-wired",
      })
    end
  end

  os.execute("nmcli device wifi rescan >/dev/null 2>&1 &")

  local raw = sh("nmcli -t -e no -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null")
  local best = {}

  for line in raw:gmatch("[^\n]+") do
    local inuse, ssid, signal, sec = line:match("^([^:]*):([^:]*):([^:]*):(.*)$")
    if ssid and ssid ~= "" then
      local sig = tonumber(signal) or 0
      local active_ap = (inuse == "*")
      if not best[ssid] or sig > best[ssid].signal or (active_ap and not best[ssid].active) then
        best[ssid] = {
          signal = sig,
          sec = (sec ~= "" and sec or "open"),
          active = active_ap,
        }
      end
    end
  end

  local networks = {}
  for ssid, info in pairs(best) do
    table.insert(networks, { ssid = ssid, info = info })
  end

  table.sort(networks, function(a, b)
    if a.info.active ~= b.info.active then
      return a.info.active
    end
    return a.info.signal > b.info.signal
  end)

  for _, item in ipairs(networks) do
    local ssid = item.ssid
    local info = item.info
    local subtext = string.format("%d%% · %s", info.signal, info.sec)
    if info.active then
      subtext = subtext .. " · connected"
    end

    table.insert(entries, {
      Text = ssid,
      Subtext = subtext,
      Value = ssid,
      Icon = signal_icon(info.signal),
      Actions = {
        connect = WIFI_CONNECT .. " " .. quote(ssid),
        ask = WIFI_CONNECT .. " " .. quote(ssid) .. " --ask",
      },
    })
  end

  return entries
end
