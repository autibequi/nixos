---
name: orquestrador/refinar-bug
description: Use when the developer wants to refine a Bug card in Jira. Reads the card, investigates the relevant repositories (any of the 19 repos in the Estrategia ecosystem — not just the core 3), finds code references (file, line, method), and fills the "Sugestão de Implementação" field with a structured ADF template. Uses estrategia/ecosystem-map to route to the correct repos when the bug involves mobile, search, ecommerce, accounts, webcasts, etc.
---

# refinar-bug: Refinar Card de Bug no Jira

## Objetivo

Investigar os repositórios relevantes para um card de Bug (qualquer repo do ecossistema Estratégia — pode ser 1 ou mais), encontrar referências de código (arquivo, linha, método), e preencher o campo "Sugestão de Implementação" (resolvido pelo nome via `names` map) no Jira com um template estruturado em ADF.

**Ecossistema completo:** ver `coruja/ecosystem-map` para o mapa dos 19 repos com stack, proposito e tabela de pistas-para-repo.

## Inputs

Recebe o número do card Jira (ex: `FUK2-9719`).

## Cloud ID

Todas as chamadas Jira usam: `9795b90e-d410-4737-a422-a7c15f9eadf0`

## Passo 0 — Plan Mode Obrigatório

Chamar `EnterPlanMode` imediatamente antes de qualquer ação.
Sair apenas após aprovação explícita do dev.
Exceção: se invocado dentro de fluxo Orquestrador já aprovado, pular.

## Passo 1 — Ler o card Jira

1. Buscar o card com `getJiraIssue`:
   - `issueIdOrKey`: o ID recebido
   - `cloudId`: `9795b90e-d410-4737-a422-a7c15f9eadf0`
   - `fields`: `["*all"]`
   - `expand`: `"names"`

2. **Validar tipo:** verificar se `issuetype.name` é "Bug" (ou variações como "bug", "Defeito"). Se **não** for Bug, avisar o dev:
   ```
   Este card é do tipo "[tipo]", não Bug.
   Deseja prosseguir com o refinamento mesmo assim?
   ```
   Só continuar com confirmação explícita.

3. **Extrair informações do card:**
   - `summary` — título do bug
   - `description` — descrição em ADF (extrair texto recursivamente dos nós `content[].text`)
   - `comment` — comentários (autor + data + conteúdo ADF)
   - `issuelinks` — cards relacionados
   - `attachment` — imagens/arquivos anexados

4. **Extrair custom fields pelo NOME, não pelo ID.** O mapa `names` retornado pelo `expand: "names"` mapeia IDs de campo → nomes legíveis. Iterar sobre `names` para encontrar o ID de cada campo desejado (case-insensitive). **Nunca hardcodar IDs de campo** como `customfield_11246` — IDs podem mudar entre instâncias do Jira. O nome é a fonte de verdade.

   **Campos a localizar pelo nome:**

   | Nome do campo (buscar no `names` map) | Uso |
   |---|---|
   | **Sugestão de Implementação** | Campo-alvo que será preenchido |
   | **PR causador do Bug** | Contexto: qual PR introduziu o bug |
   | **DoD Engenharia** | Critérios de aceite técnicos |
   | **[Tech] Referência Engenharia** | Links ou referências técnicas |
   | **Refinado por** | Campo para registrar quem refinou (Passo 6b) |

   **Procedimento:**
   ```
   Para cada nome desejado:
     1. Percorrer o mapa `names` procurando (case-insensitive) o nome
     2. O key correspondente é o field ID real (ex: "customfield_11246")
     3. Usar esse ID para ler/escrever o campo em `fields`
   ```

   Guardar os IDs resolvidos para uso nos Passos 2 e 6.

5. **Se o card não puder ser carregado:** pedir ao dev que cole a descrição e seguir com ela.

## Passo 2 — Verificar se o campo já tem conteúdo humano

### Lógica de detecção

