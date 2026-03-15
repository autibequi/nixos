# Guidelines de Tamanho

> Limits para evitar context rot

## Arquivos de Projeto

| Arquivo | Max Lines | Max Tokens |
|---------|-----------|------------|
| PROJECT.md | 100 | ~3k |
| REQUIREMENTS.md | 200 | ~6k |
| ROADMAP.md | 100 | ~3k |
| STATE.md | 150 | ~5k |
| CONTEXT.md | 100 | ~3k |
| RESEARCH.md | 150 | ~5k |
| PLAN.md | 80 | ~2k |
| SUMMARY.md | 60 | ~1.5k |

## Princípios

1. **Se exceder → dividir** — criar arquivos separados por fase/topic
2. **GSD principle** — "200k tokens purely for implementation, zero accumulated garbage"
3. **Chunking** — cada task deve caber em ~2-3k tokens de instructions

## Contexto por Task

- Max history: ~50 mensagens
- Max tool results: ~100KB
- Se exceder → iniciar fresh agent
