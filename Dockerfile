FROM ubuntu:22.04

WORKDIR /app

RUN apt-get update && \
  apt-get install -y curl git build-essential ca-certificates xz-utils && \
  rm -rf /var/lib/apt/lists/*

# Install Zig
RUN curl -L https://ziglang.org/builds/zig-linux-x86_64-0.15.2.tar.xz \
  | tar -xJ && \
  mv zig-linux-* /zig

ENV PATH="/zig:$PATH"

COPY . .

# Build NullClaw
RUN zig build --release=fast -freference-trace

# Run gateway
CMD ["./zig-out/bin/nullclaw"]
