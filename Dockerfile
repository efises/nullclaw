# ---------- BUILD STAGE ----------
FROM debian:bookworm-slim AS builder

WORKDIR /build

RUN apt-get update && \
  apt-get install -y curl xz-utils ca-certificates build-essential && \
  rm -rf /var/lib/apt/lists/*

# Install Zig 0.15.2
RUN curl -L https://ziglang.org/builds/zig-linux-x86_64-0.15.2.tar.xz \
  | tar -xJ && \
  mv zig-linux-* /usr/local/zig

ENV PATH="/usr/local/zig:$PATH"

# Copy NullClaw source
COPY . .

# Build
RUN zig build --release=fast


# ---------- RUNTIME STAGE ----------
FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && \
  apt-get install -y ca-certificates && \
  rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/zig-out/bin/nullclaw /usr/local/bin/nullclaw

EXPOSE 3002

CMD ["nullclaw"]
