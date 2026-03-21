# PR Inspector

Inspeção interativa e guiada de PR — caminha com o dev categoria por categoria, detecta hallucinations, cross-referencia padrões existentes.

## Entrada
- `$ARGUMENTS`: número do PR, URL, ou `<repo>#<number>` (ex: `monolito#1234`)

## Instruções
Spawne o agente **Coruja** com o skill `pr-inspector`:
```
Agent subagent_type=Coruja prompt="Execute o skill pr-inspector para: $ARGUMENTS"
```
