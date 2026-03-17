# Zion: CLI (zion) e sandbox.
# make install = regenera CLI (bashly) e instala symlink em stow/.local/bin

.PHONY: help install

NIXOS_ROOT := $(abspath ..)
CLI_DIR    := $(NIXOS_ROOT)/zion/cli
BIN_DEST   := $(NIXOS_ROOT)/stow/.local/bin/zion

help:
	@echo "  make install   Regenera zion (bashly generate) e instala symlink em stow/.local/bin"

install:
	cd "$(CLI_DIR)" && bashly generate
	@mkdir -p "$(dir $(BIN_DEST))"
	@ln -sf "$(CLI_DIR)/zion" "$(BIN_DEST)"
	@echo "[zion] zion instalado: $(BIN_DEST) -> $(CLI_DIR)/zion"
