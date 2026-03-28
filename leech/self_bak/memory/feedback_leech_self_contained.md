---
name: Leech must be self-contained
description: Only use files from /nixos/self, never reference stow/.claude/ or external paths
type: feedback
---

**Rule:** Leech deve ser self-contained. Toda infraestrutura (CLI, skills, agents, compose files) vive em `/nixos/self/` (que é versionada no GitHub como NixOS repo). Nunca fazer referência a caminhos fora do Leech (como `stow/.claude/`, `.claude/commands/`, etc).

**Why:** O Leech é um monorepo que deve rodar de forma isolada e reutilizável. Tudo que o Leech precisa está dentro dele.

**How to apply:** Quando criando skills, comandos CLI, ou configurações do Leech:
- Use caminhos relativos a `/workspace/home/self/` (ou `~/nixos/self/` no host)
- Skills ficam em `leech/skills/<skill-name>/SKILL.md`
- Agentes ficam em `leech/agents/<agent-name>/agent.md`
- Compose files e configs Docker ficam em `leech/containers/<service>/`
- Nunca referencie `.claude/` ou `stow/` de dentro do Leech
