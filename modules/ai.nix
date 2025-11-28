# AI Configurations for NixOS

{
  pkgs,
  lib,
  pkgs-unstable,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # 🎨 Stable Diffusion / ComfyUI
    # Executar: nix run github:nixified-ai/flake#comfyui-nvidia

    # 🤖 LLM Local
    lmstudio
    jan

    # 💻 AI IDEs
    windsurf
    pkgs-unstable.code-cursor
    opencode

    # 🛠️ Utilities
    llm
    upscayl
  ];
}
