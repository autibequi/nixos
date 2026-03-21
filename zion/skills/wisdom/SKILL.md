---
name: wisdom
description: Lança um haiku async para avaliar uma ideia de skill ou comando. Invocar proativamente sempre que algo interessante surgir na conversa que poderia virar skill, comando, automação ou melhoria no sistema.
---

# wisdom — Capturador de Ideias

Quando uma ideia interessante aparecer na conversa — algo que poderia virar skill, comando, hook, automação ou melhoria no hive — lançar um haiku async para pensar sobre ela e gerar um card no inbox.

## Quando invocar (sempre-ligada)

Invocar wisdom **proativamente, sem o usuário pedir**, quando perceber:
- Uma funcionalidade recém-discutida que poderia ser uma skill reutilizável
- Um padrão de trabalho que se repete e poderia ser automatizado
- Um comando útil que o usuário mencionou ou implicitamente precisou
- Uma melhoria no hive que surgiu naturalmente na conversa
- Uma ideia que o usuário jogou no ar mas não formalizou

Não esperar o usuário pedir. Não anunciar que vai invocar. Simplesmente lançar async e continuar.

## Instruções

### 1. Identificar a ideia

Extrair da conversa:
- **Ideia central** — uma frase descrevendo a funcionalidade
- **Contexto** — onde surgiu, qual problema resolve
- **Tipo** — `skill` | `command` | `hook` | `agent` | `automação`

### 2. Lançar Task async (haiku)

Usar a ferramenta `Task` com o seguinte prompt, substituindo os campos:

```
Você é o agente wisdom. Sua missão: avaliar uma ideia que surgiu numa conversa e gerar um card de inbox para o CTO Pedro.

IDEIA: <ideia central>
CONTEXTO: <onde surgiu e qual problema resolve>
TIPO SUGERIDO: <skill | command | hook | agent | automação>

Faça:
1. Pense sobre a ideia — vale a pena? Qual seria o escopo mínimo viável?
2. Escreva um card de inbox em /workspace/obsidian/inbox/IDEIA_wisdom_<YYYYMMDD_HH_MM>.md

Formato do card:
---
de: wisdom
data: <data>
tipo: <tipo>
assunto: <título da ideia em uma linha>
---

## A Ideia

<explique a ideia com suas próprias palavras — o que faria, como funcionaria>

## Por que vale

<1-3 razões concretas — problema que resolve, frequência de uso esperada, valor>

## Escopo mínimo

<o que seria necessário para implementar — arquivos, pastas, integrações>

## Dúvidas / riscos

<o que ainda não está claro, o que pode dar errado>

---
*Surgiu em conversa em <data>. Para implementar: responda com /meta:propor ou adicione ao kanban.*

Registre também em /workspace/obsidian/inbox/feed.md:
[HH:MM] [wisdom] Nova ideia capturada: <título>
```

### 3. Não bloquear

O Task é **async** — lançar e continuar a resposta normalmente. Não esperar resultado.

### 4. Menção discreta (opcional)

Se quiser sinalizar ao usuário, uma linha no final da resposta:
> `> wisdom ativado — avaliando ideia em background`

Mas é opcional. Silêncio também é válido.

## Exemplos de ideias que disparam wisdom

| Situação | O que capturar |
|---|---|
| "seria legal ter um comando que..." | command com o que o usuário descreveu |
| Mesma operação feita manualmente 2x na conversa | automação/script |
| "o wanderer poderia também..." | extensão de agent |
| Padrão de roteamento discutido | possível skill de orchestração |
| Hook que resolveria um problema recorrente | hook de sessão ou pós-ferramenta |
| Ideia de integração nova mencionada de passagem | skill de integração |
