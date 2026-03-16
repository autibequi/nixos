---
name: Engine Cursor CLI
overview: "Implementar engine=cursor no claudio-cli levantando o Cursor CLI (`agent`) no container da mesma forma que opencode/claude: instalar o binário na imagem, montar credenciais do host (~/.cursor) e repassar CURSOR_API_KEY; incluir passo de verificação da chave antes de usar."
todos: []
isProject: false
---

# Engine Cursor CLI no claudio-cli

## Contexto

- **Cursor CLI**: instalado com `curl https://cursor.com/install -fsS | bash`, binário em `~/.local/bin/agent`. Documentação: [Cursor CLI](https://cursor.com/pt-BR/cli), [Headless](https://cursor.com/docs/cli/headless), [Authentication](https://cursor.com/docs/cli/reference/authentication).
- **Config e credenciais**: `~/.cursor/cli-config.json` (global); auth por browser (`agent login`) ou `CURSOR_API_KEY`. No Linux a config fica em `~/.cursor`; pode ser sobrescrita com `CURSOR_CONFIG_DIR`.
- **Hoje**: em [run.sh](claudinho/claudio-cli/src/commands/run.sh) o branch `cursor` repete o de `claude` (executa o binário Claude no container). O objetivo é passar a executar o **Cursor CLI** (`agent`) no container, no mesmo estilo de opencode/claude.

## Arquitetura

```mermaid
flowchart LR
  subgraph host [Host]
    HOME[~/.cursor]
    ENV[~/.claudio / .env]
  end
  subgraph container [Container claude-nix-sandbox]
    mount[/workspace/mount]
    cursor_home["/home/claude/.cursor"]
    agent[agent CLI]
  end
  HOME -->|volume rw| cursor_home
  ENV -->|CURSOR_API_KEY| container
  cursor_home --> agent
  mount --> agent
```

- **Credenciais**: montar `${HOME}/.cursor` do host em `/home/claude/.cursor` no container (como já se faz com `~/.claude` e opencode em `~/.config/opencode`). Assim, login feito no host com `agent login` fica visível no container.
- **API key**: ler `CURSOR_API_KEY` de `~/.claudio` ou `.env` e repassar ao compose/container (como `ANTHROPIC_API_KEY`), para uso em scripts/headless.
- **Teste da chave**: antes de confiar no fluxo, rodar uma vez no container `agent status` (ou `agent --version` se não houver auth) para validar que o binário existe e que a auth (mount ou env) funciona.

## Alterações propostas

### 1. Dockerfile.claude

- Instalar Cursor CLI no build:
  - Rodar o script oficial como root (ele escreve em `$HOME/.local/bin` → `/root/.local/bin`).
  - Copiar `/root/.local/bin/agent` para `/home/claude/.local/bin/agent` e ajustar dono (claude:1000).
  - Garantir que `PATH` no image inclua `/home/claude/.local/bin` (por exemplo `ENV PATH="/home/claude/.local/bin:/home/claude/.nix-profile/bin:..."`).

Observação: o script de install pode baixar um binário estático; se depender de libs não presentes na imagem Nix, será preciso ajustar (multi-stage ou base alternativa). Testar o build após a alteração.

### 2. docker-compose.claude.yml

- **Volumes** (em `x-base-volumes`):
  - Adicionar: `${HOME}/.cursor:/home/claude/.cursor`
  - Comentar ou documentar: necessário para reutilizar login do host (`agent login`); opcional se usar só `CURSOR_API_KEY`.
- **Env** (em `x-env-base`):
  - Adicionar: `CURSOR_API_KEY: ${CURSOR_API_KEY:-}` (e, se útil, `CURSOR_CONFIG_DIR` só se quiser override explícito).

### 3. Config e carga de variáveis

- **~/.claudio**: documentar (em README ou .env.example) que `CURSOR_API_KEY` pode ser definida ali para o engine cursor.
- Em [compose_lib.sh](claudinho/claudio-cli/src/lib/compose_lib.sh), em `claudio_load_config`, exportar `CURSOR_API_KEY` quando definida em `~/.claudio` (mesmo padrão de `GH_TOKEN` / `ANTHROPIC_API_KEY`), para o compose receber via ambiente.

### 4. run.sh e binário gerado (claudio)

- **engine=cursor**:
  - Deixar de executar o binário Claude.
  - Executar o Cursor CLI: após bootstrap e `cd /workspace/mount`, fazer `exec agent` (ou `exec /home/claude/.local/bin/agent` se preferir path absoluto).
  - Manter o mesmo padrão de `claudio_compose_cmd -p "$proj_name" run --rm -it ... sandbox` e variáveis de ambiente (e.g. `CLAUDIO_MOUNT`), apenas trocando o comando final para `agent`.
- Ajustar o mesmo branch no script monolítico [claudio](claudinho/claudio-cli/claudio) (função `claudio_run_command`) para manter paridade.

### 5. Comandos start / resume / continue

- **start**: hoje sempre executa Claude. Decisão: (a) não alterar start (cursor só via `run --engine=cursor`) ou (b) fazer start respeitar `CLAUDIO_ENGINE`/`--engine` e, quando for cursor, dar `exec agent` em vez de `claude`. Recomendação: implementar só `run` primeiro; start com cursor pode ser fase seguinte.
- **resume/continue**: são específicos do Claude (sessão persistente). Cursor CLI não tem o mesmo conceito; manter resume/continue apenas para engine claude; para cursor, não alterar (ou documentar que não se aplicam).

### 6. Verificação da chave antes de usar

- **No host** (uma vez após configurar):
  - Com o mount `~/.cursor` e, se quiser, `CURSOR_API_KEY` em `~/.claudio`, rodar um container efêmero e checar auth:
    - Exemplo: `claudio_compose_cmd run --rm sandbox agent status` (a partir do diretório do compose), ou um wrapper tipo `claudio run --engine=cursor /tmp && agent status` e sair.
  - Confirmar que `agent status` mostra autenticado (ou que `agent --version` roda e que, com API key ou .cursor montado, não dá “not authenticated”).
- **Documentação**: no README ou em comentário no compose, descrever que o usuário deve rodar essa checagem uma vez (e que, sem mount ou API key, o cursor no container não estará autenticado).

## Ordem sugerida

1. Dockerfile: instalar Cursor CLI e PATH; buildar imagem e rodar `agent --version` no container (sem auth) para validar binário.
2. Compose: volume `~/.cursor` e env `CURSOR_API_KEY`; carregar `CURSOR_API_KEY` em `claudio_load_config`.
3. run.sh + claudio: branch cursor executando `agent` em vez de `claude`.
4. Testar no host: mount de `~/.cursor` (e opcionalmente `CURSOR_API_KEY`), depois `agent status` dentro do container; só então usar `claudio run --engine=cursor <dir>` em fluxo real.
5. Documentar no README/.env.example o uso do engine cursor e o passo de verificação da chave.

## Riscos e alternativas

- **Install script**: se o script do Cursor exigir interação ou não rodar bem como root, alternativas: instalar em estágio com usuário não-root e copiar binário; ou baixar o release/asset manualmente no Dockerfile e extrair para `/home/claude/.local/bin`.
- **Credenciais só por API key**: se não quisermos montar `~/.cursor`, dá para usar apenas `CURSOR_API_KEY`; a “chave extraída” a testar seria então essa variável (por exemplo com `agent -p "hello"` ou `agent status`).
- **start/resume/continue**: manter apenas para claude/opencode até haver demanda clara para cursor.

## Referências

- [Cursor CLI (pt-BR)](https://cursor.com/pt-BR/cli)
- [Cursor CLI Authentication](https://cursor.com/docs/cli/reference/authentication)
- [Cursor CLI Configuration](https://cursor.com/docs/cli/reference/configuration) — `~/.cursor/cli-config.json`, `CURSOR_CONFIG_DIR`
- [Headless CLI](https://cursor.com/docs/cli/headless) — `agent -p`, `CURSOR_API_KEY`
