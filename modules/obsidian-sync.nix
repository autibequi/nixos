{ pkgs, ... }:
let
  user = "pedrinho";
  vaultPath = "/home/${user}/.ovault";
  npmPrefix = "/home/${user}/.npm-global";
  nodejs = pkgs.nodejs_22;

  syncScript = pkgs.writeShellScript "obsidian-sync" ''
    set -euo pipefail
    export PATH="${nodejs}/bin:${npmPrefix}/bin:$PATH"
    export NPM_CONFIG_PREFIX="${npmPrefix}"

    echo "[obsidian-sync] Iniciando sync contínuo: ${vaultPath}"
    exec ob sync --continuous --path "${vaultPath}"
  '';
in {
  # Instala obsidian-headless no switch
  system.activationScripts.obsidian-headless = {
    text = ''
      echo "[activation] Instalando obsidian-headless..."
      su ${user} -s /bin/sh -c '
        export PATH="${nodejs}/bin:$PATH"
        export NPM_CONFIG_PREFIX="${npmPrefix}"
        mkdir -p ${npmPrefix}
        ${nodejs}/bin/npm install -g obsidian-headless 2>&1 | tail -1
      '
    '';
  };

  systemd.services.obsidian-sync = {
    description = "Obsidian Sync headless (continuous)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      User = user;
      Group = "users";

      ExecStart = "${syncScript}";

      Restart = "on-failure";
      RestartSec = "15s";

      # Credenciais do `ob login` ficam em ~/.config/obsidian-headless/
      Environment = [
        "HOME=/home/${user}"
        "XDG_CONFIG_HOME=/home/${user}/.config"
        "NODE_ENV=production"
      ];
    };

    wantedBy = [ "multi-user.target" ];
  };
}
