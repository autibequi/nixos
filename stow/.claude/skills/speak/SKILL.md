---
name: speak
description: Use when the user asks to speak, say, or read text aloud - runs espeak-ng to synthesize speech from the given text
---

# Speak — Text-to-Speech via espeak

Fala o texto fornecido usando `espeak-ng`.

## Entrada

`$ARGUMENTS` — texto a falar, com flags opcionais:

| Flag | Descrição | Default |
|------|-----------|---------|
| `-v <voz>` | Voz/idioma (`pt-br`, `en`, `es`, `fr`, etc.) | `pt-br` |
| `-s <vel>` | Velocidade em palavras/min | `150` |
| `-p <pitch>` | Tom (0–99) | `50` |
| `-a <amp>` | Amplitude/volume (0–200) | `100` |

Exemplos:
- `/speak olá, tudo bem?`
- `/speak -v en hello world`
- `/speak -v pt-br -s 130 -p 60 texto aqui`

## Instruções

### 1. Parsear argumentos

Separar flags (`-v`, `-s`, `-p`, `-a`) do texto. Se nenhuma flag de voz for passada, usar `-v pt-br`.

### 2. Montar e executar o comando

```bash
espeak-ng -v <voz> -s <velocidade> -p <pitch> -a <amplitude> "<texto>"
```

Exemplo prático:
```bash
espeak-ng -v pt-br -s 150 -p 50 "olá, tudo bem?"
```

### 3. Tratar erros

- Se `espeak-ng` não estiver no PATH: usar `nix-shell -p espeak-ng` como wrapper:
  ```bash
  nix-shell -p espeak-ng --run 'espeak-ng -v <voz> -s <vel> -p <pitch> "<texto>"'
  ```
- Se `nix-shell` falhar com `Permission denied` no Nix store (lock file): o container precisa de RW em `/nix/var/nix/db` — informar ao user
- Se tudo falhar: sugerir instalar via `/add-pkg espeak-ng`

### 4. Resposta

Confirmar brevemente o que foi falado, ex:
> Falei: "olá, tudo bem?" (voz: pt-br, vel: 150)

Não exibir o output do espeak (geralmente vazio).

## Vozes úteis

| Código | Idioma |
|--------|--------|
| `pt-br` | Português Brasileiro |
| `pt` | Português Europeu |
| `en` | Inglês (US) |
| `en-gb` | Inglês (UK) |
| `es` | Espanhol |
| `fr` | Francês |
| `de` | Alemão |
| `ja` | Japonês |

Listar todas as vozes disponíveis:
```bash
espeak-ng --voices
```
