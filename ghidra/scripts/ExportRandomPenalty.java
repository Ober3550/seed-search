import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import java.io.*; import java.nio.charset.StandardCharsets; import java.util.*;
public class ExportRandomPenalty extends GhidraScript {
    private static final long[] TARGETS = { 0x1015f0384L };
    private static final int DEPTH = 1;
    private static final String OUT = "/Users/olivermainey/Workspace/seed-search/ghidra/export/random_penalty.c";
    private DecompInterface d; private Set<Long> done = new HashSet<>(); private StringBuilder out = new StringBuilder();
    public void run() throws Exception {
        d = new DecompInterface(); d.openProgram(currentProgram);
        for (long t : TARGETS) { Function f = getFunctionContaining(toAddr(t));
            if (f==null){ println("no func @ "+Long.toHexString(t)); continue; }
            for (Function c : f.getCallingFunctions(monitor)) println("caller: "+c.getName()+" @ 0x"+Long.toHexString(c.getEntryPoint().getOffset()));
            rec(f, DEPTH); }
        try (Writer w = new OutputStreamWriter(new FileOutputStream(OUT), StandardCharsets.UTF_8)) { w.write(out.toString()); }
        println("wrote "+OUT+" ("+done.size()+" funcs)");
    }
    private void rec(Function f, int depth){ if(f==null) return; long ep=f.getEntryPoint().getOffset(); if(done.contains(ep)) return; done.add(ep);
        DecompileResults r = d.decompileFunction(f, 60, monitor);
        out.append("/* ").append(f.getName()).append(" @ 0x").append(Long.toHexString(ep)).append(" */\n");
        out.append(r!=null&&r.decompileCompleted()? r.getDecompiledFunction().getC() : "// fail").append("\n\n");
        if(depth<=0) return; for(Function c: f.getCalledFunctions(monitor)) rec(c, depth-1);
    }
}
