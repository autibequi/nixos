---
name: Zion must be self-contained
description: Only use files from /nixos/zion, never reference stow/.claude/ or external paths
type: feedback
---

**Rule:** Zion deve ser self-contained. Toda infraestrutura (CLI, skills, agents, compose files) vive em `/nixos/zion/` (que é versionada no GitHub como NixOS repo). Nunca fazer referência a caminhos fora do Zion (como `stow/.claude/`, `.claude/commands/`, etc).

**Why:** O Zion é um monorepo que deve rodar de forma isolada e reutilizável. Tudo que o Zion precisa está dentro dele.

**How to apply:** Quando criando skills, comandos CLI, ou configurações do Zion:
- Use caminhos relativos a `/workspace/mnt/zion/` (ou `~/nixos/zion/` no host)
- Skills ficam em `zion/skills/<skill-name>/SKILL.md`
- Agentes ficam em `zion/agents/<agent-name>/agent.md`
- Compose files e configs Docker ficam em `zion/containers/<service>/`
- Nunca referencie `.claude/` ou `stow/` de dentro do Zion
