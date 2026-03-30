---
name: git/jujutsu
description: "Auto-ativar quando: repo tem .jj/, user menciona jj, jujutsu, change id, bookmark, op log, ou pede operacao de VCS em repo com jj. Workflow completo: comandos, PR GitHub, curar output de AI, recuperacao via op log."
---

# git/jujutsu — Jujutsu VCS

Skill para trabalhar com repos que usam **Jujutsu (jj)** como VCS, seja puro ou como frontend do git.

---

## 🆘 Estou Perdido — Guia de Emergência

Se você não sabe onde está ou o que aconteceu:

```bash
jj log          # onde estou? quais commits existem?
jj status       # o que mudei no working copy?
jj op log       # o que aconteceu até agora nesta sessão?
```

**Algo deu errado?**
```bash
jj undo         # desfaz a última operação (seguro, sempre funciona)
jj op log       # ver histórico completo de operações
jj op restore <id>  # voltar a qualquer estado anterior
```

**Não sei em qual commit estou:**
```bash
jj log -r '@'   # mostra só o commit atual com detalhes
jj show         # diff + metadata do commit atual
```

**Quero voltar para o main limpo:**
```bash
jj edit main    # vai para o commit main (mas pede confirmação!)
```

**Meu repo não tem .jj:**
```bash
jj git init --colocate  # adiciona jj sem apagar o git (pede confirmação!)
```

> **Regra de ouro:** se estiver em dúvida, `jj undo`. É sempre reversível.

---

## Modo Pedagógico — SEMPRE ATIVO

O user está **aprendendo jj** e vem do git. Regras obrigatórias:

1. **Alertar** qualquer anti-padrão git imediatamente — ex: se o user disser `git add`, `git commit`, `git stash`, `git branch`, `git checkout`, `git worktree`, corrigir na hora com o equivalente jj
2. **Pedir confirmação antes de QUALQUER comando jj que escreva algo** — não só os destrutivos. Inclui `jj new`, `jj describe`, `jj bookmark create`, `jj commit`, `jj rebase`, `jj squash`, `jj abandon`, `jj op restore`, `jj git push`
3. **Explicar o efeito concreto** antes de executar — quais commits são afetados, o que muda, o que é reversível
4. **Errar para o lado do excesso** — se tiver dúvida se deve confirmar, confirma

**Leitura pura (automático, sem confirmação):** `jj log`, `jj status`, `jj diff`, `jj show`, `jj op log`

### Repo sem .jj?

Se o repo ainda não tem jj inicializado, **sempre perguntar antes de qualquer operação jj**:

> "⚠️ Este repo não tem `.jj/` — ainda está em git puro. Posso inicializar o jj com:
> ```
> jj git init --colocate
> ```
> Isso **não altera o histórico git** — só adiciona o jj por cima do `.git/` existente.
> Todo o histórico anterior fica acessível via `jj log`. Confirma?"

Após confirmação e execução, verificar:
```bash
jj log          # deve mostrar o histórico existente do git
jj status       # deve mostrar o working copy atual
```

Se o repo não tem git nem jj ainda:
> "Este diretório não tem controle de versão. Quer iniciar com jj puro (`jj git init`) ou já tem um remote git? Me diz como prefere."

Exemplo de confirmação correta:
> "Vou rodar `jj new -m 'feat: auth'`. Isso cria um commit novo vazio em cima do seu working copy atual (`@`). Seus arquivos atuais ficam no commit anterior. Confirma?"

---

## Conceitos Fundamentais

### Sem staging area
Não existe `git add`. O jj captura o working copy **automaticamente** a cada operação.
Tudo que está no disco é parte do commit atual. Ponto.

### Change IDs vs Commit IDs
- **Change ID** (ex: `qpvuntsm`) — imutável, identifica a *mudança* mesmo após rebase/amend
- **Commit ID** (hash) — muda a cada rewrite
- Sempre use Change IDs para referencias durávies em logs/scripts

### Operation Log
Toda operação fica no `jj op log`. Qualquer erro pode ser desfeito com `jj op undo`.

