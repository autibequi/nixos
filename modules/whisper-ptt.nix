# Whisper Push-to-Talk — system dependencies
# Python deps (faster-whisper, sounddevice, webrtcvad) live in ~/.venv/whisper

{
  pkgs,
  unstable,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    # Socket communication
    socat

    # Text output to Wayland
    wtype
    wl-clipboard

    # Overlay widget
    unstable.eww

    # Notifications
    libnotify

    # Audio
    pipewire # PipeWire headers/libs for sounddevice
    portaudio # sounddevice backend

    # Python venv bootstrap
    (python3.withPackages (ps: with ps; [
      pip
      virtualenv
    ]))
  ];
}
