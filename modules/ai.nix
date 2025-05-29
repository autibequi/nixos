# AI Configurations for NixOS

{
  pkgs,
  inputs,
  ...
}:

{
  # Enable AI tools from nixified-ai flake
  environment.systemPackages = with inputs.nixified-ai.packages.${pkgs.system}; [
    comfyui-nvidia # ComfyUI with NVIDIA support
  ];

  # # Open WebUI for local LLM interface
  # services.open-webui = {
  #   enable = true;
  #   host = "127.0.0.1";
  #   port = 8080;
  #   environment = {
  #     # Configure Ollama backend
  #     OLLAMA_BASE_URL = "http://127.0.0.1:11434";
  #     # Enable GPU acceleration if available
  #     WEBUI_AUTH = "False";  # Set to True for authentication
  #   };
  # };

  # # Ollama service for running local LLMs
  # services.ollama = {
  #   enable = true;
  #   acceleration = "cuda";  # Use NVIDIA GPU acceleration
  #   host = "127.0.0.1";
  #   port = 11434;
  # };

  # Additional configurations for ComfyUI models and custom nodes can be added here
  # For now, we'll assume models are downloaded or configured by the user post-installation
}
