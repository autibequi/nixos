# Melhorar Automações do Claudinho

## Objetivo
Analise toda a estrutura do workspace `/workspace` e proponha melhorias concretas de automação. Foco em reduzir trabalho manual e tornar o fluxo mais eficiente.

## O que analisar
1. **makefile** — targets existentes, possíveis targets novos úteis
2. **scripts/** — clau-runner.sh e possíveis scripts auxiliares que faltem
3. **tasks/** — o próprio sistema de tarefas, se pode ser mais robusto
4. **stow/** — automação de dotfiles, detecção de drift, validação
5. **CLAUDE.md** — se a personalidade/diretrizes podem ser mais claras
6. **docker-compose.claude.yml + Dockerfile.claude** — otimizações no container

## O que entregar
Crie um arquivo `proposta.md` DENTRO DESTA PASTA da tarefa (o diretório onde este CLAUDE.md está) com:

- Lista numerada de melhorias propostas
- Para cada uma: o que é, por que ajuda, e nível de esforço (baixo/médio/alto)
- Priorização: o que dá mais valor com menos esforço primeiro

## Regras
- **NÃO** modifique nenhum arquivo do workspace — apenas leia e analise
- **NÃO** toque em código de projetos dentro de `claudinho/`
- Escreva APENAS o `proposta.md` dentro desta pasta de tarefa
- Seja direto e prático — nada de proposta genérica tipo "melhorar documentação"
