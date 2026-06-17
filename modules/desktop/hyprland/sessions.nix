{
  pkgs,
  ...
}:
let
  # Wrappers de sessão UWSM. O texto vive em ./scripts/*.sh pra evitar
  # shell embutido em string Nix (sem syntax highlight, sem shellcheck).
  startHyprlandNvidia = pkgs.writeShellScriptBin "start-hyprland-nvidia" (
    builtins.readFile ./scripts/start-hyprland-nvidia.sh
  );

  startHyprlandNvidiaLoop = pkgs.writeShellScriptBin "start-hyprland-nvidia-loop" (
    builtins.readFile ./scripts/start-hyprland-nvidia-loop.sh
  );
in
{
  programs.uwsm = {
    enable = true;
    package = pkgs.uwsm;
    waylandCompositors = {
      # Sessão híbrida (default): compositor roda na iGPU AMD, apps usam
      # `gpu-offload <bin>` (gpu-toggle.nix) pra subir só o que precisa
      # na dGPU NVIDIA. Modo bateria-friendly.
      start-hyprland = {
        prettyName = "Hyprland (Hybrid)";
        comment = "Hyprland on iGPU AMD; apps offload to dGPU via gpu-offload";
        binPath = "/run/current-system/sw/bin/start-hyprland";
      };
      # Sessão NVIDIA full: tudo na dGPU. Selecionar no greeter (tuigreet)
      # quando estiver plugado na tomada / dock.
      start-hyprland-nvidia = {
        prettyName = "Hyprland (NVIDIA full offload)";
        comment = "Hyprland and all clients render on dGPU NVIDIA";
        binPath = "${startHyprlandNvidia}/bin/start-hyprland-nvidia";
      };
      # Sessão NVIDIA full + loop resiliente: igual à start-hyprland-nvidia,
      # mas com AQ_MGPU_NO_EXPLICIT=1 e auto-restart em config completo
      # (sem --safe-mode) quando Hyprland crasha. Pra usar quando a NVIDIA
      # full está crashando recorrentemente — evita ficar preso em safe mode.
      start-hyprland-nvidia-loop = {
        prettyName = "Hyprland (NVIDIA full + resilient loop)";
        comment = "NVIDIA full offload; AQ_MGPU_NO_EXPLICIT; restarts on crash without safe-mode";
        binPath = "${startHyprlandNvidiaLoop}/bin/start-hyprland-nvidia-loop";
      };
    };
  };

  # Wrappers expostos como pacotes (também referenciados via binPath acima).
  environment.systemPackages = [
    startHyprlandNvidia
    startHyprlandNvidiaLoop
  ];
}
