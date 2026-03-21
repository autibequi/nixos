# Refinar Bug

Investiga e refina um card de Bug no Jira.

## Entrada
- `$ARGUMENTS`: número do card Jira (ex: FUK2-5678)

## Instruções

Spawne o agente **Coruja** com o skill `refinar-bug`:

```
Agent subagent_type=Coruja prompt="Execute o skill refinar-bug para: $ARGUMENTS"
```

A Coruja vai:
1. Ler o card Jira
2. Investigar repos pertinentes (monolito, bo-container, front-student)
3. Encontrar referências no código (arquivo, linha, método)
4. Preencher campo "Sugestão de Implementação" com template ADF estruturado
