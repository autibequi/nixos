---
name: code/goodpractices
description: "Auto-ativar quando: usuário fala de desenvolvimento, programação, implementar feature, criar endpoint, modificar código, fazer PR, debugar, testar, refatorar — qualquer trabalho em código em qualquer projeto."
---

# goodpractices — Boas Práticas de Desenvolvimento

Skill base de desenvolvimento. Auto-ativa em qualquer conversa de código. Cobre o ciclo completo: entender → planejar → implementar → verificar → entregar.

---

## 1. Nunca modificar o que não foi lido

Antes de qualquer mudança:
- Ler o arquivo completo (ou a seção relevante)
- Entender o padrão existente antes de propor o novo
- Verificar se já existe algo similar antes de criar

```
Proibido: "vou adicionar X" sem ter lido onde X vai morar
Correto: ler → entender → planejar → implementar
```

---

## 2. Plan Mode antes de implementar

Para qualquer intenção de criar ou modificar código, entrar em `EnterPlanMode` **antes** de propor ou executar.

Gatilhos:
- "quero adicionar / criar / implementar / modificar"
- qualquer descrição de trabalho a ser feito em código

Exceção: já dentro de fluxo aprovado nessa mesma conversa.

**Na dúvida, plan mode. Custa pouco, evita retrabalho.**

---

## 3. Worktree isolado para qualquer mudança não-trivial

Toda mudança que envolva mais de 1 arquivo ou que possa ser proposta (não urgente) deve rodar em worktree isolado.

### Quando usar worktree
- Feature nova
- Refactor
- Mudança com impacto em múltiplos arquivos
- Qualquer coisa que o user queira ver antes de decidir

### Quando não usar
- Typo fix trivial em arquivo único
- Mudança que o user aprovou explicitamente sem review

### Fluxo worktree
```
EnterWorktree  →  implementar  →  commit [proposta]  →  pitch  →  user decide
```

**Sessões interativas:** sempre permitido.
**Tasks autônomas:** só se frontmatter tiver `worktrees: true`.

---

## 4. Pitch format — apresentar antes de mergear

Toda proposta implementada em worktree deve ser apresentada antes de mergear:

```
╭─ proposta: <titulo curto> ──────────────────╮

## O que muda
<2-3 bullets diretos>

## Por que
<problema que resolve ou melhoria>

## Arquivos tocados
<lista de arquivos criados/modificados/removidos>

## Diff
<partes relevantes do git diff real>

╰──────────────────────────────────────────────╯
```

Opções ao user:
- **Aceitar** → `ExitWorktree keep` + `git merge --no-ff <branch>`, limpar worktree
- **Aceitar parcial** → cherry-pick seletivo por arquivo/hunk
- **Descartar** → `ExitWorktree remove`, zero side effects

Mostrar diff REAL — rodar `git diff` de verdade, nunca inventar.
Se proposta envolver >10 arquivos, avisar antes de implementar.

---

## 5. Escopo mínimo — não sobre-engenheirar

- Fazer apenas o que foi pedido
- Não adicionar features, refactors ou "melhorias" por conta
- Não adicionar docstrings, comments ou type annotations em código não tocado
- Não criar helpers/abstrações para uso único
- Três linhas similares > abstração prematura

---

## 6. Verificação — evidência antes de declarar pronto

Nunca dizer "pronto" sem mostrar prova:

| Tipo de mudança | Evidência necessária |
|----------------|---------------------|
| Código Go | `go build ./...` passando |
| Testes | output de `go test` ou equivalente |
| Vue/Nuxt | `yarn build` sem erros |
| NixOS | `nh os test .` passando |
| Script/CLI | output de execução real |
| Skill/Command | invocação demonstrada |

Se evidência for impossível (ex: teste manual no host), dizer o que deve ser testado e por que.

---

## 7. Git — commits disciplinados

- Conventional commits: `feat:`, `fix:`, `refactor:`, `chore:`
- NUNCA commitar sem autorização (verificar flag `autocommit` do boot)
- `autocommit=ON` → pode commitar após edições
- `autocommit=OFF` → proibido commitar sem o user pedir
- `git add` para staging é sempre permitido
- Commits no worktree: prefixar com `[proposta]` para distinguir de commits definitivos

---

## 8. Por projeto — onde editar e como verificar

| Projeto | Build/Test | Path raiz | Delegação |
|---------|-----------|-----------|-----------|
| monolito (Go) | `go build ./...` / `go test ./...` | repo Go | `/contractor <pedido>` → Coruja |
| bo-container (Vue 2) | `yarn build` / `yarn test` | `bo-container/` | `/contractor <pedido>` → Coruja |
| front-student (Nuxt 2) | `yarn build` | `front-student/` | `/contractor <pedido>` → Coruja |
| NixOS / Leech | `nh os test .` | `/workspace/mnt/` | direto |
| Leech CLI | `bashly generate` | `leech/cli/src/` | direto |

Para monolito/bo/front: preferir delegar à Coruja — ela conhece o domínio e as skills específicas.

---

## 9. Segurança — regras invioláveis

- Não introduzir: SQL injection, XSS, command injection, credenciais hardcoded
- Validar apenas em fronteiras do sistema (input do user, APIs externas)
- Não validar código interno/framework — confiar nas garantias do framework
- Se encontrar código inseguro por acidente, reportar imediatamente

---

## 10. Worktree — paths e permissões

```bash
# Achar raiz do repo em mount aninhado
git -C <path> rev-parse --show-toplevel

# Contexto de worktree
# /workspace → projeto externo (foco padrão)
# /workspace/mnt → repo NixOS/Leech
```

Permissões:
- Sessão interativa → sempre ok
- Task autônoma → só com `worktrees: true` no frontmatter
- Se rejeitado: sugerir mudança em texto em `obsidian/sugestoes/`
