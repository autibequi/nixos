# Pesquisar Subcontainer Nix para Subagentes

## Objetivo
Pesquisar como criar subcontainers (containers aninhados) a partir do container `claude-nix-sandbox` (baseado em `nixos/nix:latest`) para que o Claudinho possa:

1. **Aninhar subagentes** — spawnar containers filhos que rodam instâncias de Claude Code como subagentes isolados
2. **Rodar serviços do monolito** — levantar serviços do projeto (Go APIs, bancos de dados, etc.) dentro de containers filhos para testes e desenvolvimento

## Contexto atual
- Container base: `nixos/nix:latest` (ver `/workspace/Dockerfile.claude`)
- Roda como user `claude` (uid 1000) dentro do container
- Host usa Podman (não Docker daemon)
- Compose file: `/workspace/docker-compose.claude.yml`
- Projetos de trabalho montados em `/workspace/claudinho/`

## O que pesquisar

### 1. Docker-in-Docker (DinD) vs Socket forwarding
- Podman-in-Podman é viável no nixos/nix?
- Montar o socket do Podman do host (`/run/podman/podman.sock`) dentro do container
- Rootless Podman dentro de container Nix — precisa de user namespaces?
- Alternativa: usar `nix run` pra levantar serviços sem container aninhado

### 2. Nix como gerenciador de ambientes
- `nix develop` pra criar shells isolados com dependências do monolito (Go, PostgreSQL, Redis, etc.)
- `nix build` pra construir imagens OCI direto do Nix (nixpkgs.dockerTools)
- `nix run` pra rodar serviços efêmeros sem precisar de container

### 3. Permissões necessárias
- Quais capabilities o container pai precisa (`--privileged`, `SYS_ADMIN`, etc.)
- Como configurar user namespaces pra Podman rootless aninhado
- Impacto de segurança de cada abordagem
- O que precisa mudar no `docker-compose.claude.yml`

### 4. Abordagens alternativas
- `bubblewrap` (bwrap) como sandbox leve dentro do container Nix
- `systemd-nspawn` dentro do container
- Machinectl / NixOS containers (nixos-container)
- Simplesmente usar `nix-shell` / `devShells` pra isolar ambientes

### 5. Subagentes Claude Code
- Como o runner (`clau-runner.sh`) poderia spawnar subagentes em containers filhos
- Compartilhar o volume `/workspace` vs copiar
- Limites de recursos (cgroups) pra evitar que subagente consuma tudo
- Comunicação entre agente pai e filhos (filesystem, unix socket, etc.)

## Entregável
Escreva resultado em `<diretório de contexto>/contexto.md` com:

1. **Comparativo** das abordagens (tabela: abordagem × complexidade × segurança × flexibilidade)
2. **Recomendação** com a abordagem mais pragmática pro cenário
3. **PoC** — mudanças mínimas necessárias no Dockerfile.claude e docker-compose.claude.yml
4. **Riscos** — o que pode dar errado e como mitigar

## Regras
- NÃO modifique arquivos do workspace — apenas pesquise e documente
- Foque em soluções que funcionem com Podman (não assume Docker daemon)
- Priorize abordagens rootless quando possível
- Considere que o host é NixOS (pode ter particularidades)
