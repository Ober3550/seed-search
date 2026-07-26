/* ExportEntityPlacement.java — decompile Factorio's per-chunk entity/resource
 * placement (EntityMapGenerationTask::generateEntities @ ~0x1014cb5fc).
 *
 * Goal: extract the EXACT per-chunk placement RNG that turns a resource's
 * probability_expression into placed tiles:
 *   - per-32x32-chunk seed derivation (chunk_x/chunk_y, no map_seed/seed1),
 *   - RNG type + how it is advanced (per tile? per candidate? per resource?),
 *   - the compare (rng * 2^-32 < probability) and the tile iteration ORDER.
 * This is what crude-oil (random_probability=1/48) needs to match tile-for-tile.
 *
 * Usage: open the factorio arm64 program in Ghidra, run this script. Writes
 *   ghidra/export/entity_placement.c
 */

import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class ExportEntityPlacement extends GhidraScript {

    // Known/candidate targets. The first is from prior notes; the script also
    // searches for the placement constants to find the real function if this
    // address drifted between builds.
    private static final long[] TARGETS = {
        0x1014cb5fcL, // EntityMapGenerationTask::generateEntities (per notes)
    };

    // Constants distinctive to the per-chunk placement seed: 7907, 7919, 0x3fbe2c.
    // Search for functions whose body references these to locate the roll.
    private static final long TEXT_LO = 0x100000000L;
    private static final long TEXT_HI = 0x103000000L;

    private static final int CALLEE_DEPTH = 2;
    private static final String OUT_PATH =
        "/Users/olivermainey/Workspace/seed-search/ghidra/export/entity_placement.c";

    private DecompInterface decomp;
    private Set<Long> exported = new HashSet<>();
    private StringBuilder out = new StringBuilder();

    @Override
    public void run() throws Exception {
        decomp = new DecompInterface();
        decomp.openProgram(currentProgram);

        // Search for scalar constants near the placement seed derivation. Ghidra
        // can't grep instructions cheaply from script easily, so we rely on the
        // known target + its callees; print callers too so we can walk up.
        println("=== Decompiling targets + callees (depth " + CALLEE_DEPTH + ") ===");
        for (long t : TARGETS) {
            Address a = toAddr(t);
            Function f = getFunctionContaining(a);
            if (f == null) {
                println("  no function at 0x" + Long.toHexString(t) + " (run auto-analysis?)");
                continue;
            }
            println("  target: " + f.getName() + " @ 0x" + Long.toHexString(f.getEntryPoint().getOffset()));
            // Print callers so we can walk up to the chunk loop if needed.
            for (Function caller : f.getCallingFunctions(monitor)) {
                println("    caller: " + caller.getName() + " @ 0x" + Long.toHexString(caller.getEntryPoint().getOffset()));
            }
            exportRecursive(f, CALLEE_DEPTH);
        }

        try (Writer w = new OutputStreamWriter(new FileOutputStream(OUT_PATH), StandardCharsets.UTF_8)) {
            w.write(out.toString());
        }
        println("=== Wrote " + OUT_PATH + " (" + exported.size() + " functions) ===");
    }

    private void exportRecursive(Function f, int depth) {
        if (f == null) return;
        long ep = f.getEntryPoint().getOffset();
        if (exported.contains(ep)) return;
        exported.add(ep);

        DecompileResults r = decomp.decompileFunction(f, 60, monitor);
        out.append("/* ").append(f.getName()).append(" @ 0x")
           .append(Long.toHexString(ep)).append(" */\n");
        if (r != null && r.decompileCompleted()) {
            out.append(r.getDecompiledFunction().getC()).append("\n\n");
        } else {
            out.append("// decompile failed\n\n");
        }
        if (depth <= 0) return;
        for (Function callee : f.getCalledFunctions(monitor)) {
            exportRecursive(callee, depth - 1);
        }
    }
}
