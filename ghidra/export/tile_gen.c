// ===== BasicTilesMapGenerationTask::generateBasicTiles  @ 0x1014b2cec =====

/* BasicTilesMapGenerationTask::generateBasicTiles(CompiledMapGenSettings const&, ChunkPosition
   const&, ID<TilePrototype, unsigned short>, ChunkTiles&) */

void BasicTilesMapGenerationTask::generateBasicTiles
               (CompiledMapGenSettings *param_1,ChunkPosition *param_2,undefined2 param_3,
               long param_4)

{
  undefined2 *puVar1;
  void *pvVar2;
  code *pcVar3;
  long lVar4;
  ID *pIVar5;
  long lVar7;
  ulong uVar8;
  ulong uVar9;
  ulong uVar10;
  ulong uVar11;
  ID *local_b8;
  NoiseCache aNStack_a0 [16];
  long local_90;
  void *local_80;
  void *local_58;
  ID *pIVar6;
  
  NoiseProgram::getChunkNoiseCache((ChunkPosition *)(param_1 + 0x150));
  local_b8 = (ID *)0x0;
  if (local_90 != 0) {
    if (local_90 < 0) {
      std::vector<ID<TilePrototype,unsigned_short>,std::allocator<ID<TilePrototype,unsigned_short>>>
      ::__throw_length_error_abi_v160006_();
                    /* WARNING: Does not return */
      pcVar3 = (code *)SoftwareBreakpoint(1,0x1014b30d8);
      (*pcVar3)();
    }
    uVar11 = local_90 * 2;
    local_b8 = operator_new(uVar11);
    if (uVar11 != 0) {
      uVar8 = local_90 - 1U & 0x7fffffffffffffff;
      pIVar6 = local_b8;
      if (0x1e < uVar8) {
        uVar9 = 0;
        uVar8 = uVar8 + 1;
        uVar10 = uVar8 & 0xffffffffffffffe0;
        do {
          *(ulong *)(pIVar6 + 8) = CONCAT26(param_3,CONCAT24(param_3,CONCAT22(param_3,param_3)));
          *(ulong *)pIVar6 = CONCAT26(param_3,CONCAT24(param_3,CONCAT22(param_3,param_3)));
          *(ulong *)(pIVar6 + 0x18) = CONCAT26(param_3,CONCAT24(param_3,CONCAT22(param_3,param_3)));
          *(ulong *)(pIVar6 + 0x10) = CONCAT26(param_3,CONCAT24(param_3,CONCAT22(param_3,param_3)));
          *(ulong *)(pIVar6 + 0x28) = CONCAT26(param_3,CONCAT24(param_3,CONCAT22(param_3,param_3)));
          *(ulong *)(pIVar6 + 0x20) = CONCAT26(param_3,CONCAT24(param_3,CONCAT22(param_3,param_3)));
          *(ulong *)(pIVar6 + 0x38) = CONCAT26(param_3,CONCAT24(param_3,CONCAT22(param_3,param_3)));
          *(ulong *)(pIVar6 + 0x30) = CONCAT26(param_3,CONCAT24(param_3,CONCAT22(param_3,param_3)));
          uVar9 = uVar9 + 0x20;
          pIVar6 = pIVar6 + 0x40;
        } while (uVar10 != uVar9);
        pIVar6 = local_b8 + uVar10 * 2;
        if (uVar8 == uVar10) goto LAB_1014b2dc4;
      }
      do {
        pIVar5 = pIVar6 + 2;
        *(undefined2 *)pIVar6 = param_3;
        pIVar6 = pIVar5;
      } while (pIVar5 != local_b8 + uVar11);
    }
  }
LAB_1014b2dc4:
  generateBasicTiles(param_1,param_2,aNStack_a0,local_b8);
  lVar4 = 0;
  lVar7 = *(long *)PTR_indexToPrototype_102d4c598;
  pIVar6 = local_b8 + 0x20;
  do {
    puVar1 = (undefined2 *)(param_4 + lVar4);
    *puVar1 = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0x20) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 1) = 0x10;
    puVar1[0x30] = *(undefined2 *)
                    (*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0x1e) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x31) = 0x10;
    puVar1[0x60] = *(undefined2 *)
                    (*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0x1c) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x61) = 0x10;
    puVar1[0x90] = *(undefined2 *)
                    (*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0x1a) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x91) = 0x10;
    puVar1[0xc0] = *(undefined2 *)
                    (*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0x18) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0xc1) = 0x10;
    puVar1[0xf0] = *(undefined2 *)
                    (*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0x16) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0xf1) = 0x10;
    puVar1[0x120] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0x14) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x121) = 0x10;
    puVar1[0x150] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0x12) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x151) = 0x10;
    puVar1[0x180] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0x10) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x181) = 0x10;
    puVar1[0x1b0] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0xe) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x1b1) = 0x10;
    puVar1[0x1e0] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -0xc) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x1e1) = 0x10;
    puVar1[0x210] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -10) * 8) + 0x188)
    ;
    *(undefined1 *)(puVar1 + 0x211) = 0x10;
    puVar1[0x240] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -8) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x241) = 0x10;
    puVar1[0x270] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -6) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x271) = 0x10;
    puVar1[0x2a0] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -4) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x2a1) = 0x10;
    puVar1[0x2d0] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + -2) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x2d1) = 0x10;
    puVar1[0x300] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)pIVar6 * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x301) = 0x10;
    puVar1[0x330] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 2) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x331) = 0x10;
    puVar1[0x360] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 4) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x361) = 0x10;
    puVar1[0x390] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 6) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x391) = 0x10;
    puVar1[0x3c0] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 8) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x3c1) = 0x10;
    puVar1[0x3f0] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 10) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x3f1) = 0x10;
    puVar1[0x420] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 0xc) * 8) + 0x188)
    ;
    *(undefined1 *)(puVar1 + 0x421) = 0x10;
    puVar1[0x450] = *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 0xe) * 8) + 0x188)
    ;
    *(undefined1 *)(puVar1 + 0x451) = 0x10;
    puVar1[0x480] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 0x10) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x481) = 0x10;
    puVar1[0x4b0] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 0x12) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x4b1) = 0x10;
    puVar1[0x4e0] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 0x14) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x4e1) = 0x10;
    puVar1[0x510] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 0x16) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x511) = 0x10;
    puVar1[0x540] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 0x18) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x541) = 0x10;
    puVar1[0x570] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 0x1a) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x571) = 0x10;
    puVar1[0x5a0] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 0x1c) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x5a1) = 0x10;
    puVar1[0x5d0] =
         *(undefined2 *)(*(long *)(lVar7 + (ulong)*(ushort *)(pIVar6 + 0x1e) * 8) + 0x188);
    *(undefined1 *)(puVar1 + 0x5d1) = 0x10;
    lVar4 = lVar4 + 3;
    pIVar6 = pIVar6 + 0x40;
  } while (lVar4 != 0x60);
  if (local_b8 != (ID *)0x0) {
    operator_delete(local_b8);
  }
  pvVar2 = local_58;
  local_58 = (void *)0x0;
  if (pvVar2 != (void *)0x0) {
    operator_delete__(pvVar2);
  }
  pvVar2 = local_80;
  local_80 = (void *)0x0;
  if (pvVar2 != (void *)0x0) {
    operator_delete__(pvVar2);
  }
  return;
}



// ===== BasicTilesMapGenerationTask::generateBasicTiles  @ 0x1014b3124 =====

/* BasicTilesMapGenerationTask::generateBasicTiles(CompiledMapGenSettings const&, ChunkPosition
   const&, NoiseCache&, ID<TilePrototype, unsigned short>*) */

