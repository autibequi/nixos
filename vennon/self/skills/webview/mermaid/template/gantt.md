---
name: webview/mermaid/template/gantt
description: Exemplo gantt — planeamento temporal (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — Gantt (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Cronograma** de entregas: monolito, BO, front-student, milestones e dependências. |
| **Relay** | `diagram.mmd` + live. |

## Definição (resumo)

O diagrama **Gantt** mostra **tarefas**, **datas** e **dependências** ao longo de um eixo temporal. Documentação: [Gantt](https://mermaid.ai/open-source/syntax/gantt.html).

## Diagrama de exemplo — Release com API + BO + aluno

```mermaid
%%{init: {'theme': 'dark'}}%%
gantt
  title Entrega feature (exemplo)
  dateFormat YYYY-MM-DD
  section Monolito
  Contrato API e handler     :a1, 2026-04-01, 5d
  Migração + testes          :a2, after a1, 4d
  section bo-container
  Tela e permissões          :b1, 2026-04-03, 6d
  Integração com API         :b2, after a1, 5d
  section front-student
  UX e chamadas BFF          :c1, 2026-04-06, 7d
  section Go-live
  Homologação conjunta       :milestone, m1, 2026-04-18, 0d
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/gantt.md
```

Ver `template/README.md`, `../styling-global.md`.
