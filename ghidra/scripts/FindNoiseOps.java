import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.address.*;
import ghidra.program.model.symbol.*;
import ghidra.program.util.*;
import java.io.*; import java.nio.charset.StandardCharsets; import java.util.*;

public class FindNoiseOps extends GhidraScript {
    @Override public void run() throws Exception {
        StringBuilder o = new StringBuilder();
        String[] needles = { "expression_in_range", "spot_noise", "distance_from_nearest_point" };
        Listing list = currentProgram.getListing();
        // 1) defined string data matches + xrefs
        DataIterator it = list.getDefinedData(true);
        Set<String> seen = new HashSet<>();
        Map<String,List<Long>> strRefs = new HashMap<>();
        while (it.hasNext() && !monitor.isCancelled()) {
            Data d = it.next();
            Object v = d.getValue();
            if (!(v instanceof String)) continue;
            String s = (String) v;
            for (String n : needles) {
                if (s.equals(n)) {
                    strRefs.computeIfAbsent(n, k -> new ArrayList<>()).add(d.getAddress().getOffset());
                }
            }
        }
        DecompInterface di = new DecompInterface(); di.openProgram(currentProgram);
        for (String n : needles) {
            o.append("\n==== string \"" + n + "\" @ ").append(strRefs.getOrDefault(n, List.of())).append(" ====\n");
            for (long addr : strRefs.getOrDefault(n, List.of())) {
                Address a = toAddr(addr);
                for (Reference r : currentProgram.getReferenceManager().getReferencesTo(a)) {
                    Function f = list.getFunctionContaining(r.getFromAddress());
                    if (f == null) { o.append("  xref @ " + r.getFromAddress() + " (no func)\n"); continue; }
                    String key = f.getName(true) + " " + f.getEntryPoint();
                    if (!seen.add(key)) continue;
                    o.append("  xref func: " + f.getName(true) + " @ " + f.getEntryPoint() + "\n");
                    DecompileResults res = di.decompileFunction(f, 90, monitor);
                    if (res != null && res.decompileCompleted()) {
                        o.append(res.getDecompiledFunction().getC()).append("\n");
                    }
                }
            }
        }
        // 2) demangled symbol sweep for class/impl names
        o.append("\n==== symbol sweep ====\n");
        String[] pats = { "in_range", "InRange", "SpotNoise", "spot_noise", "DistanceFromNearest", "NearestPoint" };
        SymbolTable st = currentProgram.getSymbolTable();
        for (Symbol sym : st.getAllSymbols(true)) {
            String nm = sym.getName();
            if (nm == null) continue;
            for (String p : pats) {
                if (nm.contains(p)) {
                    o.append("  " + sym.getName(true) + "  @ " + sym.getAddress() + "\n");
                    break;
                }
            }
            if (monitor.isCancelled()) break;
        }
        try (Writer w = new OutputStreamWriter(new FileOutputStream("/Users/olivermainey/Workspace/seed-search/ghidra/export/noise_ops_find.txt"), StandardCharsets.UTF_8)) {
            w.write(o.toString());
        }
        println("wrote ghidra/export/noise_ops_find.txt");
    }
}
