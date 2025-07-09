{
  lib,
  ...
}:
{
  # Instalation
  options.diskUUIDs = {
    boot = lib.mkOption {
      description = "Boot partition";
      default = "/dev/disk/by-uuid/1F53-9115";
    };
    root = lib.mkOption {
      description = "Root partition";
      default = "/dev/disk/by-uuid/ee52cc58-f10d-4979-8244-4386302649c5";
    };
    swap = lib.mkOption {
      description = "Swap partition";
      default = "/dev/disk/by-uuid/17e5c565-c90c-4233-92c6-bb86adfed306";
    };
  };
}
