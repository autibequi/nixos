# Estratégia Dev Stack — Docker Compose Standalone

Stack de desenvolvimento local da Estratégia sem dependência do binário Rust `plug`.

## Início rápido — CLI `coruja`

A interface do dev stack é a CLI `coruja` (gerada com [bashly](https://bashly.dannyb.co/)).
Ela escolhe o **ambiente de cada container** (local/sandbox, misturado), resolve as
dependências de forma inteligente e faz o bootstrap.

```bash
# 1) Buildar e instalar a CLI no PATH (~/.local/bin/coruja)
make install            # = bashly generate + instala em ~/.local/bin (grava o path do projeto)

# 2) Usar de qualquer diretório
coruja doctor           # checa pré-requisitos (docker, mkcert, certs, ~/.npmrc, ~/.ssh, /etc/hosts)
coruja install          # 1ª vez: wizard escolhe os apps → build + deps (npm/go mod) + certs
coruja install --yes    # instala deps de TODOS os apps, sem wizard
coruja up               # wizard: ambiente por serviço + modo; foreground segura o terminal e mostra logs
coruja up -d            # sobe em background (detached) e devolve o terminal
coruja up --front sandbox --bo local --yes   # não-interativo (flags pulam o wizard)
coruja up --dry-run                          # mostra o que subiria, sem subir
coruja status           # status dos containers
coruja logs monolito
coruja down             # derruba (--volumes apaga os dados)
```

> `make install` grava o caminho deste projeto dentro do binário instalado, então o
> `coruja` funciona de qualquer pasta. Override pontual via `CORUJA_DIR=/path coruja ...`.
> Se `~/.local/bin` não estiver no PATH, o `make install` avisa como adicionar.

> O wizard **lembra a última config usada** (salva em `.coruja-state` no projeto,
> gitignored) e pré-seleciona ela como default na próxima vez — inclusive no
> `coruja up --yes`. Flags sempre têm precedência sobre o state.

**Resolução inteligente:** se todos os frontends apontam pro **sandbox**, o backend local
(monolito/worker/postgres/redis/localstack) **não sobe** — só `reverseproxy` + frontends.
Qualquer serviço em `local` sobe o backend.

**Como cada ambiente se traduz:**

| Serviço | `local` | `sandbox` |
|---|---|---|
| `front-student` | `npm run local:<vertical>`, BFF local | `npm run sandbox:<vertical>`, BFF deployado |
| `bo-container` | `npm run serve:local` (bloco `local` do `.env-cmdrc.js`) | `npm run serve:sandbox` (bloco `sandbox`) |
| `monolito` | sobe local (`.env.local`) | `sandbox`/`prod` chaveiam o `.env`; `skip` não sobe |

> **monolito**: `local`/`sandbox`/`prod` rodam o container localmente mas chaveiam qual
> `.env.<X>` (+ `APP_ENV`) ele carrega — útil pra apontar tokens/integrações (NewRelic,
> Sentry, APIs externas) pra outro ambiente. DB/Redis/localstack continuam **sempre locais**
> (o compose força). `prod` avisa antes de subir.
>
> O DB local espelha o `make setup` do monolito: postgres `root/root` + `01_init_db.sql`
> (cria os databases por vertical) + filas SQS via `init-aws.sh` + `socat` pro SQS hardcoded.
> `coruja seed` popula os dumps (`02+_*.sql`). **1ª vez / recriar os databases:** rode
> `coruja down -v` antes do `up` — o init do postgres só roda em volume vazio.

**Build da CLI** (após editar `src/`): `make build` gera só o `./coruja`; `make install`
builda e instala em `~/.local/bin`. O `Makefile` só (re)gera/instala o script — não sobe
containers (use `coruja up`).

O passo a passo detalhado de pré-requisitos continua documentado abaixo.

## Pré-requisitos

### 1. Docker (ou Podman com compatibilidade docker-compose)

```bash
docker --version        # >= 24
docker-compose --version  # >= 2.x  (ou `docker compose` integrado)
```

### 2. mkcert (geração de certificados TLS locais)

```bash
# Ubuntu/Debian
sudo apt install mkcert libnss3-tools

# macOS
brew install mkcert nss

# Arch
sudo pacman -S mkcert nss

# NixOS / devbox
nix-env -iA nixpkgs.mkcert nixpkgs.nss
```

### 3. Entradas no `/etc/hosts`

O nginx termina TLS com `*.local.estrategia-sandbox.com.br`. Adicionar:

```
127.0.0.1   local.estrategia-sandbox.com.br
127.0.0.1   admin.local.estrategia-sandbox.com.br
127.0.0.1   api.local.estrategia-sandbox.com.br
127.0.0.1   perfil.local.estrategia-sandbox.com.br
```

Verificar após editar:

```bash
ping -c1 admin.local.estrategia-sandbox.com.br
```

### 4. `~/.npmrc` com token GitHub Packages

bo-container e front-student instalam pacotes `@estrategiahq/*` do GitHub Package Registry.
O token é montado read-only em `/root/.npmrc` dentro dos containers.

```bash
# Criar (substituir <TOKEN> pelo PAT com read:packages)
echo "//npm.pkg.github.com/:_authToken=<TOKEN>" >> ~/.npmrc
chmod 600 ~/.npmrc
```

Verificar:
```bash
grep -q "_authToken" ~/.npmrc && echo "OK" || echo "FALTANDO TOKEN"
```

### 5. `~/.ssh` com chave SSH para módulos Go privados

O monolito usa `GOPRIVATE=github.com/estrategiahq/*`. O Dockerfile configura:

```
GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
git config url."git@github.com:estrategiahq/".insteadOf "https://..."
```

Garantir que `~/.ssh/id_ed25519` (ou `id_rsa`) está configurado com acesso ao org `estrategiahq`.

```bash
ssh -T git@github.com    # deve responder "Hi <user>! You've successfully authenticated"
```

---

## Passo a passo — primeira vez

### Passo 1: Gerar certificados TLS

```bash
cd /path/to/este/docker-compose/
bash scripts/gen-cert.sh
```

Saída esperada em `./certs/`:
```
certs/
  fullchain.pem
  privkey.pem
```

### Passo 2: Criar `.env`

```bash
cp .env.example .env
# Editar APP_DIR_MONOLITO, APP_DIR_BO, APP_DIR_FRONT com os paths reais no seu host
nano .env
```

Campos obrigatórios:

| Variável | Exemplo |
|---|---|
| `APP_DIR_MONOLITO` | `/home/pedro/coruja/apps/monolito` |
| `APP_DIR_BO` | `/home/pedro/coruja/apps/bo-container` |
| `APP_DIR_FRONT` | `/home/pedro/coruja/apps/front-student` |

### Passo 3: Instalar node_modules (primeira vez ou após `git clean`)

**bo-container:**
```bash
docker-compose run --rm --no-deps \
  -e VERTICAL=carreiras-juridicas \
  bo-container npm install
```

**front-student:**
```bash
docker-compose run --rm --no-deps \
  --entrypoint sh front-student \
  -c 'cd /app && npm install'
```

### Passo 4: Subir a stack

```bash
# Todos os serviços
docker-compose up -d

# Ver logs ao vivo
docker-compose logs -f monolito front-student

# Só infra (sem apps frontend)
docker-compose up -d reverseproxy postgres monolito-redis localstack
```

### Passo 5: Verificar

| URL | O que deve aparecer |
|---|---|
| `https://local.estrategia-sandbox.com.br` | Front-student (Nuxt) |
| `https://admin.local.estrategia-sandbox.com.br` | BO Container (Quasar) |
| `https://api.local.estrategia-sandbox.com.br/health` | `{"status":"ok"}` |
| `http://localhost:4566/_localstack/health` | LocalStack status JSON |

---

## Grafo de dependências

```
reverseproxy
    ├── (depende de: nenhum serviço compose)
    └── recebe tráfego de: front-student, bo-container, monolito

postgres          ←── monolito, monolito-worker
monolito-redis    ←── monolito, monolito-worker
localstack        ←── monolito, monolito-worker

monolito          ←── front-student (BFF_URL)
                  depende de: postgres (healthy), monolito-redis (healthy), localstack (healthy)

monolito-worker   depende de: postgres (healthy), monolito-redis (healthy), localstack (healthy)

bo-container      depende de: reverseproxy (serve order)
front-student     depende de: reverseproxy, monolito (serve order)
```

Ordem de startup garantida pelo `depends_on` + `condition: service_healthy`.

---

## Operações comuns

```bash
# Parar tudo (mantém volumes)
docker-compose down

# Parar e apagar volumes (reset banco)
docker-compose down -v

# Rebuild das imagens (após mudar Dockerfile)
docker-compose build monolito
docker-compose up -d --no-deps monolito

# Shell no monolito
docker-compose exec monolito /bin/sh

# Rodar make test no monolito
docker-compose exec monolito sh -c 'cd /go/apps/monolito && make test'

# Ver logs de um serviço
docker-compose logs -f --tail=200 monolito-worker

# Ativar debug Delve no monolito
PLUG_DEBUG_APP=1 docker-compose up -d --no-deps monolito
# Conectar: dlv connect localhost:2345
```

---

## Pontos difíceis resolvidos

### 1. `network_mode: host` → rede interna `estrategia`

O `docker-compose.dev.yml` original do monolito usava `network_mode: host`, o que exigia:
- `DB_HOST=127.0.0.1`
- `REDIS_URL=127.0.0.1:6379`
- `socat TCP-LISTEN:4566 TCP:localstack:4566` para redirecionar LocalStack

**Solução:** rede `estrategia` nomeada. Todos os serviços se resolvem por hostname:
- `DB_HOST=postgres`
- `REDIS_URL=monolito-redis:6379`
- `AWS_ENDPOINT_URL=http://localstack:4566`

O `socat` foi **removido** dos entrypoints — não é mais necessário.

O monolito tem alias de rede `api.local.estrategia-sandbox.com.br`, então o front-student
consegue resolver o BFF_URL internamente sem `extra_hosts`.

### 2. `PLUG_DOTENV` / `PLUG_ENV_FILE` → env_file nativo

O plug original passava `PLUG_ENV_FILE` (path de `.env.sandbox`) e o entrypoint
fazia `source` do arquivo. Aqui, as variáveis chegam diretamente via `environment:`
no docker-compose. O entrypoint não faz mais source de arquivo — simplificado.

Se o seu repo tiver um `.env.sandbox` com variáveis extras (ex: feature flags, API keys reais),
adicione ao `env_file:` do serviço `monolito`:

```yaml
monolito:
  env_file:
    - ${APP_DIR_MONOLITO}/.env.sandbox   # opcional
```

### 3. `GOPRIVATE` + SSH

O Dockerfile do monolito configura `GOPRIVATE=github.com/estrategiahq/*` e sobrepõe
`git clone` para usar SSH. O `~/.ssh` é montado read-only em `/root/.ssh:ro`.

**Pré-requisito obrigatório:** `~/.ssh/id_*` com acesso ao org `estrategiahq`.

Se estiver em máquina sem chave SSH configurada, gerar e adicionar ao GitHub:
```bash
ssh-keygen -t ed25519 -C "dev@estrategia"
cat ~/.ssh/id_ed25519.pub   # adicionar em github.com → Settings → SSH Keys
```

### 4. `~/.npmrc` para pacotes `@estrategiahq/*`

bo-container e front-student instalam pacotes do GitHub Package Registry.
O arquivo `~/.npmrc` do host é montado read-only:
```
volumes:
  - ${HOME}/.npmrc:/root/.npmrc:ro
```

Se `~/.npmrc` não existir ou não tiver o token, o `npm install` falha com `401 Unauthorized`.

### 5. Build context do monolito = `apps/` inteiro

O monolito usa `go.work` que referencia SDKs irmãos via path relativo (`../accounts`, `../audit-log`, etc.).
O build context no docker-compose é `${APP_DIR_MONOLITO}/../` (o diretório `apps/`),
e o bind-mount monta `apps/` inteiro em `/go/apps`.

Isso significa que **todos os submodules de `apps/` precisam estar inicializados** no host:
```bash
cd /path/para/coruja
git submodule update --init --recursive
```

### 6. Dockerfile do monolito

O `Dockerfile` original fica em `plug/containers/services/monolito/Dockerfile`.
Ele não está no repo `coruja` — precisará ser copiado para o app ou configurado via variável:

```bash
# Opção A: copiar o Dockerfile para apps/monolito/
cp /path/para/plug/containers/services/monolito/Dockerfile \
   /path/para/coruja/apps/monolito/Dockerfile

# Opção B: apontar MONOLITO_DOCKERFILE no .env
MONOLITO_DOCKERFILE=./monolito/Dockerfile   # relativo ao context apps/
```

O mesmo vale para bo-container e front-student — os Dockerfiles estão em
`plug/containers/services/bo-container/Dockerfile` e `front-student/Dockerfile`.

```bash
# Copiar Dockerfiles
cp plug/containers/services/bo-container/Dockerfile \
   /path/para/coruja/apps/bo-container/Dockerfile

cp plug/containers/services/front-student/Dockerfile \
   /path/para/coruja/apps/front-student/Dockerfile
```

---

## Checklist antes do primeiro `docker-compose up`

- [ ] Docker >= 24 instalado e rodando
- [ ] `mkcert` instalado
- [ ] `bash scripts/gen-cert.sh` executado (arquivos em `./certs/`)
- [ ] `/etc/hosts` tem entradas para `*.local.estrategia-sandbox.com.br`
- [ ] `~/.npmrc` com `_authToken` para `npm.pkg.github.com`
- [ ] `~/.ssh` com chave com acesso ao org `estrategiahq`
- [ ] `.env` criado a partir de `.env.example` com paths reais
- [ ] `git submodule update --init --recursive` executado no coruja
- [ ] Dockerfiles copiados para os apps (ou `MONOLITO_DOCKERFILE`/`BO_DOCKERFILE`/`FRONT_DOCKERFILE` configurados no `.env`)
- [ ] `npm install` rodado para bo-container e front-student via `docker-compose run --rm`
- [ ] `docker-compose up -d` → `docker-compose ps` mostra todos healthy

---

## Estrutura dos arquivos

```
.
├── docker-compose.yml          # stack completa (8 serviços)
├── .env.example                # todas as variáveis com defaults comentados
├── .env                        # (não commitar) — cópia local do .env.example
├── .env.secrets                # (não commitar) — secrets (DB_PASSWORD, tokens)
├── nginx/
│   └── nginx.conf              # proxy reverso adaptado para rede interna
├── scripts/
│   ├── gen-cert.sh             # gera fullchain.pem + privkey.pem via mkcert
│   ├── entrypoint-app.sh       # entrypoint monolito API (CompileDaemon / Delve)
│   └── entrypoint-worker.sh    # entrypoint monolito worker (CompileDaemon / Delve)
└── certs/                      # gerado por gen-cert.sh (não commitar)
    ├── fullchain.pem
    └── privkey.pem
```
