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

4. Gere um resumo em português com:
   - Título do vídeo
   - Pontos principais (bullets)
   - Conclusão ou takeaway geral

5. Limpe os arquivos temporários após terminar:
   ```
   rm -f /tmp/yt_transcript*
   ```
