---
name: meta:executor
description: "Executor paralelo — como despachar multiplos agentes como subagentes em paralelo, coordenar outputs e agregar resultados."
---

# Executor Paralelo

Skill para despachar multiplos agentes simultaneamente via Agent tool.
Use quando o trabalho pode ser dividido em fatias independentes.

---

## Quando Usar Paralelo vs Sequencial

**Paralelo:** quando as tarefas sao independentes entre si.

| Cenario | Agentes em paralelo |
|---------|---------------------|
| Investigacao multi-repo | wanderer (repos) + coruja (jira) + paperboy (feeds) |
| Limpeza do sistema | keeper (disco/vault) + wiseman (enforce) |
| Analise noturna ampla | wanderer + coruja + assistant |
| Digest matinal | paperboy + assistant + hermes |

**Sequencial:** quando B precisa do output de A.

```
# Errado: em paralelo
coruja analisa jira → wanderer implementa baseado no jira

# Certo: sequencial
1. coruja analisa jira
2. (recebe resultado)
3. wanderer implementa baseado no resultado
```

---

## Checklist Antes de Despachar

```bash
# 1. Verificar quota — nao disparar se >= 85%
cat ~/.leech | grep pct

# 2. Confirmar quais agentes sao relevantes para a tarefa
# 3. Preparar prompt compacto por agente (ver abaixo)
# 4. Lancar em paralelo no mesmo turno
```

---

## Como Montar o Prompt de Cada Subagente

Cada subagente recebe contexto autonomo — ele NAO herda o contexto do despachante.

**Template de prompt por subagente:**
```
Voce e o <nome>. Contexto: <2-3 linhas do estado atual relevante>.
Tarefa: <acao especifica e delimitada>.
Output esperado: <o que retornar ao final — formato, destino>.
Regras: ler RULES.md + bedrooms.md no boot. Reagendar ao fim.
```

**Exemplo — analise noturna:**
```
Wanderer: Explore o monolito buscando hotspots (arquivos +git log -n 200).
          Retorne: top 5 arquivos mais modificados + 1 insight nao-obvio.
          Salve em bedrooms/wanderer/DESKTOP/hotspots-noturno.md

Coruja:   Escaneia o board Jira (FUK2) buscando cards urgentes ou blockers.
          Retorne: lista de cards criticos + qualquer alerta para o CTO.
          Salve em bedrooms/coruja/DESKTOP/jira-scan-noturno.md

Paperboy: Processe os feeds configurados e monte digest das ultimas 24h.
          Retorne: top 5 noticias + 1 item de destaque.
          Salve em bedrooms/paperboy/DESKTOP/digest-noturno.md
```

---

## Limite Pratico

- **Maximo: 5 agentes em paralelo** por dispatch (quota + contexto)
- Preferir 2-3 agentes para tarefas focadas
- Nao despachar o mesmo agente duas vezes em paralelo

---

## Agregacao de Resultados

Apos os subagentes retornarem:

**1. Feed.md — 1 linha por subagente:**
```bash
echo "[$(date -u +%H:%M)] [executor] wanderer: N hotspots | coruja: N cards | paperboy: digest pronto" \
  >> /workspace/obsidian/inbox/feed.md
```

**2. CARTA consolidada** — apenas se houver achados relevantes:
```bash
# Criar CARTA_executor_YYYYMMDD_HH_MM.md no inbox com resumo cross-agente
```

**3. Nao duplicar** — se um subagente ja escreveu no feed.md, nao repetir.

---

## Exemplo Completo — Gandalf Despachando Analise Noturna

```
Contexto: 03h UTC, sem diretriz do CTO, 3 ciclos seguidos em INTROSPECT.
Decisao: FREE_ROAM → despachar analise multi-repo.

Agentes: wanderer + coruja (2 em paralelo, haiku economiza quota)
Prompt wanderer: [contexto minimo] buscar hotspots no monolito
Prompt coruja:   [contexto minimo] escanear board Jira por urgencias

Apos retorno:
- 1 linha no feed.md com resumo
- Se coruja encontrou algo urgente: criar ALERTA_ no inbox
- Registrar em DIARIO/2026/03.md o que foi feito
```

---

> Paralelismo e multiplicador de foco, nao substituto de clareza.
> Cada agente precisa de um objetivo claro — nao apenas "olhe ao redor".
