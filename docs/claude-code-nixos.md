# Claude Code no NixOS

## Por que aparece "switched from npm to native installer"

O app mostra esse aviso quando acha que você ainda está no install antigo (npm). No seu caso você **já usa o binário nativo** via flake `sadjow/claude-code-nix` (native binary, atualizações horárias). O banner é genérico e pode aparecer mesmo quando o binário é nativo, por exemplo se:

- o executável não estiver em `~/.local/bin/claude` (no Nix fica em `/nix/store/.../bin/claude`), ou
- o app não reconhecer o “install method” quando vem do Nix.

Não é erro do seu sistema: é o app sugerindo migração para quem ainda usava npm.

## Opções para o banner

1. **Ignorar** — é só informativo; o app funciona normalmente.
2. **Dispensar na UI** — se aparecer um X ou “Don’t show again”, use.
3. **Launcher em ~/.local/bin** (opcional): criar um wrapper que chama o binário do Nix pode fazer o app “achar” que está no path típico do native install; não há garantia de que isso remova o banner, mas em alguns setups reduz avisos.

## Auto-atualizar

- **Com Nix (seu caso):** a versão é a do flake. Para atualizar:
  ```bash
  nix flake update claude-code
  nh os test .   # ou rebuild
  ```
  O repositório `sadjow/claude-code-nix` atualiza o pacote com frequência (ex.: horária); o seu “auto-update” é rodar `nix flake update` e rebuild quando quiser.
- **Built-in do app:** o auto-updater de fundo do “native installer” oficial (curl|bash) **não** roda quando o binário vem do Nix store (diretório read-only). Não dá para “ligar uma flag” e fazer esse updater atualizar o binário Nix; o canal de atualização é o Nix.

## Configuração útil no settings

Em `stow/.claude/settings.json` (ou user/project) você pode usar:

- `autoUpdatesChannel`: `"latest"` (padrão) ou `"stable"` — só afeta o comportamento do updater **interno** do app (quando ele puder atualizar; no Nix normalmente não consegue). Deixar em `"latest"` não atrapalha.

Não existe setting documentado para “não mostrar o aviso de migração npm → native”. O que existe é o app parar de mostrar depois de rodar `claude install` (que instala em `~/.local/bin`); em NixOS isso duplicaria o install e não é necessário.

**Resumo:** você já está no modelo “native” via Nix; o banner é cosmético. Atualizações = `nix flake update claude-code` + rebuild.
