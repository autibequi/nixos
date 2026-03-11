.PHONY: get-ids reload switch update stow restow claude-sandbox claude-sandbox-build claude-sandbox-shell claude-sandbox-down

get-ids:
	cat /etc/nixos/hardware-configuration.nix | grep -B 3 "device ="

reload:
	git update-index --no-skip-worktree hardware.nix
	git add hardware.nix
	git update-index --skip-worktree hardware.nix

switch:
	nh os switch .

update:
	nh os switch --update .

stow:
	stow --target=$$HOME --no-folding --adopt -R stow

restow:
	stow --target=$$HOME -D stow
	stow --target=$$HOME --no-folding -R stow

COMPOSE_CLAUDE = docker compose -f docker-compose.claude.yml

claude-sandbox-build:
	$(COMPOSE_CLAUDE) build

claude-sandbox:
	$(COMPOSE_CLAUDE) up -d sandbox
	@$(COMPOSE_CLAUDE) exec sandbox claude --permission-mode bypassPermissions

claude-sandbox-down:
	$(COMPOSE_CLAUDE) down
