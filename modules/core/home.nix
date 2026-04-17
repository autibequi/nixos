{ pkgs, inputs, ... }:
{
  # avoid file colisions
  home-manager.backupFileExtension = "backup";

  users.defaultUserShell = pkgs.zsh;

  # it's a me, pedrinho! o-ho!
  home-manager.users."pedrinho" =
    { ... }:
    {
      home.stateVersion = "25.11";
      home.enableNixpkgsReleaseCheck = false;

      # Profile-Sync-Daemon: monta perfil do Chrome em tmpfs (RAM)
      services.psd = {
        enable = true;
        resyncTimer = "30min";
      };

      # Ícone no tray do Waybar (StatusNotifierItem) — requer tailscaled (services.tailscale.enable)
      systemd.user.services.tailscale-systray = {
        Unit = {
          Description = "Tailscale status icon (systray)";
          After = [ "graphical-session-pre.target" ];
        };
        Service = {
          ExecStart = "${pkgs.tailscale}/bin/tailscale systray";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
