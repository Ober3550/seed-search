# Quick fix: generate GT overlay using Python reading the zig BMP bytes properly
import json, struct, sys

gt_path = sys.argv[1]
noise_path = sys.argv[2]
out_path = sys.argv[3]

gt = set()
with open(gt_path) as f:
    for line in f:
        e = json.loads(line.strip())
        if e["n"] == "iron-ore" and abs(e["x"]) < 128 and abs(e["y"]) < 128:
            gt.add((e["x"], e["y"]))

with open(noise_path, "rb") as f:
    data = bytearray(f.read())

# Parse BMP header to find data offset and dimensions
import struct as st
data_off = st.unpack_from('<I', data, 10)[0]
width = st.unpack_from('<i', data, 18)[0]
height = abs(st.unpack_from('<i', data, 22)[0])
bpp = st.unpack_from('<H', data, 28)[0]
print(f"BMP: {width}x{height} {bpp}bpp, data at {data_off}")

row_size = ((width * 3 + 3) // 4) * 4
pixels = data[data_off:]

# The zig BMP writer uses BGR order (B at offset 0, G at 1, R at 2)
# Let's find the actual channel order by looking at a known pixel
# All noise pixels are greyscale so R=G=B. After overlay, we want RED.
# Try both BGR and RGB
for (x, y) in gt:
    px = x + 128
    py_bmp = (height - 1) - (y + 128)
    if 0 <= px < width and 0 <= py_bmp < height:
        idx = py_bmp * row_size + px * 3
        # Try setting the "R" channel — if BGR order, R is offset 2
        # If RGB order, R is offset 0
        # Let's just set ALL three to known values: B=0, G=255, R=0 = green
        # If user sees green, we know the order
        pixels[idx] = 0        # assume B
        pixels[idx + 1] = 255  # assume G
        pixels[idx + 2] = 0    # assume R

# Write
new_data = bytearray(data[:data_off])
for y in range(height-1, -1, -1):
    new_data.extend(pixels[y*row_size:(y+1)*row_size])

with open(out_path, "wb") as f:
    f.write(new_data)
print(f"Wrote {out_path} — GT tiles marked in GREEN")
