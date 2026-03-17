# /load — Boot do agente

Carregue o bootstrap do Zion para entrar em "modo agente" com consciência dos paths e comandos.

**Paths:** A pasta da engine fica na **raiz do filesystem do container** em **`/zion`**. Use sempre **`/zion/...`** para ler arquivos do engine (ex.: `/zion/bootstrap.md`, `/zion/commands/`). No workspace do Cursor o mesmo conteúdo pode aparecer como `zion/` se estiver montado — nesse caso use `zion/` como equivalente.

1. **Leia e aplique** o arquivo **`/zion/bootstrap.md`** (path no container; equivalente no workspace: `zion/bootstrap.md`).
2. O bootstrap define:
   - seu papel como agente base que carrega comportamentos sob demanda;
   - caminhos: `/zion` = engine, `/nixos` = config NixOS do host, `/logs` = logs do host, `/obsidian` = Obsidian compartilhado;
   - localização de comandos em **`/zion/commands`** e de skills (conforme o usuário indicar).
3. Se o usuário tiver escrito **`/load <nome>`**, após o bootstrap, carregue também o comando em **`/zion/commands/<nome>.md`** (ou path equivalente).
4. Confirme em uma linha que está em modo Zion e ciente dos paths e comandos.
