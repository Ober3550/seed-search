import ghidra.app.script.GhidraScript;
import ghidra.program.model.mem.*;
public class DumpRngData extends GhidraScript {
    public void run() throws Exception {
        long[] addrs = {0x1029732a8L,0x1029732b0L,0x1029732b8L,0x1029732c0L,
                        0x1029735c8L,0x1029735d0L,0x1029735d8L,0x1029735e0L};
        Memory mem = currentProgram.getMemory();
        for (long a : addrs) {
            byte[] b = new byte[8];
            mem.getBytes(toAddr(a), b);
            StringBuilder sb = new StringBuilder();
            for (int i=7;i>=0;i--) sb.append(String.format("%02x", b[i]&0xff));
            println(String.format("DAT_%x = 0x%s", a, sb));
        }
    }
}
