# 🚀 Guia Rápido — Wiseman & Trashman

Instruções práticas pra usar os dois agentes.

---

## 🧙‍♂️ Wiseman — Teia de Conexões

### Usar agora (interativo)
```
/wiseman
```
Invoca o mago pra tecer conexões nas notas do Obsidian.

### Como funciona automaticamente
- **Roda:** a cada hora (every60)
- **Tempo máximo:** 10 minutos
- **Modelo:** Sonnet (análise semântica)
- **O que faz:**
  1. Lê o grimório (`obsidian/wiseman-chrononomicon.md`)
  2. Procura novas notas em `sugestoes/`, `artefacts/`, etc.
  3. Adiciona backlinks `[[nota]]`, tags `#tema`, campo `related` no frontmatter
  4. Atualiza o grimório com novas heurísticas

### Onde ele guarda memória
- **`obsidian/wiseman-chrononomicon.md`** — tudo que o Wiseman aprende (tags, heurísticas, log de conexões)

### Regra de Ouro
- ✅ Adiciona backlinks e tags
- ❌ Nunca deleta nada
- ❌ Nunca toca em `kanban.md` ou `scheduled.md`
- ✅ Se nada novo pra conectar, só registra no grimório e sai

---

## 🗑️ Trashman — Limpeza Segura

### Usar agora (interativo)
```
/trashman
```
Invoca o zelador pra arquivar lixo do workspace.

### Como funciona automaticamente
- **Roda:** a cada hora (every60)
- **Tempo máximo:** 3 minutos
- **Modelo:** Haiku (rápido e simples)
- **O que limpa:**
  1. Arquivos temporários > 7 dias (`.ephemeral/scratch/`)
  2. Logs antigos > 14 dias (`.ephemeral/logs/`)
  3. Notas órfãs (`.ephemeral/notes/`)
  4. Artefatos de tasks concluídas > 30 dias
  5. Sugestões revisadas > 14 dias
  6. Imagens não referenciadas > 3 dias
  7. Pastas vazias (recursivamente)

### Onde fica o histórico
- **`/.ephemeral/.trashlist`** — log histórico: `data | arquivo original | motivo`
- **`/.ephemeral/.trashbin/`** — lixeira reversível (pra recuperar se errar)

### Regra de Ouro
- ✅ Move tudo pra `.trashbin/` (reversível)
- ✅ Registra motivo no `.trashlist`
- ❌ Nunca toca em: `CLAUDE.md`, `SOUL.md`, `SELF.md`, `flake.nix`, `kanban.md`, `scheduled.md`
- ❌ Nunca toca em: `modules/`, `stow/`, `projetos/`, `scripts/`
- ✅ Na dúvida, NÃO arquiva (melhor deixar lixo)

---

## 📊 Status Atual

### Ver tudo em ação
- **`obsidian/_agent/scheduled.md`** — coluna "Recorrentes" mostra os dois (quando estão "Em Execução" = rodando agora)
- **`obsidian/_agent/reports/`** — relatórios automáticos após cada ciclo
- **`obsidian/_agent/tasks/recurring/wiseman/`** — estado do Wiseman
- **`obsidian/_agent/tasks/recurring/trashman/`** — estado do Trashman

### Verificar saúde
- Wiseman processando novas notas? → check `obsidian/wiseman-chrononomicon.md` (seção "Análise do Vault")
- Trashman limpando? → check `/.ephemeral/.trashlist` (entrada mais recente)

---

## ❓ FAQ

**P: Posso invocar `/wiseman` enquanto ele tá rodando automaticamente?**
Sim. Não há conflito — cada invocação é independente.

**P: E se Trashman arquivar algo que eu precisava?**
Tá em `/.ephemeral/.trashbin/` com path relativo — recupera e coloca de volta.

**P: Como Wiseman sabe que uma nota é nova?**
Ele lê o Chrononomicon (grimório) que tem log de todas as notas que já processou. Tudo que não tá no log é novo.

**P: Trashman muda a regra de limpeza?**
Sim! Após cada execução, ele reflete sobre thresholds e pode editar `obsidian/_agent/tasks/recurring/trashman/CLAUDE.md` pra se melhorar.

**P: Posso forçar Wiseman a processar uma nota específica?**
Sim — edita o Chrononomicon e remove a nota do "Registro de Teias Tecidas". Próxima execução ela será processada como nova.

---

## 🔧 Checklist — Garantir Tudo Pronto

- [ ] Executar `/wiseman` e verificar se tece alguma conexão
- [ ] Executar `/trashman` e verificar se encontra algo pra limpar
- [ ] Ver `obsidian/_agent/scheduled.md` → ambos em "Recorrentes" ✅
- [ ] Ler `obsidian/wiseman-chrononomicon.md` → verificar se tem dados
- [ ] Verificar `.ephemeral/.trashlist` → verificar se tem histórico

---

**Documentação completa:** `docs/agents-reference.md`
