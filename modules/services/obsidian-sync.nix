{ pkgs, ... }:
let
  user = "pedrinho";
  indicatorPython = pkgs.python3.withPackages (ps: [ ps.pystray ps.pillow ]);
  indicatorScript = "/home/${user}/.config/obsidian-sync-indicator/indicator.py";
  indicatorGiPath = pkgs.lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.gtk3
    pkgs.glib
    pkgs.gdk-pixbuf
    pkgs.pango
    pkgs.libayatana-appindicator
  ];
  vaultPath = "/home/${user}/.ovault";
  npmPrefix = "/home/${user}/.npm-global";
  nodejs = pkgs.nodejs_22;

  installScript = pkgs.writeShellScript "obsidian-headless-install" ''
    export PATH="${nodejs}/bin:$PATH"
    export NPM_CONFIG_PREFIX="${npmPrefix}"
    mkdir -p ${npmPrefix}

    if [ ! -x "${npmPrefix}/bin/ob" ]; then
      echo "[obsidian-sync] Instalando obsidian-headless..."
      ${nodejs}/bin/npm install -g obsidian-headless
    fi
  '';

  syncScript = pkgs.writeShellScript "obsidian-sync" ''
    set -euo pipefail
    export PATH="${nodejs}/bin:${npmPrefix}/bin:$PATH"
    export NPM_CONFIG_PREFIX="${npmPrefix}"

    mkdir -p "${vaultPath}"
    echo "[obsidian-sync] Iniciando sync contínuo: ${vaultPath}"
    exec ob sync --continuous --path "${vaultPath}"
  '';
in {
  systemd.services.obsidian-sync = {
    description = "Obsidian Sync headless (continuous)";
    # Só depende de rede — graphical.target aqui causava ordering cycle:
    #   obsidian-sync → graphical → multi-user → obsidian-sync
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      User = user;
      Group = "users";

      ExecStartPre = "${installScript}";
      ExecStart = "${syncScript}";

      Restart = "on-failure";
      RestartSec = "15s";

      Environment = [
        "HOME=/home/${user}"
        "XDG_CONFIG_HOME=/home/${user}/.config"
        "NODE_ENV=production"
      ];
    };

    wantedBy = [ "multi-user.target" ];
  };

  systemd.user.services.obsidian-sync-indicator = {
    description = "Obsidian Sync status indicator (system tray)";
    after = [ "graphical-session-pre.target" ];
    wantedBy = [ "graphical-session.target" ];
    environment = {
      GI_TYPELIB_PATH = indicatorGiPath;
    };
    serviceConfig = {
      ExecStart = "${indicatorPython}/bin/python3 ${indicatorScript}";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
