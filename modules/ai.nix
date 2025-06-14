# AI Configurations for NixOS

{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Enable AI tools from nixified-ai flake
    # comfyui-nvidia # ComfyUI with NVIDIA support
    lmstudio # LM Studio for local LLMs

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
