import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import java.io.*; import java.nio.charset.StandardCharsets;

public class ExportNoiseOps2 extends GhidraScript {
    private static final long[] TARGETS = {
        0x1015f42d0L, // ExpressionInRange::peakToNoiseExpression
        0x1015f4738L, // ExpressionInRange::clampedPeakToNoiseExpression
        0x1015f49b0L, // ExpressionInRange::dimensionsToNoiseExpression
        0x10249508cL, // registration xref for "expression_in_range"
        0x102260278L, // createDistance<Type0>
        0x102260580L, // createDistance<Type1>
        0x1022607a8L, // createDistance<Type2>
        0x1015f1ec4L, // DistanceFromNearestPoint::compile
        0x1015f34d8L, // SpotNoise::compile
    };
    @Override public void run() throws Exception {
        DecompInterface di = new DecompInterface(); di.openProgram(currentProgram);
        StringBuilder o = new StringBuilder();
        for (long t : TARGETS) {
            Function f = getFunctionContaining(toAddr(t));
            if (f == null) { o.append("// no func @0x").append(Long.toHexString(t)).append("\n"); continue; }
            o.append("// ===== ").append(f.getName(true)).append(" @ 0x").append(Long.toHexString(t)).append(" =====\n");
            DecompileResults r = di.decompileFunction(f, 120, monitor);
            o.append(r != null && r.decompileCompleted() ? r.getDecompiledFunction().getC() : "// (failed)\n").append("\n\n");
        }
        try (Writer w = new OutputStreamWriter(new FileOutputStream("/Users/olivermainey/Workspace/seed-search/ghidra/export/noise_ops2.c"), StandardCharsets.UTF_8)) {
            w.write(o.toString());
        }
        println("wrote noise_ops2.c");
    }
}
