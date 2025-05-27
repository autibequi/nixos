# AI Configurations for NixOS

{ config, pkgs, inputs, ... }:

{
  # Enable AI tools from nixified-ai flake
  environment.systemPackages = with inputs.nixified-ai.packages.${pkgs.system}; [
    comfyui-nvidia  # ComfyUI with NVIDIA support
  ];

  # Additional configurations for ComfyUI models and custom nodes can be added here
  # For now, we'll assume models are downloaded or configured by the user post-installation
}