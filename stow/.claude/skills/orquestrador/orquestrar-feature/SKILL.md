---
name: orquestrador/orquestrar-feature
description: Use when receiving a Jira card number to implement a feature across one or more repositories (monolito, bo-container, front-student). Reads the card, investigates current state, creates feature files in the root, negotiates with the dev, then delegates to subagents.
---

# orquestrar-feature: Orquestrar Feature Cross-Repositório

## Templates

Antes de executar esta skill, **ler todos os templates** listados abaixo. Eles contêm o conteúdo que será usado para criar os arquivos de controle e os prompts dos subagentes.

| Arquivo | Descrição |
|---|---|
| `templates/feature.md` | Template do arquivo central de progresso da feature |
| `templates/feature-monolito.md` | Template de instruções para o subagente do monolito |
| `templates/feature-bo.md` | Template de instruções para o subagente do bo-container |
| `templates/feature-frontstudent.md` | Template de instruções para o subagente do front-student |
| `templates/subagent.monolito.md` | Prompt para lançar o subagente do monolito |
| `templates/subagent.bo.md` | Prompt para lançar o subagente do bo-container |
| `templates/subagent.frontstudent.md` | Prompt para lançar o subagente do front-student |

Todos os templates estão na subpasta `templates/` deste diretório.

## Passo 0 — Entrar em modo de planejamento

Chamar `EnterPlanMode` **imediatamente**, antes de qualquer outra ação.

Permanecer em plan mode durante os Passos 1 a 4. Nenhum arquivo será criado, nenhum comando executado, nenhuma branch criada enquanto o plano não estiver aprovado.

Só chamar `ExitPlanMode` após o dev confirmar **explicitamente** que o plano está aprovado e os arquivos de instruções podem ser criados (ex: "pode criar os arquivos", "aprovado", "pode seguir", "ok").

## Inputs

Recebe apenas o número do card Jira (ex: `FUK2-1234`).

## Pasta de controle da feature

Cada feature tem sua própria pasta na raiz do monorepo, nomeada seguindo o padrão:

- **Com Jira ID:** `FUK2-<Codigo>` (ex: `FUK2-1234/`)
- **Sem Jira ID:** `FUK2-<descricao-curta>` em kebab-case (ex: `FUK2-bloqueio-edicao-toc-rebuild/`)

Dentro da pasta ficam todos os arquivos de controle:

| Arquivo | Propósito |
|---|---|
| `feature.md` | Visão geral, progresso centralizado, dúvidas |
| `feature.monolito.md` | Instruções completas para o subagente do monolito |
| `feature.bo.md` | Instruções completas para o subagente do bo-container |
| `feature.frontstudent.md` | Instruções completas para o subagente do front-student |

Isso permite ter múltiplas features organizadas simultaneamente.

Os subagentes recebem o caminho completo da pasta no prompt e leem/atualizam **apenas o seu próprio arquivo** — nunca o `feature.md`. O orquestrador é responsável por atualizar o `feature.md` após cada subagente concluir.

## Passo 1 — Ler o card e todos os links

1. Buscar o card Jira pelo número usando MCP Jira **com `fields: ["*all"]` e `expand: "names"`**. A chamada padrão (sem `fields`) retorna apenas 6 campos e **omite custom fields críticos** como a Sugestão de Implementação.
2. **Extrair custom fields relevantes pelo NOME** (não pelo ID, pois IDs podem mudar). Usar o mapa `names` retornado pelo `expand: "names"` para localizar os campos abaixo. O conteúdo de campos ADF deve ser extraído recursivamente dos nós `content[].text`.

   **Campos a procurar (por nome, case-insensitive):**

   | Nome do campo | Prioridade | Pra que serve |
   |---|---|---|
   | **Sugestão de Implementação** | CRÍTICO | Guia técnico de como implementar — ver seção abaixo |
   | **DoD Engenharia** | Alta | Critérios de aceite técnicos específicos de engenharia |
   | **[Tech] Referência Engenharia** | Média | Links ou referências técnicas adicionais |
   | **[Tech] Horizontal** | Contexto | Qual horizontal/sistema é afetado (ex: "LDI") |
   | **[Tech] Frente de Produto** | Contexto | Qual frente de produto (ex: "Estudo / Consumo de Conteúdo") |
   | **PR causador do Bug** | Se bug | Link do PR que causou o bug (quando aplicável) |
   | **Checklists** | Baixa | Checklists adicionais do card |

   Se algum desses campos tiver valor, incluir no contexto da feature. Se nenhum tiver, seguir normalmente.

