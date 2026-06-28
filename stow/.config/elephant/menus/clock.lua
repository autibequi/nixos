Name = "clock"
NamePretty = "Relógio"
Icon = "clock-symbolic"
Description = "Data, hora e calendário"
SearchName = false
Cache = false
FixedOrder = true
HideFromProviderlist = true

function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function locale_date(fmt, fallback_fmt)
  os.setlocale("pt_BR.UTF-8", "time")
  local out = trim(os.date(fmt))
  if out == "" and fallback_fmt then
    out = trim(os.date(fallback_fmt))
  end
  return out
end

function GetEntries()
  local long_date = locale_date("%A, %d de %B", "%A, %d %B")
  local time = os.date("%H:%M")
  local iso = os.date("%Y-%m-%d")
  local year = os.date("%Y")

  local q_iso = quote(iso)
  local q_time = quote(time)

  return {
    {
      Text = long_date,
      Subtext = time .. " · " .. year,
      Icon = "clock-symbolic",
      Actions = {
        activate = "sh -c 'printf \"%s\" \"$(date \"+%Y-%m-%d %H:%M\")\" | wl-copy && notify-send -a Relógio \"Copiado\" \"Data e hora\" -u low'",
      },
    },
    {
      Text = "Calendário",
      Subtext = "Quickshell · scroll",
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
