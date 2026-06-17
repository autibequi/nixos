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

    # 💻 AI IDEs
    unstable.code-cursor

    # 🛠️ Utilities
    # (jan, windsurf, opencode, llm, upscayl → system/packages-extra.nix)

    # MCPS
    unstable.python314Packages.firecrawl-py
  ];
}