3. **Se o card não puder ser carregado:**
   - Informar o dev que o Jira não respondeu
   - Pedir que o dev cole a descrição do card (título, descrição, critérios de aceite)
   - Prosseguir com a descrição colada — o Jira ID ainda é usado para nomes de pasta e branch
   - Se o dev não tiver a descrição: perguntar o que a feature deve fazer e construir o escopo a partir da conversa
4. Ler a descrição, critérios de aceite, e **todos os links** associados:
   - Páginas Notion
   - Designs (Figma, etc.)
   - Cards relacionados ou sub-tasks
5. Se algum link não puder ser lido automaticamente, pedir ao dev que cole o conteúdo

### Links de Notion e Figma encontrados no card

**Sempre ler o conteúdo completo** de qualquer link Notion ou Figma encontrado na description ou nos custom fields do card. Esses links frequentemente contêm spikes, documentação técnica, análises de performance e diagramas que são essenciais para o planejamento.

**Procedimento:**

1. **Extrair todos os links** da description (markdown `[texto](url)`) e dos custom fields ADF (nós `marks.type: "link"`)
2. **Para cada link Notion encontrado:** usar `mcp Notion fetch` para ler o conteúdo completo da página. Notion retorna texto, código, tabelas e referências a imagens.
3. **Para imagens dentro de páginas Notion:** as imagens vêm como URLs S3 temporárias (`prod-files-secure.s3...`) que **podem ser baixadas** via `WebFetch`. Após o download, usar `Read` no arquivo salvo para analisar visualmente (screenshots de performance, diagramas, fluxogramas).
4. **Para cada link Figma encontrado:** tentar abrir via `WebFetch`. Se não funcionar, pedir ao dev para compartilhar prints das telas relevantes.
5. **Para links de cards Jira relacionados** (ex: spikes, blockers): ler via MCP Jira com `fields: ["*all"]` e `expand: "names"` — o mesmo procedimento do card principal.
6. **Incorporar ao plano:** o conteúdo lido deve alimentar diretamente o Passo 2 (escopo), o Passo 3 (feature.md) e os `feature.X.md` dos subagentes. Não ler esses links e depois ignorá-los — eles existem no card por um motivo.

### Imagens e attachments do card

O campo `attachment` (retornado com `fields: ["*all"]`) contém a lista de arquivos anexados ao card, incluindo imagens (fluxogramas, diagramas, mockups). Cada attachment tem uma URL de conteúdo no campo `content`.

**Procedimento para cada imagem encontrada:**

1. **Sempre tentar baixar** a imagem via `WebFetch` usando a URL do campo `content` do attachment. O MCP pode evoluir e passar a suportar isso.
2. **Se o download falhar** (403, timeout, etc.), pedir ao dev:
   ```
   O card tem [N] imagem(ns) anexada(s) que não consegui baixar automaticamente:
   - [filename1]
   - [filename2]
   Pode colar como print screen aqui no chat para que eu possa analisar?
   ```
3. **Se o dev enviar a imagem**, analisar o conteúdo (diagrama de fluxo, arquitetura, mockup, etc.) e incorporar as informações ao plano.
4. **Imagens na description** também devem ser verificadas — a description renderizada pode conter `<img src="...">` com URLs de attachments. Cruzar com a lista de attachments para não pedir duplicados.

### Comentários do card

O campo `comment` (retornado com `fields: ["*all"]`) contém todos os comentários do card em formato ADF. Comentários frequentemente contêm decisões técnicas, mudanças de escopo, respostas a dúvidas ou ações definidas em reunião.

**Procedimento:**

