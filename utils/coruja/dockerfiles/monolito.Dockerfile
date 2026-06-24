# syntax=docker/dockerfile:1
# Só toolchain Go + Delve; código vem do monorepo apps/ montado em /go/apps.
# Monolito roda a partir de /go/apps/monolito (go.work referencia SDKs irmaos via ../).
# Arranque: go run (compila em runtime; sem COPY, sem vendor, sem go build no Dockerfile).

FROM golang:1.26.1-alpine

RUN apk add --no-cache ca-certificates git gcc libc-dev librdkafka-dev openssh-client wget socat

ENV GOPRIVATE=github.com/estrategiahq/*
ENV GIT_TERMINAL_PROMPT=0
ENV GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new"
RUN git config --global url."git@github.com:estrategiahq/".insteadOf "https://github.com/estrategiahq/"

RUN go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install github.com/githubnemo/CompileDaemon@latest

WORKDIR /go/apps/monolito

ENV CGO_ENABLED=1

EXPOSE 4004

# HEALTHCHECK só no serviço app no compose (worker partilha a imagem).

CMD ["go", "run", "-tags", "musl", "./cmd/server/main.go"]
