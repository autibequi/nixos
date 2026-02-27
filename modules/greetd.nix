{ config, pkgs, ... }:
{
  services.greetd = {
    enable = true;
    # Não exibir erros/warnings no TTY antes do greeter carregar
    vt = 7;
    settings = {
      default_session = {
        command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
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
