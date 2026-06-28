Name = "dash"
NamePretty = "Dash"
Icon = "view-grid-symbolic"
Description = "Ferramentas e sistema"
SearchName = false
Cache = false
FixedOrder = true
HideFromProviderlist = true

local LAUNCHER = os.getenv("HOME") .. "/.config/hypr/walker-launch.sh"
local NIXOS = os.getenv("HOME") .. "/nixos"

function GetEntries()
  return {
    {
      Text = "Wi-Fi",
      Subtext = "redes",
      Icon = "network-wireless",
      Actions = { activate = LAUNCHER .. " --theme neon --provider menus:wifi" },
    },
    {
      Text = "Bluetooth",
      Subtext = "dispositivos",
      Icon = "preferences-system-bluetooth",
      Actions = { activate = LAUNCHER .. " --theme neon --provider bluetooth" },
    },
    {
      Text = "Áudio",
      Subtext = "volume · dispositivos",
      Icon = "audio-volume-high",
      Actions = { activate = LAUNCHER .. " --provider wireplumber" },
    },
    {
      Text = "Clipboard",
      Subtext = "prefixo :",
      Icon = "edit-copy",
      Actions = { activate = LAUNCHER .. " --provider clipboard" },
    },
    {
      Text = "Janelas",
      Subtext = "prefixo w:",
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
      Text = "Restow dotfiles",
      Subtext = "make restow",
      Icon = "view-refresh",
      Actions = { activate = "make -C " .. NIXOS .. " restow" },
    },
    {
      Text = "Reload Waybar",
      Subtext = "waybar",
      Icon = "view-refresh-symbolic",
      Actions = { activate = "systemctl --user reload waybar.service" },
    },
  }
end
