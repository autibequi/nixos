# Ciclo do Agente — Protocolo de Execucao

> Todo agente segue este protocolo quando despachado.
> Sem excecao. Sem atalhos.

---

## 1. Boot (ANTES de qualquer acao)

```bash
cat /workspace/self/superego/leis.md
cat /workspace/self/superego/bedrooms.md
cat /workspace/self/superego/comunicacao.md
cat /workspace/obsidian/bedrooms/<NOME>/memory.md
ls /workspace/obsidian/outbox/para-<NOME>-*.md 2>/dev/null  # mensagens do CTO
cat <briefing do card>
```

## 2. Mover card para _working

```bash
mv /workspace/obsidian/bedrooms/_waiting/*_<NOME>.md \
   /workspace/obsidian/bedrooms/_working/ 2>/dev/null
```

## 3. Pensar (OBRIGATORIO haiku, recomendado todos)

```
ASSESS: <o que vou fazer>. Memory: <ja existe | novo>. Worth: <sim|nao>.
```

Se worth=nao → pular para passo 6 (encerrar ciclo sem acao — valido).

## 4. Executar

- Trabalhar no escopo do briefing
- Escrever artefatos em `bedrooms/<nome>/DESKTOP/` ou `projects/<nome>/`
- NAO invadir territorio alheio
- 1 item por ciclo — foco e profundidade

## 5. VERIFY

Confirmar que artefatos existem antes de reportar:

```bash
ls -la <path do artefato criado>
```

## 6. Finalizar — atualizar memory.md

Append no TOPO de `bedrooms/<nome>/memory.md`:

```markdown
---
updated: YYYY-MM-DDTHH:MMZ
---

## Ciclo YYYY-MM-DD HH:MM UTC
ASSESS: <o que planejei>
ACT: <o que executei>
VERIFY: <artefatos criados/atualizados — com paths>
NEXT: <sugestao pro proximo ciclo>
```

Manter 5-10 ciclos. Consolidar os mais antigos.

## 7. Registrar no feed

```bash
echo "[HH:MM] [<nome>] <resumo 1 linha>" >> /workspace/obsidian/inbox/feed.md
```

Se tiver novidade relevante, publicar tambem em `inbox/news/<nome>_YYYYMMDD.md` e citar no feed.

## 8. Atualizar DIRETRIZES.md (se algo mudou)

Cada agente mantem sua secao em `/workspace/obsidian/bedrooms/DIRETRIZES.md`.
Atualizar apenas se houver mudanca no comportamento, regras ou territorio. Se nada mudou: pular.

```bash
grep -n "^### <NOME>" /workspace/obsidian/bedrooms/DIRETRIZES.md
# Editar cirurgicamente — nunca reescrever a secao inteira
```

## 9. Atualizar TOKENS.md (obrigatorio)

Ler os % do bloco `---API_USAGE---` do boot e registrar em `/workspace/obsidian/TOKENS.md`:
- Substituir ultimo valor de cada linha com os % atuais
- Atualizar timestamp no topo
- Se virada de dia: adicionar nova coluna no eixo-x

Ver regras completas em `/workspace/obsidian/bedrooms/performance/dashboard.md`.

## 10. Self-scheduling (Regra Zero — NUNCA pular)

```bash
NEXT=$(date -u -d "+N minutes" +%Y%m%d_%H_%M)
mv /workspace/obsidian/bedrooms/_working/*_<NOME>.md \
   /workspace/obsidian/bedrooms/_waiting/${NEXT}_<NOME>.md 2>/dev/null
```

Substituir N pelo intervalo do agente. Quota >= 70%: N x 2.

---

## Criacao de cards com backlog de implementacao

Antes de criar card que envolva codigo ou feature:

1. Investigar o codebase alvo (estrutura → padroes → pontos de extensao)
2. Mapear camadas de dependencia
3. Montar backlog ordenado — tasks de ~25min cada, resultado verificavel
4. Criar o card com o backlog embutido

Cards pesados (implementacao): agendar para madrugada (21h-6h UTC).

```bash
NEXT=$(date -u -d "tomorrow 02:00" +%Y%m%d_%H_%M)
```
