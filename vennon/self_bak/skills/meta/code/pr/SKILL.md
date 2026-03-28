---
name: meta:code:pr
description: Skill composta para auditoria e análise de Pull Requests
type: skill-index
---

# Meta Code PR

Ferramentas de análise e auditoria de Pull Requests.

## Sub-skills

### `/meta:code:pr:comment-check`
Extrai TODOS os comentários CodeRabbit de uma PR, verifica se cada um foi resolvido no código e gera relatório detalhado.

**Uso:**
```bash
/meta:code:pr:comment-check <repo> <pr> [--format json|markdown|table] [--detailed]
```

**Exemplos:**
```
/meta:code:pr:comment-check estrategiahq/monolito 4485
/meta:code:pr:comment-check estrategiahq/front-student 4583 --detailed
```

**Saída:**
- ✅/❌ Status de cada comentário
- 📊 Taxa de resolução
- 📋 Relatório em JSON/Markdown/Table
- 💾 Export para arquivo

**Implementação:**
- Script: `comment-check/script.sh`
- Requer: `gh` CLI + autenticação
- Linguagem: Bash + jq

---

**Skill Author:** Claude Haiku
**Versão:** 1.0
**Status:** ✅ Pronto para uso