void BasicTilesMapGenerationTask::generateBasicTiles
               (CompiledMapGenSettings *param_1,ChunkPosition *param_2,NoiseCache *param_3,
               ID *param_4)

{
  bool bVar1;
  undefined8 *puVar2;
  long *plVar3;
  undefined2 uVar4;
  bool bVar5;
  bool bVar6;
  bool bVar7;
  bool bVar8;
  bool bVar9;
  void *pvVar10;
  long lVar11;
  long lVar12;
  ulong uVar13;
  ulong uVar14;
  ulong uVar15;
  int iVar16;
  ulong uVar17;
  ID *pIVar18;
  long lVar19;
  long lVar20;
  undefined8 *puVar21;
  long *plVar22;
  float fVar23;
  undefined8 uVar24;
  undefined8 uVar25;
  
  uVar14 = (ulong)*(uint *)(param_1 + 0x50) + 1 >> 1;
  uVar13 = (ulong)*(uint *)(param_1 + 0x54) + 1 >> 1;
  lVar12 = -(ulong)(*(uint *)(param_1 + 0x50) >> 1);
  lVar11 = -(ulong)(*(uint *)(param_1 + 0x54) >> 1);
  lVar20 = (long)(*(int *)param_2 << 5);
  lVar19 = (long)(*(int *)(param_2 + 4) << 5);
  bVar1 = lVar20 < lVar12;
  uVar17 = (ulong)(int)(*(int *)param_2 << 5 | 0x1f);
  bVar5 = lVar19 < lVar11;
  bVar9 = uVar14 != uVar17;
  uVar15 = (ulong)(int)(*(int *)(param_2 + 4) << 5 | 0x1f);
  bVar6 = (long)uVar17 <= (long)uVar14;
  bVar8 = (((!bVar1 && !bVar5) && bVar9) && ((bVar1 || bVar5) || bVar6)) && SBORROW8(uVar13,uVar15);
  bVar7 = (((!bVar1 && !bVar5) && bVar9) && ((bVar1 || bVar5) || bVar6)) &&
          (long)(uVar13 - uVar15) < 0;
  if (((((bVar1 || bVar5) || (!bVar9 || !bVar6)) || uVar13 == uVar15) || bVar7 != bVar8) &&
     (((((long)uVar14 <= lVar20 || ((long)uVar13 <= lVar19)) || ((long)uVar17 < lVar12)) ||
      ((long)uVar15 < lVar11)))) {
    if (0 < (long)(*(ulong *)(param_3 + 0x10) * 2)) {
      uVar4 = *(undefined2 *)(CorePrototypes::outOfMap + 0x188);
      uVar14 = *(ulong *)(param_3 + 0x10) & 0x7fffffffffffffff;
      uVar13 = (uVar14 - (uVar14 != 0)) + 1;
      if (0x1f < uVar13) {
        uVar17 = uVar13 & 0xffffffffffffffe0;
        uVar14 = uVar14 - uVar17;
        uVar24 = CONCAT26(uVar4,CONCAT24(uVar4,CONCAT22(uVar4,uVar4)));
        uVar25 = CONCAT26(uVar4,CONCAT24(uVar4,CONCAT22(uVar4,uVar4)));
        pIVar18 = param_4 + 0x20;
        uVar15 = uVar17;
        do {
          *(undefined8 *)(pIVar18 + -0x18) = uVar25;
          *(undefined8 *)(pIVar18 + -0x20) = uVar24;
          *(undefined8 *)(pIVar18 + -8) = uVar25;
          *(undefined8 *)(pIVar18 + -0x10) = uVar24;
          *(undefined8 *)(pIVar18 + 8) = uVar25;
          *(undefined8 *)pIVar18 = uVar24;
          *(undefined8 *)(pIVar18 + 0x18) = uVar25;
          *(undefined8 *)(pIVar18 + 0x10) = uVar24;
          uVar15 = uVar15 - 0x20;
          pIVar18 = pIVar18 + 0x40;
        } while (uVar15 != 0);
        param_4 = param_4 + uVar17 * 2;
        if (uVar13 == uVar17) {
          return;
        }
      }
      uVar14 = uVar14 + 1;
      do {
        *(undefined2 *)param_4 = uVar4;
        uVar14 = uVar14 - 1;
        param_4 = param_4 + 2;
      } while (1 < uVar14);
    }
    return;
  }
  puVar2 = *(undefined8 **)(param_1 + 0x160);
  for (puVar21 = *(undefined8 **)(param_1 + 0x158); puVar21 != puVar2; puVar21 = puVar21 + 1) {
    (**(code **)(*(long *)*puVar21 + 0x18))((long *)*puVar21,param_3);
  }
  uVar17 = *(ulong *)(param_3 + 0x10);
  uVar14 = uVar17 * 4;
  if (uVar17 >> 0x3e != 0) {
    uVar14 = 0xffffffffffffffff;
  }
  pvVar10 = operator_new__(uVar14);
  if (0 < (long)(uVar17 * 4)) {
    _memset_pattern16(pvVar10,&DAT_102973120,(uVar17 - ((uVar17 & 0x3fffffffffffffff) != 0)) * 4 + 4
                     );
  }
  lVar11 = NoiseCache::getFloatRegister(param_3,0);
  lVar12 = NoiseCache::getFloatRegister(param_3,1);
  plVar22 = *(long **)(param_1 + 0x1a8);
  plVar3 = *(long **)(param_1 + 0x1b0);
  if (plVar3 == plVar22) {
    uVar14 = *(ulong *)(param_3 + 0x10);
  }
  else {
    do {
      lVar19 = NoiseCache::getFloatRegister(param_3,(int)plVar22[1]);
      uVar14 = *(ulong *)(param_3 + 0x10);
      if (uVar14 != 0) {
        uVar17 = 0;
        do {
          fVar23 = *(float *)(lVar19 + uVar17 * 4);
          if (*(float *)((long)pvVar10 + uVar17 * 4) < fVar23) {
            *(float *)((long)pvVar10 + uVar17 * 4) = fVar23;
            *(undefined2 *)(param_4 + uVar17 * 2) = *(undefined2 *)(*plVar22 + 0x188);
            uVar14 = *(ulong *)(param_3 + 0x10);
          }
          uVar17 = uVar17 + 1;
        } while (uVar17 < uVar14);
      }
      plVar22 = plVar22 + 2;
    } while (plVar22 != plVar3);
  }
  if (uVar14 != 0 &&
      ((((bVar1 || bVar5) || (!bVar9 || !bVar6)) || uVar13 == uVar15) || bVar7 != bVar8)) {
    uVar13 = 0;
    do {
      iVar16 = (int)*(float *)(lVar11 + uVar13 * 4);
      if (((long)iVar16 < (long)-(ulong)(*(uint *)(param_1 + 0x50) >> 1)) ||
         ((double)*(uint *)(param_1 + 0x50) * 0.5 < (double)iVar16 + 0.1)) {
LAB_1014b3304:
        *(undefined2 *)(param_4 + uVar13 * 2) = *(undefined2 *)(CorePrototypes::outOfMap + 0x188);
        uVar14 = *(ulong *)(param_3 + 0x10);
      }
      else {
        iVar16 = (int)*(float *)(lVar12 + uVar13 * 4);
        if (((long)iVar16 < (long)-(ulong)(*(uint *)(param_1 + 0x54) >> 1)) ||
           ((double)*(uint *)(param_1 + 0x54) * 0.5 < (double)iVar16 + 0.1)) goto LAB_1014b3304;
      }
      uVar13 = uVar13 + 1;
    } while (uVar13 < uVar14);
  }
  operator_delete__(pvVar10);
  return;
}



