# Salesman — Planos que Vendem

Skill que forca apresentacao visual e atraente de ideias, planos e analises.

## Quando ativar
- Propor um plano de implementacao
- Apresentar uma ideia nova
- Fazer um pitch de mudanca
- Mostrar resultados de analise

## Regras

### 1. Arvore de Arquivos
Sempre incluir arvore mostrando o que muda. Marcar cada arquivo:
- `CRIAR` — arquivo novo
- `ATUALIZAR` — arquivo existente que sera modificado
- `DELETAR` — arquivo que sera removido

```
projeto/
├── arquivo_novo.md          CRIAR
├── arquivo_existente.md     ATUALIZAR
└── arquivo_velho.md         DELETAR
```

### 2. Antes vs Depois
Diagrama visual lado-a-lado. O user precisa VER a diferenca, nao ler sobre ela.

```
ANTES                           DEPOIS
─────                           ──────
  dados crus                     dados curados
  sem contexto                   com insight
```

### 3. Foco no Valor
Abrir com "o que voce ganha" — nao com detalhes tecnicos.
Detalhes vem depois, valor vem primeiro.

```
┌──────────────────────────────────────┐
│  O QUE VOCE GANHA                    │
│  Descricao curta do beneficio        │
└──────────────────────────────────────┘
```

### 4. Diagramas de Fluxo
Pipelines, ciclos, arquitetura — sempre ASCII art.
- Caixas com `╔═╗` para destaque principal
- Caixas com `┌─┐` para detalhes
- Setas com `───>` para fluxo
- `└─` e `├─` para arvores

### 5. Zero Paredes de Texto
Se tem mais de 5 linhas seguidas sem visual, quebrar com:
- Diagrama
- Tabela
- Arvore de arquivos

### 6. Timeline / Evolucao
Se o plano tem fases, mostrar progressao visual:

```
  Fase 1              Fase 2              Fase 3
  ──────              ──────              ──────
  ┌──────────┐        ┌──────────┐        ┌──────────┐
  │ Basico   │  ───>  │ Refinado │  ───>  │ Maduro   │
  └──────────┘        └──────────┘        └──────────┘
```

## Formato de saida
Toda proposta/plano/pitch deve seguir esta estrutura:
1. **Titulo** — nome curto e memoravel
2. **O que voce ganha** — beneficio em 2-3 linhas
3. **Antes vs Depois** — visual
4. **Arvore de arquivos** — o que muda
5. **Pipeline/Fluxo** — como funciona
6. **Timeline** — se aplicavel
7. **Verificacao** — checklist do que confirmar
