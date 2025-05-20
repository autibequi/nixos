# nix-config
i have no ideia what i'm doing...

update: i have SOME ideia now

# Instalação

Add to config files and run:

```sh
sudo nixos-rebuild switch
```

# nh manual

```sh 
nh os switch /etc/nixos
```

# Gnome
Mostly overwritten config are just to move the windows between screens and locating myself in worksapces without having to move my hand much.

```
<super> a/d = move workspace left/right
<super> w/s = maximize/minimize
<super> q/e - move window to left/right workspaces

<super> x - notifications
<super> c - menu
<super> z = overview

<super> esc = kill window

<super> f3 = toggle dark/light mode // night theme switcher ext
<super> tab = fill all tiles // tilling ext
<super> delete = reseta extensões do gnome // custom toggle ext
```

# Dotfiles

## Ghostty (`dotfiles/ghostty.conf`)
Configuração para o terminal Ghostty, incluindo atalhos de teclado personalizados:

```
<ctrl><shift> a/s/d/w = Dividir painel
<ctrl><shift> t = Nova aba
<ctrl><shift> n = Nova janela
```

## Fastfetch (`dotfiles/fastfetch.jsonc`)
Configuração para a ferramenta de informações do sistema Fastfetch. A configuração atual exibe as seguintes informações:

```
  ▗▄   ▗▄ ▄▖      OS: NixOS 25.11 (Xantusia)
 ▄▄🬸█▄▄▄🬸█▛ ▃     Shell: zsh 5.9
   ▟▛    ▜▃▟🬕     DE: GNOME 48.1
🬋🬋🬫█      █🬛🬋🬋    CPU: AMD Ryzen 9 7940HS 16 with threads @ 4.00 GHz
 🬷▛🮃▙    ▟▛       GPU: GeForce RTX 4060 Max-Q / Mobile
 🮃 ▟█🬴▀▀▀█🬴▀▀     GPU: AMD Radeon 780M
  ▝▀ ▀▘   ▀▘      RAM: 46.36 GiB/13%
                  UPTIME: 69d 4h 20m 
```

## Atuin (`dotfiles/atuin.conf`)
Atuin é uma ferramenta de histórico de comandos que sincroniza e criptografa seu histórico entre dispositivos.


### Comandos Básicos:
- `<ctrl>r` - Busca no histórico
- `atuin sync` - Sincroniza histórico entre dispositivos
- `atuin import` - Importa histórico do bash/zsh
- `atuin stats` - Mostra estatísticas de uso