#!/usr/bin/env bash
# Setup opencode config via stow
# Install opencode-lmstudio plugin and sync config from stow to home

set -euo pipefail

WORKSPACE="${WORKSPACE:-/workspace}"
HOME_DIR="${HOME:-$HOME}"
STOW_DIR="$WORKSPACE/stow"
CONFIG_DIR="$HOME_DIR/.config/opencode"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Setting up opencode config...${NC}"

# Check if stow is available
if ! command -v stow &> /dev/null; then
    echo -e "${YELLOW}⚠️  stow not found. Installing via nix-shell...${NC}"
    nix-shell -p stow --run "stow --version" || {
        echo -e "${YELLOW}⚠️  Could not verify stow. Continuing anyway...${NC}"
    }
fi

# Ensure config dir exists
mkdir -p "$CONFIG_DIR"

# Stow the .config/opencode directory
echo -e "${BLUE}📦 Stowing .config/opencode...${NC}"
cd "$STOW_DIR"
stow -v -t "$HOME_DIR" .config/opencode 2>&1 | grep -E "(symlink|skip|conflict)" || true

# Install dependencies with bun
if command -v bun &> /dev/null; then
    echo -e "${BLUE}📥 Installing dependencies with bun...${NC}"
    cd "$CONFIG_DIR"
    bun install
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠️  bun not found in PATH. Run 'bun install' manually in $CONFIG_DIR${NC}"
fi

echo -e "${GREEN}✓ Setup complete!${NC}"
echo -e "${BLUE}📍 Config location: $CONFIG_DIR${NC}"
echo -e "${YELLOW}💡 Tip: Test with 'opencode --version'${NC}"
