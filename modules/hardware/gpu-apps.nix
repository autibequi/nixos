# ════════════════════════════════════════════════════════════════════
# modules/hardware/gpu-apps.nix
#
# Força apps GUI específicos a renderizarem na dGPU NVIDIA (RTX 4060)
# via PRIME offload, em vez de cair na iGPU AMD (Radeon 780M).
#
# Mecanismo:
#   - .desktop overrides em ~/.local/share/applications/ (precedência
#     sobre /run/current-system/sw/share/applications/ no XDG_DATA_DIRS)
#   - shellAliases zsh pra invocações CLI (`cursor .`, `code .`, etc.)
#
# Pré-requisito: hardware.nvidia.prime.offload.enableOffloadCmd = true
# (já ativado em modules/hardware/nvidia.nix → expõe binário nvidia-offload)
#
# Adicionar novo app:
#   1. Incluir entry em `apps` abaixo
#   2. `sudo nixos-rebuild switch` (ou `nh os switch`)
#
# Remover app:
#   1. Tirar entry da lista
#   2. Rebuild → cleanup automático remove o override antigo
#
# Verificar se um app está na dGPU em runtime:
#   prime-run / nvidia-smi (deve aparecer o processo)
#   __NV_PRIME_RENDER_OFFLOAD=1 glxinfo | grep "OpenGL renderer"
# ════════════════════════════════════════════════════════════════════
{ config, lib, pkgs, ... }:

let
  user = "pedrinho";

  # ── LISTA DE APPS ─────────────────────────────────────────────────
  # Campos por entry:
  #   bin          → executável no PATH (obrigatório)
  #   name         → display name no launcher (obrigatório)
  #   desktopFile  → nome do .desktop a sobrescrever, sem extensão
  #                  (default = bin; ajustar se o nome canônico difere)
  #   icon         → nome do ícone XDG (default = bin)
  #   categories   → string XDG separada por ';' (default = "Application;")
  #   mimeType     → string XDG opcional, separada por ';'
  #   wmClass      → StartupWMClass pra agrupar janelas (default = bin)
  #   args         → tokens pra Exec= (default = "%U")
  apps = [
    {
      bin = "alacritty"; name = "Alacritty";
      desktopFile = "Alacritty"; icon = "Alacritty";
      categories = "System;TerminalEmulator;";
    }
    {
      bin = "ghostty"; name = "Ghostty";
      desktopFile = "com.mitchellh.ghostty"; icon = "com.mitchellh.ghostty";
      categories = "System;TerminalEmulator;";
    }
    {
      # zed-editor (unstable.zed-editor) instala o binário como `zeditor`
      bin = "zeditor"; name = "Zed";
      desktopFile = "dev.zed.Zed"; icon = "zed";
      categories = "Development;TextEditor;IDE;";
      mimeType = "text/plain;inode/directory;";
    }
    {
      bin = "code"; name = "Visual Studio Code";
      desktopFile = "code"; icon = "vscode";
      categories = "Development;TextEditor;IDE;";
      mimeType = "text/plain;inode/directory;";
      wmClass = "Code";
    }
    {
      bin = "cursor"; name = "Cursor";
      desktopFile = "cursor"; icon = "cursor";
      categories = "Development;TextEditor;IDE;";
      mimeType = "text/plain;inode/directory;";
      wmClass = "Cursor";
    }
  ];
  # ──────────────────────────────────────────────────────────────────

  mkDesktopFile = app:
    let
      icon = app.icon or app.bin;
      cats = app.categories or "Application;";
      mime = app.mimeType or "";
      wm   = app.wmClass or app.bin;
      args = app.args or "%U";
      file = app.desktopFile or app.bin;
    in pkgs.writeText "${file}.desktop" ''
      [Desktop Entry]
      Type=Application
      Name=${app.name}
      Exec=nvidia-offload ${app.bin} ${args}
      TryExec=${app.bin}
      Icon=${icon}
      Terminal=false
      Categories=${cats}
      ${lib.optionalString (mime != "") "MimeType=${mime}"}
      StartupNotify=true
      StartupWMClass=${wm}
      X-DGPU-Override=managed
    '';

in {
  # ── Deploy dos .desktop overrides ────────────────────────────────
  # Activation script roda como root a cada nixos-rebuild switch.
  # Idempotente: limpa overrides antigos (tag X-DGPU-Override=managed)
  # e reescreve a partir da lista atual.
  system.activationScripts.dGPUAppsDesktop = {
    text = ''
      target=/home/${user}/.local/share/applications
      mkdir -p "$target"

      # Cleanup: remove overrides anteriores deste módulo
      for f in "$target"/*.desktop; do
        [ -f "$f" ] || continue
        if grep -qF "X-DGPU-Override=managed" "$f" 2>/dev/null; then
          rm -f "$f"
        fi
      done

      # Deploy novos overrides
      ${lib.concatMapStringsSep "\n" (app:
        let file = app.desktopFile or app.bin;
        in ''install -m 644 ${mkDesktopFile app} "$target/${file}.desktop"''
      ) apps}

      # Garante ownership (activation roda como root)
      chown -R ${user} "$target"
    '';
    deps = [];
  };

  # ── Aliases zsh ──────────────────────────────────────────────────
  # Pra quando você abre via terminal (`cursor .`, `code repo/`, etc.).
  # Sem alias o launcher cai na iGPU porque o .desktop override só
  # afeta launches via launcher (rofi/Hyprland/dock).
  programs.zsh.shellAliases = lib.listToAttrs (map (app: {
    name  = app.bin;
    value = "nvidia-offload ${app.bin}";
  }) apps);
}
