CONTAINER := claude-sandbox
export GIT_AUTHOR_NAME := $(shell git config user.name)
export GIT_AUTHOR_EMAIL := $(shell git config user.email)
export GIT_COMMITTER_NAME := $(GIT_AUTHOR_NAME)
export GIT_COMMITTER_EMAIL := $(GIT_AUTHOR_EMAIL)

.PHONY: help switch update get-ids reload stow restow stow-tree stow-confirm \
       build shell sandbox sandbox-shell resume down inject claude \
       run auto stop reset status new logs logs-list usage usage-api usage-api-7d usage-api-30d \
       test test-task test-container test-mcp test-runner doctor \
       dashboard clean-tasks ping vault-link

help:
	@echo ""
	@echo "  NixOS"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make switch            Aplica config NixOS (nh os switch)"
	@echo "  make update            Atualiza flake e aplica"
	@echo "  make get-ids           Mostra UUIDs de partição"
	@echo "  make reload            Re-adiciona hardware.nix ao git"
	@echo ""
	@echo "  Dotfiles"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make stow              Injeta dotfiles via stow"
	@echo "  make restow            Remove e re-injeta dotfiles"
	@echo "  make stow-tree         Lista arquivos que serão injetados"
	@echo "  make stow-confirm      Restow interativo com confirmação"
	@echo ""
	@echo "  Container (sandbox interativo)"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make build             Build da imagem Docker"
	@echo "  make claude            Abre Alacritty com sandbox Claude"
	@echo "  make sandbox           Sobe sandbox + abre Claude"
	@echo "  make shell             Sobe sandbox + abre bash"
	@echo "  make resume            Retoma sessão Claude anterior"
	@echo "  make down              Para todos os containers"
	@echo "  make inject            Restow + restart sandbox + Claude"
	@echo ""
	@echo "  Tasks (worker autônomo)"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make run               Roda todas as tasks com output ao vivo"
	@echo "  make run task=nome     Roda uma task específica com output"
	@echo "  make auto              Roda tasks headless (systemd/cron)"
	@echo "  make stop              Para worker + reseta tasks presas"
	@echo "  make reset             Devolve tasks de running/ pra origem"
	@echo "  make status            Mostra estado do worker e das tasks"
	@echo "  make new name=x        Cria task (wizard interativo)"
	@echo ""
	@echo "  Dashboard & Vault"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make dashboard         Regenera vault/dashboard.md"
	@echo "  make vault-link        Cria symlink ~/.vault/Work → vault/"
	@echo "  make ping              Health endpoint JSON (pra Waybar)"
	@echo "  make clean-tasks       Limpa done/ e failed/"
	@echo ""
	@echo "  Teste & Validação"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make doctor            Checa tudo: container, MCP, tasks, runner"
	@echo "  make test              Roda todos os testes abaixo"
	@echo "  make test-container    Testa se o container sobe e tem as deps"
	@echo "  make test-mcp          Testa se MCP server carrega e no-mcp funciona"
	@echo "  make test-runner       Testa runner sem executar Claude"
	@echo "  make test-task task=x  Roda uma task com timeout curto (dry-run)"
	@echo ""
	@echo "  Logs & Usage"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  make logs              Mostra/segue último log do worker"
	@echo "  make logs-list         Lista todos os logs"
	@echo "  make usage             Uso do mês (tasks executadas)"
	@echo "  make usage-api         Uso da API Anthropic (hoje)"
	@echo "  make usage-api-7d      Uso da API (últimos 7 dias)"
	@echo "  make usage-api-30d     Uso da API (últimos 30 dias)"
	@echo ""

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

# ── Container ──────────────────────────────────────────────────────

COMPOSE = docker compose -f docker-compose.claude.yml
LOGDIR  = logs
LOGFILE = $(LOGDIR)/$$(date +%Y-%m-%dT%H:%M:%S.%3N).log

build:
	$(COMPOSE) build

sandbox:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --permission-mode bypassPermissions -- "startup"

shell:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox bash

sandbox-shell:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox bash

resume:
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --resume --permission-mode bypassPermissions

down:
	$(COMPOSE) down

inject:
	$(MAKE) restow
	$(COMPOSE) down
	$(COMPOSE) up -d sandbox
	@$(COMPOSE) exec sandbox claude --permission-mode bypassPermissions -- "startup"


# ── Tasks ──────────────────────────────────────────────────────────

run:
	@existing=$$(docker ps --filter "label=com.docker.compose.service=worker" --format "{{.ID}}" 2>/dev/null | head -1); \
	if [ -n "$$existing" ]; then \
		echo "[clau] Worker já rodando ($$existing). Use 'make stop' ou 'make logs'."; \
		exit 0; \
	fi
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	echo "[clau] Log: $$logfile"; \
	$(COMPOSE) run --rm -e CLAU_VERBOSE=1 worker /workspace/scripts/clau-runner.sh $(task) 2>&1 | tee "$$logfile"

