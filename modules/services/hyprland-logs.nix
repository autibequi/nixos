{ ... }:
let
  user = "pedrinho";
  logDir = "/home/${user}/nixos/logs";
in
{
  # Serviço que exporta logs de apps Hyprland custom para uma pasta
  # acessível de dentro do container Claude (/workspace/host/logs/).
  # Apps devem logar via: logger -t hyprland-custom "mensagem"
  # ou: echo "..." >> /home/pedrinho/nixos/logs/custom.log
  systemd.user.services.hyprland-log-export = {
    description = "Exporta logs de apps Hyprland custom para ${logDir}";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${logDir}";
      # Segue logs do journal tagged 'hyprland-custom', 'rofi', 'waybar-custom'
      ExecStart = "/run/current-system/sw/bin/sh -c 'journalctl --user --follow --output=short --no-pager -t hyprland-custom -t rofi-launch >> ${logDir}/hyprland.log 2>&1'";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
