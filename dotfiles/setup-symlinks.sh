#!/bin/bash

# Script para criar symlinks dos dotfiles
# Executar de dentro da pasta dotfiles

set -e

echo "🔗 Criando symlinks dos dotfiles..."

# Função para criar symlink com backup
create_symlink() {
    local source="$1"
    local target="$2"
    
    if [ -L "$target" ]; then
        echo "Removendo symlink existente: $target"
        rm "$target"
    elif [ -e "$target" ]; then
        echo "Fazendo backup de: $target"
        mv "$target" "$target.backup"
    fi
    
    echo "Criando symlink: $source -> $target"
    ln -sf "$source" "$target"
}

# Diretórios para criar symlinks
DIRS=(
    "hypr:~/.config/hypr"
    "waybar:~/.config/waybar"
    "fuzzel:~/.config/fuzzel"
    "zed:~/.config/zed"
)

# Arquivos individuais para criar symlinks
FILES=(
    "atuin.conf:~/.config/atuin/config.toml"
    "fastfetch.jsonc:~/.config/fastfetch/config.jsonc"
    "ghostty.conf:~/.config/ghostty/config"
    "vscode.json:~/.config/Code/User/settings.json"
)

# Criar symlinks dos diretórios
for dir_pair in "${DIRS[@]}"; do
    IFS=':' read -r source_dir target_dir <<< "$dir_pair"
    source_path="$(pwd)/$source_dir"
    target_path="${target_dir/#\~/$HOME}"
    
    if [ -d "$source_path" ]; then
        create_symlink "$source_path" "$target_path"
    else
        echo "⚠️  Diretório não encontrado: $source_path"
    fi
done

# Criar symlinks dos arquivos
for file_pair in "${FILES[@]}"; do
    IFS=':' read -r source_file target_file <<< "$file_pair"
    source_path="$(pwd)/$source_file"
    target_path="${target_file/#\~/$HOME}"
    
    # Criar diretório pai se não existir
    target_dir=$(dirname "$target_path")
    if [ ! -d "$target_dir" ]; then
        echo "Criando diretório: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    if [ -f "$source_path" ]; then
        create_symlink "$source_path" "$target_path"
    else
        echo "⚠️  Arquivo não encontrado: $source_path"
    fi
done

echo "✅ Symlinks criados com sucesso!"
echo ""
echo "📋 Resumo dos symlinks criados:"
echo "Diretórios:"
for dir_pair in "${DIRS[@]}"; do
    IFS=':' read -r source_dir target_dir <<< "$dir_pair"
    echo "  $source_dir -> $target_dir"
done
echo ""
echo "Arquivos:"
for file_pair in "${FILES[@]}"; do
    IFS=':' read -r source_file target_file <<< "$file_pair"
    echo "  $source_file -> $target_file"
done 