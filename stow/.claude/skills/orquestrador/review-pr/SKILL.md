---
name: orquestrador/review-pr
description: Use when the developer wants to read and resolve PR review comments (e.g. from RabbitAI, teammates) on a GitHub pull request. Reads all comments via `gh` CLI using GH_TOKEN, groups them by file/topic, and iterates on the code to resolve each one. Requires GH_TOKEN configured in .env.
---

# review-pr: Ler e resolver comentários de PR

## Pré-requisito

Esta skill requer `GH_TOKEN` configurado no `.env` do container. Se não estiver configurado, orientar o dev:

```
GH_TOKEN não encontrado. Configure no .env seguindo o .env.example:
  1. Crie um Fine-grained token em GitHub → Settings → Developer settings
  2. Permissões: Pull requests (Read-only), Contents (Read-only), Issues (Read-only)
  3. Adicione no .env: GH_TOKEN=ghp_...
  4. Reinicie o container: docker compose restart claude
```

## Passo 1 — Identificar o PR

Se o dev passou um número de PR ou URL, extrair o número e o repositório.

Se não passou, detectar automaticamente a partir da branch atual de cada repositório:

```bash
cd <repo>/
BRANCH=$(HOME=/tmp git branch --show-current)
```

Tentar encontrar PR aberto para essa branch usando `gh`:

```bash
GH_TOKEN=$GH_TOKEN gh pr list --repo estrategiahq/<repo> --head "$BRANCH" --state open --json number,title,url --limit 1
```

Repetir para cada repositório (`monolito`, `bo-container`, `front-student`) e listar os PRs encontrados:

```
PRs encontrados:
  monolito    #123 — Título do PR
  bo-container #456 — Título do PR

Qual PR deseja revisar? (ou "todos")
```

## Passo 2 — Ler os comentários do PR

Para o PR selecionado, buscar todos os tipos de comentários:

### 2a — Comentários gerais (conversação do PR)

```bash
GH_TOKEN=$GH_TOKEN gh api repos/estrategiahq/<repo>/issues/<pr_number>/comments --jq '.[] | {id, user: .user.login, body: .body, created_at: .created_at}'
```

### 2b — Review comments (inline no código)

```bash
GH_TOKEN=$GH_TOKEN gh api repos/estrategiahq/<repo>/pulls/<pr_number>/comments --jq '.[] | {id, user: .user.login, path: .path, line: .original_line, diff_hunk: .diff_hunk, body: .body, in_reply_to_id: .in_reply_to_id, created_at: .created_at}'
```

### 2c — Reviews (aprovações, pedidos de mudança)

```bash
GH_TOKEN=$GH_TOKEN gh api repos/estrategiahq/<repo>/pulls/<pr_number>/reviews --jq '.[] | {id, user: .user.login, state: .state, body: .body}'
```

## Passo 3 — Organizar e apresentar

Agrupar os comentários por arquivo e linha, montando threads (usando `in_reply_to_id`). Separar por autor para facilitar a visualização.

Apresentar ao dev no formato:

```
PR #123 — monolito — Título do PR
Comentários: N pendentes

── arquivo1.go:42 ──────────────────────────
  [rabbitai] Sugestão: usar mutex aqui para evitar race condition
  [dev] Faz sentido, vou ajustar
  → Status: não resolvido

── arquivo2.go:108 ─────────────────────────
  [rabbitai] Este erro não está sendo tratado
  → Status: não resolvido

── Gerais ──────────────────────────────────
  [rabbitai] Resumo: 3 issues encontradas...
```

### Classificação dos comentários

Categorizar cada comentário como:

| Tipo | Descrição | Ação |
|---|---|---|
| Bug/Erro | Problema real no código | Corrigir |
| Sugestão | Melhoria de qualidade/legibilidade | Avaliar com dev |
| Nitpick | Estilo, formatação menor | Avaliar com dev |
| Pergunta | Dúvida sobre decisão | Responder |
| Elogio/Info | Sem ação necessária | Ignorar |

## Passo 4 — Validar relevância dos comentários

Antes de propor qualquer resolução, **analisar criticamente cada comentário** e dar seu veredito honesto sobre se vale a pena resolver. Nem todo comentário de reviewer (humano ou bot) é válido ou relevante.

Para cada comentário, avaliar:

| Critério | Pergunta |
|---|---|
| Impacto real | Isso causa bug, perda de dados ou comportamento inesperado? |
| Proporcionalidade | O esforço da mudança é proporcional ao benefício? |
| Over-engineering | A sugestão adiciona complexidade desnecessária para um caso de uso único? |
| Contexto do projeto | Faz sentido dado os padrões e convenções do repositório? |