### Commits são baratos
Criar um commit novo (`jj new`) é a forma normal de trabalhar — como um "novo rascunho".
Squash depois se necessário.

---

## Regras — O Que NÃO Fazer

```
❌ git add          → não existe staging
❌ git worktree     → usar jj nativo
❌ git commit       → usar jj describe + jj new
❌ git branch       → usar jj bookmark
❌ git checkout     → usar jj edit ou jj new --insert-before
❌ git stash        → usar jj new (commits são descartáveis)
❌ git merge        → usar jj rebase ou deixar o jj resolver
```

---

## Comandos Core

### Navegação e Status
```bash
jj log                          # log visual com grafo (default: revset main..@)
jj log -r 'all()'               # log completo
jj log -r 'ancestors(@, 5)'     # últimos 5 ancestrais
jj log -r 'main::@'             # commits entre main e atual (sintaxe ::)
jj status                       # arquivos modificados no working copy
jj diff                         # diff do commit atual vs pai
jj diff -r <rev>                # diff de um commit específico
jj diff --from <rev> --to <rev> # diff entre dois commits
jj show <rev>                   # diff + metadata de um commit específico
```

### Criar e Navegar Commits
```bash
jj new                          # novo commit em cima do atual
jj new <rev>                    # novo commit em cima de <rev>
jj new <rev1> <rev2>            # merge commit (dois pais)
jj edit <rev>                   # volta a editar um commit existente
jj describe -m "mensagem"       # descreve o commit atual
jj describe <rev> -m "mensagem" # descreve um commit específico
jj diffedit -r <rev>            # edita o conteúdo de um commit interativamente
```

### Modificar Histórico
```bash
jj squash                       # move mudanças do atual para o pai (amend equivalente)
jj squash --into <rev>          # squash para qualquer commit ancestral
jj squash -i                    # squash interativo (escolher arquivos)
jj unsquash                     # move mudanças do pai para o filho
jj split                        # divide o commit atual em dois (= git add -p + commit)
jj split <paths>                # divide selecionando arquivos específicos
jj rebase -d <dest>             # rebase o commit atual em cima de <dest>
jj rebase -s <source> -d <dest> # rebase <source> e descendentes em <dest>
jj rebase -b <branch> -d <dest> # rebase toda a branch
jj rebase -r <rev> -B <before>  # insere <rev> ANTES de <before>
jj abandon <rev>                # abandona um commit (como git reset --hard)
```

### Desfazer
```bash
jj undo                         # desfaz a última operação jj
jj op log                       # histórico de operações
jj op undo <op-id>              # desfaz operação específica
jj restore --from <rev> <path>  # restaura arquivo de um commit
```

---

## Bookmarks (= Branches do Git)

No jj, "branches" são **bookmarks** — ponteiros nomeados para commits.

```bash
jj bookmark list                # lista todos os bookmarks
jj bookmark create <nome>       # cria bookmark no commit atual
jj bookmark create <nome> -r <rev>  # cria em commit específico
jj bookmark set <nome>          # move bookmark existente para commit atual
jj bookmark set <nome> -r <rev> # move para commit específico
jj bookmark delete <nome>       # deleta bookmark
jj bookmark track <nome>@origin # rastreia bookmark remoto
```

### Convenção de nomes
```bash
jj bookmark create feat/FUK2-1234-descricao
jj bookmark create fix/bug-descricao
```

---

## Colaboração com Git / GitHub / GitLab

### Setup inicial (repo git existente)
```bash
jj git clone <url>              # clone com backend git
# OU em repo git existente:
jj git init --colocate          # inicializa jj no repo git atual
```

### Fetch e Push
```bash
jj git fetch                    # fetch de todos os remotos
jj git fetch --remote origin    # fetch específico
jj git push                     # push de todos os bookmarks locais modificados
jj git push --bookmark <nome>   # push de bookmark específico
jj git push --change @          # push do commit atual (cria bookmark automático)
jj git push --all               # push de tudo
```

