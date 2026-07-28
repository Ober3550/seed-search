import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import java.io.*; import java.nio.charset.StandardCharsets; import java.util.*;
public class ExportByName extends GhidraScript {
    static final String[] NAMES={"checkForWeakDiagonalSupport","countFixedNeighborsOfKind","getDefaultCandidateTileID"};
    static final String OUT="/Users/olivermainey/Workspace/seed-search/ghidra/export/tile_support.c";
    @Override public void run() throws Exception {
        DecompInterface d=new DecompInterface(); d.openProgram(currentProgram);
        StringBuilder o=new StringBuilder(); Set<String> want=new HashSet<>(Arrays.asList(NAMES));
        for (Function f: currentProgram.getFunctionManager().getFunctions(true)){
            if(want.contains(f.getName())){
                DecompileResults r=d.decompileFunction(f,60,monitor);
                o.append("// ===== ").append(f.getName(true)).append("  @ 0x").append(Long.toHexString(f.getEntryPoint().getOffset())).append(" =====\n");
                o.append(r!=null&&r.decompileCompleted()?r.getDecompiledFunction().getC():"//(failed)\n").append("\n\n");
                println("exported "+f.getName());
            }
        }
        try(Writer w=new OutputStreamWriter(new FileOutputStream(OUT),StandardCharsets.UTF_8)){w.write(o.toString());}
        println("wrote "+OUT);
    }
}
