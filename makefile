CONTAINER := claude-sandbox

.PHONY: help switch update stow restow build start shell sandbox resume down destroy inject openclaw \
       clau run auto stop reset status new logs logs-list \
       usage-api usage-api-7d usage-api-30d clau-service-logs ask claw claw-stop code code-stop attach claudio codio

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
	@echo "  Container"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make build             Build da imagem Docker"
	@echo "  make claudio [dir=path] Abre Claude isolado por projeto (multi-instância)"
	@echo "  make attach [dir=path] Abre sandbox isolado por projeto (multi-instância, default: pwd)"
	@echo "  make start             Sobe sandbox + bootstrap + Claude Code"
	@echo "  make sandbox           Idem (bootstrap depois abre Claude)"
	@echo "  make shell             Sobe sandbox + só bash (bootstrap no .bashrc)"
	@echo "  make resume            Retoma sessão Claude anterior (usa API)"
	@echo "  make down              Para todos os containers"
	@echo "  make destroy           Para containers + remove imagens"
	@echo "  make inject            Restow + restart sandbox + shell"
	@echo "  make openclaw          Sobe sandbox e roda openclaw gateway no container"
	@echo "  make code              Sobe sandbox e roda OpenCode (TUI) no container"
	@echo "  make code-stop         Encerra opencode no container"
	@echo "  make codio [dir=path]  Abre OpenCode isolado por projeto (multi-instância, monta pwd)"
	@echo ""
	@echo "  Tasks"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make run               Roda worker every60 com output"
	@echo "  make run task=nome     Roda task específica com output"
	@echo "  make run-fast          Roda worker every10 com output"
	@echo "  make auto              Roda worker headless (systemd)"
	@echo "  make auto-fast         Roda worker every10 headless"
	@echo "  make clau              Lança workers (every60 x2)"
	@echo "                         Vários runners: use CLAU_WORKER_ID diferente por processo"
	@echo "  make stop              Para workers + reseta tasks presas"
	@echo "  make reset             Devolve tasks de running/ pra origem"
	@echo "  make status            Mostra estado via kanban + workers"
	@echo "  make new name=x        Cria task + card no kanban"
	@echo ""
	@echo "  Logs"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make logs              Mostra/segue último log"
	@echo "  make logs-list         Lista todos os logs"
	@echo "  make clau-service-logs Logs do systemd service"
	@echo "  make usage-api         Uso da API Anthropic (hoje)"
	@echo ""
	@echo "  Quick"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make ask q='pergunta'  Abre Alacritty com Claude respondendo"
	@echo "  make ask               Abre Claude interativo em Alacritty"
	@echo ""

# ── NixOS ──────────────────────────────────────────────────────────

switch:
	nh os switch .

update:
	nh os switch --update .

# ── Dotfiles ───────────────────────────────────────────────────────

stow:
	stow --target=$$HOME --no-folding --adopt -R stow

restow:
	stow --target=$$HOME --no-folding --adopt --override=file -R stow

# ── Container ──────────────────────────────────────────────────────

COMPOSE = docker compose -f docker-compose.claude.yml
LOGDIR  = logs
LOGFILE = $(LOGDIR)/$$(date +%Y-%m-%dT%H:%M:%S.%3N).log

build:
	$(COMPOSE) build

VAULT_KANBAN = $(HOME)/.ovault/Work/kanban.md

clau:
	@if [ ! -f "$(VAULT_KANBAN)" ]; then \
		echo "[clau] kanban.md não encontrado em $(VAULT_KANBAN)"; \
		exit 1; \
	fi
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	echo "[clau] Log: $$logfile"; \
	for i in 1 2; do \
		WORKER_ID="worker-$$i"; \
		existing=$$(podman ps --filter "name=_worker_" --filter "label=clau.worker.id=$$WORKER_ID" --format "{{.ID}}" 2>/dev/null | head -1); \
		if [ -n "$$existing" ]; then \
			echo "[clau] $$WORKER_ID já rodando ($$existing) — skip"; \
			continue; \
		fi; \
		echo "[clau] Lançando $$WORKER_ID (every60)..."; \
		$(COMPOSE) run --rm -T \
			-e CLAU_WORKER_ID="$$WORKER_ID" \
			-e CLAU_CLOCK=every60 \
			-l clau.worker.id="$$WORKER_ID" \
			worker /workspace/host/scripts/clau-runner.sh >> "$$logfile" 2>&1 & \
	done; \
	echo "[clau] Workers lançados. Seguindo log..."; \
	tail -f "$$logfile"