1. Extrair o texto de cada comentário (autor + data + conteúdo ADF)
2. Identificar informações que impactam o plano: decisões técnicas, restrições novas, mudanças de escopo, ações atribuídas
3. Incorporar ao contexto da feature — se um comentário contradiz a description, provavelmente é mais recente e deve prevalecer. Em caso de dúvida, levantar ao dev no Passo 4.

### Cards linkados e sub-tasks

Os campos `issuelinks` e `subtasks` (retornados com `fields: ["*all"]`) contêm referências a outros cards relacionados.

**Procedimento:**

1. **Sub-tasks:** listar todas com título e status. Sub-tasks podem representar divisões de trabalho já planejadas — respeitar essa divisão ao invés de criar uma própria.
2. **Issue links:** verificar os tipos de relação (`blocks`, `is blocked by`, `split from`, `relates to`, etc.). Para links do tipo `split from` (spike que originou o card) ou `is blocked by`, **ler o card linkado** com `getJiraIssue` usando `fields: ["*all"]` e `expand: "names"` — o mesmo procedimento do card principal. Spikes especialmente contêm análises técnicas detalhadas.
3. Não é necessário ler todos os cards linkados — focar nos que são do tipo spike, bloqueio, ou que têm relação técnica direta. Links do tipo `relates to` genérico podem ser ignorados a menos que o título sugira relevância.

### Prioridade: Sugestão de Implementação

**Se o card contiver uma seção "Sugestão de Implementação" (ou variações como "Sugestão de implementação", "Sugestão técnica", "Sugestão de Implementação Técnica")**, essa seção deve ser tratada como **a principal referência técnica** para o planejamento. Ela tem precedência sobre inferências próprias do orquestrador porque foi escrita por quem conhece o contexto do sistema.

- **Usar como base do plano:** o Passo 2 (escopo) e o Passo 3 (feature.md) devem refletir diretamente o que está na sugestão — arquitetura proposta, ordem de implementação, services/handlers mencionados, abordagem técnica
- **Não contradizer sem justificativa:** se a investigação do código revelar algo diferente do sugerido, levantar a divergência como dúvida ao dev no Passo 4, não ignorar silenciosamente a sugestão
- **Propagar para os subagentes:** transcrever as partes relevantes da sugestão nos respectivos `feature.X.md` — o subagente do monolito recebe a parte de backend, o do bo-container a parte de BO, etc.
- **O restante do card é contexto:** as seções como Contexto, Objetivo, Escopo/Regras e Critérios de Aceite fornecem o "o quê" e o "porquê"; a Sugestão de Implementação fornece o "como" — e o "como" guia a execução

### Resumo de fontes lidas

**Antes de prosseguir para o Passo 2**, apresentar ao dev um resumo visual de todas as fontes de contexto que foram lidas (ou não), no seguinte formato:

```
## Fontes de contexto lidas

| Fonte | Status | Detalhes |
|---|---|---|
| Jira — description | ✅ Lido | [título do card] |
| Jira — Sugestão de Implementação | ✅ Lido / ⚠️ Não encontrado | [resumo 1 linha ou "campo vazio"] |
| Jira — DoD Engenharia | ✅ Lido / ⚠️ Não encontrado | ... |
| Jira — outros custom fields | ✅ N lidos / ⚠️ Nenhum | [listar quais tinham valor] |
| Jira — comentários | ✅ N comentários lidos / ⚠️ Nenhum | [último autor + data] |
| Jira — sub-tasks | ✅ N sub-tasks / ⚠️ Nenhuma | [listar títulos] |
| Jira — cards linkados | ✅ N lidos / ⚠️ Nenhum | [listar keys + tipo de relação] |
| Jira — attachments/imagens | ✅ N baixadas / ❌ N falharam / ⚠️ Nenhuma | [filenames] |
| Notion — [título da página] | ✅ Lido | [URL] |
| Notion — imagens | ✅ N analisadas / ⚠️ Nenhuma | ... |
| Figma | ✅ Lido / ❌ Não acessível / ⚠️ Nenhum link | [URL] |

Faltou algo? Se houver outro documento, design ou contexto que eu deveria ler, me envie o link ou cole aqui.
```

