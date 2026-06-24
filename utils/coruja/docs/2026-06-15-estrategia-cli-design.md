# Design — `coruja` CLI (bashly)

**Data:** 2026-06-15
**Autor:** Pedro Correa
**Status:** implementado

> **Atualizações pós-aprovação (2026-06-15):**
> 1. **Binário renomeado de `estrategia` → `coruja`.** Os exemplos abaixo que dizem
>    `estrategia <cmd>` leem-se como `coruja <cmd>`.
> 2. **Instalação no PATH:** `make install` (default goal) builda e instala em
>    `~/.local/bin/coruja`, **gravando o caminho do projeto** no binário (substitui o
>    placeholder `__CORUJA_PROJECT_DIR__`). `coruja_dir()` resolve nesta ordem:
>    `$CORUJA_DIR` → diretório do script se houver `docker-compose.yml` ao lado →
>    caminho gravado. Assim o `coruja` funciona de qualquer pasta.
> 3. **Gap do `bo-container` resolvido:** o bo usa **Vite via env-cmd**, não `quasar dev`.
>    O command passou a ser `npm run serve:${BO_ENV} -- --host 0.0.0.0`
>    (`serve:local`/`serve:sandbox` = `env-cmd -e <env> -- vite`). O `--host 0.0.0.0`
>    é necessário porque o bloco do `.env-cmdrc.js` sobrescreve `LOCAL_BO_CONTAINER_HOST`
>    com um hostname; o flag de CLI do vite tem precedência. `node:14-alpine` está
>    correto (repo: `.nvmrc 14.21.3`, `engines node >=14.15 <15`, `vite ^4.5.14`).
> 4. **Modo de execução:** o wizard pergunta o modo — `foreground` (default; `compose up`
>    attached, segura o terminal e mostra os logs) ou `background` (`-d`/`--detach` =
>    `compose up -d`).
> 5. **Persistência da última config:** o wizard salva as escolhas (front/bo/mono/modo/
>    vertical) em `.coruja-state` no projeto (gitignored) e usa como default na próxima
>    vez, inclusive no `--yes`. Flags têm precedência. Lógica em `src/lib/state.sh`
>    (`state_load`/`state_save`).
> 6. **Monolito carregava só DB/Redis/AWS → fatal "Nao consegui achar o token global".**
>    O monolito lê ~70 vars via viper `AutomaticEnv` (inclui `GLOBAL_SYSTEM_TOKENS`).
>    Fix: `env_file: ${APP_DIR_MONOLITO}/.env.${APP_ENV:-local}` no anchor `x-monolito-base`.
>    O `environment:` mantém precedência e força os hosts de rede.
> 7. **Front-student não conectava no BFF (TLS não estabelecia).** O alias
>    `api.local.estrategia-sandbox.com.br` estava no monolito (HTTP 4004); o TLS na 443 é
>    do reverseproxy (nginx). Fix: alias movido do monolito → reverseproxy (que proxia
>    `http://monolito:4004`). Idem `local`/`admin.local`/`perfil.local` para resolução interna.
> 8. **`coruja install` ganhou wizard de seleção de apps** (multi-select bo/front/monolito
>    via `gum --no-limit` ou fallback Y/n; `--yes` = todos). Builda + instala deps só dos
>    selecionados. `pick_multi` em `src/lib/wizard.sh`.
> 9. **Monolito chaveia o `.env` por ambiente.** `--monolito local|sandbox|prod` (+ `auto`/`skip`)
>    define `MONO_ENV`, usado pelo compose em `env_file: .env.${MONO_ENV}` e no `APP_ENV` do
>    monolito/worker (isolado do front, que segue com seu próprio APP_ENV). `prod` emite aviso.
>    DB/Redis/localstack seguem locais (o `environment:` tem precedência).
> 10. **UI dos wizards (gum > fzf > texto).** Sem gum, o `install` agora usa `fzf --multi`
>    (`start:select-all` pré-marca todos, TAB desmarca) e o `up` (fzf single) põe o default/
>    última config no topo, refletindo o state visualmente.
> 11. **`coruja up --no-deps`.** A CLI resolve todas as deps; sem `--no-deps` o compose puxava
>    serviços via `depends_on` (front-student → monolito) mesmo marcados `skip`.
> 12. **Front-student mapeado aos comandos reais.** 5 ambientes (`local/sandbox/qa/prod/devbox`)
>    × 6 verticais (`carreiras-juridicas/concursos/medicina/militares/oab/vestibulares`);
>    `npm run <ambiente>:<vertical>`. Wizard de vertical. `local`/`devbox` apontam BFF local
>    (puxam backend). bo expandido p/ `local/sandbox/qa/prod`.
> 13. **Setup completo do monolito local (espelha `make setup`/`make seed`).** postgres vira
>    `root/root/root` + monta `${APP_DIR_MONOLITO}/scripts/01_init_db.sql` (databases por
>    vertical + schemas); localstack monta `localstack/init-aws.sh` (filas SQS); monolito/worker
>    ganham `SHARED_DB_*` (postgres/root) + `DISABLE_DB_SSL`; entrypoint roda `socat`
>    localhost:4566→localstack:4566 (config_sqs.yaml usa localhost fixo). Comando próprio `coruja seed`
>    com **wizard de apps** (hoje só `monolito`; extensível p/ ecommerce etc. via `SEED_APPS`
>    + `seed_<app>()` em `src/lib/seed.sh`) aplica os dumps `02+_*.sql` via `psql -U root` no
>    banco local. O `install` **não** roda seed — só sugere `coruja seed` no fim. Reset do DB:
>    `coruja down -v` (o 01_init_db só roda em volume vazio).

