# AI Configurations for NixOS

{
  pkgs,
  lib,
  pkgs-unstable,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # 🎨 ComfyUI (NVIDIA)
    inputs.nixified-ai.packages.x86_64-linux.comfyui-nvidia

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
