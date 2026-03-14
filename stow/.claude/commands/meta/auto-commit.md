Toggle do modo AUTO_COMMIT. Checar se `/workspace/.ephemeral/auto-commit` existe:

- Se existe: remover o arquivo e confirmar "Auto-commit DESLIGADO"
- Se não existe: criar o arquivo (conteúdo: "on") e confirmar "Auto-commit LIGADO"

Quando AUTO_COMMIT está ON:
- Commitar automaticamente sem perguntar ao user
- Usar a identidade git interativa (Author=Pedrinho, Committer=Claudinho)
- Commit messages devem seguir conventional commits
- Ainda respeitar bom senso: não commitar código quebrado