// ===== NoiseProgram::getChunkNoiseCache  @ 0x1014b3618 =====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* NoiseProgram::getChunkNoiseCache(ChunkPosition const&) const */

void NoiseProgram::getChunkNoiseCache(ChunkPosition *param_1)

{
  void *pvVar1;
  long lVar2;
  long lVar3;
  undefined8 *in_x1;
  uint uVar4;
  undefined8 *in_x8;
  float *pfVar5;
  float *pfVar6;
  float fVar7;
  undefined8 uVar8;
  float fVar9;
  
  uVar4 = *(uint *)param_1;
  *in_x8 = 0x400;
  *(uint *)(in_x8 + 1) = uVar4;
  uVar8 = _DAT_102971e70;
  in_x8[3] = _UNK_102971e78;
  in_x8[2] = uVar8;
  pvVar1 = operator_new__(0x4010);
  _bzero(pvVar1,0x4010);
  in_x8[4] = pvVar1;
  *(undefined1 *)(in_x8 + 5) = 0;
  *(undefined8 *)((long)in_x8 + 0x34) = 0;
  *(undefined8 *)((long)in_x8 + 0x2c) = 0;
  *(undefined4 *)((long)in_x8 + 0x3c) = 0;
  in_x8[8] = (ulong)uVar4 << 10;
  pvVar1 = operator_new__((ulong)uVar4 << 0xc);
  in_x8[9] = pvVar1;
  *(undefined1 *)(in_x8 + 5) = 1;
  uVar8 = NEON_scvtf(CONCAT44((int)((ulong)*in_x1 >> 0x20) << 5,(int)*in_x1 << 5),4);
  *(undefined8 *)((long)in_x8 + 0x2c) = uVar8;
  *(undefined8 *)((long)in_x8 + 0x34) = 0x2000000020;
  *(undefined4 *)((long)in_x8 + 0x3c) = 0x3f800000;
  in_x8[2] = 0x400;
  lVar2 = NoiseCache::getFloatRegister();
  lVar3 = NoiseCache::getFloatRegister();
  uVar4 = 0;
  fVar9 = (float)uVar8;
  pfVar5 = (float *)(lVar3 + 0x40);
  pfVar6 = (float *)(lVar2 + 0x40);
  do {
    fVar7 = (float)((ulong)uVar8 >> 0x20) + (float)uVar4;
    pfVar6[-0x10] = fVar9;
    pfVar5[-0x10] = fVar7;
    pfVar6[-0xf] = fVar9 + 1.0;
    pfVar5[-0xf] = fVar7;
    pfVar6[-0xe] = fVar9 + 2.0;
    pfVar5[-0xe] = fVar7;
    pfVar6[-0xd] = fVar9 + 3.0;
    pfVar5[-0xd] = fVar7;
    pfVar6[-0xc] = fVar9 + 4.0;
    pfVar5[-0xc] = fVar7;
    pfVar6[-0xb] = fVar9 + 5.0;
    pfVar5[-0xb] = fVar7;
    pfVar6[-10] = fVar9 + 6.0;
    pfVar5[-10] = fVar7;
    pfVar6[-9] = fVar9 + 7.0;
    pfVar5[-9] = fVar7;
    pfVar6[-8] = fVar9 + 8.0;
    pfVar5[-8] = fVar7;
    pfVar6[-7] = fVar9 + 9.0;
    pfVar5[-7] = fVar7;
    pfVar6[-6] = fVar9 + 10.0;
    pfVar5[-6] = fVar7;
    pfVar6[-5] = fVar9 + 11.0;
    pfVar5[-5] = fVar7;
    pfVar6[-4] = fVar9 + 12.0;
    pfVar5[-4] = fVar7;
    pfVar6[-3] = fVar9 + 13.0;
    pfVar5[-3] = fVar7;
    pfVar6[-2] = fVar9 + 14.0;
    pfVar5[-2] = fVar7;
    pfVar6[-1] = fVar9 + 15.0;
    pfVar5[-1] = fVar7;
    *pfVar6 = fVar9 + 16.0;
    *pfVar5 = fVar7;
    pfVar6[1] = fVar9 + 17.0;
    pfVar5[1] = fVar7;
    pfVar6[2] = fVar9 + 18.0;
    pfVar5[2] = fVar7;
    pfVar6[3] = fVar9 + 19.0;
    pfVar5[3] = fVar7;
    pfVar6[4] = fVar9 + 20.0;
    pfVar5[4] = fVar7;
    pfVar6[5] = fVar9 + 21.0;
    pfVar5[5] = fVar7;
    pfVar6[6] = fVar9 + 22.0;
    pfVar5[6] = fVar7;
    pfVar6[7] = fVar9 + 23.0;
    pfVar5[7] = fVar7;
    pfVar6[8] = fVar9 + 24.0;
    pfVar5[8] = fVar7;
    pfVar6[9] = fVar9 + 25.0;
    pfVar5[9] = fVar7;
    pfVar6[10] = fVar9 + 26.0;
    pfVar5[10] = fVar7;
    pfVar6[0xb] = fVar9 + 27.0;
    pfVar5[0xb] = fVar7;
    pfVar6[0xc] = fVar9 + 28.0;
    pfVar5[0xc] = fVar7;
    pfVar6[0xd] = fVar9 + 29.0;
    pfVar5[0xd] = fVar7;
    pfVar6[0xe] = fVar9 + 30.0;
    pfVar5[0xe] = fVar7;
    pfVar6[0xf] = fVar9 + 31.0;
    pfVar5[0xf] = fVar7;
    uVar4 = uVar4 + 1;
    pfVar5 = pfVar5 + 0x20;
    pfVar6 = pfVar6 + 0x20;
  } while (uVar4 != 0x20);
  return;
}



// ===== std::vector<ID<TilePrototype,unsigned_short>,std::allocator<ID<TilePrototype,unsigned_short>>>::__throw_length_error[abi:v160006]  @ 0x101b5b6dc =====

/* std::vector<ID<TilePrototype, unsigned short>, std::allocator<ID<TilePrototype, unsigned short> >
   >::__throw_length_error[abi:v160006]() const */

void std::vector<ID<TilePrototype,unsigned_short>,std::allocator<ID<TilePrototype,unsigned_short>>>
     ::__throw_length_error_abi_v160006_(void)

{
                    /* WARNING: Subroutine does not return */
  std::__throw_length_error_abi_v160006_("vector");
}



// ===== BasicTilesMapGenerationTask::getDefaultCandidateTileID  @ 0x1014b26e0 =====

/* BasicTilesMapGenerationTask::getDefaultCandidateTileID(CompiledMapGenSettings const&) */

short BasicTilesMapGenerationTask::getDefaultCandidateTileID(CompiledMapGenSettings *param_1)

{
  long *plVar1;
  short sVar2;
  long *plVar3;
  long lVar4;
  
  plVar3 = *(long **)(param_1 + 0x1a8);
  plVar1 = *(long **)(param_1 + 0x1b0);
  if (plVar3 != plVar1) {
    if (CorePrototypes::character == 0) {
      do {
        if (*plVar3 == CorePrototypes::walkableTile) goto LAB_1014b2738;
        if (*(short *)(*plVar3 + 0x188) == CorePrototypes::emptySpaceTile) {
          return CorePrototypes::emptySpaceTile;
        }
        plVar3 = plVar3 + 2;
      } while (plVar3 != plVar1);
    }
    else {
      sVar2 = 0;
      do {
        lVar4 = *plVar3;
        if (lVar4 == CorePrototypes::walkableTile) {
LAB_1014b2738:
          return *(short *)(CorePrototypes::walkableTile + 0x188);
        }
        if (*(short *)(lVar4 + 0x188) == CorePrototypes::emptySpaceTile) {
          return CorePrototypes::emptySpaceTile;
        }
        if (sVar2 == 0) {
          if (*(char *)(lVar4 + 0x1b10) == '\0') {
            sVar2 = *(short *)(lVar4 + 0x188);
            if ((*(ulong *)(lVar4 + 400) & *(ulong *)(CorePrototypes::character + 0x2a8) &
                0xffffffffffffff) != 0) {
              sVar2 = 0;
            }
          }
          else {
            sVar2 = 0;
          }
        }
        plVar3 = plVar3 + 2;
      } while (plVar3 != plVar1);
      if (sVar2 != 0) {
        return sVar2;
      }
    }
  }
  return *(short *)(CorePrototypes::walkableTile + 0x188);
}



