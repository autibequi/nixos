---
name: orquestrador/pr-inspector
description: Use when the developer wants an interactive, guided, step-by-step inspection of a PR — especially large vibe-coded PRs (4k+ lines). Walks through the PR category-by-category with the developer, asks questions, detects hallucinations, cross-references existing patterns, and builds shared understanding. Unlike review-code (automated) or review-pr (resolves comments), this is a proactive detective-style walkthrough WITH the user.
---

# pr-inspector: Inspeção Interativa de PR

## Templates

Antes de executar, ler TODOS os templates neste diretório:

| Arquivo | Conteúdo |
|---|---|
| `templates/patterns.md` | **Catálogo de padrões suspeitos** — sinais de vibe-code, hallucinations, anti-patterns. **EVOLUI COM O TEMPO.** |
| `templates/go-checklist.md` | Checklist de inspeção específico para Go |
| `templates/vue-checklist.md` | Checklist de inspeção específico para Vue 2 / Nuxt 2 |
| `templates/report.md` | Template do relatório final de inspeção |

## Diferença dos Outros Skills

| Skill | Modo | Propósito |
|---|---|---|
| `review-code` | Automatizado | Gera artefatos de review autonomamente |
| `review-pr` | Reativo | Lê e resolve comentários de review existentes |
| **`pr-inspector`** | **Interativo** | **Caminha com o dev categoria por categoria, faz perguntas, constrói entendimento compartilhado** |

## Entrada

- `$ARGUMENTS`: número do PR, URL do PR, ou `<repo>#<number>` (ex: `monolito#1234`)

## Passo 1 — Fetch PR

### Detectar repo e buscar metadata:

```bash
GH_TOKEN=$GH_TOKEN gh pr view <number> --repo estrategiahq/<repo> --json title,body,state,headRefName,baseRefName,additions,deletions,files,commits,author,createdAt
```

### Buscar o diff completo:

```bash
GH_TOKEN=$GH_TOKEN gh pr diff <number> --repo estrategiahq/<repo>
```

Se o PR não for encontrado, tentar detectar o repo:
```bash
for repo in monolito bo-container front-student; do
  GH_TOKEN=$GH_TOKEN gh pr view <number> --repo estrategiahq/$repo --json number,title 2>/dev/null && echo "→ $repo"
done
```

## Passo 2 — Triage

Apresentar o big picture ao dev:

```
── PR #<N> — <repo> ──────────────────────

  Título:   <título>
  Autor:    <autor>
  Branch:   <head> → <base>
  Criado:   <data>
  Tamanho:  +<additions> / -<deletions> linhas
  Arquivos: <count> modificados
  Commits:  <count>

── Avaliação de Risco ────────────────────

  Tamanho:        <small/medium/large/massive>
  Commits:        <single/few/many>
  Vibe-code risk: <low/medium/high>
```

### Sinais de vibe-code risk:
| Sinal | Peso |
|---|---|
| Commit único com >500 linhas | Alto |
| >4000 linhas total | Alto |
| Mensagem de commit genérica ("implement feature", "add changes") | Médio |
| Muitos arquivos novos sem testes correspondentes | Médio |
| Padrões inconsistentes dentro do mesmo PR | Médio |
| Autor conhecido por usar AI assistants | Contexto |

Perguntar ao dev:

```
Quer a inspeção completa (todas as categorias) ou focada?
Categorias disponíveis: [listar as categorias detectadas]
```

**PARAR e aguardar resposta.**

## Passo 3 — Categorizar arquivos

Agrupar arquivos por camada usando path patterns:

### Monolito (Go):
| Categoria | Pattern | Ordem |
|---|---|---|
| Migration | `migration/` | 1 |
| Entity/Struct | `structs/`, `entities/` | 2 |
| Interface | `interfaces/` | 3 |
| Repository | `repositories/` | 4 |
| Service | `services/` | 5 |
| Handler | `handlers/` (HTTP) | 6 |
| Worker | `handlers/` (event) | 7 |
| Test | `*_test.go` | 8 |
| Mock | `mocks/` | 9 |
| Config | `configuration/`, `*.yaml`, `*.json` | 10 |

### BO Container / Front Student (Vue/Nuxt):
| Categoria | Pattern | Ordem |
|---|---|---|
| Service | `services/` | 1 |
| Store | `store/` | 2 |
| Route | `router/` | 3 |
| Component | `components/` | 4 |
| Container | `containers/` | 5 |
| Page | `pages/` | 6 |
| Config | `*.config.*`, `nuxt.config.*` | 7 |

Apresentar mapa:

```
── Categorias detectadas ─────────────────

  Categoria      Arquivos  Linhas
  migration      2         +45
  entity         3         +120
  interface      2         +30
  repository     3         +250
  service        4         +380
  handler        3         +200
  test           5         +300
  mock           3         +150
  ──────────────────────────────
  Total          25        +1475
```

## Passo 4 — Inspeção interativa (bottom-up)

Para cada categoria, na ordem definida acima (fundações primeiro):

### 4a — Apresentar categoria

```
── [N/total] Categoria: <nome> ───────────

  Arquivos:
  - path/to/file1.go  (+50/-3)
  - path/to/file2.go  (+80/-0)  NEW

  Resumo: <1-2 frases do que esta categoria faz no PR>
```

### 4b — Ler e analisar

1. **Ler o diff** de cada arquivo da categoria
2. **Ler o arquivo completo** quando o diff não dá contexto suficiente
3. **Aplicar checklist** da categoria (Go ou Vue, conforme repo)
4. **Aplicar padrões suspeitos** do `templates/patterns.md`
5. **Cross-referenciar** com código existente no repo

### 4c — Apresentar findings

