# Agentroom — Protocolo dos Agents

## Regra Zero — Self-Scheduling

**Nao reagendar = morrer.** Ao final de CADA ciclo:

```bash
NEXT=$(date -d "+N minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/agents/_running/*_SEUNOME.md \
   /workspace/obsidian/agents/_schedule/${NEXT}_SEUNOME.md 2>/dev/null
```

- SEMPRE reagendar, mesmo se falhar
- Quota >= 70%: intervalo 2x
- On-demand: +24h heartbeat

## Inicio do Ciclo

```bash
# Skill obsidian ja no contexto (boot injeta)
cat /workspace/obsidian/agents/SEUNOME/memory.md
ls /workspace/obsidian/outbox/para-SEUNOME-*.md 2>/dev/null
```

## Breakroom

```
agents/<nome>/
├── memory.md       — persistente (unico arquivo, atualizar ANTES de reagendar)
├── DIARIO.md       — append-only
├── diarios/        — logs por ciclo
├── outputs/        — artefatos
├── cartas/         — copias CTO
└── done/           — cards concluidos
```

## memory.md

```yaml
---
name: <nome>-memory
type: agent-memory
updated: YYYY-MM-DDTHH:MMZ
---
```

Append ciclo novo no topo. Manter 5-10 ciclos.

## Fim do Ciclo

```
1. [ ] Atualizar memory.md
2. [ ] Append inbox/feed.md se relevante
3. [ ] REAGENDAR (Regra Zero)
```

## Regras

- Nunca commitar sem CTO pedir
- Nunca mover cards DOING/DONE
- Datas absolutas, nunca relativas

## Criacao de cards com backlog de implementacao

**Antes de criar qualquer card que envolva implementacao de codigo ou feature:**

1. Carregar skill `refinar` (`/workspace/self/skills/refinar/SKILL.md`)
2. Investigar o codebase alvo (ondas: estrutura → padroes → pontos de extensao)
3. Mapear camadas de dependencia
4. Montar backlog ordenado com tasks TX: dimensionadas para ~25min cada
5. So entao criar o card com o backlog embutido

**Regra de madrugada (21h-6h UTC):**
Cards de implementacao devem ser agendados para rodar na madrugada — tokens de baixo custo, sem competicao de quota, tempo de reflexao aproveitado.
Ao criar um card pesado: `NEXT=$(date -u -d "tomorrow 02:00" +%Y%m%d_%H_%M)` ou horario de madrugada mais proximo.

**Sinal de que o backlog esta pronto:**
- Cada task tem resultado verificavel
- A ordem respeita as camadas (dados → estado → UI → polish)
- Nenhuma task tem mais de 3 arquivos novos
- Existe skill de dominio para acumulo de conhecimento entre ciclos
