---
name: code/debug
description: "Debugging sistematico — ativado automaticamente ao ver stack trace ou bug report. Fluxo: leitura → localização → rastreio+logs → hipótese → fix mínimo → verificação."
---

# Skill: debug — Debugging Sistematico

> Ativada automaticamente ao receber stack trace, erro de execucao, ou bug report.
> Nunca chutar fix sem evidencia. Sempre conectar todos os pontos antes de agir.

---

## Quando usar

- Stack trace recebido na conversa
- Bug reportado (Jira, user, CI)
- Teste falhando sem causa obvia
- Comportamento inesperado em producao/staging
- Incidente ou regressao

## Contexto do projeto — ler antes de debugar

Antes de iniciar o fluxo, verificar se existem arquivos `.md` no projeto que descrevem
arquitetura, convenções de debug, ou detalhes de infraestrutura:

```
Glob: **/*.md (no projeto atual)
Priorizar: README.md, ARCHITECTURE.md, DEBUG.md, CONTRIBUTING.md, docs/
```

Esses arquivos podem conter:
- Como rodar testes localmente
- Onde ficam os logs da aplicacao
- Flags de ambiente relevantes
- Convenções específicas do projeto

Se encontrar algo útil: absorver antes de continuar o fluxo.

## Fluxo — Stack Trace recebido

Quando o user manda um stack trace diretamente:

1. **Leitura** — tipo de erro, mensagem principal, linha que importa (geralmente nao e a primeira)
2. **Localização** — Grep pelo arquivo/funcao do stack → Read das linhas ao redor
3. **Rastreio da cadeia** — subir chamadas ate a origem real
   - Checar proativamente `/workspace/logs/<nome-da-aplicacao>/` — logs da execucao atual ja estao la
   - Ler ultimos logs sem perguntar ao user — determinar se sao uteis
   - Combinar stack + logs + codigo antes de continuar
4. **Hipotese** — conectar TODOS os pontos (stack + logs + codigo)
   - Todos os arquivos relevantes devem ser lidos e validados antes de assumir que a solucao esta correta
   - Nao assumir causa sem evidencia em cada camada
5. **Fix** — diff minimo, menor mudanca possivel, sem reformatar nada fora do escopo
6. **Verificacao** — rodar testes/lint apos o fix (especifico por projeto — ver secao Dominio abaixo)

---

## Fase 1 — REPRODUZIR

Antes de qualquer hipotese, **reproduzir o bug**:

- Definir passos exatos para triggerar o problema
- Se Jira card: extrair repro steps de descricao/comentarios
- Se observacao direta: documentar comando/acao/input exato
- Registrar output esperado vs output obtido
- **NAO PULAR** — sem reproducao, qualquer fix e chute

Se nao conseguir reproduzir: pedir mais informacao ao dev. Nao avancar.

## Fase 2 — HIPOTESES

Listar **3-5 causas possiveis**, rankeadas por probabilidade:

| # | Hipotese | Probabilidade | Evidencia para confirmar/refutar |
|---|---------|---------------|----------------------------------|
| 1 | ... | Alta | ... |
| 2 | ... | Media | ... |
| 3 | ... | Baixa | ... |

Considerar:
- Mudanca recente no codigo? (`git log --oneline -20`)
- Regressao de merge?
- Race condition?
- Config/env diferente?
- Dependencia externa mudou?

## Fase 3 — ISOLAR

Para a hipotese mais provavel:

1. Escrever teste minimo ou comando que isola a causa
2. Usar **busca binaria** quando muitos componentes envolvidos (desabilitar metade, checar se bug persiste)
3. Fazer **UMA mudanca por vez** entre test runs
4. Registrar cada tentativa no investigation log (ver template)

Se hipotese 1 refutada: passar para hipotese 2. Atualizar a tabela.

## Fase 4 — VERIFICAR

Apos identificar causa raiz e aplicar fix:

1. Rodar cenario de reproducao da Fase 1 — confirmar que o bug sumiu
2. Rodar testes relacionados — checar regressoes
3. Rodar testes do pacote/modulo inteiro
4. Documentar causa raiz e fix aplicado

## Dominio: Go monolito

- **Trace:** handler → service → repository (seguir a cadeia de chamadas)
- **Migrations:** checar se migration recente alterou schema esperado
- **Debug remoto:** dlv (ref: skill dockerizer para setup de debug)
- **Flags:** `APP_ENV=testing`, `-tags testing` para rodar em ambiente de teste
- **Logs:** grep por erro em logs do container (`/workspace/logs/docker/`)

## Dominio: Vue frontends (bo-container / front-student)

- **Trace:** page → container → service → API call
- **Store:** checar mutations e state — valor esperado vs obtido
- **Network:** isolar se problema e frontend ou backend (DevTools > Network)
- **Build:** `yarn build` pode revelar erros silenciosos que `yarn dev` esconde

## Regras de ouro

1. **UMA mudanca por vez** entre test runs — senao nao sabe o que corrigiu
2. **Registrar TUDO** no investigation log — o rastro e tao valioso quanto o fix
3. **Nao chutar** — se Fase 1 nao reproduz, parar e pedir mais info
4. **Preferir teste automatizado** para reproduzir — vira regressao guard de graca
5. **Ref: DIRETRIZES.md** — mostrar evidencia antes de dizer "corrigido"

## Template

Usar `templates/investigation-log.md` para registrar o processo de debugging.
Salvar o log preenchido junto ao fix (no PR, no commit, ou em doc separado).
