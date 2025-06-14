# NixOS

i have no ideia what i'm doing...

- [Documentação do Gnome](./modules/gnome/README.md)
- [Dotfile Docs](./dotfiles/README.md)

## Dirs
- `/core/` - Configurações essenciais (hardware, kernel, serviços, etc.)
- `/modules/` - Módulos (gnome, cosmic, bluetooth, nvidia, plymouth, etc.)
- `/assets/` - Arquivos de mídia, temas, ícones e outros recursos visuais
- `/dotfiles` - Arquivos de configuração pessoais para programas e ferramentas

## Instalation

From fresh install, get the `/boot`, `/` and `swap` partition UUIDs from the auto generated file.

```sh
cat /etc/nixos/configuration.nix
```

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

## Tricks
```
Q: High wattage consumption without CPU or GPU usage:
A: Nvi
dia prob went crazy, go to `sudo powertop` and turn on the tweaks.
```
