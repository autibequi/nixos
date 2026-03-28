---
name: docker install — padrões de SSH e TTY em containers
description: Lições do comando leech docker install sobre SSH, TTY e go mod download
type: feedback
---

**Regras aprendidas no desenvolvimento do `leech docker install`:**

1. **SSH mount deve ser em path neutro, não `/root/.ssh:ro`**
   Montar diretamente em `/root/.ssh:ro` e depois tentar `chmod` quebra com "Read-only file system".
   **Fix:** montar em `/ssh-host:ro` e copiar dentro do container: `cp /ssh-host/* /root/.ssh/`

2. **`git config` deve vir DEPOIS do `apk add git`**
   Executar `git config` antes de instalar git resulta em "git: not found".
   Ordem correta: instalar ferramentas → configurar git → usar git.

3. **`docker run -t` para cores**
   Sem `-t`, ferramentas como `apk` e `go` não emitem sequências ANSI.
   Adicionar `-t` ao `docker run` aloca pseudo-TTY e habilita cores.

4. **`go mod download` não tem `-v`, tem `-x`**
   `-v` retorna "flag provided but not defined". Usar `-x` para verbose (mostra cada comando git/http executado).
   `go mod download` é silencioso por padrão — parece travado mas está baixando.

5. **`install` acessa credenciais — `run`/workers nunca**
   Separação de responsabilidades no leech docker:
   - `leech docker install` — acessa `~/.ssh`, `~/.npmrc`, tokens. Gera artefatos no projeto (vendor/, node_modules/).
   - `leech docker run` / Dockerfile / workers — build e runtime limpos, sem credenciais. Consomem os artefatos gerados pelo install.
   Para Node.js: o Dockerfile não faz `npm install`. Só sobe o servidor. O bind mount expõe o `node_modules/` gerado pelo install.

**Why:** Erros encontrados ao implementar `leech docker install monolito` em 2026-03-18. Separação de credenciais exigida pelo usuário em 2026-03-18 ao dockerizar bo-container.
**How to apply:** Qualquer novo serviço dockerizado — credenciais só em `docker_install.sh`, nunca em Dockerfile ou `docker_run.sh`.
