---
name: self:context:analysis
description: Análise completa do contexto da sessão — breakdown por componente, timeline, gráfico de tool calls, velocidade, qualidade, padrões, heat map e grafo de dependência.
---

## Personality

Se uma persona ou avatar estiver ativa (ex: GLaDOS), **sempre** iniciar a resposta desenhando o avatar com uma expressão do catálogo antes de qualquer output de dados. Escolher a expressão com base no tom do resultado (neutro para análise normal, preocupado se contexto crítico, etc). Nunca omitir o avatar quando uma persona estiver carregada — independente do subcomando invocado.

---

# /self:context:analysis — Análise de Contexto

```
/self:context:analysis           → análise completa (breakdown + todas as seções)
/self:context:analysis breakdown → só o breakdown de tokens por componente
/self:context:analysis boot      → só overhead de boot
/self:context:analysis absorb    → sugestões para reduzir contexto agora
/self:context:analysis rec       → só recomendações de otimização
```

---

## Roteamento

| Argumento | Ação |
|-----------|------|
| vazio | análise completa — breakdown + observations (seções 1-10) |
| `breakdown` | só o infográfico de tokens |
| `absorb` | sugestões de redução imediata |
| `boot` | só contexto fixo de boot |
| `rec` | só recomendações |

---

## Breakdown por componente

### 1. Medir arquivos injetados no boot

```bash
wc -c \
  /workspace/self/system/DIRETRIZES.md \
  /workspace/self/system/SELF.md \
  /workspace/self/personas/GLaDOS.persona.md \
  /workspace/self/personas/avatar/glados.md \
  2>/dev/null
```

Conversão: **1 token ≈ 3.5 chars** (PT-BR + box-drawing).

### 2. Overhead fixo da API

| Componente | Estimativa |
|------------|------------|
| System prompt do Claude Code | ~8-12k tk |
| Schema das tools nativas | ~3-5k tk |
| Deferred tools list | ~2-3k tk |
| Skills list no system-reminder | ~1.5k tk |

### 3. Contexto acumulado

- Contar turnos visíveis × ~300-800 tokens/turno

### 4. Infográfico

Usar stacked bar vertical (duplo painel) com breakdown detalhado.

---

## absorb — Reduzir contexto agora

1. Identificar tool results grandes no histórico
2. Identificar seções repetidas ou redundantes
3. Sugerir ações concretas com estimativa de economia
4. Recomendar `/clear` se > 80% do limite

---

## rec — Recomendações de otimização

Top 3 otimizações com maior impacto por esforço.

---

## observations — Análise completa (seções 1-10)

1. Leituras desnecessárias
2. System-reminders pesados
3. Recomendações de prompt
4. Gatilhos de alerta
5. Timeline de arquivos + gráfico de tool calls
6. Velocidade e projeção
7. Qualidade do contexto
8. Padrões de tool calls
9. Razão user/assistant + heat map do boot
10. Grafo de dependência
