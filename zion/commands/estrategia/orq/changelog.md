# Changelog

Gera changelog visual de todas as mudanças na branch atual vs main.

## Entrada
- `$ARGUMENTS`: (opcional) repo específico ou branch

## Instruções

Spawne o agente **Coruja** com o skill `changelog`:

```
Agent subagent_type=Coruja prompt="Execute o skill changelog. $ARGUMENTS"
```

A Coruja vai:
1. Diffar cada sub-repositório contra main
2. Categorizar mudanças por tipo (handlers, services, repos, workers, pages, components, routes)
3. Apresentar changelog estruturado com nomes de métodos e parâmetros
