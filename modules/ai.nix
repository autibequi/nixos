# AI Configurations for NixOS

{
  pkgs,
  pkgs-unstable,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # 🎨 ComfyUI - usar via: nix run github:nixified-ai/flake#comfyui-nvidia

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