Usar ✅ para lido com sucesso, ❌ para tentou mas falhou, ⚠️ para não encontrado/não aplicável. Isso permite ao dev validar rapidamente se todo o contexto foi capturado antes de avançar para o planejamento.

## Passo 2 — Avaliar escopo e investigar estado atual

### 2a — Determinar repositórios envolvidos

**Backend (monolito):**
- [ ] O endpoint já existe ou precisa ser criado?
- [ ] Precisa de nova tabela ou coluna? (migration)
- [ ] Qual app de domínio concentra a regra? (ldi, cursos, questoes, etc.)
- [ ] Qual BFF/BO expõe o handler? (bo/, bff/, bff_mobile/)

**Frontend bo-container:**
- [ ] A funcionalidade afeta o backoffice?
- [ ] É uma feature nova ou extensão de módulo existente?
- [ ] Qual módulo?

**Frontend front-student:**
- [ ] A funcionalidade afeta a área do aluno?
- [ ] É uma feature nova ou extensão de página existente?
- [ ] Qual módulo?

### 2b — Investigar estado atual de cada repositório envolvido

**CRÍTICO:** Não assumir que o trabalho é apenas adicionar código novo. Pode ser necessário modificar código existente.

**Usar `feature-dev:code-explorer`** para investigações profundas — quando a feature envolve código existente complexo (múltiplos services interligados, fluxos cross-layer), lançar um agente `code-explorer` no repositório envolvido para mapear a arquitetura, dependências e padrões antes de planejar. Para investigações simples (verificar se um endpoint existe), a busca direta com Grep/Glob é suficiente.

**monolito** (se envolvido):
- Verificar se o endpoint já existe: buscar em `apps/bo/internal/handlers/`, `apps/bff/internal/handlers/`
- Verificar se o service/repository relevante existe: buscar em `apps/<dominio>/internal/services/`, `apps/<dominio>/internal/repositories/`
- Verificar se existe migration relacionada
- Identificar o que precisa ser criado vs. modificado

**bo-container** (se envolvido):
- Verificar se o módulo alvo existe: `src/modules/<modulo>/`
- Verificar se já existe service, page, ou componente relacionado
- Identificar o que precisa ser criado vs. modificado

**front-student** (se envolvido):
- Verificar se o módulo alvo existe: `modules/<modulo>/`
- Verificar se já existe service, container, page, ou componente relacionado
- Identificar o que precisa ser criado vs. modificado

## Passo 3 — Criar pasta da feature e feature.md

### 3a — Determinar o nome da pasta

- Se há Jira ID (ex: `FUK2-1234`): pasta = `FUK2-1234/`
- Se não há Jira ID: pasta = `FUK2-<descricao-curta>/` em kebab-case (ex: `FUK2-bloqueio-edicao-toc-rebuild/`)

Criar a pasta na raiz do monorepo:

```bash
mkdir -p <pasta-da-feature>/
```

Guardar o caminho da pasta (ex: `FUK2-1234/`) para uso em todos os passos seguintes. Todos os arquivos de controle serão criados **dentro desta pasta**.

### 3b — Criar feature.md

Criar o arquivo `<pasta-da-feature>/feature.md`:

→ Usar o template em `templates/feature.md`

**Importante:** As tarefas em `## Progresso` devem ter a **mesma granularidade** das entregas que serão listadas nos arquivos `feature.X.md` — não resumos de alto nível. Isso garante que o mapeamento entre os arquivos seja direto e sem ambiguidade.

## Passo 4 — Negociar com o dev

**Não criar os arquivos `feature.X.md` ainda.**

1. Apresentar o `feature.md` ao dev
2. Listar explicitamente todas as **dúvidas em aberto**
3. Aguardar confirmação ou correções
4. Ajustar o `feature.md` conforme feedback
5. Confirmar: "Posso criar os arquivos de instruções para os subagentes?"

## Passo 4.5 — Dashboard visual do plano

Após o dev aprovar o plano (e antes de criar os arquivos), apresentar um **dashboard gráfico** que resuma visualmente a feature. Isso ajuda a confirmar o entendimento e serve como referência rápida.