// ===== TileCorrectionMapGenerationTask::correctFromTile  @ 0x10151f210 =====

/* TileCorrectionMapGenerationTask::correctFromTile(TileCorrectionMapGenerationTask::AreaPosition
   const&, TileCorrectionMapGenerationTask::TileCorrectionBuffers&,
   std::vector<TileCorrectionMapGenerationTask::AreaPosition,
   std::allocator<TileCorrectionMapGenerationTask::AreaPosition> >&) */

void __thiscall
TileCorrectionMapGenerationTask::correctFromTile
          (TileCorrectionMapGenerationTask *this,AreaPosition *param_1,
          TileCorrectionBuffers *param_2,vector *param_3)

{
  uint uVar1;
  uint uVar2;
  uint *puVar3;
  uint uVar4;
  AreaPosition *pAVar5;
  ushort uVar6;
  undefined *puVar7;
  int iVar8;
  ulong uVar9;
  void *pvVar10;
  vector<TileCorrectionMapGenerationTask::AreaPosition,std::allocator<TileCorrectionMapGenerationTask::AreaPosition>>
  *pvVar11;
  undefined8 uVar12;
  undefined8 uVar13;
  ushort *puVar14;
  ulong uVar15;
  ushort *puVar16;
  undefined8 *puVar17;
  uint uVar18;
  ulong uVar19;
  AreaPosition *pAVar20;
  TileCorrectionBuffers *pTVar21;
  ulong uVar22;
  TileCorrectionMapGenerationTask *pTVar23;
  undefined8 *puVar24;
  undefined8 *puVar25;
  TileCorrectionMapGenerationTask *pTVar26;
  vector<TileCorrectionMapGenerationTask::AreaPosition,std::allocator<TileCorrectionMapGenerationTask::AreaPosition>>
  *pvVar27;
  undefined8 *puVar28;
  ulong uVar29;
  int *piVar30;
  long lVar31;
  ushort *puVar32;
  ushort *puVar33;
  undefined1 auVar34 [16];
  undefined1 auStack_2528 [7];
  undefined1 uStack_2521;
  ushort *puStack_2520;
  int *piStack_2518;
  ulong uStack_2510;
  undefined8 *puStack_2508;
  undefined8 *puStack_2500;
  TileCorrectionMapGenerationTask *pTStack_24f8;
  ulong uStack_24f0;
  undefined8 uStack_24e8;
  ulong uStack_24e0;
  TileCorrectionBuffers *pTStack_24d8;
  undefined1 *puStack_24d0;
  code *pcStack_24c8;
  TileCorrectionBuffers *local_24c0;
  vector *local_24b8;
  TileCorrectionMapGenerationTask *local_24b0;
  uint local_24a4;
  ulong local_24a0;
  uint local_2494;
  TileCorrectionMapGenerationTask *local_2490;
  char *local_2488;
  TileCorrectionMapGenerationTask *local_2480;
  undefined8 local_2478;
  ushort local_2470 [3];
  char local_2469;
  char acStack_2468 [9224];
  
  if (((-1 < (int)*(uint *)param_1) && (*(uint *)(param_1 + 4) < 0x60)) && (*(uint *)param_1 < 0x60)
     ) {
    puVar24 = *(undefined8 **)param_2;
    *(undefined8 **)(param_2 + 8) = puVar24;
    pTVar21 = param_2 + 0x18;
    *(undefined8 *)(param_2 + 0x20) = *(undefined8 *)pTVar21;
    local_2480 = this;
    _bzero(acStack_2468,0x2400);
    local_24c0 = pTVar21;
    local_24b8 = param_3;
    if (puVar24 == *(undefined8 **)(param_2 + 0x10)) {
      puVar28 = operator_new(8);
      uVar12 = *(undefined8 *)param_1;
      *(undefined8 **)param_2 = puVar28;
      puVar25 = puVar28 + 1;
      *puVar28 = uVar12;
      *(undefined8 **)(param_2 + 8) = puVar25;
      *(undefined8 **)(param_2 + 0x10) = puVar25;
      if (puVar24 != (undefined8 *)0x0) {
        operator_delete(puVar24);
        puVar25 = *(undefined8 **)(param_2 + 8);
      }
    }
    else {
      puVar25 = puVar24 + 1;
      *puVar24 = *(undefined8 *)param_1;
      *(undefined8 **)(param_2 + 8) = puVar25;
    }
    acStack_2468[(ulong)*(uint *)(param_1 + 4) + (ulong)*(uint *)param_1 * 0x60] = '\x01';
    puVar24 = *(undefined8 **)param_2;
    if (puVar25 != puVar24) {
      local_24a0 = 0;
      local_2490 = local_2480 + 0x20;
      pTVar23 = local_2480;
      do {
        puVar3 = (uint *)(puVar24 + local_24a0);
        local_24a0 = local_24a0 + 1;
        uVar4 = *puVar3;
        uVar18 = puVar3[1];
        piVar30 = &Util::NEIGHBOR_COORDS;
        local_2494 = uVar18;
        do {
          uVar1 = *piVar30 + uVar4;
          if (-1 < (int)uVar1) {
            uVar2 = piVar30[1] + uVar18;
            uVar19 = (ulong)uVar2;
            if (((uVar2 < 0x60) && (uVar1 < 0x60)) &&
               (local_2488 = acStack_2468 + (ulong)uVar1 * 0x60, local_2488[uVar19] == '\0')) {
              pTVar26 = local_2490 + (ulong)uVar1 * 0xc0;
              uVar6 = *(ushort *)(pTVar26 + uVar19 * 2);
              uVar29 = (ulong)uVar6;
              pvVar27 = *(vector<TileCorrectionMapGenerationTask::AreaPosition,std::allocator<TileCorrectionMapGenerationTask::AreaPosition>>
                          **)(*(long *)PTR_indexToPrototype_102d4c598 + uVar29 * 8);
              if (pvVar27 != CorePrototypes::outOfMap) {
                local_2469 = '\0';
                local_2470[0] = 0;
                puVar32 = *(ushort **)(param_2 + 0x18);
                *(ushort **)(param_2 + 0x20) = puVar32;
                local_2478 = CONCAT44(uVar2,uVar1);
                pvVar11 = pvVar27;
                uVar9 = isTileConsistentWithFixedTiles
                                  (pTVar23,local_2478,pvVar27,acStack_2468,&local_2469,local_2470);
                puVar33 = puVar32;
                if ((uVar9 & 1) == 0) {
                  local_24a4 = (uint)uVar6;
                  local_24b0 = pTVar26;
                  do {
                    uVar6 = (ushort)uVar29;
                    if (puVar32 == *(ushort **)(param_2 + 0x28)) {
                      uVar9 = (long)puVar32 - (long)puVar33;
                      if ((long)uVar9 < -2) {
                        std::
                        vector<ID<TilePrototype,unsigned_short>,std::allocator<ID<TilePrototype,unsigned_short>>>
                        ::__throw_length_error_abi_v160006_();
                        goto LAB_10151f848;
                      }
                      lVar31 = (long)uVar9 >> 1;
                      uVar15 = uVar9;
                      if (uVar9 <= lVar31 + 1U) {
                        uVar15 = lVar31 + 1;
                      }
                      if (0x7ffffffffffffffd < uVar9) {
                        uVar15 = 0x7fffffffffffffff;
                      }
                      if (uVar15 == 0) {
                        pvVar10 = (void *)0x0;
                        puVar14 = (ushort *)(lVar31 * 2);
                        puVar16 = puVar14 + 1;
                        *puVar14 = uVar6;
                        if (puVar32 == puVar33) goto LAB_10151f58c;
LAB_10151f494:
                        do {
                          puVar32 = puVar32 + -1;
                          puVar14 = puVar14 + -1;
                          *puVar14 = *puVar32;
                        } while (puVar32 != puVar33);
                        *(ushort **)(param_2 + 0x18) = puVar14;
                        *(ushort **)(param_2 + 0x20) = puVar16;
                        *(void **)(param_2 + 0x28) = (void *)((long)pvVar10 + uVar15 * 2);
                        pTVar23 = local_2480;
                      }
                      else {
                        if ((long)uVar15 < 0) goto LAB_10151f848;
                        pvVar10 = operator_new(uVar15 << 1);
                        puVar14 = (ushort *)((long)pvVar10 + lVar31 * 2);
                        puVar16 = puVar14 + 1;
                        *puVar14 = uVar6;
                        if (puVar32 != puVar33) goto LAB_10151f494;
LAB_10151f58c:
                        *(ushort **)(param_2 + 0x18) = puVar14;
                        *(ushort **)(param_2 + 0x20) = puVar16;
                        *(void **)(param_2 + 0x28) = (void *)((long)pvVar10 + uVar15 * 2);
                        pTVar23 = local_2480;
                      }
                      local_2480 = pTVar23;
                      if (puVar33 != (ushort *)0x0) {
                        operator_delete(puVar33);
                      }
                    }
                    else {
                      *puVar32 = uVar6;
                      *(ushort **)(param_2 + 0x20) = puVar32 + 1;
                    }
                    uVar9 = (ulong)local_2470[0];
                    if ((*(ushort *)(pvVar27 + 0x188) == local_2470[0]) ||
                       (*(char *)(*(long *)(pvVar27 + 0x1ab8) + uVar9) != '\0')) {
                      puVar14 = *(ushort **)(param_2 + 0x18);
                      puVar32 = *(ushort **)(param_2 + 0x20);
                      puVar33 = puVar14;
                      if (puVar14 != puVar32) goto LAB_10151f4ec;
LAB_10151f530:
                      uVar29 = uVar9;
                      if (puVar14 != puVar32) break;
                    }
                    else {
                      uVar9 = (ulong)*(ushort *)
                                      (*(long *)(*(long *)(*(long *)PTR_indexToPrototype_102d4c598 +
                                                          uVar9 * 8) + 0x1ad8) + uVar29 * 2);
                      puVar14 = *(ushort **)(param_2 + 0x18);
                      puVar32 = *(ushort **)(param_2 + 0x20);
                      puVar33 = puVar14;
                      if (puVar14 == puVar32) goto LAB_10151f530;
LAB_10151f4ec:
                      do {
                        if ((uint)*puVar14 == (uint)uVar9) goto LAB_10151f530;
                        puVar14 = puVar14 + 1;
                        uVar29 = uVar9;
                      } while (puVar14 != puVar32);
                    }
                    if ((int)uVar29 == 0) goto LAB_10151f5dc;
                    pvVar27 = *(vector<TileCorrectionMapGenerationTask::AreaPosition,std::allocator<TileCorrectionMapGenerationTask::AreaPosition>>
                                **)(*(long *)PTR_indexToPrototype_102d4c598 + uVar29 * 8);
                    pvVar11 = pvVar27;
                    iVar8 = isTileConsistentWithFixedTiles
                                      (pTVar23,local_2478,pvVar27,acStack_2468,&local_2469,
                                       local_2470);
                  } while (iVar8 == 0);
                  if (((uint)uVar29 == 0) || ((uint)uVar29 == local_24a4)) goto LAB_10151f5dc;
                  puVar24 = *(undefined8 **)(local_24b8 + 8);
                  if (puVar24 == *(undefined8 **)(local_24b8 + 0x10)) {
                    puVar28 = *(undefined8 **)local_24b8;
                    uVar15 = (long)puVar24 - (long)puVar28;
                    puVar33 = (ushort *)((long)uVar15 >> 3);
                    uVar9 = (long)puVar33 + 1;
                    if (uVar9 >> 0x3d != 0) goto LAB_10151f854;
                    uVar22 = uVar15 >> 2;
                    if (uVar15 >> 2 <= uVar9) {
                      uVar22 = uVar9;
                    }
                    if (0x7ffffffffffffff7 < uVar15) {
                      uVar22 = 0x1fffffffffffffff;
                    }
                    if (uVar22 == 0) {
                      pvVar10 = (void *)0x0;
                      puVar25 = (undefined8 *)((long)puVar33 * 8);
                      puVar17 = puVar25 + 1;
                      *puVar25 = local_2478;
                      if (puVar24 == puVar28) goto LAB_10151f7b0;
LAB_10151f704:
                      do {
                        puVar24 = puVar24 + -1;
                        puVar25 = puVar25 + -1;
                        *puVar25 = *puVar24;
                      } while (puVar24 != puVar28);
                      puVar24 = *(undefined8 **)local_24b8;
                      *(undefined8 **)local_24b8 = puVar25;
                      *(undefined8 **)(local_24b8 + 8) = puVar17;
                      *(void **)(local_24b8 + 0x10) = (void *)((long)pvVar10 + uVar22 * 8);
                    }
                    else {
                      if (uVar22 >> 0x3d != 0) goto LAB_10151f848;
                      pvVar10 = operator_new(uVar22 << 3);
                      puVar25 = (undefined8 *)((long)pvVar10 + (long)puVar33 * 8);
                      puVar17 = puVar25 + 1;
                      *puVar25 = local_2478;
                      if (puVar24 != puVar28) goto LAB_10151f704;
LAB_10151f7b0:
                      *(undefined8 **)local_24b8 = puVar25;
                      *(undefined8 **)(local_24b8 + 8) = puVar17;
                      *(void **)(local_24b8 + 0x10) = (void *)((long)pvVar10 + uVar22 * 8);
                    }
                    if (puVar24 != (undefined8 *)0x0) {
                      operator_delete(puVar24);
                    }
                  }
                  else {
                    *puVar24 = local_2478;
                    *(undefined8 **)(local_24b8 + 8) = puVar24 + 1;
                  }
                  *(short *)(local_24b0 + uVar19 * 2) = (short)uVar29;
                  puVar24 = *(undefined8 **)(param_2 + 8);
                  if (puVar24 != *(undefined8 **)(param_2 + 0x10)) goto LAB_10151f34c;
                  puVar28 = *(undefined8 **)param_2;
                  uVar15 = (long)puVar24 - (long)puVar28;
                  uVar29 = (long)uVar15 >> 3;
                  uVar9 = uVar29 + 1;
                  if (uVar9 >> 0x3d != 0) {
LAB_10151f84c:
                    std::
                    vector<TileCorrectionMapGenerationTask::AreaPosition,std::allocator<TileCorrectionMapGenerationTask::AreaPosition>>
                    ::__throw_length_error_abi_v160006_();
LAB_10151f854:
                    auVar34 = std::
                              vector<TileCorrectionMapGenerationTask::AreaPosition,std::allocator<TileCorrectionMapGenerationTask::AreaPosition>>
                              ::__throw_length_error_abi_v160006_();
                    pTVar21 = auVar34._8_8_;
                    pTVar26 = auVar34._0_8_;
                    uStack_24e8 = 0x60;
                    pcStack_24c8 = trySecondPass;
                    uVar12 = *(undefined8 *)pTVar21;
                    *(undefined8 *)(pTVar21 + 8) = uVar12;
                    puVar7 = PTR_indexToPrototype_102d4c598;
                    pAVar20 = *(AreaPosition **)pvVar11;
                    pAVar5 = *(AreaPosition **)(pvVar11 + 8);
                    uVar13 = uVar12;
                    puStack_2520 = puVar33;
                    piStack_2518 = piVar30;
                    uStack_2510 = uVar29;
                    puStack_2508 = puVar28;
                    puStack_2500 = puVar24;
                    pTStack_24f8 = pTVar23;
                    uStack_24f0 = (ulong)uVar4;
                    uStack_24e0 = uVar19;
                    pTStack_24d8 = param_2;
                    puStack_24d0 = &stack0xfffffffffffffff0;
                    if (pAVar20 != pAVar5) {
                      lVar31 = *(long *)PTR_indexToPrototype_102d4c598;
                      do {
                        uVar19 = isTileConsistentWithFixedTiles
                                           (pTVar26,*(undefined8 *)pAVar20,
                                            *(undefined8 *)
                                             (lVar31 + (ulong)*(ushort *)
                                                               (pTVar26 +
                                                               (ulong)*(uint *)(pAVar20 + 4) * 2 +
                                                               (ulong)*(uint *)pAVar20 * 0xc0 + 0x20
                                                               ) * 8),0,&uStack_2521,auStack_2528);
                        if ((uVar19 & 1) == 0) {
                          correctFromTile(pTVar26,pAVar20,pTVar21,(vector *)pTVar21);
                          lVar31 = *(long *)puVar7;
                        }
                        pAVar20 = pAVar20 + 8;
                      } while (pAVar20 != pAVar5);
                      pAVar20 = *(AreaPosition **)(pvVar11 + 8);
                      uVar12 = *(undefined8 *)pTVar21;
                      uVar13 = *(undefined8 *)(pTVar21 + 8);
                    }
                    std::
                    vector<TileCorrectionMapGenerationTask::AreaPosition,std::allocator<TileCorrectionMapGenerationTask::AreaPosition>>
                    ::insert<std::__wrap_iter<TileCorrectionMapGenerationTask::AreaPosition*>,0>
                              (pvVar11,pAVar20,uVar12,uVar13);
                    return;
                  }
                  uVar22 = uVar15 >> 2;
                  if (uVar15 >> 2 <= uVar9) {
                    uVar22 = uVar9;
                  }
                  if (0x7ffffffffffffff7 < uVar15) {
                    uVar22 = 0x1fffffffffffffff;
                  }
                  if (uVar22 == 0) {
                    pvVar10 = (void *)0x0;
                    puVar25 = (undefined8 *)(uVar29 * 8);
                    puVar17 = puVar25 + 1;
                    *puVar25 = local_2478;
                    if (puVar24 == puVar28) goto LAB_10151f7fc;
LAB_10151f7e8:
                    do {
                      puVar24 = puVar24 + -1;
                      puVar25 = puVar25 + -1;
                      *puVar25 = *puVar24;
                    } while (puVar24 != puVar28);
LAB_10151f7f8:
                    puVar24 = *(undefined8 **)param_2;
                  }
                  else {
                    if (uVar22 >> 0x3d != 0) goto LAB_10151f848;
                    pvVar10 = operator_new(uVar22 << 3);
                    puVar25 = (undefined8 *)((long)pvVar10 + uVar29 * 8);
                    puVar17 = puVar25 + 1;
                    *puVar25 = local_2478;
                    if (puVar24 != puVar28) goto LAB_10151f7e8;
                  }
LAB_10151f7fc:
                  *(undefined8 **)param_2 = puVar25;
                  *(undefined8 **)(param_2 + 8) = puVar17;
                  *(void **)(param_2 + 0x10) = (void *)((long)pvVar10 + uVar22 * 8);
                  if (puVar24 != (undefined8 *)0x0) {
                    operator_delete(puVar24);
                  }
                }
                else {
LAB_10151f5dc:
                  if (local_2469 != '\0') {
                    puVar24 = *(undefined8 **)(param_2 + 8);
                    if (puVar24 == *(undefined8 **)(param_2 + 0x10)) {
                      puVar28 = *(undefined8 **)param_2;
                      uVar15 = (long)puVar24 - (long)puVar28;
                      uVar29 = (long)uVar15 >> 3;
                      uVar9 = uVar29 + 1;
                      if (uVar9 >> 0x3d != 0) goto LAB_10151f84c;
                      uVar22 = uVar15 >> 2;
                      if (uVar15 >> 2 <= uVar9) {
                        uVar22 = uVar9;
                      }
                      if (0x7ffffffffffffff7 < uVar15) {
                        uVar22 = 0x1fffffffffffffff;
                      }
                      if (uVar22 == 0) {
                        pvVar10 = (void *)0x0;
                        puVar25 = (undefined8 *)(uVar29 * 8);
                        *puVar25 = local_2478;
                      }
                      else {
                        if (uVar22 >> 0x3d != 0) {
LAB_10151f848:
                    /* WARNING: Subroutine does not return */
                          std::__throw_bad_array_new_length_abi_v160006_();
                        }
                        pvVar10 = operator_new(uVar22 << 3);
                        puVar25 = (undefined8 *)((long)pvVar10 + uVar29 * 8);
                        *puVar25 = local_2478;
                      }
                      puVar17 = puVar25 + 1;
                      if (puVar24 != puVar28) {
                        do {
                          puVar24 = puVar24 + -1;
                          puVar25 = puVar25 + -1;
                          *puVar25 = *puVar24;
                        } while (puVar24 != puVar28);
                        goto LAB_10151f7f8;
                      }
                      goto LAB_10151f7fc;
                    }
LAB_10151f34c:
                    *puVar24 = local_2478;
                    *(undefined8 **)(param_2 + 8) = puVar24 + 1;
                  }
                }
                local_2488[uVar19] = '\x01';
                uVar18 = local_2494;
              }
            }
          }
          piVar30 = piVar30 + 2;
        } while (piVar30 != (int *)&UNK_10297d214);
        puVar24 = *(undefined8 **)param_2;
      } while (local_24a0 < (ulong)(*(long *)(param_2 + 8) - (long)puVar24 >> 3));
    }
  }
  return;
}



