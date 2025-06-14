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

From fresh install, get the `/boot`, `/` and `swap` partition UUIDs. Hibernation and Swap configuration are optional.

```sh
cat /etc/nixos/configuration.nix
```

Then, change the values in `configuration.nix` to match your partitions.

After that run the following command to switch to the new configuration:

```sh
sudo nixos-rebuild switch --flake .#nomad
```

## Tricks
```
Q: High wattage consumption without CPU or GPU usage:
A: Nvidia prob went crazy, go to `sudo powertop` and turn on the tweaks.
```
