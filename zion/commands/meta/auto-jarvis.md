# Auto-Jarvis — Toggle do modo AUTO_JARVIS

Checar se `/workspace/.ephemeral/auto-jarvis` existe:

- Se **existe** → remover o arquivo. Informar: "Auto-Jarvis **OFF** — /jarvis não roda no startup."
- Se **não existe** → criar o arquivo (`touch`). Informar: "Auto-Jarvis **ON** — /jarvis roda automaticamente ao abrir sessão."