// ===== TileCorrectionMapGenerationTask::isTileConsistentWithFixedTiles  @ 0x10151f9e4 =====

/* TileCorrectionMapGenerationTask::isTileConsistentWithFixedTiles(TileCorrectionMapGenerationTask::AreaPosition,
   TilePrototype const&, std::array<std::array<bool, 96ul>, 96ul> const*, bool&, ID<TilePrototype,
   unsigned short>&) const */

bool __thiscall
TileCorrectionMapGenerationTask::isTileConsistentWithFixedTiles
          (TileCorrectionMapGenerationTask *this,ulong param_2,TilePrototype *param_3,array *param_4
          ,undefined1 *param_5,ushort *param_6)

{
  uint uVar1;
  uint uVar2;
  uint uVar3;
  int iVar4;
  ushort uVar5;
  ushort uVar6;
  ushort uVar7;
  ushort uVar8;
  ushort uVar9;
  uint uVar10;
  long lVar11;
  long lVar12;
  long lVar13;
  TilePrototype *pTVar14;
  uint uVar15;
  uint uVar16;
  uint uVar17;
  TilePrototype *pTVar18;
  long *plVar19;
  ulong uVar20;
  long lVar21;
  long lVar22;
  bool bVar23;
  int iVar24;
  int iVar25;
  uint uVar26;
  ulong uVar27;
  ulong uVar28;
  int iVar29;
  ulong uVar30;
  uint uVar31;
  int iVar32;
  uint local_80;
  uint uStack_7c;
  uint local_78;
  uint uStack_74;
  ulong local_70 [2];
  
  iVar24 = 0;
  bVar23 = false;
  *param_5 = 0;
  *param_6 = 0;
  uVar5 = *(ushort *)(param_3 + 0x188);
  uVar27 = param_2 >> 0x20;
  uVar20 = param_2 & 0xffffffff;
  lVar11 = uVar20 * 0xc0 + 0x20;
  uVar31 = 0xffffffff;
  plVar19 = (long *)PTR_indexToPrototype_102d4c598;
  local_70[0] = param_2;
  do {
    pTVar14 = CorePrototypes::outOfMap;
    uVar17 = (uint)param_2;
    uVar1 = uVar31 + uVar17;
    uVar2 = uVar31 + uVar1;
    lVar12 = (ulong)uVar1 * 0xc0 + 0x20;
    lVar22 = *plVar19;
    uVar6 = *(ushort *)(param_3 + 0x1a0);
    uVar3 = uVar17 + uVar31 * 2;
    uVar10 = uVar17 - uVar31;
    lVar13 = (ulong)uVar10 * 0xc0 + 0x20;
    uVar26 = (uint)(param_2 >> 0x20);
    iVar25 = -1;
    iVar29 = 1;
    iVar32 = -2;
    do {
      if (uVar31 != 0 || iVar29 != 0) {
        uStack_74 = uVar26 + iVar25;
        uVar28 = (ulong)uStack_74;
        if (((uVar1 < 0x60) && (uStack_74 < 0x60)) &&
           ((param_4 == (array *)0x0 || (param_4[uVar28 + (ulong)uVar1 * 0x60] != (array)0x0)))) {
          uVar9 = *(ushort *)(this + uVar28 * 2 + lVar12);
          uVar30 = (ulong)uVar9;
          pTVar18 = param_3;
          if (uVar9 != uVar5) {
            pTVar18 = *(TilePrototype **)(lVar22 + uVar30 * 8);
          }
          if (pTVar18 != pTVar14) {
            *param_6 = uVar9;
            if ((*(ushort *)(pTVar18 + 0x188) != uVar5) &&
               (*(char *)(*(long *)(pTVar18 + 0x1ab8) + (ulong)uVar5) == '\0')) {
              return bVar23;
            }
            if ((pTVar18 != param_3) && (uVar7 = *(ushort *)(pTVar18 + 0x1a0), uVar6 != uVar7)) {
              iVar4 = iVar24 + iVar29;
              local_78 = uVar1;
              if (uVar7 < uVar6) {
                uStack_7c = uVar26 + iVar32;
                local_80 = uVar3;
                if ((((uVar3 < 0x60) && (uStack_7c < 0x60)) &&
                    (*(ushort *)(this + (ulong)uStack_7c * 2 + (ulong)uVar3 * 0xc0 + 0x20) != uVar9)
                    ) && (uVar7 < *(ushort *)
                                   (*(long *)(lVar22 + (ulong)*(ushort *)
                                                               (this + (ulong)uStack_7c * 2 +
                                                                       (ulong)uVar3 * 0xc0 + 0x20) *
                                                       8) + 0x1a0))) {
                  if (param_4 == (array *)0x0) {
                    if (uVar31 == 0) {
                      return bVar23;
                    }
                    if (iVar29 == 0) {
                      return bVar23;
                    }
LAB_10151fcb8:
                    uVar30 = checkForWeakDiagonalSupport
                                       (this,(AreaPosition *)&local_78,iVar4 != 1,pTVar18,param_4);
                    plVar19 = (long *)PTR_indexToPrototype_102d4c598;
                    if ((uVar30 & 1) == 0) {
                      return bVar23;
                    }
                  }
                  else if ((param_4[(ulong)uStack_7c + (ulong)uVar3 * 0x60] != (array)0x0) ||
                          (uVar31 != 0 && iVar29 != 0)) {
                    if (param_4[(ulong)uStack_7c + (ulong)uVar3 * 0x60] != (array)0x0) {
                      if (uVar31 == 0 || iVar29 == 0) {
                        return bVar23;
                      }
                      goto LAB_10151fcb8;
                    }
                  }
                  else {
                    uVar15 = countFixedNeighborsOfKind(this,local_70,uVar30);
                    uVar16 = countFixedNeighborsOfKind(this,&local_80,uVar30);
                    plVar19 = (long *)PTR_indexToPrototype_102d4c598;
                    if (uVar16 < uVar15) {
                      return bVar23;
                    }
                  }
                }
              }
              if (((uVar6 < uVar7) && (uVar10 < 0x60)) &&
                 ((uVar15 = uVar26 + iVar29, uVar15 < 0x60 &&
                  ((*(ushort *)(this + (ulong)uVar15 * 2 + lVar13) != uVar5 &&
                   (uVar6 < *(ushort *)
                             (*(long *)(lVar22 + (ulong)*(ushort *)
                                                         (this + (ulong)uVar15 * 2 + lVar13) * 8) +
                             0x1a0))))))) {
                if ((uVar31 == 0) ||
                   ((iVar29 == 0 ||
                    (uVar30 = checkForWeakDiagonalSupport
                                        (this,(AreaPosition *)local_70,iVar4 != 1,param_3,param_4),
                    plVar19 = (long *)PTR_indexToPrototype_102d4c598, (uVar30 & 1) == 0)))) {
                  if (param_4 == (array *)0x0) {
                    return bVar23;
                  }
                  if (param_4[(ulong)uVar15 + (ulong)uVar10 * 0x60] != (array)0x0) {
                    return bVar23;
                  }
                }
                else {
                  uVar30 = checkForStrongDiagonalSupport
                                     (this,(AreaPosition *)local_70,iVar4 != 1,param_3,param_4);
                  plVar19 = (long *)PTR_indexToPrototype_102d4c598;
                  if ((uVar30 & 1) != 0) goto LAB_10151fe28;
                }
                *param_5 = 1;
              }
LAB_10151fe28:
              if (((uVar7 < uVar6) && (uVar31 != 0)) && (iVar29 != 0)) {
                lVar21 = *plVar19;
                uVar15 = uVar26 + iVar32;
                if ((((uVar15 < 0x60) &&
                     ((param_4 == (array *)0x0 ||
                      (param_4[(ulong)uVar15 + (ulong)uVar1 * 0x60] != (array)0x0)))) &&
                    (*(ushort *)(this + (ulong)uVar15 * 2 + lVar12) != uVar9)) &&
                   (((-1 < (int)uVar17 && (uVar17 < 0x60)) &&
                    (uVar7 < *(ushort *)
                              (*(long *)(lVar21 + (ulong)*(ushort *)
                                                          (this + (ulong)uVar15 * 2 + lVar12) * 8) +
                              0x1a0))))) {
                  if (param_4 == (array *)0x0) {
                    uVar8 = *(ushort *)
                             (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar28 * 2 + lVar11) * 8)
                             + 0x1a0);
                    if (uVar8 <= uVar7) {
                      return bVar23;
                    }
LAB_10151fee0:
                    if (uVar7 < uVar8) goto LAB_10151fef0;
                  }
                  else if (param_4[uVar28 + uVar20 * 0x60] != (array)0x0) {
                    if (*(ushort *)
                         (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar28 * 2 + lVar11) * 8) +
                         0x1a0) <= uVar7) {
                      return bVar23;
                    }
                    if (param_4[uVar28 + uVar20 * 0x60] != (array)0x0) {
                      uVar8 = *(ushort *)
                               (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar28 * 2 + lVar11) *
                                                   8) + 0x1a0);
                      goto LAB_10151fee0;
                    }
                  }
                  *param_5 = 1;
                }
LAB_10151fef0:
                if (((uVar2 < 0x60) &&
                    (((param_4 == (array *)0x0 ||
                      (param_4[uVar28 + (ulong)uVar2 * 0x60] != (array)0x0)) &&
                     (*(ushort *)(this + uVar28 * 2 + (ulong)uVar2 * 0xc0 + 0x20) != uVar9)))) &&
                   ((uVar26 < 0x60 &&
                    (uVar7 < *(ushort *)
                              (*(long *)(lVar21 + (ulong)*(ushort *)
                                                          (this + uVar28 * 2 +
                                                                  (ulong)uVar2 * 0xc0 + 0x20) * 8) +
                              0x1a0))))) {
                  if (param_4 == (array *)0x0) {
                    if (*(ushort *)
                         (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar27 * 2 + lVar12) * 8) +
                         0x1a0) <= uVar7) {
                      return bVar23;
                    }
LAB_101520018:
                    if (uVar7 < *(ushort *)
                                 (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar27 * 2 + lVar12)
                                                     * 8) + 0x1a0)) goto LAB_10151fefc;
                  }
                  else if (param_4[uVar27 + (ulong)uVar1 * 0x60] != (array)0x0) {
                    if (*(ushort *)
                         (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar27 * 2 + lVar12) * 8) +
                         0x1a0) <= uVar7) {
                      return bVar23;
                    }
                    if (param_4[uVar27 + (ulong)uVar1 * 0x60] != (array)0x0) goto LAB_101520018;
                  }
                  *param_5 = 1;
                }
              }
