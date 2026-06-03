{ pkgs, lib, ... }:
let
  # We point directly to 'gnugrep' instead of 'grep'
  grep = pkgs.gnugrep;
  # 1. Declare the Flatpaks you *want* on your system
  desiredFlatpaks = [
    # Zen Browser: via flake em modules/core/packages.nix
    # "com.usebottles.bottles"
    # "io.github.seadve.Kooha"
    # "net.nokyan.Resources"
    "com.stremio.Stremio"
    "dev.zed.Zed"
    "dev.zed.Zed-Preview"
    # "io.github.qwersyk.Newelle"
    # "com.github.tenderowl.frog"
    # "com.vivaldi.Vivaldi"
  ];

  # 1b. Overrides por app — quebra o sandbox de forma declarativa.
  # Cada entrada: {
  #   filesystem = [ "xdg-config" "home" ... ];   # --filesystem flags
  #   configLinks = { "zed" = "$HOME/.config/zed"; };  # symlinks dentro do dir
  #     # privado do app (~/.var/app/<id>/config/<key>) apontando pro path
  #     # do host. Necessário porque o runtime do Flatpak força XDG_CONFIG_HOME
  #     # pro dir privado e ignora --env override.
  # }
  flatpakOverrides = {
    "dev.zed.Zed" = {
      filesystem = [ "xdg-config" ];
      configLinks = {
        "zed" = "$HOME/.config/zed";
      };
    };
    "dev.zed.Zed-Preview" = {
      filesystem = [ "xdg-config" ];
      configLinks = {
        "zed" = "$HOME/.config/zed";
      };
    };
  };

  overrideLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      app: cfg:
      let
        fsFlags = lib.concatMapStringsSep " " (p: "--filesystem=${p}") (cfg.filesystem or [ ]);
        linkCmds = lib.concatStringsSep "\n" (
          lib.mapAttrsToList (sub: target: ''
            mkdir -p "$HOME/.var/app/${app}/config"
            link="$HOME/.var/app/${app}/config/${sub}"
            if [ -e "$link" ] && [ ! -L "$link" ]; then
              rm -rf "$link"
            fi
            ln -sfn "${target}" "$link"
          '') (cfg.configLinks or { })
        );
      in
      ''
        ${pkgs.flatpak}/bin/flatpak override --user ${fsFlags} ${app}
        ${linkCmds}
      ''
    ) flatpakOverrides
  );
in
{
  services.flatpak.enable = true;

  system.userActivationScripts.flatpakManagement = {
    text = ''
      # 2. Ensure the Flathub repo is added
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub \
        https://flathub.org/repo/flathub.flatpakrepo

      # 3. Get currently installed Flatpaks
      installedFlatpaks=$(${pkgs.flatpak}/bin/flatpak list --app --columns=application)

      # 4. Remove any Flatpaks that are NOT in the desired list
      for installed in $installedFlatpaks; do
        if ! echo ${toString desiredFlatpaks} | ${grep}/bin/grep -q $installed; then
          echo "Removing $installed because it's not in the desiredFlatpaks list."
          ${pkgs.flatpak}/bin/flatpak uninstall -y --noninteractive $installed
        fi
      done

      # 5. Install or re-install the Flatpaks you DO want
      for app in ${toString desiredFlatpaks}; do
        echo "Ensuring $app is installed."
        ${pkgs.flatpak}/bin/flatpak install -y flathub $app
      done

      # 6. Remove unused Flatpaks
      ${pkgs.flatpak}/bin/flatpak uninstall --unused -y

      # 7. Update all installed Flatpaks
      ${pkgs.flatpak}/bin/flatpak update -y

      # 8. Apply filesystem overrides (sandbox holes para enxergar host config)
      ${overrideLines}
    '';
  };
}
