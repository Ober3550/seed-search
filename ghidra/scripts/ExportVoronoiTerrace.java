/* ExportVoronoiTerrace.java — decompile Factorio 2.0's VoronoiNoise + Terrace
 * ops (the primitives the Space Age planet surfaces need — fulgora/gleba
 * voronoi terrain, vulcanus terraces, etc.).
 *
 * Usage: run from the Script Manager with the factorio-arm64 program open.
 * Writes decompiled C to ghidra/export/voronoi.c and ghidra/export/terrace.c.
 */

import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import java.io.*;

public class ExportVoronoiTerrace extends GhidraScript {
    static final String OUT_DIR = "/Users/olivermainey/Workspace/seed-search/ghidra/export";

    static final String[] VORONOI = {
        "0x10226c098", // VoronoiPoints ctor (jitter + id hash)
        "0x10161290c", // parseDistanceType
        "0x101612f98", // run (dispatcher)
        "0x101612fd0", // runInternal<0> chebyshev
        "0x1016139c4", // runInternal<1> manhattan
        "0x101614328", // runInternal<2> euclidean
        "0x101615130", // runInternal<3> minkowski3
        "0x1015f3c90", // VoronoiNoiseWrapper::compile (type -> output)
    };
    static final String[] TERRACE = {
        "0x1015f1450", // Terrace::run
        "0x1015f144c", // Terrace ctor
        "0x101611718", // Terrace::save
        "0x10161193c", // Terrace::getRegisterReferences
        "0x101611b38", // Terrace::toString
        "0x1015ff888", // GridOperation ctor
    };

    @Override
    public void run() throws Exception {
        DecompInterface decomp = new DecompInterface();
        decomp.openProgram(currentProgram);
        File outDir = new File(OUT_DIR);
        outDir.mkdirs();
        FunctionManager fm = currentProgram.getFunctionManager();
        String[][] jobs = new String[][] { { "voronoi.c", "VORONOI" }, { "terrace.c", "TERRACE" } };
        for (String[] job : jobs) {
            String[] addrs = job[1].equals("VORONOI") ? VORONOI : TERRACE;
            StringBuilder sb = new StringBuilder();
            sb.append("// Decompiled from factorio-arm64 (Space Age 2.0).\n");
            sb.append("// Functions: ").append(addrs.length).append("\n\n");
            for (String addrStr : addrs) {
                Address a = currentProgram.getAddressFactory().getAddress(addrStr);
                Function f = fm.getFunctionAt(a);
                if (f == null) f = fm.getFunctionContaining(a);
                if (f == null) {
                    sb.append("// ---- ").append(addrStr).append(" : NOT A FUNCTION ----\n\n");
                    continue;
                }
                sb.append("// ===== ").append(addrStr).append(" ").append(f.getName()).append(" =====\n");
                DecompileResults res = decomp.decompileFunction(f, 120, monitor);
                String code = res.getDecompiledFunction() == null ? "(decompile failed)"
                        : res.getDecompiledFunction().getC();
                sb.append(code).append("\n\n");
                println("decompiled " + f.getName());
            }
            File out = new File(outDir, job[0]);
            try (Writer w = new OutputStreamWriter(new FileOutputStream(out), "UTF-8")) {
                w.write(sb.toString());
            }
            println("wrote " + out.getAbsolutePath());
        }
        decomp.dispose();
    }
}
