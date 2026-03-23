# AI Configurations for NixOS

{
  pkgs,
  unstable,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # 🎨 ComfyUI - usar via: nix run github:nixified-ai/flake#comfyui-nvidia

    # 🤖 LLM Local
    unstable.lmstudio
    # jan

    # 💻 AI IDEs
    # windsurf
    unstable.code-cursor
    # opencode

    # 🛠️ Utilities
    # llm
    upscayl
  ];
}
