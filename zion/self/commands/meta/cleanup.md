# meta:cleanup — Revisão e Limpeza de Sessão

Revisa o que ficou no workspace após a sessão e limpa debris — tentativas fracassadas, código morto, experimentos revertidos. **Nunca apaga sem mostrar e confirmar.**

---

## Quando usar

Após uma sessão com muitas iterações, tentativas, ou correções de curso — como quando experimentamos algo que não funcionou e revertemos. O objetivo é garantir que só o que realmente vale ficou.

---

## Fase 1 — Mapear o que mudou

```bash
cd <repo atual>
git diff --name-only HEAD      # arquivos com mudanças não commitadas
git diff --name-only HEAD~1    # ou comparar com último commit se tudo commitado
```

Se não houver git no contexto atual, listar arquivos modificados recentemente via `ls -lt`.

Para cada arquivo modificado: ler o conteúdo atual e o diff.

---

## Fase 2 — Classificar cada mudança

Para cada arquivo modificado, classificar cada trecho alterado:

### KEEPER — fica, é o resultado real da sessão
- Mudança que o usuário aprovou explicitamente
- Mudança que está funcionando (o usuário confirmou)
- Mudança que remove algo que estava errado
- Nova feature / nova configuração ativa e válida

### DEBRIS — candidato a limpeza
Padrões que indicam entulho de iteração:

| Padrão | Exemplo |
|--------|---------|
| `@keyframes` sem nenhum `animation:` referenciando no mesmo arquivo | `@keyframes foo {}` órfão |
| Regra CSS para seletor inexistente no config | `#custom-xyz {}` sem módulo correspondente |
| Bloco comentado que parece tentativa abandonada | `/* tentativa 1: ... */` |
| Variável/constante declarada mas nunca usada | |
| Arquivo temporário de teste | `test_`, `tmp_`, `debug_`, `_bak` |
| Código duplicado (mesmo bloco aparece duas vezes) | |
| Regra vazia `selector {}` | |
| `TODO` / `FIXME` deixado por Claude durante a sessão | |
| Import não utilizado | |

### INCERTO — precisa de decisão do usuário
- Código que parece morto mas pode ter propósito não óbvio
- Arquivo que não foi tocado nesta sessão mas está na mesma área
- Mudança que reverteu outra mudança (líquido zero — questionar se deve sumir)
- Qualquer coisa com menos de 2 sinais claros de ser debris

---

## Fase 3 — Regras de validação antes de propor remoção

**NUNCA propor remover** sem confirmar TODOS estes pontos:

1. **Só arquivos desta sessão** — não tocar em nada que não apareceu no `git diff` da sessão
2. **Verificar referências** — antes de marcar algo como morto, buscar no projeto inteiro se está referenciado em outro lugar
3. **Respeitar git history** — se o item tem commits anteriores associados, é INCERTO, não debris
4. **Regra do @keyframes** — só é debris se não existir NENHUM `animation-name:` ou `animation:` apontando pra ele no mesmo arquivo
5. **CSS órfão** — antes de marcar um seletor CSS como órfão, verificar se existe o módulo/classe no arquivo de config do Waybar (ou arquivo equivalente)
6. **Nunca batch-delete** — apresentar um item por vez ou agrupado por arquivo, nunca tudo de uma vez

---

## Fase 4 — Relatório

Apresentar sempre neste formato antes de qualquer ação:

```
╭─ CLEANUP REPORT ──────────────────────────────────────────╮

Sessão tocou N arquivo(s): <lista>

## KEEPER — ficam, são o resultado real
  arquivo: path/to/file
  └─ o que ficou: descrição curta
  └─ por que vale: motivo em uma frase

## DEBRIS — proponho remover (aguardando confirmação)
  [D1] arquivo: path/to/file  linha X–Y
       o quê: descrição do trecho
       motivo: por que é debris
       risco: Baixo / Médio (o que pode dar errado)

## INCERTO — preciso da sua decisão
  [I1] arquivo: path/to/file
       contexto: o que é
       dúvida: por que não tenho certeza

╰────────────────────────────────────────────────────────────╯
```

---

## Fase 5 — Confirmar e executar

Após o relatório, perguntar para cada grupo DEBRIS:

```
Posso remover [D1] — <descrição curta>? [s / n / ver]
  s = remover
  n = manter
  ver = mostrar o trecho exato antes de decidir
```

Para itens INCERTO: sempre mostrar o conteúdo completo e aguardar decisão explícita antes de qualquer ação.

**Execução:** usar Edit para remover apenas o trecho exato, nunca reescrever o arquivo inteiro.

---

## Fase 6 — Confirmar resultado

Após todas as remoções aprovadas:

```
## Cleanup concluído

Removido: N itens em M arquivos
Mantido:  N itens (por escolha ou incerteza)

Arquivos limpos:
  - path/to/file: o que foi removido
```

Se nada a remover: `Sessão limpa — nenhum debris encontrado.`

---

## Regras absolutas

- **Nunca apagar sem mostrar o conteúdo exato primeiro**
- **Nunca tocar arquivos fora do escopo da sessão**
- **Dúvida = INCERTO, não DEBRIS**
- **Se a remoção requer entender o sistema além do diff, perguntar antes de classificar**
- **Não confundir "não gostei do resultado" com "é debris"** — se o usuário aprovou e está ativo, é KEEPER mesmo que pareça simples
