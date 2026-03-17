# Changelog

Gera changelog visual de todas as mudanças na branch atual vs main.

## Entrada
- `$ARGUMENTS`: (opcional) repo específico ou branch

## Instruções

Spawne o agente **Orquestrador** com o skill `changelog`:

```
Agent subagent_type=Orquestrador prompt="Execute o skill changelog. $ARGUMENTS"
```

O Orquestrador vai:
1. Diffar cada sub-repositório contra main
2. Categorizar mudanças por tipo (handlers, services, repos, workers, pages, components, routes)
3. Apresentar changelog estruturado com nomes de métodos e parâmetros