### Workflow típico com GitHub PR
```bash
# 1. Criar feature
jj new main -m "feat: descrição"
# ... editar arquivos ...
jj describe -m "feat(scope): mensagem completa"

# 2. Criar bookmark para o PR
jj bookmark create feat/minha-feature

# 3. Push
jj git push --bookmark feat/minha-feature

# 4. Criar PR via gh
gh pr create --head feat/minha-feature --base main

# 5. Atualizar após review
jj edit feat/minha-feature      # volta ao commit da feature
# ... editar arquivos ...
jj git push --bookmark feat/minha-feature
```

### Sincronizar com main
```bash
jj git fetch
jj rebase -d main               # rebase da feature em cima do main atualizado
```

---

## Revsets — Filtros de Log

O jj usa uma linguagem de query para selecionar commits:

```
@                               # working copy (commit atual)
main                            # bookmark main
@-                              # pai do atual
@--                             # avô do atual
main..@                         # commits entre main e atual (default do log)
ancestors(@, 3)                 # 3 níveis de ancestrais
descendants(main)               # tudo abaixo de main
all()                           # todo o repo
mutable()                       # commits não publicados
```

---

## Resolução de Conflitos

O jj **não para** em conflitos — ele os materializa no arquivo e continua.

```bash
jj status                       # mostra arquivos com conflito
# editar os arquivos para resolver
jj resolve                      # abre mergetool configurado (ex: vimdiff)
jj resolve --list               # lista conflitos
```

Formato de conflito no arquivo:
```
<<<<<<< Conflict 1 of 1
+++++++ Contents of side #1
conteúdo da versão A
------- Contents of base
conteúdo base
+++++++ Contents of side #2
conteúdo da versão B
>>>>>>> Conflict 1 of 1
```

---

## Padrões de Workflow

### "Stash" equivalente
```bash
# Em vez de git stash: criar novo commit vazio e voltar ao trabalho
jj new                          # novo commit acima (working copy limpo)
# ... quando quiser continuar o trabalho anterior:
jj edit @-                      # volta ao commit anterior
```

### Amend equivalente
```bash
# Editar o último commit:
# apenas edite os arquivos — o jj captura automaticamente
jj describe -m "nova mensagem"  # se precisar mudar a mensagem
```

### Squash múltiplos commits antes do PR
```bash
jj log -r 'main..@'            # ver commits da feature
jj rebase -s <primeiro-commit-da-feature> -d main  # garantir base
jj squash --from <commits> --into <destino>
# OU usar jj squash iterativamente
```

### Ver o que será enviado no PR
```bash
jj diff --from main --to @      # diff completo da feature
jj log -r 'main..@'            # commits da feature
```

---

## Workspaces Múltiplos

O jj suporta múltiplos working copies no mesmo repo (sem `git worktree`):

```bash
jj workspace add ../minha-feature    # cria workspace paralelo
jj workspace list                    # lista todos
jj workspace root --name <ws>        # path de um workspace específico
jj workspace update-stale            # atualiza workspace stale após ops externas
```

Útil para: revisar código enquanto continua trabalhando, builds paralelos, etc.

---

## Limitações — Git Compatibility

O jj tem suporte **parcial** a algumas features git:

| Feature | Suporte |
|---------|---------|
| Branches/bookmarks, merge commits | Completo |
| Tags (leitura/checkout) | Parcial — não cria annotated tags |
| `.gitignore` | Funciona, mas pode precisar de `jj file untrack` manual |
| Config git (remotes, `core.excludesFile`) | Parcial |
| `.gitattributes` | **Não suportado** |
| Hooks git | **Não suportados** |
| Submodules | **Não suportados** |
| Git LFS | **Não suportado** |
| Sparse checkouts | **Não suportados** |
| Staging area (index) | **Ignorado** pelo jj |

---

## Configuração Recomendada (~/.jjconfig.toml)

```toml
[user]
name = "Seu Nome"
email = "seu@email.com"

[ui]
default-command = "log"         # jj sozinho mostra o log
diff-editor = ":builtin"
merge-editor = "vimdiff"

[git]
auto-local-bookmark = true      # bookmarks locais para branches git

[revsets]
log = "@ | ancestors(main..@, 2) | main"  # log focado na feature atual

[core]
# Protege commits já publicados de modificação acidental
immutable-revisions = "bookmarks(remote_bookmarks())"
```

