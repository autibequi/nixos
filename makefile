CONTAINER := claude-sandbox
export GIT_AUTHOR_NAME := $(shell git config user.name)
export GIT_AUTHOR_EMAIL := $(shell git config user.email)
export GIT_COMMITTER_NAME := $(GIT_AUTHOR_NAME)
export GIT_COMMITTER_EMAIL := $(GIT_AUTHOR_EMAIL)

.PHONY: help switch update stow restow build start shell sandbox resume down destroy inject \
       clau run auto stop reset status new logs logs-list \
       usage-api usage-api-7d usage-api-30d clau-service-logs ask

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
	@echo "  make start             Sobe sandbox + abre Claude (alias sandbox)"
	@echo "  make sandbox           Sobe sandbox + abre Claude"
	@echo "  make shell             Sobe sandbox + abre bash"
	@echo "  make resume            Retoma sessão Claude anterior"
	@echo "  make down              Para todos os containers"
	@echo "  make destroy           Para containers + remove imagens"
	@echo "  make inject            Restow + restart sandbox + Claude"
	@echo ""
	@echo "  Tasks"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make run               Roda worker every60 com output"
	@echo "  make run task=nome     Roda task específica com output"
	@echo "  make run-fast          Roda worker every10 com output"
	@echo "  make auto              Roda worker headless (systemd)"
	@echo "  make auto-fast         Roda worker every10 headless"
	@echo "  make clau              Lança workers (every60 x2)"
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

COMPOSE = podman-compose -f docker-compose.claude.yml
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
			worker /workspace/scripts/clau-runner.sh >> "$$logfile" 2>&1 & \
	done; \
	echo "[clau] Workers lançados. Seguindo log..."; \
	tail -f "$$logfile"

start: sandbox

sandbox:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --permission-mode bypassPermissions -- "startup"

shell:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox bash

resume:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --resume --permission-mode bypassPermissions

down:
	$(COMPOSE) down

destroy:
	$(COMPOSE) down --rmi all --volumes

inject:
	$(MAKE) restow
	$(COMPOSE) down
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --permission-mode bypassPermissions -- "startup"

# ── Tasks ──────────────────────────────────────────────────────────

run:
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	echo "[clau] Log: $$logfile"; \
	$(COMPOSE) run --rm -e CLAU_VERBOSE=1 -e CLAU_CLOCK=every60 \
		-e CLAU_WORKER_ID=$${CLAU_WORKER_ID:-worker-1} \
		worker /workspace/scripts/clau-runner.sh $(task) 2>&1 | tee "$$logfile"

run-fast:
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	echo "[clau] Log: $$logfile"; \
	$(COMPOSE) run --rm -e CLAU_VERBOSE=1 -e CLAU_CLOCK=every10 \
		-e CLAU_WORKER_ID=$${CLAU_WORKER_ID:-worker-fast} \
		worker-fast /workspace/scripts/clau-runner.sh 2>&1 | tee "$$logfile"

auto:
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	$(COMPOSE) run --rm -T -e CLAU_CLOCK=every60 \
		-e CLAU_WORKER_ID=$${CLAU_WORKER_ID:-worker-1} \
		worker /workspace/scripts/clau-runner.sh > "$$logfile" 2>&1

auto-fast:
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	$(COMPOSE) run --rm -T -e CLAU_CLOCK=every10 \
		-e CLAU_WORKER_ID=$${CLAU_WORKER_ID:-worker-fast} \
		worker-fast /workspace/scripts/clau-runner.sh > "$$logfile" 2>&1

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
	@if [ -f vault/scheduled.md ]; then \
		for col in "Recorrentes" "Em Execução"; do \
			count=0; in_col=0; \
			while IFS= read -r line; do \
				if [ "$$line" = "## $$col" ]; then in_col=1; continue; fi; \
				if echo "$$line" | grep -q '^## ' && [ "$$in_col" = "1" ]; then break; fi; \
				if [ "$$in_col" = "1" ] && echo "$$line" | grep -q '^- \['; then count=$$((count + 1)); fi; \
			done < vault/scheduled.md; \
			echo "  $$col: $$count"; \
		done; \
	fi
	@if [ -f vault/kanban.md ]; then \
		for col in "Backlog" "Em Andamento" "Concluido" "Falhou"; do \
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
	if [ "$$task_type" = "recurring" ]; then kanban_col="Recorrentes"; kanban_file="vault/scheduled.md"; fi; \
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
