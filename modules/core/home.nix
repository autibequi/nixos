{ pkgs, inputs, ... }:
let
  anyrunPkg = inputs.anyrun.packages.${pkgs.system}.anyrun-with-all-plugins;
  pluginDir = "${anyrunPkg}/lib/anyrun";
in
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

      # anyrun config com paths absolutos do nix store (bare filenames não funcionam no NixOS)
      xdg.configFile."anyrun/config.ron".text = ''
        Config(
          x: Fraction(0.5),
          y: Fraction(0.5),
          width: Absolute(700),
          height: Absolute(500),
          hide_icons: false,
          ignore_exclusive_zones: true,
          layer: Top,
          hide_plugin_info: false,
          close_on_click: true,
          show_results_immediately: true,
          max_entries: Some(10),
          plugins: [
            "${pluginDir}/libapplications.so",
            "${pluginDir}/libwebsearch.so",
            "${pluginDir}/librink.so",
            "${pluginDir}/libshell.so",
            "${pluginDir}/libsymbols.so",
            "${pluginDir}/libtranslate.so",
            "${pluginDir}/libdictionary.so",
          ],
          border_radius: Some(12),
          shadow: Some(false),
          opacity: Some(1.0),
        )
      '';

      # Profile-Sync-Daemon: monta perfil do Chrome em tmpfs (RAM)
      services.psd = {
        enable = true;
        resyncTimer = "30min";
      };

      # Corrige erro de caractere reservado no campo Exec (desktop spec)
      xdg.desktopEntries."obsidian-work" = {
        name = "Obsidian (Work)";
        comment = "Obsidian como aplicativo web";
        exec = "xdg-open \"obsidian://open?vault=Work\"";
        icon = "obsidian";
        type = "Application";
        categories = [
          "Office"
          "TextEditor"
        ];
      };

      xdg.desktopEntries."obsidian-personal" = {
        name = "Journal (Obsidian)";
        comment = "Obsidian como aplicativo web";
        exec = "xdg-open \"obsidian://open?vault=books\"";
        icon = "obsidian";
        type = "Application";
        categories = [
          "Office"
          "TextEditor"
        ];
      };
    };
}
