/* DumpAsNoiseLayerID.java — decompile NoiseExpressionConstant::asNoiseLayerID
 * and the string/number hash it uses for seed1.
 */
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.io.*;

public class DumpAsNoiseLayerID extends GhidraScript {
    static final String OUT = "/Users/olivermainey/Workspace/seed-search/ghidra/export/asnoiselayerid.c";

    @Override
    public void run() throws Exception {
        StringBuilder sb = new StringBuilder();
        FunctionManager fm = currentProgram.getFunctionManager();
        DecompInterface decomp = new DecompInterface();
        decomp.openProgram(currentProgram);
        int n = 0;
        for (Function f : fm.getFunctions(true)) {
            String name = f.getName();
            if (!name.contains("asNoiseLayerID")) continue;
            n++;
            sb.append("// ===== ").append(f.getEntryPoint()).append(" ").append(name).append(" =====\n");
            DecompileResults res = decomp.decompileFunction(f, 300, monitor);
            sb.append(res.getDecompiledFunction() == null ? "(decompile failed)"
                    : res.getDecompiledFunction().getC());
            sb.append("\n\n");
        }
        sb.append("TOTAL " + n + "\n");
        try (Writer w = new OutputStreamWriter(new FileOutputStream(OUT), "UTF-8")) {
            w.write(sb.toString());
        }
        decomp.dispose();
        println("wrote " + OUT + " (" + n + ")");
    }
}
