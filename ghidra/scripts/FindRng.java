/* FindRng.java — Ghidra script to locate Factorio's triple-LFSR RNG.
 * 
 * Searches for the characteristic bitmask + shift pattern:
 *   0xFFFFFFFE << 12, 0xFFFFFFF8 << 4, 0xFFFFFFF0 << 17
 *
 * Usage: Run from Ghidra's Script Manager (Window → Script Manager)
 */

import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.mem.*;
import ghidra.program.model.scalar.*;
import ghidra.program.model.address.*;

public class FindRng extends GhidraScript {

    // RNG constants from the known algorithm
    private static final int[] MASKS = {0xFFFFFFFE, 0xFFFFFFF8, 0xFFFFFFF0};
    private static final int[] SHIFTS_LEFT = {12, 4, 17};
    private static final int[] SHIFTS_RIGHT = {19, 25, 11};

    @Override
    public void run() throws Exception {
        println("=== Searching for Factorio RNG constants ===");

        Memory mem = currentProgram.getMemory();
        Listing listing = currentProgram.getListing();

        // Search for the 32-bit mask constants
        for (int mask : MASKS) {
            byte[] bytes = new byte[]{
                (byte)(mask & 0xFF),
                (byte)((mask >> 8) & 0xFF),
                (byte)((mask >> 16) & 0xFF),
                (byte)((mask >> 24) & 0xFF)
            };

            Address addr = mem.findBytes(
                currentProgram.getImageBase(),
                bytes,
                null,
                true,
                monitor
            );

            while (addr != null) {
                println("Found mask 0x" + Integer.toHexString(mask) + " at " + addr);
                // Show surrounding instructions
                Instruction instr = listing.getInstructionContaining(addr);
                if (instr != null) {
                    println("  Context: " + instr);
                }
                addr = mem.findBytes(addr.add(1), bytes, null, true, monitor);
            }
        }

        println("=== Search complete ===");
    }
}
