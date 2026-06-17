# Sessão "NVIDIA full + loop resiliente" — igual ao start-hyprland-nvidia.sh
# mas com 2 diferenças:
#
#   1. AQ_MGPU_NO_EXPLICIT=1
#      Desliga explicit sync entre buffers que atravessam dGPU↔iGPU
#      (camada Aquamarine). Mesmo na sessão NVIDIA full, o cursor passeia
#      entre as duas GPUs (`drm: Cursor buffer imported into KMS` no log).
#      Esse é o caminho que falha em eglDupNativeFenceFDANDROID →
#      GL_INNOCENT_CONTEXT_RESET → SIGABRT (ver hyprlandCrashReport*.txt
#      e hyprwm/Hyprland#7230).
#
#   2. Loop bash em vez de invocar `start-hyprland`
#      O wrapper oficial `start-hyprland` (v0.55.2, start/src/main.cpp)
#      hardcoda `safeMode = true` quando Hyprland sai non-clean:
#
#          if (!RET) {
#              g_logger->log(LOG_ERR, "Hyprland exit not-cleanly, restarting");
#              safeMode = true;   // <-- sem env var ou flag pra desligar
#              continue;
#          }
#
#      `--safe-mode` ignora o config Lua inteiro → sem keybinds, sem
#      terminal, único caminho de saída é TTY2. Aqui rodamos o Hyprland
#      direto num while-true: se crashar, volta com config completo.
#      Trade-off: se o config tiver erro real, fica em crashloop —
#      nesse cenário ainda dá pra ir TTY2 e editar.

# PRIME render offload globalmente
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

# wlroots / Wayland backends apontando pra NVIDIA
export GBM_BACKEND=nvidia-drm
export LIBVA_DRIVER_NAME=nvidia
export WLR_NO_HARDWARE_CURSORS=1

# Força o wlroots a abrir APENAS o DRM da dGPU (PCI 1:0:0 em nvidia.nix).
export WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:01:00.0-card

# Aquamarine: sem explicit sync entre buffers multi-GPU (ver comentário acima).
export AQ_MGPU_NO_EXPLICIT=1

# Loop substitui o watchdog do start-hyprland: nunca passa --safe-mode.
while true; do
  /run/current-system/sw/bin/Hyprland "$@"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    # Saída limpa (logout do usuário) — encerra a sessão.
    exit 0
  fi
  echo "[start-hyprland-nvidia-loop] Hyprland exit non-clean (rc=$rc), restarting with full config in 1s..." >&2
  sleep 1
done
