# /code:refine — Refine Task

Mapeia requisito, scope, impacto, unknowns de uma tarefa.

## Responsabilidades

- [ ] Ler o Jira card ou descrição da tarefa
- [ ] Mapear requisito (o que é pedido exatamente?)
- [ ] Definir scope (o que INCLUI, o que NÃO inclui)
- [ ] Identificar impacto (quais áreas afeta?)
- [ ] Listar unknowns/riscos (o que precisa validar?)
- [ ] Preencher seção REFINING no devflow

## Input

```
/code:refine FUK2-XXXXX
```

Ou com contexto:

```
/code:refine
Tarefa: Refactor auth para JWT
Jira: FUK2-987213
Arquivo: /workspace/obsidian/workshop/estrategia/FUK2-987213-refactor-jwt.md
```

## Output

Preenche seção **REFINING** do arquivo devflow com:
- ✅ Requisito mapeado (o que é pedido)
- ✅ Scope definido (inclui/exclui)
- ✅ Impacto identificado (quais repos, services)
- ✅ Riscos/unknowns listados
- ✅ Recomendação: continua PLANNING ou vai pra ATTENTION?

## Exemplo

```
## REFINING

- [x] **Requisito**: Migrar session cookies → JWT para compliance legal
- [x] **Scope**: Backend (Go), Frontend Vue/Nuxt, mobile client
- [x] **Impacto**: 5 services auth-related, breaking change em v1 mobile
- [x] **Risks**:
  - Mobile v1 não espera JWT format
  - Logout precisa revoke strategy
  - Migration sem downtime é crítica
- [x] **Recomendação**: Ir pra ATTENTION — Guru deve brainstorm 4 questões de design
```

## 🌐 Related Skills & Agents

### Skills que Pode Chamar

| Skill | Quando Usar | Contexto |
|-------|-----------|---------|
| `/coruja` (sub-skills) | Se tarefa é Estratégia | Monolito, Vue, Nuxt patterns |
| `/meta:obsidian` | Se precisa explorar vault | Consolidar histórico similar |
| `/meta:feed` | Descobrir contexto cross-repo | Que foi feito recentemente |
| `/thinking:investigate` | Se requisito é vago | Investigar + formular perguntas |

### Agentes que Pode Invocar

| Agente | Quando Usar | Por Quê |
|--------|-----------|--------|
| **Coruja** | Tarefa é Estratégia | Especialista monolito, sabe padrões |
| **Wanderer** | Tarefa é genérica | Explora código desconhecido |
| **Wiseman** | Impacto sistêmico | Consolida aprendizado cross-repo |

### Exemplo: Refine com Contexto Máximo

```
/code:refine FUK2-987213

Mas ANTES:
1. /meta:feed → descobrir contexto recente
2. Chamar Wanderer: "Explore codebase, que padrões já existem?"
3. /coruja → se Estratégia, pega padrões do monolito
4. /thinking:investigate → se ambiguidade

DEPOIS (com contexto):
5. /code:refine (agora com background completo)
```

## Checklist Pós-Refine

- [ ] Arquivo devflow criado/atualizado
- [ ] REFINING preenchido com contexto suficiente
- [ ] **Contexto levantado**: Chamou skills/agentes relacionados
- [ ] ATTENTION vazio ou com brainstorm questions (se complexo)
- [ ] Timeline atualizada com data/hora refining completo
- [ ] Bloqueadores conhecidos identificados (via Wanderer/Wiseman)
