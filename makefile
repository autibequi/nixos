.PHONY: get-ids reload switch update stow restow stow-tree stow-confirm \
       sandbox sandbox-build sandbox-shell sandbox-down sandbox-restart sandbox-inject \
       claude-resume clau clau-run clau-stop clau-reset clau-restart clau-worker clau-status clau-new \
       clau-logs logs usage

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

# ── Autônomo (singleton) ──────────────────────────────────────────

# Worker singleton: um container, processa todas as tasks sequencialmente
# Seguro rodar do terminal — flock interno garante que só um roda por vez
clau:
	@existing=$$(docker ps --filter "label=com.docker.compose.service=worker" --format "{{.ID}}" 2>/dev/null | head -1); \
	if [ -n "$$existing" ]; then \
		echo "[clau] Worker já rodando ($$existing). Singleton ativo."; \
		echo "[clau] Use 'make clau-stop' pra parar, ou 'make clau-logs' pra acompanhar."; \
		exit 0; \
	fi
	$(COMPOSE) run --rm -T worker /workspace/scripts/clau-runner.sh

# Roda uma task específica: make clau-run task=nome-da-task
clau-run:
	@[ -n "$(task)" ] || (echo "Uso: make clau-run task=nome-da-task" && exit 1)
	$(COMPOSE) run --rm -T worker /workspace/scripts/clau-runner.sh "$(task)"

# Para o worker e reseta tasks presas
clau-stop:
	@echo "[clau-stop] Parando worker..."
	@$(COMPOSE) kill worker 2>/dev/null || true
	@$(COMPOSE) rm -f worker 2>/dev/null || true
	@$(MAKE) --no-print-directory clau-reset

# Reseta tasks presas em running/ → devolve pra origem (sem matar workers)
clau-reset:
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
	@rm -f .ephemeral/.clau.lock
	@[ -z "$$(ls -A tasks/running/ 2>/dev/null | grep -v '\.gitkeep')" ] && echo "[clau-reset] running/ limpo." || echo "[clau-reset] AVISO: ainda há tasks em running/"

# Para via systemd (inclui cleanup automático via ExecStopPost)
clau-restart:
	sudo systemctl stop claude-autonomous.service 2>/dev/null || true
	sudo systemctl start claude-autonomous.service

# Worker ativo?
clau-worker:
	@echo "=== Worker container ==="
	@docker ps --filter "label=com.docker.compose.service=worker" --format "table {{.ID}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null || echo "(nenhum)"
	@echo "\n=== Systemd service ==="
	@systemctl is-active claude-autonomous.service 2>/dev/null || echo "inactive"
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

# Logs do worker singleton
clau-logs:
	@id=$$(docker ps --filter "label=com.docker.compose.service=worker" --format "{{.ID}}" 2>/dev/null | head -1); \
	if [ -n "$$id" ]; then \
		docker logs -f "$$id" 2>&1; \
	else \
		echo "(nenhum worker rodando)"; \
		echo "Últimos logs do systemd:"; \
		journalctl -u claude-autonomous.service --no-pager -n 30 2>/dev/null || true; \
	fi

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