```
── Findings: <categoria> ─────────────────

  ✅ [item que está ok]
  ✅ [item que está ok]
  ⚠️ [warning — possível problema]
     → contexto: <explicação>
  🔴 [blocker — problema confirmado]
     → contexto: <explicação>
     → arquivo: <path>:<line>
  ❓ [pergunta para o dev]
     → contexto: <por que estou perguntando>
```

### 4d — Perguntar ao dev

Sempre terminar cada categoria com perguntas ou pedido de confirmação:

```
Dúvidas sobre esta categoria:
1. <pergunta específica sobre decisão de design>
2. <pergunta sobre comportamento esperado>

Quer que eu aprofunde em algum arquivo? Ou seguimos para <próxima categoria>?
```

**PARAR e aguardar resposta antes de ir para a próxima categoria.**

## Passo 5 — Hallucination detection

Para cada import, referência, ou path suspeito no PR:

### Go:
```bash
# Verificar se o pacote importado existe
ls /home/claude/projects/estrategia/monolito/<import_path> 2>/dev/null

# Verificar se a interface/tipo referenciado existe
grep -r "type <TypeName> " /home/claude/projects/estrategia/monolito/apps/<app>/
```

### Vue/Nuxt:
```bash
# Verificar se o componente importado existe
find /home/claude/projects/estrategia/<repo>/src/ -name "<ComponentName>.vue" 2>/dev/null

# Verificar se o service importado existe
find /home/claude/projects/estrategia/<repo>/src/ -path "*/services/<ServiceName>*" 2>/dev/null
```

Reportar hallucinations encontradas:

```
── Hallucination Check ───────────────────

  ❌ Import inexistente:
     arquivo: handlers/aluno/get.go:5
     import:  "github.com/estrategiahq/monolito/apps/ldi/internal/services/historico"
     → pacote "historico" NÃO existe em services/

  ❌ Tipo inexistente:
     arquivo: services/aluno/create.go:15
     tipo:    interfaces.AlunoHistoricoService
     → interface NÃO declarada em interfaces/

  ✅ Todos os outros imports verificados (18/18 existem)
```

## Passo 6 — Cross-reference com código existente

Para cada arquivo novo no PR, verificar se segue os padrões estabelecidos no mesmo app:

```bash
# Encontrar handlers existentes no mesmo pacote para comparar
ls /home/claude/projects/estrategia/monolito/apps/<app>/internal/handlers/<pkg>/

# Encontrar services existentes para comparar pattern
ls /home/claude/projects/estrategia/monolito/apps/<app>/internal/services/<svc>/
```

Comparar:
- Naming conventions (structs, funções, arquivos)
- Error handling pattern (usa `common.Err*`? `elogger`?)
- Request/response struct organization
- Swagger comment format
- Import organization

Reportar divergências:

```
── Pattern Compliance ────────────────────

  Handlers existentes usam: structs.HTTPResponse
  PR usa:                   custom JSON marshaling
  → Divergência: não segue o envelope padrão

  Services existentes usam: elogger.InfoErr
  PR usa:                   log.Printf
  → Divergência: logging fora do padrão
```

## Passo 7 — Gerar relatório

Criar artefato em `obsidian/artefacts/inspect-pr-<N>/`:

```
obsidian/artefacts/inspect-pr-<N>/
├── README.md          ← índice + frontmatter
└── report.md          ← relatório completo
```

Usar o formato definido em `templates/report.md`.

## Passo 8 — Veredito final

Apresentar resumo consolidado:

```
── Veredito Final — PR #<N> ──────────────

  🔴 Blockers:     <N>
  ⚠️ Warnings:     <N>
  💡 Sugestões:    <N>
  ✅ Clean:        <N categorias sem issues>

  Hallucinations:  <N encontradas>
  Pattern drift:   <N divergências>

  Recomendação: <APROVAR / APROVAR COM RESSALVAS / SOLICITAR MUDANÇAS / REJEITAR>

  Razão: <1-2 frases justificando>
```

Perguntar ao dev:

```
Concorda com o veredito? Quer que eu:
  1. Gere uma lista de comentários para postar no PR?
  2. Aprofunde em algum finding específico?
  3. Compare com outro PR do mesmo autor?
```

## Passo 9 — Evoluir conhecimento

**CRÍTICO: Esta é a parte que faz a skill melhorar ao longo do tempo.**

Após completar a inspeção, perguntar-se:
1. Descobri algum padrão suspeito novo que não está no `templates/patterns.md`?
2. Algum sinal de vibe-code que deveria checar em inspeções futuras?
3. Alguma heurística de hallucination detection que funcionou bem?

Se sim, **atualizar `templates/patterns.md`** adicionando a nova entrada:
```markdown
### [Título curto]
**Aprendido em:** inspeção de PR #<N> (<repo>) (YYYY-MM-DD)
**Sinal:** <como detectar>
**Risco:** <o que pode dar errado>
**Verificação:** <como confirmar>
```

## Regras

- **Interativo** — sempre parar e perguntar entre categorias. Nunca percorrer tudo sem input do dev.
- **Bottom-up** — começar pelas fundações (migrations, entities) e subir. Problemas na base afetam tudo acima.
- **Verificar, não assumir** — para cada import/referência suspeita, `ls`/`grep` para confirmar existência.
- **Construtivo** — é código de colega. Apontar problemas com contexto e sugestão.
- **Priorizar** — blockers primeiro, warnings depois, sugestões por último. Não soterrar findings importantes.
- **Evoluir knowledge** — cada inspeção deve melhorar a próxima via `templates/patterns.md`.
- **Responder em PT-BR** — artefatos e comunicação em português.
- **GitHub read-only** — nunca criar/editar/comentar no PR via API. Apenas ler.
