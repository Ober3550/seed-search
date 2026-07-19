# Minimal Docker image for the Zig seed finder.
#
# Build the binary first on your host, then:
#   docker build -t seedgen -f Dockerfile.zig .
#
# Or use docker compose:
#   docker compose up --build
#
# The binary must be compiled for the target platform:
#   Native (macOS/Linux):  cd generator/zig && zig build-exe main.zig -O ReleaseFast -femit-bin=seedgen
#   Linux x86_64 target:   cd generator/zig && zig build-exe main.zig -O ReleaseFast -femit-bin=seedgen -target x86_64-linux-musl

FROM debian:bookworm-slim
WORKDIR /workspace
COPY generator/zig/seedgen /usr/local/bin/seedgen
RUN mkdir -p /workspace/output
ENTRYPOINT ["/usr/local/bin/seedgen"]
