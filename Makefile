# Makefile — claude-nix-sandbox
# Uso: make <target>

COMPOSE_FILE := docker-compose.claude.yml
SERVICE      := sandbox

.PHONY: help shell build rebuild start stop logs openclaw start-openclaw claw

help:
	@echo "Targets disponíveis:"
	@echo "  make shell           — abre shell interativo no container sandbox"
	@echo "  make build           — builda a imagem (sem cache: make rebuild)"
	@echo "  make rebuild         — rebuild forçado da imagem"
	@echo "  make start           — sobe o container sandbox em background"
	@echo "  make stop            — derruba o container sandbox"
	@echo "  make logs            — tail dos logs do sandbox"
	@echo "  make claw            — abre openclaw TUI no Makefile"
	@echo "  make openclaw        — abre shell com openclaw pronto (gateway local)"
	@echo "  make start-openclaw  — inicia gateway openclaw em background no container"

shell:
	docker compose -f $(COMPOSE_FILE) exec $(SERVICE) bash

build:
	docker compose -f $(COMPOSE_FILE) build

rebuild:
	docker compose -f $(COMPOSE_FILE) build --no-cache

start:
	docker compose -f $(COMPOSE_FILE) up -d $(SERVICE)

stop:
	docker compose -f $(COMPOSE_FILE) stop $(SERVICE)

logs:
	docker compose -f $(COMPOSE_FILE) logs -f $(SERVICE)

# Abre shell já com openclaw configurado via OPENCLAW_CONFIG_PATH
openclaw:
	docker compose -f $(COMPOSE_FILE) exec \
		-e OPENCLAW_CONFIG_PATH=/home/claude/.openclaw/openclaw-container.json \
		$(SERVICE) bash

# Inicia o gateway openclaw em background no container
start-openclaw:
	docker compose -f $(COMPOSE_FILE) exec -d \
		-e OPENCLAW_CONFIG_PATH=/home/claude/.openclaw/openclaw-container.json \
		$(SERVICE) openclaw gateway
	@echo "Gateway openclaw iniciado no container. Verificar: make logs"

# Abre openclaw TUI no Makefile
claw:
	docker compose -f $(COMPOSE_FILE) exec \
		-e OPENCLAW_CONFIG_PATH=/home/claude/.openclaw/openclaw-container.json \
		$(SERVICE) openclaw tui noi makefile
