{ config, lib, pkgs, ... }:

{
  # Docker
  virtualisation.docker = {
    enable = true;

    # Socket activation: docker.service only starts when the socket is first used,
    # removing it from the critical boot path entirely.
    enableOnBoot = false;

    daemon.settings = {
      # Usa iptables direto em vez de subir um processo docker-proxy por porta exposta.
      # Elimina overhead de processo intermediário por container com portas mapeadas.
      "userland-proxy" = false;

      # Containers continuam rodando se o daemon reiniciar (update, crash).
      # Sem isso, todo `vennon switch` que reinicia o docker derruba os containers.
      "live-restore" = true;
    };
  };

  # Allow Docker containers to reach the host on port 443/80 (needed for SSR → nginx reverse proxy)
  networking.firewall.extraInputRules = ''
    iifname "br-*" tcp dport { 80, 443 } accept
    iifname "docker0" tcp dport { 80, 443 } accept
  '';

  # Install docker-compose and lazydocker
  environment.systemPackages = with pkgs; [
    docker-compose
    lazydocker
  ];
}
