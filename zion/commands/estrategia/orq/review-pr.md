# Review PR

Lê e resolve comentários de review em um PR no GitHub.

## Entrada
- `$ARGUMENTS`: número do PR ou link (ex: 123, owner/repo#123)

## Instruções

Spawne o agente **Coruja** com o skill `review-pr`:

```
Agent subagent_type=Coruja prompt="Execute o skill review-pr para: $ARGUMENTS"
```

A Coruja vai:
1. Ler todos os comentários do PR via `gh` CLI
2. Agrupar por arquivo/tópico
3. Iterar no código pra resolver cada comentário
