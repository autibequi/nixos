# Research Agent

> Investigate domínio antes de planejar/codar

## Quando usar

Executar ANTES de:
- `/plan-phase` 
- Qualquer feature nova
- Refactoring grande

## Workflow

1. **Analisar contexto** — ler CONTEXT.md e ROADMAP.md
2. **Pesquisar stack** — libraries, patterns, pitfalls
3. **Documentar findings** — em RESEARCH.md

## Output

Criar arquivo `vault/artefacts/research-{nome-da-feature}.md`:

```markdown
# Research: {feature}

## Stack
- libs encontradas:
- padrões:

## Features
- approaches:

## Architecture
- recommendations:

## Pitfalls
- evita:

## Referências
- links úteis:
```

## Áreas de Pesquisa

| Tipo | O que investigar |
|------|------------------|
| Stack | libs, frameworks, versions |
| Features | patterns, alternatives |
| Architecture | trade-offs, scalability |
| Pitfalls | common mistakes, edge cases |

## Exemplo de Uso

```
/research Add dark mode to settings page
```

O agent vai:
1. Verificar nosso DesignSystem
2. Pesquisar libs de theming
3. Documentar approach recomendado
