# Shadow — Inconsciente do Sistema

> O que influencia sem ser invocado diretamente.

## Estrutura (obrigatoria)

```
shadow/
├── memory/       ← memorias persistentes (feedback_*, project_*, reference_*, user_*)
├── modes/        ← modos ocultos de comportamento (analysis, beta)
├── experiments/  ← coisas em teste (personas, prototipos)
└── limbo/        ← lixeira (legacy, deprecated, lixo)
```

## Regras

1. **memory/** — UNICO lugar pra memorias. Nunca criar memorias fora daqui.
2. **modes/** — modos carregados condicionalmente pelo boot (ANALYSIS_MODE, BETA).
3. **experiments/** — prototipos e testes. Nao afeta producao.
4. **limbo/** — lixeira de coisas deprecated. Nada no limbo e referenciado por codigo ativo. Pode ser deletado a qualquer momento sem quebrar nada.
5. **Nao criar pastas novas** fora dessas 4 sem justificativa.
6. **Nao deixar arquivos soltos** na raiz do shadow/ — tudo vai numa das 4 pastas.
