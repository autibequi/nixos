# Skill: CodeRabbit Review Extractor

**Objetivo:** Extrair e listar TODOS os comentários do CodeRabbit em um PR (GitHub), separando issues resolvidas de pendentes.

**Trigger:** User passa PR URL e pede "comentários do coderabbit" ou "review do coderabbit"

## Fluxo

### 1. Fetch Comments
```bash
curl -s -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/repos/OWNER/REPO/pulls/PR_NUMBER/comments" \
  > /tmp/pr_comments.json
```

### 2. Parse & Separate
```python
import json

with open('/tmp/pr_comments.json') as f:
    data = json.load(f)

# Filter only CodeRabbit
coderabbit_comments = [c for c in data if c['user']['login'] == 'coderabbitai[bot]']

# Detect active vs fixed
active = []
fixed = []

for c in coderabbit_comments:
    date = c['created_at'][:10]
    path = c['path'].split('/')[-1]
    line = c['line']
    body = c['body']

    # Heuristics: se houver commit que resolve após o comentário, marcar como fixed
    # Por enquanto: simples separação por data/response
    if is_resolved(c):  # ver lógica abaixo
        fixed.append({...})
    else:
        active.append({...})
```

### 3. Detection Logic (`is_resolved`)
- ✅ **FIXED**: Se há um commit **posterior** ao comentário que implementa a sugestão
  - Ex: comentário 2026-03-23, commit 2026-03-26 com mensagem "fix" / "refactor" → FIXED
  - Ex: há reply do usuario dizendo "tks vou fazer" ou "done" → FIXED

- 🔴 **ACTIVE**: Sem resposta, sem commit posterior

### 4. Output Format

```
╔════════════════════════════════════════════════════╗
║         CodeRabbit Review — PR #XXXX              ║
╚════════════════════════════════════════════════════╝

✅ FIXED (N)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#1 — file.vue:123 | 🟡 Minor
  └─ Issue description (1-liner)
     ✓ Fixed in commit XXXXX (date)

[...more fixed...]

🔴 ACTIVE (N) — Precisa fazer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#5 — file.vue:95 | 🟡 Minor
  └─ **Preserve o grupo clicado no CTA**

     Descrição completa: [primeira parte do body]

     Sugestão: [extract from <details> se houver]

#6 — file.vue:227 | 🟠 Major
  [...]

```

## Workflow Esperado

1. User: "pode ver os comentários do coderabbit em https://github.com/estrategiahq/front-student/pull/4566?"
2. Skill executa + lista (5 min, incluindo parsing)
3. User: "corrija os ativos"
4. Implementar todas as issues 🔴 ACTIVE
5. Commit + push

## Implementação

**Arquivo:** `/workspace/self/skills/code/github-evaluate/coderabbit-review.py`

```python
#!/usr/bin/env python3
import json
import sys
import os
import subprocess
from datetime import datetime

def fetch_pr_comments(owner, repo, pr_number):
    """Fetch all review comments from a PR"""
    token = os.environ.get('GH_TOKEN')
    url = f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}/comments"
    cmd = f'curl -s -H "Authorization: token {token}" "{url}"'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return json.loads(result.stdout)

def fetch_commits(owner, repo, pr_number):
    """Fetch commits to detect fixes"""
    token = os.environ.get('GH_TOKEN')
    url = f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr_number}/commits"
    cmd = f'curl -s -H "Authorization: token {token}" "{url}"'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return json.loads(result.stdout)

def parse_url(pr_url):
    """Extract owner/repo/pr_number from GitHub URL"""
    # https://github.com/estrategiahq/front-student/pull/4566
    parts = pr_url.rstrip('/').split('/')
    return parts[-4], parts[-3], int(parts[-1])

def is_fixed(comment, commits):
    """Heuristic: check if issue was fixed after comment"""
    comment_date = datetime.fromisoformat(comment['created_at'].replace('Z', '+00:00'))

    # Check if any commit after comment date references the issue
    for commit in commits:
        commit_date = datetime.fromisoformat(commit['commit']['author']['date'].replace('Z', '+00:00'))
        if commit_date > comment_date:
            msg = commit['commit']['message'].lower()
            if any(kw in msg for kw in ['fix', 'refactor', 'simplify', 'remove']):
                return True
    return False

def extract_issue_summary(body):
    """Extract first sentence/key info from CodeRabbit comment"""
    lines = body.split('\n')
    for line in lines:
        if line.startswith('**') and line.endswith('**'):
            return line.strip('*')
    return lines[0][:100]

def main():
    if len(sys.argv) < 2:
        print("Usage: coderabbit-review.py <PR_URL>")
        sys.exit(1)

    pr_url = sys.argv[1]
    owner, repo, pr_number = parse_url(pr_url)

    comments = fetch_pr_comments(owner, repo, pr_number)
    commits = fetch_commits(owner, repo, pr_number)

    coderabbit_comments = [c for c in comments if c['user']['login'] == 'coderabbitai[bot]']

    active = []
    fixed = []

    for i, c in enumerate(coderabbit_comments, 1):
        comment = {
            'id': i,
            'path': c['path'].split('/')[-1],
            'line': c['line'],
            'body': c['body'],
            'date': c['created_at'][:10],
            'summary': extract_issue_summary(c['body'])
        }

        if is_fixed(c, commits):
            fixed.append(comment)
        else:
            active.append(comment)

    # Output
    print(f"\n{'='*60}")
    print(f"CodeRabbit Review — {owner}/{repo} PR #{pr_number}")
    print(f"{'='*60}\n")

    if fixed:
        print(f"✅ FIXED ({len(fixed)})")
        print("-" * 60)
        for c in fixed:
            print(f"#{c['id']} — {c['path']}:{c['line']}")
            print(f"    └─ {c['summary']}")
            print()

    if active:
        print(f"\n🔴 ACTIVE ({len(active)}) — Precisa fazer")
        print("-" * 60)
        for c in active:
            print(f"#{c['id']} — {c['path']}:{c['line']}")
            print(f"    └─ {c['summary']}\n")
            print(f"    {c['body'][:300]}...\n")

if __name__ == '__main__':
    main()
```

## CLI Shortcut (opcional)

Adicionar ao `.bashrc` ou skill:
```bash
coderabbit() {
  python3 /workspace/self/skills/code/github-evaluate/coderabbit-review.py "$1"
}
```

Usage: `coderabbit https://github.com/estrategiahq/front-student/pull/4566`

## Tags
- `github`
- `coderabbit`
- `review`
- `automation`
- `pr-analysis`
