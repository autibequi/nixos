---
name: self:context:usage
description: Relatório de uso e abuso do contexto — padrões, explicações planas, dicas personalizadas e conselhos para reduzir o contexto inicial.
---

# /self:context:usage — Relatório de Uso do Contexto

Foco em **comportamento**, não em números. Responde: "como estamos usando o contexto? o que está errado? o que poderia ser melhor?"

```
/self:context:usage          → relatório completo de uso
/self:context:usage abuse    → só os padrões de abuso detectados
/self:context:usage tips     → só dicas personalizadas desta sessão
/self:context:usage boot     → análise e conselhos sobre o contexto inicial
```

---

## Executar

### 1. Coletar dados da sessão

Varrer o histórico visível e extrair:
- Número de turnos
- Tool calls por tipo
- Arquivos lidos (quais, quantas vezes, tamanho estimado)
- Falhas e retries
- Tópicos abordados
- System-reminders (frequência)

### 2. Detectar padrões de abuso

Classificar com severidade: alto / médio / baixo

| Padrão | Sinal | Severidade |
|--------|-------|------------|
| Leitura total desnecessária | arquivo >50 linhas lido sem offset/limit | médio |
| Read repetido | mesmo arquivo 2x+ sem edição entre reads | médio |
| Bash em vez de Read | cat/head/tail quando Read bastaria | baixo |
| Sessão muito longa | >30 turnos no mesmo contexto | alto |
| Tópicos misturados | >3 assuntos sem /clear | médio |
| Contexto morto alto | >20% nunca referenciado depois | alto |

### 3. Explicações planas (educativo)

Para cada padrão detectado, explicar **por que é um problema** em linguagem simples.

### 4. Dicas personalizadas desta sessão

3-5 dicas específicas (não genéricas) baseadas nos padrões encontrados.

### 5. Análise do contexto inicial (boot)

Inspecionar o que é injetado no boot, avaliar custo-benefício, sugerir lazy-loads e otimizações estruturais.