1. Extrair todo texto do ADF do campo "Sugestão de Implementação" (usando o ID resolvido no Passo 1)
2. Remover:
   - Os 7 headers do template (`Descrição da Solução`, `Componentes / Arquivos Impactados`, `Dependências Externas`, `Sugestão de Testes`, `Contratos de API`, `Referências Técnicas`, `Restrições / Impactos a Evitar`)
   - Sub-headers (`Aplicações / Serviços`, `Banco de Dados`, `OpenSearch`, `Happy Path`, `Sad Path`)
   - Placeholders comuns: `TODO`, `N/A`, `TBD`, `[Descrever aqui]`, `- `
   - Numeração (`1.`, `2.`, etc.)
   - Whitespace
3. Se o texto restante tiver **>50 caracteres** → é conteúdo humano

### Ações por condição

| Condição | Ação |
|---|---|
| Campo `null`, vazio, ou `undefined` | Prosseguir sem aviso |
| Campo só tem headers/placeholders do template (<=50 chars restantes) | Prosseguir sem aviso |
| Campo tem conteúdo humano (>50 chars restantes) | **AVISAR o dev** — ver abaixo |

### Quando detectar conteúdo humano

Mostrar ao dev:

```
── CONTEÚDO EXISTENTE DETECTADO ──

O campo "Sugestão de Implementação" já contém
conteúdo preenchido por um humano:

  "[preview dos primeiros 200 chars...]"

Opções:
  1. Sobrescrever — substitui tudo pelo refinamento
  2. Complementar — preserva o existente, adiciona
     as descobertas abaixo (com separador visual)
  3. Cancelar — não altera o campo

Qual opção?
```

Só prosseguir após escolha explícita. Se `Cancelar`, encerrar a skill com mensagem amigável.

## Passo 3 — Investigar o codebase

**Nem todo bug envolve todos os repositórios.** A investigação é direcionada — pode envolver 1, 2 ou 3 repos dependendo do contexto do card. Não investigar repos irrelevantes.

### 3a — Extrair keywords do bug

A partir da description, summary, comments e custom fields, extrair:
- Nomes de tela ou página (ex: "tela de histórico", "página do aluno")
- URLs ou paths de API (ex: `/bo/alunos/`, `/bff/shelf/`)
- Nomes de entidades ou tabelas (ex: `alunos`, `shelf_items`, `AlunoService`)
- Mensagens de erro (ex: "erro ao salvar", "500 Internal Server Error")
- Nomes de componentes ou módulos (ex: `AlunoModal`, `ShelfPage`)

**Atenção especial aos comentários de devs/engenheiros** — frequentemente contêm o diagnóstico mais preciso da causa raiz, com termos técnicos específicos (nomes de tabela, índice, worker) que não aparecem na descrição do card. Priorizar keywords extraídas de comentários técnicos.

### 3b — Determinar repos a investigar

**PRIMEIRO:** Ler `coruja/ecosystem-map` quando o card envolver qualquer horizontal fora do trio principal (mobile, busca, ecommerce, questoes, accounts, webcast, toggler, user-access). O ecosystem-map tem a tabela definitiva de pistas → repos para todos os 19 repos.

Tabela resumida para os casos mais comuns:

| Pista no card | Repos a investigar |
|---|---|
| "BO", "backoffice", "operador", "professor" | `bo-container/` + `monolito/apps/bo/` |
| "aluno", "área do aluno", "front" | `front-student/` + `monolito/apps/bff/` |
| "APP", "mobile", "aplicativo", "iOS", "Android" | `mobile-estrategia-educacional/` + `monolito/apps/bff_mobile/` |
| "LDI", "capitulo", "item", "bloco", "video LDI" | `monolito/apps/ldi/` + `front-student/modules/ldi-poc/` |
| "questao", "caderno", "simulado" | `monolito/apps/questoes/` + `questions/` |
| "compra", "pedido", "produto", "cupom" | `ecommerce/` + `monolito/apps/ecommerce/` |
| "busca", "search", "OpenSearch", "indexacao" | `search/` + `monolito/apps/search/` |
| "webcast", "live", "streaming" | `WebCasts/` |
| API, endpoint, dados, DB, migration, worker | `monolito/` somente |
| Bug visual, CSS, layout, componente | Frontend afetado somente |
| Sem pista clara | Comecar pelo `monolito/`, expandir se necessario |

