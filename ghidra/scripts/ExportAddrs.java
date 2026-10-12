import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.address.*;
import java.io.*; import java.nio.charset.StandardCharsets;
// Decompile the functions at the given entry addresses.
// Arguments: <output file> <hex address>...   e.g.
//   run-process.sh ExportAddrs.java export/autoplace_order.c 10221e6cc
public class ExportAddrs extends GhidraScript {
    @Override public void run() throws Exception {
        String[] a=getScriptArgs();
        DecompInterface d=new DecompInterface(); d.openProgram(currentProgram);
        StringBuilder o=new StringBuilder();
        for(int i=1;i<a.length;i++){
            Address ad=currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(Long.parseLong(a[i],16));
            Function f=getFunctionContaining(ad); if(f==null){ println("no function at "+a[i]); continue; }
            DecompileResults r=d.decompileFunction(f,180,monitor);
            o.append("// ===== ").append(f.getName(true)).append("  @ 0x").append(Long.toHexString(f.getEntryPoint().getOffset())).append(" =====\n");
            o.append(r!=null&&r.decompileCompleted()?r.getDecompiledFunction().getC():"//(failed)\n").append("\n\n");
            println("exported "+f.getName(true));
        }
        try(Writer w=new OutputStreamWriter(new FileOutputStream(a[0]),StandardCharsets.UTF_8)){w.write(o.toString());}
        println("wrote "+a[0]);
    }
}
