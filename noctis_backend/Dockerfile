# NOCTIS backend container — multi-stage build.
FROM golang:1.22-alpine AS builder
WORKDIR /src
RUN apk add --no-cache git
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags='-s -w' -o /out/noctis ./cmd/noctis

FROM alpine:3.20
RUN apk add --no-cache ca-certificates curl tzdata
WORKDIR /app
COPY --from=builder /out/noctis /app/noctis
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
  CMD curl -fsS http://localhost:8080/healthz || exit 1
ENTRYPOINT ["/app/noctis"]
