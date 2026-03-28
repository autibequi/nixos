---
name: feedback_rescue_agent_files
description: Agentes background que escrevem em paths deletados durante reorganizacao — como resgatar arquivos dos logs.
type: feedback
---

Quando reorganizar pastas ENQUANTO agentes background estao rodando, os agentes podem escrever em paths que ja foram deletados. Os arquivos "somem" porque o Write cria o diretorio de volta, mas o rm -rf posterior apaga.

**How to apply:**
1. NUNCA reorganizar pastas com agentes ainda rodando — esperar todos terminarem
2. Se ja reorganizou: arquivos estao no output log do agente em `/tmp/claude-0/.../tasks/<agentId>.output`
3. Resgatar com Python:
```python
import json, os
with open(output_file) as f:
    for line in f:
        data = json.loads(line)
        for item in data.get('message',{}).get('content',[]):
            if item.get('name') == 'Write':
                # item['input']['file_path'] e item['input']['content']
```
4. Copiar para o path correto da nova estrutura

**Why:** Na sessao Jonathas, 3 posts SEO + landing pages + termos legais foram "perdidos" porque reorganizei pastas antes dos agentes terminarem. Resgatei tudo dos logs, mas custou tempo.
