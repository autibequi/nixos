---
name: project_base_interface
description: BASE_INTERFACE.md — 4 dialog templates obrigatórios para todo output interativo
type: project
---

Arquivo criado em `/workspace/self/BASE_INTERFACE.md` com os 4 templates mandatórios de interface.

**Por que:** padronizar outputs de skills, relatórios e respostas para serem visualmente consistentes e copiáveis.

**How to apply:** todo output final de skill usa um desses blocos. Spec completa no arquivo.

## 4 tipos

| Tipo | Estrutura | Quando |
|------|-----------|--------|
| ERRO | bloco sólido `███` no topo + corpo light | falha, exception, build quebrado |
| SUCESSO | bloco sólido `███` no topo + corpo light | tarefa concluída, PR aberto, deploy feito |
| AÇÃO NECESSÁRIA | bloco sólido `███` no topo + corpo light | usuário precisa agir para continuar |
| INFO | light `╭──[ tema ]──` | resposta a pergunta, how-to, referência |

## Regra crítica de bordas

Linha com **código ou comando** = **SEM** `│` nas laterais (usuário copia com mouse).
Linha com **texto/prose** = **COM** `│` nas laterais.

```
  ██████████████████████████████████████████
  █  AÇÃO NECESSÁRIA                       █
  ██████████████████████████████████████████
  │                                        │
  │   Instalar o binário:                  │   ← texto: COM borda
  │                                        │
     cd ~/nixos/leech/rust                     ← código: SEM borda
     just install                              ← código: SEM borda
  │                                        │
  ╰────────────────────────────────────────╯
```

Diretriz também em `/home/claude/.claude/CLAUDE.md` (seção "Interface — Diálogos Mandatórios").
