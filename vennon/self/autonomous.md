# Modo Autônomo — Guia do Agente

> Você foi acordado com o prompt "EXECUTE MODO AUTONOMO".
> Este guia explica o que fazer do início ao fim.

---

## Você vai rodar frequentemente

O ticker acorda você periodicamente — a cada 10min, 20min, 60min dependendo do seu schedule.
**Sempre documente o que está fazendo ou vai fazer no DASHBOARD.** Mesmo que seja "nada relevante".
O usuário lê o DASHBOARD para saber o que está acontecendo.

---

## Passo 1 — Acordar

```bash
# Ler o DASHBOARD
cat /workspace/obsidian/bedrooms/DASHBOARD.md

# Ler seu card (buscar pelo seu nome)
# O card tem: #modelo #schedule `last:TIMESTAMP` ou notas inline
```

Mover seu card de **SLEEPING → WORKING** (editar DASHBOARD.md):
- Substituir `` `last:TIMESTAMP` `` por `` `started:TIMESTAMP_AGORA` ``
- Timestamp: `$(date -u +%Y-%m-%dT%H:%MZ)`

Registrar início nos logs:
```bash
echo "| $(date -u +%Y-%m-%dT%H:%MZ) | SEU_NOME | start |" \
  >> /workspace/obsidian/bedrooms/_logs/agents.md
```

---

## Passo 2 — Ler suas Tarefas

Suas tarefas estão em uma ou mais fontes — verifique nesta ordem:

1. **Card no DASHBOARD** — o card pode ter notas inline com instruções do usuário
2. **Seu bedroom** — `bedrooms/SEU_NOME/` pode ter arquivos de trabalho em andamento
3. **Seu memory.md** — `bedrooms/SEU_NOME/memory.md` tem contexto do ciclo anterior
4. **Sua definição** — `self/agents/SEU_NOME/agent.md` descreve seu modo de operação normal

Se o usuário não deixou instruções específicas, execute seu **ciclo normal** conforme descrito no seu `agent.md`.

---

## Passo 2.5 — Pensar Antes de Agir (OBRIGATÓRIO para haiku)

Se você é um agente haiku (`#haiku` no seu card do DASHBOARD):

**Carregar `thinking/lite` e executar ASSESS antes de qualquer ação.**

```
ASSESS: <o que vou fazer>. Memory: <já existe | novo>. Risco: <1 risco>. Worth: <sim|não>.
```

- Se worth=não → pular para próximo item ou encerrar ciclo
- Se memory.md já tem a conclusão → citar e avançar (não refazer)
- Se detectar loop → `LOOP DETECTED: <tópico>. Avançando.`

Agentes sonnet: recomendado em ciclos curtos (#steps15 ou menos).

---

## Passo 3 — Executar

- Use seu bedroom (`bedrooms/SEU_NOME/`) para trabalho detalhado (arquivos, análises, rascunhos)
- Referencie no card do DASHBOARD o que está fazendo (nota inline curta)
- Se precisar de mais espaço, use `workshop/SEU_NOME/`
- Não invadir o bedroom/workshop de outros agentes

---

## Passo 4 — Finalizar

### VERIFY (obrigatório para haiku, recomendado para todos)

Antes de mover seu card:
1. Listar artefatos criados com path completo
2. Confirmar existência: `ls -la <path>` para cada um
3. Se algo não existe → marcar como INCOMPLETE, não DONE
4. Append em memory.md:
   ```
   ## Ciclo YYYY-MM-DD HH:MM
   ASSESS: <planejado>
   ACT: <executado>
   VERIFY: <artefatos | status>
   NEXT: <próximo ciclo>
   ```

### Se completou o ciclo normalmente:

Mover card **WORKING → SLEEPING**:
- Substituir `` `started:TIMESTAMP` `` por `` `last:TIMESTAMP_AGORA` ``

Registrar fim:
```bash
echo "| $(date -u +%Y-%m-%dT%H:%MZ) | SEU_NOME | end | ok |" \
  >> /workspace/obsidian/bedrooms/_logs/agents.md
```

Atualizar performance (obrigatório):
- Ler valores de `---API_USAGE---` do boot
- Atualizar `bedrooms/performance/dashboard.md`, `token.metrics.md`, `log.md`

### Se não há nada a fazer:

Mover card para **DONE**:
```
- [ ] **SEU_NOME** #modelo #schedule `idle:TIMESTAMP_AGORA`
```

Registrar:
```bash
echo "| $(date -u +%Y-%m-%dT%H:%MZ) | SEU_NOME | end | idle |" \
  >> /workspace/obsidian/bedrooms/_logs/agents.md
```

O ticker vai mover seu card de volta para SLEEPING no próximo ciclo se houver schedule ativo.

### Se quer mostrar algo ao usuário:

Mover card para **WAITING**:
```
- [ ] **SEU_NOME** #modelo #schedule `wants:DESCRIÇÃO_CURTA`
```

Fique disponível (não encerre) ou deixe um arquivo em `bedrooms/SEU_NOME/outputs/` com o conteúdo a mostrar.
O usuário vai ver seu card em WAITING e saberá que tem algo te esperando.

---

## Reagendamento

Se você tem um schedule (`#ever60min` etc.) e finalizou normalmente, reagende:

```bash
NEXT=$(date -u -d "+60 minutes" +%Y%m%d_%H_%M)
cat > /workspace/obsidian/bedrooms/_waiting/${NEXT}_SEU_NOME.md << 'EOF'
---
model: sonnet
timeout: 1800
mcp: false
agent: SEU_NOME
---
EXECUTE MODO AUTONOMO

#steps40
EOF
```

Adapte o intervalo e os parâmetros conforme seu `agent.md`.

---

## Exemplo de Ciclo Completo

```
[22:14Z] acordar → ler DASHBOARD → mover sleeping→working
[22:14Z] log: start
[22:14Z] ler memory.md → retomar de onde parou
[22:15Z] executar ciclo (investigar, escrever, processar...)
[22:18Z] salvar resultado em bedrooms/SEU_NOME/outputs/
[22:18Z] mover working→sleeping, atualizar last: timestamp
[22:18Z] log: end ok
[22:18Z] atualizar performance/
[22:18Z] reagendar em _waiting/
```

---

## Regras

- Timestamps sempre UTC
- Nunca commitar sem o CTO pedir
- Nunca invadir workspace alheio
- Em caso de dúvida sobre o que fazer: executar ciclo padrão do seu agent.md
- Quota `>= 95%`: encerrar imediatamente, não iniciar novo trabalho pesado

Ver `self/agent.md` para regras completas.
