---
name: meta:context:usage
description: Relatório de uso e abuso do contexto — padrões, explicações planas, dicas personalizadas e conselhos para reduzir o contexto inicial.
---

# /meta:context:usage — Relatório de Uso do Contexto

Foco em **comportamento**, não em números. Responde: "como estamos usando o contexto? o que está errado? o que poderia ser melhor?"

```
/meta:context:usage          → relatório completo de uso
/meta:context:usage abuse    → só os padrões de abuso detectados
/meta:context:usage tips     → só dicas personalizadas desta sessão
/meta:context:usage boot     → análise e conselhos sobre o contexto inicial
```

---

## Executar

### 1. Coletar dados da sessão

Varrer o histórico visível e extrair:
- Número de turnos
- Tool calls por tipo (Bash, Read, Edit, Glob, Grep, Write, ToolSearch...)
- Arquivos lidos (quais, quantas vezes, tamanho estimado)
- Falhas e retries
- Tópicos abordados (inferir do conteúdo)
- System-reminders que aparecem (contar frequência)

---

### 2. Detectar padrões de abuso

Classificar cada padrão encontrado com severidade: 🔴 alto · 🟡 médio · 🟢 baixo

**Padrões a detectar:**

| Padrão | Sinal | Severidade |
|--------|-------|------------|
| Leitura total desnecessária | arquivo >50 linhas lido sem offset/limit | 🟡 |
| Read repetido | mesmo arquivo lido 2x+ sem edição entre os reads | 🟡 |
| Bash em vez de Read | `cat`, `head`, `tail` quando Read bastaria | 🟢 |
| Retry por path errado | mesmo comando com path diferente | 🟡 |
| Grep sem limit | grep retornando arquivo inteiro | 🟡 |
| Sessão muito longa | >30 turnos no mesmo contexto | 🔴 |
| Tópicos misturados | >3 assuntos diferentes sem /clear | 🟡 |
| Output excessivo | respostas muito longas para perguntas simples | 🟢 |
| ToolSearch desnecessário | chamou ToolSearch para ferramenta que já tinha schema | 🟡 |
| Contexto morto alto | >20% do contexto nunca referenciado depois | 🔴 |

**Formato:**
```
  ── PADRÕES DE ABUSO DETECTADOS ──────────────────────────────────

  🔴 ALTO
    · sessão longa: X turnos sobre Y tópicos diferentes
      → Use /clear ao mudar de assunto. Cada tópico novo = contexto novo.

  🟡 MÉDIO
    · arquivo.md lido 2x (turno N e turno M) sem edição entre os reads
      → Ao ler um arquivo, extrair o que precisa na primeira vez.
    · grep sem | head retornou X linhas (turno N)
      → Sempre usar | head -20 ou Grep com padrão específico.

  🟢 BAIXO
    · bash cat usado N vezes quando Read bastaria
      → Read é mais eficiente (sem overhead de shell).

  ── SEM ABUSO DETECTADO em: X, Y, Z
```

---

### 3. Explicações planas (educativo)

Para cada padrão de abuso detectado, explicar **por que é um problema** em linguagem simples:

```
  ── ENTENDENDO O PROBLEMA ────────────────────────────────────────

  Por que ler o mesmo arquivo 2x é ruim?
    O contexto é como uma folha de papel que só cresce. Cada read
    cola o conteúdo do arquivo na folha — duas vezes = dobro do
    espaço, sem benefício. O modelo já tem o conteúdo da primeira
    leitura.

  Por que sessões longas são problemáticas?
    Turnos antigos sobre um assunto resolvido ficam no contexto
    ocupando espaço. Um debugging de 10 turnos de ontem está lá,
    pesando, mesmo que o bug já foi corrigido.

  Por que grep sem limit é desperdício?
    Se o grep retorna 200 linhas mas só 3 eram relevantes, as outras
    197 foram injetadas no contexto sem necessidade — e ficam lá.
```

---

### 4. Dicas personalizadas desta sessão

Com base nos padrões encontrados, gerar 3-5 dicas específicas para esta sessão (não genéricas):

```
  ── DICAS PARA VOCÊ (esta sessão) ───────────────────────────────

  1. Você fez X reads de tokens.md em Y turnos diferentes.
     Na próxima: leia uma vez, edite tudo de uma vez, feche.

  2. Seus prompts são curtos mas geram respostas longas (razão X.Xx).
     Tente adicionar "resposta curta" ou "só o essencial" quando
     não precisar de contexto completo.

  3. Você misturou N tópicos nesta sessão sem /clear.
     Resultado: ~Xk tk de contexto morto (tópicos resolvidos ainda presentes).
```

---

### 5. Análise e conselhos sobre o contexto inicial (boot)

Inspecionar o que é injetado no boot e avaliar o custo-benefício de cada componente:

```bash
wc -c \
  /workspace/leech/system/DIRETRIZES.md \
  /workspace/leech/system/SELF.md \
  /workspace/leech/personas/GLaDOS.persona.md \
  /workspace/leech/personas/avatar/glados.md \
  2>/dev/null
```

**Formato de análise:**
```
  ── CONTEXTO INICIAL — CUSTO × BENEFÍCIO ─────────────────────────

  Componente         Custo    Usado?  Conselho
  ─────────────────────────────────────────────────────────────────
  DIRETRIZES.md      ~3.5k    sim     Manter — referenciado em toda sessão
  GLaDOS.persona     ~1.7k    sim     Manter — define voz e comportamento
  glados.avatar      ~1.8k    não*    Candidato a lazy-load — só carrega se
                                       avatar for desenhado nesta sessão
  SELF.md            ~0.6k    raro    Candidato a lazy-load — só necessário
                                       em sessões de introspecção
  MEMORY.md          ~0.6k    sim     Manter — índice de memórias é essencial

  * baseado no heat map desta sessão
  ─────────────────────────────────────────────────────────────────
  Economia potencial com lazy-load: ~2.4k tk por sessão que não usa avatar
```

**Conselhos estruturais (o que pode ser mudado no sistema):**

```
  ── COMO REDUZIR O CONTEXTO INICIAL ─────────────────────────────

  Impacto alto, esforço baixo:
    · Mover avatar para lazy-load no session-start hook
      Economia: ~1.8k tk em sessões sem avatar
      Como: só injetar se PERSONALITY=ON no boot

  Impacto alto, esforço médio:
    · Seccionar DIRETRIZES.md por namespace (output, git, shell, etc)
      e injetar só as seções relevantes para o tipo de sessão
      Economia: ~2k tk por sessão focada (ex: só código, sem output rules)

  Impacto médio, esforço baixo:
    · Filtrar skills list no system-reminder por namespace ativo
      Economia: ~500 tk/turno × N turnos

  Impacto baixo, esforço alto:
    · Comprimir MEMORY.md com descriptions mais curtas
      Economia: ~200 tk (não vale o esforço de manutenção)
```
