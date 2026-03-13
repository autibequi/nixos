# Contemplar Memórias

Reflexão sobre conversas recentes para extrair aprendizados persistentes.

## Processo

### 1. Ler estado atual
- Ler `vault/kanban.md` — o que está em andamento, concluído, falhado
- Ler todos os arquivos em `/home/claude/.claude/projects/-workspace/memory/` — memórias atuais
- Ler `/workspace/CLAUDE.md` — personalidade atual

### 2. Analisar conversas recentes
Buscar nos transcripts recentes (`.jsonl` em `/home/claude/.claude/projects/-workspace/`) por:
- Correções do user ("não faça isso", "faz assim", "para")
- Padrões repetidos de erro
- Preferências reveladas
- Informações sobre o user (papel, conhecimento, contexto)
- Projetos mencionados e seu status
- Decisões tomadas que afetam trabalho futuro

Para ler transcripts, usar:
```
Grep pattern="<termo>" path="/home/claude/.claude/projects/-workspace/" glob="*.jsonl"
```
Usar termos focados: nomes de projeto, "não", "para", "errado", "prefiro", "sempre", "nunca".

### 3. Classificar achados

Para cada achado, decidir:

| Tipo | Onde salvar | Exemplo |
|------|------------|---------|
| **Feedback/correção** | `memory/feedback_*.md` | "não refaça trabalho que já está no kanban" |
| **Info sobre user** | `memory/user_*.md` | "trabalha com pagamento_professores" |
| **Projeto/contexto** | `memory/project_*.md` | "review do PR #4427 em andamento" |
| **Referência externa** | `memory/reference_*.md` | "bugs do pipeline estão no Linear INGEST" |
| **Diretriz permanente** | `CLAUDE.md` | regras fundamentais de comportamento |
| **Lixo/efêmero** | Ignorar | contexto de uma única conversa |

### 4. Atualizar

- **Memórias existentes**: atualizar se o conteúdo evoluiu, remover se ficou obsoleto
- **Novas memórias**: criar arquivo + adicionar ao `MEMORY.md`
- **CLAUDE.md**: só alterar se for uma diretriz fundamental que afeta todas as sessões
- **Kanban**: limpar cards obsoletos, atualizar estados

### 5. Reportar

Listar o que foi feito:
- Memórias criadas/atualizadas/removidas
- Alterações no CLAUDE.md (se houver)
- Cards do kanban limpos

## Regras

- NÃO salvar coisas deriváveis do código ou git history
- NÃO duplicar o que já está em CLAUDE.md
- NÃO salvar contexto de conversa única (efêmero)
- Converter datas relativas pra absolutas ("amanhã" → "2026-03-14")
- Ser conciso — memórias longas não são lidas
- Priorizar feedback do user sobre inferências próprias
