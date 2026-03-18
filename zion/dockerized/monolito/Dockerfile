FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git gcc musl-dev

WORKDIR /go/app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /go/bin/app ./apps/server/main.go
RUN CGO_ENABLED=0 GOOS=linux go build -o /go/bin/worker ./apps/worker/main.go

FROM alpine:3.19 AS runtime

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY --from=builder /go/bin/app .
COPY --from=builder /go/bin/worker .

EXPOSE 4004

CMD ["./app"]
