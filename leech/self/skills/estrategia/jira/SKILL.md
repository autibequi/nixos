---
name: estrategia/jira
description: Lê um card Jira da Estrategia com TODOS os campos relevantes. Use quando precisar ler, exibir ou analisar um card Jira (ex: FUK2-12090). Documenta a chamada MCP correta, o mapa de campos customizados, e como extrair texto de ADF.
---

# estrategia/jira: Ler Card Jira Completo

## Gatilhos — quando usar OBRIGATORIAMENTE

Invocar esta skill sempre que o usuário enviar qualquer um dos formatos abaixo:

- URL completa: `https://estrategia.atlassian.net/browse/FUK2-XXXXX`
- Chave do card: `FUK2-12273`, `FUK2-XXXX`, ou qualquer `<PROJETO>-<NÚMERO>`
- Pedido de refinamento: "refine essa", "analisa esse card", "sugestão de implementação"

**Nunca** sair investigando o codebase ou escrevendo sugestão sem antes ler a skill completa.

## Objetivo

Ler um card Jira do projeto Estrategia extraindo **todos** os campos relevantes de uma vez, sem precisar de múltiplas chamadas ou tentativas.

## Inputs

- Número do card Jira (ex: `FUK2-12090`, `FUK2-9719`)

## Cloud ID

```
9795b90e-d410-4737-a422-a7c15f9eadf0
```

Usar este UUID em todas as chamadas MCP Jira. **Não usar** a URL `estrategia.atlassian.net` como cloudId — funciona para algumas chamadas mas falha para outras.

---

## Passo 1 — Chamada MCP correta

```
mcp__claude_ai_Atlassian__getJiraIssue:
  cloudId: "9795b90e-d410-4737-a422-a7c15f9eadf0"
  issueIdOrKey: "<CARD-ID>"
  fields: ["*all"]
  expand: "names"
  responseContentFormat: "markdown"
```

### Por que cada parâmetro importa

| Parâmetro | Sem ele | Com ele |
|---|---|---|
| `fields: ["*all"]` | Retorna apenas 6 campos (summary, description, issuetype, project, status, assignee) | Retorna **todos** os 600+ campos incluindo custom fields |
| `expand: "names"` | Sem mapa de nomes — impossível saber qual customfield_XXXXX é qual | Retorna `names` map: `{ "customfield_11246": "Sugestão de Implementação", ... }` |
| `responseContentFormat: "markdown"` | Description em ADF (JSON verboso) | Description em markdown legível |

### Resultado grande — como lidar

A resposta com `fields: ["*all"]` tipicamente tem **70-100K chars** e será salva em arquivo pelo MCP. Usar `jq` para extrair dados:

```bash
FILE="<path-do-arquivo-salvo>"

# 1. Listar todas as keys de campo
cat "$FILE" | jq '.issues.nodes[0].fields | keys[]' -r

# 2. Extrair mapa de nomes (customfield_ID → nome legível)
cat "$FILE" | jq '.issues.nodes[0].names | to_entries | map(select(.key | startswith("customfield_"))) | map("\(.key) → \(.value)") | .[]' -r | sort

# 3. Extrair todos os campos não-null com preview
cat "$FILE" | jq '
.issues.nodes[0].fields | to_entries | map(select(.value != null and .value != "" and .value != [] and .value != {})) | map({key, value_preview: (
  if .value | type == "string" then (.value | .[0:200])
  elif .value | type == "number" then .value
  elif .value | type == "boolean" then .value
  elif .value | type == "array" then ("array[" + (.value | length | tostring) + "]")
  elif .value | type == "object" then (if .value.displayName then .value.displayName elif .value.name then .value.name elif .value.value then .value.value elif .value.total != null then ("total:" + (.value.total | tostring)) else (.value | keys | join(",")) end)
  else .value | tostring
  end
)}) | .[] | "\(.key): \(.value_preview)"
' -r

# 4. Extrair texto de campo ADF (ex: Sugestão de Implementação)
python3 -c "
import json, sys
with open('$FILE') as f:
    data = json.load(f)
field = data['issues']['nodes'][0]['fields']['customfield_11246']
def extract_text(node):
    texts = []
    if isinstance(node, dict):
        if 'text' in node: texts.append(node['text'])
        for v in node.values():
            if isinstance(v, (dict, list)): texts.extend(extract_text(v))
    elif isinstance(node, list):
        for item in node: texts.extend(extract_text(item))
    return texts
print(' '.join(extract_text(field)))
"
```

