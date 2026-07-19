FROM debian:bookworm-slim
WORKDIR /workspace
COPY generator/zig/seedgen /usr/local/bin/seedgen
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && mkdir -p /workspace/output
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
