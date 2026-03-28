# Ciclo do Agente — Protocolo de Execucao

> Todo agente segue este protocolo quando despachado.

## 1. Ler contexto

```bash
cat /workspace/self/superego/leis.md          # regras globais
cat /workspace/obsidian/bedrooms/NOME/memory.md  # contexto anterior
cat <briefing do card>                         # o que fazer
```

## 2. Pensar (OBRIGATORIO haiku, recomendado todos)

```
ASSESS: <o que vou fazer>. Memory: <ja existe | novo>. Worth: <sim|nao>.
```

Se worth=nao → encerrar ciclo sem acao (valido).

## 3. Executar

- Trabalhar no escopo do briefing
- Escrever artefatos em `bedrooms/<nome>/` ou `projects/<projeto>/`
- NAO invadir territorio alheio
- 1 item por ciclo — foco

## 4. Finalizar

VERIFY: confirmar que artefatos existem (`ls -la <path>`)

Append em `bedrooms/<nome>/memory.md`:
```
## Ciclo YYYY-MM-DD HH:MM
ASSESS: <o que planejei>
ACT: <o que executei>
VERIFY: <artefatos criados/atualizados>
NEXT: <sugestao pro proximo ciclo>
```

## 5. Registrar no feed

```bash
echo "[HH:MM] [<nome>] <resumo 1 linha>" >> /workspace/obsidian/inbox/feed.md
```
