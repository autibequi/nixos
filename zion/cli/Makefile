# Zion: CLI (zion) e sandbox.
# make install = regenera CLI (bashly), instala symlink e adiciona PATH + alias no ~/.zshrc

.PHONY: help install

# From cli/ we need repo root (nixos/), so go up two levels.
NIXOS_ROOT := $(abspath ../..)
CLI_DIR    := $(NIXOS_ROOT)/zion/cli
BIN_DEST   := $(NIXOS_ROOT)/stow/.local/bin/zion
BIN_DIR    := $(patsubst %/,%,$(dir $(BIN_DEST)))

help:
	@echo "  make install   Regenera zion (bashly), symlink e atualiza scripts/bootstrap.sh"

install: install-bootstrap
	cd "$(CLI_DIR)" && bashly generate
	@mkdir -p "$(dir $(BIN_DEST))"
	@ln -sf "$(CLI_DIR)/zion" "$(BIN_DEST)"
	@echo "[zion] zion instalado: $(BIN_DEST) -> $(CLI_DIR)/zion"

install-bootstrap:
	@mkdir -p "$(NIXOS_ROOT)/scripts"
	@install -m 755 "$(NIXOS_ROOT)/zion/scripts/bootstrap-dashboard.sh" "$(NIXOS_ROOT)/scripts/bootstrap.sh"
	@echo "[zion] scripts/bootstrap.sh atualizado (mounts em /workspace/nixos)"
	@if [ -f "$(NIXOS_ROOT)/scripts/puppy-scheduler.sh" ]; then \
	  sed -i 's|/workspace/host/scripts/puppy-runner.sh|/workspace/nixos/scripts/puppy-runner.sh|g' "$(NIXOS_ROOT)/scripts/puppy-scheduler.sh" 2>/dev/null && echo "[zion] puppy-scheduler.sh: path /workspace/nixos aplicado" || true; \
	fi
	@for rc in "$$HOME/.zshrc" "$$HOME/.bashrc"; do \
	  [ -n "$$rc" ] && (touch "$$rc" 2>/dev/null) && [ -w "$$rc" ] || continue; \
	  grep -q 'stow/.local/bin' "$$rc" 2>/dev/null || { echo "" >> "$$rc"; echo "# Zion CLI (make install)" >> "$$rc"; echo 'export PATH="$(BIN_DIR):$$PATH"' >> "$$rc"; echo "[zion] PATH adicionado em $$rc"; }; \
	  grep -q 'alias zion=' "$$rc" 2>/dev/null || grep -q 'stow/.local/bin' "$$rc" 2>/dev/null || { echo 'alias zion=zion' >> "$$rc"; echo "[zion] alias em $$rc"; }; \
	done; \
	echo "[zion] Rode: source ~/.zshrc  (ou source ~/.bashrc se usar bash)"