## Problema

O dev stack local da Estratégia (`/workspace/.cache/work/estrategia/`) hoje sobe via
`Makefile` + `docker-compose.yml`, tratando a stack inteira com **um único `APP_ENV`**.
Não há como rodar cada container num ambiente diferente (ex.: `front-student` apontando
pro sandbox deployado enquanto o `bo-container` roda local). Quem aponta pro sandbox não
precisa do backend local, mas o setup atual sobe tudo igual.

Queremos um utilitário CLI (`estrategia`, gerado por **bashly**) que:

1. **Levante os containers** com seleção de **ambiente por container** (local/sandbox, misturado).
2. **Resolva dependências de forma inteligente** — não sobe `monolito`+infra se ninguém usa o backend local.
3. **Instale dependências** com bootstrap completo (build + npm + go mod + certs + checagem de pré-reqs).

## Decisões travadas (decision gate 2026-06-15)

| # | Decisão | Escolha |
|---|---------|---------|
| 1 | UX de seleção de ambiente | **Wizard interativo** (pergunta container por container; resumo + confirmação antes de subir) |
| 2 | bashly vs Makefile | **bashly é a interface única**; o Makefile só builda a CLI (`bashly generate`) — demais alvos removidos |
| 3 | Resolução de dependências | **Inteligente**: se nenhum app usa o backend local, NÃO sobe monolito/worker/postgres/redis/localstack |
| 4 | Escopo do `install` | **Bootstrap completo**: build imagens + npm install (bo+front no container) + go mod download + gera certs + checa `~/.npmrc` / `~/.ssh` / `/etc/hosts` |

## Onde roda

A CLI roda no **host do dev** (onde existe docker/podman + o repo coruja com submodules).
bashly gera um único script bash portável (`estrategia`). O backend de compose é
autodetectado (`docker compose` → `docker-compose` → `podman-compose`), com override por
flag/env `COMPOSE=`.

## Contrato "local vs sandbox" por serviço

Derivado dos Dockerfiles e do `docker-compose.yml` existentes:

| Serviço | `local` | `sandbox` |
|---|---|---|
| `front-student` | `NPM_SCRIPT_ENV=local`, `BFF_URL=https://api.local.estrategia-sandbox.com.br/` → CMD `npm run local:<VERTICAL>` | `NPM_SCRIPT_ENV=sandbox`, `BFF_URL=https://api.estrategia-sandbox.com.br/` → CMD `npm run sandbox:<VERTICAL>` |
| `bo-container` | `BO_ENV=local` (`quasar dev`) | `BO_ENV=sandbox` |
| `monolito` + `monolito-worker` | sobe (`APP_ENV=local`, go run/CompileDaemon contra postgres/redis/localstack) | **não sobe** (frontend usa BFF deployado) |
| `reverseproxy` | sobe sempre que algum frontend sobe (termina TLS) | idem |
| `postgres` / `monolito-redis` / `localstack` | sobe junto com o monolito local | não sobe |

## Lógica de resolução (wizard → serviços)

Estado de entrada: `front ∈ {local,sandbox,skip}`, `bo ∈ {local,sandbox,skip}`,
`monolito ∈ {auto,local,skip}`.

```
backend_local = (monolito == local) OR (front == local) OR (bo == local)
              [quando monolito == auto, deriva dos frontends]

serviços a subir:
  - front-student   se front != skip
  - bo-container    se bo != skip
  - reverseproxy    se (front != skip) OR (bo != skip)   # TLS dos frontends
  - monolito        se backend_local
  - monolito-worker se backend_local  (flag --no-worker pula)
  - postgres        se backend_local
  - monolito-redis  se backend_local
  - localstack      se backend_local
```

