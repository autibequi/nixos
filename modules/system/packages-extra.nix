{
  pkgs,
  unstable,
  inputs,
  ...
}:
# ════════════════════════════════════════════════════════════════════════════
# packages-extra.nix — CATÁLOGO de pacotes opt-in (referência)
#
# Tudo aqui está comentado de propósito: NADA é instalado por padrão.
#   • Para INSTALAR de vez → descomente a linha do pacote.
#   • Para uso PONTUAL sem instalar → `nix run nixpkgs#<nome>`.
#
# Este módulo é importado por system/default.nix; enquanto tudo está comentado,
# ele só contribui uma lista vazia (custo zero).
# ════════════════════════════════════════════════════════════════════════════
{
  environment.systemPackages = with pkgs; [
    # ── Benchmark / hardware ───────────────────────────────────────────
    # geekbench           # benchmark CPU/GPU
    # fio                 # I/O benchmark (CrystalDiskMark-style)
    # openrgb_git         # controle de iluminação RGB

    # ── Games / 3D / impressão ─────────────────────────────────────────
    # godot               # game engine
    # retroarchFull       # frontend de emuladores
    # sidequest           # sideloading Oculus/Quest
    # ventoy-full-gtk     # pendrive multiboot (GTK) — exige permittedInsecurePackages = [ "ventoy-qt5-1.1.05" ]
    # ventoy-full-qt      # pendrive multiboot (Qt)   — idem ventoy-qt5 inseguro
    # cura                # fatiador de impressão 3D

    # ── Mídia / imagem ─────────────────────────────────────────────────
    # unstable.digikam    # gerenciador de fotos (pesado, deps KDE)
    # upscayl             # upscale de imagem por IA (modelos pesados)

    # ── Apps Windows / compat ──────────────────────────────────────────
    # bottles             # rodar apps/jogos Windows (wine wrapper)
    # winboat             # Windows em container

    # ── Terminais / launchers ──────────────────────────────────────────
    # cool-retro-term     # terminal estilo CRT (brinquedo)
    # rofi-wayland         # alternativa ao rofi-unwrapped

    # ── Browsers alternativos ──────────────────────────────────────────
    # servo                                                              # browser experimental (Rust)
    # inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # ── Editores / agentes de IA (dev) ─────────────────────────────────
    # windsurf            # IDE com IA
    # opencode            # agente de código no terminal
    # jan                 # LLM local (alternativa ao lmstudio)
    # llm                 # CLI de LLM (datasette)
    # evil-helix_git      # fork do helix

    # ── Experimentais (inputs externos / inseguros) ────────────────────
    # unstable.howdy      # login por reconhecimento facial
    # inputs.antigravity-nix.packages.${pkgs.system}.default
    # inputs.voxtype.packages.${pkgs.system}.vulkan

    # ── Dev / Estratégia ───────────────────────────────────────────────
    # pipx                # instalar CLIs Python isolados
    # unstable.jiratui     # TUI de Jira
    # home-manager        # CLI standalone do HM (não usado — home.nix foi removido)
  ];
}
