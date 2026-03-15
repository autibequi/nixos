.PHONY: help switch update stow restow

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
	@echo "  Claudinho (make -C claudinho)"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make -C claudinho help Mostra comandos do claudinho"
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

# ── Proxy claudinho targets ───────────────────────────────────────

%:
	@$(MAKE) -C claudinho $@
