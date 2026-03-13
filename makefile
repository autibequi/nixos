.PHONY: help switch update get-ids reload stow restow stow-tree stow-confirm \
       build shell sandbox resume down inject \
       run auto stop reset status new logs logs-list usage usage-api \
       test test-task test-container test-mcp test-runner doctor

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
	@echo "  make new name=x        Cria task one-shot em pending/"
	@echo "  make new name=x type=recurring"
	@echo "                         Cria task recorrente"
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
	@echo "  Uso típico"
	@echo "  ─────────────────────────────────────────────────────────"
	@echo "  1. Validar setup:       make doctor"
	@echo "  2. Testar uma task:     make test-task task=usage-tracker"
	@echo "  3. Rodar interativo:    make run task=usage-tracker"
	@echo "  4. Rodar todas (vivo):  make run"
	@echo "  5. Rodar headless:      make auto"
	@echo "  6. Debug travamento:    make status && make logs"
	@echo "  7. Destravou?:          make stop  (ou: make reset)"
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

# make run — interativo com TTY (default)
# make run task=nome — uma task específica
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

# make auto — headless (systemd/cron)
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
	@echo "\n=== Recurring ==="
	@ls -1 tasks/recurring/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Pending ==="
	@ls -1 tasks/pending/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Running ==="
	@ls -1 tasks/running/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Done ==="
	@ls -1 tasks/done/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"
	@echo "\n=== Failed ==="
	@ls -1 tasks/failed/ 2>/dev/null | grep -v '\.gitkeep' || echo "(vazio)"

new:
	@[ -n "$(name)" ] || (echo "Uso: make new name=minha-tarefa [type=recurring]" && exit 1)
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

# ── Teste & Validação ─────────────────────────────────────────────

# Roda todos os testes de validação
test: test-container test-mcp test-runner
	@echo "\n=== Todos os testes passaram ==="

# Testa se o container sobe e tem as dependências necessárias
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

# Testa se o MCP no-mcp.json funciona e se o MCP server nix carrega
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

# Testa o runner sem executar Claude (valida claim, lock, cleanup)
test-runner:
	@echo "=== test-runner: verificando runner ==="
	@echo -n "  clau-runner.sh: "; \
	[ -x scripts/clau-runner.sh ] && echo "[OK] executável" || echo "[AVISO] não-executável (chmod +x)"
	@echo -n "  tasks/recurring: "; ls -1 tasks/recurring/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo -n "  tasks/pending:   "; ls -1 tasks/pending/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo -n "  tasks/running:   "; ls -1 tasks/running/ 2>/dev/null | grep -cv '\.gitkeep' || echo "0"
	@echo -n "  lockfile:        "; \
	[ -f .ephemeral/.clau.lock ] && echo "existe ($(wc -c < .ephemeral/.clau.lock)B)" || echo "limpo"
	@echo -n "  NODE_OPTIONS:    "; echo "$${NODE_OPTIONS:-(não definido, runner usa --max-old-space-size=1536)}"
	@echo -n "  CLAU_TIMEOUT:    "; echo "$${CLAU_TIMEOUT:-600}s"
	@echo -n "  CLAU_MAX_TASKS:  "; echo "$${CLAU_MAX_TASKS:-5}"
	@echo "  [OK] Runner configurado"

# Roda uma task com timeout curto (60s) pra validar que funciona
test-task:
	@[ -n "$(task)" ] || (echo "Uso: make test-task task=nome-da-task" && exit 1)
	@echo "=== test-task: $(task) (timeout 60s) ==="
	@$(COMPOSE) run --rm -e CLAU_VERBOSE=1 -e CLAU_TIMEOUT=60 -e CLAU_MAX_TASKS=1 \
		worker /workspace/scripts/clau-runner.sh $(task)

# Diagnóstico completo: testa tudo + mostra estado atual
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
	@$(COMPOSE) exec sandbox jq -s \
		'{ tasks: length, total_duration: (map(.duration) | add), entries: . }' \
		/workspace/.ephemeral/usage/$$(date +%Y-%m).jsonl 2>/dev/null \
		|| echo "Sem dados de tasks ainda."

usage-api:
	@$(COMPOSE) exec sandbox bash /workspace/scripts/api-usage.sh

usage-api-7d:
	@$(COMPOSE) exec sandbox bash /workspace/scripts/api-usage.sh -- 7d

usage-api-30d:
	@$(COMPOSE) exec sandbox bash /workspace/scripts/api-usage.sh -- 30d
