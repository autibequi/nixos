# Makefile — claude-nix-sandbox
# Uso: make <target>

COMPOSE_FILE := docker-compose.claude.yml
SERVICE      := sandbox
OPENCLAW_SVC := openclaw

.PHONY: help shell build rebuild start stop logs start-openclaw stop-openclaw logs-openclaw openclaw claw

help:
	@echo "Targets disponíveis:"
	@echo "  make shell            — abre shell interativo no container sandbox"
	@echo "  make build            — builda a imagem (sem cache: make rebuild)"
	@echo "  make rebuild          — rebuild forçado da imagem"
	@echo "  make start            — sobe sandbox em background"
	@echo "  make stop             — derruba o container sandbox"
	@echo "  make logs             — tail dos logs do sandbox"
	@echo "  make start-openclaw   — sobe container openclaw (gateway isolado)"
	@echo "  make stop-openclaw    — derruba o container openclaw"
	@echo "  make logs-openclaw    — tail dos logs do openclaw"
	@echo "  make claw             — abre openclaw TUI (sandbox → gateway via host network)"
	@echo "  make openclaw         — abre shell no container openclaw"

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

# Sobe container openclaw dedicado (gateway + vault isolado)
start-openclaw:
	@mkdir -p $(HOME)/.ovault/Work/openclaw
	docker compose -f $(COMPOSE_FILE) up -d $(OPENCLAW_SVC)
	@echo "Gateway openclaw subindo em claude-openclaw. Verificar: make logs-openclaw"

# Derruba container openclaw
stop-openclaw:
	docker compose -f $(COMPOSE_FILE) stop $(OPENCLAW_SVC)

# Logs do container openclaw
logs-openclaw:
	docker compose -f $(COMPOSE_FILE) logs -f $(OPENCLAW_SVC)

# Shell dentro do container openclaw
openclaw:
	docker compose -f $(COMPOSE_FILE) exec $(OPENCLAW_SVC) bash

# Abre openclaw TUI no sandbox (gateway acessível via host network)
claw:
	@rm -f $(HOME)/.openclaw/agents/main/sessions/sessions.json \
		$(HOME)/.openclaw/agents/main/sessions/*.jsonl
	docker compose -f $(COMPOSE_FILE) restart $(OPENCLAW_SVC)
	@sleep 2
	docker compose -f $(COMPOSE_FILE) exec \
		$(SERVICE) openclaw tui
