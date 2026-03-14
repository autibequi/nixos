# Retomar Feature

Retoma trabalho em feature iniciada em sessão anterior.

## Entrada
- `$ARGUMENTS`: nome da feature ou card Jira (ex: FUK2-1234)

## Instruções

Spawne o agente **Orquestrador** com o skill `retomar-feature`:

```
Agent subagent_type=Orquestrador prompt="Execute o skill retomar-feature para: $ARGUMENTS"
```

O Orquestrador vai:
1. Ler feature folder e arquivos de cada agente
2. Checar estado git de cada repo (branches, commits, PRs)
3. Identificar o que foi concluído vs pendente
4. Retomar de onde parou
