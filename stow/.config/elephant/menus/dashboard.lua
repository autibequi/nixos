Name = "dashboard"
NamePretty = "Dashboard"
Icon = "view-grid-symbolic"
Description = "Status do sistema"
SearchName = false
Cache = false
FixedOrder = true
HideFromProviderlist = true

local CACHE = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
local CACHE_FILE = CACHE .. "/elephant/dash-status.cache"
local CACHE_SCRIPT = os.getenv("HOME") .. "/.config/hypr/walker-dash-cache.sh"

function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function locale_short()
  os.setlocale("pt_BR.UTF-8", "time")
  local out = trim(os.date("%A, %d %b"))
  if out == "" then
    out = trim(os.date("%A, %d %b"))
  end
  return out
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

function GetEntries()
  local cache = load_cache()
  maybe_refresh_cache(cache)

  local time = os.date("%H:%M")
  local date = locale_short()
  local status = "…"
  if cache and cache.status and cache.status ~= "" then
    status = cache.status
  end

  return {
    {
      Text = time .. "  ·  " .. date,
      Subtext = status,
      Icon = "clock-symbolic",
      Actions = { activate = "qs ipc call clock toggle" },
    },
  }
end
