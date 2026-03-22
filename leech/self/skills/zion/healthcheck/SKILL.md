---
name: zion/healthcheck
description: "Procedimentos de diagnostico do sistema — ferramentas, disco, load, workspace, git, tasks. Thresholds e regras de alerta. Usado pelo Keeper e qualquer agente que precise checar saude."
---

# Healthcheck — Diagnostico do Sistema

Procedimentos padronizados de health check. Fonte da verdade para thresholds e alertas.

## 1. Container e ferramentas

```bash
# Verificar ferramentas essenciais
for tool in awk sed make node go ffmpeg ps free; do
  command -v $tool >/dev/null 2>&1 && echo "OK: $tool" || echo "MISSING: $tool"
done

# Disco
df -h / | tail -1

# Load
uptime

# Nix daemon lock
ls -la /nix/var/nix/db/big-lock 2>/dev/null
```

## 2. Thresholds

| Metrica | Warning | Critico | Acao |
|---------|---------|---------|------|
| Disco | > 80% | > 95% | Alerta no inbox |
| Ferramentas ausentes | > 2 | — | Escalar |
| Load | > 4.0 | > 8.0 | Warning no feed |

## 3. Workspace e git

```bash
# Repos sujos
cd /workspace/mnt && git status --porcelain | head -5

# Tasks orfas em _running/
ls /workspace/obsidian/agents/_running/*.md 2>/dev/null
```

## 4. Tasks e agentes

- Cards em DOING/ sem lock ativo → orfaos, reportar
- Cards em _schedule/ com horario > 2h passado → stale, reportar
- agent.md sem contractor folder no Obsidian → inconsistencia

## 5. Cleanup — thresholds de limpeza

| Alvo | Threshold | Destino |
|------|-----------|---------|
| `/trash/*.md` sem refs, < 3d | arquivar | `.trashbin/` |
| `/trash/*.md` sem refs, >= 3d | deletar | permanente |
| `.ephemeral/scratch/` | > 7 dias | `.trashbin/` |
| `.ephemeral/logs/` | > 14 dias | `.trashbin/` |
| `.ephemeral/notes/` orfas | sem task ativa | `.trashbin/` |
| `agents/*/outputs/` | > 30 dias | `.trashbin/` |
| `.ephemeral/rss/` | > 500KB ou > 30 dias | `.trashbin/` |

## 6. Formato de reporte

```markdown
[HH:MM] [doctor] HEALTH: disco XX%, N ferramentas ok, N issues
```

Se critico → criar `/workspace/obsidian/inbox/ALERTA_doctor_<tema>.md`
