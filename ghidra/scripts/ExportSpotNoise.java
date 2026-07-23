/* ExportSpotNoise.java — decompile Factorio's SpotNoise op and its callees.
 *
 * Goal: extract the four C++ internals we can't derive from the data-stage Lua:
 *   1. per-region RNG seed derivation from (map_seed/seed0, seed1, region_x, region_y)
 *   2. candidate generation + skip_span/skip_offset striding
 *   3. target-quantity spot selection (hard vs soft)
 *   4. spot contribution shape + maximum_spot_basement_radius basement transition
 *
 * Usage (Ghidra Script Manager, with the factorio arm64 program open):
 *   1. Run once. It:
 *        - decompiles the known SpotNoise ctor (0x10016104d4) so you can read the
 *          vtable store and find the `evaluate` slot,
 *        - searches the distinctive param strings and prints their code xrefs
 *          (these lead to the op's evaluate / registration).
 *   2. Add the evaluate address you find to TARGETS below, re-run.
 *   3. It writes decompiled C (targets + callees, to CALLEE_DEPTH) to
 *        ghidra/export/spot_noise.c
 *
 * Then paste ghidra/export/spot_noise.c back for porting.
 */

import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import ghidra.program.model.mem.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class ExportSpotNoise extends GhidraScript {

    private static final long[] TARGETS = {
        0x1015daca8L, // Noise::Noise default ctor (builds base gradient table)
    };

    private static final String[] SYMBOL_SUBSTRINGS = {
    };

    // Distinctive spot_noise-only parameter names to locate the op via strings.
    private static final String[] PARAM_STRINGS = {
        "maximum_spot_basement_radius",
        "candidate_spot_count",
        "hard_region_target_quantity",
        "suggested_minimum_candidate_point_spacing",
        "skip_span",
        "skip_offset",
    };

    // Vtables to dump: read pointers and decompile each code target.
    // PTR__SpotNoise_102f85cb8 — installed by the SpotNoise ctor; holds evaluate().
    private static final long[] VTABLES = {
    };
    private static final int VTABLE_SLOTS = 24;
    // arm64 __text range for this image, to filter vtable code pointers.
    private static final long TEXT_LO = 0x100000000L;
    private static final long TEXT_HI = 0x103000000L;

    private static final int CALLEE_DEPTH = 1;
    private static final String OUT_PATH =
        "/Users/olivermainey/Workspace/seed-search/ghidra/export/spot_noise.c";

    private DecompInterface decomp;
    private Set<Long> exported = new HashSet<>();
    private StringBuilder out = new StringBuilder();

    @Override
    public void run() throws Exception {
        decomp = new DecompInterface();
        decomp.openProgram(currentProgram);

        println("=== Locating spot_noise param strings ===");
        for (String s : PARAM_STRINGS) {
            findStringXrefs(s);
        }

        println("=== Symbol search (spot-list generator) ===");
        FunctionIterator fit = currentProgram.getFunctionManager().getFunctions(true);
        while (fit.hasNext()) {
            Function f = fit.next();
            String n = f.getName();
            for (String sub : SYMBOL_SUBSTRINGS) {
                if (n.contains(sub)) {
                    println("  " + n + " @ 0x" + Long.toHexString(f.getEntryPoint().getOffset()));
                    break;
                }
            }
        }

        println("=== Dumping vtables ===");
        for (long vt : VTABLES) {
            dumpVtable(vt);
        }

        println("=== Decompiling targets + callees (depth " + CALLEE_DEPTH + ") ===");
        for (long t : TARGETS) {
            Address a = toAddr(t);
            Function f = getFunctionContaining(a);
            if (f == null) {
                println("  no function at 0x" + Long.toHexString(t) + " (run auto-analysis?)");
                continue;
            }
            exportRecursive(f, CALLEE_DEPTH);
        }

        try (Writer w = new OutputStreamWriter(new FileOutputStream(OUT_PATH), StandardCharsets.UTF_8)) {
            w.write(out.toString());
        }
        println("=== Wrote " + OUT_PATH + " (" + exported.size() + " functions) ===");
    }

    private void dumpVtable(long vtAddr) throws Exception {
        Address base = toAddr(vtAddr);
        Memory mem = currentProgram.getMemory();
        println("  vtable @ 0x" + Long.toHexString(vtAddr) + ":");
        for (int i = 0; i < VTABLE_SLOTS; i++) {
            Address slot = base.add((long) i * 8);
            long ptr;
            try {
                ptr = mem.getLong(slot) & 0xffffffffffffffffL;
            } catch (MemoryAccessException e) {
                break;
            }
            if (ptr < TEXT_LO || ptr >= TEXT_HI) {
                println("    [" + i + "] 0x" + Long.toHexString(ptr) + " (non-code)");
                continue;
            }
            Function f = getFunctionContaining(toAddr(ptr));
            String nm = (f != null) ? f.getName() + " @ 0x" + Long.toHexString(f.getEntryPoint().getOffset()) : "(no func)";
            println("    [" + i + "] 0x" + Long.toHexString(ptr) + "  " + nm);
            // Decompile each slot body (no recursion) so evaluate is identifiable.
            if (f != null) exportRecursive(f, CALLEE_DEPTH);
        }
    }

    private void findStringXrefs(String needle) throws Exception {
        byte[] pat = (needle + "\0").getBytes(StandardCharsets.US_ASCII);
        Memory mem = currentProgram.getMemory();
        Address at = mem.findBytes(currentProgram.getImageBase(), pat, null, true, monitor);
        while (at != null) {
            println("  \"" + needle + "\" @ " + at);
            ReferenceIterator refs = currentProgram.getReferenceManager().getReferencesTo(at);
            for (Reference r : refs) {
                Function f = getFunctionContaining(r.getFromAddress());
                println("      xref from " + r.getFromAddress()
                        + (f != null ? " in " + f.getName() + " @ " + f.getEntryPoint() : ""));
            }
            at = mem.findBytes(at.add(1), pat, null, true, monitor);
        }
    }

    private void exportRecursive(Function f, int depth) {
        long key = f.getEntryPoint().getOffset();
        if (exported.contains(key)) return;
        exported.add(key);

        DecompileResults res = decomp.decompileFunction(f, 60, monitor);
        out.append("// ===== ").append(f.getName())
           .append("  @ 0x").append(Long.toHexString(key)).append(" =====\n");
        if (res != null && res.decompileCompleted()) {
            out.append(res.getDecompiledFunction().getC()).append("\n\n");
        } else {
            out.append("// (decompile failed)\n\n");
        }
        println("  exported " + f.getName() + " @ " + f.getEntryPoint());

        if (depth <= 0) return;
        for (Function callee : f.getCalledFunctions(monitor)) {
            if (callee.isThunk() || callee.isExternal()) continue;
            exportRecursive(callee, depth - 1);
        }
    }
}
