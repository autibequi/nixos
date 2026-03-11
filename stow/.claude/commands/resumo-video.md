Resuma o conteúdo de um vídeo do YouTube a partir da sua transcrição.

## Entrada
- $ARGUMENTS: URL do vídeo do YouTube

## Instruções

1. Use `yt-dlp` para baixar apenas as legendas (sem baixar o vídeo):
   ```
   yt-dlp --write-auto-sub --sub-lang "pt,en" --skip-download --sub-format vtt -o "/tmp/yt_transcript" "<URL>"
   ```
   - Priorize legendas em português (`pt`), fallback para inglês (`en`)
   - Use `--skip-download` para não baixar o vídeo em si

2. Pegue também o título e descrição do vídeo:
   ```
   yt-dlp --get-title --get-description "<URL>"
   ```

3. Leia o arquivo `.vtt` gerado em `/tmp/yt_transcript.<lang>.vtt`
   - Se o arquivo for grande demais, extraia apenas o texto (removendo timestamps e tags VTT):
     ```
     sed 's/<[^>]*>//g' arquivo.vtt | grep -v '^$' | grep -v '^WEBVTT' | grep -v '^Kind:' | grep -v '^Language:' | grep -v '^\s*$' | grep -v '^[0-9][0-9]:[0-9][0-9]' | sort -u
     ```

4. Gere um resumo em português intercalando texto e mini-diagramas ASCII:
   - Titulo do video e canal
   - Para cada ponto principal ou grupo de pontos relacionados, escreva o texto explicativo em bullets e, quando fizer sentido, insira um mini-diagrama ASCII inline para ilustrar a relacao entre conceitos (fluxo, comparacao, timeline, etc.)
   - Nem todo ponto precisa de diagrama — use apenas quando agrega valor visual
   - Conclusao ou takeaway geral no final

   Regras para os diagramas ASCII:
   - SEM borda externa grande envolvendo o diagrama inteiro
   - Pode usar caixas pequenas internas para representar conceitos (ex: [Ponto A] --> [Ponto B])
   - Use setas simples: -->, <--, |, v, *, #
   - NÃO use caracteres Unicode para bordas (nada de ╔═║╗╚╝┌─┐└┘│)
   - Pode usar +--+ para caixas pequenas internas
   - NÃO use emojis
   - Maximo 50 colunas de largura
   - Mantenha simples: 3-8 linhas por diagrama
   - Coloque cada diagrama dentro de um bloco de codigo markdown (```) para separar visualmente do texto
   - Exemplo de estilo:

     ```
     +------------+     +----------+
     | Non-profit |---->| Empresa  |
     +------------+     +----------+
                             |
                             v
                       +-----------+
                       |    IPO    |
                       +-----------+
     ```

     ```
     Receita: ???
     Gastos:  $$$ bilhoes/mes
     Gap:     ENORME
     ```

5. Apos o resumo com mini-diagramas, gere um infografico final maior que conecte TODOS os pontos principais do video em um unico diagrama de visao global:
   - Use o titulo do video como cabecalho (linha de === ou ---)
   - Conecte os conceitos principais com setas mostrando causa/efeito ou sequencia
   - SEM borda externa grande envolvendo tudo
   - Mesmas regras dos mini-diagramas: caixas internas com +--+, setas simples, sem Unicode, sem emojis
   - Maximo 50 colunas de largura
   - Coloque dentro de um bloco de codigo markdown (```)
   - Exemplo de estilo:

     ```
     TITULO DO VIDEO
     ===============

     +--------+    +--------+
     | Causa  |--->| Efeito |
     +--------+    +--------+
          |             |
          v             v
     +--------+    +---------+
     | Prob 1 |    | Prob 2  |
     +--------+    +---------+
           \          /
            v        v
         +-----------+
         | Conclusao |
         +-----------+
     ```

6. Limpe os arquivos temporários após terminar:
   ```
   rm -f /tmp/yt_transcript*
   ```
