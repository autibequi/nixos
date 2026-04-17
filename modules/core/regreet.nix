{ pkgs, ... }:
{
  services.greetd.enable = true;

  # ReGreet — GTK4 greeter rodando dentro do cage (Wayland kiosk compositor).
  # O módulo programs.regreet já configura o greetd.default_session automaticamente.
  programs.regreet = {
    enable = true;

    settings = {
      background = {
        # Descomenta e aponta para um wallpaper se quiseres fundo no greeter:
        # path = "/home/pedrinho/.config/hypr/wallpaper.png";
        fit = "Cover";
      };

      GTK = {
        application_prefer_dark_theme = true;
      };
    };

    # CSS extra para personalizar (opcional)
    # extraCss = ''
    #   window {
    #     background-color: #1e1e2e;
    #   }
    # '';
  };
}
