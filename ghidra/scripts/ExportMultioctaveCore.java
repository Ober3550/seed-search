/* ExportMultioctaveCore.java — decompile the SCALAR multioctave core that
 * MultioctaveNoise::run calls (the exact per-octave amplitude/coordinate
 * recurrence the terrain + ore vein depend on).
 *   Noise::multioctaveNoise @ 0x1015dbe58  (scalar core)
 *   + its callees (scalar Noise::noise variants) to depth 2.
 * Writes ghidra/export/multioctave_core.c
 * Run: analyzeHeadless <proj> <name> -process factorio-arm64 -noanalysis
 *      -scriptPath scripts -postScript ExportMultioctaveCore.java
 */
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class ExportMultioctaveCore extends GhidraScript {
    private static final long[] TARGETS = {
        0x1015dbe58L, // Noise::multioctaveNoise (scalar core)
    };
    private static final int CALLEE_DEPTH = 2;
    private static final String OUT_PATH =
        "/Users/olivermainey/Workspace/seed-search/ghidra/export/multioctave_core.c";

    private DecompInterface decomp;
    private Set<Long> exported = new HashSet<>();
    private StringBuilder out = new StringBuilder();

    @Override public void run() throws Exception {
        decomp = new DecompInterface();
        decomp.openProgram(currentProgram);
        for (long t : TARGETS) {
            Function f = getFunctionContaining(toAddr(t));
            if (f == null) { println("no func @ 0x"+Long.toHexString(t)); continue; }
            exportRecursive(f, CALLEE_DEPTH);
        }
        try (Writer w = new OutputStreamWriter(new FileOutputStream(OUT_PATH), StandardCharsets.UTF_8)) {
            w.write(out.toString());
        }
        println("=== Wrote "+OUT_PATH+" ("+exported.size()+" functions) ===");
    }

    private void exportRecursive(Function f, int depth) {
        long key = f.getEntryPoint().getOffset();
        if (exported.contains(key)) return;
        exported.add(key);
        DecompileResults res = decomp.decompileFunction(f, 60, monitor);
        out.append("// ===== ").append(f.getName())
           .append("  @ 0x").append(Long.toHexString(key)).append(" =====\n");
        if (res != null && res.decompileCompleted())
            out.append(res.getDecompiledFunction().getC()).append("\n\n");
        else out.append("// (decompile failed)\n\n");
        println("  exported "+f.getName());
        if (depth <= 0) return;
        for (Function callee : f.getCalledFunctions(monitor)) {
            if (callee.isThunk() || callee.isExternal()) continue;
            exportRecursive(callee, depth - 1);
        }
    }
}
