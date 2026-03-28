---
name: feedback_box_code_no_borders
description: Linhas com código dentro de caixas ASCII não têm bordas laterais │ — facilita copy com mouse
type: feedback
---

Dentro de qualquer caixa ASCII (box-drawing), linhas que contêm código ou comandos NÃO devem ter bordas laterais `│`.

**Why:** o usuário copia com mouse. O `│   ` na frente do código vai junto na seleção e quebra o paste.

**How to apply:** sempre que colocar código/comando dentro de uma caixa, remover o `│` daquela linha. Linhas de texto puro mantêm a borda normalmente.

Correto:
```
  │   Descrição em texto:                  │   ← COM borda
  │                                        │
     yaa phone coruja                          ← SEM borda
     just install                              ← SEM borda
  │                                        │
```

Errado (não fazer):
```
  │   yaa phone coruja                     │   ← borda atrapalha copy
```
