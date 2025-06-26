# AI Configurations for NixOS

{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Enable AI tools from nixified-ai flake
    lmstudio # LM Studio for local LLMs
    jan

    # AI Core
    windsurf
    code-cursor
    opencode

    # Local Whisper
    # openai-whisper-cpp
    # whisper-cpp
    # whisper-cpp-vulkan # Voice-To-Text - for blurt gnome extension
  ];
}
