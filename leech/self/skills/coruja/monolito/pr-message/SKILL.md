---
name: coruja/monolito/pr-message
description: Gera descrição de PR do monolito (Go) a partir do diff da branch atual vs main. Categoriza por migration, repository, services, workers, handlers BO e BFF. Usa template fixo com legenda ✻/+ e tabela de cobertura de testes.
---

# coruja:monolito:pr-message — Gerar descrição de PR

Analisa o diff da branch atual vs main e produz o markdown de PR no template padrão do monolito.

## Passo 1 — Identificar fork point e contexto

```bash
HOME=/tmp git config --global --add safe.directory $(pwd)
FORK=$(HOME=/tmp git merge-base origin/main HEAD)
HOME=/tmp git log --oneline $FORK..HEAD
HOME=/tmp git diff origin/main..HEAD --stat | grep -v "_test.go\|mocks/"
```

Extrair:
- **JIRA ID** do nome da branch (ex: `FUK2-11746/toc-async-builder` → `FUK2-11746`)
- **Resumo da feature** lendo commits e arquivos modificados

## Passo 2 — Categorizar arquivos modificados

Agrupar os arquivos do diff (excluindo testes e mocks) nas seguintes seções, nesta ordem:

| Seção | Padrão de path |
|---|---|
| 🗄 Migration | `migration/` |
| 🗃 Repository | `apps/*/internal/interfaces/` + `apps/*/internal/repositories/` |
| ⚙️ Services | `apps/*/internal/services/` |
| 📨 Worker | `apps/*/internal/handlers/*/worker.go` + `event_container.go` + `libs/worker/` + `configuration/config_sqs.yaml` |
| 🛡 Handlers BO | `apps/bo/internal/handlers/` |
| 🌐 Handler BFF | `apps/bff/internal/handlers/` |

Para cada arquivo, ler o diff e identificar:
- O que foi **adicionado** (`+`) — novos métodos, campos, comportamentos
- Se o arquivo foi **criado do zero** ou apenas **modificado**

## Passo 3 — Contar testes

```bash
HOME=/tmp git diff origin/main..HEAD --stat | grep "_test.go"
```

Para cada arquivo de teste novo, listar os `t.Run(...)` para montar a tabela de cobertura. Agrupar por service/função testada.

## Passo 4 — Gerar o markdown no template fixo

Usar exatamente o template abaixo. Seções de arquivos são texto plano (sem backtick blocks).
Omitir seções sem arquivos.

---

## TEMPLATE

```markdown
## O que foi feito?

<resumo em 2-3 linhas explicando o problema resolvido e a abordagem>

---

### 📖 Legenda

✻  arquivo modificado ou criado nesta branch
+  funcionalidade adicionada dentro do arquivo

> Arquivos marcados com `✻` foram tocados nesta branch.
> Linhas com `+` indicam métodos, campos ou comportamentos **novos** inseridos —
> o restante do arquivo já existia e foi mantido sem alteração.

---

### 🗄 Migration

✻ `<path relativo ao repo>`
    <descrição do que a migration faz>

---

### 🗃 Repository

✻ `<interface file>`
\+ `<método adicionado com assinatura>`

✻ `<implementação>`
    <descrição>

---

### ⚙️ Services

`<package path>/`
✻ `<arquivo>.go`
\+ `<Método>` — <descrição curta do que faz>
✻ `<arquivo>.go` — \+ <mudança pontual>

`<outro package path>/`
✻ `<arquivo>.go` — \+ <mudança>

---

### 📨 Worker (SQS handler)

✻ `<handler file>`
\+ `<Handler>` — <descrição>
\+ `<HandlerDLQ>` — DLQ stub

✻ `<event_container>`
\+ registro `<HandlerName>` e `<HandlerNameDLQ>`

✻ `libs/worker/handlers_names.go`
\+ `<HandlerName>` / `<HandlerNameDLQ>`

✻ `configuration/config_sqs.yaml`
\+ `<HandlerName>` e `<HandlerNameDLQ>` em todos os ambientes
  (<lista de ambientes>)

---

### 🛡 Handlers BO — proteção <código de status>

`apps/bo/internal/handlers/ldi/`
✻ `<path>` — \+ <descrição do comportamento adicionado>
...

---

### 🌐 Handler BFF — <descrição>

✻ `<path>`
\+ <descrição>

---

### 🧪 Cobertura de testes

<N> testes unitários adicionados cobrindo os caminhos críticos:

| Área | Cenários cobertos |
|---|---|
| `<Service>.<Método>` | <lista de cenários> |

---

## Como testar?

1. <passo concreto>
2. <passo concreto>

## Dependências

- **<repo ou serviço>**: <o que precisa ser feito lá>
```

---

## Regras

- **Seções de arquivos são texto plano** — sem backtick blocks envolvendo os arquivos
- Paths de arquivos em backtick inline: ✻ \`apps/ldi/...\`
- **Nunca incluir** arquivos de teste ou mocks nas seções de código — apenas na tabela de cobertura
- **Paths relativos** ao root do repo (sem `/home/claude/projects/...`)
- **Resumo** focado no problema de negócio, não na implementação técnica
- Omitir seções sem arquivos — não deixar seções vazias
- Se a branch tiver JIRA ID, mencioná-lo apenas no título do PR (não no body)
