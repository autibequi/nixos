.PHONY: help switch update stow restow proxy

help:
	@echo ""
	@echo "  NixOS"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make switch            Aplica config NixOS (nh os switch)"
	@echo "  make update            Atualiza flake e aplica"
	@echo ""
	@echo "  Dotfiles"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make stow              Injeta dotfiles via stow"
	@echo "  make restow            Remove e re-injeta dotfiles"
	@echo ""
	@echo "  Proxy"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make proxy             Mocks LDI + sobe reverse proxy (docker)"
	@echo ""
	@echo "  Claudinho (CLI: claudio)"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make install        Regenera zion (bashly), symlink e atualiza scripts/bootstrap.sh"
	@echo "  make install-bootstrap  Só atualiza scripts/bootstrap.sh (mounts em /workspace/nixos)"
	@echo "  claudio --help      Lista comandos (run, build, worker, etc.)"
	@echo ""

# ── NixOS ──────────────────────────────────────────────────────────

switch:
	nh os switch .

update:
	nh os switch --update .

# ── Dotfiles ───────────────────────────────────────────────────────

stow:
	@for dir in agents commands hooks scripts skills; do \
		link="$$HOME/.claude/$$dir"; \
		if [ -L "$$link" ]; then \
			target=$$(readlink "$$link"); \
			case "$$target" in /workspace/*) echo "removing container symlink: $$link"; rm -f "$$link" ;; esac; \
		fi; \
	done
	stow --target=$$HOME --no-folding --adopt -R stow

restow:
	@for dir in agents commands hooks scripts skills; do \
		link="$$HOME/.claude/$$dir"; \
		if [ -L "$$link" ]; then \
			target=$$(readlink "$$link"); \
			case "$$target" in /workspace/*) rm -f "$$link" ;; esac; \
		fi; \
	done
	stow --target=$$HOME --no-folding --adopt --override=file -R stow

# ── Reverse proxy ─────────────────────────────────────────────────

proxy:
	@if [ -f scripts/reverseproxy/Makefile ]; then $(MAKE) -C scripts/reverseproxy mocks-ldi; fi
	docker compose -f scripts/reverseproxy/docker-compose.yaml up -d

# ── Claudinho / Zion CLI ───────────────────────────────────────────
# install = regenera zion (bashly) + symlink + copia bootstrap para scripts/
# install-bootstrap = só copia bootstrap (mounts em /workspace/nixos) para scripts/bootstrap.sh

install-bootstrap:
	@mkdir -p scripts
	@install -m 755 zion/scripts/bootstrap-dashboard.sh scripts/bootstrap.sh
	@echo "[make] scripts/bootstrap.sh atualizado (fonte: zion/scripts/bootstrap-dashboard.sh)"

%:
	@$(MAKE) -C zion/cli $@
