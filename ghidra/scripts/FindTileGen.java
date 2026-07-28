/* FindTileGen.java — list functions likely responsible for TILE map generation /
 * autoplace tile selection, so we can decompile the one that turns per-tile
 * autoplace probabilities into a placed tile. Writes candidates to a file. */
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class FindTileGen extends GhidraScript {
    private static final String OUT =
        "/Users/olivermainey/Workspace/seed-search/ghidra/export/tilegen_candidates.txt";
    @Override public void run() throws Exception {
        StringBuilder sb = new StringBuilder();
        String[] pats = {"tile","Tile","autoplace","Autoplace","MapGenerationTask",
                         "generateTiles","GenerationTask","collectTiles","chooseTile","pickTile"};
        FunctionManager fm = currentProgram.getFunctionManager();
        int n=0;
        for (Function f : fm.getFunctions(true)) {
            String nm = f.getName();
            for (String p : pats) {
                if (nm.contains(p)) {
                    sb.append("0x").append(Long.toHexString(f.getEntryPoint().getOffset()))
                      .append("  ").append(f.getName(true)).append("\n");
                    n++; break;
                }
            }
        }
        try (Writer w=new OutputStreamWriter(new FileOutputStream(OUT),StandardCharsets.UTF_8)) { w.write(sb.toString()); }
        println("wrote "+n+" candidates to "+OUT);
    }
}
