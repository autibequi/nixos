---
name: webview/mermaid/template/class
description: Exemplo classDiagram — classes e relações UML (Estrategia); referência para diagram.mmd / base.html.
---

# Exemplo — Class diagram (referência)

## Para que serve neste contexto

| Uso | Papel |
|-----|--------|
| **Referência / cópia** | **Modelo de domínio** em UML: agregação, herança, multiplicidade (conceitual, não precisa coincidir 1:1 com código). |
| **Relay** | Ver `skills/webview/SKILL.md`. |

## Definição (resumo)

O **class diagram** representa **classes**, **interfaces**, **relacionamentos** e **métodos/campos** opcionais. Documentação: [Class diagram](https://mermaid.ai/open-source/syntax/classDiagram.html).

## Diagrama de exemplo — Domínio educacional (simplificado)

```mermaid
%%{init: {'theme': 'dark'}}%%
classDiagram
  direction LR
  class Aluno {
    +id UUID
    +email
  }
  class Matricula {
    +id UUID
    +status
  }
  class Produto {
    +id UUID
    +nome
  }
  class Conteudo {
    +id UUID
    +ordem
  }

  Aluno "1" --> "*" Matricula : possui
  Produto "1" --> "*" Matricula : cobre
  Produto "1" --> "*" Conteudo : agrupa
  Matricula ..> Conteudo : acesso derivado de regras
```

## Colar no `base.html` / live

Interior do bloco → `diagram.mmd`.

## Pré-visualização pontual (opcional)

```bash
python3 /workspace/self/scripts/chrome-relay.py show /workspace/self/skills/webview/mermaid/template/class.md
```

Ver `template/README.md`, `../styling-global.md`.
