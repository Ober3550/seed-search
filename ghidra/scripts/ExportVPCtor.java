import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import java.io.*; import java.nio.charset.StandardCharsets; import java.util.*;
public class ExportVPCtor extends GhidraScript {
    long[] T = { 0x101611c50L, 0x1015f1c50L };
    public void run() throws Exception {
        DecompInterface d=new DecompInterface(); d.openProgram(currentProgram);
        StringBuilder o=new StringBuilder();
        for (long t: T){ Function f=getFunctionContaining(toAddr(t)); if(f==null){o.append("// none @"+Long.toHexString(t)+"\n");continue;}
            DecompileResults r=d.decompileFunction(f,60,monitor);
            o.append("// ===== "+f.getName()+" @0x"+Long.toHexString(f.getEntryPoint().getOffset())+" =====\n");
            o.append(r!=null&&r.decompileCompleted()?r.getDecompiledFunction().getC():"// fail").append("\n\n");
            println("done "+f.getName());
        }
        try(Writer w=new OutputStreamWriter(new FileOutputStream("/Users/olivermainey/Workspace/seed-search/ghidra/export/vp_ctor.c"),StandardCharsets.UTF_8)){w.write(o.toString());}
    }
}
