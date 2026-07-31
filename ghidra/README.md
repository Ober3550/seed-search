# Ghidra Reverse Engineering — Factorio Surface Generation

## Setup

1. **Launch Ghidra** (GUI already started via `ghidraRun`):
   ```bash
   /opt/homebrew/bin/ghidraRun
   ```

2. **Create a new project**:
   - File → New Project → Non-Shared Project
   - Set project directory to: `$(pwd)/ghidra/project`
   - Name: `factorio-surface-gen`

3. **Import the Factorio binary**:
   - File → Import File
   - Select: `/Applications/Factorio.app/Contents/MacOS/factorio`
   - It's a Mach-O universal binary — choose **arm64** (aarch64) for Apple Silicon analysis
   - Use default analysis options, but enable:
     - Decompiler Parameter ID
     - Stack Analysis
     - Data Reference Analysis

4. **Run analysis** — this will take several minutes for a binary this size (~50MB).

## Target Functions

Key areas to identify in the binary:

### Map Generation Pipeline
| Lua/Symbol         | C++ Equivalent               | Pattern to Search                   |
| ------------------ | ---------------------------- | ----------------------------------- |
| `MapGenSettings`   | `MapGenSettings` struct      | String refs to "water", "autoplace" |
| `noise.expression` | `NoiseExpression` evaluate() | Float math + RNG                    |
| `chunk.generate()` | `Chunk::generate()`          | 32×32 loop, tile placement          |
| `autoplace`        | `AutoplaceGenerator`         | Probability distribution, peaks     |

### RNG
Search for the characteristic triple-LFSR pattern:
```
s1 = ((s1 & 0xFFFFFFFE) << 12) ^ (((s1 << 13) ^ s1) >> 19)
s2 = ((s2 & 0xFFFFFFF8) <<  4) ^ (((s2 <<  2) ^ s2) >> 25)
s3 = ((s3 & 0xFFFFFFF0) << 17) ^ (((s3 <<  3) ^ s3) >> 11)
```

### Noise Functions
Look for standard noise implementations:
- Perlin noise (gradient dot products)
- Simplex noise (skew factors)
- Voronoi distance calculations

## Approach

1. **String search** — Find references to "noise", "autoplace", "chunk", "tile"
2. **Cross-reference with Lua** — SE/open-source mods define the Lua API; trace how those calls reach C++
3. **Trace RNG calls** — The RNG is called everywhere; find it first, then work outward
4. **Compare with known implementations** — Factorio's noise is similar to standard Perlin/Simplex

## Scripts

- `scripts/FindRng.java` — Ghidra script to locate RNG constants
- `scripts/ExportChunkGen.java` — Export decompiled chunk generation to .c files
