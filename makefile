.PHONY: get-ids reload switch update stow restow stow-tree stow-confirm \
       sandbox sandbox-build sandbox-shell sandbox-down sandbox-restart sandbox-inject \
       claude-resume clau clau-run clau-reset clau-status clau-workers usage

# ── NixOS ──────────────────────────────────────────────────────────

switch:
	nh os switch .

update:
	nh os switch --update .

get-ids:
	cat /etc/nixos/hardware-configuration.nix | grep -B 3 "device ="

reload:
	git update-index --no-skip-worktree hardware.nix
	git add hardware.nix
	git update-index --skip-worktree hardware.nix

# ── Dotfiles ───────────────────────────────────────────────────────

stow:
	stow --target=$$HOME --no-folding --adopt -R stow

restow:
	stow --target=$$HOME -D stow
	stow --target=$$HOME --no-folding -R stow

stow-tree:
	@echo "=== Árvore de dotfiles (stow/) ==="
	@find stow/ -type f \
		-not -path '*/skill-evaluations/*' \
		-not -path '*/.git/*' \
		| sed 's|^stow/|~/|' | sort

stow-confirm:
	@echo "=== Arquivos que serão injetados ==="
	@stow --target=$$HOME --no-folding -R stow --simulate 2>&1 | sort
	@echo ""
	@read -p "Confirma restow? [y/N] " confirm && [ "$$confirm" = "y" ] && \
		$(MAKE) restow || echo "Cancelado."

# ── Sandbox Interativo ─────────────────────────────────────────────

COMPOSE = docker compose -f docker-compose.claude.yml

sandbox-build:
	$(COMPOSE) build

sandbox:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --permission-mode bypassPermissions -- "startup"

sandbox-shell:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox bash

sandbox-restart:
	$(COMPOSE) down
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --permission-mode bypassPermissions -- "startup"

sandbox-inject:
	$(MAKE) restow
	$(MAKE) sandbox-restart

claude-resume:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --resume --permission-mode bypassPermissions

sandbox-down:
	$(COMPOSE) down

# ── Autônomo ───────────────────────────────────────────────────────

# Spawna um worker por task disponível (pending + recurring), cada um no seu container
clau:
	@pending=$$(ls -1 tasks/pending/ 2>/dev/null | grep -v '\.gitkeep'); \
	recurring=$$(ls -1 tasks/recurring/ 2>/dev/null | grep -v '\.gitkeep'); \
	all="$$pending $$recurring"; \
	count=0; \
	for task in $$all; do \
		[ -z "$$task" ] && continue; \
		[ -d "tasks/running/$$task" ] && echo "[clau] $$task já em running, skip" && continue; \
		echo "[clau] Spawning worker: $$task"; \
		$(COMPOSE) run --rm -d -T worker /workspace/scripts/clau-runner.sh 600 "$$task" & \
		count=$$((count + 1)); \
	done; \
	wait; \
	[ "$$count" -eq 0 ] && echo "[clau] Sem tarefas disponíveis." || echo "[clau] $$count workers spawned."

# Roda uma task específica: make clau-run task=nome-da-task
clau-run:
	@[ -n "$(task)" ] || (echo "Uso: make clau-run task=nome-da-task" && exit 1)
	$(COMPOSE) run --rm -T worker /workspace/scripts/clau-runner.sh 600 "$(task)"

# Reseta tasks presas em running/ → devolve pra origem
clau-reset:
	@$(COMPOSE) kill worker 2>/dev/null || true
	@$(COMPOSE) rm -f worker 2>/dev/null || true
	@for dir in tasks/running/*/; do \
		[ -d "$$dir" ] || continue; \
		name=$$(basename "$$dir"); \
		source=$$(grep '^source=' "$$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending"); \
		rm -f "$$dir/.lock"; \
		if [ "$$source" = "recurring" ]; then \
			mv "$$dir" "tasks/recurring/$$name"; \
			echo "[clau-reset] $$name → recurring/"; \
		else \
			mv "$$dir" "tasks/pending/$$name"; \
			echo "[clau-reset] $$name → pending/"; \
		fi; \
	done
	@[ -z "$$(ls -A tasks/running/ 2>/dev/null | grep -v '\.gitkeep')" ] && echo "[clau-reset] running/ limpo." || echo "[clau-reset] AVISO: ainda há tasks em running/"

# Lista workers ativos
clau-workers:
	@echo "=== Workers ativos ==="
	@docker ps --filter "label=com.docker.compose.service=worker" --format "table {{.ID}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null || echo "(nenhum)"
	@echo "\n=== Tasks em running/ ==="
	@ls -1 tasks/running/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"

clau-status:
	@echo "=== Recurring (imortais) ==="
	@ls -1 tasks/recurring/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Pending (one-shot) ==="
	@ls -1 tasks/pending/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Running ==="
	@ls -1 tasks/running/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Done ==="
	@ls -1 tasks/done/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Failed ==="
	@ls -1 tasks/failed/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"

# ── Criar Tasks ───────────────────────────────────────────────────

clau-new:
	@[ -n "$(name)" ] || (echo "Uso: make clau-new name=minha-tarefa [type=recurring]" && exit 1)
	@if [ "$(type)" = "recurring" ]; then \
		mkdir -p tasks/recurring/$(name); \
		echo "# $(name)\n\n## Personalidade\nVocê é o **$(name)**. Descreva quem você é e como pensa.\n\n## Missão\n\n## O que fazer a cada execução\n\n## Entregável\nAtualize \`<diretório de contexto>/contexto.md\`.\n\n## Regras\n\n## Auto-evolução\nNo final de CADA execução, reflita sobre seu funcionamento.\nSe precisar melhorar, **edite este CLAUDE.md** diretamente.\nRegistre mudanças em \`<diretório de contexto>/evolucao.log\`." \
			> tasks/recurring/$(name)/CLAUDE.md; \
		mkdir -p .ephemeral/notes/$(name); \
		echo "Task recorrente criada: tasks/recurring/$(name)/"; \
	else \
		mkdir -p tasks/pending/$(name); \
		echo "# $(name)\n\n## Objetivo\n\n## O que entregar\nEscreva resultado em \`<diretório de contexto>/contexto.md\`.\n\n## Regras" \
			> tasks/pending/$(name)/CLAUDE.md; \
		mkdir -p .ephemeral/notes/$(name); \
		echo "Task one-shot criada: tasks/pending/$(name)/"; \
	fi
	@echo "Edite: $$( [ '$(type)' = 'recurring' ] && echo 'tasks/recurring' || echo 'tasks/pending' )/$(name)/CLAUDE.md"

# ── Utils ──────────────────────────────────────────────────────────

usage:
	@echo "=== Uso do mês (tasks) ==="
	@cat .ephemeral/usage/$$(date +%Y-%m).jsonl 2>/dev/null | jq -s \
		'{ tasks: length, total_duration: (map(.duration) | add), entries: . }' \
		|| echo "Sem dados de tasks ainda."

usage-api:
	@$(COMPOSE) exec sandbox bash /workspace/scripts/api-usage.sh

usage-api-7d:
	@$(COMPOSE) exec sandbox bash /workspace/scripts/api-usage.sh -- 7d

usage-api-30d:
	@$(COMPOSE) exec sandbox bash /workspace/scripts/api-usage.sh -- 30d
