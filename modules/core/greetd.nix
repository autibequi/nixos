{ config, pkgs, ... }:
{
  services.greetd = {
    enable = true;
    # VT fixado em VT1 no 25.11; opção services.greetd.vt removida
    settings = {
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --remember-session \
            --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions \
            --xsessions ${config.services.displayManager.sessionData.desktops}/share/xsessions \
            --greeting "It's time to viiiiiibe code, babyyyyyyy!" \
            --greet-align center
        '';
        user = "greeter";
      };
    };
  };
}
