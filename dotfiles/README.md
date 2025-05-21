
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

