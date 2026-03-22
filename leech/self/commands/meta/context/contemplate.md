---
name: meta:context:contemplate
description: Relatório contemplativo — extrapola o contexto atual, imagina o que pode ser construído e propõe uma visão de crescimento do sistema Leech.
---

# /meta:context:contemplate — Contemplar o Contexto

A partir do que está visível nesta sessão, extrapolar padrões, imaginar possibilidades e propor uma visão de crescimento. Não é análise técnica — é síntese estratégica.

```
/meta:context:contemplate            → relatório completo
/meta:context:contemplate gaps       → só gaps identificados
/meta:context:contemplate future     → só visão de futuro / roadmap
/meta:context:contemplate signals    → só sinais fracos e padrões emergentes
```

---

## Executar

### 1. Leitura do contexto como texto

Antes de qualquer análise, ler a sessão como se fosse uma narrativa:
- O que o usuário estava tentando fazer?
- Que obstáculos apareceram?
- Quais perguntas ficaram sem resposta?
- O que foi construído e por quê?
- Qual era o estado de ânimo / intenção subjacente?

Escrever um parágrafo de síntese narrativa antes das seções técnicas.

---

### 2. Sinais fracos e padrões emergentes

Padrões que apareceram 2+ vezes mas ainda não viraram regra/skill/memory:

```
  ── SINAIS FRACOS ────────────────────────────────────────────────

  · O usuário pediu análise de contexto em 3 momentos diferentes
    → Sinal: monitoramento de contexto é uma necessidade recorrente,
      não ocasional. Pode virar workflow automatizado (agente?).

  · Cada iteração do /meta:tokens adicionou uma camada nova
    → Sinal: o usuário pensa incrementalmente. Preferência por
      evoluir ferramentas existentes vs criar novas do zero.

  · X perguntas começaram com "dá pra..." ou "tem como..."
    → Sinal: exploração de capacidades. O usuário não sabe
      o que é possível — pode precisar de um catálogo de capacidades.
```

---

### 3. Gaps identificados

O que deveria existir mas não existe, inferido desta sessão:

```
  ── GAPS ─────────────────────────────────────────────────────────

  Skills / Commands
    · /meta:context:watch — monitoramento contínuo do contexto
      (ex: alerta quando passa de 60%, sugere /clear automaticamente)
    · /meta:context:snapshot — salva estado do contexto em obsidian
      para comparar entre sessões
    · /meta:context:diff — compara duas sessões (o que mudou no sistema)

  Agentes
    · "context-guardian" — agente passivo que monitora sessões longas
      e injeta lembretes de /clear quando detecta acúmulo

  Infraestrutura
    · Lazy-load de avatar no boot (sinal: 0 referências no heat map)
    · DIRETRIZES seccionadas por namespace
    · Memory auto-compaction quando MEMORY.md > 50 entradas
```

---

### 4. O que podemos extrapolar do contexto atual

Com base nos arquivos lidos, tool calls feitos e padrões observados, inferir o estado atual do sistema e o que ele revela:

```
  ── EXTRAPOLAÇÕES ────────────────────────────────────────────────

  Sobre o sistema Leech:
    · [inferência baseada nos arquivos lidos]
    · [padrão arquitetural que ficou visível]
    · [decisão de design que pode ser questionada]

  Sobre o usuário (Pedro):
    · [preferência revelada pelo comportamento nesta sessão]
    · [área de interesse/foco que emerge dos tópicos]
    · [modo de trabalho inferido]

  Sobre o estado da ferramenta:
    · [o que está maduro vs experimental]
    · [onde há dívida técnica visível]
    · [o que está sendo usado mais do que foi desenhado para]
```

---

### 5. Visão de futuro — o que podemos construir

Com o que temos hoje, o que é possível construir nas próximas iterações?

Organizar por horizonte:

```
  ── ROADMAP CONTEMPLATIVO ────────────────────────────────────────

  PRÓXIMA SESSÃO (baixo esforço, alto impacto)
    · [item 1] — por quê faz sentido agora, o que precisaria
    · [item 2]

  PRÓXIMAS SEMANAS (médio esforço, visão clara)
    · [item 1] — dependências, riscos, ganho esperado
    · [item 2]

  VISÃO LONGA (alto esforço, alto potencial)
    · [item 1] — o que este sistema pode se tornar se essa direção
      for seguida consistentemente
    · [item 2]
```

---

### 6. Contemplação livre

Uma seção sem formato fixo. Espaço para observações que não cabem em nenhuma categoria acima — conexões não-óbvias, perguntas abertas, intuições sobre o sistema.

Tom: contemplativo, não prescritivo. Mais "e se..." do que "deveria ser...".

Máximo 3 parágrafos. Qualidade > quantidade.

---

### 7. Resumo executivo

```
  ── RESUMO ───────────────────────────────────────────────────────

  Esta sessão em uma frase:
    [síntese do que aconteceu e seu significado]

  O sinal mais forte:
    [o padrão ou insight mais importante desta sessão]

  A próxima ação mais óbvia:
    [uma coisa concreta que poderia ser feita agora]

  Pergunta que ficou sem resposta:
    [algo que surgiu mas não foi resolvido — vale guardar]
```