**Exemplos de decisao:**
- Bug "aluno nao consegue ver certificado" → `front-student/` + `monolito/apps/bff/`
- Bug "erro ao salvar no backoffice" → `bo-container/` + `monolito/apps/bo/`
- Bug "video nao carrega no app" → `mobile-estrategia-educacional/` + `monolito/apps/bff_mobile/` + `monolito/apps/ldi/`
- Bug "migration falhou" → `monolito/` somente
- Bug "botao nao funciona na tela X" → investigar o frontend relevante, adicionar `monolito/` so se a causa parecer ser do backend

### 3c — Busca em ondas

Lançar **Explore agents em paralelo apenas nos repos selecionados no 3b** (1 agent por repo):

**Onda 1 — Busca direta:**
- Grep termos específicos: mensagens de erro, nomes de método, paths de endpoint
- Glob por nomes de arquivo mencionados

**Onda 2 — Rastrear dependências:**
- Ler arquivos encontrados na onda 1
- Traçar cadeia: handler → service → repository → DB (monolito)
- Traçar cadeia: page → container → service → API call (frontends)

**Onda 3 — Ampliar busca (se ondas 1-2 insuficientes):**
- Buscar por nomes de entidade/tabela
- Buscar por nomes de rota/módulo
- Buscar em arquivos de configuração e registro de rotas

### 3d — Registrar referências encontradas

Para **cada arquivo relevante**, registrar:
- **Path relativo** (ex: `monolito/apps/cast/internal/repositories/shelf/repository.go`)
- **Número da linha** (ou range de linhas)
- **Nome do método/função** (ex: `func (r *Repository) FindByID(ctx, id) (*Entity, error)`)
- **Relevância** — por que este arquivo/método é relevante para o bug (1 linha)

## Passo 4 — Montar a sugestão

### Estrutura do conteúdo

```
[Banner ASCII "refined by vennon"]

1. Descrição da Solução
   [O que precisa ser feito para corrigir o bug — 2-5 frases]

2. Componentes / Arquivos Impactados
   Aplicações / Serviços:
   - [repo] path/to/file.go:42 — MétodoX() — [o que faz]
   - [repo] path/to/file.vue:15 — ComponenteY — [o que faz]

   Banco de Dados:
   - [tabela] — [o que precisa mudar, se aplicável]
   - N/A (se não há mudanças em DB)

   OpenSearch:
   - [índice] — [o que precisa mudar, se aplicável]
   - N/A (se não há mudanças em OpenSearch)

3. Dependências Externas
   - [serviço externo, se aplicável]
   - Nenhuma (se não há)

4. Sugestão de Testes
   Happy Path:
   - [cenário de sucesso 1]
   - [cenário de sucesso 2]

   Sad Path:
   - [cenário de erro 1]
   - [cenário de erro 2]

5. Contratos de API
   - [endpoint afetado: método HTTP, path, mudanças no payload/response]
   - N/A (se não há mudanças de contrato)

6. Referências Técnicas
   - [link para doc, PR causador, card relacionado]

7. Restrições / Impactos a Evitar
   - [o que NÃO deve ser afetado pela correção]
   - [efeitos colaterais a monitorar]
```

### Banner ASCII

O banner é um `codeBlock` ADF com linguagem `"text"`:

```
█▀█ █▀▀ █▀▀ █ █▄ █ █▀▀ █▀▄   █▄▄ █▄█
█▀▄ ██▄ █▀  █ █ ▀█ ██▄ █▄▀   █▄█  █

█▀▀ █   █▀█ █ █ █▀▄ █ █▄ █ █ █ █▀█
█▄▄ █▄▄ █▀█ █▄█ █▄▀ █ █ ▀█ █▀█ █▄█
```

