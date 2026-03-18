# Inspector Learn

Absorve aprendizados da sessão atual e atualiza as definições dos inspetores no Obsidian.

## Entrada
- `$ARGUMENTS`: (opcional) nome de um inspetor específico para focar — `claude`, `documentation`, `qa`, `namer`, `simplifier`

## Instruções
Spawne o agente **Monolito** em modo LEARN:
```
Agent subagent_type=Monolito prompt="
Modo: LEARN — Evolução de conhecimento dos inspetores.

1. Leia o contexto completo da sessão atual (findings, discussões, decisões do dev)
2. Leia as definições atuais dos inspetores em /workspace/obsidian/agents/inspectors/
3. Para cada inspetor (ou apenas '$ARGUMENTS' se especificado):
   a. Identifique patterns novos descobertos na sessão
   b. Identifique heurísticas que funcionaram bem ou mal
   c. Identifique armadilhas específicas do monolito encontradas
4. Atualize a seção 'Aprendizados' de cada arquivo no Obsidian
5. Atualize o campo 'updated:' no frontmatter
6. Reporte ao dev o que foi aprendido e por qual inspetor

Formato de cada aprendizado:
### [Título curto]
**Aprendido em:** <contexto> (YYYY-MM-DD)
**Contexto:** <onde/como aparece>
**O que checar:** <ação concreta para inspeções futuras>
"
```
