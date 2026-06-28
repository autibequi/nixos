Name = "power"
NamePretty = "Power"
Icon = "system-shutdown-symbolic"
Description = "Lock, logout, suspend, shutdown"
SearchName = false
Cache = false
FixedOrder = true
HideFromProviderlist = true

function GetEntries()
  return {
    {
      Text = "Lock",
      Subtext = "hyprlock",
      Icon = "system-lock-screen",
      Actions = { activate = "hyprlock" },
    },
    {
      Text = "Logout",
      Subtext = "uwsm stop",
      Icon = "system-log-out",
      Actions = { activate = "uwsm stop" },
    },
    {
      Text = "Suspend",
      Subtext = "sleep",
      Icon = "system-sleep",
      Actions = { activate = "systemctl suspend" },
    },
    {
      Text = "Hibernate",
      Subtext = "disk",
      Icon = "system-hibernate",
      Actions = { activate = "systemctl hibernate" },
    },
    {
      Text = "Reboot",
      Subtext = "restart",
      Icon = "system-reboot",
      Actions = { activate = "systemctl reboot" },
    },
    {
      Text = "Shutdown",
      Subtext = "power off",
      Icon = "system-shutdown",
      Actions = { activate = "systemctl poweroff" },
    },
  }
end