---

## Passo 2 — Mapa de campos relevantes para Engenharia

### Campos padrão do Jira

| Campo | Key | Tipo | Notas |
|---|---|---|---|
| Título | `summary` | string | |
| Descrição | `description` | string (markdown com `responseContentFormat: "markdown"`) ou ADF | |
| Tipo | `issuetype.name` | string | Task, Bug, Story, etc. |
| Status | `status.name` | string | "Em desenvolvimento", "Refinamento", etc. |
| Prioridade | `priority.name` | string | Alta, Média, Baixa |
| Assignee | `assignee.displayName` | string | |
| Reporter/Creator | `creator.displayName` | string | |
| Labels | `labels` | array[string] | Ex: ["Busca"] |
| Sprint | `customfield_10021` | object | |
| Story Points | `customfield_10023` | number | |
| Criado | `created` | datetime | |
| Atualizado | `updated` | datetime | |
| Due date | `duedate` | date | |
| Comentários | `comment.comments` | array | Autor + data + body ADF |
| Anexos | `attachment` | array | filename + content URL |
| Sub-tasks | `subtasks` | array | |
| Links | `issuelinks` | array | Tipo de relação + card linkado |

### Campos [Tech] — Engenharia (os que importam)

| Nome legível | Custom Field ID | Tipo | Descrição |
|---|---|---|---|
| **Sugestão de Implementação** | `customfield_11246` | ADF | Guia técnico de como implementar — CAMPO MAIS IMPORTANTE para engenharia |
| **DoD Engenharia** | `customfield_11258` | ADF | Critérios de aceite técnicos |
| **[Tech] Referência Engenharia** | `customfield_11331` | string/ADF | Links ou referências técnicas |
| **[Tech] Horizontal** | `customfield_11263` | string | Ex: "ÁreaAluno - Geral", "BO - Backoffice" |
| **[Tech] Frente de Produto** | `customfield_11266` | string | Ex: "Estudo / Consumo de Conteúdo" |
| **[Tech] Vertical** | `customfield_11315` | string | Vertical do produto |
| **[Tech] Estimativa Original** | `customfield_11322` | string | Ex: "13 \| entre 2 e 3 dias" |
| **.[Tech] Estimativa Restante** | `customfield_11330` | string | Mesma format da original |
| **[Tech] Complexidade de Engenharia** | `customfield_13883` | string | |
| **[Tech] Task Size** | `customfield_13884` | string | |
| **[Tech] Prioridade** | `customfield_11250` | string | Prioridade técnica (diferente da prioridade Jira) |
| **[Tech] Responsáveis Engenharia** | `customfield_11219` | array[user] | Devs responsáveis |
| **[Tech] Responsável Produto** | `customfield_11220` | array[user] | PM responsável |
| **[Tech] Responsáveis Design** | `customfield_11221` | array[user] | Designers |
| **[Tech] Responsáveis Refinamento** | `customfield_11321` | array[user] | Quem refinou |
| **[Tech] Refinado por** | `customfield_11248` | array[user] | Quem participou do refinamento |
| **[Tech] Dupla de Produto** | `customfield_11261` | string | |
| **PR causador do Bug** | `customfield_11247` | string/ADF | Se for bug — qual PR introduziu |
| **Design** | `customfield_11312` | string/ADF | Link do design (Figma etc) |
| **[tech] Decorrente de** | `customfield_11140` | string | Card que originou este |
| **[tech] Originado por** | `customfield_11141` | string | Outro card relacionado |

