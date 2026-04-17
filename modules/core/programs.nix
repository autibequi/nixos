{ pkgs, ... }:

{
  # This explicitly prevents the default nano installation
  programs.nano.enable = false;

  # Programs
  programs = {
    adb.enable = true;
    direnv.enable = true;
    starship.enable = true;
    starship.transientPrompt.enable = true;
    starship.settings = {
      # Limita scan de módulos a 10ms e comandos externos a 200ms.
      # Sem isso, starship faz git status em repos grandes a cada prompt,
      # acumulando minutos de CPU em shells idle.
      scan_timeout = 10;
      command_timeout = 200;
    };
  };

  # Waydroid: habilitado mas container NÃO sobe automaticamente no boot.
  # O waydroid-container.service consumia ~55MB de RAM e CPU em idle.
  # Para usar: `sudo systemctl start waydroid-container` ou `waydroid session start`
  virtualisation.waydroid.enable = true;
  systemd.services.waydroid-container.wantedBy = [ ]; # remove de multi-user.target

  environment.systemPackages = with pkgs; [
    python3Packages.pyclip
    wl-clipboard-rs
    waydroid-helper
  ];
}
