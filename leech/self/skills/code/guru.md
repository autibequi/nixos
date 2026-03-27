# /code:guru — Brainstorm Design Ideas

Brainstorm criativo com `/brainstorm` skill pra achar múltiplas soluções.

## Responsabilidades

- [ ] Ler questões de design em ATTENTION
- [ ] Usar skill `/brainstorm` pra gerar 3+ ideias por questão
- [ ] Propor opções com tradeoffs (complexidade, risco, benefício)
- [ ] Recomendar melhor opção (com reasoning)
- [ ] Preencher ATTENTION com soluções
- [ ] Movimentar card pra PLANNING (agora com confiança)

## Input

```
/code:guru FUK2-XXXXX
```

Ou com contexto:

```
/code:guru
Arquivo: /workspace/obsidian/workshop/estrategia/FUK2-987213-refactor-jwt.md
Questão 1: JWT refresh strategy? (TTL vs blacklist vs ambos?)
Questão 2: Token revoke? (logout imediato ou esperar expirar?)
```

## Output

Preenche **ATTENTION** com:
- 🧠 **Q1: [Questão]**
  - Opção A: [descrição] — Prós/Contras
  - Opção B: [descrição] — Prós/Contras
  - Opção C: [descrição] — Prós/Contras
  - ✅ **Recomendação**: Opção [X] porque [reasoning]

- 🧠 **Q2: [Questão]**
  - (mesmo padrão)

## Exemplo

```
## ATTENTION

- [x] **Guru: Brainstorm Design** (2026-03-27 14:00 - 15:30)

  **Q1: Refresh token strategy?**
  - Opção A: TTL curto (7d), sem blacklist
    - ✅ Simples, nada extra
    - ❌ Logout não é imediato

  - Opção B: Blacklist Redis
    - ✅ Logout imediato
    - ❌ Complexo, requer Redis cleanup

  - Opção C: TTL + optional blacklist
    - ✅ Padrão bom, logout simples
    - ❌ Um pouco mais código

  - ✅ **Guru recomenda**: Opção C

  **Q2: Token revoke?**
  - (similar structure)
```

## 🌐 Related Skills & Agents

### Skills Principais

| Skill | Como Usar |
|-------|-----------|
| `/brainstorm` | **OBRIGATÓRIO**. Gera ideias, 3+ opções por questão |
| `/coruja` | Se domínio é Estratégia, specialista opina |
| `/thinking:brainstorm` | Se brainstorm fica travado, escalate |

### Agentes Especializados

| Agente | Quando Usar | Por Quê |
|--------|-----------|--------|
| **Coruja** | Design de Estratégia | Conhece monolito, padrões Go/Vue/Nuxt |
| **Wiseman** | Impacto sistêmico | Consolida design options cross-repo |
| **Wanderer** | Padrões existentes | Explora codebase pra patterns similares |

### Fluxo Guru com Contexto

```
Questão: "Refresh token strategy?"

1. /brainstorm → gera 3+ opções
2. /coruja → se auth é critical, opina
3. Wanderer → "Quais padrões já existem em outros services?"
4. Wiseman → "Qual opção é mais sistêmica?"

RESULTADO: Opção recomendada com 4 perspectivas
```

## Checklist Pós-Guru

- [ ] `/brainstorm` skill chamado (obrigatório)
- [ ] Todas questões têm 3+ opções
- [ ] Cada opção tem prós/contras
- [ ] **Contexto levantado**: Consultou agentes/skills relacionadas
- [ ] Recomendação clara com reasoning (considerando perspectivas múltiplas)
- [ ] ATTENTION completo, ready pra PLANNING
- [ ] Timeline atualizada (data/hora guru brainstorm)
