# https://github.com/NixOS/nixpkgs/pull/216245
{ inputs, ... }: 
{
  disabledModules = ["security/pam.nix"];
  imports = [
    "${inputs.nixpkgs-howdy}/nixos/modules/security/pam.nix"
    "${inputs.nixpkgs-howdy}/nixos/modules/services/security/howdy.nix"
    "${inputs.nixpkgs-howdy}/nixos/modules/services/misc/linux-enable-ir-emitter.nix"
  ];
    
  services = {
    howdy = {
      enable = true;
      settings = {
        video.device_path = "/dev/video2";
        # you may not need these
        core.no_confirmation = true;
        video.dark_threshold = 90;
      };
    };
  };
}