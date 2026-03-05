FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && \
  apt-get install -y curl ca-certificates file && \
  rm -rf /var/lib/apt/lists/*

RUN curl -fL https://github.com/nullclaw/nullclaw/releases/download/v2026.3.4/nullclaw-linux-x86_64.bin \
  -o /usr/local/bin/nullclaw && \
  chmod +x /usr/local/bin/nullclaw && \
  file /usr/local/bin/nullclaw

EXPOSE 3002

CMD ["nullclaw", "serve", "--host", "0.0.0.0", "--port", "3002"]
