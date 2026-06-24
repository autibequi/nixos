# Makefile — build + install da CLI `coruja`.
#
# O binário NÃO é versionado: é gerado em /tmp e instalado em ~/.local/bin.
# A CLI é a interface do dev stack — este Makefile só (re)gera/instala o script.
#
#   make            # = make install (gera em /tmp + instala em ~/.local/bin)
#   make build      # só gera em /tmp (inspeção/dev da CLI)
#   make install    # build + instala em ~/.local/bin (grava o path do projeto)
#   make uninstall  # remove ~/.local/bin/coruja
#   make validate   # valida o src/bashly.yml

PREFIX    ?= $(HOME)/.local/bin
BIN       := coruja
BUILD_DIR ?= /tmp/coruja-build

.DEFAULT_GOAL := install
.PHONY: build install uninstall watch validate help

build:  ## Gera o script em /tmp (não deixa o binário no repo)
	@bashly generate >/dev/null
	@mkdir -p "$(BUILD_DIR)"
	@mv -f "$(BIN)" "$(BUILD_DIR)/$(BIN)"
	@# bashly 1.3.8: `default: true` só roteia comando DESCONHECIDO (*) pro wizard;
	@# args vazios (`coruja` puro) ainda caem em usage+exit 1. Patcha o fallback vazio
	@# pra rodar o wizard, mantendo `coruja` puro = wizard interativo.
	@perl -0pi -e 's/      coruja_usage >&2\n      exit 1\n      ;;\n\n    \*\)\n      action="wizard"/      action="wizard"\n      coruja_wizard_parse_requirements "\$$\@"\n      shift \$$#\n      ;;\n\n    *)\n      action="wizard"/' "$(BUILD_DIR)/$(BIN)"
	@echo "gerado: $(BUILD_DIR)/$(BIN)"

install: build  ## Builda e instala em ~/.local/bin (grava o path do projeto)
	@mkdir -p "$(PREFIX)"
	@sed "s#__CORUJA_PROJECT_DIR__#$(CURDIR)#g" "$(BUILD_DIR)/$(BIN)" > "$(PREFIX)/$(BIN)"
	@chmod +x "$(PREFIX)/$(BIN)"
	@echo "✓ instalado: $(PREFIX)/$(BIN)  (projeto: $(CURDIR))"
	@case ":$$PATH:" in \
		*":$(PREFIX):"*) ;; \
		*) printf '! %s não está no PATH — adicione ao rc do shell:\n    export PATH="%s:$$PATH"\n' "$(PREFIX)" "$(PREFIX)" ;; \
	esac

uninstall:  ## Remove ~/.local/bin/coruja
	@rm -f "$(PREFIX)/$(BIN)" && echo "removido: $(PREFIX)/$(BIN)"

watch:  ## Regenera ao salvar (dev da CLI; ./coruja é gitignored)
	bashly watch

validate:  ## Valida o src/bashly.yml
	bashly validate

help:  ## Lista os alvos disponíveis
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'