## Passo 5 — Apresentar ao dev para aprovação

Mostrar a sugestão completa formatada no terminal:

```
── REFINAMENTO: FUK2-XXXX ──
── [título do card] ──

Repos investigados: [apenas os que foram de fato investigados]
  monolito ─────────┐
  front-student ────┘── N arquivos encontrados

Arquivos referenciados: N total
  [repo1]:  N
  [repo2]:  N

── SUGESTÃO ──

[conteúdo completo da sugestão, formatado como aparecerá no Jira]

── FIM DA SUGESTÃO ──

Aprovar e salvar no Jira? (sim/não)
```

**Nunca salvar no Jira sem confirmação explícita do dev.**

## Passo 6 — Salvar no Jira

### 6a — Atualizar Sugestão de Implementação

Usar `editJiraIssue` para atualizar o campo "Sugestão de Implementação" (usando o ID resolvido pelo `names` map no Passo 1) com o conteúdo em ADF.

**Estrutura ADF completa:**

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "codeBlock",
      "attrs": { "language": "text" },
      "content": [
        {
          "type": "text",
          "text": "█▀█ █▀▀ █▀▀ █ █▄ █ █▀▀ █▀▄   █▄▄ █▄█\n█▀▄ ██▄ █▀  █ █ ▀█ ██▄ █▄▀   █▄█  █\n\n█▀▀ █   █▀█ █ █ █▀▄ █ █▄ █ █ █ █▀█\n█▄▄ █▄▄ █▀█ █▄█ █▄▀ █ █ ▀█ █▀█ █▄█"
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "1. Descrição da Solução" }]
    },
    {
      "type": "paragraph",
      "content": [{ "type": "text", "text": "[conteúdo dinâmico]" }]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "2. Componentes / Arquivos Impactados" }]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "Aplicações / Serviços" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "[repo] path/to/file:line — Método() — relevância" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "Banco de Dados" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "[conteúdo dinâmico ou N/A]" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "OpenSearch" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "[conteúdo dinâmico ou N/A]" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "3. Dependências Externas" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "[conteúdo dinâmico ou Nenhuma]" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "4. Sugestão de Testes" }]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "Happy Path" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "[cenário dinâmico]" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 3 },
      "content": [{ "type": "text", "text": "Sad Path" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "[cenário dinâmico]" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "5. Contratos de API" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "[conteúdo dinâmico ou N/A]" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "6. Referências Técnicas" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "[links, PRs, cards relacionados]" }]
            }
          ]
        }
      ]
    },
    {
      "type": "heading",
      "attrs": { "level": 2 },
      "content": [{ "type": "text", "text": "7. Restrições / Impactos a Evitar" }]
    },
    {
      "type": "bulletList",
      "content": [
        {
          "type": "listItem",
          "content": [
            {
              "type": "paragraph",
              "content": [{ "type": "text", "text": "[conteúdo dinâmico]" }]
            }
          ]
        }
      ]
    }
  ]
}
```

**Notas sobre o ADF:**
- Cada seção de conteúdo dinâmico deve ser construída com os dados reais da investigação
- `bulletList` deve conter um `listItem` por referência de arquivo/teste/restrição
- Para referências de código, usar formato: `[repo] path/to/file:linha — Método() — por que é relevante`
- Se a opção do Passo 2 foi "Complementar":
  1. Ler o ADF existente do campo (o objeto `{ type: "doc", version: 1, content: [...] }`)
  2. Fazer **append** ao array `content` existente — nunca substituir
  3. Adicionar nesta ordem: `rule` (separador) → `codeBlock` (banner ASCII) → headings e conteúdo da investigação
  4. O ADF final enviado ao Jira deve ser: `{ type: "doc", version: 1, content: [...conteúdo_existente, rule, banner, ...conteúdo_novo] }`

### 6b — Adicionar dev ao campo "Refinado por"

1. Usar `atlassianUserInfo` (MCP) para obter o account ID do usuário ativo automaticamente:
   - **Nunca perguntar o nome do dev** — sempre resolver via MCP
   - **Nunca usar `lookupJiraAccountId`** — usar `atlassianUserInfo` que retorna o usuário autenticado diretamente

2. Usar `editJiraIssue` para atualizar o campo "Refinado por" (usando o ID resolvido pelo `names` map no Passo 1):
   - **Preservar usuários existentes** na lista (append, não replace)
   - Primeiro ler o valor atual do campo, depois adicionar o novo usuário à lista
   - Formato do campo: array de objetos `{ "accountId": "..." }`

## Passo 7 — Confirmação final

Mostrar resumo visual:

```
── REFINAMENTO CONCLUÍDO: FUK2-XXXX ──

