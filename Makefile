# NixOS — root Makefile
# Uso: make <alvo>
# Requer: make, nh, stow

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.PHONY: help switch update zed-update yaak-update stow restow

help: ## Lista os alvos disponíveis
	@grep -E '^[a-z][a-zA-Z_-]*:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*## "}{printf "  \033[1m%-12s\033[0m %s\n", $$1, $$2}'

# ── NixOS ──────────────────────────────────────────────────────────────────

switch: ## Aplica a config NixOS (nh os switch)
	nh os switch .

update: ## Atualiza o flake inteiro e aplica
	nh os switch --update .

zed-update: ## Atualiza o Zed pro último stable (binário oficial) e aplica
	@latest=$$(git ls-remote --tags https://github.com/zed-industries/zed.git | sed 's|.*refs/tags/||' | grep -vE '\^\{\}' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$$' | sort -V | tail -1)
	[ -n "$$latest" ] || { echo "erro: nenhuma tag stable encontrada"; exit 1; }
	ver=$${latest#v}
	pkg=modules/apps/zed.nix
	current=$$(grep -oE 'version = "[0-9.]+"' $$pkg | head -1 | grep -oE '[0-9.]+')
	if [ "$$current" = "$$ver" ]; then echo "Zed já na $$ver — nada a fazer"; exit 0; fi
	url="https://github.com/zed-industries/zed/releases/download/$$latest/zed-linux-x86_64.tar.gz"
	echo "Zed: $$current → $$ver — prefetch do tarball oficial..."
	hash=$$(nix store prefetch-file --json "$$url" | jq -r .hash)
	{ [ -n "$$hash" ] && [ "$$hash" != null ]; } || { echo "erro: prefetch falhou"; exit 1; }
	sed -i -E "s|(version = \")[0-9.]+(\";)|\1$$ver\2|" $$pkg
	sed -i -E "s|(hash = \")sha256-[A-Za-z0-9+/=]+(\";)|\1$$hash\2|" $$pkg
	echo "→ Zed $$ver  ($$hash)"
	nh os switch .

yaak-update: ## Atualiza o Yaak pro último release (AppImage) e aplica
	@latest=$$(git ls-remote --tags https://github.com/mountain-loop/yaak.git | sed 's|.*refs/tags/||' | grep -vE '\^\{\}' | grep -E '^v[0-9]{4}\.[0-9]+\.[0-9]+$$' | sort -V | tail -1)
	[ -n "$$latest" ] || { echo "erro: nenhuma tag encontrada"; exit 1; }
	ver=$${latest#v}
	pkg=modules/apps/yaak.nix
	git add $$pkg modules/apps/yaak.png
	current=$$(grep -oE 'version = "[^"]+"' $$pkg | head -1 | grep -oE '[0-9.]+')
	cur_hash=$$(grep -oE 'hash = "sha256-[^"]*"' $$pkg | grep -oE 'sha256-[A-Za-z0-9+/=]+')
	if [ "$$current" = "$$ver" ] && [ "$$cur_hash" != "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=" ]; then echo "Yaak já na $$ver — nada a fazer"; exit 0; fi
	url="https://github.com/mountain-loop/yaak/releases/download/$$latest/yaak_$${ver}_amd64.AppImage"
	echo "Yaak: $$current → $$ver — prefetch do AppImage..."
	hash=$$(nix store prefetch-file --json "$$url" | jq -r .hash)
	{ [ -n "$$hash" ] && [ "$$hash" != null ]; } || { echo "erro: prefetch falhou"; exit 1; }
	sed -i -E "s|(version = \")[^\"]+(\";)|\1$$ver\2|" $$pkg
	sed -i -E "s|(hash = \")sha256-[A-Za-z0-9+/=]+(\";)|\1$$hash\2|" $$pkg
	echo "→ Yaak $$ver  ($$hash)"
	git add $$pkg modules/apps/yaak.png
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
