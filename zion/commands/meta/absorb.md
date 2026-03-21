# Absorb — Cristalizar a Sessão

```
/meta:absorb          → cristalizar: persiste memórias, skills, agentes
/meta:absorb resumo   → resumo leve da sessão em linguagem simples
```

Chame depois de uma boa conversa. Reflete sobre tudo que aconteceu nesta sessão e persiste o que vale: memórias Claude, skills Zion, agentes, commands.

---

## Modo `resumo`

Se `$ARGUMENTS` contiver `resumo` ou `imhi`: explicar a sessão cronologicamente como se fosse pra uma criança de 7 anos. Tom carinhoso, frases curtas, ícones visuais. Incluir linha do tempo ASCII, tabela de resultados, barra de progresso e rodapé com "próximo passo" e "pode dormir?". Não persistir nada — só explicar.

---

## Instruções

Você (Claude) deve executar o ABSORB diretamente — sem subagente, sem Wanderer. Você tem o contexto completo desta conversa.

### 1. Revisar a sessão

Olhe para tudo que foi discutido e identifique:

- **Correções** — algo que você fez errado e foi corrigido
- **Preferências** — como o usuário gosta que as coisas sejam feitas
- **Decisões de design** — escolhas arquiteturais, convenções, padrões
- **Conhecimento novo** — sobre o sistema, projeto, usuário
- **Padrões emergentes** — algo que apareceu 2+ vezes e merece formalizar
- **Gaps** — skill, command ou agent que deveria existir mas não existe

### 2. Persistir o que vale

| O que é | Onde salvar |
|---------|-------------|
| Correção de comportamento | `~/.claude/projects/-workspace-mnt/memory/feedback_*.md` |
| Preferência do usuário | `memory/user_*.md` |
| Contexto de projeto | `memory/project_*.md` |
| Referência externa | `memory/reference_*.md` |
| Melhoria em skill existente | editar `zion/skills/*/SKILL.md` |
| Comportamento de agente mudou | editar `zion/agents/*/agent.md` |
| Regra fundamental | sugerir via inbox (não editar CLAUDE.md direto) |

**Paths:**
- Memórias: `~/.claude/projects/-workspace-mnt/memory/` + `MEMORY.md`
- Zion skills: `/workspace/mnt/zion/skills/`
- Zion agents: `/workspace/mnt/zion/agents/`
- Commands: `/workspace/mnt/stow/.claude/commands/`

### 3. Skills disponíveis (para identificar gaps ou melhorias)

Liste as skills atuais do sistema e avalie se alguma precisa de update ou se falta alguma baseado na sessão:

```bash
ls /workspace/mnt/zion/skills/
ls /workspace/mnt/stow/.claude/commands/
```

### 4. Regras

- Verificar se já existe algo similar antes de criar (não duplicar)
- Se for memory: atualizar MEMORY.md também
- Não salvar coisas deriváveis do código ou git
- Não editar CLAUDE.md diretamente — sugerir via inbox
- Silêncio é válido — se nada novo emergiu, dizer isso

### 5. Reportar

Ao final, mostre ao usuário um resumo inline:

```
## Absorb — Sessão cristalizada

**Memórias salvas/atualizadas:** lista
**Zion atualizado:** skills/agents/commands modificados
**Sugestões:** o que precisa aprovação do usuário
**Nada novo:** se não havia o que absorver
```