### Regra de largura

**CRÍTICO:** Os gráficos são renderizados em terminal monospace. Nunca usar bordas externas com largura fixa (ex: `╔════...════╗` com `║` nas laterais) — o conteúdo interno varia e **quebra a borda direita**. Em vez disso:

- Usar **separadores horizontais** (`───`) sem bordas verticais externas
- Usar **caixas internas** pequenas (por repo) sem moldura global
- Máximo **50 colunas** de conteúdo útil por linha
- Se precisar de moldura, usar apenas **topo e base** (`───`)

### Obrigatório: Diagrama de fluxo

Mostrar como os repos se conectam:

```
── [JIRA-ID] — [Título curto] ──

  ┌── monolito ──┐
  │ migration    │
  │ entity       │
  │ repository   │
  │ service      │
  │ handler ─────┼──┐
  └──────────────┘  │
                    ▼
  ┌── bo-container ──┐
  │ service API      │
  │ componente(s)    │
  │ page             │
  └──────────────────┘
                    │
                    ▼
  ┌── front-student ──┐
  │ service API       │
  │ container(s)      │
  │ page              │
  └───────────────────┘
```

Adaptar ao escopo real — se só 2 repos, mostrar só esses. Incluir endpoints reais nas setas.

### Obrigatório: Mapa de entregas

```
  monolito      ██░░░░ 5 entregas
  bo-container  ████░░ 3 entregas
  front-student ████░░ 3 entregas
  ─────────────────────────────
  Total: 11 entregas
```

### Opcional (usar quando relevante):

**Dependências entre tabelas:**
```
  alunos ───┐
            ├──▶ historico_alunos (NOVA)
  cursos ───┘    aluno_id, curso_id, status
```

**Timeline:**
```
  monolito      ═══▶ ✓
  bo-container       ═══▶ ✓
  front-student           ═══▶ ✓
  ─────────────────────────▶ tempo
```

**Arquivos impactados:**
```
  monolito/
  ├── apps/ldi/internal/
  │   ├── services/
  │   │   └── aluno_service.go  ~ MOD
  │   └── repositories/
  │       └── aluno_repo.go     ~ MOD
  └── apps/bo/internal/handlers/
      └── aluno_handler.go      + NEW
```

## Passo 5 — Criar os arquivos feature.X.md na pasta da feature

Após aprovação, criar os arquivos de instruções **dentro da pasta da feature** (ex: `FUK2-1234/`).

### Verificação antes de criar

**Para cada arquivo que será criado**, verificar se já existe dentro da pasta:

```
<pasta-da-feature>/feature.monolito.md
<pasta-da-feature>/feature.bo.md
<pasta-da-feature>/feature.frontstudent.md
```

Se algum existir, **alertar o dev antes de sobrescrever**:

```
Atenção: já existe o arquivo `FUK2-1234/feature.monolito.md`.
Sobrescrever?
```

Só prosseguir com a criação após confirmação explícita.

### Template: feature.monolito.md

→ Usar o template em `templates/feature-monolito.md`

### Template: feature.bo.md

→ Usar o template em `templates/feature-bo.md`

### Template: feature.frontstudent.md

→ Usar o template em `templates/feature-frontstudent.md`

### Nomes dos arquivos

| Repositório | Arquivo dentro da pasta da feature |
|---|---|
| monolito | `<pasta-da-feature>/feature.monolito.md` |
| bo-container | `<pasta-da-feature>/feature.bo.md` |
| front-student | `<pasta-da-feature>/feature.frontstudent.md` |

### Caso especial: backend já existe

Se o monolito **não** for implementado nesta feature (endpoint já existe), os arquivos dos frontends não terão um "Após 6a" para atualizar seus endpoints. Neste caso, **no próprio Passo 5**:

1. Investigar os endpoints existentes no monolito (paths reais, payloads, responses) — usando os dados levantados no Passo 2b
2. Preencher `## Endpoints disponíveis` e `## Skill a invocar` de `feature.bo.md` e `feature.frontstudent.md` com os dados reais já na criação — não com placeholders

