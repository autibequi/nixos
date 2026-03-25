---
name: thinking/brainstorm
description: Geração e validação de teorias quando preso num problema. Gera 5-10 hipóteses sem filtro, valida cada uma lendo artefatos reais, entrega 1 vencedor com evidência. Acionado automaticamente pelo thinking ao detectar loop ou causa não clara.
---

# thinking/brainstorm — Geração e Validação de Teorias

> Quando todas as hipóteses óbvias falharam: gerar tudo, validar com evidência, emergir com certeza.
> Não é brainstorming de whiteboard — cada teoria é testada contra o código e os logs reais.

---

## Quando acionar

**Automático — thinking aciona sem esperar o user pedir:**
- Mesma hipótese revisitada 2x no pipeline (loop detectado)
- Causa não está clara após a fase de investigate + thinking
- Todas as hipóteses óbvias já foram refutadas

**Explícito:**
- User diz "estou preso", "não faz sentido", "já tentei tudo"

---

## Fluxo

### Fase 1 — Descrever o problema (sem julgamento)

Escrever 1 parágrafo descrevendo o que se sabe até agora:
- O que acontece
- O que deveria acontecer
- O que já foi descartado
- O que ainda não foi investigado

### Fase 2 — Gerar teorias (mínimo 5, ideal 8-10)

**Sem filtro nessa fase.** Incluir as óbvias, as improváveis e as absurdas.

Fontes de teorias a considerar:
- Lógica do código (condição faltando, tipo errado, nil não tratado)
- Estado/dados (valor inesperado no banco, cache stale, migração incompleta)
- Timing (race condition, timeout, ordem de inicialização)
- Infra/config (env var errada, variável de ambiente ausente, porta diferente)
- Deploy recente (commit que mudou comportamento, dependência atualizada)
- Integração externa (serviço externo retornando diferente, API mudou)
- Contexto do usuário (reproduz só em produção? só com dados específicos?)
- Efeito colateral (outra feature tocou o mesmo recurso)

### Fase 3 — Validar cada teoria com evidência real

Para cada teoria:

| # | Teoria | Artefato a verificar | Resultado |
|---|--------|----------------------|-----------|
| 1 | ... | arquivo:linha / log / config | CONFIRMADA / REFUTADA / INCONCLUSIVA |
| 2 | ... | ... | ... |

**Ação por resultado:**
- `CONFIRMADA` → parar de gerar novas teorias, subir como hipótese principal
- `REFUTADA` → riscar, continuar
- `INCONCLUSIVA` → marcar, continuar com as demais, voltar se necessário

### Fase 4 — Output

**Se 1 teoria confirmada:**
```
Hipótese: [descrição]
Evidência: [arquivo:linha ou trecho de log]
Confiança: Alta
Próximo passo: → code/debug para o fix
```

**Se múltiplas confirmadas:**
Listar com grau de confiança relativo. Deixar o user decidir qual atacar primeiro.

**Se nenhuma confirmada:**
Reportar as INCONCLUSIVAS com o que falta para confirmá-las. Pedir ao user mais dados específicos.

---

## Regras

1. **Quantidade antes de qualidade** na fase 2 — filtrar na fase 3, não antes
2. **Cada teoria exige verificação real** — não dizer "provavelmente é X" sem ler o artefato
3. **Parar ao confirmar** — não continuar gerando quando já tem um vencedor
4. **Registrar o descartado** — saber o que foi eliminado é tão valioso quanto saber o que sobrou
