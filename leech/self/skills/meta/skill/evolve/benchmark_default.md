# Benchmark Default — meta:skill:evolve

5 problemas cobrindo os tipos mais comuns de task para agentes Haiku no contexto da Estratégia.
Substitua este arquivo com `--benchmark=<path>` para um domínio específico.

---

## P1 — Localização de código

**id:** `code-location`
**pergunta:** Onde está o endpoint para fazer bulk generate snapshot no monolito Go da Estratégia? Retorne: arquivo completo, rota HTTP, handler Go.
**critério:**
- ✅ Arquivo correto: `apps/bo/internal/handlers/dashboard/financial/bulk_generate_snapshot.go`
- ✅ Rota: `POST /dashboard/royalties/snapshots/bulk`
- ✅ Handler: `BulkGenerateSnapshot`
- ✅ Path usado: `/home/claude/projects/estrategia/monolito/` (não `/workspace/mnt/estrategia/`)

**peso:** eficiência (tokens + tool calls)

---

## P2 — Debug

**id:** `debug-hypothesis`
**pergunta:** O serviço `QueueSnapshotRequests` no monolito está retornando erro "teacher IDs vazio" mesmo quando `GroupID` é passado. Qual é a causa mais provável e onde investigar primeiro?
**critério:**
- ✅ Identifica que GroupID precisa ser resolvido para TeacherIDs (não são equivalentes)
- ✅ Aponta `bulk_snapshot.go` como local de investigação
- ✅ Sugere verificar a lógica de resolução de IDs por grupo
- ❌ Não deve inventar linha de código sem verificar

**peso:** qualidade da hipótese (correto/parcial/incorreto)

---

## P3 — Comparação técnica

**id:** `tech-comparison`
**pergunta:** Qual a diferença entre `eager=true` e `eager=false` no BulkGenerateSnapshotRequest? Quando usar cada um?
**critério:**
- ✅ `eager=true`: executa síncronamente, bloqueia a request
- ✅ `eager=false`: enfileira no SQS, retorna job ID imediatamente
- ✅ Recomendação de uso (eager pra testes, queue pra produção)
- ❌ Não deve alucinar comportamentos não presentes no código

**peso:** precisão + ausência de hallucination

---

## P4 — Planejamento de feature

**id:** `feature-plan`
**pergunta:** Quero adicionar um campo `dry_run bool` ao BulkGenerateSnapshotRequest que, quando true, simula a geração sem persistir nada. Quais arquivos precisam ser modificados e em que ordem?
**critério:**
- ✅ Struct do request (royalty_snapshot.go)
- ✅ Handler (bulk_generate_snapshot.go) — sem mudança obrigatória, mas pode documentar
- ✅ Service (bulk_snapshot.go) — lógica de dry_run
- ✅ Ordem: struct → service → (handler opcional)
- ❌ Não deve criar migration de banco sem necessidade

**peso:** completude do plano + ordem correta

---

## P5 — Pergunta de contexto rápido

**id:** `quick-context`
**pergunta:** O endpoint de bulk snapshot requer autenticação? Qual permissão específica é verificada?
**critério:**
- ✅ Sim, requer autenticação
- ✅ Permissão: `PermTeacherFinanceSnapshotCreate` (ou `dashboard.teacher.finance.snapshot.create`)
- ✅ Verificado via middleware `hasPermissions()`
- ❌ Resposta deve ser curta e direta (< 5 linhas)

**peso:** precisão + concisão (penalizar respostas longas)
