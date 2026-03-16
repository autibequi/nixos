# Claudinho — prompts e persona

Esta pasta contém **apenas conteúdo de prompts e persona** do agente Claude:

- **personas/** — personas e avatares (`.persona.md`, `avatar/`)
- **SOUL.md**, **SELF.md**, **DIRETRIZES.md** — identidade e diretrizes
- **CONTAINER_INIT.md**, **FONTS.md** — documentação

Toda a **lógica de container, workers e tasks** está no **CLI `claudio`**:

- **`claudinho/claudio-cli/`** — código do CLI (bashly), Docker, docker-compose, Make-equivalent
- Uso: `claudio --help`, `claudio build`, `claudio worker`, `claudio status`, etc.

Instalação do CLI: `claudio install` (regenera e cria symlink em `stow/.local/bin/claudio`).
