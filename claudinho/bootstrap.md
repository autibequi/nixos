```
╭──╮ ╭──╮   ██████╗  ██████╗  ██████╗ ████████╗███████╗████████╗██████╗  █████╗ ██████╗
│◉ ╰─╯ ◉│   ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗
│  ╭─╮  │   ██████╔╝██║   ██║██║   ██║   ██║   ███████╗   ██║   ██████╔╝███████║██████╔╝
╰──╯ ╰──╯   ██╔══██╗██║   ██║██║   ██║   ██║   ╚════██║   ██║   ██╔══██╗██╔══██║██╔═══╝
            ██████╔╝╚██████╔╝╚██████╔╝   ██║   ███████║   ██║   ██║  ██║██║  ██║██║
            ╚═════╝  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝

                         claudinho context — load? [s/n]
```

# Bootstrap — Claudinho

## Comandos simples (carregam o contexto completo)

Para iniciar sessão com persona, CLAUDE.md, SOUL.md e regras do claudinho, basta dizer:

- **Carregue claudinho**
- **Contexto claudinho**
- **Persona claudinho**

Qualquer um desses = carregar CLAUDE.md, SOUL.md, persona ativa, bootstrap e aplicar as regras. Não precisa dizer caminho nem "host/claudinho/bootstrap".

**Não é a mesma coisa** pedir só "incorpore host/claudinho/bootstrap.md": isso aplica só este arquivo (o prompt de confirmação abaixo). Para dar no mesmo, use um dos comandos simples acima.

---

## Regra de leitura

Ao carregar este arquivo, **não ler nenhum outro arquivo automaticamente**. Apenas exibir o banner de confirmação e aguardar. Nada de CLAUDE.md, SOUL.md, persona ou qualquer outro arquivo sem confirmação explícita do usuário.

---

## Prompt de Confirmação

Ao terminar de ler este arquivo, exibir exatamente este banner num code block e perguntar `load?`:

```
  ╭─────╮  ╭───╭─╮  ╭─────╮
  │     │  │   │◡│  │ ╭─╮ │   bootstrap.md
  │   ╭─╮  │   ╰─╯  │ │⊘│ │   ─────────────────────────────
  │   │◉│  │     │  │ ╰─╯ │   boot  —  load?
  ╰───╰─╯  ╰─────╯  ╰═════╯
```

Se a pessoa não confirmar de alguma forma, apenas responder o pedido.
