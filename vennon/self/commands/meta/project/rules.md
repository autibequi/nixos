---
name: briefing-rules
description: Regras obrigatorias para todo BRIEFING.md — formato, conteudo minimo, convencoes
---

# Regras do BRIEFING.md

> Todo projeto em `projects/` e toda ronda em `bedrooms/` DEVE ter um BRIEFING.md.
> Este arquivo e o contrato entre o DASHBOARD e o agente executor.

---

## Formato obrigatorio

```markdown
# <Nome> — Briefing do Projeto

> <Objetivo em 1-2 linhas>
> Este arquivo e lido pelo agente executor antes de cada ciclo.

## Contexto
<por que este projeto existe, pra quem, qual problema resolve>

## O que fazer a cada ciclo
1. <Passo concreto — verbo no infinitivo>
2. ...

## Prioridade
1. <Mais importante>
2. <Medio>
3. <Menos importante>

## Regras
- <Regra especifica>

## Estado Atual
<Atualizado pelo agente apos cada ciclo>
```

---

## Regras

### 1. Autonomo
O briefing deve ser suficiente pra um agente SEM CONTEXTO entender o que fazer.
Nao assumir que o agente sabe algo — ele acorda do zero a cada ciclo.
A unica memoria e `bedrooms/<agente>/memory.md`.

### 2. Concreto
- "Ler INDEX.md e executar proximo item" ✓
- "Trabalhar no projeto" ✗ (vago demais)
- Cada passo do ciclo deve ser uma acao com verbo

### 3. Priorizado
Sempre ter secao Prioridade com pelo menos 2 niveis.
Agente executa 1 item por ciclo — precisa saber qual e mais importante.

### 4. Localizado
- Paths absolutos ou relativos a `projects/<nome>/`
- Nunca referenciar arquivos fora do projeto sem path completo
- Se o agente precisa de skill: mencionar qual (ex: "usar skill coruja/monolito/go-handler")

### 5. Atualizavel
- Secao "Estado Atual" deve ser atualizada pelo agente ao fim de cada ciclo
- Nao e o briefing que muda — e o estado dentro dele
- Se o projeto muda de direcao: user edita o briefing manualmente

### 6. Sem codigo no briefing
- Briefing e instrucao, nao implementacao
- Codigo, templates, schemas vao em arquivos separados dentro de `projects/<nome>/`
- Briefing referencia eles: "ver `schema.sql` para estrutura do banco"

### 7. Tamanho
- Minimo: 10 linhas (objetivo + ciclo + 1 regra)
- Maximo: ~100 linhas (se passar disso, quebrar em sub-arquivos)
- Ideal: 30-50 linhas

---

## Briefings de ronda (bedrooms/)

Rondas sao mais simples que projetos — o agente ja sabe quem e (tem agent.md).
Briefing de ronda precisa apenas:

```markdown
# <Agente> — Ronda

> <O que faz em 1 linha>

## Ciclo
1. <Passo>
2. <Passo>

## Territorios
- Escrita: bedrooms/<nome>/, <outros paths permitidos>
```

---

## Checklist de validacao

Antes de criar o card no DASHBOARD, verificar:

- [ ] BRIEFING.md existe em `projects/<nome>/` ou `bedrooms/<agente>/`
- [ ] Tem secao "O que fazer a cada ciclo" com passos concretos
- [ ] Tem secao "Prioridade"
- [ ] Paths estao corretos e arquivos referenciados existem
- [ ] Card no DASHBOARD aponta pro briefing certo (`briefing:projects/<nome>/BRIEFING.md`)
- [ ] Agente especificado no card existe em `self/ego/`
