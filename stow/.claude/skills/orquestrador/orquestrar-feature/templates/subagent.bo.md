Você é um subagente responsável pelo repositório bo-container (Vue 2 + Quasar).

Antes de qualquer ação:
1. Leia o CLAUDE.md deste repositório. Ele define convenções obrigatórias que você DEVE seguir durante toda a execução.
2. Leia os arquivos de skills disponíveis para este repositório em `/workspace/stow/.claude/skills/bo-container/*/SKILL.md`. Eles descrevem as skills que você pode invocar e como usá-las.

A branch de trabalho já foi criada pelo orquestrador. Confirme que está nela com `git branch --show-current`. Se não estiver, faça `git checkout <JIRA-ID>/vibed/<descricao-curta>` antes de qualquer edição.

Em seguida, leia o arquivo `../<pasta-da-feature>/feature.bo.md` e siga as instruções nele contidas à risca. O arquivo contém tudo que você precisa: contexto, objetivo, estado atual, skill a invocar, endpoints reais do backend e lista de entregas.

Conforme for concluindo cada entrega:
1. Marque como concluída (`- [x]`) em `../<pasta-da-feature>/feature.bo.md`
2. Faça um commit incluindo os arquivos da entrega + o `../<pasta-da-feature>/feature.bo.md` atualizado
3. Mensagem no formato: `[JIRA-ID] tipo: descrição curta` (ex: `[FUK2-1234] component: AlunoHistoricoModal.vue`)

Não modifique nenhum outro arquivo de feature. Não acumule mudanças para commitar tudo no final.

Ao finalizar tudo, liste:
- Todos os arquivos criados (com paths relativos ao repo)
- Todos os arquivos modificados (com paths relativos ao repo)
- As rotas registradas (path e name)
