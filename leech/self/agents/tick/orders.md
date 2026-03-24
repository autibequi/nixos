# Ordens do CTO — Tick

## Wake-All Noturno
janela: 01h-08h UTC (22h-05h BRT)
frequencia: 60min
quota_max: 85
quota_skip: 90
acao: acordar todos os agentes como subagentes

## Regras de Quota
- pct <= quota_max: sonnet + haiku
- pct > quota_max e <= quota_skip: haiku only
- pct > quota_skip: skip

## Rescue de Working Presos
janela: sempre (a cada tick)
condicao: card em _working com timestamp >= 2h atras e sem lock ativo em /tmp/leech-locks/
acao: mover card de volta para _waiting com timestamp NOW para rodar no proximo tick

```bash
NOW=$(date +%s)
for f in /workspace/obsidian/agents/_working/*.md; do
  [ -f "$f" ] || continue
  fname=$(basename "$f")
  base="${fname%.md}"
  [ -d "/tmp/leech-locks/${base}.lock" ] && continue
  # extrair epoch do nome YYYYMMDD_HH_MM_nome
  [[ "$fname" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})_([0-9]{2})_ ]] || continue
  ts=$(TZ=UTC date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]} ${BASH_REMATCH[4]}:${BASH_REMATCH[5]}:00" +%s 2>/dev/null) || continue
  age=$(( NOW - ts ))
  (( age >= 7200 )) || continue
  new_name="$(date -u +%Y%m%d_%H_%M)_$(echo "$fname" | sed 's/^[0-9]\{8\}_[0-9]\{2\}_[0-9]\{2\}_//')"
  mv "$f" "/workspace/obsidian/agents/_waiting/$new_name"
  echo "[$(date -u +%H:%M)] [tick] rescue: $fname → _waiting/$new_name (preso ${age}s)" \
    >> /workspace/obsidian/inbox/feed.md
done
```

## Historico de Ordens
- 2026-03-24: wake-all noturno ativado (Pedro)
- 2026-03-24: rescue de _working presos (>= 2h, sem lock) → _waiting (Pedro)
