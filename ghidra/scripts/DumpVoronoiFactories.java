/* DumpVoronoiFactories.java — decompile the VoronoiNoise factory/ctors.
 */
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import java.io.*;

public class DumpVoronoiFactories extends GhidraScript {
    static final String OUT = "/Users/olivermainey/Workspace/seed-search/ghidra/export/voronoi-ctors.c";
    static final String[] ADDRS = {
        "0x1015e4440", // VoronoiNoise (ctor?)
        "0x1016126b8", // VoronoiNoise
        "0x101612b74", // VoronoiNoise
        "0x102261b24", // getOrCreate<NoiseExpressions::VoronoiNoise>
        "0x102261ad8", // wrapper factory type 0
        "0x102261ef4", // wrapper factory type 1
        "0x102261f44", // wrapper factory type 2
        "0x102261f94", // wrapper factory type 3
        "0x1015f3c90", // VoronoiNoiseWrapper::compile
    };

    @Override
    public void run() throws Exception {
        DecompInterface decomp = new DecompInterface();
        decomp.openProgram(currentProgram);
        FunctionManager fm = currentProgram.getFunctionManager();
        StringBuilder sb = new StringBuilder();
        sb.append("// VoronoiNoise factories + ctors (factorio-arm64 2.0.77)\n\n");
        for (String addrStr : ADDRS) {
            Address a = currentProgram.getAddressFactory().getAddress(addrStr);
            Function f = fm.getFunctionAt(a);
            if (f == null) f = fm.getFunctionContaining(a);
            if (f == null) {
                sb.append("// ===== ").append(addrStr).append(" : NOT A FUNCTION =====\n\n");
                continue;
            }
            sb.append("// ===== ").append(addrStr).append(" ").append(f.getName()).append(" =====\n");
            DecompileResults res = decomp.decompileFunction(f, 300, monitor);
            sb.append(res.getDecompiledFunction() == null ? "(decompile failed)"
                    : res.getDecompiledFunction().getC());
            sb.append("\n\n");
            println("decompiled " + f.getName());
        }
        try (Writer w = new OutputStreamWriter(new FileOutputStream(OUT), "UTF-8")) {
            w.write(sb.toString());
        }
        decomp.dispose();
        println("wrote " + OUT);
    }
}
