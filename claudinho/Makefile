# Claudinho: CLI (claudio) e sandbox.
# make install = regenera CLI (bashly) e instala symlink em stow/.local/bin

.PHONY: help install

NIXOS_ROOT := $(abspath ..)
CLI_DIR    := $(NIXOS_ROOT)/claudinho/claudio-cli
BIN_DEST   := $(NIXOS_ROOT)/stow/.local/bin/claudio

help:
	@echo "  make install   Regenera claudio (bashly generate) e instala symlink em stow/.local/bin"

install:
	cd "$(CLI_DIR)" && bashly generate
	@mkdir -p "$(dir $(BIN_DEST))"
	@ln -sf "$(CLI_DIR)/claudio" "$(BIN_DEST)"
	@echo "[claudinho] claudio instalado: $(BIN_DEST) -> $(CLI_DIR)/claudio"
