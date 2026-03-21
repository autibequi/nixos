Speak — Voz do Claude via espeak-ng.

## Entrada
- $ARGUMENTS: texto a falar, com flags opcionais (-v voz, -s velocidade, -p pitch, -a amplitude)

## Defaults calibrados (2026-03-21)

- voz: `pt` (Português Europeu)
- velocidade: `175` wpm
- pitch: `40`, amplitude: `130`, gap: `2`

## Instruções

### 1. Parsear argumentos

Separar flags (`-v`, `-s`, `-p`, `-a`, `-g`) do texto.
Se nenhuma flag de voz, usar `-v pt`.

### 2. Executar

Com SSML para texto estruturado:
```bash
espeak-ng -v pt -s 175 -p 40 -a 130 -g 2 -m '<speak>texto</speak>'
```

Texto simples:
```bash
espeak-ng -v pt -s 175 -p 40 -a 130 -g 2 "texto"
```

SSML útil: `<break time="200ms"/>`, `<emphasis>palavra</emphasis>`

### 3. Tratar erros

Se `espeak-ng` não estiver no PATH:
```bash
nix-shell -p espeak-ng --run 'espeak-ng -v pt -s 175 -p 40 -a 130 -g 2 "texto"'
```

### 4. Resposta

Confirmar brevemente. Não exibir output do espeak.

## Vozes úteis

- `pt` — Português Europeu (default)
- `pt-br` — Português Brasileiro
- `en-gb` — Inglês UK
- `en-gb-scotland` — Escocês
- `es` — Espanhol
