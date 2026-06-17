{ ... }:
{
  # Serviços de sistema (daemons de base do desktop). Tuning de performance
  # de serviços (oomd/journald/slices/irqbalance/tlp) fica em performance.nix;
  # rede (tailscale/ssh/NM) fica em networking.nix.

  # Disable Evil Printer
  services.printing.enable = false;

  # ModemManager: gerencia modems 3G/4G — inútil sem modem celular.
  # Consome RAM e faz polling de USB no boot.
  systemd.services.ModemManager.enable = false;

  # UPower: battery/power info via DBus. Chrome e outros apps chamam org.freedesktop.UPower;
  # sem o serviço, falha "ServiceUnknown: The name is not activatable" e pode bloquear no launch.
  services.upower.enable = true;

  # udisks2: automontagem de dispositivos removíveis (pendrives, HDs externos).
  # gvfs: expõe udisks2 via DBus para apps GTK/Nautilus montarem automaticamente.
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # fwupd — desativado (firmware update é manual, daemon rodando 24/7 não faz sentido)
  services.fwupd.enable = false;

  # LM Studio API Server (disabled — lms binary segfaults, needs manual install).
  # Opção definida em services/lmstudio.nix.
  services.lmstudio.enable = false;
}