### Confirmação antes de lançar subagentes

```
Arquivos criados em <pasta-da-feature>/:
- feature.monolito.md ✓ (se aplicável)
- feature.bo.md ✓ (se aplicável)
- feature.frontstudent.md ✓ (se aplicável)

Revise os arquivos e confirme: posso lançar os subagentes?
```

**Não prosseguir para o Passo 5.5 sem confirmação explícita.**

## Passo 5.5 — Criar branch em cada submodulo envolvido

Após a confirmação do dev, e **antes de lançar qualquer subagente**, criar a branch de trabalho em cada repositório envolvido.

### Nome da branch

```
<JIRA-ID>/vibed/<descricao-curta>
```

Exemplos:
- `FUK2-1234/vibed/adicionar-campo-cpf`
- `FUK2-890/vibed/tela-historico-aluno`

A **descrição curta** deve ser em kebab-case, derivada do título do card, com no máximo 4-5 palavras.

**O nome da branch deve ser IDÊNTICO em todos os repositórios** — isso permite rastrear o trabalho cross-repo pelo mesmo nome.

### Comandos a executar em cada repositório envolvido

```bash
# Para cada repo envolvido (monolito, bo-container, front-student):
cd <repo>/
git checkout main
git pull origin main
git checkout -b <JIRA-ID>/vibed/<descricao-curta>
```

Executar sequencialmente para cada submodulo envolvido. Se `main` não existir, usar o branch padrão do repositório.

### Registrar a branch no feature.md

Após criar as branches, adicionar ao `feature.md` na seção de cabeçalho:

```markdown
## Branch
`<JIRA-ID>/vibed/<descricao-curta>` — criada em: monolito, bo-container, front-student (listar apenas os envolvidos)
```

## Passo 6 — Implementar com subagentes

Após confirmação, executar na ordem correta. **Todos os subagentes rodam sequencialmente** — bo-container e front-student também não rodam em paralelo, pois ambos escrevem em `../feature.md` via o orquestrador e poderiam ter conflitos de atualização.

**CRÍTICO:** Nunca implementar diretamente no contexto principal. Cada repositório é um subagente separado com seu próprio `working_dir`.

### 6a — monolito (se necessário)

Chamar a ferramenta `Agent` com:
- `working_dir`: caminho absoluto para `monolito/`
- `prompt`:

→ Usar o template em `templates/subagent.monolito.md` (substituindo `<JIRA-ID>`, `<descricao-curta>` e `<pasta-da-feature>` pelos valores reais)

### Após 6a — Atualizar endpoints e feature.md

Antes de lançar qualquer subagente de frontend:

1. **Ler o relatório do monolito** e extrair os endpoints reais (paths, payloads, responses)
2. Em `<pasta-da-feature>/feature.bo.md` e `<pasta-da-feature>/feature.frontstudent.md`, atualizar **ambas** as seções com os dados reais:
   - `## Endpoints disponíveis` — substituir os planejados pelos confirmados
   - `## Skill a invocar` — atualizar o input `endpoints` para bater com os reais
3. **Atualizar `<pasta-da-feature>/feature.md`**: marcar as entregas do monolito como concluídas (`- [x]`) na seção `### monolito`

### 6b — bo-container (se necessário)

Chamar a ferramenta `Agent` com:
- `working_dir`: caminho absoluto para `bo-container/`
- `prompt`:

→ Usar o template em `templates/subagent.bo.md` (substituindo `<JIRA-ID>`, `<descricao-curta>` e `<pasta-da-feature>` pelos valores reais)

### Após 6b — Atualizar feature.md

Marcar as entregas do bo-container como concluídas (`- [x]`) na seção `### bo-container` do `<pasta-da-feature>/feature.md`.

### 6c — front-student (se necessário)

Chamar a ferramenta `Agent` com:
- `working_dir`: caminho absoluto para `front-student/`
- `prompt`:

→ Usar o template em `templates/subagent.frontstudent.md` (substituindo `<JIRA-ID>`, `<descricao-curta>` e `<pasta-da-feature>` pelos valores reais)

### Após 6c — Atualizar feature.md

