import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.address.*;
import java.io.*; import java.nio.charset.StandardCharsets;
// Decompiles the chunk entity task's driver, collision check and cliff
// generation (addresses from mapgen_names.txt, Factorio 2.0.77 arm64).
public class ExportEntityCliffs extends GhidraScript {
    static final long[] ADDRS={
        0x1014cb070L, // EntityMapGenerationTask::computeInternal
        0x1014ca408L, // EntityMapGenerationTask::buildArea
        0x1014cb1c4L, // EntityMapGenerationTask::generateCliffs
        0x1014cd608L, // EntityMapGenerationTask::tryToAddCliff
        0x1014cda38L, // EntityMapGenerationTask::wouldCollide
        0x1014cdbc0L, // EntityMapGenerationTask::isInArea
        0x1014cca28L, // EntityMapGenerationTask::applyEntities
        0x1014cc484L, // EntityMapGenerationTask::applyCliffs
        0x1014b4cc8L, 0x1014c16a8L, // Surface::wouldCollide
        0x1014b5598L, // CliffGenerator::crossesCliff
        0x1014b5624L, // CliffGenerator::getNoiseCacheSize
        0x1014b5650L, // CliffGenerator::crossingsForChunk
        0x1014b51d4L, // CellEdgeCliffCrossingArray::fixImpossibleCells
        0x1014b54fcL, // CellEdgeCliffCrossingArray::clearCell
        0x1014b5550L, // CellEdgeCliffCrossingArray::getCellCliffCrossing
        0x1014b5030L, // CellCliffCrossing::toMaybeCliffOrientation
        0x1014b4f10L, // MaybeCliffOrientation::value
        0x1014b5f14L, 0x1014b8b3cL, // CliffPlacementSettings::getModifiedElevationInterval / Richness
        0x1014bada8L, // CompiledMapGenSettings::prepareCliffProgramBuilder
        0x1014b48d0L, 0x1014b4a98L, // CliffCraterPlacer
        0x1007135e0L, 0x100712dc8L, // Cliff::getNeighborPosition / neighborSidesForOrientation
        0x100712604L, // CliffPrototype::getOrientationInfo
    };
    static final String OUT="/Users/olivermainey/Workspace/seed-search/ghidra/export/entity_cliffs.c";
    @Override public void run() throws Exception {
        DecompInterface d=new DecompInterface(); d.openProgram(currentProgram);
        StringBuilder o=new StringBuilder();
        AddressSpace sp=currentProgram.getAddressFactory().getDefaultAddressSpace();
        for (long a: ADDRS){
            Function f=currentProgram.getFunctionManager().getFunctionAt(sp.getAddress(a));
            if(f==null){ o.append("// no function at 0x").append(Long.toHexString(a)).append("\n\n"); continue; }
            DecompileResults r=d.decompileFunction(f,120,monitor);
            o.append("// ===== ").append(f.getName(true)).append("  @ 0x").append(Long.toHexString(a)).append(" =====\n");
            o.append(r!=null&&r.decompileCompleted()?r.getDecompiledFunction().getC():"//(failed)\n").append("\n\n");
            println("exported "+f.getName(true));
        }
        try(Writer w=new OutputStreamWriter(new FileOutputStream(OUT),StandardCharsets.UTF_8)){w.write(o.toString());}
        println("wrote "+OUT);
    }
}
