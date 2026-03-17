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
	@ZSHRC="$$HOME/.zshrc"; \
	if [ -n "$$ZSHRC" ] && (touch "$$ZSHRC" 2>/dev/null) && [ -w "$$ZSHRC" ]; then \
	  grep -q 'stow/.local/bin' "$$ZSHRC" 2>/dev/null || { echo "" >> "$$ZSHRC"; echo "# Zion CLI (make install)" >> "$$ZSHRC"; echo 'export PATH="$(BIN_DIR):$$PATH"' >> "$$ZSHRC"; echo "[zion] PATH adicionado em $$ZSHRC"; }; \
	  grep -q 'alias claudio=zion' "$$ZSHRC" 2>/dev/null || { echo 'alias claudio=zion' >> "$$ZSHRC"; echo "[zion] alias claudio=zion adicionado em $$ZSHRC"; }; \
	  echo "[zion] Rode: source $$ZSHRC"; \
	else \
	  echo "[zion] Adicione ao seu ~/.zshrc: export PATH=\"$(BIN_DIR):\$$PATH\" e alias claudio=zion"; \
	fi
