{ ... }:
{
  # PipeWire — stack de áudio completo (substitui PulseAudio + JACK).
  #   alsa       → compatibilidade com apps ALSA legados
  #   pulse      → clientes PulseAudio
  #   jack       → clientes JACK (DAWs, etc.)
  #   wireplumber → session/policy manager
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };
}
