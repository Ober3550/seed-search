#!/usr/bin/env python3
"""Minimal Factorio RCON client (Source RCON protocol), stdlib only.

Migrated from factorio-ai/bridge/src/rcon.ts. Factorio sends each rcon.print()
result as a single complete packet (it does not split large responses the way
some Source servers do), so we read one response packet per command.

Packet layout (little-endian):
    int32 size   -- number of bytes after this field
    int32 id     -- request id
    int32 type   -- 3=AUTH, 2=COMMAND/AUTH_RESPONSE, 0=RESPONSE
    bytes body   -- null-terminated ASCII
    byte  0x00   -- empty-string terminator
"""
import socket
import struct
import time

AUTH = 3
COMMAND = 2
RESPONSE_VALUE = 0


class RconError(Exception):
    pass


class RconClient:
    def __init__(self, host="127.0.0.1", port=25575, password="", timeout=15.0):
        self.host = host
        self.port = port
        self.password = password
        self.timeout = timeout
        self._sock = None
        self._id = 0

    def connect(self):
        self._sock = socket.create_connection((self.host, self.port), timeout=self.timeout)
        self._sock.settimeout(self.timeout)
        # Authenticate.
        rid = self._send(AUTH, self.password)
        _, resp_id, _ = self._recv()
        if resp_id == -1:
            raise RconError("RCON authentication failed (wrong password)")
        return self

    def command(self, body):
        self._send(COMMAND, body)
        _, _, payload = self._recv()
        return payload

    def close(self):
        if self._sock:
            try:
                self._sock.close()
            finally:
                self._sock = None

    # ── framing ──────────────────────────────────────────────────────────────
    def _send(self, type_, body):
        self._id += 1
        rid = self._id
        data = struct.pack("<ii", rid, type_) + body.encode("ascii", "replace") + b"\x00\x00"
        self._sock.sendall(struct.pack("<i", len(data)) + data)
        return rid

    def _recv_exact(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self._sock.recv(n - len(buf))
            if not chunk:
                raise RconError("RCON connection closed mid-packet")
            buf += chunk
        return buf

    def _recv(self):
        size = struct.unpack("<i", self._recv_exact(4))[0]
        data = self._recv_exact(size)
        rid, type_ = struct.unpack("<ii", data[:8])
        body = data[8:-2].decode("ascii", "replace")  # strip the two null terminators
        return type_, rid, body


def wait_for_rcon(host, port, password, deadline_s=120.0, poll_s=2.0):
    """Poll until the server accepts an authenticated RCON connection."""
    start = time.time()
    last_err = None
    while time.time() - start < deadline_s:
        try:
            c = RconClient(host, port, password, timeout=5.0)
            c.connect()
            return c
        except (OSError, RconError) as e:
            last_err = e
            time.sleep(poll_s)
    raise RconError(f"RCON not ready after {deadline_s:.0f}s: {last_err}")


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 4:
        print("usage: rcon.py <host> <port> <password> [command...]", file=sys.stderr)
        sys.exit(2)
    host, port, password = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    cmd = " ".join(sys.argv[4:]) or "/sc rcon.print('pong')"
    client = RconClient(host, port, password).connect()
    print(client.command(cmd))
    client.close()
