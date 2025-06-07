{ ... }:
{
  # curent setup g14
  programs.rog-control-center = {
    enable = true;
    autoStart = true;
  };

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
    supergfxd = {
      enable = true;
      settings = {
        mode = "integrated";
      };
    };
  };
}