LAB_10151fefc:
              if (((uVar6 < uVar7) && (uVar31 != 0)) && (iVar29 != 0)) {
                lVar21 = *plVar19;
                if ((uVar10 < 0x60 && uVar26 < 0x60) && -1 < (int)uVar17) {
                  if (((uVar17 < 0x60) && (*(ushort *)(this + uVar27 * 2 + lVar13) != uVar5)) &&
                     (uVar6 < *(ushort *)
                               (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar27 * 2 + lVar13) *
                                                   8) + 0x1a0))) {
                    if (param_4 == (array *)0x0) {
                      uVar9 = *(ushort *)
                               (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar28 * 2 + lVar11) *
                                                   8) + 0x1a0);
                      if (uVar9 <= uVar6) {
                        return bVar23;
                      }
LAB_101520050:
                      if (uVar6 < uVar9) goto LAB_101520074;
                    }
                    else if (param_4[uVar28 + uVar20 * 0x60] != (array)0x0) {
                      if (uVar6 < *(ushort *)
                                   (*(long *)(lVar21 + (ulong)*(ushort *)
                                                               (this + uVar28 * 2 + lVar11) * 8) +
                                   0x1a0)) {
                        uVar9 = *(ushort *)
                                 (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar28 * 2 + lVar11)
                                                     * 8) + 0x1a0);
                        goto LAB_101520050;
                      }
                      if (param_4[uVar27 + (ulong)uVar10 * 0x60] != (array)0x0) {
                        return bVar23;
                      }
                    }
                    *param_5 = 1;
                  }
                }
                else if ((int)uVar17 < 0) goto LAB_10151fb28;
