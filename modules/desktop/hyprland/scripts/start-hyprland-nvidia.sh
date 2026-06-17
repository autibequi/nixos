# Sessão "NVIDIA full offload" — wrapper que exporta env vars antes de subir
# o Hyprland. Resultado: compositor e TODOS os clients renderizam na dGPU
# NVIDIA (RTX 4060). iGPU AMD fica praticamente ociosa — útil quando plugado
# na tomada ou em sessão de jogo/dev pesado. Pra modo híbrido (compositor na
# iGPU + offload por app via `gpu-offload`) use a sessão default.

# PRIME render offload globalmente
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

# wlroots / Wayland backends apontando pra NVIDIA
export GBM_BACKEND=nvidia-drm
export LIBVA_DRIVER_NAME=nvidia
export WLR_NO_HARDWARE_CURSORS=1

# Força o wlroots a abrir APENAS o DRM da dGPU (PCI 1:0:0 em nvidia.nix).
# Sem isso, o compositor pode escolher a iGPU como GPU primária.
export WLR_DRM_DEVICES=/dev/dri/by-path/pci-0000:01:00.0-card

exec /run/current-system/sw/bin/start-hyprland "$@"
