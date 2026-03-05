FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && \
  apt-get install -y curl ca-certificates file && \
  rm -rf /var/lib/apt/lists/*

# Download prebuilt NullClaw binary
RUN curl -fL https://github.com/nullclaw/nullclaw/releases/latest/download/nullclaw-linux-amd64 \
  -o /usr/local/bin/nullclaw && \
  chmod +x /usr/local/bin/nullclaw && \
  file /usr/local/bin/nullclaw

EXPOSE 3002

CMD ["nullclaw"]
