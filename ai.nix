{ config, pkgs, lib, ... } :
{
  # CUDA
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  # Packages
  environment.systemPackages = with pkgs; [
  ];

  # WebUI (heavy build)
  services.open-webui.enable = true;
}