Marcar as entregas do front-student como concluídas (`- [x]`) na seção `### front-student` do `<pasta-da-feature>/feature.md`.

## Passo 6.5 — Code review automatizado

Após **todos** os subagentes concluírem, e antes de reportar ao dev, rodar um review automatizado usando `feature-dev:code-reviewer` em cada repositório que foi modificado.

Para cada repo envolvido, lançar um agente `code-reviewer` com `subagent_type: "feature-dev:code-reviewer"`:

```
Revise as mudanças na branch atual deste repositório.
Foque em: bugs, erros de lógica, vulnerabilidades de segurança, e aderência aos padrões do projeto.
Ignore estilo cosmético — apenas problemas que impactam funcionalidade ou segurança.
```

Os reviews podem rodar em paralelo (um por repo), pois são read-only.

**Se o reviewer encontrar problemas de alta confiança:**
1. Listar os problemas encontrados ao dev junto com o relatório final
2. Perguntar se deseja que o orquestrador lance um subagente de correção

**Se não houver problemas:** seguir direto para o Passo 7.

## Passo 7 — Gerar changelog

Antes de consolidar, invocar a skill `orquestrador/changelog` para gerar o changelog visual de todos os repositórios modificados. O changelog é salvo automaticamente em `changelog.<data>` na raiz do projeto.

Isso dá ao dev uma visão completa e categorizada de tudo que foi implementado — métodos, endpoints, componentes, rotas — antes de decidir os próximos passos.

## Passo 8 — Consolidar e reportar

Apresentar o resumo final com **dashboard visual** junto com o changelog gerado. **Não usar bordas externas fixas** — usar separadores e caixas internas:

```
── CONCLUÍDO: [JIRA-ID] ──
── [Título do card] ──

Progresso: ████████████████████ 100%

┌── monolito ──────────────┐
│ + N criados  ~ N modific │
│ POST /bo/...             │
│ GET /bff/...             │
└──────────────────────────┘

┌── bo-container ──────────┐
│ + N criados  ~ N modific │
│ Rota: /modulo/pagina     │
└──────────────────────────┘

┌── front-student ─────────┐
│ + N criados  ~ N modific │
│ Rota: /pagina            │
└──────────────────────────┘

Changelog: changelog.<data>

Próximos passos:
  □ Testar localmente
  □ Criar PRs em cada repositório
```

Adaptar ao escopo real — mostrar apenas os repos implementados. Dados reais extraídos dos relatórios dos subagentes.

### Gráfico de impacto

```
  Repo           criados  modific  commits
  monolito       ████ 4   ██ 2    █████ 5
  bo-container   ███ 3    █ 1     ███ 3
  front-student  ███ 3    █ 1     ███ 3
```

## Resolução de conflitos cross-repo

Após o monolito concluir (Passo 6a), pode haver divergências entre o que foi planejado e o que foi implementado:

**Cenário: endpoint retorna shape diferente do planejado**
1. Ler o relatório do subagente monolito e comparar com o planejado no `feature.bo.md` / `feature.frontstudent.md`
2. Atualizar `## Endpoints disponíveis` nos arquivos de frontend com os dados reais
3. Se a divergência for grande (campos renomeados, estrutura completamente diferente), informar o dev antes de prosseguir

**Cenário: endpoint adicional necessário (descoberto durante implementação)**
1. Registrar o endpoint novo no `feature.md` e nos arquivos de frontend
2. Se o frontend já foi implementado, relançar o subagente com as correções

**Cenário: erro de compilação ou teste no monolito**
1. Verificar se é um problema de wiring (falta import, falta registro no container)
2. Relançar o subagente com diagnóstico específico
3. Se o problema persistir após 2 tentativas, informar o dev para debug manual

**Regra geral:** O orquestrador é o único que tem visão completa do sistema. Quando houver conflito, é ele quem decide como ajustar — nunca delegar essa decisão ao subagente.

## Recuperação de falha de subagente

Se um subagente reportar erro ou parar com trabalho incompleto:

