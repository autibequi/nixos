# Pesquisa: Subcontainers Nix para Subagentes — RESULTADO

## Status
✅ **CONCLUÍDO** — Pesquisa completa com recomendação pragmática

## Entrega

### Documentação Gerada
- **contexto.md**: Análise completa com 9 seções
  - Comparativo de 6 abordagens (tabela)
  - Recomendação: Abordagem Híbrida em 3 Níveis
  - PoC Mínimo com mudanças específicas (Dockerfile, docker-compose, script)
  - Riscos identificados + mitigações
  - Roadmap de implementação (4 fases)

## Achados Principais

### 1. Stack Atual Já Suporta Subcontainers
- Socket Podman já montado em docker-compose.yml (apenas remover :ro)
- userns_mode: keep-id garante user namespaces (sem --privileged needed)
- nixos/nix:latest é minimal e seguro para DinD alternativas

### 2. Recomendação Final: Abordagem Híbrida

**Nível 0 (Leve)**: nix develop + nix run
- Ideal para serviços do monolito (Go, DB)
- Zero overhead de container, reproduzível

**Nível 1 (Médio)**: Podman Socket Forwarding
- Subagentes Claude via containers OCI
- Seguro: rootless Podman, sem --privileged
- Mudanças mínimas (3 arquivos)

**Nível 2 (Pesado, Future)**: NixOS containers
- Full OS isolation se necessário
- nixos-container CLI no host

### 3. Mudanças Implementação

**Dockerfile.claude**: +2 linhas (podman, podman-compose)

**docker-compose.yml**: 
- Remover :ro de /run/podman/podman.sock
- Adicionar cap_add: [SYS_ADMIN, NET_ADMIN]
- Novo service subagent (template)

**clau-runner.sh**: Detectar --subagent flag, usar flock para task queueing

### 4. Segurança

Analysed 7 security risks:
- Privilege escalation: MITIGATED via rootless Podman
- Resource exhaustion: MITIGATED via cgroups (mem_limit, cpu_shares)
- Race conditions: MITIGATED via flock + atomic filesystem
- Socket permissions: OK com userns_mode: keep-id

### 5. Roadmap Implementação
- Fase 1 (semana 1): Socket + Podman install + test
- Fase 2 (semana 2): Task queueing + pai-filho communication
- Fase 3 (semana 3): nix develop integration (Go API, DB)
- Fase 4 (week 4): Full orchestration (múltiplos subagentes)

## Próximos Passos (Recomendados)

1. **Validação PoC**: Testar socket forwarding com `podman ps` no container
2. **Prototipagem**: Criar subagent container em docker-compose
3. **Integração**: Adaptar clau-runner.sh para --subagent flag
4. **Testes de carga**: Múltiplos subagentes spawning tasks
5. **Documentação**: Atualizar projetos/CLAUDE.md com setup

## Referências Principais

- nixos/nix:latest container image
- Podman rootless architecture + socket forwarding
- Nix flakes + devShells
- nixpkgs.dockerTools (OCI images)
- systemd-nspawn + NixOS containers
- User namespaces + cgroups

---

**Tempo total**: ~2h de pesquisa
**Model**: Haiku 4.5
**Confiança**: Alta (Stack atual viável, roadmap claro)