auto:
	@existing=$$(docker ps --filter "label=com.docker.compose.service=worker" --format "{{.ID}}" 2>/dev/null | head -1); \
	if [ -n "$$existing" ]; then \
		echo "[clau] Worker já rodando ($$existing). Singleton ativo."; \
		exit 0; \
	fi
	@mkdir -p $(LOGDIR)
	@logfile="$(LOGFILE)"; \
	echo "[clau] Log: $$logfile"; \
	$(COMPOSE) run --rm -T worker /workspace/scripts/clau-runner.sh > "$$logfile" 2>&1

stop:
	@echo "[clau] Parando worker..."
	@$(COMPOSE) kill worker 2>/dev/null || true
	@$(COMPOSE) rm -f worker 2>/dev/null || true
	@$(MAKE) --no-print-directory reset

reset:
	@for dir in tasks/running/*/; do \
		[ -d "$$dir" ] || continue; \
		name=$$(basename "$$dir"); \
		source=$$(grep '^source=' "$$dir/.lock" 2>/dev/null | cut -d= -f2 || echo "pending"); \
		rm -f "$$dir/.lock"; \
		if [ "$$source" = "recurring" ]; then \
			mv "$$dir" "tasks/recurring/$$name"; \
			echo "[reset] $$name → recurring/"; \
		else \
			mv "$$dir" "tasks/pending/$$name"; \
			echo "[reset] $$name → pending/"; \
		fi; \
	done
	@rm -f .ephemeral/.clau.lock
	@[ -z "$$(ls -A tasks/running/ 2>/dev/null | grep -v '\.gitkeep')" ] && echo "[reset] running/ limpo." || echo "[reset] AVISO: ainda há tasks em running/"

status:
	@echo "=== Worker ==="
	@docker ps --filter "label=com.docker.compose.service=worker" --format "table {{.ID}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null || echo "(nenhum)"
	@echo "\n=== Systemd ==="
	@systemctl is-active claude-autonomous.service 2>/dev/null || echo "inactive"
	@echo "\n=== Recurring ($(shell ls -1 tasks/recurring/ 2>/dev/null | grep -cv '\.gitkeep' || echo 0)) ==="
	@for dir in tasks/recurring/*/; do \
		[ -d "$$dir" ] || continue; \
		name=$$(basename "$$dir"); \
		schedule=$$(sed -n '/^---$$/,/^---$$/p' "$$dir/CLAUDE.md" 2>/dev/null | grep -m1 '^schedule:' | awk '{print $$2}' || echo "?"); \
		model=$$(sed -n '/^---$$/,/^---$$/p' "$$dir/CLAUDE.md" 2>/dev/null | grep -m1 '^model:' | awk '{print $$2}' || echo "?"); \
		echo "  $$name ($$schedule, $$model)"; \
	done
	@echo "\n=== Pending ($(shell ls -1 tasks/pending/ 2>/dev/null | grep -cv '\.gitkeep' || echo 0)) ==="
	@ls -1 tasks/pending/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Running ==="
	@ls -1 tasks/running/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Últimas 5 execuções ==="
	@if [ -f ".ephemeral/usage/$$(date +%Y-%m).jsonl" ]; then \
		tail -5 ".ephemeral/usage/$$(date +%Y-%m).jsonl" 2>/dev/null | \
		while IFS= read -r line; do \
			task=$$(echo "$$line" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"{d.get('task','?'):25s} {d.get('status','?'):5s} {d.get('model','?'):8s} {d.get('date','?')}\")" 2>/dev/null || echo "$$line"); \
			echo "  $$task"; \
		done; \
	else \
		echo "  (sem dados)"; \
	fi

# Task creation wizard
new:
	@[ -n "$(name)" ] || (echo "Uso: make new name=minha-tarefa [type=recurring|pending] [model=haiku|sonnet] [schedule=always|night] [timeout=300]" && exit 1)
	@task_type="$${type:-pending}"; \
	task_model="$${model:-$$([ "$$task_type" = "recurring" ] && echo "haiku" || echo "sonnet")}"; \
	task_schedule="$${schedule:-$$([ "$$task_type" = "recurring" ] && echo "night" || echo "always")}"; \
	task_timeout="$${timeout:-$$([ "$$task_type" = "recurring" ] && echo "300" || echo "900")}"; \
	task_dir="tasks/$$task_type/$(name)"; \
	mkdir -p "$$task_dir"; \
	printf '%s\n' \
		"---" \
		"timeout: $$task_timeout" \
		"model: $$task_model" \
		"schedule: $$task_schedule" \
		"---" \
		"# $(name)" \
		"" \
		"## Objetivo" \
		"" \
		"## O que fazer" \
		"" \
		"## Entregável" \
		"Atualize \`<diretório de contexto>/contexto.md\`." \
		"" \
		"## Regras" \
		"" \
		"## Sugestões" \
		"Gere sugestões em \`vault/sugestoes/\` se identificar melhorias." \
		> "$$task_dir/CLAUDE.md"; \
	if [ "$$task_type" = "recurring" ]; then \
		printf '%s\n' \
			"# $(name) — Memória" \
			"" \
			"## Resumo" \
			"Task nova. Primeira execução pendente." \
			"" \
			"## Histórico de execuções" \
			"(nenhuma ainda)" \
			> "$$task_dir/memoria.md"; \
	fi; \
	mkdir -p ".ephemeral/notes/$(name)"; \
	echo "Task criada: $$task_dir/ ($$task_model, $$task_schedule, $${task_timeout}s)"; \
	echo "Edite: $$task_dir/CLAUDE.md"

