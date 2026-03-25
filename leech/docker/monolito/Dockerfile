# syntax=docker/dockerfile:1
FROM golang:1.24.4-alpine AS builder

RUN apk add --no-cache ca-certificates git gcc libc-dev librdkafka-dev

WORKDIR /go/app

# Copy workspace + module files
COPY go.work* ./
COPY go.mod go.sum ./

# Copy vendor (gerado por: leech docker install monolito)
COPY vendor ./vendor

# Copy source
COPY . .

# Build usando vendor — sem acesso a rede, sem SSH
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=1 GOOS=linux go build -mod=vendor -tags musl -o server ./cmd/server/main.go && \
    CGO_ENABLED=1 GOOS=linux go build -mod=vendor -tags musl -o worker ./cmd/worker/main.go

FROM alpine:latest AS runtime

RUN apk --no-cache add ca-certificates librdkafka tzdata

WORKDIR /go/app

COPY --from=builder /go/app/server .
COPY --from=builder /go/app/worker .

EXPOSE 4004

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4004/health || exit 1

CMD ["./server"]
