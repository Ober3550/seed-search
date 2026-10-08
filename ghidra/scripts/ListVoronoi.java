/* ListVoronoi.java — list + decompile every VoronoiNoise/VoronoiPoints/terrace
 * factory symbol so we can find where data-stage params (seed0, seed1,
 * grid_size, distance_type, jitter) are turned into the op fields
 * (+0x20 seed, +0x24 grid u16, +0x26 type u8, +0x28 jitter f32).
 */
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.io.*;

public class ListVoronoi extends GhidraScript {
    static final String OUT = "/Users/olivermainey/Workspace/seed-search/ghidra/export/voronoi-factories.c";

    @Override
    public void run() throws Exception {
        StringBuilder sb = new StringBuilder();
        sb.append("// VoronoiNoise/VoronoiPoints symbols in factorio-arm64 2.0.77\n\n");
        FunctionManager fm = currentProgram.getFunctionManager();
        int n = 0;
        for (Function f : fm.getFunctions(true)) {
            String name = f.getName();
            if (!name.contains("VoronoiNoise") && !name.contains("VoronoiPoints")
                    && !name.contains("NativeNoiseFunction") && !name.contains("registerNoiseFunction")) {
                continue;
            }
            n++;
            sb.append(String.format("0x%s  %s\n", f.getEntryPoint(), name));
        }
        sb.append("\nTOTAL " + n + "\n");
        try (Writer w = new OutputStreamWriter(new FileOutputStream(OUT), "UTF-8")) {
            w.write(sb.toString());
        }
        println("wrote " + OUT);
    }
}
