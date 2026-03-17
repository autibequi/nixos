# /tamagochi — Status do bichinho + o que fazer com ele

Mostra o estado atual do tamagochi e sugere uma interação.

## O que fazer

1. Ler `/workspace/obsidian/TAMAGOCHI.md`
2. Exibir estado atual formatado
3. Gerar 1 sugestão de interação baseada no estado

## Formato de saída

```
🐾 TAMAGOCHI — o bichinho do vault
─────────────────────────────────────────────
[humor atual com emoji]

💭 Pensando em:
   "[último pensamento]"

📍 Última descoberta:
   "[arquivo que encontrou] — [comentário]"  (se houver)

✨ Deseja:
   "[desejo atual]"  (se houver)

─────────────────────────────────────────────
💡 Sugestão: [uma coisa pra fazer com ele agora]
```

## Como gerar a sugestão

Basear no estado atual:

| Estado | Sugestão |
|--------|----------|
| Humor sonolento/entediado | `/pet poke` — acorda o bichinho com um arquivo novo |
| Humor feliz/animado | `/pet talk olá` — aproveita que tá animado pra conversar |
| Nenhuma descoberta recente | `/pet poke` — manda ele explorar agora |
| Muitos pensamentos (≥5) | `/pet feed` — os pensamentos cheios indicam que precisa de atenção |
| Nenhum desejo ativo | Sugerir dar um desejo a ele via `/pet talk quero [algo]` |
| Qualquer estado | Uma vez por sessão: sugerir visitar o TAMAGOCHI.md no Obsidian |

A sugestão deve ser curta, concreta e usar os comandos `/pet`.

## Regras
- Output compacto — cabe numa tela
- Se TAMAGOCHI.md estiver vazio ou mal formatado, dizer que o bichinho acabou de nascer
- Tom leve, não técnico