Apresentar a análise ao dev com recomendação clara:

```
Análise dos comentários — PR #123

  #  Arquivo:linha        Comentário                         Veredito   Por quê
  1  arquivo1.go:42       Adicionar mutex (bug real)         ✅ Válido  Race condition confirmada
  2  arquivo2.go:108      Tratar erro retornado              ✅ Válido  Erro silenciado pode mascarar falha
  3  arquivo3.go:55       Extrair para computed              ❌ Ignorar Usado 1x, extrair é over-engineering
  4  arquivo3.go:200      Duplicação de código               ✅ Válido  Manutenção futura fica frágil
  5  Geral                Resumo do bot                      ➖ Info    Sem ação necessária

Recomendação: resolver 1, 2 e 4. Ignorar 3 e 5.
Concorda? Quer ajustar algo?
```

**PARAR e aguardar aprovação do dev.** Nunca implementar sem confirmação. O dev pode discordar da análise e pedir para resolver ou ignorar itens diferentes.

## Passo 5 — Plano de resolução

Após o dev aprovar quais comentários resolver, apresentar o plano de implementação:

```
Plano de resolução (aprovados pelo dev):

  1. arquivo1.go:42 — adicionar mutex em FuncX()
  2. arquivo2.go:108 — tratar erro retornado em FuncY()
  4. arquivo3.go:200 — extrair método auxiliar para eliminar duplicação

Posso prosseguir?
```

**PARAR e aguardar confirmação antes de implementar.**

## Passo 6 — Resolver os comentários

Para cada item aprovado:

1. **Ler o arquivo atual** no repositório local (não o diff do PR)
2. **Entender o contexto completo** — ler funções adjacentes, imports, testes relacionados
3. **Aplicar a correção** usando Edit
4. **Verificar** se a correção não quebra nada:
   - Go: `cd <repo> && go build ./...` e rodar testes relevantes
   - Vue: verificar se o componente ainda faz sentido estruturalmente

5. **Commitar** cada correção (ou grupo coeso):

```bash
cd <repo>/
HOME=/tmp git -c user.name="$GIT_AUTHOR_NAME" -c user.email="$GIT_AUTHOR_EMAIL" add <arquivos>
HOME=/tmp git -c user.name="$GIT_AUTHOR_NAME" -c user.email="$GIT_AUTHOR_EMAIL" commit -m "$(cat <<'EOF'
fix: descrição da correção (review PR #N)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

6. **Reportar** o que foi feito em formato de tabela.

## Passo 7 — Avaliação final

Ao concluir todas as resoluções, **sempre apresentar a avaliação final em formato de tabela**:

```
Avaliação Final — PR #123 — monolito

  #  Arquivo:linha        Comentário                   Status       Commit
  1  arquivo1.go:42       Adicionar mutex              ✅ Resolvido  a1b2c3d
  2  arquivo2.go:108      Tratar erro retornado        ✅ Resolvido  d4e5f6a
  3  arquivo3.go:55       Extrair para computed         ❌ Ignorado   —
  4  arquivo3.go:200      Duplicação de código         ✅ Resolvido  g7h8i9j
  5  Geral                Resumo do bot                 ➖ Info       —

Resultado: 3/5 resolvidos · 1 ignorado · 1 informativo
Commits: 3 novos commits na branch feature/xyz
```

A tabela deve conter **todos** os comentários do PR (não apenas os resolvidos), com o status final de cada um. Isso dá visibilidade completa do que foi feito e do que foi conscientemente ignorado.

Se houver mais comentários pendentes ou se o dev quiser revisar outros PRs, voltar ao passo relevante.

Após a tabela, perguntar:

```
Deseja fazer push para atualizar o PR? (sim/não)
```

Se sim:

```bash
cd <repo>/
HOME=/tmp git push origin $(HOME=/tmp git branch --show-current)
```

## Regras

- **Nunca implementar sem aprovação** — sempre apresentar o plano antes
- **Nunca fazer push sem confirmação** — perguntar explicitamente
- **Se GH_TOKEN não estiver configurado**, parar e orientar o dev (não tentar sem token)
- **Ler o arquivo completo** antes de editar — não confiar apenas no diff_hunk do comentário
- **Respeitar o escopo** — resolver apenas o que o comentário pede, não refatorar código ao redor
- **Commits pequenos** — um commit por correção ou grupo coeso de correções relacionadas
- **Lint apenas nos arquivos modificados** — nunca rodar lint no projeto inteiro
- **Se um comentário for ambíguo** ou conflitar com a arquitetura do projeto, escalar para o dev em vez de decidir sozinho