start: sandbox

start-haiku: sandbox-haiku

sandbox-haiku:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec -it sandbox bash -c '. /workspace/host/scripts/bootstrap.sh; exec /home/claude/.nix-profile/bin/claude --model claude-haiku-4-5-20251001 --permission-mode bypassPermissions'

claudio:
	$(eval MOUNT_DIR := $(abspath $(or $(dir),$(shell pwd))))
	$(eval PROJ_SLUG := $(shell basename "$(abspath $(or $(dir),$(shell pwd)))" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$$//'))
	$(eval CLAU_PROJ := clau-$(PROJ_SLUG))
	@touch $(HOME)/.claude.json
	@echo "[claudio] $(PROJ_SLUG) → projeto $(CLAU_PROJ)"
	@CLAUDIO_MOUNT="$(MOUNT_DIR)" docker compose -f docker-compose.claude.yml -p "$(CLAU_PROJ)" up -d sandbox
	@CLAUDIO_MOUNT="$(MOUNT_DIR)" docker compose -f docker-compose.claude.yml -p "$(CLAU_PROJ)" exec -it \
		-e CLAUDIO_MOUNT="$(MOUNT_DIR)" sandbox bash -c \
		'. /workspace/host/scripts/bootstrap.sh; exec /home/claude/.nix-profile/bin/claude --permission-mode bypassPermissions'

attach:
	$(eval MOUNT_DIR := $(abspath $(or $(dir),$(shell pwd))))
	$(eval PROJ_SLUG := $(shell basename "$(abspath $(or $(dir),$(shell pwd)))" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$$//'))
	$(eval CLAU_PROJ := clau-$(PROJ_SLUG))
	@mkdir -p /tmp/claude-mount-empty
	@echo "[attach] $(PROJ_SLUG) → projeto $(CLAU_PROJ) (mount: $(MOUNT_DIR))"
	@CLAUDIO_MOUNT="$(MOUNT_DIR)" $(COMPOSE) -p "$(CLAU_PROJ)" up -d --no-recreate sandbox
	@CLAUDIO_MOUNT="$(MOUNT_DIR)" $(COMPOSE) -p "$(CLAU_PROJ)" exec -it \
		-e CLAUDIO_MOUNT="$(MOUNT_DIR)" sandbox bash -c \
		'. /workspace/host/scripts/bootstrap.sh; exec /home/claude/.nix-profile/bin/claude --permission-mode bypassPermissions'

sandbox:
	@touch $(HOME)/.claude.json
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec -it sandbox bash -c '. /workspace/host/scripts/bootstrap.sh; exec /home/claude/.nix-profile/bin/claude --permission-mode bypassPermissions'

shell:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec -it sandbox bash

resume:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox /home/claude/.nix-profile/bin/claude --resume --permission-mode bypassPermissions

claw:
	$(COMPOSE) exec sandbox openclaw tui

claw-stop:
	$(COMPOSE) stop openclaw

down:
	$(COMPOSE) down

destroy:
	$(COMPOSE) down --rmi all --volumes

inject:
	$(MAKE) restow
	$(COMPOSE) down
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec -it sandbox bash -c '. /workspace/host/scripts/bootstrap.sh; exec /home/claude/.nix-profile/bin/claude --permission-mode bypassPermissions "oi"'

openclaw:
	@mkdir -p $(HOME)/.openclaw && \
	if [ ! -f $(HOME)/.openclaw/openclaw.json ]; then \
		cp .openclaw/openclaw.json $(HOME)/.openclaw/openclaw.json && \
		echo "[openclaw] Config copiada para $(HOME)/.openclaw (LM Studio em host.docker.internal:1234)"; \
	fi
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec -it sandbox openclaw gateway

code:
	$(COMPOSE) up -d opencode
	@$(COMPOSE) exec -it opencode opencode

code-stop:
	@$(COMPOSE) exec opencode pkill opencode 2>/dev/null || true

codio:
	$(eval MOUNT_DIR := $(abspath $(or $(dir),$(shell pwd))))
	$(eval PROJ_SLUG := $(shell basename "$(abspath $(or $(dir),$(shell pwd)))" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-*$$//'))
	$(eval CODIO_PROJ := codio-$(PROJ_SLUG))
	@echo "[codio] $(PROJ_SLUG) → projeto $(CODIO_PROJ)"
	@CLAUDIO_MOUNT="$(MOUNT_DIR)" docker compose -f docker-compose.claude.yml -p "$(CODIO_PROJ)" up -d sandbox
	@CLAUDIO_MOUNT="$(MOUNT_DIR)" docker compose -f docker-compose.claude.yml -p "$(CODIO_PROJ)" exec -it \
		-e CLAUDIO_MOUNT="$(MOUNT_DIR)" sandbox bash -c \
		'cd /workspace/mount && exec opencode'

# ── Tasks ──────────────────────────────────────────────────────────
# Vários runners por linha de comando: use CLAU_WORKER_ID diferente em cada um.
# Ex.: CLAU_WORKER_ID=worker-1 make run &  CLAU_WORKER_ID=worker-2 make run
# Mesmo WORKER_ID em dois processos = um pode recuperar a task do outro como órfã.

run:
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	echo "[clau] Log: $$logfile"; \
	$(COMPOSE) run --rm -e CLAU_VERBOSE=1 -e CLAU_CLOCK=every60 \
		-e CLAU_WORKER_ID=$${CLAU_WORKER_ID:-worker-1} \
		worker /workspace/host/scripts/clau-runner.sh $(task) 2>&1 | tee "$$logfile"

run-fast:
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	echo "[clau] Log: $$logfile"; \
	$(COMPOSE) run --rm -e CLAU_VERBOSE=1 -e CLAU_CLOCK=every10 \
		-e CLAU_WORKER_ID=$${CLAU_WORKER_ID:-worker-fast} \
		worker-fast /workspace/host/scripts/clau-runner.sh 2>&1 | tee "$$logfile"

auto:
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	$(COMPOSE) run --rm -T -e CLAU_CLOCK=every60 \
		-e CLAU_WORKER_ID=$${CLAU_WORKER_ID:-worker-1} \
		worker /workspace/host/scripts/clau-runner.sh > "$$logfile" 2>&1

auto-fast:
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	$(COMPOSE) run --rm -T -e CLAU_CLOCK=every10 \
		-e CLAU_WORKER_ID=$${CLAU_WORKER_ID:-worker-fast} \
		worker-fast /workspace/host/scripts/clau-runner.sh > "$$logfile" 2>&1

stop:
	@echo "[clau] Parando workers..."
	@$(COMPOSE) kill worker 2>/dev/null || true
	@$(COMPOSE) kill worker-fast 2>/dev/null || true
	@$(COMPOSE) rm -f worker worker-fast 2>/dev/null || true
	@$(MAKE) --no-print-directory reset

reset:
	@for dir in vault/_agent/tasks/running/*/; do \
		[ -d "$$dir" ] || continue; \
		name=$$(basename "$$dir"); \
		source=$$(grep '^source=' "$$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending"); \
		rm -f "$$dir/.lock"; \
		if [ "$$source" = "recurring" ]; then \
			rm -rf "$$dir"; \
			echo "[reset] $$name (recurring) removed"; \
		else \
			mv "$$dir" "vault/_agent/tasks/pending/$$name"; \
			echo "[reset] $$name → pending/"; \
		fi; \
	done
	@rm -f .ephemeral/.kanban.lock .ephemeral/locks/*.lock
	@echo "[reset] done"

status:
	@echo "=== Workers ==="
	@podman ps --filter "name=_worker_" --format "table {{.ID}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null || echo "(nenhum)"
	@echo "\n=== Kanban ==="
	@if [ -f vault/_agent/scheduled.md ]; then \
		for col in "Recorrentes" "Em Execução"; do \
			count=0; in_col=0; \
			while IFS= read -r line; do \
				if [ "$$line" = "## $$col" ]; then in_col=1; continue; fi; \
				if echo "$$line" | grep -q '^## ' && [ "$$in_col" = "1" ]; then break; fi; \
				if [ "$$in_col" = "1" ] && echo "$$line" | grep -q '^- \['; then count=$$((count + 1)); fi; \
			done < vault/_agent/scheduled.md; \
			echo "  $$col: $$count"; \
		done; \
	fi
	@if [ -f vault/kanban.md ]; then \
		for col in "Backlog" "Em Andamento" "Aprovado" "Falhou"; do \
			count=0; in_col=0; \
			while IFS= read -r line; do \
				if [ "$$line" = "## $$col" ]; then in_col=1; continue; fi; \
				if echo "$$line" | grep -q '^## ' && [ "$$in_col" = "1" ]; then break; fi; \
				if [ "$$in_col" = "1" ] && echo "$$line" | grep -q '^- \['; then count=$$((count + 1)); fi; \
			done < vault/kanban.md; \
			echo "  $$col: $$count"; \
		done; \
	fi
	@echo "\n=== Em Andamento ==="
	@in_col=0; \
	while IFS= read -r line; do \
		if [ "$$line" = "## Em Andamento" ]; then in_col=1; continue; fi; \
		if echo "$$line" | grep -q '^## ' && [ "$$in_col" = "1" ]; then break; fi; \
		if [ "$$in_col" = "1" ] && echo "$$line" | grep -q '^- \['; then echo "  $$line"; fi; \
	done < vault/kanban.md 2>/dev/null || echo "  (vazio)"

new:
	@[ -n "$(name)" ] || (echo "Uso: make new name=minha-tarefa [type=recurring|pending] [model=haiku|sonnet] [clock=every10|every60] [timeout=300]" && exit 1)
	@task_type="$${type:-pending}"; \
	task_model="$${model:-$$([ "$$task_type" = "recurring" ] && echo "haiku" || echo "sonnet")}"; \
	task_clock="$${clock:-$$([ "$$task_type" = "recurring" ] && echo "every10" || echo "every60")}"; \
	task_timeout="$${timeout:-$$([ "$$task_clock" = "every10" ] && echo "120" || echo "300")}"; \
	task_dir="vault/_agent/tasks/$$task_type/$(name)"; \
	mkdir -p "$$task_dir"; \
	printf '%s\n' \
		"---" \
		"clock: $$task_clock" \
		"timeout: $$task_timeout" \
		"model: $$task_model" \
		"schedule: always" \
		"---" \
		"# $(name)" \
		"" \
		"## Objetivo" \
		"" \
		"## O que fazer" \
		"" \
		"## Entregável" \
		"Atualize \`<diretório de contexto>/contexto.md\`." \
		> "$$task_dir/CLAUDE.md"; \
	kanban_col="Backlog"; kanban_file="vault/kanban.md"; \
	if [ "$$task_type" = "recurring" ]; then kanban_col="Recorrentes"; kanban_file="vault/_agent/scheduled.md"; fi; \
	card="- [ ] **$(name)** #$$task_type $$(date +%Y-%m-%d) \`$$task_model\`"; \
	KANBAN_FILE="$$kanban_file" source scripts/kanban-sync.sh && kanban_add_card "$$kanban_col" "$$card" 2>/dev/null || \
		echo "[AVISO] Não conseguiu adicionar card no kanban"; \
	echo "Task: $$task_dir/ ($$task_model, $$task_tier, $${task_timeout}s)"

# ── Quick Ask ──────────────────────────────────────────────────────

ask:
	@bash scripts/claude-ask.sh "$(q)"

# ── Logs ───────────────────────────────────────────────────────────

clau-service-logs:
	@journalctl -u claude-autonomous.service -n 30 -f

logs:
	@latest=$$(ls -1t logs/*.log 2>/dev/null | head -1); \
	if [ -z "$$latest" ]; then \
		echo "(nenhum log)"; \
	else \
		id=$$(podman ps --filter "name=_worker_" --format "{{.ID}}" 2>/dev/null | head -1); \
		if [ -n "$$id" ]; then \
			echo "=== Seguindo $$latest ==="; \
			tail -f "$$latest"; \
		else \
			echo "=== $$latest ==="; \
			cat "$$latest"; \
		fi; \
	fi

logs-list:
	@ls -1t logs/*.log 2>/dev/null || echo "(nenhum log)"

# ── Usage ──────────────────────────────────────────────────────────

usage-api:
	@bash scripts/api-usage.sh

usage-api-7d:
	@bash scripts/api-usage.sh 7d

usage-api-30d:
	@bash scripts/api-usage.sh 30d