# ── Dashboard & Vault ─────────────────────────────────────────────

dashboard:
	@echo "Gerando vault/dashboard.md..."
	@$(COMPOSE) exec sandbox bash -c 'cd /workspace && bash scripts/clau-runner.sh __dashboard 2>/dev/null' || \
		echo "(fallback: rode 'make auto' pra gerar automaticamente)"

vault-link:
	@mkdir -p $$HOME/.ovault/Claudinho
	@echo "Pasta criada: ~/.ovault/Claudinho/"
	@echo "Rode 'make down && make sandbox' pra ativar o bind mount."

ping:
	@if [ -f .ephemeral/health.json ]; then \
		cat .ephemeral/health.json; \
	else \
		echo '{"text":"?","tooltip":"Claudinho: sem dados","class":"warning","alt":"unknown"}'; \
	fi

clean-tasks:
	@echo "Limpando done/ e failed/..."
	@rm -rf tasks/done/* tasks/failed/*
	@echo "Limpo."

# ── Teste & Validação ─────────────────────────────────────────────

test: test-container test-mcp test-runner
	@echo "\n=== Todos os testes passaram ==="

test-container:
	@echo "=== test-container: verificando imagem e deps ==="
	@$(COMPOSE) run --rm -T --entrypoint "" worker bash -c ' \
		echo -n "  bash:    "; bash --version | head -1; \
		echo -n "  node:    "; node --version; \
		echo -n "  claude:  "; claude --version 2>/dev/null || echo "FALHOU"; \
		echo -n "  jq:      "; jq --version 2>/dev/null || echo "FALHOU"; \
		echo -n "  timeout: "; timeout --version 2>/dev/null | head -1 || echo "FALHOU"; \
		echo -n "  flock:   "; flock --version 2>/dev/null | head -1 || echo "FALHOU"; \
		echo -n "  mem_limit: "; cat /sys/fs/cgroup/memory.max 2>/dev/null || cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo "sem cgroup"; \
		echo "  [OK] Container funcional" \
	'

test-mcp:
	@echo "=== test-mcp: verificando configuração MCP ==="
	@if [ -f .ephemeral/no-mcp.json ]; then \
		echo "  [OK] .ephemeral/no-mcp.json existe"; \
		cat .ephemeral/no-mcp.json | python3 -m json.tool > /dev/null 2>&1 \
			&& echo "  [OK] JSON válido" \
			|| echo "  [FALHOU] JSON inválido"; \
	else \
		echo "  [FALHOU] .ephemeral/no-mcp.json não existe"; \
		echo '  Criando...'; \
		mkdir -p .ephemeral; \
		echo '{"mcpServers":{}}' > .ephemeral/no-mcp.json; \
		echo "  [OK] Criado"; \
	fi
	@echo -n "  .mcp.json: "; \
	if [ -f .mcp.json ]; then \
		servers=$$(python3 -c "import json; d=json.load(open('.mcp.json')); print(', '.join(d.get('mcpServers',{}).keys()))" 2>/dev/null); \
		echo "$$servers"; \
	else \
		echo "(não existe)"; \
	fi

test-runner:
	@echo "=== test-runner: verificando runner ==="
	@echo -n "  clau-runner.sh: "; \
	[ -x scripts/clau-runner.sh ] && echo "[OK] executável" || echo "[AVISO] não-executável (chmod +x)"
	@echo -n "  tasks/recurring: "; ls -1 tasks/recurring/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo -n "  tasks/pending:   "; ls -1 tasks/pending/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo -n "  tasks/running:   "; ls -1 tasks/running/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo -n "  lockfile:        "; \
	[ -f .ephemeral/.clau.lock ] && echo "existe ($(shell wc -c < .ephemeral/.clau.lock 2>/dev/null || echo 0)B)" || echo "limpo"
	@echo -n "  CLAU_TIMEOUT:    default 300s (recurring) / 900s (pending)"
	@echo ""
	@echo -n "  CLAU_MAX_TASKS:  "; echo "$${CLAU_MAX_TASKS:-5}"
	@echo "  [OK] Runner configurado"

test-task:
	@[ -n "$(task)" ] || (echo "Uso: make test-task task=nome-da-task" && exit 1)
	@echo "=== test-task: $(task) (timeout 60s) ==="
	@$(COMPOSE) run --rm -e CLAU_VERBOSE=1 -e CLAU_TIMEOUT=60 -e CLAU_MAX_TASKS=1 \
		worker /workspace/scripts/clau-runner.sh $(task)

doctor:
	@echo "╔═══════════════════════════════════════════════════╗"
	@echo "║              Claudinho Doctor                    ║"
	@echo "╚═══════════════════════════════════════════════════╝"
	@echo ""
	@$(MAKE) --no-print-directory test-container 2>&1 || echo "  [FALHOU] container"
	@echo ""
	@$(MAKE) --no-print-directory test-mcp
	@echo ""
	@$(MAKE) --no-print-directory test-runner
	@echo ""
	@echo "=== docker/podman ==="
	@echo -n "  engine:    "; docker --version 2>/dev/null | head -1 || echo "não encontrado"
	@echo -n "  compose:   "; docker compose version 2>/dev/null | head -1 || echo "não encontrado"
	@echo -n "  worker up: "; docker ps --filter "label=com.docker.compose.service=worker" --format "{{.ID}} ({{.Status}})" 2>/dev/null || echo "não"
	@echo ""
	@echo "=== sistema ==="
	@echo -n "  RAM total: "; free -h | awk '/^Mem:/{print $$2}'
	@echo -n "  RAM livre: "; free -h | awk '/^Mem:/{print $$7}'
	@echo -n "  swap:      "; free -h | awk '/^Swap:/{print $$2 " (usado: " $$3 ")"}'
	@echo ""
	@echo "=== tasks ==="
	@echo -n "  recurring: "; ls -1 tasks/recurring/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo -n "  pending:   "; ls -1 tasks/pending/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo -n "  running:   "; ls -1 tasks/running/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo -n "  done:      "; ls -1 tasks/done/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo -n "  failed:    "; ls -1 tasks/failed/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo ""
	@echo "=== vault ==="
	@echo -n "  dashboard: "; [ -f vault/dashboard.md ] && echo "existe ($$(wc -l < vault/dashboard.md) linhas)" || echo "não existe (rode make auto)"
	@echo -n "  sugestões: "; ls -1 vault/sugestoes/ 2>/dev/null | wc -l || echo "0"
	@echo -n "  health:    "; [ -f .ephemeral/health.json ] && cat .ephemeral/health.json || echo "(sem dados)"
	@echo ""

# ── Logs ───────────────────────────────────────────────────────────

logs:
	@latest=$$(ls -1t logs/*.log 2>/dev/null | head -1); \
	if [ -z "$$latest" ]; then \
		echo "(nenhum log em logs/)"; \
	else \
		id=$$(docker ps --filter "label=com.docker.compose.service=worker" --format "{{.ID}}" 2>/dev/null | head -1); \
		if [ -n "$$id" ]; then \
			echo "=== Worker ativo — seguindo $$latest ==="; \
			tail -f "$$latest"; \
		else \
			echo "=== Último log: $$latest ==="; \
			cat "$$latest"; \
		fi; \
	fi

logs-list:
	@ls -1t logs/*.log 2>/dev/null || echo "(nenhum log)"

# ── Usage ──────────────────────────────────────────────────────────

usage:
	@echo "=== Uso do mês (tasks) ==="
	@if [ -f ".ephemeral/usage/$$(date +%Y-%m).jsonl" ]; then \
		python3 -c "\
import json, sys; \
lines = [json.loads(l) for l in open('.ephemeral/usage/$$(date +%Y-%m).jsonl')]; \
print(f'  Tasks: {len(lines)}'); \
print(f'  Duration total: {sum(l.get(\"duration\",0) for l in lines)}s'); \
models = {}; \
[models.update({l.get('model','?'): models.get(l.get('model','?'),0)+1}) for l in lines]; \
print(f'  Models: {models}'); \
statuses = {}; \
[statuses.update({l.get('status','?'): statuses.get(l.get('status','?'),0)+1}) for l in lines]; \
print(f'  Statuses: {statuses}')" 2>/dev/null || \
		echo "Sem dados ou python3 indisponível."; \
	else \
		echo "Sem dados de tasks ainda."; \
	fi

usage-api:
	@bash scripts/api-usage.sh

usage-api-7d:
	@bash scripts/api-usage.sh 7d

usage-api-30d:
	@bash scripts/api-usage.sh 30d
