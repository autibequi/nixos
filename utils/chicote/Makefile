# chicote — subprojeto isolado. Não depende do repo pai.
# Uso: make install   (builda e põe o binário no PATH)

PREFIX ?= $(HOME)/.local

.PHONY: build install run clean

# path:. força o flake local — sem isso, dentro do repo git o nix sobe pro flake raiz.
build: ## Builda o binário release (raylib via flake)
	nix develop path:. -c cargo build --release

install: build ## Builda e instala em $(PREFIX)/bin
	install -Dm755 target/release/chicote "$(PREFIX)/bin/chicote"
	@echo "chicote → $(PREFIX)/bin/chicote (MOD3+s pra ligar; integração em README.md)"

run: ## Roda direto sem instalar
	nix develop path:. -c cargo run --release

clean: ## Limpa o target
	cargo clean
