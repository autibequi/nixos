# /meta:skill:evolve

Evolução empírica de uma skill via benchmark paralelo.
Gera N variações do prompt da skill, roda cada uma contra um conjunto de problemas, compara os resultados e propõe a versão melhorada.

## Uso

```
/meta:skill:evolve <skill_path> [--n=5] [--benchmark=<path>] [--model=haiku]
```

| Parâmetro | Default | Descrição |
|-----------|---------|-----------|
| `skill_path` | **obrigatório** | Caminho da skill (ex: `thinking/lite`, `coruja/monolito/go-handler`) |
| `--n` | `5` | Número de variações a testar |
| `--benchmark` | benchmark padrão | Arquivo `.md` com lista de problemas |
| `--model` | `haiku` | Modelo dos subagentes (`haiku`, `sonnet`) |

## Execução

Ler este arquivo e executar os passos abaixo:

---

### Passo 1 — Ler a skill original

```
Read self/skills/<skill_path>/SKILL.md
```

Extrair:
- Propósito central (1 linha)
- Estrutura atual (seções principais)
- Pontos de variação possíveis (onde o prompt pode ser modificado)

---

### Passo 2 — Ler o benchmark

Se `--benchmark` foi passado → usar esse arquivo.
Senão → usar `self/skills/meta/skill/evolve/benchmark_default.md`

O benchmark é uma lista de problemas. Cada problema tem:
- `id` — identificador curto
- `pergunta` — o que o agente deve responder
- `critério` — como avaliar a qualidade da resposta

---

### Passo 3 — Gerar N variações

Para cada variação, aplicar **uma** das técnicas de mutação abaixo ao prompt da skill original.
Não acumular múltiplas mutações na mesma variação — 1 variação = 1 mudança isolada (para saber qual funcionou).

**Técnicas de mutação disponíveis** (escolher as mais relevantes para a skill):

| Técnica | O que muda |
|---------|-----------|
| `budget` | Adiciona limite explícito de tool calls ("você tem N calls") |
| `grep-first` | Força grep como primeira tool call obrigatória |
| `step-back` | Exige declaração de hipótese antes de agir |
| `format-output` | Define formato exato de saída antes de pesquisar |
| `path-anchor` | Fornece path provável explicitamente no prompt |
| `persona-expert` | Adiciona "você conhece profundamente este codebase" |
| `sub-questions` | Decompõe a tarefa em 3 sub-perguntas sequenciais |
| `negatives-only` | Remove instruções positivas, mantém só restrições |
| `confidence` | Pede confidence score por item retornado |
| `minimal` | Remove 80% do texto, mantém só a regra central |

Registrar qual técnica foi usada em cada variação:
```
V1: budget
V2: grep-first
V3: step-back
...
```

---

### Passo 4 — Rodar subagentes em paralelo

Lançar todos os N subagentes **em paralelo** (um por variação) usando o Agent tool.

Cada subagente recebe:
```
[prompt da variação injetado]

---
Problema do benchmark:
<pergunta do benchmark>
```

Cada subagente deve resolver **todos** os problemas do benchmark em sequência.

Registrar para cada subagente:
- `tokens_total`
- `tool_calls`
- `duration_ms`
- `path_correto` (sim/não — verificado pelo conteúdo da resposta)
- `qualidade` (avaliação subjetiva: completo/parcial/incorreto)

---

### Passo 5 — Relatório comparativo

Exibir tabela ranqueada por eficiência (tokens × tool_calls × tempo):

```
| Rank | Variação | Técnica | Tokens | Tools | Tempo | Path | Qualidade |
|------|----------|---------|--------|-------|-------|------|-----------|
| 1    | V3       | step-back | 52k  | 3     | 8s    | ✅   | completo  |
...
```

Depois:
- **Vencedor absoluto** — melhor em todas as dimensões
- **Trade-offs notáveis** — ex: "V5 é mais lento mas mais completo"
- **Insight principal** — o que essa rodada revelou sobre a skill

---

### Passo 6 — Proposta de melhoria

Baseado no vencedor, gerar um diff do SKILL.md original → proposta melhorada.

Perguntar ao user:
> "Quer que eu aplique essa melhoria ao SKILL.md? (s/n)"

Se sim → editar o arquivo. Se não → salvar proposta em `self/skills/<skill_path>/SKILL_evolved_<data>.md`.

---

## Exemplo de sessão

```
/meta:skill:evolve thinking/lite --n=10 --model=haiku

→ Lendo thinking/lite/SKILL.md...
→ Lendo benchmark_default.md (5 problemas)...
→ Gerando 10 variações (budget, grep-first, step-back, ...)
→ Lançando 10 subagentes em paralelo...
→ [aguardando resultados]

| Rank | Variação | Técnica      | Tokens | Tools | Tempo | Qualidade |
|------|----------|--------------|--------|-------|-------|-----------|
| 1    | V9       | budget       | 52.7k  | 3     | 7.8s  | completo  |
| 2    | V5       | path+termo   | 57.2k  | 4     | 7.7s  | completo  |
...

Vencedor: V9 (budget). Quer aplicar a melhoria? (s/n)
```
