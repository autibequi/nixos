---
name: webview/mermaid/template/pie
description: Exemplo pie — proporções (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — Pie chart (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Partes de um todo** percentuais: tráfego por app, erros por área, mix de chamadas API. |
| **Relay** | Ver `skills/webview/SKILL.md`. |

## Definição (resumo)

O diagrama **pie** exibe **fatias** com rótulos e valores. Documentação: [Pie chart](https://mermaid.ai/open-source/syntax/pie.html).

## Diagrama de exemplo — Tráfego de entrada (ilustrativo)

```mermaid
%%{init: {'theme': 'dark'}}%%
pie showData
  title Distribuição de requests (exemplo)
  "front-student (BFF)" : 52
  "bo-container (BO API)" : 28
  "Workers / interno" : 12
  "Outros" : 8
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/pie.md
```

Ver `template/README.md`, `../styling-global.md`.
