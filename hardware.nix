# Instalation
# Create a copy of this file named hardware.nix with the content below.
# In a fresh start the UUIDs can be retrieved with:
#
#   cat /etc/nixos/hardware-configuration.nix | grep -B 3 "device ="
#
{ ... }:
{
  config = {
    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/1F53-9115";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/ee52cc58-f10d-4979-8244-4386302649c5";
      fsType = "ext4"; # TODO: testar zfs com lz4 no proximo setup
      neededForBoot = true;
      options = [
        "defaults"
        "noatime"
        # "discard" removido: continuous TRIM adiciona latência em cada delete.
        # fstrim semanal (kernel.nix) é o modo correto para NVMe — menos overhead,
        # mesmo benefício de saúde para o SSD.
      ];
    };

    # Hibernation
    boot.resumeDevice = "/dev/disk/by-uuid/17e5c565-c90c-4233-92c6-bb86adfed306";

    # Swap
    swapDevices = [ { device = "/dev/disk/by-uuid/17e5c565-c90c-4233-92c6-bb86adfed306"; } ];
  };
}
