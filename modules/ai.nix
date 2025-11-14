# AI Configurations for NixOS

{
  pkgs,
  lib,
  pkgs-unstable,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Enable AI tools from nixified-ai flake
    lmstudio # LM Studio for local LLMs
    jan

    # AI Core
    windsurf
    pkgs-unstable.code-cursor
    opencode

    llm # access large language models

    # AI Image Upscaler
    upscayl

    # Local Whisper
    # openai-whisper-cpp
    # whisper-cpp
    # whisper-cpp-vulkan # Voice-To-Text - for blurt gnome extension
  ];
}
