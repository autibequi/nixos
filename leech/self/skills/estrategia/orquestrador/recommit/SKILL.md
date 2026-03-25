---
name: orquestrador/recommit
description: Use when the developer wants to reorganize the commit history of a repository branch for PR review. Asks which repo (monolito, bo-container, front-student), resets all commits since the fork from main, reads the final code diff, and creates clean, chronological, small commits that tell a logical development story. Optionally force-pushes at the end.
---

# recommit: Reorganizar histórico de commits para PR

## Passo 1 — Perguntar qual repositório

Perguntar ao dev qual repositório deseja recommitar:

```
Qual repositório deseja recommitar?
1. monolito
2. bo-container
3. front-student
```

Aguardar a resposta antes de prosseguir.

## Passo 2 — Identificar o ponto de fork e o escopo real

### 2a — safe.directory (sempre rodar primeiro)

```bash
HOME=/tmp git config --global --add safe.directory /workspace/mnt/estrategia/<repo>
```

### 2b — Fork point e commits

```bash
HOME=/tmp git -C /workspace/mnt/estrategia/<repo> merge-base main HEAD
HOME=/tmp git -C /workspace/mnt/estrategia/<repo> rev-list --count <FORK_POINT>..HEAD
HOME=/tmp git -C /workspace/mnt/estrategia/<repo> log --oneline <FORK_POINT>..HEAD
```

### 2c — Diff real vs main (OBRIGATÓRIO)

O diff vs fork point pode incluir commits que já foram mergeados na main (via PRs de outras branches). Sempre confirmar o que de fato difere da main atual:

```bash
HOME=/tmp git -C /workspace/mnt/estrategia/<repo> diff main..HEAD --stat
```

**Usar este diff como fonte da verdade** para o plano de commits — não o diff do fork point. Se os dois coincidirem, main ainda está no fork point. Se diferirem, ignorar os arquivos que já existem igualmente na main.

### 2d — Apresentar ao dev

Mostrar:
- Repositório: `<repo>`
- Branch: `<branch-atual>`
- Fork point: `<FORK_POINT_SHORT>`
- Commits no histórico: N (incluindo merges)
- Arquivos realmente diferentes de main: (stat do 2c)

## Passo 3 — Executar o reset --soft

```bash
cd /home/claude/projects/estrategia/<repo>/
HOME=/tmp git reset --soft <FORK_POINT>
```

Agora todas as mudanças estão staged. Fazer um unstage geral para ter controle granular:

```bash
HOME=/tmp git restore --staged .
```

## Passo 4 — Analisar o diff completo

Ler e entender todas as mudanças feitas desde o fork:

1. Listar todos os arquivos modificados/criados/deletados:
   ```bash
   HOME=/tmp git status --short
   ```

2. Ler o conteúdo de cada arquivo modificado/criado para entender o que foi feito

3. Categorizar as mudanças em grupos lógicos que contam uma história de desenvolvimento cronológica

### Critérios de agrupamento por repositório

**monolito (Go + Echo):**
- migration (cada migration é um commit)
- entity/model (structs e tipos)
- repository (interface + implementação)
- service (lógica de negócio)
- mocks (arquivos gerados)
- testes (unit tests)
- handler (endpoints HTTP)
- ajustes/fixes (correções pontuais)

**bo-container (Vue 2 + Quasar):**
- service (API service)
- route (registro de rotas)
- componentes (cada componente ou grupo coeso de componentes)
- page (página principal)
- ajustes/fixes

**front-student (Nuxt 2 + Vue 2):**
- service (API service)
- componentes (cada componente ou grupo coeso de componentes)
- container (container components)
- page (páginas em pages/)
- ajustes/fixes

### Regras de agrupamento

- Cada commit deve compilar/funcionar isoladamente quando possível
- A ordem deve fazer sentido cronológico: infraestrutura antes de lógica, lógica antes de UI
- Não criar commits com apenas 1 linha de mudança — agrupar com contexto relacionado
- Não criar commits enormes com muitos arquivos desrelacionados — quebrar em partes lógicas
- Arquivos de configuração/registro (rotas, imports) vão junto com a feature que os necessita

