# Recommit

Reorganiza histórico de commits de uma branch pra PR review.

## Entrada
- `$ARGUMENTS`: (opcional) repo (monolito, bo-container, front-student)

## Instruções

Spawne o agente **Orquestrador** com o skill `recommit`:

```
Agent subagent_type=Orquestrador prompt="Execute o skill recommit. $ARGUMENTS"
```

O Orquestrador vai:
1. Perguntar qual repo (se não especificado)
2. Resetar commits desde fork de main
3. Ler diff final do código
4. Criar commits limpos, cronológicos, pequenos — narrativa lógica
5. Opcionalmente force-push
