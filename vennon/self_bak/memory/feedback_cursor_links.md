---
name: feedback_cursor_links
description: Sempre usar cursor://file//home/pedrinho/... para links clicáveis de arquivos — formato com linha e coluna
type: feedback
---

Sempre que referenciar um arquivo ao usuário, usar link clicável do Cursor:

```
[nome](cursor://file//home/pedrinho/caminho/arquivo.ext:linha:col)
```

**Why:** O usuário usa Cursor no host. Links clicáveis abrem o arquivo direto na posição. Verificado que `cursor://file//home/pedrinho/nixos/CLAUDE.md:10:5` abre corretamente.

**How to apply:**
- Container `/workspace/home/` = Host `/home/pedrinho/`
- Sempre incluir `:linha:col` — mínimo `:1:1` quando linha desconhecida
- Aplicar em TODA menção de arquivo: resultados de busca, erros, code review, sugestões
- Formato: `[arquivo.go:42](cursor://file//home/pedrinho/estrategia/monolito/arquivo.go:42:1)`
