{ pkgs, ... }:

{
  # This explicitly prevents the default nano installation
  programs.nano.enable = false;

  # Programs
  programs = {
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

    # nix-index: gera o db que o `comma` (,) usa pra achar pacotes + handler
    # command-not-found. Após o switch, rode `nix-index` UMA vez pra popular o db
    # (~minutos; ou adicione o input nix-index-database pra um db pré-gerado).
    nix-index.enable = true;
    # command-not-found (via channels) usa o MESMO handler do shell → conflita.
    command-not-found.enable = false;
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
