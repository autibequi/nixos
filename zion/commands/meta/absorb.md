# Absorb — Cristalizar a Sessão

Chame depois de uma boa conversa. Lança o **Wanderer** em background no modo ABSORB — ele reflete sobre tudo que aconteceu e persiste o que vale para sempre: memórias Claude, skills Zion, agentes, commands, obsidian.

Não bloqueia sua thread. Wanderer reporta quando terminar via inbox.

## Instruções

Lançar o Wanderer em background no modo ABSORB:

```
Agent(
  subagent_type="Wanderer",
  prompt="""Modo: ABSORB — Cristalizar aprendizados da sessão.

Você tem acesso ao contexto completo desta conversa. Revise tudo que foi discutido e tente absorver o máximo possível nos lugares certos.

## O que procurar

- **Correções** — algo que Claude fez errado e foi corrigido
- **Preferências** — como o usuário gosta que as coisas sejam feitas
- **Decisões de design** — escolhas arquiteturais, convenções, padrões
- **Conhecimento novo** — sobre o sistema, projeto, usuário
- **Padrões emergentes** — algo que apareceu 2+ vezes e merece formalizar
- **Gaps** — skill, command ou agent que deveria existir mas não existe

## Onde persistir cada coisa

| O que é | Onde salvar |
|---------|-------------|
| Correção de comportamento | `~/.claude/projects/-workspace-mnt/memory/feedback_*.md` |
| Preferência do usuário | `memory/user_*.md` |
| Contexto de projeto | `memory/project_*.md` |
| Referência externa | `memory/reference_*.md` |
| Melhoria em skill existente | editar `zion/skills/*/SKILL.md` |
| Comportamento de agente mudou | editar `zion/agents/*/agent.md` |
| Insight sobre o vault | `/workspace/obsidian/vault/insights.md` |
| Regra fundamental | sugerir via inbox (não editar CLAUDE.md direto) |

## Paths importantes

- Memórias: `~/.claude/projects/-workspace-mnt/memory/` + `MEMORY.md`
- Zion skills: `/workspace/mnt/zion/skills/`
- Zion agents: `/workspace/mnt/zion/agents/`
- Commands: `/workspace/mnt/stow/.claude/commands/`

## Regras

- Verificar se já existe algo similar antes de criar (não duplicar)
- Se for memory: atualizar MEMORY.md também
- Não salvar coisas deriváveis do código ou git
- Não editar CLAUDE.md diretamente — sugerir via inbox
- Silêncio é válido — se nada novo emergiu, diga isso

## Ao terminar

Appenda em `/workspace/obsidian/inbox/inbox.md`:

### [Wanderer/Absorb] YYYY-MM-DD — Sessão cristalizada

**Memórias Claude:** lista do que foi salvo/atualizado
**Zion atualizado:** skills/agents/commands modificados
**Sugestões pendentes:** o que precisa aprovação do usuário
**Nada novo:** se não havia o que absorver
""",
  run_in_background=True
)
```

Confirmar ao usuário que o Wanderer foi lançado em background e vai reportar no inbox quando terminar.
