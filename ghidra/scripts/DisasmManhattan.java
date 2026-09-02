import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import java.io.*;
public class DisasmManhattan extends GhidraScript {
    static final String OUT = "/Users/olivermainey/Workspace/seed-search/ghidra/export/manhattan-asm.txt";
    public void run() throws Exception {
        Address a = currentProgram.getAddressFactory().getAddress("0x1016139c4");
        Function f = currentProgram.getFunctionManager().getFunctionAt(a);
        if (f == null) f = currentProgram.getFunctionManager().getFunctionContaining(a);
        StringBuilder sb = new StringBuilder();
        Listing listing = currentProgram.getListing();
        Instruction ins = listing.getInstructionAt(a);
        int n = 0;
        while (ins != null && n < 900) {
            sb.append(ins.getAddress()).append("  ").append(ins.toString()).append("\n");
            ins = ins.getNext(); n++;
        }
        Writer w = new OutputStreamWriter(new FileOutputStream(OUT), "UTF-8");
        w.write(sb.toString()); w.close();
        println("wrote " + OUT);
    }
}
