.PHONY: get-ids reload switch update stow restow stow-tree stow-confirm \
       sandbox sandbox-build sandbox-shell sandbox-down sandbox-restart sandbox-inject \
       clau clau-status usage

# ── NixOS ──────────────────────────────────────────────────────────

switch:
	nh os switch .

update:
	nh os switch --update .

get-ids:
	cat /etc/nixos/hardware-configuration.nix | grep -B 3 "device ="

reload:
	git update-index --no-skip-worktree hardware.nix
	git add hardware.nix
	git update-index --skip-worktree hardware.nix

# ── Dotfiles ───────────────────────────────────────────────────────

stow:
	stow --target=$$HOME --no-folding --adopt -R stow

restow:
	stow --target=$$HOME -D stow
	stow --target=$$HOME --no-folding -R stow

stow-tree:
	@echo "=== Árvore de dotfiles (stow/) ==="
	@find stow/ -type f \
		-not -path '*/skill-evaluations/*' \
		-not -path '*/.git/*' \
		| sed 's|^stow/|~/|' | sort

stow-confirm:
	@echo "=== Arquivos que serão injetados ==="
	@stow --target=$$HOME --no-folding -R stow --simulate 2>&1 | sort
	@echo ""
	@read -p "Confirma restow? [y/N] " confirm && [ "$$confirm" = "y" ] && \
		$(MAKE) restow || echo "Cancelado."

# ── Sandbox Interativo ─────────────────────────────────────────────

COMPOSE = docker compose -f docker-compose.claude.yml

sandbox-build:
	$(COMPOSE) build

sandbox:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --permission-mode bypassPermissions -- "startup"

sandbox-shell:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox bash

sandbox-restart:
	$(COMPOSE) down
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --permission-mode bypassPermissions -- "startup"

sandbox-inject:
	$(MAKE) restow
	$(MAKE) sandbox-restart

sandbox-down:
	$(COMPOSE) down

# ── Autônomo ───────────────────────────────────────────────────────

clau:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec -T sandbox bash /workspace/scripts/clau-runner.sh

clau-status:
	@echo "=== Pending ==="
	@ls -1 tasks/pending/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Running ==="
	@ls -1 tasks/running/ 2>/dev/null || echo "(vazio)"
	@echo "\n=== Done ==="
	@ls -1 tasks/done/ 2>/dev/null || echo "(vazio)"
	@echo "\n=== Failed ==="
	@ls -1 tasks/failed/ 2>/dev/null || echo "(vazio)"

# ── Utils ──────────────────────────────────────────────────────────

usage:
	@echo "=== Uso do mês ==="
	@cat .ephemeral/usage/$$(date +%Y-%m).jsonl 2>/dev/null | jq -s \
		'{ tasks: length, total_duration: (map(.duration) | add), entries: . }' \
		|| echo "Sem dados de uso ainda."
