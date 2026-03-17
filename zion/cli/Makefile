# Zion: CLI (zion) e sandbox.
# make install = regenera CLI (bashly), instala symlink e adiciona PATH + alias no ~/.zshrc

.PHONY: help install

# From cli/ we need repo root (nixos/), so go up two levels.
NIXOS_ROOT := $(abspath ../..)
CLI_DIR    := $(NIXOS_ROOT)/zion/cli
BIN_DEST   := $(NIXOS_ROOT)/stow/.local/bin/zion
BIN_DIR    := $(patsubst %/,%,$(dir $(BIN_DEST)))

help:
	@echo "  make install   Regenera zion (bashly generate) e instala symlink em stow/.local/bin"

install:
	cd "$(CLI_DIR)" && bashly generate
	@mkdir -p "$(dir $(BIN_DEST))"
	@ln -sf "$(CLI_DIR)/zion" "$(BIN_DEST)"
	@echo "[zion] zion instalado: $(BIN_DEST) -> $(CLI_DIR)/zion"
	@for rc in "$$HOME/.zshrc" "$$HOME/.bashrc"; do \
	  [ -n "$$rc" ] && (touch "$$rc" 2>/dev/null) && [ -w "$$rc" ] || continue; \
	  grep -q 'stow/.local/bin' "$$rc" 2>/dev/null || { echo "" >> "$$rc"; echo "# Zion CLI (make install)" >> "$$rc"; echo 'export PATH="$(BIN_DIR):$$PATH"' >> "$$rc"; echo "[zion] PATH adicionado em $$rc"; }; \
	  grep -q 'alias claudio=zion' "$$rc" 2>/dev/null || { echo 'alias claudio=zion' >> "$$rc"; echo "[zion] alias claudio=zion em $$rc"; }; \
	done; \
	echo "[zion] Rode: source ~/.zshrc  (ou source ~/.bashrc se usar bash)"
