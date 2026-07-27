#!/usr/bin/env python3
"""Convert BMP to PNG using only stdlib (struct + zlib). No Pillow needed.

Usage: python3 bmp2png.py <input.bmp> [output.png]
"""

import struct, zlib, sys, os


def bmp_to_png(bmp_path, png_path=None):
    if png_path is None:
        png_path = os.path.splitext(bmp_path)[0] + ".png"

    with open(bmp_path, "rb") as f:
        # BMP header
        assert f.read(2) == b"BM", "not a BMP"
        f.seek(10)
        data_offset = struct.unpack("<I", f.read(4))[0]
        f.seek(18)
        w = struct.unpack("<i", f.read(4))[0]
        h = struct.unpack("<i", f.read(4))[0]  # positive = bottom-up
        f.seek(28)
        bits = struct.unpack("<H", f.read(2))[0]
        assert bits == 24, f"only 24-bit BMP supported, got {bits}"

        # Read pixel rows (bottom-up in BMP). 24-bit BMP pixels are stored BGR;
        # PNG wants RGB, so swap the R and B channels per row.
        # Derive the actual row stride from the file size: standard BMPs pad rows
        # to 4 bytes, but the ore-counter mod writes unpadded rows (w*3). Pick the
        # stride that the pixel data actually uses.
        import os as _os
        avail = _os.path.getsize(bmp_path) - data_offset
        padded = ((w * 3 + 3) // 4) * 4
        row_size = padded if avail >= padded * h else (w * 3)
        rows = []
        for y in range(h):
            f.seek(data_offset + y * row_size)
            ba = bytearray(f.read(w * 3))
            b_ch, r_ch = bytes(ba[0::3]), bytes(ba[2::3])
            ba[0::3], ba[2::3] = r_ch, b_ch
            rows.append(bytes(ba))

    # The ore layer (oremap.bmp) is drawn on black; emit RGBA with the black
    # pixels transparent so terrain shows through underneath.
    alpha = "oremap" in os.path.basename(bmp_path)

    # PNG signature
    png_sig = b"\x89PNG\r\n\x1a\n"

    # IHDR chunk (color type 6 = RGBA, 2 = RGB)
    ihdr_data = struct.pack(">IIBBBBB", w, h, 8, 6 if alpha else 2, 0, 0, 0)
    ihdr = make_chunk(b"IHDR", ihdr_data)

    # IDAT: filter byte 0 + pixel data per row, compressed
    raw = b""
    for row in rows:
        if alpha:
            line = bytearray()
            for x in range(w):
                r, g, b = row[x * 3], row[x * 3 + 1], row[x * 3 + 2]
                line += bytes((r, g, b, 0 if (r == 0 and g == 0 and b == 0) else 255))
            raw += b"\x00" + bytes(line)
        else:
            raw += b"\x00" + row  # filter type 0 (None)
    idat = make_chunk(b"IDAT", zlib.compress(raw))

    # IEND
    iend = make_chunk(b"IEND", b"")

    with open(png_path, "wb") as f:
        f.write(png_sig)
        f.write(ihdr)
        f.write(idat)
        f.write(iend)

    png_size = os.path.getsize(png_path)
    print(f"  {os.path.basename(bmp_path)} → {os.path.basename(png_path)}  "
          f"({w}×{h}, {png_size:,} bytes)")
    return png_path


def make_chunk(chunk_type, data):
    chunk = chunk_type + data
    crc = struct.pack(">I", zlib.crc32(chunk) & 0xFFFFFFFF)
    return struct.pack(">I", len(data)) + chunk + crc


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: bmp2png.py <input.bmp> [output.png]")
        sys.exit(1)
    bmp_to_png(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