### Campos auxiliares úteis

| Nome legível | Custom Field ID | Tipo | Descrição |
|---|---|---|---|
| **Template de Descrição** | `customfield_11226` | ADF | Template/cópia da descrição |
| **Checklists** | `customfield_12682` | ADF | Checklists do card (Smart Checklist etc) |
| **Smart Checklist** | `customfield_13917` | string | Conteúdo de checklists |
| **Smart Checklist Progress** | `customfield_10109` | string | Ex: "0/1" |
| **Descrição (custom)** | `customfield_10915` | ADF | Campo "Descrição" customizado |
| **Observação** | `customfield_10916` | ADF | Observações adicionais |
| **Development** | `customfield_10000` | object | Links de desenvolvimento (PRs, branches) |
| **Notificar Engenharia?** | `customfield_11313` | string | Flag para notificar eng |

---

## Passo 3 — Extrair e apresentar

### Ordem de apresentação recomendada

1. **Header**: Card ID, título, tipo, status, prioridade, assignee
2. **Descrição**: campo `description` (já em markdown se usou `responseContentFormat: "markdown"`)
3. **Sugestão de Implementação** (`customfield_11246`): extrair texto de ADF — este é o campo mais valioso para engenharia
4. **DoD Engenharia** (`customfield_11258`): critérios técnicos
5. **Metadados Tech**: horizontal, vertical, frente de produto, estimativa, complexidade
6. **Pessoas**: responsáveis eng, produto, design, refinamento
7. **Comentários**: extrair texto de cada comment body (ADF)
8. **Links e sub-tasks**: cards relacionados
9. **Anexos**: listar filenames (não é possível baixar via MCP)

### Extração de texto de ADF

Campos ADF (Atlassian Document Format) são JSON com estrutura `{ type: "doc", version: 1, content: [...] }`. Para extrair texto legível:

```python
def extract_text(node):
    texts = []
    if isinstance(node, dict):
        if 'text' in node:
            texts.append(node['text'])
        for v in node.values():
            if isinstance(v, (dict, list)):
                texts.extend(extract_text(v))
    elif isinstance(node, list):
        for item in node:
            texts.extend(extract_text(item))
    return texts

text = ' '.join(extract_text(adf_field))
```

### Extração de usuários de campos array[user]

```bash
cat "$FILE" | jq '.issues.nodes[0].fields.customfield_11248 | map(.displayName)'
```

---

## Lições aprendidas

### Chamada sem `fields: ["*all"]` retorna lixo
A chamada padrão (sem `fields`) retorna **apenas 6 campos**: summary, description, issuetype, project, status, assignee. Todos os custom fields ficam de fora. **Sempre usar `fields: ["*all"]`.**

### `expand: "names"` sem `fields: ["*all"]` também é inútil
O mapa `names` só inclui os campos que foram retornados. Se só vieram 6 campos, o mapa tem 6 entradas. Precisa combinar os dois.

### `responseContentFormat: "markdown"` só afeta `description`
Os custom fields ADF (como Sugestão de Implementação) continuam em formato ADF mesmo com markdown mode. Precisa extrair texto manualmente.

### Resultado > 70K chars é normal
Com `fields: ["*all"]`, a resposta tipicamente excede o limite de tokens e é salva em arquivo. Usar `jq` para navegar — nunca tentar ler o JSON bruto.

### IDs de campo NÃO mudam entre instâncias do Estrategia
Diferente do que é dito na documentação genérica do Jira, os IDs dos custom fields são estáveis na instância da Estrategia. Os IDs listados neste documento foram validados e podem ser usados diretamente. O mapa `names` serve como verificação, não como lookup obrigatório.

