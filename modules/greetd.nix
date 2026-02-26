{ config, pkgs, ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --remember-session \
            --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions \
            --xsessions ${config.services.displayManager.sessionData.desktops}/share/xsessions \
            --greeting "AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH"
        '';
        user = "greeter";
      };
    };
  };
}
