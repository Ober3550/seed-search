import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;

public class DumpNoiseData extends GhidraScript {
    @Override public void run() throws Exception {
        // disassemble around the PARAM ref to find the call (BL) that fills defaultNoise
        long at = 0x102499e20L;
        Listing lst = currentProgram.getListing();
        println("=== instructions 0x"+Long.toHexString(at-0x20)+" .. +0x60 ===");
        Address a = toAddr(at-0x20);
        for (int i=0;i<40;i++){
            Instruction ins = lst.getInstructionAt(a);
            if (ins==null){ a=a.add(4); continue; }
            String tgt="";
            if (ins.getMnemonicString().startsWith("bl")||ins.getMnemonicString().equals("b")){
                for (Address ref : ins.getFlows()){
                    Function f=getFunctionContaining(ref);
                    tgt="  -> "+ref+(f!=null?" "+f.getName():"");
                }
            }
            println(ins.getAddress()+": "+ins+tgt);
            a = ins.getAddress().add(ins.getLength());
        }
    }
}
