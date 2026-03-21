# Man — Manual de Skills, Commands e Diretrizes

Exibe documentação sobre um skill ou command disponível. Também gerencia as diretrizes do sistema.

## Entrada
- `$ARGUMENTS`: nome do skill/command, ou `diretrizes [add|rm|edit] ...`

## Modo diretrizes

Se `$ARGUMENTS` começa com `diretrizes`:
- **`diretrizes`** (sem mais args): ler `/workspace/DIRETRIZES.md` e exibir formatado
- **`diretrizes add <regra>`**: adicionar nova diretriz na seção apropriada
- **`diretrizes rm <trecho>`**: remover diretriz que contém o trecho
- **`diretrizes edit <trecho> → <novo>`**: substituir diretriz

Após qualquer modificação, exibir estado final.

## Instruções

1. Se `$ARGUMENTS` estiver vazio, listar TUDO disponível:
   - Buscar todos os `SKILL.md` em `stow/.claude/skills/` (ignorar `skill-evaluations/`)
   - Buscar todos os `.md` em `stow/.claude/commands/`
   - Apresentar em tabela organizada por categoria:
     ```
     ## Skills
     | Nome | Descrição |
     |------|-----------|
     | monolito/go-worker | criação de workers SQS... |

     ## Commands
     | Nome | Descrição |
     |------|-----------|
     | /quick | lança subagente haiku... |
     ```
   - Extrair nome e descrição do frontmatter YAML (`name:` e `description:`)

2. Se `$ARGUMENTS` foi informado, buscar o match:
   - Procurar em `stow/.claude/skills/**/SKILL.md` por frontmatter `name:` que contenha o argumento
   - Procurar em `stow/.claude/commands/*.md` pelo nome do arquivo matching
   - Match parcial é válido (ex: `worker` matcha `monolito/go-worker`)

3. Quando encontrar o skill/command, apresentar um help formatado:
   ```
   ╭─ man: <nome> ─╮

   <descrição do frontmatter>

   ## Seções principais
   (resumo das seções do SKILL.md/command — workflow, regras, templates disponíveis)

   ## Uso
   (como invocar: se é skill automático ou command com /nome)

   ## Arquivos
   - SKILL.md: <path>
   - Templates: <lista se houver>

   ╰───╯
   ```

4. Se não encontrar match nenhum, sugerir os nomes mais similares disponíveis.

## Regras
- NUNCA editar arquivos — este comando é somente leitura
- Usar model default (não lançar subagente)
- Ler o conteúdo real dos arquivos encontrados — não inventar
- Ignorar o diretório `skill-evaluations/` (são benchmarks, não skills)
- Para skills com templates, listar os templates disponíveis mas não exibir conteúdo completo
- Ser conciso — é um help, não um dump do arquivo inteiro
