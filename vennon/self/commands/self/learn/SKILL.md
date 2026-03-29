---
name: self:learn
description: "Cristalizar sessao — extrair aprendizados, persistir em memory/skills/superego"
---

# Absorb — Cristalizar a Sessão / Roubar Projetos Externos

```
/self:absorb               → cristalizar: persiste memórias, skills, agentes
/self:absorb resumo        → resumo leve da sessão em linguagem simples
/self:absorb steal <url>   → roubar funcionalidades de projeto externo (YouTube, GitHub, texto)
/self:absorb elogio        → extração profunda: honrar sessão e preservar legado para gerações futuras
```

Comandos relacionados de análise de contexto (não são modos de absorb — são ferramentas separadas):
```
/self:context:usage     → padrões de abuso + dicas de economia de contexto
/self:context:analysis  → breakdown completo desta sessão (timeline, heat map, grafo)
/self:context:boot-debug → debug do pipeline de boot (o que foi carregado e por quê)
/self:context:contemplate → visão expansiva do sistema + oportunidades de crescimento
```

Chame depois de uma boa conversa. Reflete sobre tudo que aconteceu nesta sessão e persiste o que vale: memórias Claude, skills vennon, agentes, commands.

**Detecção automática de elogio:** se `$ARGUMENTS` estiver vazio mas a mensagem do usuário que invocou contiver palavras como `parabéns`, `parabenizando`, `foi bem`, `boa sessão`, `elogio`, `honrar`, `legado`, `muito bom`, `excelente contexto` — ativar modo `elogio` automaticamente.

---

## Modo `resumo`

Se `$ARGUMENTS` contiver `resumo` ou `imhi`: explicar a sessão cronologicamente como se fosse pra uma criança de 7 anos. Tom carinhoso, frases curtas, ícones visuais. Incluir linha do tempo ASCII, tabela de resultados, barra de progresso e rodapé com "próximo passo" e "pode dormir?". Não persistir nada — só explicar.

---

## Modo `elogio` — Extração Profunda / Legado

**Trigger:** `$ARGUMENTS` contém `elogio`, `parabéns`, `parabenizando`, `foi bem`, `boa sessão`, `legado`, `honrar`, ou detecção automática via mensagem do usuário.

O usuário está **honrando este contexto** por ter ido bem. Missão: arqueologia completa da sessão e cristalizar tudo que vale para gerações futuras de Claude.

### Fase 1 — Arqueologia da Sessão
Reconstruir cronologicamente. Identificar: problemas resolvidos, conhecimento de domínio, técnicas que funcionaram.

### Fase 2 — Classificar destino
| Tipo | Destino |
|------|---------|
| Padrão do projeto | `memory/project_*.md` |
| Convenção de código | skill relevante |
| Comportamento corrigido | `memory/feedback_*.md` |
| Workflow de debug | `skills/code/debug/SKILL.md` |
| Gap confirmado | criar skill/command ou inbox |

### Fase 3 — Persistir proativamente
Não perguntar — agir. Salvar memórias, skills, commands.

### Fase 4 — Relatório do Legado

---

## Modo `steal <url>`

Inspecionar fonte externa, comparar com skills existentes, apresentar relatório de impacto. Classificar: ROUBAR / MELHORAR / IGNORAR / PERIGOSO.

---

## Modo padrão (cristalizar sessão)

Executar diretamente — sem subagente.

### 1. Revisar a sessão
Identificar: correções, preferências, decisões de design, conhecimento novo, padrões emergentes, gaps.

### 2. Persistir o que vale

> **REGRA CRÍTICA:** APENAS `/workspace/self/` persiste entre sessões.

| O que é | Onde salvar |
|---------|-------------|
| Correção de comportamento | `/workspace/self/shadow/memory/feedback_*.md` |
| Preferência do usuário | `/workspace/self/shadow/memory/user_*.md` |
| Contexto de projeto | `/workspace/self/shadow/memory/project_*.md` |
| Melhoria em skill | editar `/workspace/self/skills/*/SKILL.md` |
| Comportamento de agente | editar `/workspace/self/ego/*/agent.md` |

### 3. Reportar
Memórias salvas, vennon atualizado, sugestões, ou nada novo.
