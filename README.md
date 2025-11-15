# NixOS

i STILL have no ideia what i'm doing...

- [Documentação do Gnome](./modules/gnome/README.md)
- [Dotfile Docs](./dotfiles/README.md)

## Dirs
- `/core/` - Configurações essenciais (hardware, kernel, serviços, etc.)
- `/modules/` - Módulos (gnome, cosmic, bluetooth, nvidia, plymouth, etc.)
- `/assets/` - Arquivos de mídia, temas, ícones e outros recursos visuais
- `/dotfiles` - Arquivos de configuração pessoais para programas e ferramentas

## Instalation

You will need GIT and a text editor, run with nix without installing first:
```
nix-shell -p helix git
```

From fresh install, get the `/boot`, `/` and `swap` partition UUIDs from the auto generated file.

```sh
grep device /etc/nixos/hardware-configuration.nix
```

you will get something like:

```
17:    { device = "/dev/disk/by-uuid/ee52cc58-f10d-4979-8244-4386302649c5";
22:    { device = "/dev/disk/by-uuid/1F53-9115";
28:    [ { device = "/dev/disk/by-uuid/17e5c565-c90c-4233-92c6-bb86adfed306"; }
```

In order: boot, root and swap. Check the file for extra safeness.

Clone this repository then change the values in `configuration.nix` the extracted UUIds.

Hibernation and Swap configuration are optional.

After that run the following command to switch to the new configuration:

```sh

sudo nixos-rebuild switch --flake .#nomad
```

Make a little pray and reboot your system.

```sh
reboot
```

If it doesnt work boot the device and hit the hell out of `del` key to enter the latest stable version.

## Tricks
```
Q: High wattage consumption without CPU or GPU usage:
A: Nvi
dia prob went crazy, go to `sudo powertop` and turn on the tweaks.
```

```
Q: How update flakes
nix --extra-experimental-features 'nix-command flakes' flake update
```

## SSHKey to pull/push changes

```
ssh-keygen -t ed25519 -C "your_email@example.com"
```
## Validade Store

```sh
sudo nix-channel --update && sudo nixos-rebuild switch && nix-store --verify --check-contents $(nix-store -qR $(which warp-taskbar))
```

## Worktree control (for hardware.nix template)

Skip
```sh
git update-index --skip-worktree <file>
```
Unskip
```sh
git update-index --no-skip-worktree <file>
```

## Get UUIDs from hardware-configuration.nix

```sh
cat /etc/nixos/hardware-configuration.nix | grep -B 3 "device ="
```
