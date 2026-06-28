# NixOS — root Makefile
# Uso: make <alvo>
# Requer: make, nh, stow

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
.PHONY: help switch update upgrade zed-update yaak-update stow restow space

help: ## Lista os alvos disponíveis
	@grep -E '^[a-z][a-zA-Z_-]*:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*## "}{printf "  \033[1m%-12s\033[0m %s\n", $$1, $$2}'

# ── NixOS ──────────────────────────────────────────────────────────────────

switch: ## Aplica a config NixOS (nh os switch)
	nh os switch .

update: ## Atualiza o flake inteiro e aplica
	nh os switch --update .

upgrade: stow ## Reinjeta dotfiles, atualiza/aplica NixOS e reinicia serviços user
	nh os switch --update .
	systemctl --user daemon-reload
	systemctl --user restart waybar hypridle quickshell

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

# ── Manutenção ──────────────────────────────────────────────────────────────

space: ## Mostra maiores consumidores de disco por pasta/cache/podman
	@limit="$${SPACE_LIMIT:-30}"
	root="$${SPACE_ROOT:-$$HOME}"
	fs_target="$${SPACE_FS_TARGET:-$$root}"
	read -r fs_size fs_used fs_avail fs_pct fs_mount < <(df -B1 --output=size,used,avail,pcent,target "$$fs_target" | awk 'NR == 2 { print $$1, $$2, $$3, $$4, $$5 }')
	human() { numfmt --to=iec-i --suffix=B --format='%.1f' "$$1"; }
	section_du() {
	  local title="$$1" dir="$$2"
	  [[ -d "$$dir" ]] || return 0
	  printf '\n## %s (%s)\n' "$$title" "$$dir"
	  printf '%12s %8s  %s\n' "SIZE" "%FS" "PATH"
	  { du -x -B1 -d 1 "$$dir" 2>/dev/null || true; } \
	    | sort -nr \
	    | awk -v total="$$fs_size" -v limit="$$limit" 'NR <= limit { pct = total > 0 ? ($$1 / total) * 100 : 0; printf "%12d %7.2f%%  %s\n", $$1, pct, $$2 }' \
	    | numfmt --field=1 --to=iec-i --suffix=B --format='%8.1f'
	}
	printf 'Filesystem: %s\n' "$$fs_mount"
	printf 'Total: %s  Used: %s (%s)  Free: %s\n' "$$(human "$$fs_size")" "$$(human "$$fs_used")" "$$fs_pct" "$$(human "$$fs_avail")"
	printf 'Limit per section: %s entries (SPACE_LIMIT=N)\n' "$$limit"
	section_du '$$HOME' "$$root"
	section_du '$$HOME/.local/share' "$$root/.local/share"
	section_du '$$HOME/.cache' "$$root/.cache"
	section_du '$$HOME/projects' "$$root/projects"
	section_du '$$HOME/Downloads' "$$root/Downloads"
	if command -v podman >/dev/null 2>&1; then
	  printf '\n## Podman images\n'
	  podman images --format 'table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.Created}}' 2>/dev/null || true
	  printf '\n## Podman containers\n'
	  podman ps -a --format 'table {{.ID}}\t{{.Image}}\t{{.Names}}\t{{.Status}}\t{{.Size}}' --size 2>/dev/null || true
	fi
