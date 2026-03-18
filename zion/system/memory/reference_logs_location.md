---
name: reference_logs_location
description: Onde encontrar logs de serviços, testes e containers Docker no ambiente zion
type: reference
---

Logs de monitoramento ficam em `/workspace/logs/` (disponível em todas as sessões, não só `zion edit`).

**Estrutura no agente (`/workspace/logs/docker/<service>/`):**
- `service.log` — logs do servidor em runtime (streaming do docker compose)
- `test.log` — output completo dos testes (`zion docker <service> test`)
- `startup.log` — log do build e up inicial
- `deps.log` — log das dependências (postgres, redis)
- `install.log` — log do install de dependências

**Exemplos:**
- `/workspace/logs/docker/monolito/service.log`
- `/workspace/logs/docker/monolito/test.log`
- `/workspace/logs/docker/bo-container/test.log`
- `/workspace/logs/docker/front-student/test.log`

**Volume mount:** `/tmp/zion-logs/dockerized` → `/workspace/logs/docker` (ro)
**Função host:** `zion_docker_log_dir("monolito")` = `/tmp/zion-logs/dockerized/monolito`
**No container do teste:** o mesmo diretório é montado em `/workspace/logs` (rw) — testes podem escrever artefatos lá

**Logs do host/sistema:**
- `/workspace/logs/host/journal/` — journal systemd do host NixOS (só em `zion edit`)

**Regra:** quando o usuário falar sobre logs de um serviço ou testes, buscar em `/workspace/logs/docker/<nome>/`. Para logs do sistema/host, usar `/workspace/logs/host/journal/`.
