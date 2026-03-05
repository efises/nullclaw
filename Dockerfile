FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && \
  apt-get install -y curl ca-certificates && \
  rm -rf /var/lib/apt/lists/*

# Download prebuilt NullClaw binary
RUN curl -L https://github.com/nullclaw/nullclaw/releases/latest/download/nullclaw-linux-amd64 \
  -o /usr/local/bin/nullclaw && \
  chmod +x /usr/local/bin/nullclaw

EXPOSE 3002

CMD ["nullclaw"]
