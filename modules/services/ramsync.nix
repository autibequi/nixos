# ════════════════════════════════════════════════════════════════════
# modules/services/ramsync.nix
#
# Profile-em-RAM: move profiles que escrevem MUITO pra tmpfs (RAM) e
# faz resync periódico ao disco. Reduz wear do SSD e melhora fluidez.
#
# ── Profile-Sync-Daemon (psd) — BROWSERS ────────────────────────────
#   Habilitado abaixo. Detecta os browsers instalados automaticamente
#   (google-chrome, chromium, vivaldi). Roda como systemd.user service
#   (NÃO precisa home-manager). Resync a cada 30min + sync no shutdown.
#   Substitui o psd que vivia em modules/core/home.nix (home-manager,
#   hoje desativado).
#
# ── Apps não-browser (Zed, Obsidian, …) ─────────────────────────────
#   psd é browser-ONLY por design (tem sanity-checks de profile que o
#   anything-sync-daemon não tem — ArchWiki alerta perda de dados ao
#   usar asd em browser). Pra Zed/Obsidian o caminho seria o asd, que
#   NÃO tem módulo no nixpkgs (exigiria service custom com bind mounts
#   + overlayfs). Avaliação:
#     - Zed:      estado em ~/.local/share/zed (DB/conversas) — perda no
#                 crash é ruim; ganho modesto num NVMe rápido.
#     - Obsidian: o *vault* JAMAIS vai pra tmpfs (risco de perder notas);
#                 ~/.config/obsidian é leve, ganho marginal.
#     - Alacritty: config estática (stow), zero cache que renda em RAM.
#   → Mantido FORA por enquanto. Ver discussão no PR/relatório.
# ════════════════════════════════════════════════════════════════════
{ ... }:
{
  services.psd = {
    enable = true;
    resyncTimer = "30min";
  };
}
