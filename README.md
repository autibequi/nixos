## NixOS Config

i have no ideia what i'm doing...

update: i have SOME ideia now

### Other Docs
[Documentação do Gnome](./desktop-envs/gnome/README.md)
[Dotfile Docs](./dotfiles/README.md)

### Estrutura Principal
- `configuration.nix` - Arquivo principal de configuração
- `flake.nix` - Gerenciamento de dependências e configuração do sistema
- `nix.nix` - Configurações específicas do Nix (substituidores, etc.)

### Diretórios
- `/core/` - Configurações essenciais (hardware, kernel, serviços, etc.)
- `/modules/` - Módulos opcionais (bluetooth, nvidia, plymouth, etc.)
- `/desktop-envs/` - Ambientes de desktop (GNOME, KDE, Cosmic)
- `/assets/` - Arquivos de mídia, temas, ícones e outros recursos visuais
- `/dotfiles` - Arquivos de configuração pessoais para programas e ferramentas

# Instalação

Add to config files and run:

```sh
sudo nixos-rebuild switch
```

# nh manual

```sh
nh os switch /etc/nixos
```

## Throubleshouting

Q: High wattage consumption without CPU or GPU usage:
A: nvidia went crazy, go to `sudo powertop` and turn on the tweaks
