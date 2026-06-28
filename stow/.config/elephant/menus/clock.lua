Name = "clock"
NamePretty = "Relógio"
Icon = "clock-symbolic"
Description = "Data, hora e calendário"
SearchName = false
Cache = false
FixedOrder = true
HideFromProviderlist = true

local LC = "LC_TIME=pt_BR.UTF-8"

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

function GetEntries()
  local long_date = trim(sh(LC .. " date '+%A, %d de %B'"))
  local year = trim(sh("date '+%Y'"))
  local time = trim(sh("date '+%H:%M'"))
  local iso = trim(sh("date '+%Y-%m-%d'"))
  local month_title = trim(sh(LC .. " date '+%B %Y'"))
  local cal = trim(sh(LC .. " cal -m 2>/dev/null"))
  local tz = trim(sh("timedatectl show -p Timezone --value 2>/dev/null"))
  if tz == "" then
    tz = trim(sh("date '+%Z'"))
  end

  local q_iso = quote(iso)
  local q_time = quote(time)

  return {
    {
      Text = long_date,
      Subtext = time .. " · " .. year .. " · " .. tz,
      Icon = "clock-symbolic",
      Actions = {
        activate = "sh -c 'printf \"%s\" \"$(date \"+%Y-%m-%d %H:%M\")\" | wl-copy && notify-send -a Relógio \"Copiado\" \"Data e hora\" -u low'",
      },
    },
    {
      Text = month_title,
      Subtext = cal,
      Icon = "x-office-calendar",
      Actions = { activate = "qs ipc call clock toggle" },
    },
    {
      Text = "Copiar data",
      Subtext = iso,
      Icon = "edit-copy",
      Actions = {
        activate = "sh -c 'printf \"%s\" " .. q_iso .. " | wl-copy && notify-send -a Relógio \"Copiado\" " .. q_iso .. " -u low'",
      },
    },
    {
      Text = "Copiar hora",
      Subtext = time,
      Icon = "edit-copy",
      Actions = {
        activate = "sh -c 'printf \"%s\" " .. q_time .. " | wl-copy && notify-send -a Relógio \"Copiado\" " .. q_time .. " -u low'",
      },
    },
  }
end
