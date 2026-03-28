# [JIRA-ID] — [Nome da Feature] — monolito

## Contexto
[Resumo do card: o que é a feature, por que existe, qual problema resolve]

## Objetivo
[O que especificamente este subagente precisa implementar no monolito]

## Estado atual relevante
[O que já existe relacionado a esta feature:
- Arquivos existentes que serão modificados (com paths)
- O que NÃO existe ainda e precisa ser criado]

## Decisões de arquitetura
<!-- Estas respostas alimentam diretamente o Passo 0 do monolito/make-feature -->
- App de domínio: <ex: ldi, cursos, questoes>
- Handler em: <bo/ | bff/ | bff_mobile/>
- Precisa migration: <sim — motivo | não>
- Precisa repository novo: <sim — motivo | não>
- Precisa service novo: <sim — motivo | não, adicionar método em XxxService existente>
- Service precisa cache Redis: <sim | não>
- Service orquestra outros apps: <sim — quais | não>

## Skill a invocar
monolito/make-feature

## Lista de entregas esperadas
- [ ] [ex: migration — adiciona coluna X na tabela Y]
- [ ] [ex: entity — struct XxxEntity]
- [ ] [ex: repository — interface + impl de XxxRepository]
- [ ] [ex: service — método Xxx em XxxService]
- [ ] [ex: mocks — make mocks-<app>]
- [ ] [ex: testes — cobertura do service]
- [ ] [ex: handler — POST /bo/xxx/yyy]

## Critérios de aceite
[Critérios do card relevantes para o backend]
