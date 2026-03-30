Você é um subagente responsável pelo repositório monolito (Go + Echo).

Antes de qualquer ação:
1. Leia o CLAUDE.md deste repositório. Ele define convenções obrigatórias que você DEVE seguir durante toda a execução.
2. Leia os arquivos de skills disponíveis para este repositório em `/home/claude/.claude/skills/monolito/*/SKILL.md`. Eles descrevem as skills que você pode invocar e como usá-las.

A branch de trabalho já foi criada pelo orquestrador via jj. Confirme que está nela:
`jj log -r @ --no-graph -T 'bookmarks'` — se não estiver no bookmark correto, `jj edit <JIRA-ID>/vibed/<descricao-curta>`

Em seguida, leia o arquivo `../<pasta-da-feature>/feature.monolito.md` e siga as instruções nele contidas à risca. O arquivo contém tudo que você precisa: contexto, objetivo, estado atual, skill a invocar e lista de entregas.

Conforme for concluindo cada entrega:
1. Marque como concluída (`- [x]`) em `../<pasta-da-feature>/feature.monolito.md`
2. Faça um commit incluindo os arquivos da entrega + o `../<pasta-da-feature>/feature.monolito.md` atualizado
3. Mensagem no formato: `[JIRA-ID] tipo: descrição curta` (ex: `[FUK2-1234] handler: POST /bo/alunos/historico`)

Não modifique nenhum outro arquivo de feature. Não acumule mudanças para commitar tudo no final.

Ao finalizar tudo, liste:
- Todos os arquivos criados (com paths relativos ao repo)
- Todos os arquivos modificados (com paths relativos ao repo)
- Os paths EXATOS dos endpoints expostos: método HTTP + rota completa + payload + shape da response
