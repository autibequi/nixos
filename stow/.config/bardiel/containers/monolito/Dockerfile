# syntax=docker/dockerfile:1
# Targets: runtime (prod) | runtime-debug (Delve + binários -N -l).
# Compose: app / worker → target runtime + DEBUG_BUILD=0; app-debug / worker-debug → runtime-debug + DEBUG_BUILD=1.

FROM golang:1.26.1-alpine AS builder

RUN apk add --no-cache ca-certificates git gcc libc-dev librdkafka-dev

WORKDIR /go/app

COPY go.work* ./
COPY go.mod go.sum ./
COPY vendor ./vendor
COPY . .

ARG DEBUG_BUILD=0
RUN go install github.com/go-delve/delve/cmd/dlv@latest

RUN --mount=type=cache,target=/root/.cache/go-build \
    sh -ec 'if [ "$DEBUG_BUILD" = "1" ]; then GF="-gcflags=all=-N -l"; else GF=""; fi; \
      CGO_ENABLED=1 GOOS=linux go build -mod=vendor -tags musl $GF -o server ./cmd/server/main.go && \
      CGO_ENABLED=1 GOOS=linux go build -mod=vendor -tags musl $GF -o worker ./cmd/worker/main.go'

FROM alpine:latest AS runtime-base

RUN apk --no-cache add ca-certificates librdkafka tzdata

WORKDIR /go/app

COPY --from=builder /go/app/server .
COPY --from=builder /go/app/worker .

FROM runtime-base AS runtime

EXPOSE 4004

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4004/health || exit 1

CMD ["./server"]

FROM runtime-base AS runtime-debug

COPY --from=builder /go/bin/dlv /usr/local/bin/dlv

EXPOSE 4004 2345

CMD ["/usr/local/bin/dlv", "exec", "./server", \
     "--headless", "--listen=:2345", "--api-version=2", \
     "--accept-multiclient", "--continue"]
