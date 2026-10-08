import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.address.*;
import ghidra.program.model.symbol.*;
import java.io.*; import java.nio.charset.StandardCharsets; import java.util.*;

public class ExportEirFactory extends GhidraScript {
    private static final long[] HELPER = {
        0x1015f49b0L, // dimensionsToNoiseExpression
        0x1015f4738L, // clampedPeakToNoiseExpression
    };
    @Override public void run() throws Exception {
        StringBuilder o = new StringBuilder();
        Set<String> done = new HashSet<>();
        DecompInterface di = new DecompInterface(); di.openProgram(currentProgram);
        ReferenceManager rm = currentProgram.getReferenceManager();
        for (long h : HELPER) {
            Address a = toAddr(h);
            for (Reference r : rm.getReferencesTo(a)) {
                Function f = getFunctionContaining(r.getFromAddress());
                if (f == null) continue;
                String key = f.getName(true);
                if (!done.add(key)) continue;
                o.append("// ===== caller: ").append(f.getName(true))
                 .append(" @ ").append(f.getEntryPoint()).append(" calls ").append(Long.toHexString(h)).append(" =====\n");
                DecompileResults res = di.decompileFunction(f, 120, monitor);
                o.append(res != null && res.decompileCompleted() ? res.getDecompiledFunction().getC() : "// (failed)\n").append("\n");
            }
        }
        try (Writer w = new OutputStreamWriter(new FileOutputStream("/Users/olivermainey/Workspace/seed-search/ghidra/export/eir_factory.c"), StandardCharsets.UTF_8)) {
            w.write(o.toString());
        }
        println("wrote eir_factory.c");
    }
}
