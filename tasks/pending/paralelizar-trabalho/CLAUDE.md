# Paralelizar Trabalho — Pesquisa & Proposta

## Contexto
Hoje o Claudinho roda um container único (`claude-nix-sandbox`) que processa tasks sequencialmente via `clau-runner.sh`. O usuário quer explorar formas de paralelizar o trabalho — múltiplas tasks rodando ao mesmo tempo, possivelmente com múltiplos containers.

## O que pesquisar e avaliar

### 1. Estado atual (ler, não modificar)
- `docker-compose.claude.yml` — como o container está configurado
- `Dockerfile.claude` — o que está instalado
- `scripts/clau-runner.sh` — como tasks são processadas
- `makefile` — targets disponíveis
- `tasks/` — estrutura de tasks

### 2. Abordagens a considerar

#### A. Múltiplos workers no mesmo container
- Runner processar N tasks em paralelo (background jobs)
- Prós: simples, sem overhead de container
- Contras: contenção de recursos, complexidade de lock

#### B. Múltiplos containers (docker-compose scale)
- `docker compose up --scale sandbox=N`
- Cada container pega uma task diferente
- Prós: isolamento real, escala horizontal
- Contras: custo de API (cada container = uma sessão Claude), volume compartilhado

#### C. Container por projeto
- Um container fixo por projeto em `claudinho/` (monolito, bo-container, front-student)
- Cada um com seu CLAUDE.md e context
- Prós: contexto isolado, paralelismo natural
- Contras: mais infra pra manter

#### D. Worktrees + containers
- Git worktrees para branches diferentes
- Container por worktree
- Prós: trabalho paralelo em branches diferentes
- Contras: complexidade

#### E. Orquestrador + workers
- Container principal que despacha tasks
- Workers efêmeros que executam e morrem
- Prós: arquitetura limpa
- Contras: mais complexo

### 3. Constraints
- API Claude tem custo por token — paralelismo custa mais
- Timeout de 20min por task
- Tasks recorrentes voltam pra fila
- Volume `/workspace` é compartilhado — cuidado com conflitos de escrita
- O host é um G14 com 7940HS (8C/16T) + 32GB RAM — recursos limitados

## Entregável
Escrever `<diretório de contexto>/contexto.md` com:

```
# Paralelizar Trabalho — Análise
**Data:** <timestamp>

## Estado atual
<como funciona hoje, gargalos identificados>

## Comparação de abordagens
| Abordagem | Complexidade | Custo API | Isolamento | Recomendação |
|-----------|-------------|-----------|------------|-------------|

## Proposta recomendada
<a melhor abordagem, com justificativa>

## Implementação
<passos concretos para implementar, com estimativa de esforço>

## Riscos
<o que pode dar errado>
```

Se a proposta for boa, criar também `<diretório de contexto>/proposta-docker-compose.yml` com um rascunho da config.

## Regras
- NÃO modifique nenhum arquivo do workspace
- Seja prático — o objetivo é encontrar a solução que dá mais valor com menos complexidade
- Considere que o usuário é 1 dev solo — não precisa de infra enterprise
