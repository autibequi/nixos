# /meta:imhi — Oi, o que tá rolando?

Usado quando o usuário está cansado, chapado, exausto, ou os 4 ao mesmo tempo e precisa entender o que diabos aconteceu na conversa atual.

## Instruções

Leia TODO o contexto da sessão atual e explique **cronologicamente** o que foi feito, como se estivesse explicando pra uma criança de 7 anos.

### Regras de linguagem

- Frases **curtas**. Sem jargão técnico. Se precisar usar um termo técnico, explica na mesma frase.
- Use analogias simples: "é como uma caixinha que guarda coisas", "é como um botão que liga a luz"
- Tom carinhoso, sem pressa
- **Numerado e cronológico** — "primeiro fizemos X, depois Y, aí rolou Z"

### Formato obrigatório

Deve ter TUDO isso:

**1. Cabeçalho com hora e humor**
```
╭─────────────────────────────────────────╮
│  🧸  oi! eu te conto o que rolou hoje   │
│  🕐  [hora atual]   📍 sessão ativa     │
╰─────────────────────────────────────────╯
```

**2. Linha do tempo visual (ASCII)**

Para cada coisa importante que aconteceu, uma linha:
```
  [HH:MM?]  ──●── descrição simples
              │
  [HH:MM?]  ──●── outra coisa
              │
     agora  ──★── onde a gente tá
```
(se não souber o horário exato, omite o horário, mantém os bullets)

**3. O que foi feito — em linguagem de criança, com ícones**

Para cada item, escolha um ícone que faça sentido visualmente:
- 🗑️ removemos algo
- ✨ criamos algo novo
- 🔧 consertamos algo
- 🏷️ renomeamos algo
- 🤖 mexemos num robozinho
- 🎨 mudamos como algo aparece

**4. Tabela de resultados**

```
┌──────────────────────────┬──────────┬────────────────────────┐
│ O que                    │ Status   │ Em palavras simples     │
├──────────────────────────┼──────────┼────────────────────────┤
│ nome da coisa            │  ✅ feito │ o que isso faz         │
│ outra coisa              │  ✅ feito │ ...                    │
│ ...                      │  🔜 fila  │ ...                    │
└──────────────────────────┴──────────┴────────────────────────┘
```

**5. Barra de progresso da sessão**

Inventar uma estimativa honesta de quanto da sessão foi produtiva:
```
Progresso  ████████████████████░░░░  85%  quase tudo feito!
Commits    ██████░░░░░░░░░░░░░░░░░░  3 commits
```

**6. Rodapé**
```
📍 parei em → [onde parou em uma frase]
🔜 próximo  → [o que vem se tiver algo]
💤 pode dormir? → [sim/não e por quê em 1 frase]
```

### Tom de exemplo

> "A gente tem um robozinho chamado Wanderer que fica lendo o código sozinho enquanto você dorme. A gente ensinou ele a fazer 5 coisas diferentes dependendo do humor dele."

Não precisa cobrir TUDO, só o que importa. Se a sessão foi longa, agrupa por tema.
