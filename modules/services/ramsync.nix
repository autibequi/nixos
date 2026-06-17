# ════════════════════════════════════════════════════════════════════
# modules/services/ramsync.nix
#
# Profile/cache em RAM: reduz wear do SSD e melhora fluidez movendo
# dados que escrevem MUITO pra tmpfs (RAM).
#
# ── BROWSERS → Profile-Sync-Daemon (psd) ────────────────────────────
#   psd tem sanity-checks específicos de profile de browser (o asd NÃO
#   tem — ArchWiki alerta perda de dados ao usar asd em browser). Roda
#   como systemd.user service (sem home-manager). Resync 30min + sync no
#   shutdown. Detecta os browsers instalados (google-chrome/chromium/vivaldi).
#   Substitui o psd que vivia no antigo modules/core/home.nix (removido).
#
# ── ZED + OBSIDIAN → tmpfs nos CACHES (descartáveis) ────────────────
#   psd é browser-only e o asd (anything-sync-daemon) não tem módulo no
#   nixpkgs. Como aqui só queremos CACHE (descartável, reconstruído pelo
#   app), tmpfs puro é mais simples e seguro que o asd — não há sync que
#   possa corromper, e perder no reboot é o esperado de um cache.
#
#   ⚠️ O VAULT do Obsidian NUNCA entra em tmpfs (risco de perder notas).
#      Só os caches do app Electron (~/.config/obsidian/{Cache,...}) e o
#      cache XDG do Zed (~/.cache/zed). Alacritty ficou de fora: config
#      estática (stow), zero cache que renda em RAM.
#
#   "nofail": se o app nunca rodou e o dir-pai não existe, o mount falha
#   silenciosamente sem travar o boot.
# ════════════════════════════════════════════════════════════════════
{ ... }:
let
  user = "pedrinho";
  uid = "1000";
  ramOpts = sz: [
    "size=${sz}"
    "mode=0700"
    "uid=${uid}"
    "gid=100" # grupo `users`
    "noatime"
    "nosuid"
    "nodev"
    "nofail"
  ];
in
{
  # ── Browsers ──
  services.psd = {
    enable = true;
    resyncTimer = "30min";
  };

  # ── Zed + Obsidian: caches em RAM (NUNCA o vault) ──
  fileSystems = {
    "/home/${user}/.cache/zed" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ramOpts "1G";
    };
    "/home/${user}/.config/obsidian/Cache" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ramOpts "512M";
    };
    "/home/${user}/.config/obsidian/GPUCache" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ramOpts "256M";
    };
    "/home/${user}/.config/obsidian/Code Cache" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ramOpts "256M";
    };
  };
}
