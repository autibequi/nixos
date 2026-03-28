---
name: reference_pr_message_skill
description: Onde vive e qual o contrato da skill code/pr-message (descrições de PR Estrategia)
type: reference
---

## Contrato do template

Ordem fixa: `# TICKET — título (repo)` → **O que foi implementado** → **Como testar** (tabela, cenários `Happy —` / `Sad —` sem emoji no padrão) → **Dependências** (preferir 2 colunas `Tipo` | `Item`; 3ª coluna só em PRs com migration/fila/toggler) → **`## JIRA`** com **URL pura** numa linha (`https://estrategia.atlassian.net/browse/<TICKET>`), sem link markdown.

Escopo: branch→`main` ou, se branch suja, commit/paths filtrados + nota opcional `> **Escopo:** …`.

## Onde está a skill (espelhos)

| Local | Path |
|-------|------|
| Leech no host (fonte operacional) | `…/leech/self/skills/code/pr-message/SKILL.md` (sob `$LEECH_ROOT` / mount em `/workspace/host/leech/self/`) |
| Self persistente no container | `/workspace/self/skills/code/pr-message/SKILL.md` |
| Workspace Cursor (mnt) | `/workspace/mnt/.cursor/skills/code/pr-message/SKILL.md` |

Manter conteúdo alinhado entre esses três quando houver mudança de contrato.

## Permissões

Subpastas sob `self/skills/code/` podem ter sido criadas como **root**; até `chown` para o user do container, `cp`/`Write` falha. Workaround temporário: gravar em `pr-message-updated/` ou ficheiro `*.SKILL.md` ao lado; depois do `chown`, instalar no `pr-message/`.

## Índice composto

Linha em `self/skills/code/SKILL.md` na tabela deve mencionar JIRA + escopo por commit/paths.
