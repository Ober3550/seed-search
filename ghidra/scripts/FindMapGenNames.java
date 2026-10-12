import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import java.io.*; import java.nio.charset.StandardCharsets; import java.util.*;
// Lists every function whose qualified name mentions map-generation entity /
// cliff placement, with address and size, so the ones to decompile can be picked.
public class FindMapGenNames extends GhidraScript {
    static final String[] KEYS={"Cliff","wouldCollide","EntityMapGenerationTask","tryToAddEntity","MapGenerationTask","AutoplaceSpecification"};
    static final String OUT="/Users/olivermainey/Workspace/seed-search/ghidra/export/mapgen_names.txt";
    @Override public void run() throws Exception {
        StringBuilder o=new StringBuilder(); int n=0;
        for (Function f: currentProgram.getFunctionManager().getFunctions(true)){
            String q=f.getName(true);
            for(String k:KEYS) if(q.contains(k)){ o.append(String.format("0x%x %6d %s%n", f.getEntryPoint().getOffset(), f.getBody().getNumAddresses(), q)); n++; break; }
        }
        try(Writer w=new OutputStreamWriter(new FileOutputStream(OUT),StandardCharsets.UTF_8)){w.write(o.toString());}
        println("wrote "+n+" names to "+OUT);
    }
}
