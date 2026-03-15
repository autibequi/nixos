# Agents Reference — Wiseman & Trashman

Documentação unificada dos dois agentes principais do workspace.

---

## 🧙‍♂️ Wiseman — The Mage of Connections

**Propósito:** Interconectar notas no vault Obsidian usando backlinks, tags e frontmatter YAML, transformando notas isoladas em uma rede de conhecimento navegável.

### Como Usar

#### Interativo
```
/wiseman
```
Invoca o mago para tecer conexões sob demanda. Útil quando você adicionar um monte de notas novas de uma vez.

#### Automático (Recorrente)
Task `wiseman` roda a cada **hora** (every60, timeout 600s, Sonnet model).
- Lê `obsidian/wiseman-chrononomicon.md` (seu grimório de memória)
- Varre `sugestoes/`, `_agent/reports/`, `artefacts/`, etc.
- Tece conexões semânticas (backlinks, tags, `related` field)
- Atualiza Chrononomicon com novas heurísticas

### Configuração

```yaml
clock: every60      # a cada hora
timeout: 600        # 10 minutos max
model: sonnet       # análise semântica (requer Sonnet)
schedule: always    # roda 24/7
```

### Workflow Padrão

1. **Ler Chrononomicon** (`obsidian/wiseman-chrononomicon.md`) — suas memórias
2. **Varrer o Obsidian** — procurar notas novas/modificadas em:
   - `obsidian/sugestoes/` — sugestões de tasks
   - `obsidian/_agent/reports/` — relatórios
   - `obsidian/artefacts/` — entregáveis
   - `obsidian/_agent/tasks/done/` — tasks concluídas
   - `obsidian/*.md` — notas na raiz
3. **Analisar** — backlinks existentes? Tags normalizadas? Pertence a cluster?
4. **Tecer** — adicionar `[[backlinks]]`, tags, campo `related` no frontmatter
5. **Registrar** — atualizar Chrononomicon com o que fez

### Regras Invioláveis

- ✋ **NUNCA deletar** — só adicionar conexões
- ✋ **NUNCA editar** kanban.md ou scheduled.md
- ✋ **Conexões semânticas** — qualidade > quantidade
- ✋ **Respeitar estrutura** — manter formato de notas existentes
- ✋ **Se nada novo** — registrar no Chrononomicon e sair

### Recursos Obsidian

| Recurso | Uso | Exemplo |
|---------|-----|---------|
| **Backlinks** | Link direto bidireccional | `[[nome-da-nota]]` ou `[[pasta/nota\|alias]]` |
| **Tags** | Categorização inline | `#nixos`, `#trabalho`, `#critico` |
| **Frontmatter** | Tags estruturadas + `related` | `tags: [nixos, performance]` |
| **Callouts** | Destaque visual em clusters | `> [!abstract] Cluster...` |

### Documentação Interna

- **`obsidian/wiseman-chrononomicon.md`** — grimório pessoal do Wiseman (seu libro de memória)
  - Tags canônicas do Obsidian
  - Heurísticas de correlação descobertas
  - Registro de teias já tecidas (pra não refazer)
  - Regras de ouro do Obsidian

---

## 🗑️ Trashman — Workspace Cleanup Agent

**Propósito:** Escanear o workspace e arquivar arquivos obsoletos de forma segura e reversível.

### Como Usar

#### Interativo
```
/trashman
```
Invoca a limpeza sob demanda. Útil quando você sentir que há muita coisa obsoleta.

#### Automático (Recorrente)
Task `trashman` roda a cada **hora** (every60, timeout 180s, Haiku model).
- Escaneia candidatos à limpeza
- Move pra `/workspace/.ephemeral/.trashbin/` (reversível)
- Registra em `/workspace/.ephemeral/.trashlist` com motivo

### Configuração

```yaml
clock: every60      # a cada hora
timeout: 180        # 3 minutos max
model: haiku        # simples e rápido
schedule: always    # roda 24/7
```

### O Que Trashman Limpa

1. **`.ephemeral/scratch/`** — arquivos temporários > 7 dias
2. **`.ephemeral/logs/`** — logs > 14 dias
3. **`.ephemeral/notes/`** — notas órfãs (task foi deletada)
4. **`obsidian/artefacts/`** — pastas de tasks concluídas > 30 dias
5. **`obsidian/_agent/reports/`** — reports > 30 dias
6. **`obsidian/sugestoes/`** — sugestões revisadas (`reviewed: true`) > 14 dias
7. **Imagens/Assets** — arquivos não referenciados > 3 dias (delegado a `trashman-clean-assets`)
8. **Pastas vazias** — recursivamente (após limpeza de arquivos)

### Variante: Trashman — Clean Assets

