---
name: webview/mermaid/template/quadrant
description: Exemplo quadrantChart — matriz 2x2 (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — Quadrant chart (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Priorização** em duas dimensões: esforço/impacto, risco/valor, urgência/importância. |
| **Relay** | Ver `skills/webview/SKILL.md`. |

## Definição (resumo)

O **quadrantChart** define **eixos**, **quadrantes** nomeados e **pontos** com coordenadas. Documentação: [Quadrant Chart](https://mermaid.ai/open-source/syntax/quadrantChart.html).

## Diagrama de exemplo — Backlog técnico (ilustrativo)

```mermaid
%%{init: {'theme': 'dark'}}%%
quadrantChart
  title Priorização técnica (exemplo)
  x-axis Baixo esforço --> Alto esforço
  y-axis Baixo impacto --> Alto impacto
  quadrant-1 Quick wins
  quadrant-2 Projetos estratégicos
  quadrant-3 Preenchimento / baixa prioridade
  quadrant-4 Redução de dívida urgente
  Refator handler monolito: [0.35, 0.72]
  Melhoria UX bo-container: [0.55, 0.45]
  Cache BFF front-student: [0.42, 0.68]
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/quadrant.md
```

Ver `template/README.md`, `../styling-global.md`.
