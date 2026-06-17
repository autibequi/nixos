{ pkgs, ... }:
{
  users.defaultUserShell = pkgs.zsh;

  # User Accounts
  # (grupos extras de virtualização — libvirtd/kvm — são adicionados em services/virt.nix;
  #  o NixOS faz merge das listas de extraGroups por usuário.)
  users.users.pedrinho = {
    isNormalUser = true;
    description = "pedrinho";
    extraGroups = [
      "adbusers"
      "podman" # socket rootful em /run/podman/podman.sock (virtualisation.podman.dockerSocket)
      "hidraw"
      "i2c"
      "input"
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };
}