Card:  [título do bug]
Campo: Sugestão de Implementação ── atualizado
Repos: [lista de repos investigados]

Arquivos referenciados: N
  monolito:       N
  bo-container:   N
  front-student:  N

Refinado por: [nome do dev] ── adicionado
```

## Regras

- **Nunca salvar no Jira sem confirmação explícita** — sempre apresentar o conteúdo ao dev primeiro
- **Detectar conteúdo humano** antes de sobrescrever — respeitar trabalho existente
- **Investigar o codebase de verdade** — não inventar referências de arquivo/linha
- **Registrar arquivo + linha + método** para cada referência — ser específico
- **Usar Explore agents** para investigação profunda nos repos — não ficar limitado a Grep superficial
- **ADF bem formado** — testar a estrutura antes de enviar ao Jira
- **Preservar usuários existentes** no campo "Refinado por" — nunca sobrescrever a lista
- **Usar `atlassianUserInfo`** do MCP para obter o account ID do dev — nunca perguntar o nome, nunca usar `lookupJiraAccountId`
- **Resolver campos Jira pelo NOME** via `names` map — nunca hardcodar IDs como `customfield_11246`
- **Investigar apenas repos relevantes** — analisar pistas do card para decidir quais repos investigar (pode ser 1, 2 ou 3)

## Lições aprendidas

Aprendizados de refinamentos anteriores que melhoram a qualidade:

### Bugs com múltiplas camadas
- Um bug pode ter causas raiz em **camadas diferentes** (ex: backend não indexa um campo E frontend sobrescreve a ordenação com sort alfabético). Investigar apenas um repo pode perder metade do problema.
- Mesmo quando o card aponta claramente para um repo (ex: "falta indexar no search"), sempre avaliar se o frontend consumidor tem lógica própria que agrava ou mascara o bug.

### Complementar vs sobrescrever
- Quando o refinamento humano existente tem o **diagnóstico direcional correto** mas falta referências de código, a opção "Complementar" agrega mais valor — preserva a análise de quem conhece o domínio e adiciona os detalhes técnicos (arquivo, linha, método) que aceleram a implementação.

### Fluxos paralelos no mesmo sistema
- Atentar para quando o mesmo dado é servido por **dois caminhos diferentes** (ex: endpoint direto via PostgreSQL vs endpoint via OpenSearch). O bug pode existir em apenas um dos caminhos, o que dificulta a reprodução e confunde o diagnóstico.

### Parsing do resultado do Jira
- O resultado de `getJiraIssue` com `fields: ["*all"]` e `expand: "names"` pode ser muito grande (>100K chars). Usar um script Node.js intermediário (salvar em `/tmp/`) para extrair os campos relevantes ao invés de tentar ler o JSON bruto. O bash do container escapa `!` em node `-e`, então sempre usar arquivo `.js` separado.

### Imagens/anexos do card
- O MCP Atlassian **não suporta download de attachments** — o tool `fetch` só aceita ARIs de issues e pages, não de attachments. Os IDs de anexo são interpretados como IDs de issue, retornando dados errados.
- Se o card contiver screenshots ou imagens relevantes para o diagnóstico e a descrição textual não for suficiente para entender o problema com clareza, **pedir ao dev que envie os prints diretamente na conversa** antes de prosseguir com a investigação.
