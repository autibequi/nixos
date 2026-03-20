Toggle do modo ZION DEBUG. Só funciona quando `zion_edit=1` (sessão nixos/zion).

## O que é

**Zion Debug** carrega o contexto completo do Zion na sessão:
- BOOTSTRAP (mapa de arquivos e flags)
- DIRETRIZES (regras operacionais completas)
- PERSONALITY + persona GLaDOS + avatar
- SELF (diário da sessão)

Por padrão todas as sessões iniciam em **lite mode** (~3k tokens).
Zion Debug carrega o segundo stage (~10k tokens adicionais) quando necessário.

## Quando usar

Chamar automaticamente quando a task envolver:
- Edição de módulos NixOS, Hyprland, dotfiles
- Alteração de `zion/` (CLI, hooks, skills, personas, agents)
- Questões sobre persona, avatar ou DIRETRIZES
- Debug do próprio sistema Zion

## Procedimento

1. Verificar se está em ambiente zion_edit (checar `zion_edit=1` no boot ou se `/workspace/logs` existe).
   Se não estiver: informar "Zion Debug só disponível em sessão zion lab." e parar.

2. Verificar flag: `/workspace/.ephemeral/zion-debug`

3. **Se OFF → ligar:**
   - Criar o arquivo `/workspace/.ephemeral/zion-debug`
   - Ler e exibir o conteúdo dos arquivos abaixo (injetando no contexto):
     - `/workspace/zion/bootstrap.md` (ou `/workspace/mnt/zion/bootstrap.md`)
     - `/workspace/zion/system/DIRETRIZES.md`
     - `/workspace/zion/system/PERSONALITY.md`
     - Persona ativa (ler path da linha `Persona:` no PERSONALITY.md)
     - Avatar ativo (ler path da linha `Avatar:` no PERSONALITY.md)
     - `/workspace/zion/system/SELF.md`
   - Confirmar: "**Zion Debug ON** — contexto completo carregado nesta sessão. Próximas sessões também iniciarão com debug ativo."

4. **Se ON → desligar:**
   - Remover o arquivo `/workspace/.ephemeral/zion-debug`
   - Confirmar: "**Zion Debug OFF** — lite mode ativado. Efeito completo na próxima sessão."
   - Nota: o contexto já carregado nesta sessão permanece até o fim da conversa.