1. **Ler o `<pasta-da-feature>/feature.X.md`** do repositório em questão para identificar quais entregas foram marcadas `[x]` (concluídas) e quais ainda estão `[ ]`
2. **Diagnosticar** o problema relatado:
   - **Erro de compilação** → verificar imports, interfaces (assinatura mudou?), container wiring
   - **Teste falhando** → verificar se mock está atualizado com a interface, se fixtures batem com structs
   - **Arquivo faltante** → verificar se etapa anterior foi pulada (entity antes de repo, repo antes de service)
3. **Corrigir** o problema se for algo que o orquestrador pode resolver (ex: atualizar informação no `feature.X.md`)
4. **Relançar o subagente** com instrução adicional:

```
[prompt padrão do subagente]

RETOMADA: algumas entregas já foram concluídas (marcadas com [x] em ../<pasta-da-feature>/feature.X.md).
Comece a partir da primeira entrega ainda marcada como [ ] e siga em diante.
O problema anterior foi: [descrição do erro e como foi resolvido].
```

## Regras

- **Entrar em `EnterPlanMode` imediatamente** — nenhuma ação antes da aprovação do plano
- **Sair do plan mode (`ExitPlanMode`) apenas com confirmação explícita do dev**
- **Nunca pular o Passo 4** — plano sempre aprovado antes de criar os arquivos de instruções
- **Nunca pular a confirmação do Passo 5** — arquivos sempre revisados pelo dev antes de lançar subagentes
- **Todos os arquivos de controle ficam na pasta da feature** (`FUK2-<Codigo>/` ou `FUK2-<descricao-curta>/`)
- **Verificar existência** de `feature.X.md` na pasta antes de criar — alertar se já existir
- **Atualizar endpoints reais** em `<pasta>/feature.bo.md` e `<pasta>/feature.frontstudent.md` antes de lançar os frontends
- **Todos os subagentes rodam sequencialmente** — nunca em paralelo
- **Subagentes só atualizam seu próprio `<pasta>/feature.X.md`** — nunca o `feature.md`
- **Orquestrador atualiza `<pasta>/feature.md`** após cada subagente concluir
- **Granularidade das tarefas** em `feature.md` deve bater com as entregas dos `feature.X.md`
- **Tirar todas as dúvidas** antes de começar — uma dúvida não resolvida pode invalidar horas de trabalho
- **Commits incrementais obrigatórios** — ver seção abaixo

## Commits incrementais

Cada subagente deve fazer commits pequenos e legíveis por humanos **a cada entrega concluída** da `feature.X.md`, não um commit gigante no final.

### Timeline de desenvolvimento

Os commits devem contar uma história lógica de desenvolvimento — a mesma sequência que um dev humano seguiria naturalmente. Nunca commitar coisas fora de ordem ou de forma que pareça que o código "apareceu pronto". A progressão deve fazer sentido: banco antes de código, interface antes de implementação, base antes de detalhes.

Exemplos de timelines que fazem sentido:
- `migration` → `entity` → `repository` → `service` → `handler`
- `service` → `component` → `page`

### Regras de commit

- **Um commit por entrega** da lista de entregas (migration, entity, service, handler, componente, page, etc.)
- **Mensagem no formato:** `[JIRA-ID] tipo: descrição curta do que foi feito`
- **Exemplos de mensagens boas:**
  - `[FUK2-1234] migration: adiciona coluna cpf na tabela alunos`
  - `[FUK2-1234] service: implementa método BuscarHistorico em AlunoService`
  - `[FUK2-1234] handler: POST /bo/alunos/historico`
  - `[FUK2-1234] component: AlunoHistoricoModal.vue`
  - `[FUK2-1234] page: tela de histórico do aluno`
- **Nunca commitar arquivos não relacionados** à entrega atual
- **Marcar a entrega como `[x]`** no `feature.X.md` e incluir esse arquivo no mesmo commit

### Instrução adicional nos prompts dos subagentes

Os prompts dos subagentes já incluem essa instrução. Ao lançar um subagente, garantir que o prompt menciona: *"Faça um commit a cada entrega concluída, com mensagem no formato `[JIRA-ID] tipo: descrição curta`."*