A CLI então exporta as env vars derivadas (`NPM_SCRIPT_ENV`, `BFF_URL`, `BO_ENV`,
`APP_ENV`, `VERTICAL`) e roda `$COMPOSE up -d <lista resolvida>`. Ambiente exportado
sobrescreve o `.env` (precedência nativa do compose).

## Comandos da CLI

| Comando | O que faz |
|---|---|
| `estrategia up [flags]` | Wizard de ambiente → resolução → `compose up -d`. Flags pulam o wizard: `--front <env>`, `--bo <env>`, `--monolito <auto\|local\|skip>`, `--no-worker`, `--yes` (não-interativo), `--vertical <v>` |
| `estrategia install` | Bootstrap completo (build + npm install bo/front + go mod download + certs + `doctor`) |
| `estrategia doctor` | Só a checagem de pré-reqs (docker, mkcert, certs, `~/.npmrc`, `~/.ssh`, `/etc/hosts`) — reaproveitado pelo `install` |
| `estrategia down [--volumes]` | Derruba (mantém volumes; `--volumes` apaga = antigo `clean`) |
| `estrategia status` | `compose ps` |
| `estrategia logs [service] [--tail N]` | Tail dos logs |
| `estrategia restart [service]` | `--force-recreate` |
| `estrategia build [service]` | (Re)build de imagens |
| `estrategia debug [app\|worker]` | Sobe monolito/worker com Delve headless (2345/2346) |
| `estrategia shell <service>` | `compose exec <service> sh` (conveniência) |

## Estrutura bashly

```
estrategia/
  src/
    bashly.yml               # definição declarativa de comandos/flags/args/examples
    up_command.sh
    install_command.sh
    doctor_command.sh
    down_command.sh
    status_command.sh
    logs_command.sh
    restart_command.sh
    build_command.sh
    debug_command.sh
    shell_command.sh
    lib/
      compose.sh             # detecta backend compose; estrategia_dir() + run_compose()
      resolve.sh             # estado de env → lista de serviços + env vars + print_plan
      wizard.sh              # pick_env() (usa gum/fzf se houver; fallback read numérico)
      checks.sh              # doctor: pré-reqs + ensure_certs
  estrategia                 # script gerado (bashly generate) — commitar
  Makefile                   # SÓ builda a CLI: `make build` → bashly generate
```

`bashly generate` empacota `src/**` num único `estrategia` standalone (bash puro, sem runtime).

## Wizard (interativo)

Para cada serviço selecionável (`front-student`, `bo-container`, `monolito`) pergunta o
ambiente; mostra o resumo resolvido (incluindo o que sobe por dependência) e pede
confirmação `[Y/n]`.

- Se `gum` ou `fzf` estiver no PATH → seleção com setas (bonito).
- Senão → prompt numérico nativo (`read`), zero dependência.
- `--yes` + flags → modo não-interativo (CI / scripts).

## install / doctor (bootstrap completo)

`doctor` (também chamado no início do `install`) verifica e reporta com remédio:

- `docker`/`docker compose` (ou podman-compose) presente
- `mkcert` instalado; `certs/fullchain.pem` existe (senão roda `scripts/gen-cert.sh`)
- `~/.npmrc` com `_authToken` para `npm.pkg.github.com`
- `~/.ssh/id_*` presente (GOPRIVATE estrategiahq)
- entradas `*.local.estrategia-sandbox.com.br` no `/etc/hosts` (reporta as faltantes; **não** edita — fora de escopo)
- `.env` existe (senão copia de `.env.example` e avisa pra ajustar paths)

`install` então: `compose build` → `npm install` (bo, front via `compose run --rm`) →
`go mod download` (monolito) → `gen-cert.sh` se faltar.

## Gaps conhecidos / riscos

- **bo-container sandbox**: o `docker-compose.yml` comenta que o modo sandbox "avançado"
  usa `node -e "require('./.env-cmdrc.js')['<BO_ENV>']"`. O `.env-cmdrc.js` é do repo
  bo-container e não está aqui. Modelamos via `BO_ENV`; se o command precisar mudar,
  fica como ponto de extensão (override de `command` no compose). **A validar com o repo real.**
- **Repo `.cache` stub**: `/workspace/.cache/work` tem `.git` vazio — não dá pra commitar
  daqui. Entrego os arquivos; versionamento é feito no host.
- **`/etc/hosts`**: o `doctor` só reporta entradas faltantes (não edita — exige sudo).

## Fora de escopo (YAGNI)

- Profiles salvos / arquivo de combos (decisão 1 = wizard; flags cobrem automação).
- Edição automática de `/etc/hosts`.
- Suporte a ambiente `devbox`/`qa` no wizard (só `local`/`sandbox` por ora — extensível).
- Orquestração dos demais apps do monorepo (accounts, ecommerce, etc.) — só os 3 do compose atual.