LAB_101520074:
                uVar15 = uVar26 + iVar29;
                if (((uVar15 < 0x60) && (uVar17 < 0x60)) &&
                   ((uVar26 < 0x60 &&
                    ((*(ushort *)(this + (ulong)uVar15 * 2 + lVar11) != uVar5 &&
                     (uVar6 < *(ushort *)
                               (*(long *)(lVar21 + (ulong)*(ushort *)
                                                           (this + (ulong)uVar15 * 2 + lVar11) * 8)
                               + 0x1a0))))))) {
                  if (param_4 == (array *)0x0) {
                    uVar9 = *(ushort *)
                             (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar27 * 2 + lVar12) * 8)
                             + 0x1a0);
                    if (uVar9 <= uVar6) {
                      return bVar23;
                    }
LAB_101520108:
                    if (uVar6 < uVar9) goto LAB_10151fb28;
                  }
                  else if (param_4[uVar27 + (ulong)uVar1 * 0x60] != (array)0x0) {
                    if (uVar6 < *(ushort *)
                                 (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar27 * 2 + lVar12)
                                                     * 8) + 0x1a0)) {
                      uVar9 = *(ushort *)
                               (*(long *)(lVar21 + (ulong)*(ushort *)(this + uVar27 * 2 + lVar12) *
                                                   8) + 0x1a0);
                      goto LAB_101520108;
                    }
                    if (param_4[(ulong)uVar15 + uVar20 * 0x60] != (array)0x0) {
                      return bVar23;
                    }
                  }
                  *param_5 = 1;
                }
              }
            }
          }
        }
      }