### Comentários automáticos vs humanos
O campo `comment.comments[].author.accountType` indica se é `"app"` (automação) ou `"atlassian"` (humano). Comentários de automação (ex: "Automation for Jira") geralmente são regras de workflow, não contexto útil.

### Anexos não podem ser baixados via MCP
O MCP Atlassian não suporta download de attachments. O `fetchAtlassian` só aceita ARIs de issues e pages. Se o card tiver imagens importantes, pedir ao dev que envie no chat.

### `searchAtlassian` requer app instalada
A busca Rovo (`searchAtlassian`) pode falhar com 403 "The app is not installed". Usar `searchJiraIssuesUsingJql` como alternativa para buscas.

---

## Referência rápida — Chamadas MCP disponíveis

| Tool | Uso |
|---|---|
| `getJiraIssue` | Ler card completo (com `fields: ["*all"]`, `expand: "names"`) |
| `editJiraIssue` | Atualizar campos de um card |
| `addCommentToJiraIssue` | Adicionar comentário |
| `searchJiraIssuesUsingJql` | Buscar cards com JQL |
| `getTransitionsForJiraIssue` | Ver transições disponíveis |
| `transitionJiraIssue` | Mover card de status |
| `atlassianUserInfo` | Obter account ID do usuário autenticado |
| `lookupJiraAccountId` | Buscar account ID por nome/email |
| `getVisibleJiraProjects` | Listar projetos acessíveis |
| `getJiraProjectIssueTypesMetadata` | Tipos de issue de um projeto |
| `getJiraIssueTypeMetaWithFields` | Campos obrigatórios para criar issue |
| `createJiraIssue` | Criar novo card |
| `createIssueLink` | Linkar dois cards |
| `getIssueLinkTypes` | Tipos de link disponíveis |
| `getJiraIssueRemoteIssueLinks` | Links externos do card |
| `addWorklogToJiraIssue` | Registrar tempo |
| `fetchAtlassian` | Ler recurso por ARI (issue ou page) |

Todas as chamadas usam `cloudId: "9795b90e-d410-4737-a422-a7c15f9eadf0"`.

---

## Escrever Sugestão de Implementação (customfield_11246)

Quando for solicitado a preencher ou refinar a Sugestão de Implementação de um card, usar o template abaixo com os 7 blocos padrão, **sempre precedido de um banner ASCII**.

### Banner ASCII

O banner fica no início do campo, dentro de um `codeBlock` ADF com `language: "text"`. **Variar o estilo do banner a cada vez** — escolher um dos abaixo ou criar uma variação criativa com o mesmo tema "REFINED BY CLAUDINHO":

**Variação 1 (pixel bold):**
```
█▀█ █▀▀ █▀▀ █ █▄ █ █▀▀ █▀▄   █▄▄ █▄█
█▀▄ ██▄ █▀  █ █ ▀█ ██▄ █▄▀   █▄█  █

█▀▀ █   █▀█ █ █ █▀▄ █ █▄ █ █ █ █▀█
█▄▄ █▄▄ █▀█ █▄█ █▄▀ █ █ ▀█ █▀█ █▄█
```

**Variação 2 (box drawing):**
```
╦═╗╔═╗╔═╗╦╔╗╔╔═╗╔╦╗  ╔╗ ╦ ╦
╠╦╝║╣ ╠╣ ║║║║║╣  ║║  ╠╩╗╚╦╝
╩╚═╚═╝╚  ╩╝╚╝╚═╝═╩╝  ╚═╝ ╩
╔═╗╦  ╔═╗╦ ╦╔╦╗╦╔╗╔╦ ╦╔═╗
║  ║  ╠═╣║ ║ ║║║║║║╠═╣║ ║
╚═╝╩═╝╩ ╩╚═╝═╩╝╩╝╚╝╩ ╩╚═╝
```

