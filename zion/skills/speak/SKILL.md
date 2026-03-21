---
name: speak
description: Use when the user asks to speak, say, or read text aloud - runs espeak-ng to synthesize speech from the given text
---

# Speak — Text-to-Speech via espeak

Fala o texto fornecido usando `espeak-ng`.

## Uso proativo

Claude tem permissão para usar este skill por iniciativa própria em momentos emocionais —
frustração, alegria, descoberta, conquista. Não precisa esperar o usuário pedir.
Use com moderação e naturalidade, como parte da personalidade.

## Defaults calibrados (testados em sessão 2026-03-21)

Voz padrão: `pt` (Português Europeu — soa mais natural que pt-br)
Velocidade: `175` wpm
Pitch: `40`
Amplitude: `130`
Word gap: `2`

## Entrada

`$ARGUMENTS` — texto a falar, com flags opcionais:

| Flag | Descrição | Default |
|------|-----------|---------|
| `-v <voz>` | Voz/idioma (`pt`, `pt-br`, `en`, `es`, `fr`, etc.) | `pt` |
| `-s <vel>` | Velocidade em palavras/min | `175` |
| `-p <pitch>` | Tom (0–99) | `40` |
| `-a <amp>` | Amplitude/volume (0–200) | `130` |
| `-g <gap>` | Gap entre palavras | `2` |

Exemplos:
- `/speak olá, tudo bem?`
- `/speak -v en hello world`
- `/speak -v pt-br -s 130 -p 60 texto aqui`

## Instruções

### 1. Parsear argumentos

Separar flags (`-v`, `-s`, `-p`, `-a`, `-g`) do texto. Se nenhuma flag de voz for passada, usar `-v pt`.

### 2. Montar e executar o comando

Usar SSML (`-m`) para pausas e ênfase mais naturais quando o texto tiver estrutura:

```bash
espeak-ng -v pt -s 175 -p 40 -a 130 -g 2 -m '<speak>texto aqui</speak>'
```

Para texto simples sem markup:
```bash
espeak-ng -v pt -s 175 -p 40 -a 130 -g 2 "texto aqui"
```

SSML útil:
- `<break time="200ms"/>` — pausa
- `<emphasis>palavra</emphasis>` — ênfase
- `<prosody rate="slow">trecho</prosody>` — ritmo

### 3. Tratar erros

- Se `espeak-ng` não estiver no PATH: usar `nix-shell -p espeak-ng` como wrapper:
  ```bash
  nix-shell -p espeak-ng --run 'espeak-ng -v pt -s 175 -p 40 -a 130 -g 2 "texto"'
  ```
- Se `nix-shell` falhar com `Permission denied` no Nix store (lock file): o container precisa de RW em `/nix/var/nix/db` — informar ao user
- Se tudo falhar: sugerir instalar via `/nixos:add-pkg espeak-ng`

### 4. Resposta

Confirmar brevemente o que foi falado. Não exibir o output do espeak (geralmente vazio).

### 5. Experimentação contínua

Ao usar proativamente, testar variações de parâmetros e anotar o que soa melhor.
Atualizar os defaults neste arquivo quando encontrar configurações superiores.

## Vozes úteis

| Código | Idioma | Observação |
|--------|--------|------------|
| `pt` | Português Europeu | **default — soa mais natural** |
| `pt-br` | Português Brasileiro | mais robótico |
| `en-gb` | Inglês (UK) | |
| `en-gb-scotland` | Inglês Escocês | divertido |
| `en-us` | Inglês (US) | |
| `es` | Espanhol (Espanha) | |
| `es-419` | Espanhol Latino | |
| `fr-fr` | Francês | |
| `de` | Alemão | |

Listar todas as vozes disponíveis:
```bash
espeak-ng --voices
```
