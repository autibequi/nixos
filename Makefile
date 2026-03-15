# Makefile — claude-nix-sandbox
# Uso: make <target>

COMPOSE_FILE := docker-compose.claude.yml
SERVICE      := sandbox
OPENCLAW_SVC := openclaw
OPENCODE_SVC := opencode

.PHONY: help shell build rebuild up start stop logs start-openclaw stop-openclaw logs-openclaw openclaw claw claw-stop start-code stop-code logs-code code code-stop

help:
	@echo "Targets disponíveis:"
	@echo "  make shell            — abre shell interativo no container sandbox"
	@echo "  make build            — builda a imagem (sem cache: make rebuild)"
	@echo "  make rebuild          — rebuild forçado da imagem"
	@echo "  make up               — sobe sandbox + workers com mounts preparados"
	@echo "  make start            — sobe sandbox em background"
	@echo "  make stop             — derruba o container sandbox"
	@echo "  make logs             — tail dos logs do sandbox"
	@echo "  make start-openclaw   — sobe container openclaw (gateway isolado)"
	@echo "  make stop-openclaw    — derruba o container openclaw"
	@echo "  make logs-openclaw    — tail dos logs do openclaw"
	@echo "  make claw             — abre openclaw TUI (sandbox → gateway via host network)"
	@echo "  make claw-stop        — derruba o container openclaw"
	@echo "  make openclaw         — abre shell no container openclaw"
	@echo "  make start-code       — sobe container opencode"
	@echo "  make stop-code        — derruba container opencode"
	@echo "  make logs-code        — tail dos logs do opencode"
	@echo "  make code             — abre opencode TUI no container"
	@echo "  make code-stop        — derruba container opencode"

shell:
	docker compose -f $(COMPOSE_FILE) exec $(SERVICE) bash

build:
	docker compose -f $(COMPOSE_FILE) build

rebuild:
	docker compose -f $(COMPOSE_FILE) build --no-cache

# Prepare mounts e sobe sandbox + workers
up: _prepare-mounts
	@echo "Subindo sandbox + workers com mounts preparados..."
	docker compose -f $(COMPOSE_FILE) up -d $(SERVICE) worker worker-fast

# Helper — cria todos os diretórios de mount necessários
_prepare-mounts:
	@mkdir -p $(HOME)/projects
	@mkdir -p $(HOME)/.openclaw
	@mkdir -p $(HOME)/.opencode
	@mkdir -p $(HOME)/.ovault/Work
	@mkdir -p $(HOME)/.ovault/Work/openclaw
	@mkdir -p $(HOME)/.ovault/Work/opencode
	@echo "✓ Mounts preparados"

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

# OpenCode — AI coding assistant
start-code: _prepare-mounts
	docker compose -f $(COMPOSE_FILE) up -d $(OPENCODE_SVC)
	@echo "Container opencode subindo em claude-opencode."

stop-code:
	docker compose -f $(COMPOSE_FILE) stop $(OPENCODE_SVC)

logs-code:
	docker compose -f $(COMPOSE_FILE) logs -f $(OPENCODE_SVC)

# Abre opencode TUI no container dedicado
code: _prepare-mounts
	docker compose -f $(COMPOSE_FILE) up -d $(OPENCODE_SVC)
	docker compose -f $(COMPOSE_FILE) exec $(OPENCODE_SVC) opencode

# Para o container opencode
code-stop:
	docker compose -f $(COMPOSE_FILE) stop $(OPENCODE_SVC)

# Para o container openclaw
claw-stop:
	docker compose -f $(COMPOSE_FILE) stop $(OPENCLAW_SVC)

# Abre openclaw TUI no sandbox (gateway acessível via host network)
claw:
	@rm -f $(HOME)/.openclaw/agents/main/sessions/sessions.json \
		$(HOME)/.openclaw/agents/main/sessions/*.jsonl
	docker compose -f $(COMPOSE_FILE) restart $(OPENCLAW_SVC)
	@sleep 2
	docker compose -f $(COMPOSE_FILE) exec \
		$(SERVICE) openclaw tui
