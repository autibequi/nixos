# syntax=docker/dockerfile:1
FROM golang:1.24.4-alpine AS builder

RUN apk add --no-cache ca-certificates git gcc libc-dev librdkafka-dev

WORKDIR /go/app

COPY go.mod go.sum ./
COPY vendor ./vendor
COPY . .

# Build usando vendor — sem acesso a rede, sem SSH necessário
RUN CGO_ENABLED=1 GOOS=linux go build -mod=vendor -tags musl -o server ./cmd/server/main.go
RUN CGO_ENABLED=1 GOOS=linux go build -mod=vendor -tags musl -o worker ./cmd/worker/main.go

FROM alpine:latest AS runtime

RUN apk --no-cache add ca-certificates librdkafka

WORKDIR /go/app

COPY --from=builder /go/app/server .
COPY --from=builder /go/app/worker .

EXPOSE 4001 4004

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4004/health || exit 1

CMD ["./server"]
