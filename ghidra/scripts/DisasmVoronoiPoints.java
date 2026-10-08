/* DisasmVoronoiPoints.java — dump arm64 instructions of the VoronoiPoints ctor
 * (0x10226c098) so the exact u32 hash sequence can be read without
 * decompiler 64-bit lowering noise.
 */
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.io.*;

public class DisasmVoronoiPoints extends GhidraScript {
    static final String OUT = "/Users/olivermainey/Workspace/seed-search/ghidra/export/voronoi-points-asm.txt";

    @Override
    public void run() throws Exception {
        Address a = currentProgram.getAddressFactory().getAddress("0x10226c098");
        Function f = currentProgram.getFunctionManager().getFunctionAt(a);
        if (f == null) f = currentProgram.getFunctionManager().getFunctionContaining(a);
        StringBuilder sb = new StringBuilder();
        sb.append("VoronoiPoints ctor @ ").append(a).append(" len=").append(f.getBody().getNumAddresses()).append("\n");
        Listing listing = currentProgram.getListing();
        Address end = f.getBody().getMaxAddress();
        Instruction ins = listing.getInstructionAt(a);
        int n = 0;
        while (ins != null && ins.getAddress().compareTo(end) <= 0 && n < 400) {
            sb.append(ins.getAddress()).append("  ").append(ins.toString()).append("\n");
            ins = ins.getNext();
            n++;
        }
        sb.append("---- " + n + " instructions ----\n");
        try (java.io.Writer w = new java.io.OutputStreamWriter(new java.io.FileOutputStream(OUT), "UTF-8")) {
            w.write(sb.toString());
        }
        println("wrote " + OUT);
    }
}