## Passo 4.5 — Apresentar plano e aguardar confirmação (OBRIGATÓRIO antes de commitar)

Após analisar e categorizar todas as mudanças, apresentar o plano completo ao dev **antes de criar qualquer commit**.

Usar obrigatoriamente esta caixa:

```
  ██████████████████████████████████████████
  █  AÇÃO NECESSÁRIA — <repo>              █
  ██████████████████████████████████████████
  │                                        │
  │   Repositório: <repo>                  │
  │   Branch: <branch>                     │
  │   Reset base: <FORK_POINT_SHORT>       │
  │                                        │
  │   Plano — N commits:                   │
  │                                        │
  │   1. [JIRA-ID] tipo: descrição         │
  │      arquivo1.vue                      │
  │      arquivo2.vue                      │
  │                                        │
  │   2. [JIRA-ID] tipo: descrição         │
  │      arquivo3.go                       │
  │                                        │
  │   ...                                  │
  │                                        │
  │   Confirma? (sim/não)                  │
  │                                        │
  ╰────────────────────────────────────────╯
```

**PARAR AQUI e aguardar "sim" explícito.** Só após confirmação prosseguir para o Passo 5.
- Respostas ambíguas ("ok", "pode ser", "talvez") = tratar como "não"
- O dev pode pedir ajustes no plano (agrupar, separar, renomear) — incorporar e reapresentar a caixa antes de commitar
- Nunca começar a commitar sem aprovação explícita

## Passo 5 — Criar os commits reorganizados

Para cada grupo lógico, na ordem cronológica definida:

1. Adicionar os arquivos do grupo:
   ```bash
   HOME=/tmp git add <arquivo1> <arquivo2> ...
   ```

2. Ler o autor do histórico:
   ```bash
   HOME=/tmp git log --format="%an|%ae" | grep -v "Claude" | head -1
   ```
   Se não encontrar (histórico foi resetado), usar o log do reflog ou pedir ao dev.

3. Commitar:
   ```bash
   HOME=/tmp git -c user.name="<Nome Dev>" -c user.email="<email@dev.com>" commit -m "$(cat <<'EOF'
   mensagem descritiva do commit

   Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```

4. Repetir para cada grupo

### Formato das mensagens

Se houver um JIRA ID no nome da branch, usar:
```
[JIRA-ID] tipo: descrição curta do que foi feito
```

Se não houver JIRA ID:
```
tipo: descrição curta do que foi feito
```

Onde `tipo` é: migration, entity, repository, service, mock, test, handler, component, page, route, fix, refactor, config, etc.

## Passo 6 — Mostrar o resultado

Exibir o novo histórico:

```bash
HOME=/tmp git -C /workspace/mnt/estrategia/<repo> log --oneline main..HEAD
```

Apresentar usando esta caixa:

```
  ██████████████████████████████████████████
  █  SUCESSO                               █
  ██████████████████████████████████████████
  │                                        │
  │   Histórico reorganizado — N commits:  │
  │                                        │
  │   abc1234 [JIRA] tipo: descrição       │
  │   def5678 [JIRA] tipo: descrição       │
  │   ...                                  │
  │                                        │
  │   Deseja fazer push --force-with-lease?│
  │                                        │
  ╰────────────────────────────────────────╯
```

## Passo 7 — Push (opcional)

Se o dev confirmar o push:

```bash
cd /home/claude/projects/estrategia/<repo>/
HOME=/tmp git push --force-with-lease origin <branch-atual>
```

Se o dev não quiser, encerrar.

## Regras

- **Nunca prosseguir com o reset sem confirmação explícita do dev**
- **Nunca fazer push sem confirmação explícita do dev**
- **Usar `--force-with-lease`** em vez de `--force` para segurança
- **Ler todo o código** antes de decidir os agrupamentos — não adivinhar pela extensão do arquivo
- **A história deve fazer sentido** para um revisor de PR — como se o dev tivesse desenvolvido passo a passo
- **Autor do commit é sempre o dev**, Claude é co-autor
- **Se algo der errado** durante o processo, informar imediatamente e sugerir `git reflog` para recuperação
