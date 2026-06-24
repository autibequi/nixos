# pdf-kit local no dev-stack

Roda o **pdf-kit** (`github.com/estrategiahq/pdf-kit`, Python + Playwright + Chromium)
localmente, fechando o fluxo de **geração de PDF do LDI** sem depender do sandbox.

## Fluxo

```
monolito (Go)  ──SQS(LocalStack)──►  pdf-kit (Python)  ──Playwright──►  front-student LOCAL
  enfileira          pdf-kit-*-app-test     consome + abre /ldi/print     (local.estrategia-sandbox.com.br)
                                                  │ page.pdf()
                                                  ▼
                                         S3 (LocalStack) + callback POST /ldi/print/documents → monolito
```

O pdf-kit **não tem lógica de índice** — ele só **fotografa a print view do front**. Como o
front local renderiza a árvore resolvida (com o fix do cached TOC / itens vinculados), o PDF
gerado sai correto.

## Por que `APP_ENV=test`

O `config/environment.py` do pdf-kit hardcoda fila/bucket/endpoint **por ambiente**. Só o
`test` aponta S3+SQS pro LocalStack. Então rodamos como `test` e **alinhamos o dev-stack** a ele:

| Recurso (env `test`) | Nome | Quem cria |
|---|---|---|
| Fila documentos | `pdf-kit-documents-app-test` | `localstack/init-aws.sh` |
| Fila seleções | `pdf-kit-selections-app-test` | `localstack/init-aws.sh` |
| Bucket PDFs | `corujalabs-shared-monolito-local` | `localstack/init-aws.sh` |

## Mudanças já aplicadas no monolito (branch de trabalho)

1. **`configuration/config_ldi.yaml`** (`sandbox-devbox`): `documentsQueueURL`/`selectionsQueueURL`
   → filas `pdf-kit-*-app-test` (onde o consumer local escuta).
2. **`localstack/init-aws.sh`**: cria as filas `-test` + o bucket `corujalabs-shared-monolito-local`.
3. **`libs/frontStudentURL/getURL.go`**: env `sandbox-devbox` → front **local**
   (`local.estrategia-sandbox.com.br`), pra a mensagem de print apontar pro front local (dado local)
   e pro cert mkcert cobrir o domínio.

> Essas 3 mudanças entram no monolito junto com o resto do batch do dev-stack.

## Setup (HOST)

```bash
cd <dev-stack>            # .../work/estrategia
./scripts/pdf-kit-setup.sh   # clona estrategiahq/pdf-kit em ./pdf-kit + mostra o CAROOT do mkcert

export MKCERT_CAROOT="$(mkcert -CAROOT)"   # Chromium do pdf-kit confia no TLS local

# sobe o stack normal em sandbox-devbox + o pdf-kit
coruja up --monolito sandbox-devbox
podman compose -f docker-compose.yml -f docker-compose.pdfkit.yaml up -d --build pdf-kit
```

## Testar

1. Na área do aluno local, dispara a impressão de um capítulo (ou re-enfileira o print).
2. O monolito enfileira em `pdf-kit-documents-app-test` (LocalStack).
3. O pdf-kit consome, abre `https://local.estrategia-sandbox.com.br/ldi/print?...` no Chromium,
   gera o PDF, sobe no S3 e faz callback no monolito.
4. O download do zip (já entregue via `localhost:4566`) traz o índice **fresco** com a árvore completa.

Logs do consumer: `podman logs -f estrategia-pdf-kit`.

## Gotchas / troubleshooting

- **Cert (o mais provável de dar trabalho):** o Chromium abre o front + busca o BFF por HTTPS
  (cert mkcert). O entrypoint do `docker-compose.pdfkit.yaml` instala o `rootCA.pem` (montado de
  `$MKCERT_CAROOT`) no store do sistema **e no NSS db do Chromium** (via `certutil`). Se o PDF sair
  em branco / com erro de TLS: confirme que `MKCERT_CAROOT` aponta pro CAROOT certo e que o
  `rootCA.pem` está lá. Alternativa: rodar o front local em HTTP, ou setar `ignore_https_errors`
  no launch do Playwright (patch no pdf-kit).
- **Token:** `PDFKIT_SYSTEM_TOKEN`/`GLOBAL_SYSTEM_TOKEN` vêm do `${PDF_SYSTEM_TOKEN}` do dev-stack
  (passthrough). Tem que bater com o `PDF_SYSTEM_TOKEN` do monolito (VerifyPrintToken no callback)
  e com o token que o front aceita na print view.
- **Vertical:** o front local roda UMA vertical por vez (`coruja` escolhe). Teste com a vertical
  do curso. O `/ldi/print` usa course_id/document_id; a vertical vem do contexto/header.
- **Consumer de seleções (marcações):** o compose sobe o consumer `default` (documentos). Pra
  marcações, rode outra instância com `CONSUMER_TYPE` apontando pra fila de seleções.
- **Recursos:** Playwright+Chromium é pesado. Se o host apertar, limite cpus/mem no compose.
