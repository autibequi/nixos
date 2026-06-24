# NixOS — root Makefile
# Uso: make <alvo>
# Requer: make, nh, stow

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.PHONY: help switch update zed-update stow restow

help: ## Lista os alvos disponíveis
	@grep -E '^[a-z][a-zA-Z_-]*:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*## "}{printf "  \033[1m%-12s\033[0m %s\n", $$1, $$2}'

# ── NixOS ──────────────────────────────────────────────────────────────────

switch: ## Aplica a config NixOS (nh os switch)
	nh os switch .

update: ## Atualiza o flake inteiro e aplica
	nh os switch --update .

zed-update: ## Atualiza o Zed pra última tag do canal pinado (stable ou -pre) e aplica
	@current=$$(grep -oE 'zed-industries/zed/v[0-9][0-9.]*(-pre)?' flake.nix | sed 's|.*/||')
	[ -n "$$current" ] || { echo "erro: não achei o pin do zed em flake.nix"; exit 1; }
	case "$$current" in
	  *-pre) filter='-pre$$' ;;
	  *)     filter='[0-9]$$' ;;
	esac
	latest=$$(git ls-remote --tags https://github.com/zed-industries/zed.git | sed 's|.*refs/tags/||' | grep -vE '\^\{\}' | grep -E "^v[0-9].*$$filter" | sort -V | tail -1)
	[ -n "$$latest" ] || { echo "erro: nenhuma tag encontrada"; exit 1; }
	if [ "$$current" = "$$latest" ]; then echo "Zed já na $$latest — nada a fazer"; exit 0; fi
	echo "Zed: $$current → $$latest"
	sed -i -E "s|(zed-industries/zed/)v[0-9][0-9.]*(-pre)?|\1$$latest|" flake.nix
	nix flake update zed
	nh os switch .

# ── Dotfiles ───────────────────────────────────────────────────────────────

stow: ## Injeta dotfiles via stow (limpa conflitos em .config/bardiel antes)
	@for dir in agents commands hooks scripts skills; do
	  link="$$HOME/.claude/$$dir"
	  if [ -L "$$link" ]; then
	    target=$$(readlink "$$link")
	    case "$$target" in /workspace/*) echo "removing container symlink: $$link"; rm -f "$$link" ;; esac
	  fi
	done
	{ find stow/.config/bardiel -type f 2>/dev/null || true; } | while read -r src; do
	  tgt="$$HOME/$${src#stow/}"
	  { [ -e "$$tgt" ] || [ -L "$$tgt" ]; } && rm -f "$$tgt" || true
	done
	stow --target="$$HOME" --no-folding --adopt -S stow

restow: stow ## Re-injeta dotfiles (alias de stow)
