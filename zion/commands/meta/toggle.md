# Toggle — Liga/desliga flags do sistema

## Uso
```
/meta:toggle <flag>
```

Flags: `auto-commit` | `auto-jarvis` | `personality` | `zion-debug`

## Tabela de flags

| Flag | Arquivo ephemeral | Lógica | Especial |
|------|------------------|--------|----------|
| `auto-commit` | `.ephemeral/auto-commit` | existe = ON | — |
| `auto-jarvis` | `.ephemeral/auto-jarvis` | existe = ON | — |
| `personality` | `.ephemeral/personality-off` | existe = OFF (invertido) | — |
| `zion-debug` | `.ephemeral/zion-debug` | existe = ON | carrega contexto ao ligar |

## Procedimento geral

1. Ler `$ARGUMENTS` para identificar a flag
2. Verificar se o arquivo ephemeral existe em `/workspace/.ephemeral/`
3. Toggle:
   - Arquivo existe → remover → reportar OFF
   - Arquivo não existe → criar → reportar ON
4. Atenção à lógica invertida de `personality`: `personality-off` existe = personalidade DESLIGADA

## Mensagens de confirmação

| Flag | ON | OFF |
|------|----|-----|
| `auto-commit` | "Auto-commit LIGADO" | "Auto-commit DESLIGADO" |
| `auto-jarvis` | "Auto-Jarvis ON — /jarvis roda no startup" | "Auto-Jarvis OFF — /jarvis não roda no startup" |
| `personality` | "Personalidade LIGADA" | "Personalidade DESLIGADA" |
| `zion-debug` | "Zion Debug ON — contexto completo carregado" | "Zion Debug OFF — lite mode ativado. Efeito na próxima sessão." |

## Comportamento especial: auto-commit

Quando ON:
- Commitar automaticamente sem perguntar ao user
- Identidade: Author=Pedrinho, Committer=Claudinho
- Conventional commits; não commitar código quebrado

## Comportamento especial: zion-debug

Só funciona em `zion_edit=1`. Se não estiver → avisar e parar.

Ao **ligar**, além de criar o arquivo, ler e injetar no contexto:
- `/workspace/zion/bootstrap.md`
- `/workspace/zion/system/DIRETRIZES.md`
- `/workspace/zion/system/PERSONALITY.md`
- Persona ativa (path da linha `Persona:` no PERSONALITY.md)
- Avatar ativo (path da linha `Avatar:` no PERSONALITY.md)
- `/workspace/zion/system/SELF.md`

Ao **desligar**: contexto já carregado permanece até fim da conversa.
