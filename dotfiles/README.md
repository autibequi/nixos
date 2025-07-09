# 📁 Dotfiles

Configurações personalizadas para o sistema NixOS do Pedrinho.

## 🚀 Setup Automático

Para configurar todos os dotfiles automaticamente, execute:

```bash
cd dotfiles
./setup-symlinks.sh
```

Este script criará symlinks para todas as configurações necessárias.

## 📋 Estrutura

### 🎯 Diretórios de Configuração
- **`hypr/`** - Configurações do Hyprland (window manager)
- **`waybar/`** - Configurações da barra de status
- **`fuzzel/`** - Configurações do launcher de aplicações
- **`zed/`** - Configurações do editor Zed

### 📄 Arquivos de Configuração
- **`atuin.conf`** - Configuração do Atuin (histórico de comandos)
- **`fastfetch.jsonc`** - Configuração do Fastfetch (info do sistema)
- **`ghostty.conf`** - Configuração do terminal Ghostty
- **`vscode.json`** - Configurações do VS Code

## 🔧 Configurações Específicas

### Hyprland
- Configuração otimizada para desenvolvimento
- Atalhos personalizados para produtividade
- Temas e aparência customizada

### Waybar
- Barra de status minimalista
- Informações essenciais do sistema
- Integração com Hyprland

### Fuzzel
- Launcher rápido e eficiente
- Busca fuzzy para aplicações
- Interface limpa e moderna

### Zed
- Editor moderno e rápido
- Configurações otimizadas para desenvolvimento
- Atalhos personalizados

## 🛠️ Manutenção

### Adicionando Novas Configurações
1. Adicione o arquivo/diretório na pasta `dotfiles/`
2. Atualize o script `setup-symlinks.sh` com o novo item
3. Execute o script para criar o symlink

### Removendo Configurações
1. Remova o item do script `setup-symlinks.sh`
2. Delete o symlink manualmente se necessário
3. Remova o arquivo/diretório da pasta `dotfiles/`

## 📝 Notas

- Todos os symlinks apontam para `~/.config/`
- O script faz backup automático de arquivos existentes
- Configurações são versionadas no Git
- Compatível com NixOS e home-manager

## 🔄 Atualizações

Para atualizar as configurações após mudanças:

```bash
cd dotfiles
./setup-symlinks.sh
```

Isso recriará todos os symlinks com as configurações mais recentes.

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