### Workflow de Stacked PRs

O rebase automático de descendentes torna PRs empilhados práticos:

```bash
# Criar stack lógica
jj new main                              # base
jj describe -m "refactor: extrair helper"
# ... editar ...

jj new                                   # PR 1
jj describe -m "feat: usar helper"
# ... editar ...

jj new                                   # PR 2
jj describe -m "test: cobertura do helper"
# ... editar ...

# Criar bookmarks para cada PR
jj bookmark create feat/refactor -r @--
jj bookmark create feat/use-helper -r @-
jj bookmark create feat/tests -r @

# Push tudo
jj git push --all
```

Quando o PR 1 é aprovado e o PR 2 precisa de ajuste:
```bash
jj edit feat/use-helper    # volta ao commit do PR 1
# ... corrige ...
# descendentes (feat/tests) fazem rebase automaticamente
jj git push --all
```

---

## Anti-padrões e Armadilhas

| Situação | Errado | Correto |
|----------|--------|---------|
| Salvar progresso | `git add && git commit` | Editar arquivos (jj captura auto) |
| Nova branch | `git checkout -b` | `jj new` + `jj bookmark create` |
| Mudar mensagem | `git commit --amend` | `jj describe -m` |
| Desfazer | `git reset --hard` | `jj undo` ou `jj abandon` |
| Ver mudanças | `git diff` | `jj diff` |
| Navegar histórico | `git log` | `jj log` |
| Stash | `git stash` | `jj new` (commit rascunho) |
| Rebase interativo | `git rebase -i` | `jj rebase` + `jj squash` |

---

## Workflow Multi-Repo (Features Cross-Repo)

Pedro sempre trabalha em features que tocam os 3 repos da Estratégia simultaneamente:
`monolito` (Go) + `bo-container` (Vue 2) + `front-student` (Nuxt 2)

O mesmo ticket/nome de branch é usado nos 3 — ex: `FUK2-11746/toc-async-builder`.

### Iniciar feature nova nos 3 repos

```bash
TICKET="FUK2-99999/minha-feature"

for repo in monolito bo-container front-student; do
  cd /workspace/projects/estrategia/$repo
  jj new main@origin -m "feat: descrição da feature"
  jj bookmark create $TICKET --rev @
done
```

### Trabalhar em um repo específico

```bash
cd /workspace/projects/estrategia/monolito
jj log   # ver onde está
jj new -m "feat(api): endpoint X"   # novo commit
# editar arquivos...
```

### Ver estado dos 3 de uma vez

```bash
for repo in monolito bo-container front-student; do
  echo "=== $repo ==="
  cd /workspace/projects/estrategia/$repo && jj log --limit 3
done
```

### Sincronizar com main (rebase nos 3)

```bash
TICKET="FUK2-11746/toc-async-builder"

for repo in monolito bo-container front-student; do
  cd /workspace/projects/estrategia/$repo
  jj git fetch
  jj rebase -b $TICKET -d main@origin
done
```

### Push nos 3

```bash
TICKET="FUK2-11746/toc-async-builder"

for repo in monolito bo-container front-student; do
  cd /workspace/projects/estrategia/$repo
  jj git push --bookmark $TICKET
done
```

### Abandonar feature inteira (desfazer tudo)

```bash
TICKET="FUK2-11746/toc-async-builder"

for repo in monolito bo-container front-student; do
  cd /workspace/projects/estrategia/$repo
  jj abandon $TICKET   # remove commits locais
  jj bookmark delete $TICKET 2>/dev/null || true
done
```

### Iniciar nova sessão de trabalho (repo já tem feature)

```bash
cd /workspace/projects/estrategia/monolito
jj edit FUK2-11746/toc-async-builder   # volta para o commit da feature
jj new -m "feat: continuar X"          # novo commit em cima
```

---

## Workflow com AI (Claude Code + jj)

### Por que jj é superior para agentes AI

