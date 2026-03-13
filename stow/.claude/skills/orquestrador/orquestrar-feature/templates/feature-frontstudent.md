# [JIRA-ID] — [Nome da Feature] — front-student

## Contexto
[Resumo do card: o que é a feature, por que existe, qual problema resolve]

## Objetivo
[O que especificamente este subagente precisa implementar no front-student]

## Estado atual relevante
[O que já existe relacionado a esta feature:
- Arquivos existentes que serão modificados (com paths)
- O que NÃO existe ainda e precisa ser criado]

## Endpoints disponíveis
[Endpoints reais do monolito — atualizados pelo orquestrador após 6a]
  METHOD /path/completo
  Payload: { campo: tipo }
  Response: { campo: tipo }

## Skill a invocar
front-student/make-feature — com os seguintes inputs:
- module: <nome do módulo alvo>
- description: <o que a feature faz>
- endpoints: usar os endpoints listados em "Endpoints disponíveis" acima
- needs_page: <true | false>
- is_extension: <true | false>

## Lista de entregas esperadas
- [ ] [ex: service — método fetchXxx em xxxService]
- [ ] [ex: componente — XxxCard.vue]
- [ ] [ex: container — XxxContainer.vue]
- [ ] [ex: page — pages/xxx/index.vue]

## Critérios de aceite
[Critérios do card relevantes para a área do aluno]
