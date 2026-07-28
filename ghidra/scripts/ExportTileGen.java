import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import java.io.*; import java.nio.charset.StandardCharsets; import java.util.*;
public class ExportTileGen extends GhidraScript {
    private static final long[] TARGETS = {
        0x1014b2cecL, // BasicTilesMapGenerationTask::generateBasicTiles
        0x1014b26e0L, // getDefaultCandidateTileID
        0x10151f210L, // TileCorrectionMapGenerationTask::correctFromTile
        0x10151f9e4L, // isTileConsistentWithFixedTiles
        0x10151f9a4L, // setTileFixed
    };
    private static final int DEPTH = 1;
    private static final String OUT = "/Users/olivermainey/Workspace/seed-search/ghidra/export/tile_gen.c";
    private DecompInterface d; private Set<Long> done=new HashSet<>(); private StringBuilder o=new StringBuilder();
    @Override public void run() throws Exception {
        d=new DecompInterface(); d.openProgram(currentProgram);
        for (long t: TARGETS){ Function f=getFunctionContaining(toAddr(t)); if(f==null){o.append("// no func @0x"+Long.toHexString(t)+"\n");continue;} rec(f,DEPTH); }
        try(Writer w=new OutputStreamWriter(new FileOutputStream(OUT),StandardCharsets.UTF_8)){w.write(o.toString());}
        println("wrote "+OUT+" ("+done.size()+" fns)");
    }
    private void rec(Function f,int depth){ long k=f.getEntryPoint().getOffset(); if(done.contains(k))return; done.add(k);
        DecompileResults r=d.decompileFunction(f,60,monitor);
        o.append("// ===== ").append(f.getName(true)).append("  @ 0x").append(Long.toHexString(k)).append(" =====\n");
        o.append(r!=null&&r.decompileCompleted()? r.getDecompiledFunction().getC():"// (failed)\n").append("\n\n");
        if(depth<=0)return; for(Function c: f.getCalledFunctions(monitor)){ if(c.isThunk()||c.isExternal())continue; rec(c,depth-1);} }
}