LAB_10151fb28:
      iVar25 = iVar25 + 1;
      iVar29 = iVar29 + -1;
      iVar32 = iVar32 + 2;
    } while (iVar29 != -2);
    uVar31 = uVar31 + 1;
    bVar23 = 1 < uVar31;
    iVar24 = iVar24 + 1;
    if (uVar31 == 2) {
      return true;
    }
  } while( true );
}



// ===== std::__throw_bad_array_new_length[abi:v160006]  @ 0x1000350f0 =====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* std::__throw_bad_array_new_length[abi:v160006]() */

void std::__throw_bad_array_new_length_abi_v160006_(void)

{
  bad_array_new_length *this;
  
  this = (bad_array_new_length *)___cxa_allocate_exception(8);
  bad_array_new_length::bad_array_new_length(this);
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this,&bad_array_new_length::typeinfo,bad_array_new_length::~bad_array_new_length);
}



// ===== std::vector<TileCorrectionMapGenerationTask::AreaPosition,std::allocator<TileCorrectionMapGenerationTask::AreaPosition>>::__throw_length_error[abi:v160006]  @ 0x101d66d8c =====

/* std::vector<TileCorrectionMapGenerationTask::AreaPosition,
   std::allocator<TileCorrectionMapGenerationTask::AreaPosition>
   >::__throw_length_error[abi:v160006]() const */

void std::
     vector<TileCorrectionMapGenerationTask::AreaPosition,std::allocator<TileCorrectionMapGenerationTask::AreaPosition>>
     ::__throw_length_error_abi_v160006_(void)

{
                    /* WARNING: Subroutine does not return */
  std::__throw_length_error_abi_v160006_("vector");
}



// ===== TileCorrectionMapGenerationTask::setTileFixed  @ 0x10151f9a4 =====

/* TileCorrectionMapGenerationTask::setTileFixed(TileCorrectionMapGenerationTask::AreaPosition
   const&, std::array<std::array<bool, 96ul>, 96ul>&) */

void TileCorrectionMapGenerationTask::setTileFixed(AreaPosition *param_1,array *param_2)

{
  param_2[(ulong)*(uint *)(param_1 + 4) + (ulong)*(uint *)param_1 * 0x60] = (array)0x1;
  return;
}