Task separada (`trashman-clean-assets`) roda a cada **10 minutos** (every10, timeout 60s, Haiku model):
- Foco específico: imagens não referenciadas em `.md` e código-fonte
- Remove assets órfãos (`.png`, `.jpg`, `.gif`, `.svg`, etc.)
- Padrões comuns: `Pasted image YYYYMMDDHHMMSS.*` gerados pelo Obsidian
- Arquiva em `.ephemeral/.trashbin/` como o Trashman principal

### Processo de Limpeza

Para cada arquivo candidato:
1. Mover → `/workspace/.ephemeral/.trashbin/` (mantém path relativo)
2. Registrar → `/workspace/.ephemeral/.trashlist` com `YYYY-MM-DD HH:MM | path | motivo`
3. Relatório final → `contexto.md` no diretório da task

### Regras de Proteção (INVIOLÁVEIS)

| Tipo | O Que | Motivo |
|------|-------|--------|
| **Arquivos** | `CLAUDE.md`, `SOUL.md`, `SELF.md`, `flake.nix`, `configuration.nix`, `kanban.md`, `scheduled.md` | Configuração essencial do workspace |
| **Diretórios** | `modules/`, `stow/`, `projetos/`, `scripts/` | Código versionado |
| **Task state** | `memoria.md` em recorrentes | Estado persistente entre ciclos |
| **Vault linkado** | Arquivos referenciados em cards ativos (Backlog, Em Andamento) | Pode quebrar workflow |

**Regra de Ouro:** Na dúvida, **NÃO arquivar**. Melhor deixar lixo que perder trabalho.

### Auto-evolução

Após cada execução, Trashman reflete:
- Thresholds fazem sentido? (muito agressivos? conservadores?)
- Novos tipos de lixo a monitorar?
- False positives? (arquivou algo que não devia?)

Se sim → edita `obsidian/_agent/tasks/recurring/trashman/CLAUDE.md` pra melhorar.

---

## 📋 Configuração Comum

### Status em scheduled.md

Ambos aparecem na coluna **"Recorrentes"** de `obsidian/_agent/scheduled.md`:

```markdown
## Recorrentes

- [ ] **wiseman** [worker-N] `sonnet` — Mago das conexões (every60, 600s)
- [ ] **trashman** [worker-N] `haiku` — Limpeza segura (every60, 180s)
```

**Nunca modificar manualmente** — o runner controla isso automaticamente.

### Memória Persistente

Cada task tem um `memoria.md` em seu diretório:

- **`obsidian/_agent/tasks/recurring/wiseman/memoria.md`** — estado do Wiseman (ciclos, notas processadas, clusters)
- **`obsidian/_agent/tasks/recurring/trashman/memoria.md`** — histórico de limpezas (dados, status, motivos)

**Nunca deletar** — é como brain persistent entre execuções.

### Monitoramento

Verifique no Obsidian:
- **`obsidian/_agent/scheduled.md`** — status atual (Em Execução = rodando agora)
- **`obsidian/_agent/reports/`** — relatórios automáticos após cada ciclo
- **`.ephemeral/.trashlist`** — log histórico de tudo que Trashman arquivou

---

## 🎯 Checklist — Garantir Tudo Certo

- [x] Wiseman task existe em `recurring/wiseman/` com clock `every60`
- [x] Trashman task existe em `recurring/trashman/` com clock `every60`
- [x] Ambos têm `memoria.md` persistente
- [x] Comando `/wiseman` invocável (em `stow/.claude/commands/wiseman.md`)
- [x] Comando `/trashman` invocável (em `stow/.claude/commands/trashman.md`)
- [x] Agente Wiseman registrado (em `stow/.claude/agents/wiseman/agent.md`)
- [x] Agente Trashman registrado (em `stow/.claude/agents/trashman/`)
- [x] `obsidian/wiseman-chrononomicon.md` existe (grimório)
- [x] `.ephemeral/.trashlist` existe (log de limpezas)
- [x] Ambos rondam no `scheduled.md` sob "Recorrentes"
- [x] Documentação unificada aqui (este arquivo)

---

## 📚 Referências Rápidas

| Recurso | Localização |
|---------|------------|
| **Wiseman Agent** | `stow/.claude/agents/wiseman/agent.md` |
| **Trashman Agent** | `stow/.claude/agents/trashman/` |
| **Wiseman Command** | `stow/.claude/commands/wiseman.md` |
| **Trashman Command** | `stow/.claude/commands/trashman.md` |
| **Wiseman Task** | `obsidian/_agent/tasks/recurring/wiseman/` |
| **Trashman Task** | `obsidian/_agent/tasks/recurring/trashman/` |
| **Wiseman Grimório** | `obsidian/wiseman-chrononomicon.md` |
| **Trashman Log** | `.ephemeral/.trashlist` |
| **Task System Docs** | `docs/task-system.md` |
| **Status Atual** | `obsidian/_agent/scheduled.md` (Recorrentes) |

---

**Última atualização:** 2026-03-14
**Versão:** 1.0
