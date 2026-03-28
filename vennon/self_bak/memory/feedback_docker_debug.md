---
name: docker debug — dlv remoto em containers
description: Lições de como configurar Delve para debug remoto Go em Docker com Cursor/VS Code
type: feedback
---

**Regras aprendidas ao implementar `vennon run monolito --debug`:**

1. **dlv binário fica em `/go/bin/dlv`, não `/root/go/bin/dlv`**
   Na imagem `golang:alpine`, `go install` instala em `$GOPATH/bin = /go/bin`.
   CMD deve ser `["/go/bin/dlv", ...]`.

2. **`--continue` exige `--accept-multiclient` obrigatoriamente**
   Sem `--accept-multiclient`, dlv rejeita `--continue` com exit code 1 e o container fica em loop de restart.

3. **`dlv dap --listen` não funciona bem com Cursor no modo launch**
   Cursor se conecta e diz "debug session already in progress - use remote attach mode".
   Solução: usar `dlv exec --headless --listen=:2345 --api-version=2 --accept-multiclient --continue` + `request: "attach", mode: "remote"` no launch.json.

4. **SYS_PTRACE + apparmor:unconfined são obrigatórios**
   Sem esses, dlv não consegue fazer ptrace no processo filho dentro do container.
   Colocar no docker-compose.debug.yml como override.

5. **substitutePath em vez de remotePath/localRoot**
   Versões novas da extensão Go usam `substitutePath: [{from: workspaceFolder, to: /go/app}]`.
   `remotePath` e `localRoot` são deprecated.

6. **Debug Console "Type 'dlv help' for list of commands." = conectado com sucesso**
   Não é erro. É a mensagem normal do dlv quando o debugger está attached.
   Logs do servidor continuam no terminal do `vennon logs`, não no Debug Console.

7. **Imagem de debug deve ser golang:alpine no runtime (não alpine puro)**
   `alpine:latest` não tem Go, então não dá pra instalar dlv.
   Runtime do Dockerfile.debug usa `golang:1.24.4-alpine` para ter `go install`.

**Why:** Implementado em 2026-03-18 ao adicionar suporte a debug remoto no Dockerizer do monolito.
**How to apply:** Qualquer serviço Go que precise de debug remoto via Docker + Cursor/VS Code.
