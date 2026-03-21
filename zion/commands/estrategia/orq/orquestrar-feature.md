# Orquestrar Feature

Recebe um card Jira e orquestra a implementação across repos.

## Entrada
- `$ARGUMENTS`: número do card Jira (ex: FUK2-1234) ou descrição da feature

## Instruções

Spawne o agente **Coruja** com o skill `orquestrar-feature`:

```
Agent subagent_type=Coruja prompt="Execute o skill orquestrar-feature para: $ARGUMENTS"
```

A Coruja vai:
1. Ler o card Jira e investigar escopo
2. Identificar repos envolvidos (monolito, bo-container, front-student)
3. Criar feature folder com arquivos de instrução por agente
4. Apresentar plano e pedir aprovação
5. Delegar pra subagentes (monolito, bo-container, front-student)
6. Acompanhar progresso e coordenar integração