**Regra:** não repetir o mesmo banner duas vezes seguidas. Pode criar novas variações ASCII desde que legíveis e no tema "refined by claudinho" (ou abreviações/variações criativas como "REFIND BY CLAU", "CLAUDINHO WAS HERE", etc.).

---

### Template dos 7 blocos

```
1. Descrição da Solução
   Explicação direta do que está errado/faltando e o que precisa ser feito.
   Mencionar causa raiz se for bug.

2. Componentes / Arquivos Impactados
   Aplicações / Serviços
   - [repo] path/to/file:linha — Método() — por que é relevante

   Banco de Dados
   - tabela, coluna, migration relevante (ou N/A)

   OpenSearch
   - índice afetado, campos (ou N/A)

3. Dependências Externas
   - Serviços externos, feature flags, Redis keys, etc. (ou "Nenhuma")

4. Sugestão de Testes
   Happy Path:
   - [cenário de sucesso 1]

   Sad Path:
   - [cenário de erro/edge case 1]

5. Contratos de API
   - [método HTTP + path + mudanças no payload/response] (ou N/A)

6. Referências Técnicas
   - Links, PRs, cards relacionados, comentários de devs relevantes

7. Restrições / Impactos a Evitar
   - O que NÃO deve ser alterado
   - Efeitos colaterais a monitorar
```

---

### Estrutura ADF completa para `editJiraIssue`

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {
      "type": "codeBlock",
      "attrs": { "language": "text" },
      "content": [{ "type": "text", "text": "<BANNER AQUI — escolher variação>" }]
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
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "[repo] path/file:linha — Método() — relevância" }] }]
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
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "[conteúdo ou N/A]" }] }]
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
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "[conteúdo ou N/A]" }] }]
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
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "[conteúdo ou Nenhuma]" }] }]
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
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "[cenário dinâmico]" }] }]
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
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "[cenário dinâmico]" }] }]
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
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "[conteúdo ou N/A]" }] }]
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
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "[links, PRs, cards]" }] }]
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
          "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "[conteúdo dinâmico]" }] }]
        }
      ]
    }
  ]
}
```

### Quando preencher — REGRA OBRIGATÓRIA

**Nunca salvar no Jira sem autorização explícita do dev.** Mesmo que a sugestão esteja pronta, sempre mostrar o conteúdo no terminal e aguardar confirmação antes de chamar `editJiraIssue`.

Exceção: se o dev disser explicitamente "pode salvar", "salva direto", "sem confirmação" ou equivalente — aí pode prosseguir sem pedir.

### Append vs Replace

Antes de escrever, ler o conteúdo atual do campo (`customfield_11246`) e avaliar:

| Situação | Ação |
|---|---|
| Campo vazio ou `null` | Escrever do zero com a estrutura completa |
| Campo tem só template vazio (placeholders como `[conteúdo]`, `[preencher]`) | Substituir — não tem valor real |
| Campo tem conteúdo gerado por automação sem valor (lixo de workflow) | Substituir |
| Campo tem conteúdo real escrito por humano ou refinamento anterior | **Append** — adicionar `rule` + banner + novo conteúdo abaixo. Nunca sobrescrever. |

**Dúvida?** Se não for óbvio que o conteúdo existente é lixo/template, tratar como conteúdo real e fazer append.

### Marcar "Refinado por" ao salvar

Sempre que salvar a Sugestão de Implementação, também atualizar o campo **"Refinado por"** (`customfield_11248`) com o usuário autenticado no momento:

1. Chamar `atlassianUserInfo` para obter o `accountId` do usuário conectado — **nunca perguntar o nome, nunca usar `lookupJiraAccountId`**
2. Ler o valor atual de `customfield_11248` (array de usuários)
3. Adicionar o novo usuário à lista se ainda não estiver (append, nunca replace)
4. Atualizar via `editJiraIssue` com formato: `[{ "accountId": "..." }, ...]`

Isso garante que toda sugestão escrita tenha um responsável registrado e não fique solta no card.
