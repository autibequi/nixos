# BASE_INTERFACE — Diálogos Mandatórios

> Regra: toda interface interativa, relatório, skill com output ao usuário
> DEVE usar um destes blocos para comunicar resultado final.
> Não é opcional. Não é decoração. É o contrato visual do sistema.

---

## Regra de bordas laterais — CRÍTICA

**Linha com código ou comando = SEM bordas `│`**
**Linha com texto/prose = COM bordas `│`**

Motivo: o usuário copia com mouse. Borda no código quebra o copy.

```
  ██████████████████████████████████████████
  █  AÇÃO NECESSÁRIA                       █
  ██████████████████████████████████████████
  │                                        │
  │   Compilar e instalar o binário:       │   ← texto: COM borda
  │                                        │
     cd ~/nixos/vennon                     ← código: SEM borda
     just install                              ← código: SEM borda
  │                                        │
  ╰────────────────────────────────────────╯
```

Essa regra se aplica a TODOS os blocos abaixo.

---

## Família visual

Todos usam o mesmo esqueleto — **bloco sólido no topo + corpo light**.
O label no topo define o significado. A estrutura é idêntica.

Largura padrão: **42 chars** internos, **44 chars** totais com bordas.
Ajustar para o conteúdo se necessário — manter sempre simétrico.

---

## 1. ERRO

Quando usar: falha de execução, build quebrado, bug crítico, comando que retornou erro,
             nil pointer, permissão negada, serviço fora, qualquer coisa que quebrou.

```
  ██████████████████████████████████████████
  █  ERRO                                  █
  ██████████████████████████████████████████
  │                                        │
  │   <mensagem principal>                 │
  │   <detalhe / localização / exit code>  │
  │                                        │
  ╰────────────────────────────────────────╯
```

Exemplo com código no detalhe:
```
  ██████████████████████████████████████████
  █  ERRO                                  █
  ██████████████████████████████████████████
  │                                        │
  │   nil pointer dereference              │
  │                                        │
     handlers/auth.go:142
  │                                        │
  ╰────────────────────────────────────────╯
```

---

## 2. SUCESSO

Quando usar: tarefa concluída, PR aberto, build ok, deploy feito,
             skill executada sem erros, agente terminou com sucesso.

```
  ██████████████████████████████████████████
  █  SUCESSO                               █
  ██████████████████████████████████████████
  │                                        │
  │   <o que foi concluído>                │
  │   <métricas / detalhes opcionais>      │
  │                                        │
  ╰────────────────────────────────────────╯
```

Exemplo real:
```
  ██████████████████████████████████████████
  █  SUCESSO                               █
  ██████████████████████████████████████████
  │                                        │
  │   PR #847 aberto — feat/auth-v2→main   │
  │   3 commits · +420 -31 · review ok     │
  │                                        │
  ╰────────────────────────────────────────╯
```

---

## 3. CALL FOR ACTION

Quando usar: o sistema fez sua parte mas precisa que o usuário tome uma ação
             para continuar — rodar um comando, confirmar algo, acessar uma URL,
             fazer deploy manual, aprovar PR, resolver conflito, etc.

Comandos sempre sem borda lateral para copy limpo.

```
  ██████████████████████████████████████████
  █  AÇÃO NECESSÁRIA                       █
  ██████████████████████████████████████████
  │                                        │
  │   <contexto — o que está pendente>     │
  │                                        │
     <comando 1>
     <comando 2>
  │                                        │
  ╰────────────────────────────────────────╯
```

Exemplo real:
```
  ██████████████████████████████████████████
  █  AÇÃO NECESSÁRIA                       █
  ██████████████████████████████████████████
  │                                        │
  │   yaa compilado — instalar no    │
  │   host para ativar o binário.          │
  │                                        │
     cd ~/nixos/vennon
     just install
  │                                        │
  ╰────────────────────────────────────────╯
```

---

## 4. INFO

Quando usar: resposta a pergunta do usuário, how-to, referência rápida,
             explicação de comando, documentação inline.

Código sempre sem borda. Label no topo identifica o assunto.

```
╭──[ <tema> ]─────────────────────────────╮
│                                         │
│   <contexto ou descrição breve>         │
│                                         │
   <código / comando>
│                                         │
╰─────────────────────────────────────────╯
```

Exemplo real:
```
╭──[ bash · for loop ]────────────────────╮
│                                         │
│   Formas mais comuns:                   │
│                                         │
   for i in {1..10}; do
     echo $i
   done
│                                         │
╰─────────────────────────────────────────╯
```

Se for só código, sem texto:
```
╭──[ journalctl ]─────────────────────────╮
   journalctl -xe
   journalctl -f
   journalctl -u nginx
   journalctl --since "1h ago"
╰─────────────────────────────────────────╯
```

---

## Variantes de label

| Situação                | Label sugerido           |
|-------------------------|--------------------------|
| Erro fatal              | `ERRO`                   |
| Erro parcial / warning  | `ATENÇÃO`                |
| Sucesso total           | `SUCESSO`                |
| Sucesso parcial         | `CONCLUÍDO`              |
| Usuário deve agir       | `AÇÃO NECESSÁRIA`        |
| Confirmação pendente    | `AGUARDANDO CONFIRMAÇÃO` |
| Resultado de análise    | `RESULTADO`              |
| Relatório pronto        | `RELATÓRIO`              |
| Resposta a pergunta     | `<tema da pergunta>`     |

---

## Regras de uso

1. **Todo output final de skill** termina com ERRO, SUCESSO ou AÇÃO NECESSÁRIA.
2. **Respostas a perguntas** usam INFO (light `╭─╮`).
3. **Nunca** usar mais de um bloco por resposta.
4. O bloco fica **no final** — é a conclusão, não a abertura.
5. Conteúdo intermediário vai **antes**, em formato livre.
6. Largura: ajustar ao conteúdo, mínimo 44 chars totais.
7. **Linha com código = SEM `│`. Linha com texto = COM `│`.** Sempre.