| Problema com git | Solução jj |
|---|---|
| AI esquece de `git add` | Não existe staging — automático |
| `git clean` acidental destroi trabalho | `jj op undo` restaura tudo |
| Perda de contexto entre sessões | `jj obslog --revision @ --patch` mostra o que mudou |
| Force-push perigoso | jj só faz force-push quando necessário, de forma segura |

### Ciclo com Pedro (fluxo aprovação/abandono)

```bash
# 1. Pedro descreve o que quer
jj new -m "feat: botão de logout"   # ← ANTES de editar qualquer arquivo

# 2. Claude implementa (edita arquivos normalmente)

# 3. Pedro testa

# ✅ Aprovado:
jj bookmark create feat/logout --rev @
jj git push --bookmark feat/logout

# ❌ Não gostou — desfaz tudo de uma vez:
jj abandon     # commit some, arquivos voltam ao estado anterior
# ou se quiser desfazer a operação inteira (inclusive o jj new):
jj op undo
```

> `jj abandon` é o botão de desfazer total. Sem staging pra limpar, sem reset, sem nada.

### Regras para o agente

```
✅ ANTES de começar qualquer tarefa:
   jj new -m "feat: o que vou implementar"   ← descrever ANTES de editar

✅ DURANTE:
   editar arquivos normalmente — jj captura automático

✅ AO TERMINAR:
   jj describe -m "mensagem final"            ← atualizar descrição
   jj git push --bookmark <nome>              ← se for publicar

❌ NUNCA fazer:
   git add / git commit / git stash / git branch
   git worktree — use jj new + jj edit para alternar entre trabalhos
```

### Hooks recomendados para settings.json

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": "[[ -d .jj ]] && jj show --summary 2>/dev/null || true"}]
    }],
    "UserPromptSubmit": [{
      "matcher": "*",
      "hooks": [{"type": "command", "command": "[[ -d .jj ]] && jj status 2>/dev/null || true"}]
    }]
  }
}
```

> Qualquer comando jj (mesmo `jj status`) dispara snapshot interno. O `jj op log` fica com
> histórico completo sem criar commits desnecessários.

### Recuperar trabalho perdido pela AI

```bash
jj obslog --revision @ --patch --limit 5  # ver o que mudou no working copy
jj op log                                  # histórico de todas as operações
jj op restore <operation-id>              # restaurar estado anterior completo
jj op undo                                # desfazer última operação
```

---

## Curar Output da AI em Commits Limpos

A AI tende a misturar refactor + fix + feat no mesmo commit. Use jj para separar:

### Dividir um commit em partes

```bash
jj split                         # TUI interativa — selecionar arquivos/hunks
jj split --parallel <arquivo>    # isolar arquivo em commit paralelo (sem pai/filho)
```

### Squash seletivo

```bash
jj squash -i                                          # squash interativo — escolher o que vai pro pai
jj squash --from <ai-rev> --into <clean-rev>          # mover mudanças entre commits
```

### Workflow de curadoria típico

```bash
# AI gerou tudo num commit gigante
jj log -r 'main..@'

# Dividir por intenção
jj split                         # separa em feat + fix + refactor

# Reordenar se necessário
jj rebase -r <fix-rev> -d main   # mover o fix para antes da feature

# Verificar resultado final
jj log -r 'main..@'
jj diff --from main              # diff completo do que será enviado
```

---

## Integração com Hooks de Commit

Ao usar `jj git push`, se o remoto tiver hooks de pre-receive, eles rodam normalmente.
Para hooks locais equivalentes ao pre-commit do git, configurar em `.jj/hooks/` (ainda experimental).

---

## Troubleshooting

**`jj` não reconhece o repo:**
```bash
jj git init --colocate          # se for repo git existente sem jj
```

**Commit ficou vazio acidentalmente:**
```bash
jj abandon                      # abandona o commit vazio atual
```

**Preciso do hash git de um commit:**
```bash
jj log --no-graph -T 'commit_id ++ "\n"' -r @
```

**Ver o estado do .git (para ops que ainda precisam de git):**
```bash
jj git export                   # força sync jj → .git
jj git import                   # força sync .git → jj
```
