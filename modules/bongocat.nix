# BongoCat + Claude Typer
# Daemon que cria teclado virtual (uinput) e manda keypresses quando Claude está ativo.
# Bongocat lê o device /dev/input/claude-bongo (symlink criado por udev rule).

{ pkgs, lib, ... }:

let
  python-with-evdev = pkgs.python3.withPackages (ps: [ ps.evdev ]);

  claude-typer-script = pkgs.writeShellScriptBin "claude-typer" ''
    exec ${python-with-evdev}/bin/python3 "$HOME/.config/bongocat/claude-typer.py"
  '';
in
{
  # Carrega módulo uinput no boot
  boot.kernelModules = [ "uinput" ];

  # Grupo uinput + permissões no device
  users.groups.uinput = { };
  users.users.pedrinho.extraGroups = [ "uinput" ];

  services.udev.extraRules = lib.mkAfter ''
    # Permissões pro device uinput (necessário pra criar teclados virtuais)
    KERNEL=="uinput", GROUP="uinput", MODE="0660"

    # Symlink estável pro teclado virtual do Claude
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="claude-bongo", SYMLINK+="input/claude-bongo", TAG+="uaccess"
  '';

  environment.systemPackages = [ claude-typer-script ];

  # Serviço systemd user que roda o daemon
  systemd.user.services.claude-typer = {
    description = "Claude BongoCat Typer Daemon";
    wantedBy = [ "default.target" ];
    after = [ "graphical-session-pre.target" ];
    partOf = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${claude-typer-script}/bin/claude-typer";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
