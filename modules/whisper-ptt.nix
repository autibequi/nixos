# Whisper Push-to-Talk — system dependencies
# Python deps (faster-whisper, sounddevice, webrtcvad) live in ~/.venv/whisper

{
  pkgs,
  config,
  lib,
  unstable,
  ...
}:
let
  whisper-ptt-libs = pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib                # libstdc++.so.6
    pkgs.portaudio                       # libportaudio for sounddevice
    pkgs.zlib
    config.hardware.nvidia.package       # libcuda.so, libnvidia-ml.so
    pkgs.cudaPackages.cudatoolkit        # libcublas, libcudnn, etc.
  ];

  whisper-ptt-wrapper = pkgs.writeShellScriptBin "whisper-ptt-start" ''
    export LD_LIBRARY_PATH="${whisper-ptt-libs}:''${LD_LIBRARY_PATH:-}"
    exec "$HOME/.venv/whisper/bin/python" "$HOME/.config/whisper-ptt/whisper-daemon.py"
  '';
in
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

    # Wrapper that sets LD_LIBRARY_PATH for the venv
    whisper-ptt-wrapper
  ];
}
