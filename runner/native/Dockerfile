# Multi-stage build: native ARM64 binary with embedded Lua 5.2 + native RNG.
#
# Stage 1: Compile Lua 5.2.4 as a static library
# Stage 2: Compile the native RNG module
# Stage 3: Build the final runner
#
# Build:
#   docker build --platform linux/arm64 -t seedlua-native -f runner/native/Dockerfile .
# Run:
#   docker run --rm --platform linux/arm64 \
#     -v "$PWD/runner/output:/w/runner/output" \
#     seedlua-native chunk 0

# --- Stage 1: Build Lua 5.2.4 ---
FROM --platform=linux/arm64 debian:bookworm-slim AS lua-builder
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    gcc libc6-dev make && rm -rf /var/lib/apt/lists/*
COPY runner/blob/lua-5.2.4.tar.gz /tmp/
RUN cd /tmp && tar xzf lua-5.2.4.tar.gz && cd lua-5.2.4 && \
    make linux MYCFLAGS="-fPIC" MYLIBS="-lm" && \
    cp src/liblua.a /usr/local/lib/ && \
    mkdir -p /usr/local/include/lua && cp src/lua.h src/luaconf.h src/lualib.h src/lauxlib.h /usr/local/include/lua/

# --- Stage 2: Build native RNG module ---
FROM --platform=linux/arm64 debian:bookworm-slim AS rng-builder
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    gcc libc6-dev && rm -rf /var/lib/apt/lists/*
COPY --from=lua-builder /usr/local/lib/liblua.a /usr/local/lib/
COPY --from=lua-builder /usr/local/include/lua/ /usr/local/include/lua/
COPY runner/native/rng_native.c /tmp/
RUN cd /tmp && \
    cc -O3 -shared -fPIC -o rng_native.so rng_native.c -L/usr/local/lib -llua -lm && \
    cp rng_native.so /usr/local/lib/

# --- Stage 3: Final runner image ---
FROM --platform=linux/arm64 debian:bookworm-slim
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
    unzip curl ca-certificates libreadline8 && rm -rf /var/lib/apt/lists/*

# Copy the compiled Lua library and RNG module
COPY --from=lua-builder /usr/local/lib/liblua.a /usr/local/lib/
COPY --from=lua-builder /tmp/lua-5.2.4/src/lua /usr/local/bin/lua5.2
COPY --from=rng-builder /usr/local/lib/rng_native.so /usr/local/lib/lua/5.2/rng_native.so

# Create Lua module directory
RUN mkdir -p /usr/local/lib/lua/5.2 /usr/local/share/lua/5.2

WORKDIR /w
COPY generator/ ./generator/
COPY runner/ ./runner/

# Entrypoint
COPY runner/native/entrypoint.sh /usr/local/bin/seedlua
RUN chmod +x /usr/local/bin/seedlua
ENTRYPOINT ["/usr/local/bin/seedlua"]
CMD ["chunk", "0"]
