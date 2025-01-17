{ config, pkgs, lib, ... } :
{
  # NIXIFY.AI
  # https://github.com/nixified-ai/flake
  nix.settings.trusted-substituters = ["https://ai.cachix.org"];
  nix.settings.trusted-public-keys = ["ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="];

  # CUDA
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  # Packages
  environment.systemPackages = with pkgs; [
  ];

  # WebUI (heavy build)
  # services.open-webui.enable = true;
}