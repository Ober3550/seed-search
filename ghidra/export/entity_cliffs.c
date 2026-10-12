// ===== EntityMapGenerationTask::computeInternal  @ 0x1014cb070 =====

/* EntityMapGenerationTask::computeInternal() */

void __thiscall EntityMapGenerationTask::computeInternal(EntityMapGenerationTask *this)

{
  undefined8 *puVar1;
  undefined8 *puVar2;
  EntityMapGenerationTask EVar3;
  void *pvVar4;
  NoiseCache aNStack_80 [32];
  void *local_60;
  void *local_38;
  
  if (((byte)this[0x10] | 2) == 2) {
    generateCliffs();
  }
  NoiseProgram::getChunkNoiseCache((ChunkPosition *)(*(long *)(this + 0x70) + 0x130));
  puVar2 = *(undefined8 **)(*(long *)(this + 0x70) + 0x140);
  for (puVar1 = *(undefined8 **)(*(long *)(this + 0x70) + 0x138); puVar1 != puVar2;
      puVar1 = puVar1 + 1) {
    (**(code **)(*(long *)*puVar1 + 0x18))((long *)*puVar1,aNStack_80);
  }
  EVar3 = this[0x10];
  if (EVar3 == (EntityMapGenerationTask)0x0) {
    generateEntities(this,aNStack_80);
  }
  else {
    if (EVar3 != (EntityMapGenerationTask)0x1) {
      if (EVar3 == (EntityMapGenerationTask)0x2) {
        generateEntities(this,aNStack_80);
      }
      goto LAB_1014cb144;
    }
    if (*(long *)(this + 0x80) != 0) {
      generateEntities(this,aNStack_80);
    }
    if (*(long *)(this + 0x88) == 0) goto LAB_1014cb144;
  }
  generateDecoratives(this,aNStack_80);
LAB_1014cb144:
  pvVar4 = local_38;
  local_38 = (void *)0x0;
  if (pvVar4 != (void *)0x0) {
    operator_delete__(pvVar4);
  }
  pvVar4 = local_60;
  local_60 = (void *)0x0;
  if (pvVar4 != (void *)0x0) {
    operator_delete__(pvVar4);
  }
  return;
}



// ===== EntityMapGenerationTask::buildArea  @ 0x1014ca408 =====

/* EntityMapGenerationTask::buildArea(Surface&) */

void __thiscall EntityMapGenerationTask::buildArea(EntityMapGenerationTask *this,Surface *param_1)

{
  mutex *this_00;
  ulong uVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  long lVar6;
  void *pvVar7;
  undefined8 *puVar8;
  long lVar9;
  int iVar10;
  long lVar11;
  int iVar12;
  Chunk *pCVar13;
  ulong uVar14;
  void *pvVar15;
  int local_80;
  int local_7c;
  long local_78;
  long local_70;
  
  local_78 = 0xf8;
  local_70 = std::chrono::steady_clock::now();
  iVar10 = *(int *)(this + 0x60);
  iVar3 = iVar10 + -1;
  lVar11 = 0xf8;
  local_80 = iVar3;
  if (iVar3 <= iVar10 + 1) {
    iVar12 = *(int *)(this + 100);
    do {
      iVar4 = iVar12 + -1;
      local_7c = iVar4;
      if (iVar4 <= iVar12 + 1) {
        local_80 = iVar3;
        do {
          iVar10 = *(int *)(param_1 + 0x24);
          local_7c = iVar4;
          if (iVar3 < -iVar10) {
            iVar12 = iVar10 * 2;
            if (iVar10 * 2 <= -iVar3) {
              iVar12 = -iVar3;
            }
            iVar2 = *(int *)(param_1 + 0x20);
            uVar5 = (iVar2 + iVar12) - iVar10;
            uVar14 = -(ulong)(uVar5 >> 0x1f) & 0xfffffff000000000 | (ulong)uVar5 << 4;
            uVar1 = uVar14;
            if ((int)uVar5 < 0) {
              uVar1 = 0xffffffffffffffff;
            }
            pvVar7 = operator_new__(uVar1);
            if (iVar2 + iVar12 != iVar10) {
              _bzero(pvVar7,uVar14);
            }
            iVar10 = iVar2 + (iVar12 - iVar10);
            *(int *)(param_1 + 0x20) = iVar10;
            pvVar15 = *(void **)(param_1 + 0x18);
            if (pvVar15 != (void *)0x0) {
              _memmove((void *)((long)pvVar7 + (long)iVar2 * -0x10 + (long)iVar10 * 0x10),pvVar15,
                       (long)iVar2 * 0x10);
              operator_delete__(pvVar15);
            }
            *(void **)(param_1 + 0x18) = pvVar7;
            *(int *)(param_1 + 0x24) = iVar12;
            iVar10 = iVar12;
          }
          else {
            iVar12 = *(int *)(param_1 + 0x20);
            if (iVar10 + iVar3 < iVar12) {
              pvVar7 = *(void **)(param_1 + 0x18);
            }
            else {
              iVar2 = (iVar12 - iVar10) * 2;
              if (iVar12 - iVar10 == 0) {
                iVar2 = 1;
              }
              uVar5 = iVar2 + iVar10;
              if (iVar2 <= iVar3) {
                uVar5 = iVar10 + iVar3 + 1;
              }
              uVar14 = -(ulong)(uVar5 >> 0x1f) & 0xfffffff000000000 | (ulong)uVar5 << 4;
              uVar1 = uVar14;
              if ((int)uVar5 < 0) {
                uVar1 = 0xffffffffffffffff;
              }
              pvVar7 = operator_new__(uVar1);
              if (uVar5 != 0) {
                _bzero(pvVar7,uVar14);
              }
              pvVar15 = *(void **)(param_1 + 0x18);
              if (pvVar15 == (void *)0x0) {
                *(uint *)(param_1 + 0x20) = uVar5;
              }
              else {
                _memmove(pvVar7,pvVar15,(long)iVar12 << 4);
                *(uint *)(param_1 + 0x20) = uVar5;
                operator_delete__(pvVar15);
                iVar10 = *(int *)(param_1 + 0x24);
              }
              *(void **)(param_1 + 0x18) = pvVar7;
            }
          }
          puVar8 = (undefined8 *)
                   InfiniteVector<Chunk*>::operator[]
                             ((InfiniteVector<Chunk*> *)
                              ((long)pvVar7 + (long)(iVar10 + iVar3) * 0x10),iVar4);
          pCVar13 = (Chunk *)*puVar8;
          if (pCVar13 == (Chunk *)0x0) {
            pCVar13 = operator_new(0x15f0);
            Chunk::Chunk(pCVar13,param_1,(ChunkPosition *)&local_80);
            *puVar8 = pCVar13;
          }
          lVar11 = 0;
          iVar10 = *(int *)(this + 0x4890);
          uVar5 = *(int *)(this + 0x4894) + *(int *)(pCVar13 + 0xc4c) * 0x20;
          iVar12 = *(int *)(pCVar13 + 0xc48);
          pCVar13 = pCVar13 + 0x30;
          do {
            lVar6 = (ulong)((iVar12 << 5 | (uint)lVar11) + iVar10) * 0xc0 + 0x90;
            *(undefined2 *)(this + (ulong)uVar5 * 2 + lVar6) = *(undefined2 *)(pCVar13 + -0x30);
            *(undefined2 *)(this + (ulong)(uVar5 + 1) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0x2d);
            *(undefined2 *)(this + (ulong)(uVar5 + 2) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0x2a);
            *(undefined2 *)(this + (ulong)(uVar5 + 3) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0x27);
            *(undefined2 *)(this + (ulong)(uVar5 + 4) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0x24);
            *(undefined2 *)(this + (ulong)(uVar5 + 5) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0x21);
            *(undefined2 *)(this + (ulong)(uVar5 + 6) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0x1e);
            *(undefined2 *)(this + (ulong)(uVar5 + 7) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0x1b);
            *(undefined2 *)(this + (ulong)(uVar5 + 8) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0x18);
            *(undefined2 *)(this + (ulong)(uVar5 + 9) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0x15);
            *(undefined2 *)(this + (ulong)(uVar5 + 10) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0x12);
            *(undefined2 *)(this + (ulong)(uVar5 + 0xb) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0xf);
            *(undefined2 *)(this + (ulong)(uVar5 + 0xc) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + -0xc);
            *(undefined2 *)(this + (ulong)(uVar5 + 0xd) * 2 + lVar6) = *(undefined2 *)(pCVar13 + -9)
            ;
            *(undefined2 *)(this + (ulong)(uVar5 + 0xe) * 2 + lVar6) = *(undefined2 *)(pCVar13 + -6)
            ;
            *(undefined2 *)(this + (ulong)(uVar5 + 0xf) * 2 + lVar6) = *(undefined2 *)(pCVar13 + -3)
            ;
            *(undefined2 *)(this + (ulong)(uVar5 + 0x10) * 2 + lVar6) = *(undefined2 *)pCVar13;
            *(undefined2 *)(this + (ulong)(uVar5 + 0x11) * 2 + lVar6) = *(undefined2 *)(pCVar13 + 3)
            ;
            *(undefined2 *)(this + (ulong)(uVar5 + 0x12) * 2 + lVar6) = *(undefined2 *)(pCVar13 + 6)
            ;
            *(undefined2 *)(this + (ulong)(uVar5 + 0x13) * 2 + lVar6) = *(undefined2 *)(pCVar13 + 9)
            ;
            *(undefined2 *)(this + (ulong)(uVar5 + 0x14) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0xc);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x15) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0xf);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x16) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0x12);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x17) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0x15);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x18) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0x18);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x19) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0x1b);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x1a) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0x1e);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x1b) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0x21);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x1c) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0x24);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x1d) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0x27);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x1e) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0x2a);
            *(undefined2 *)(this + (ulong)(uVar5 + 0x1f) * 2 + lVar6) =
                 *(undefined2 *)(pCVar13 + 0x2d);
            lVar11 = lVar11 + 1;
            pCVar13 = pCVar13 + 0x60;
          } while (lVar11 != 0x20);
          iVar4 = iVar4 + 1;
          iVar12 = *(int *)(this + 100);
        } while (iVar4 <= iVar12 + 1);
        iVar10 = *(int *)(this + 0x60);
        local_7c = iVar4;
      }
      iVar3 = iVar3 + 1;
      lVar11 = local_78;
      local_80 = iVar3;
    } while (iVar3 <= iVar10 + 1);
  }
  lVar6 = local_70;
  this_00 = (mutex *)(*(long *)(_global + 0x1d0) + 0x18);
  std::mutex::lock(this_00);
  lVar9 = std::chrono::steady_clock::now();
  lVar11 = *(long *)(_global + 0x1d0) + lVar11;
  *(long *)(lVar11 + 0x58) = (lVar9 - lVar6) + *(long *)(lVar11 + 0x58);
  std::mutex::unlock(this_00);
  return;
}



// ===== EntityMapGenerationTask::generateCliffs  @ 0x1014cb1c4 =====

/* EntityMapGenerationTask::generateCliffs() */

void EntityMapGenerationTask::generateCliffs(void)

{
  byte bVar1;
  int iVar2;
  bool bVar3;
  bool bVar4;
  long in_x0;
  CliffGenerator *this;
  ChunkPosition *in_x2;
  uint uVar5;
  long lVar6;
  uint uVar7;
  uint uVar8;
  uint uVar9;
  uint uVar10;
  uint uVar11;
  double dVar12;
  double dVar13;
  double dVar14;
  double dVar15;
  undefined1 *puVar16;
  double dVar17;
  undefined8 local_e8;
  uint local_e0;
  uint local_dc;
  void *local_d8;
  void *local_d0;
  void *local_c0;
  void *local_b8;
  
  this = *(CliffGenerator **)(in_x0 + 0x70);
  lVar6 = *(long *)(this + 0xa8);
  if ((lVar6 != 0) && (*(float *)(*(long *)(this + 0x128) + 4) != 0.0)) {
    CliffGenerator::crossingsForChunk(this,(CompiledMapGenSettings *)(in_x0 + 0x60),in_x2);
    if ((local_e0 != 0) && (local_dc != 0)) {
      uVar10 = 0;
      dVar12 = *(double *)(lVar6 + 0xb30);
      dVar13 = *(double *)(lVar6 + 0xb38);
      dVar14 = *(double *)(lVar6 + 0xb40);
      dVar15 = *(double *)(lVar6 + 0xb48);
      uVar7 = local_e0;
      uVar9 = local_dc;
      uVar5 = local_dc;
      do {
        if (uVar5 != 0) {
          uVar11 = 0;
          uVar8 = 0;
          uVar5 = uVar9;
          do {
            iVar2 = local_e0 * uVar8;
            uVar7 = uVar8 + uVar10 + iVar2;
            uVar8 = uVar8 + 1;
            bVar1 = *(char *)((long)local_c0 + (ulong)uVar7) << 6 |
                    (*(byte *)((long)local_c0 + (ulong)(uVar7 + 1)) & 3) << 4 |
                    (*(byte *)((long)local_d8 + (ulong)(iVar2 + uVar10)) & 3) << 2 |
                    *(byte *)((long)local_d8 + (ulong)(uVar10 + local_e0 * uVar8)) & 3;
            if (0xbf < bVar1) {
              if (bVar1 < 0xcc) {
                if (bVar1 == 0xc0) {
                  local_e8 = 0xc00000002;
                }
                else {
                  if (bVar1 != 0xc1) goto switchD_1014cb31c_caseD_2;
                  local_e8 = 0x800000002;
                }
              }
              else if (bVar1 == 0xcc) {
                local_e8 = 0x400000002;
              }
              else {
                if (bVar1 != 0xf0) goto switchD_1014cb31c_caseD_2;
                local_e8 = 2;
              }
              goto LAB_1014cb42c;
            }
            switch(bVar1) {
            case 0:
              goto switchD_1014cb31c_caseD_0;
            case 1:
              local_e8 = 0x1100000002;
              break;
            default:
switchD_1014cb31c_caseD_2:
                    /* WARNING: Subroutine does not return */
              Logging::logAndAbortOrThrow
                        ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Map/EntityMapGenerationTask.cpp"
                         ,0x1ef,9,"Somehow an impossible cliff crossing made it through: %u");
            case 3:
              local_e8 = 0x1200000002;
              break;
            case 4:
              local_e8 = 0x1000000002;
              break;
            case 5:
              local_e8 = 0x100000002;
              break;
            case 0xc:
              local_e8 = 0x1300000002;
              break;
            case 0xf:
              local_e8 = 0x300000002;
              break;
            case 0x10:
              local_e8 = 0xe00000002;
              break;
            case 0x11:
              local_e8 = 0x600000002;
              break;
            case 0x1c:
              local_e8 = 0xa00000002;
              break;
            case 0x30:
              local_e8 = 0xd00000002;
              break;
            case 0x33:
              local_e8 = 0xb00000002;
              break;
            case 0x34:
              local_e8 = 0x500000002;
              break;
            case 0x40:
              local_e8 = 0xf00000002;
              break;
            case 0x43:
              local_e8 = 0x700000002;
              break;
            case 0x44:
              local_e8 = 0x900000002;
              break;
            case 0x50:
              local_e8 = 0x200000002;
            }
LAB_1014cb42c:
            puVar16 = (undefined1 *)
                      ((dVar14 + (double)(long)*(int *)(in_x0 + 0x60) * 32.0 +
                                 (double)(uVar10 * (int)dVar12) + (double)((uint)(int)dVar12 >> 1))
                      * 256.0);
            bVar3 = true;
            if ((!NAN((double)puVar16)) && (bVar3 = false, !NAN((double)puVar16))) {
              bVar3 = (double)puVar16 == INFINITY;
            }
            bVar4 = true;
            if ((!bVar3) && (bVar4 = false, !NAN((double)puVar16))) {
              bVar4 = (double)puVar16 == -INFINITY;
            }
            if (bVar4) {
LAB_1014cb598:
                    /* WARNING: Subroutine does not return */
              Logging::logAndAbortOrThrow
                        ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Util/FixedPointNumber.hpp"
                         ,0x1f,9,"double value not in range for fixed point number: %f");
            }
            dVar17 = (dVar15 + (double)(long)*(int *)(in_x0 + 100) * 32.0 + (double)uVar11 +
                               (double)((uint)(int)dVar13 >> 1)) * 256.0;
            bVar3 = true;
            if ((!NAN(dVar17)) && (bVar3 = false, !NAN(dVar17))) {
              bVar3 = dVar17 == INFINITY;
            }
            bVar4 = true;
            if ((!bVar3) && (bVar4 = false, !NAN(dVar17))) {
              bVar4 = dVar17 == -INFINITY;
            }
            if (bVar4) goto LAB_1014cb598;
            MaybeCliffOrientation::value((MaybeCliffOrientation *)&local_e8);
            if ((double)puVar16 <= -2147483648.0) {
              puVar16 = &DAT_c1e0000000000000;
            }
            NEON_fminnm(puVar16,0x41dfffffffc00000);
            NEON_fminnm(dVar17,0x41dfffffffc00000);
            tryToAddCliff();
            uVar5 = local_dc;
switchD_1014cb31c_caseD_0:
            uVar11 = uVar11 + (int)dVar13;
            uVar7 = local_e0;
            uVar9 = uVar5;
          } while (uVar8 < uVar5);
        }
        uVar10 = uVar10 + 1;
      } while (uVar10 < uVar7);
    }
    if (local_c0 != (void *)0x0) {
      local_b8 = local_c0;
      operator_delete(local_c0);
    }
    if (local_d8 != (void *)0x0) {
      local_d0 = local_d8;
      operator_delete(local_d8);
    }
  }
  return;
}



// ===== EntityMapGenerationTask::tryToAddCliff  @ 0x1014cd608 =====

/* EntityMapGenerationTask::tryToAddCliff(MapPosition, CliffOrientation, CliffPrototype const&,
   bool) */

undefined8 __thiscall
EntityMapGenerationTask::tryToAddCliff
          (EntityMapGenerationTask *this,undefined8 param_2,undefined4 param_3,long param_4,
          undefined1 param_5)

{
  undefined8 *puVar1;
  undefined2 uVar2;
  ulong uVar3;
  void *pvVar4;
  ulong uVar5;
  undefined8 *puVar6;
  undefined8 *puVar7;
  ulong uVar8;
  undefined8 uVar9;
  undefined8 *puVar10;
  undefined8 *puVar11;
  undefined8 *puVar12;
  long lVar13;
  undefined8 local_80;
  undefined8 uStack_78;
  undefined4 local_70;
  
  if (this[0x10] == (EntityMapGenerationTask)0x2) {
    switch(param_3) {
    case 0:
      lVar13 = param_4 + 0x590;
      break;
    case 1:
      lVar13 = param_4 + 0x5d8;
      break;
    case 2:
      lVar13 = param_4 + 0x620;
      break;
    case 3:
      lVar13 = param_4 + 0x668;
      break;
    case 4:
      lVar13 = param_4 + 0x6b0;
      break;
    case 5:
      lVar13 = param_4 + 0x6f8;
      break;
    case 6:
      lVar13 = param_4 + 0x740;
      break;
    case 7:
      lVar13 = param_4 + 0x788;
      break;
    case 8:
      lVar13 = param_4 + 2000;
      break;
    case 9:
      lVar13 = param_4 + 0x818;
      break;
    case 10:
      lVar13 = param_4 + 0x860;
      break;
    case 0xb:
      lVar13 = param_4 + 0x8a8;
      break;
    case 0xc:
      lVar13 = param_4 + 0x8f0;
      break;
    case 0xd:
      lVar13 = param_4 + 0x938;
      break;
    case 0xe:
      lVar13 = param_4 + 0xa10;
      break;
    case 0xf:
      lVar13 = param_4 + 0xa58;
      break;
    case 0x10:
      lVar13 = param_4 + 0x980;
      break;
    case 0x11:
      lVar13 = param_4 + 0x9c8;
      break;
    case 0x12:
      lVar13 = param_4 + 0xaa0;
      break;
    case 0x13:
      lVar13 = param_4 + 0xae8;
      break;
    default:
                    /* WARNING: Subroutine does not return */
      Logging::logAndAbortOrThrow
                ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Entity/CliffPrototype.cpp"
                 ,0xd1,9,"Invalid cliff orientation: %u");
    }
    uStack_78 = *(undefined8 *)(lVar13 + 0xc);
    local_80 = *(undefined8 *)(lVar13 + 4);
    local_70 = *(undefined4 *)(lVar13 + 0x14);
    uVar3 = wouldCollide(this,&local_80,*(undefined8 *)(param_4 + 0x2a8),param_2,0);
    if ((uVar3 & 1) != 0) {
      return 0;
    }
  }
  uVar2 = *(undefined2 *)(param_4 + 0x188);
  puVar11 = *(undefined8 **)(this + 0x38);
  if (puVar11 < *(undefined8 **)(this + 0x40)) {
    *(undefined2 *)puVar11 = uVar2;
    *(char *)((long)puVar11 + 2) = (char)param_3;
    *(undefined8 *)((long)puVar11 + 4) = param_2;
    *(undefined1 *)((long)puVar11 + 0xc) = param_5;
    *(undefined8 **)(this + 0x38) = puVar11 + 2;
  }
  else {
    puVar12 = *(undefined8 **)(this + 0x30);
    lVar13 = (long)puVar11 - (long)puVar12 >> 4;
    uVar3 = lVar13 + 1;
    if (uVar3 >> 0x3c != 0) {
      std::
      vector<EntityMapGenerationTask::CliffAddition,std::allocator<EntityMapGenerationTask::CliffAddition>>
      ::__throw_length_error_abi_v160006_();
LAB_1014cd844:
                    /* WARNING: Subroutine does not return */
      std::__throw_bad_array_new_length_abi_v160006_();
    }
    uVar5 = (long)*(undefined8 **)(this + 0x40) - (long)puVar12;
    uVar8 = uVar5 >> 3;
    if (uVar8 <= uVar3) {
      uVar8 = uVar3;
    }
    if (0x7fffffffffffffef < uVar5) {
      uVar8 = 0xfffffffffffffff;
    }
    if (uVar8 == 0) {
      pvVar4 = (void *)0x0;
    }
    else {
      if (uVar8 >> 0x3c != 0) goto LAB_1014cd844;
      pvVar4 = operator_new(uVar8 << 4);
    }
    puVar7 = (undefined8 *)((long)pvVar4 + lVar13 * 0x10);
    *(undefined2 *)puVar7 = uVar2;
    *(char *)((long)puVar7 + 2) = (char)param_3;
    *(undefined8 *)((long)puVar7 + 4) = param_2;
    *(undefined1 *)((long)puVar7 + 0xc) = param_5;
    puVar1 = puVar7 + 2;
    puVar6 = puVar7;
    if (puVar11 != puVar12) {
      do {
        puVar10 = puVar11 + -2;
        uVar9 = *(undefined8 *)((long)puVar11 - 0xb);
        puVar7 = puVar6 + -2;
        *puVar7 = *puVar10;
        *(undefined8 *)((long)puVar6 + -0xb) = uVar9;
        puVar6 = puVar7;
        puVar11 = puVar10;
      } while (puVar10 != puVar12);
      puVar11 = *(undefined8 **)(this + 0x30);
    }
    *(undefined8 **)(this + 0x30) = puVar7;
    *(undefined8 **)(this + 0x38) = puVar1;
    *(void **)(this + 0x40) = (void *)((long)pvVar4 + uVar8 * 0x10);
    if (puVar11 != (undefined8 *)0x0) {
      operator_delete(puVar11);
    }
  }
  return 1;
}



// ===== EntityMapGenerationTask::wouldCollide  @ 0x1014cda38 =====

/* EntityMapGenerationTask::wouldCollide(BoundingBox const&, CollisionMask, MapPosition, Direction)
    */

bool __thiscall
EntityMapGenerationTask::wouldCollide
          (EntityMapGenerationTask *this,undefined8 param_1,ulong param_3,undefined8 param_4,
          undefined1 param_5)

{
  uint uVar1;
  uint uVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  bool bVar6;
  int iVar7;
  bool bVar8;
  int iVar9;
  EntityMapGenerationTask *pEVar10;
  bool bVar11;
  int local_48;
  int local_44;
  int local_40;
  int local_3c;
  
  ::BoundingBox::BoundingBox((BoundingBox *)&local_48,param_1,param_5);
  iVar7 = local_48 + (int)param_4 >> 8;
  uVar1 = *(int *)(this + 0x4890) + iVar7;
  bVar8 = true;
  if (uVar1 < 0x60) {
    iVar9 = (int)((ulong)param_4 >> 0x20);
    iVar4 = local_44 + iVar9 >> 8;
    uVar2 = *(int *)(this + 0x4894) + iVar4;
    if (((-1 < (int)uVar2) && (uVar2 < 0x60)) &&
       (iVar5 = local_40 + (int)param_4 >> 8, (uint)(*(int *)(this + 0x4890) + iVar5) < 0x60)) {
      iVar9 = local_3c + iVar9 >> 8;
      uVar3 = *(int *)(this + 0x4894) + iVar9;
      if ((-1 < (int)uVar3) && (uVar3 < 0x60)) {
        if (iVar5 < iVar7) {
          bVar8 = false;
        }
        else {
          if (iVar9 < iVar4) {
            return false;
          }
          iVar4 = (iVar9 - iVar4) + 1;
          this = this + (ulong)uVar2 * 2 + (ulong)uVar1 * 0xc0 + 0x90;
          bVar11 = true;
          iVar9 = iVar4;
          pEVar10 = this;
          do {
            do {
              if ((param_3 & 0xffffffffffffff &
                  *(ulong *)(&Tile::collisionMasks + (ulong)*(ushort *)this * 8)) != 0) {
                return bVar11;
              }
              this = this + 2;
              iVar9 = iVar9 + -1;
            } while (iVar9 != 0);
            bVar8 = false;
            this = pEVar10 + 0xc0;
            bVar6 = iVar7 != iVar5;
            bVar11 = iVar7 < iVar5;
            iVar9 = iVar4;
            pEVar10 = this;
            iVar7 = iVar7 + 1;
          } while (bVar6);
        }
      }
    }
  }
  return bVar8;
}



// ===== EntityMapGenerationTask::isInArea  @ 0x1014cdbc0 =====

/* EntityMapGenerationTask::isInArea(TilePosition const&) const */

bool __thiscall
EntityMapGenerationTask::isInArea(EntityMapGenerationTask *this,TilePosition *param_1)

{
  return ((uint)(*(int *)(this + 0x4890) + *(int *)param_1) < 0x60 &&
         -1 < *(int *)(this + 0x4894) + *(int *)(param_1 + 4)) &&
         (uint)(*(int *)(this + 0x4894) + *(int *)(param_1 + 4)) < 0x60;
}



// ===== EntityMapGenerationTask::applyEntities  @ 0x1014cca28 =====

/* EntityMapGenerationTask::applyEntities(Surface&) */

void __thiscall
EntityMapGenerationTask::applyEntities(EntityMapGenerationTask *this,Surface *param_1)

{
  undefined8 *puVar1;
  size_t sVar2;
  size_t sVar3;
  ulong uVar4;
  uint uVar5;
  undefined8 *puVar6;
  uint uVar7;
  byte bVar8;
  int iVar9;
  MapPosition *pMVar10;
  ulong uVar11;
  long *plVar12;
  void *pvVar13;
  long *plVar14;
  RandomGenerator *in_x5;
  undefined8 *puVar15;
  ulong uVar16;
  long *plVar17;
  long *plVar18;
  long *plVar19;
  EntityPrototype *pEVar20;
  long lVar21;
  undefined8 *puVar22;
  char cVar23;
  undefined8 local_5ac0;
  undefined8 local_5ab8;
  undefined8 local_5ab0;
  undefined1 local_5aa8;
  char local_5aa7;
  undefined1 local_5aa6;
  undefined8 local_5aa0;
  undefined8 local_5a98;
  undefined8 uStack_5a90;
  undefined8 local_5a88;
  undefined8 uStack_5a80;
  undefined8 local_5a78;
  undefined8 uStack_5a70;
  undefined8 local_5a68;
  undefined8 local_5a60;
  undefined8 uStack_5a58;
  undefined8 local_5a50;
  undefined2 local_5a43;
  undefined1 local_5a41;
  undefined4 local_5a40;
  undefined4 local_5a3c;
  undefined1 local_5a38;
  undefined8 local_5a30;
  undefined8 uStack_5a28;
  void *local_b0;
  void *local_a8;
  void *local_98;
  void *local_90;
  long *local_80;
  long *local_78;
  long *local_70;
  
  uVar7 = *(uint *)(*(long *)(this + 0x70) + 0x4c);
  local_80 = (long *)0x0;
  local_78 = (long *)0x0;
  local_70 = (long *)0x0;
  puVar22 = *(undefined8 **)(this + 0x18);
  puVar6 = *(undefined8 **)(this + 0x20);
  if (puVar22 == puVar6) {
    return;
  }
  plVar18 = (long *)0x0;
LAB_1014ccaf8:
  cVar23 = *(char *)((long)puVar22 + 0xe);
  if (cVar23 == '\0') {
    plVar19 = *(long **)(this + 0x68);
    puVar15 = (undefined8 *)*puVar22;
    bVar8 = *(byte *)((long)puVar15 + 0x17);
    puVar1 = (void *)*puVar15;
    if (-1 < (char)bVar8) {
      puVar1 = puVar15;
    }
    sVar2 = puVar15[1];
    if (-1 < (char)bVar8) {
      sVar2 = (ulong)bVar8;
    }
    plVar12 = (long *)*plVar19;
    plVar14 = (long *)plVar19[1];
    if (plVar12 != plVar14) {
      if (sVar2 == 0) {
        do {
          lVar21 = *plVar12;
          uVar11 = (ulong)*(byte *)(lVar21 + 0x27);
          if ((char)*(byte *)(lVar21 + 0x27) < '\0') {
            uVar11 = *(ulong *)(lVar21 + 0x18);
          }
          if (uVar11 == 0) goto LAB_1014ccba8;
          plVar12 = plVar12 + 1;
        } while (plVar12 != plVar14);
      }
      else {
        do {
          lVar21 = *plVar12;
          bVar8 = *(byte *)(lVar21 + 0x27);
          puVar15 = *(void **)(lVar21 + 0x10);
          if (-1 < (char)bVar8) {
            puVar15 = (undefined8 *)(lVar21 + 0x10);
          }
          sVar3 = *(size_t *)(lVar21 + 0x18);
          if (-1 < (char)bVar8) {
            sVar3 = (ulong)bVar8;
          }
          if ((sVar2 == sVar3) && (iVar9 = _memcmp(puVar1,puVar15,sVar2), iVar9 == 0))
          goto LAB_1014ccba8;
          plVar12 = plVar12 + 1;
        } while (plVar12 != plVar14);
      }
    }
    goto LAB_1014ccbb0;
  }
  goto LAB_1014ccbc8;
LAB_1014ccba8:
  cVar23 = *(char *)(lVar21 + 8);
  if (cVar23 == '\0') {
LAB_1014ccbb0:
    lVar21 = ForceManager::create(plVar19,puVar1,sVar2,0);
    cVar23 = *(char *)(lVar21 + 8);
  }
LAB_1014ccbc8:
  pEVar20 = *(EntityPrototype **)
             (*(long *)PTR_indexToPrototype_102d4c840 + (ulong)*(ushort *)((long)puVar22 + 0xc) * 8)
  ;
  pMVar10 = (MapPosition *)(**(code **)(*(long *)pEVar20 + 0x2d0))(pEVar20);
  plVar19 = plVar18;
  if ((pMVar10 != (MapPosition *)0x0) &&
     (*(CliffPrototype **)(pMVar10 + 0xb60) != (CliffPrototype *)0x0)) {
    uVar11 = (long)*(int *)(puVar22 + 2) * 0x430a5d83 +
             (long)*(int *)((long)puVar22 + 0x14) * 0x36e998b7;
    uVar5 = uVar7 ^ (uint)uVar11 ^ (uint)(uVar11 >> 0x13);
    if (uVar5 < 0x156) {
      uVar5 = 0x155;
    }
    local_5ac0 = (EntityPrototype *)CONCAT44(uVar5,uVar5);
    local_5ab8 = CONCAT44(local_5ab8._4_4_,uVar5);
    CliffCraterPlacer::tryToPlaceCliffAsCrater
              ((CliffCraterPlacer *)param_1,(Surface *)(puVar22 + 2),pMVar10,
               *(CliffPrototype **)(pMVar10 + 0xb60),(CraterPlacementDefinition *)&local_5ac0,in_x5)
    ;
    goto LAB_1014ccaec;
  }
  uVar11 = Surface::mapGeneratorWouldCollide
                     ((Surface *)param_1,pEVar20,(MapPosition *)(puVar22 + 2),
                      (Direction *)((long)puVar22 + 0xf));
  if ((uVar11 & 1) != 0) goto LAB_1014ccaec;
  local_5ab8 = *(undefined8 *)(param_1 + 0xb8);
  local_5aa8 = *(undefined1 *)((long)puVar22 + 0xf);
  local_5ab0 = puVar22[2];
  local_5aa6 = CorePrototypes::normalQuality;
  local_5aa0 = 0;
  uStack_5a90 = 0x7fffffff7fffffff;
  local_5a98 = 0x7fffffff7fffffff;
  local_5a88 = 0;
  uStack_5a80 = 0;
  uStack_5a70 = 0x7fffffff7fffffff;
  local_5a78 = 0x7fffffff7fffffff;
  local_5a60 = 0;
  uStack_5a58 = 0;
  local_5a68 = 0;
  local_5a50 = 0x7fffffff7fffffff;
  local_5a41 = 0x14;
  local_5a3c = 0x10000ff;
  local_5a38 = 0;
  local_5a30 = 0;
  uStack_5a28 = 0;
  local_5a43 = 0x101;
  local_5a40 = *(undefined4 *)(puVar22 + 1);
  local_5ac0 = pEVar20;
  local_5aa7 = cVar23;
  plVar12 = (long *)(**(code **)(*(long *)pEVar20 + 0x6b0))(pEVar20,&local_5ac0);
  if (plVar12 == (long *)0x0) goto LAB_1014ccaec;
  in_x5 = (RandomGenerator *)0x0;
  Surface::addEntity((Surface *)param_1,plVar12,0,this[0x10] == (EntityMapGenerationTask)0x1,0,0,0);
  iVar9 = (**(code **)(*plVar12 + 0x890))(plVar12);
  plVar14 = local_80;
  if (iVar9 == 0) goto LAB_1014ccaec;
  if (plVar18 != local_70) {
    plVar19 = plVar18 + 1;
    *plVar18 = (long)plVar12;
    local_78 = plVar19;
    goto LAB_1014ccaec;
  }
  uVar16 = (long)plVar18 - (long)local_80;
  lVar21 = (long)uVar16 >> 3;
  uVar11 = lVar21 + 1;
  if (uVar11 >> 0x3d != 0) {
                    /* WARNING: Subroutine does not return */
    std::vector<Entity*,std::allocator<Entity*>>::__throw_length_error_abi_v160006_();
  }
  uVar4 = uVar16 >> 2;
  if (uVar16 >> 2 <= uVar11) {
    uVar4 = uVar11;
  }
  if (0x7ffffffffffffff7 < uVar16) {
    uVar4 = 0x1fffffffffffffff;
  }
  if (uVar4 == 0) {
    pvVar13 = (void *)0x0;
    plVar17 = (long *)(lVar21 * 8);
    plVar19 = plVar17 + 1;
    *plVar17 = (long)plVar12;
    if (plVar18 == local_80) goto LAB_1014ccd7c;
LAB_1014ccda8:
    do {
      plVar18 = plVar18 + -1;
      plVar17 = plVar17 + -1;
      *plVar17 = *plVar18;
    } while (plVar18 != plVar14);
    local_70 = (long *)((long)pvVar13 + uVar4 * 8);
    plVar18 = local_80;
  }
  else {
    if (uVar4 >> 0x3d != 0) {
                    /* WARNING: Subroutine does not return */
      std::__throw_bad_array_new_length_abi_v160006_();
    }
    pvVar13 = operator_new(uVar4 << 3);
    plVar17 = (long *)((long)pvVar13 + lVar21 * 8);
    plVar19 = plVar17 + 1;
    *plVar17 = (long)plVar12;
    if (plVar18 != plVar14) goto LAB_1014ccda8;
LAB_1014ccd7c:
    local_70 = (long *)((long)pvVar13 + uVar4 * 8);
  }
  local_80 = plVar17;
  local_78 = plVar19;
  if (plVar18 != (long *)0x0) {
    operator_delete(plVar18);
  }
LAB_1014ccaec:
  plVar12 = local_80;
  puVar22 = puVar22 + 3;
  plVar18 = plVar19;
  if (puVar22 == puVar6) {
    if (local_80 != plVar19) {
      DecalPlacementHelper::DecalPlacementHelper
                ((DecalPlacementHelper *)&local_5ac0,param_1,*(undefined8 *)(this + 0x60));
      plVar18 = plVar12;
      do {
        plVar14 = (long *)*plVar18;
        if ((*(ushort *)(plVar14 + 0xb) >> 4 & 1) == 0) {
          (**(code **)(*plVar14 + 0x898))(plVar14,&local_5ac0);
        }
        plVar18 = plVar18 + 1;
      } while (plVar18 != plVar19);
      DecalPlacementHelper::commitChanges((DecalPlacementHelper *)&local_5ac0);
      if (local_98 != (void *)0x0) {
        local_90 = local_98;
        operator_delete(local_98);
      }
      if (local_b0 != (void *)0x0) {
        local_a8 = local_b0;
        operator_delete(local_b0);
      }
    }
    if (plVar12 == (long *)0x0) {
      return;
    }
    operator_delete(plVar12);
    return;
  }
  goto LAB_1014ccaf8;
}



// ===== EntityMapGenerationTask::applyCliffs  @ 0x1014cc484 =====

/* EntityMapGenerationTask::applyCliffs(Surface&) */

void __thiscall EntityMapGenerationTask::applyCliffs(EntityMapGenerationTask *this,Surface *param_1)

{
  ulong uVar1;
  bool bVar2;
  ulong uVar3;
  ushort *puVar4;
  long *plVar5;
  long *plVar6;
  long *plVar7;
  int iVar8;
  long lVar9;
  void *pvVar10;
  ulong uVar11;
  long *plVar12;
  long *plVar13;
  long *plVar14;
  ushort *puVar15;
  long lVar16;
  long *local_138;
  undefined8 uStack_130;
  undefined8 local_128;
  undefined2 local_120;
  undefined1 local_11e;
  undefined8 local_118;
  undefined8 local_110;
  undefined8 uStack_108;
  undefined8 local_100;
  undefined8 uStack_f8;
  undefined8 local_f0;
  undefined8 uStack_e8;
  undefined8 local_e0;
  undefined8 local_d8;
  undefined8 uStack_d0;
  undefined8 local_c8;
  undefined4 uStack_c0;
  undefined2 uStack_bc;
  undefined1 uStack_ba;
  undefined1 local_b9;
  undefined8 local_b8;
  undefined1 local_b0;
  undefined8 local_a8;
  undefined8 uStack_a0;
  long *local_98;
  long *local_90;
  long *local_88;
  long *local_80;
  long *local_78;
  long *local_70;
  
  local_80 = (long *)0x0;
  local_78 = (long *)0x0;
  local_70 = (long *)0x0;
  local_98 = (long *)0x0;
  local_90 = (long *)0x0;
  local_88 = (long *)0x0;
  puVar15 = *(ushort **)(this + 0x30);
  puVar4 = *(ushort **)(this + 0x38);
  if (puVar15 == puVar4) {
    plVar13 = (long *)0x0;
    plVar14 = local_98;
    plVar12 = local_98;
    plVar6 = local_90;
  }
  else {
    do {
      plVar14 = *(long **)(*(long *)PTR_indexToPrototype_102d4c840 + (ulong)*puVar15 * 8);
      iVar8 = Surface::wouldCollide((Surface *)param_1,plVar14,puVar15 + 2,(char)puVar15[1]);
      uStack_130 = *(undefined8 *)(param_1 + 0xb8);
      local_128 = *(undefined8 *)(puVar15 + 2);
      local_120 = 0x300;
      local_11e = CorePrototypes::normalQuality;
      local_118 = 0;
      uStack_108 = 0x7fffffff7fffffff;
      local_110 = 0x7fffffff7fffffff;
      local_100 = 0;
      uStack_f8 = 0;
      uStack_e8 = 0x7fffffff7fffffff;
      local_f0 = 0x7fffffff7fffffff;
      local_d8 = 0;
      uStack_d0 = 0;
      local_e0 = 0;
      uStack_bc = 0;
      uStack_c0 = 0;
      local_c8 = 0x7fffffff7fffffff;
      local_b8 = 0x10000ff00000000;
      local_b0 = 0;
      local_a8 = 0;
      uStack_a0 = 0;
      local_b9 = (undefined1)puVar15[1];
      uStack_ba = 1;
      local_138 = plVar14;
      lVar9 = (**(code **)(*plVar14 + 0x6b0))(plVar14,&local_138);
      if (lVar9 != 0) {
        Surface::addEntity((Surface *)param_1,lVar9,0,this[0x10] == (EntityMapGenerationTask)0x1,0,0
                           ,0);
        plVar14 = local_78;
        plVar13 = local_80;
        plVar12 = local_90;
        plVar6 = local_98;
        if (iVar8 == 0) {
          if ((char)puVar15[6] == '\0') {
            if (local_90 == local_88) {
              uVar11 = (long)local_90 - (long)local_98;
              lVar16 = (long)uVar11 >> 3;
              uVar1 = lVar16 + 1;
              if (uVar1 >> 0x3d != 0) goto LAB_1014cc838;
              uVar3 = uVar11 >> 2;
              if (uVar11 >> 2 <= uVar1) {
                uVar3 = uVar1;
              }
              if (0x7ffffffffffffff7 < uVar11) {
                uVar3 = 0x1fffffffffffffff;
              }
              if (uVar3 == 0) {
                pvVar10 = (void *)0x0;
                plVar14 = (long *)(lVar16 * 8);
                *plVar14 = lVar9;
                plVar13 = local_98;
              }
              else {
                if (uVar3 >> 0x3d != 0) goto LAB_1014cc82c;
                pvVar10 = operator_new(uVar3 << 3);
                plVar14 = (long *)((long)pvVar10 + lVar16 * 8);
                *plVar14 = lVar9;
                plVar13 = local_98;
              }
              local_90 = plVar14 + 1;
              plVar5 = plVar12;
              local_98 = plVar14;
              while (plVar12 != plVar6) {
                plVar12 = plVar12 + -1;
                local_98 = local_98 + -1;
                *local_98 = *plVar12;
                plVar5 = plVar13;
              }
              local_88 = (long *)((long)pvVar10 + uVar3 * 8);
              goto joined_r0x0001014cc724;
            }
            *local_90 = lVar9;
            local_90 = local_90 + 1;
          }
        }
        else if (local_78 == local_70) {
          uVar11 = (long)local_78 - (long)local_80;
          lVar16 = (long)uVar11 >> 3;
          uVar1 = lVar16 + 1;
          if (uVar1 >> 0x3d != 0) {
LAB_1014cc838:
                    /* WARNING: Subroutine does not return */
            std::vector<Entity*,std::allocator<Entity*>>::__throw_length_error_abi_v160006_();
          }
          uVar3 = uVar11 >> 2;
          if (uVar11 >> 2 <= uVar1) {
            uVar3 = uVar1;
          }
          if (0x7ffffffffffffff7 < uVar11) {
            uVar3 = 0x1fffffffffffffff;
          }
          if (uVar3 == 0) {
            pvVar10 = (void *)0x0;
            plVar12 = (long *)(lVar16 * 8);
            *plVar12 = lVar9;
          }
          else {
            if (uVar3 >> 0x3d != 0) {
LAB_1014cc82c:
                    /* WARNING: Subroutine does not return */
              std::__throw_bad_array_new_length_abi_v160006_();
            }
            pvVar10 = operator_new(uVar3 << 3);
            plVar12 = (long *)((long)pvVar10 + lVar16 * 8);
            *plVar12 = lVar9;
          }
          local_78 = plVar12 + 1;
          plVar5 = plVar14;
          while (plVar14 != plVar13) {
            plVar14 = plVar14 + -1;
            plVar12 = plVar12 + -1;
            *plVar12 = *plVar14;
            plVar5 = local_80;
          }
          local_70 = (long *)((long)pvVar10 + uVar3 * 8);
          local_80 = plVar12;
joined_r0x0001014cc724:
          if (plVar5 != (long *)0x0) {
            operator_delete(plVar5);
          }
        }
        else {
          *local_78 = lVar9;
          local_78 = local_78 + 1;
        }
      }
      plVar7 = local_78;
      plVar13 = local_80;
      puVar15 = puVar15 + 8;
      plVar5 = local_80;
    } while (puVar15 != puVar4);
    for (; plVar14 = local_98, plVar12 = local_98, plVar6 = local_90, plVar5 != plVar7;
        plVar5 = plVar5 + 1) {
      if ((*(ushort *)((Entity *)*plVar5 + 0x58) >> 4 & 1) == 0) {
        Entity::forceDestroy((Entity *)*plVar5);
      }
    }
  }
  for (; plVar7 = local_90, plVar5 = local_98, plVar14 != local_90; plVar14 = plVar14 + 1) {
    local_98 = plVar12;
    local_90 = plVar6;
    if ((*(ushort *)((long *)*plVar14 + 0xb) >> 4 & 1) == 0) {
      (**(code **)(*(long *)*plVar14 + 0x6e8))();
    }
    plVar12 = local_98;
    plVar6 = local_90;
    local_90 = plVar7;
    local_98 = plVar5;
  }
  bVar2 = local_98 != (long *)0x0;
  local_98 = plVar12;
  local_90 = plVar6;
  if (bVar2) {
    operator_delete(plVar5);
  }
  if (plVar13 != (long *)0x0) {
    local_78 = plVar13;
    operator_delete(plVar13);
  }
  return;
}



// ===== Surface::wouldCollide  @ 0x1014b4cc8 =====

/* Surface::wouldCollide(CliffPrototype const&, MapPosition const&, CliffOrientation) const */

bool __thiscall Surface::wouldCollide(Surface *this,long param_1,int *param_2,undefined4 param_4)

{
  int iVar1;
  int iVar2;
  int iVar3;
  bool bVar4;
  int iVar5;
  long *plVar6;
  long lVar7;
  ulong uVar8;
  undefined8 local_80;
  undefined8 uStack_78;
  undefined4 local_70;
  undefined1 local_68 [24];
  undefined8 local_50;
  undefined1 auStack_48 [24];
  undefined8 local_30;
  long local_28;
  
  local_28 = *(long *)PTR____stack_chk_guard_102d481b8;
  switch(param_4) {
  case 0:
    lVar7 = param_1 + 0x590;
    break;
  case 1:
    lVar7 = param_1 + 0x5d8;
    break;
  case 2:
    lVar7 = param_1 + 0x620;
    break;
  case 3:
    lVar7 = param_1 + 0x668;
    break;
  case 4:
    lVar7 = param_1 + 0x6b0;
    break;
  case 5:
    lVar7 = param_1 + 0x6f8;
    break;
  case 6:
    lVar7 = param_1 + 0x740;
    break;
  case 7:
    lVar7 = param_1 + 0x788;
    break;
  case 8:
    lVar7 = param_1 + 2000;
    break;
  case 9:
    lVar7 = param_1 + 0x818;
    break;
  case 10:
    lVar7 = param_1 + 0x860;
    break;
  case 0xb:
    lVar7 = param_1 + 0x8a8;
    break;
  case 0xc:
    lVar7 = param_1 + 0x8f0;
    break;
  case 0xd:
    lVar7 = param_1 + 0x938;
    break;
  case 0xe:
    lVar7 = param_1 + 0xa10;
    break;
  case 0xf:
    lVar7 = param_1 + 0xa58;
    break;
  case 0x10:
    lVar7 = param_1 + 0x980;
    break;
  case 0x11:
    lVar7 = param_1 + 0x9c8;
    break;
  case 0x12:
    lVar7 = param_1 + 0xaa0;
    break;
  case 0x13:
    lVar7 = param_1 + 0xae8;
    break;
  default:
                    /* WARNING: Subroutine does not return */
    Logging::logAndAbortOrThrow
              ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Entity/CliffPrototype.cpp"
               ,0xd1,9,"Invalid cliff orientation: %u");
  }
  local_70 = *(undefined4 *)(lVar7 + 0x14);
  local_80._0_4_ = (int)*(undefined8 *)(lVar7 + 4);
  iVar5 = (int)local_80;
  local_80._4_4_ = (int)((ulong)*(undefined8 *)(lVar7 + 4) >> 0x20);
  iVar1 = local_80._4_4_;
  local_80 = CONCAT44(local_80._4_4_ + param_2[1],(int)local_80 + *param_2);
  uStack_78._0_4_ = (int)*(undefined8 *)(lVar7 + 0xc);
  iVar2 = (int)uStack_78;
  uStack_78._4_4_ = (int)((ulong)*(undefined8 *)(lVar7 + 0xc) >> 0x20);
  iVar3 = uStack_78._4_4_;
  uStack_78 = CONCAT44(uStack_78._4_4_ + param_2[1],(int)uStack_78 + *param_2);
  uVar8 = *(ulong *)(param_1 + 0x2a8);
  if ((iVar5 == iVar2) && (iVar1 == iVar3)) {
    bVar4 = false;
  }
  else {
    local_68[0] = 0;
    if ((uVar8 & Tile::sumOfAllCollisionMasks & 0xffffffffffffff) != 0) {
      if ((uVar8 >> 0x39 & 1) == 0) {
        ::BoundingBox::getAABB();
        iVar5 = checkTileCollisions(this,&local_80,auStack_48,uVar8,local_68,0,0,0,0);
      }
      else {
        ::BoundingBox::getAABB();
        iVar5 = collideBBWithTileWithTransitions(this,&local_80,auStack_48,uVar8);
      }
      if (iVar5 != 0) {
        bVar4 = true;
        goto LAB_1014b4eb0;
      }
    }
    local_30 = 0;
    local_50 = 0;
    plVar6 = (long *)collideWithEntity(this,&local_80,uVar8,0,auStack_48,local_68);
    bVar4 = plVar6 != (long *)0x0;
    if (plVar6 != (long *)0x0) {
      (**(code **)(*plVar6 + 0x220))();
    }
  }
LAB_1014b4eb0:
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_28) {
    return bVar4;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}



// ===== Surface::wouldCollide  @ 0x1014c16a8 =====

/* Surface::wouldCollide(DecorativePrototype const&, MapPosition const&, Direction const&) const */

bool __thiscall
Surface::wouldCollide
          (Surface *this,DecorativePrototype *param_1,MapPosition *param_2,Direction *param_3)

{
  int iVar1;
  int iVar2;
  bool bVar3;
  int iVar4;
  undefined8 uVar5;
  long *plVar6;
  int iVar7;
  ulong uVar8;
  int local_90;
  int iStack_8c;
  int local_88;
  int iStack_84;
  undefined1 local_78 [24];
  undefined8 local_60;
  undefined1 auStack_58 [24];
  undefined8 local_40;
  long local_38;
  
  local_38 = *(long *)PTR____stack_chk_guard_102d481b8;
  ::BoundingBox::BoundingBox((BoundingBox *)&local_90,param_1 + 0x18c,*param_3);
  uVar5 = DecorativePrototype::finalPosition
                    (param_1,CONCAT44(*(int *)(param_2 + 4) >> 8,*(int *)param_2 >> 8));
  iVar4 = local_90 + (int)uVar5;
  iVar7 = (int)((ulong)uVar5 >> 0x20);
  iVar1 = iStack_8c + iVar7;
  iVar2 = local_88 + (int)uVar5;
  iVar7 = iStack_84 + iVar7;
  uVar8 = *(ulong *)(param_1 + 0x1b8);
  if ((local_90 == local_88) && (iStack_8c == iStack_84)) {
    bVar3 = false;
    local_90 = iVar4;
    iStack_8c = iVar1;
    local_88 = iVar2;
    iStack_84 = iVar7;
  }
  else {
    local_78[0] = 0;
    local_90 = iVar4;
    iStack_8c = iVar1;
    local_88 = iVar2;
    iStack_84 = iVar7;
    if ((uVar8 & Tile::sumOfAllCollisionMasks & 0xffffffffffffff) != 0) {
      if ((uVar8 >> 0x39 & 1) == 0) {
        ::BoundingBox::getAABB();
        iVar4 = checkTileCollisions(this,&local_90,auStack_58,uVar8,local_78,0,0,0,0);
      }
      else {
        ::BoundingBox::getAABB();
        iVar4 = collideBBWithTileWithTransitions(this,&local_90,auStack_58,uVar8);
      }
      if (iVar4 != 0) {
        bVar3 = true;
        goto LAB_1014c17f4;
      }
    }
    local_40 = 0;
    local_60 = 0;
    plVar6 = (long *)collideWithEntity(this,&local_90,uVar8,0,auStack_58,local_78);
    bVar3 = plVar6 != (long *)0x0;
    if (plVar6 != (long *)0x0) {
      (**(code **)(*plVar6 + 0x220))();
    }
  }
LAB_1014c17f4:
  if (*(long *)PTR____stack_chk_guard_102d481b8 != local_38) {
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail();
  }
  return bVar3;
}



// ===== CliffGenerator::crossesCliff  @ 0x1014b5598 =====

/* CliffGenerator::crossesCliff(float, float, float, float, float) */

int CliffGenerator::crossesCliff
              (float param_1,float param_2,float param_3,float param_4,float param_5)

{
  uint uVar1;
  int iVar2;
  uint uVar3;
  float fVar4;
  
  iVar2 = 0;
  if ((0.0 <= param_1) && (0.0 <= param_2)) {
    fVar4 = param_1;
    if (param_1 <= param_2) {
      fVar4 = param_2;
    }
    fVar4 = (float)(int)((fVar4 - param_4) / param_5) * param_5 + param_4;
    if (fVar4 < param_4) {
      return 0;
    }
    if (((0.5 < param_3) && (param_1 - fVar4 < 0.0)) && (0.0 < param_2 - fVar4)) {
      return 1;
    }
    uVar3 = 0;
    if (param_2 - fVar4 < 0.0) {
      uVar3 = (uint)(0.0 < param_1 - fVar4);
    }
    uVar1 = 0;
    if (0.5 < param_3) {
      uVar1 = uVar3;
    }
    iVar2 = -uVar1;
  }
  return iVar2;
}



// ===== CliffGenerator::getNoiseCacheSize  @ 0x1014b5624 =====

/* CliffGenerator::getNoiseCacheSize(CliffPrototype const*) */

int CliffGenerator::getNoiseCacheSize(CliffPrototype *param_1)

{
  uint uVar1;
  uint uVar2;
  int iVar3;
  
  iVar3 = 0;
  if (param_1 != (CliffPrototype *)0x0) {
    uVar1 = 0;
    if ((int)*(double *)(param_1 + 0xb30) != 0) {
      uVar1 = 0x20 / (uint)(int)*(double *)(param_1 + 0xb30);
    }
    uVar2 = 0;
    if ((int)*(double *)(param_1 + 0xb38) != 0) {
      uVar2 = 0x20 / (uint)(int)*(double *)(param_1 + 0xb38);
    }
    iVar3 = uVar1 + 1 + (uVar1 + 1) * uVar2;
  }
  return iVar3;
}



// ===== CliffGenerator::crossingsForChunk  @ 0x1014b5650 =====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* CliffGenerator::crossingsForChunk(CompiledMapGenSettings const&, ChunkPosition const&) */

void __thiscall
CliffGenerator::crossingsForChunk
          (CliffGenerator *this,CompiledMapGenSettings *param_1,ChunkPosition *param_2)

{
  uint uVar1;
  ulong uVar2;
  undefined8 *puVar3;
  undefined8 *puVar4;
  uint uVar5;
  int iVar6;
  long lVar7;
  ulong uVar8;
  ulong uVar9;
  ulong uVar10;
  ulong uVar11;
  ulong uVar12;
  ulong uVar13;
  ulong uVar14;
  ulong uVar15;
  ulong uVar16;
  ulong uVar17;
  ulong uVar18;
  ulong uVar19;
  ulong uVar20;
  bool bVar21;
  void *pvVar22;
  long lVar23;
  long lVar24;
  uint uVar25;
  uint uVar26;
  CellEdgeCliffCrossingArray *in_x8;
  ulong uVar27;
  uint uVar28;
  uint uVar29;
  int iVar30;
  char cVar31;
  uint uVar32;
  ulong uVar33;
  ulong uVar34;
  uint uVar35;
  uint uVar36;
  float fVar37;
  float fVar38;
  float fVar39;
  float fVar40;
  float fVar41;
  float fVar42;
  float fVar43;
  float fVar44;
  float fVar45;
  float fVar46;
  float fVar47;
  float fVar48;
  float fVar49;
  float fVar50;
  float fVar51;
  float fVar52;
  undefined8 uVar53;
  float fVar54;
  float fVar55;
  float fVar56;
  undefined8 uVar57;
  float fVar58;
  ulong local_d0;
  uint local_c8;
  ulong local_c0;
  long local_b8;
  void *local_b0;
  undefined1 local_a8;
  undefined8 local_a4;
  undefined8 local_9c;
  float local_94;
  long local_90;
  void *local_88;
  
  fVar52 = *(float *)(this + 0xcc);
  fVar56 = 0.0;
  if (**(float **)(this + 0x128) != 0.0) {
    fVar56 = **(float **)(this + 0x128);
  }
  uVar36 = (uint)*(double *)(*(long *)(this + 0xa8) + 0xb30);
  uVar28 = (uint)*(double *)(*(long *)(this + 0xa8) + 0xb38);
  uVar26 = 0;
  if (uVar36 != 0) {
    uVar26 = 0x20 / uVar36;
  }
  uVar35 = 0;
  if (uVar28 != 0) {
    uVar35 = 0x20 / uVar28;
  }
  *(uint *)in_x8 = uVar26;
  *(uint *)(in_x8 + 4) = uVar35;
  iVar30 = uVar35 + 1;
  *(undefined8 *)(in_x8 + 0x10) = 0;
  *(undefined8 *)(in_x8 + 0x18) = 0;
  uVar33 = (ulong)(iVar30 * uVar26);
  *(undefined8 *)(in_x8 + 8) = 0;
  if (iVar30 * uVar26 == 0) {
    *(undefined8 *)(in_x8 + 0x20) = 0;
    *(undefined8 *)(in_x8 + 0x28) = 0;
    *(undefined8 *)(in_x8 + 0x30) = 0;
  }
  else {
    pvVar22 = operator_new(uVar33);
    *(void **)(in_x8 + 8) = pvVar22;
    *(void **)(in_x8 + 0x10) = pvVar22;
    *(void **)(in_x8 + 0x18) = (void *)((long)pvVar22 + uVar33);
    if (uVar33 != 0) {
      _bzero(pvVar22,uVar33);
      pvVar22 = (void *)((long)pvVar22 + uVar33);
    }
    *(void **)(in_x8 + 0x10) = pvVar22;
    *(undefined8 *)(in_x8 + 0x20) = 0;
    *(undefined8 *)(in_x8 + 0x28) = 0;
    *(undefined8 *)(in_x8 + 0x30) = 0;
  }
  uVar1 = uVar26 + 1;
  if (uVar1 * uVar35 != 0) {
    uVar33 = (ulong)(uVar1 * uVar35);
    pvVar22 = operator_new(uVar33);
    *(void **)(in_x8 + 0x20) = pvVar22;
    *(void **)(in_x8 + 0x28) = pvVar22;
    *(void **)(in_x8 + 0x30) = (void *)((long)pvVar22 + uVar33);
    if (uVar33 != 0) {
      _bzero(pvVar22,uVar33);
      pvVar22 = (void *)((long)pvVar22 + uVar33);
    }
    *(void **)(in_x8 + 0x28) = pvVar22;
  }
  uVar53 = *(undefined8 *)param_1;
  uVar34 = (ulong)(iVar30 * uVar1);
  uVar5 = *(uint *)(this + 0x1c0);
  local_b8 = uVar34 + 1;
  uVar33 = local_b8 * 0x10;
  local_d0 = uVar34;
  local_c8 = uVar5;
  pvVar22 = operator_new__(uVar33);
  _bzero(pvVar22,uVar33);
  local_9c = 0;
  local_90 = uVar5 * uVar34;
  local_a4 = 0;
  local_94 = 0.0;
  local_b0 = pvVar22;
  local_88 = operator_new__(local_90 * 4);
  fVar37 = (float)uVar36;
  uVar53 = NEON_scvtf(CONCAT44((int)((ulong)uVar53 >> 0x20) << 5,(int)uVar53 << 5),4);
  local_a8 = fVar37 == (float)uVar28;
  if ((bool)local_a8) {
    local_9c = CONCAT44(iVar30,uVar1);
    local_a4 = uVar53;
    local_94 = fVar37;
  }
  local_c0 = uVar34;
  lVar23 = NoiseCache::getFloatRegister((NoiseCache *)&local_d0,0);
  lVar24 = NoiseCache::getFloatRegister((NoiseCache *)&local_d0,1);
  uVar27 = 0;
  fVar58 = (float)uVar53;
  fVar48 = (float)_DAT_102971e80;
  uVar33 = (ulong)_DAT_102971e80 >> 0x20;
  fVar43 = (float)_UNK_102971e88;
  uVar34 = (ulong)_UNK_102971e88 >> 0x20;
  fVar38 = (float)_DAT_102971e90;
  uVar2 = (ulong)_DAT_102971e90 >> 0x20;
  fVar39 = (float)_UNK_102971e98;
  uVar8 = (ulong)_UNK_102971e98 >> 0x20;
  fVar40 = (float)_DAT_102971ea0;
  uVar9 = (ulong)_DAT_102971ea0 >> 0x20;
  fVar41 = (float)_UNK_102971ea8;
  uVar10 = (ulong)_UNK_102971ea8 >> 0x20;
  fVar42 = (float)_DAT_102971eb0;
  uVar11 = (ulong)_DAT_102971eb0 >> 0x20;
  fVar44 = (float)_UNK_102971eb8;
  uVar12 = (ulong)_UNK_102971eb8 >> 0x20;
  fVar45 = (float)_DAT_102971ec0;
  uVar13 = (ulong)_DAT_102971ec0 >> 0x20;
  fVar46 = (float)_UNK_102971ec8;
  uVar14 = (ulong)_UNK_102971ec8 >> 0x20;
  fVar47 = (float)_DAT_102971ed0;
  uVar15 = (ulong)_DAT_102971ed0 >> 0x20;
  fVar49 = (float)_UNK_102971ed8;
  uVar16 = (ulong)_UNK_102971ed8 >> 0x20;
  fVar50 = (float)_DAT_102971ee0;
  uVar17 = (ulong)_DAT_102971ee0 >> 0x20;
  fVar51 = (float)_UNK_102971ee8;
  uVar18 = (ulong)_UNK_102971ee8 >> 0x20;
  fVar54 = (float)_DAT_102971ef0;
  uVar19 = (ulong)_DAT_102971ef0 >> 0x20;
  fVar55 = (float)_UNK_102971ef8;
  uVar20 = (ulong)_UNK_102971ef8 >> 0x20;
  uVar5 = uVar1 & 0x7c;
  fVar52 = fVar52 / fVar56;
  uVar29 = 0;
  do {
    fVar56 = (float)uVar28 * (float)uVar29 + (float)((ulong)uVar53 >> 0x20);
    uVar25 = (uint)uVar27;
    uVar32 = 0;
    if ((4 < uVar36) || (CARRY4(uVar25,uVar26))) {
LAB_1014b59e0:
      do {
        *(float *)(lVar23 + uVar27 * 4) = fVar37 * (float)uVar32 + fVar58;
        *(float *)(lVar24 + uVar27 * 4) = fVar56;
        uVar32 = uVar32 + 1;
        uVar27 = (ulong)((int)uVar27 + 1);
      } while (uVar26 + 1 != uVar32);
    }
    else {
      if ((ulong)(lVar24 - lVar23) < 0x10) {
        uVar32 = 0;
        goto LAB_1014b59e0;
      }
      uVar57 = CONCAT44(fVar56,fVar56);
      puVar3 = (undefined8 *)(lVar23 + uVar27 * 4);
      puVar3[1] = CONCAT44((float)uVar34 * fVar37 + fVar58,fVar43 * fVar37 + fVar58);
      *puVar3 = CONCAT44((float)uVar33 * fVar37 + fVar58,fVar48 * fVar37 + fVar58);
      puVar3 = (undefined8 *)(lVar24 + uVar27 * 4);
      puVar3[1] = uVar57;
      *puVar3 = CONCAT44(fVar56,fVar56);
      if (uVar5 != 4) {
        lVar7 = (ulong)(uVar25 + 4) * 4;
        puVar3 = (undefined8 *)(lVar23 + lVar7);
        puVar3[1] = CONCAT44((float)uVar8 * fVar37 + fVar58,fVar39 * fVar37 + fVar58);
        *puVar3 = CONCAT44((float)uVar2 * fVar37 + fVar58,fVar38 * fVar37 + fVar58);
        puVar3 = (undefined8 *)(lVar24 + lVar7);
        puVar3[1] = uVar57;
        *puVar3 = CONCAT44(fVar56,fVar56);
        if (uVar5 != 8) {
          lVar7 = (ulong)(uVar25 + 8) * 4;
          puVar3 = (undefined8 *)(lVar23 + lVar7);
          puVar3[1] = CONCAT44((float)uVar10 * fVar37 + fVar58,fVar41 * fVar37 + fVar58);
          *puVar3 = CONCAT44((float)uVar9 * fVar37 + fVar58,fVar40 * fVar37 + fVar58);
          puVar3 = (undefined8 *)(lVar24 + lVar7);
          puVar3[1] = uVar57;
          *puVar3 = CONCAT44(fVar56,fVar56);
          if (uVar5 != 0xc) {
            lVar7 = (ulong)(uVar25 + 0xc) * 4;
            puVar3 = (undefined8 *)(lVar23 + lVar7);
            puVar3[1] = CONCAT44((float)uVar12 * fVar37 + fVar58,fVar44 * fVar37 + fVar58);
            *puVar3 = CONCAT44((float)uVar11 * fVar37 + fVar58,fVar42 * fVar37 + fVar58);
            puVar3 = (undefined8 *)(lVar24 + lVar7);
            puVar3[1] = uVar57;
            *puVar3 = CONCAT44(fVar56,fVar56);
            if (uVar5 != 0x10) {
              lVar7 = (ulong)(uVar25 + 0x10) * 4;
              puVar3 = (undefined8 *)(lVar23 + lVar7);
              puVar3[1] = CONCAT44((float)uVar14 * fVar37 + fVar58,fVar46 * fVar37 + fVar58);
              *puVar3 = CONCAT44((float)uVar13 * fVar37 + fVar58,fVar45 * fVar37 + fVar58);
              puVar3 = (undefined8 *)(lVar24 + lVar7);
              puVar3[1] = uVar57;
              *puVar3 = CONCAT44(fVar56,fVar56);
              if (uVar5 != 0x14) {
                lVar7 = (ulong)(uVar25 + 0x14) * 4;
                puVar3 = (undefined8 *)(lVar23 + lVar7);
                puVar3[1] = CONCAT44((float)uVar16 * fVar37 + fVar58,fVar49 * fVar37 + fVar58);
                *puVar3 = CONCAT44((float)uVar15 * fVar37 + fVar58,fVar47 * fVar37 + fVar58);
                puVar3 = (undefined8 *)(lVar24 + lVar7);
                puVar3[1] = uVar57;
                *puVar3 = CONCAT44(fVar56,fVar56);
                if (uVar5 != 0x18) {
                  lVar7 = (ulong)(uVar25 + 0x18) * 4;
                  puVar3 = (undefined8 *)(lVar23 + lVar7);
                  puVar3[1] = CONCAT44((float)uVar18 * fVar37 + fVar58,fVar51 * fVar37 + fVar58);
                  *puVar3 = CONCAT44((float)uVar17 * fVar37 + fVar58,fVar50 * fVar37 + fVar58);
                  puVar3 = (undefined8 *)(lVar24 + lVar7);
                  puVar3[1] = uVar57;
                  *puVar3 = CONCAT44(fVar56,fVar56);
                  if (uVar5 != 0x1c) {
                    lVar7 = (ulong)(uVar25 + 0x1c) * 4;
                    puVar3 = (undefined8 *)(lVar23 + lVar7);
                    puVar3[1] = CONCAT44((float)uVar20 * fVar37 + fVar58,fVar55 * fVar37 + fVar58);
                    *puVar3 = CONCAT44((float)uVar19 * fVar37 + fVar58,fVar54 * fVar37 + fVar58);
                    puVar3 = (undefined8 *)(lVar24 + lVar7);
                    puVar3[1] = uVar57;
                    *puVar3 = CONCAT44(fVar56,fVar56);
                  }
                }
              }
            }
          }
        }
      }
      uVar27 = (ulong)(uVar25 + uVar5);
      uVar32 = uVar5;
      if (uVar1 != uVar5) goto LAB_1014b59e0;
    }
    bVar21 = uVar29 == uVar35;
    uVar29 = uVar29 + 1;
    if (bVar21) {
      puVar4 = *(undefined8 **)(this + 0x1d0);
      for (puVar3 = *(undefined8 **)(this + 0x1c8); puVar3 != puVar4; puVar3 = puVar3 + 1) {
        (**(code **)(*(long *)*puVar3 + 0x18))((long *)*puVar3,&local_d0);
      }
      lVar23 = NoiseCache::getFloatRegister((NoiseCache *)&local_d0,*(undefined4 *)(this + 0x1e0));
      uVar33 = local_c0 << 2;
      if (local_c0 >> 0x3e != 0) {
        uVar33 = 0xffffffffffffffff;
      }
      pvVar22 = operator_new__(uVar33);
      uVar26 = uVar26 - 1;
      fVar56 = *(float *)(this + 0xd0);
      uVar28 = 0;
      do {
        uVar5 = uVar28 & 0xfffffffc;
        uVar29 = uVar5 + 4;
        if (uVar35 - 1 <= uVar5 + 4) {
          uVar29 = uVar35 - 1;
        }
        iVar30 = uVar5 * uVar1;
        iVar6 = uVar29 * uVar1;
        if (uVar29 - uVar5 == 0) {
          uVar33 = 0;
          do {
            uVar32 = (uint)uVar33;
            uVar5 = uVar32 & 0xfffffffc;
            uVar29 = uVar5 + 4;
            if (uVar26 <= uVar5 + 4) {
              uVar29 = uVar26;
            }
            fVar37 = 0.0;
            if (uVar29 - uVar5 != 0) {
              fVar37 = (float)(uVar32 & 3) / (float)(uVar29 - uVar5);
            }
            lVar24 = (ulong)(uVar28 * uVar1 + uVar32) * 4;
            *(float *)((long)pvVar22 + lVar24) =
                 fVar56 * (*(float *)(lVar23 + (ulong)(uVar5 + iVar30) * 4) * (1.0 - fVar37) +
                           fVar37 * *(float *)(lVar23 + (ulong)(uVar29 + iVar30) * 4) +
                           (1.0 - fVar37) * 0.0 * *(float *)(lVar23 + (ulong)(uVar5 + iVar6) * 4) +
                          fVar37 * 0.0 * *(float *)(lVar23 + (ulong)(uVar29 + iVar6) * 4)) +
                 (1.0 - fVar56) * *(float *)(lVar23 + lVar24);
            uVar33 = uVar33 + 1;
          } while (uVar1 != uVar33);
        }
        else {
          uVar33 = 0;
          fVar37 = (float)(uVar28 & 3) / (float)(uVar29 - uVar5);
          do {
            uVar32 = (uint)uVar33;
            uVar5 = uVar32 & 0xfffffffc;
            uVar29 = uVar5 + 4;
            if (uVar26 <= uVar5 + 4) {
              uVar29 = uVar26;
            }
            fVar48 = 0.0;
            if (uVar29 - uVar5 != 0) {
              fVar48 = (float)(uVar32 & 3) / (float)(uVar29 - uVar5);
            }
            lVar24 = (ulong)(uVar28 * uVar1 + uVar32) * 4;
            *(float *)((long)pvVar22 + lVar24) =
                 fVar56 * (*(float *)(lVar23 + (ulong)(uVar5 + iVar30) * 4) *
                           (1.0 - fVar48) * (1.0 - fVar37) +
                           fVar48 * (1.0 - fVar37) *
                           *(float *)(lVar23 + (ulong)(uVar29 + iVar30) * 4) +
                           (1.0 - fVar48) * fVar37 * *(float *)(lVar23 + (ulong)(uVar5 + iVar6) * 4)
                          + fVar48 * fVar37 * *(float *)(lVar23 + (ulong)(uVar29 + iVar6) * 4)) +
                 (1.0 - fVar56) * *(float *)(lVar23 + lVar24);
            uVar33 = uVar33 + 1;
          } while (uVar1 != uVar33);
        }
        bVar21 = uVar28 != uVar35;
        uVar28 = uVar28 + 1;
      } while (bVar21);
      lVar23 = NoiseCache::getFloatRegister((NoiseCache *)&local_d0,*(undefined4 *)(this + 0x1e4));
      if (uVar36 < 0x21) {
        uVar26 = 0;
        do {
          iVar30 = 0;
          uVar28 = uVar26 + 1;
          uVar33 = 0xffffffffffffffff;
          do {
            cVar31 = '\0';
            lVar24 = (ulong)(uVar1 * iVar30 + uVar26) * 4;
            fVar56 = *(float *)((long)pvVar22 + lVar24);
            if (0.0 <= fVar56) {
              lVar7 = (ulong)(uVar28 + uVar1 * iVar30) * 4;
              fVar37 = *(float *)((long)pvVar22 + lVar7);
              if (0.0 <= fVar37) {
                fVar43 = *(float *)(this + 200);
                fVar48 = fVar56;
                if (fVar56 <= fVar37) {
                  fVar48 = fVar37;
                }
                fVar48 = fVar43 + fVar52 * (float)(int)((fVar48 - fVar43) / fVar52);
                if (fVar48 < fVar43) {
                  cVar31 = '\0';
                }
                else {
                  fVar43 = (*(float *)(lVar23 + lVar24) + *(float *)(lVar23 + lVar7)) * 0.5;
                  if (((fVar43 <= 0.5) || (0.0 <= fVar56 - fVar48)) || (fVar37 - fVar48 <= 0.0)) {
                    cVar31 = -(0.5 < fVar43 && (fVar37 - fVar48 < 0.0 && 0.0 < fVar56 - fVar48));
                  }
                  else {
                    cVar31 = '\x01';
                  }
                }
              }
            }
            uVar33 = uVar33 + 1;
            *(char *)(*(long *)(in_x8 + 8) + (ulong)(uVar26 + *(int *)in_x8 * (int)uVar33)) = cVar31
            ;
            iVar30 = iVar30 + 1;
            uVar35 = *(uint *)(in_x8 + 4);
          } while (uVar33 < uVar35);
          uVar36 = *(uint *)in_x8;
          uVar26 = uVar28;
        } while (uVar28 < uVar36);
      }
      else {
        uVar36 = 0;
      }
      if (uVar35 != 0) {
        uVar33 = 1;
        uVar26 = 0;
        do {
          if ((int)uVar33 != 0) {
            uVar34 = 0;
            do {
              cVar31 = '\0';
              uVar2 = uVar34 + 1;
              iVar30 = (int)uVar34;
              lVar24 = (ulong)(uVar26 + uVar1 * iVar30) * 4;
              fVar56 = *(float *)((long)pvVar22 + lVar24);
              if (0.0 <= fVar56) {
                lVar7 = (ulong)(uVar26 + uVar1 * (int)uVar2) * 4;
                fVar37 = *(float *)((long)pvVar22 + lVar7);
                if (0.0 <= fVar37) {
                  fVar43 = *(float *)(this + 200);
                  fVar48 = fVar56;
                  if (fVar56 <= fVar37) {
                    fVar48 = fVar37;
                  }
                  fVar48 = fVar43 + fVar52 * (float)(int)((fVar48 - fVar43) / fVar52);
                  if (fVar48 < fVar43) {
                    cVar31 = '\0';
                  }
                  else {
                    fVar43 = (*(float *)(lVar23 + lVar24) + *(float *)(lVar23 + lVar7)) * 0.5;
                    if (((fVar43 <= 0.5) || (0.0 <= fVar56 - fVar48)) || (fVar37 - fVar48 <= 0.0)) {
                      cVar31 = -(0.5 < fVar43 && (fVar37 - fVar48 < 0.0 && 0.0 < fVar56 - fVar48));
                    }
                    else {
                      cVar31 = '\x01';
                    }
                  }
                }
              }
              *(char *)(*(long *)(in_x8 + 0x20) + (ulong)(iVar30 + iVar30 * *(int *)in_x8 + uVar26))
                   = cVar31;
              uVar33 = (ulong)*(uint *)(in_x8 + 4);
              uVar34 = uVar2;
            } while (uVar2 < uVar33);
            uVar36 = *(uint *)in_x8;
          }
          bVar21 = uVar26 < uVar36;
          uVar26 = uVar26 + 1;
        } while (bVar21);
      }
      CellEdgeCliffCrossingArray::fixImpossibleCells(in_x8,false);
      operator_delete__(pvVar22);
      pvVar22 = local_88;
      local_88 = (void *)0x0;
      if (pvVar22 != (void *)0x0) {
        operator_delete__(pvVar22);
      }
      pvVar22 = local_b0;
      local_b0 = (void *)0x0;
      if (pvVar22 != (void *)0x0) {
        operator_delete__(pvVar22);
      }
      return;
    }
  } while( true );
}



// ===== CellEdgeCliffCrossingArray::fixImpossibleCells  @ 0x1014b51d4 =====

/* CellEdgeCliffCrossingArray::fixImpossibleCells(bool) */

void __thiscall
CellEdgeCliffCrossingArray::fixImpossibleCells(CellEdgeCliffCrossingArray *this,bool param_1)

{
  uint uVar1;
  uint uVar2;
  byte *pbVar3;
  byte *pbVar4;
  byte *pbVar5;
  byte *pbVar6;
  uint uVar7;
  int iVar8;
  int iVar9;
  bool bVar10;
  byte *pbVar11;
  byte bVar12;
  uint uVar13;
  uint uVar14;
  uint uVar15;
  
LAB_1014b5210:
  if (param_1 != false) {
    uVar14 = *(uint *)this;
    iVar8 = *(int *)(this + 4);
    **(undefined1 **)(this + 8) = 0;
    **(undefined1 **)(this + 0x20) = 0;
    *(undefined1 *)(*(long *)(this + 8) + (ulong)(uVar14 - 1)) = 0;
    *(undefined1 *)(*(long *)(this + 0x20) + (ulong)uVar14) = 0;
    *(undefined1 *)(*(long *)(this + 8) + (ulong)(uint)(*(int *)this * iVar8)) = 0;
    iVar9 = iVar8 + -1;
    *(undefined1 *)(*(long *)(this + 0x20) + (ulong)(uint)(iVar9 + iVar9 * *(int *)this)) = 0;
    *(undefined1 *)(*(long *)(this + 8) + (ulong)((uVar14 - 1) + *(int *)this * iVar8)) = 0;
    *(undefined1 *)(*(long *)(this + 0x20) + (ulong)(iVar9 + iVar9 * *(int *)this + uVar14)) = 0;
  }
  uVar14 = *(uint *)this;
  uVar15 = *(uint *)(this + 4);
  if (uVar15 == 0 || uVar14 == 0) {
    return;
  }
  uVar13 = 0;
LAB_1014b52b0:
  uVar1 = uVar13 + 1;
  if (uVar14 != 0) {
    uVar15 = 0;
LAB_1014b5388:
    iVar8 = uVar13 + uVar14 * uVar13;
    pbVar3 = (byte *)(*(long *)(this + 0x20) + (ulong)(iVar8 + uVar15));
    uVar2 = uVar15 + 1;
    pbVar4 = (byte *)(*(long *)(this + 0x20) + (ulong)(iVar8 + uVar2));
    pbVar5 = (byte *)(*(long *)(this + 8) + (ulong)(uVar14 * uVar13 + uVar15));
    pbVar6 = (byte *)(*(long *)(this + 8) + (ulong)(uVar15 + uVar14 * uVar1));
    uVar14 = (uint)(*pbVar3 != 0);
    if (*pbVar4 != 0) {
      uVar14 = uVar14 + 1;
    }
    if (*pbVar5 != 0) {
      uVar14 = uVar14 + 1;
    }
    if (*pbVar6 != 0) {
      uVar14 = uVar14 + 1;
    }
    if (uVar15 != 0) {
      do {
        if (uVar14 < 3) {
          uVar7 = (*pbVar3 & 3) << 6 | (*pbVar4 & 3) << 4 | (*pbVar5 & 3) << 2 | *pbVar6 & 3;
          switch(uVar7) {
          case 0:
          case 1:
          case 3:
          case 4:
          case 5:
          case 0xc:
          case 0xf:
          case 0x10:
          case 0x11:
          case 0x1c:
          case 0x30:
          case 0x33:
          case 0x34:
          case 0x40:
          case 0x43:
          case 0x44:
          case 0x50:
            goto switchD_1014b5444_caseD_0;
          case 2:
          case 6:
          case 7:
          case 8:
          case 9:
          case 10:
          case 0xb:
          case 0xd:
          case 0xe:
          case 0x12:
          case 0x13:
          case 0x14:
          case 0x15:
          case 0x16:
          case 0x17:
          case 0x18:
          case 0x19:
          case 0x1a:
          case 0x1b:
          case 0x1d:
          case 0x1e:
          case 0x1f:
          case 0x20:
          case 0x21:
          case 0x22:
          case 0x23:
          case 0x24:
          case 0x25:
          case 0x26:
          case 0x27:
          case 0x28:
          case 0x29:
          case 0x2a:
          case 0x2b:
          case 0x2c:
          case 0x2d:
          case 0x2e:
          case 0x2f:
          case 0x31:
          case 0x32:
          case 0x35:
          case 0x36:
          case 0x37:
          case 0x38:
          case 0x39:
          case 0x3a:
          case 0x3b:
          case 0x3c:
          case 0x3d:
          case 0x3e:
          case 0x3f:
          case 0x41:
          case 0x42:
          case 0x45:
          case 0x46:
          case 0x47:
          case 0x48:
          case 0x49:
          case 0x4a:
          case 0x4b:
          case 0x4c:
          case 0x4d:
          case 0x4e:
          case 0x4f:
            break;
          default:
            uVar7 = uVar7 - 0xc0;
            if (uVar7 < 0x31 && (1L << ((ulong)uVar7 & 0x3f) & 0x1000000001003U) != 0)
            goto switchD_1014b5444_caseD_0;
          }
        }
        pbVar11 = pbVar3;
        if ((((*pbVar3 == 0) && (pbVar11 = pbVar5, *pbVar5 == 0 || uVar13 == 0)) &&
            ((*pbVar4 == 0 || (pbVar11 = pbVar4, *(int *)this - 1U <= uVar15)))) &&
           ((*pbVar6 == 0 || (pbVar11 = pbVar6, *(int *)(this + 4) - 1U <= uVar13))))
        goto joined_r0x0001014b520c;
        *pbVar11 = 0;
        uVar14 = uVar14 - 1;
      } while( true );
    }
    do {
      if (uVar14 < 3) {
        bVar12 = *pbVar5;
        uVar15 = (*pbVar3 & 3) << 6 | (*pbVar4 & 3) << 4 | (bVar12 & 3) << 2 | *pbVar6 & 3;
        switch(uVar15) {
        case 0:
        case 1:
        case 3:
        case 4:
        case 5:
        case 0xc:
        case 0xf:
        case 0x10:
        case 0x11:
        case 0x1c:
        case 0x30:
        case 0x33:
        case 0x34:
        case 0x40:
        case 0x43:
        case 0x44:
        case 0x50:
          goto switchD_1014b5444_caseD_0;
        case 2:
        case 6:
        case 7:
        case 8:
        case 9:
        case 10:
        case 0xb:
        case 0xd:
        case 0xe:
        case 0x12:
        case 0x13:
        case 0x14:
        case 0x15:
        case 0x16:
        case 0x17:
        case 0x18:
        case 0x19:
        case 0x1a:
        case 0x1b:
        case 0x1d:
        case 0x1e:
        case 0x1f:
        case 0x20:
        case 0x21:
        case 0x22:
        case 0x23:
        case 0x24:
        case 0x25:
        case 0x26:
        case 0x27:
        case 0x28:
        case 0x29:
        case 0x2a:
        case 0x2b:
        case 0x2c:
        case 0x2d:
        case 0x2e:
        case 0x2f:
        case 0x31:
        case 0x32:
        case 0x35:
        case 0x36:
        case 0x37:
        case 0x38:
        case 0x39:
        case 0x3a:
        case 0x3b:
        case 0x3c:
        case 0x3d:
        case 0x3e:
        case 0x3f:
        case 0x41:
        case 0x42:
        case 0x45:
        case 0x46:
        case 0x47:
        case 0x48:
        case 0x49:
        case 0x4a:
        case 0x4b:
        case 0x4c:
        case 0x4d:
        case 0x4e:
        case 0x4f:
          break;
        default:
          uVar15 = uVar15 - 0xc0;
          if (uVar15 < 0x31 && (1L << ((ulong)uVar15 & 0x3f) & 0x1000000001003U) != 0)
          goto switchD_1014b5444_caseD_0;
        }
      }
      else {
        bVar12 = *pbVar5;
      }
      pbVar11 = pbVar5;
      if (((bVar12 == 0 || uVar13 == 0) && ((*pbVar4 == 0 || (pbVar11 = pbVar4, *(int *)this == 1)))
          ) && ((*pbVar6 == 0 || (pbVar11 = pbVar6, *(int *)(this + 4) - 1U <= uVar13))))
      goto joined_r0x0001014b520c;
      *pbVar11 = 0;
      uVar14 = uVar14 - 1;
    } while( true );
  }
  goto LAB_1014b52a4;
switchD_1014b5444_caseD_0:
  uVar14 = *(uint *)this;
  uVar15 = uVar2;
  if (uVar14 <= uVar2) goto LAB_1014b52a0;
  goto LAB_1014b5388;
LAB_1014b52a0:
  uVar15 = *(uint *)(this + 4);
LAB_1014b52a4:
  uVar13 = uVar1;
  if (uVar15 <= uVar1) {
    return;
  }
  goto LAB_1014b52b0;
joined_r0x0001014b520c:
  bVar10 = param_1 != false;
  param_1 = true;
  if (bVar10) {
                    /* WARNING: Subroutine does not return */
    Logging::logAndAbortOrThrow
              ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Map/CliffGenerator.cpp"
               ,0x8d,9,
               "Unable to remove excess cliff cell edge crossings l/r/t/b = %d/%d/%d/%d; count=%u; cell x/y=%u,%u"
              );
  }
  goto LAB_1014b5210;
}



// ===== CellEdgeCliffCrossingArray::clearCell  @ 0x1014b54fc =====

/* CellEdgeCliffCrossingArray::clearCell(unsigned int, unsigned int) */

void __thiscall
CellEdgeCliffCrossingArray::clearCell(CellEdgeCliffCrossingArray *this,uint param_1,uint param_2)

{
  *(undefined1 *)(*(long *)(this + 0x20) + (ulong)(param_2 + param_2 * *(int *)this + param_1)) = 0;
  *(undefined1 *)(*(long *)(this + 0x20) + (ulong)(param_1 + param_2 + param_2 * *(int *)this + 1))
       = 0;
  *(undefined1 *)(*(long *)(this + 8) + (ulong)(param_1 + *(int *)this * param_2)) = 0;
  *(undefined1 *)(*(long *)(this + 8) + (ulong)(*(int *)this + *(int *)this * param_2 + param_1)) =
       0;
  return;
}



// ===== CellEdgeCliffCrossingArray::getCellCliffCrossing  @ 0x1014b5550 =====

/* CellEdgeCliffCrossingArray::getCellCliffCrossing(unsigned int, unsigned int) */

byte __thiscall
CellEdgeCliffCrossingArray::getCellCliffCrossing
          (CellEdgeCliffCrossingArray *this,uint param_1,uint param_2)

{
  uint uVar1;
  uint uVar2;
  int iVar3;
  
  iVar3 = *(int *)this * param_2;
  uVar1 = param_2 + param_1 + iVar3;
  uVar2 = iVar3 + param_1;
  return *(char *)(*(long *)(this + 0x20) + (ulong)uVar1) << 6 |
         (*(byte *)(*(long *)(this + 0x20) + (ulong)(uVar1 + 1)) & 3) << 4 |
         (*(byte *)(*(long *)(this + 8) + (ulong)uVar2) & 3) << 2 |
         *(byte *)(*(long *)(this + 8) + (ulong)(uVar2 + *(int *)this)) & 3;
}



// ===== CellCliffCrossing::toMaybeCliffOrientation  @ 0x1014b5030 =====

/* CellCliffCrossing::toMaybeCliffOrientation() */

ulong __thiscall CellCliffCrossing::toMaybeCliffOrientation(CellCliffCrossing *this)

{
  uint uVar1;
  ulong uVar2;
  ulong uVar3;
  
  uVar1 = *(uint *)this;
  uVar2 = (ulong)uVar1;
  if ((int)uVar1 < 0xc0) {
    uVar3 = uVar2;
    switch(uVar2) {
    case 0:
switchD_1014b505c_caseD_0:
      return uVar3 | uVar2;
    case 1:
      return 0x1100000002;
    case 3:
      return 0x1200000002;
    case 4:
      return 0x1000000002;
    case 5:
      return 0x100000002;
    case 0xc:
      return 0x1300000002;
    case 0xf:
      return 0x300000002;
    case 0x10:
      return 0xe00000002;
    case 0x11:
      return 0x600000002;
    case 0x1c:
      return 0xa00000002;
    case 0x30:
      return 0xd00000002;
    case 0x33:
      return 0xb00000002;
    case 0x34:
      return 0x500000002;
    case 0x40:
      return 0xf00000002;
    case 0x43:
      return 0x700000002;
    case 0x44:
      return 0x900000002;
    case 0x50:
      return 0x200000002;
    }
  }
  else if ((int)uVar1 < 0xcc) {
    if (uVar1 == 0xc0) {
      return 0xc00000002;
    }
    if (uVar1 == 0xc1) {
      return 0x800000002;
    }
  }
  else {
    if (uVar1 == 0xcc) {
      return 0x400000002;
    }
    if (uVar1 == 0xf0) {
      return 2;
    }
  }
  uVar2 = 0;
  uVar3 = 1;
  goto switchD_1014b505c_caseD_0;
}



// ===== MaybeCliffOrientation::value  @ 0x1014b4f10 =====

/* MaybeCliffOrientation::value() const */

MaybeCliffOrientation __thiscall MaybeCliffOrientation::value(MaybeCliffOrientation *this)

{
  int iVar1;
  RuntimeError *pRVar2;
  string asStack_48 [24];
  
  iVar1 = *(int *)this;
  if (iVar1 == 2) {
    return this[4];
  }
  if (iVar1 == 0) {
    pRVar2 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(pRVar2,"Can\'t turn \'no cliffs at all\' into cliff orientation");
  }
  else {
    if (iVar1 != 1) {
      pRVar2 = (RuntimeError *)___cxa_allocate_exception(0x10);
      ssprintf("Bad MaybeCliffOrientation mode: %u",asStack_48);
      RuntimeError::RuntimeError(pRVar2,asStack_48);
                    /* WARNING: Subroutine does not return */
      ___cxa_throw(pRVar2,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
    }
    pRVar2 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(pRVar2,"Impossible cliff configuration");
  }
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(pRVar2,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



// ===== MapGenSettingsHelpers::CliffPlacementSettings::getModifiedElevationInterval  @ 0x1014b5f14 =====

/* MapGenSettingsHelpers::CliffPlacementSettings::getModifiedElevationInterval(MapGenSettingsHelpers::FrequencySizeRichness
   const&) const */

float __thiscall
MapGenSettingsHelpers::CliffPlacementSettings::getModifiedElevationInterval
          (CliffPlacementSettings *this,FrequencySizeRichness *param_1)

{
  float fVar1;
  
  fVar1 = 0.0;
  if (*(float *)param_1 != 0.0) {
    fVar1 = *(float *)param_1;
  }
  return *(float *)(this + 0x3c) / fVar1;
}



// ===== MapGenSettingsHelpers::CliffPlacementSettings::getModifiedRichness  @ 0x1014b8b3c =====

/* MapGenSettingsHelpers::CliffPlacementSettings::getModifiedRichness(MapGenSettingsHelpers::FrequencySizeRichness
   const&) const */

float __thiscall
MapGenSettingsHelpers::CliffPlacementSettings::getModifiedRichness
          (CliffPlacementSettings *this,FrequencySizeRichness *param_1)

{
  float fVar1;
  
  fVar1 = 0.0;
  if (*(float *)(param_1 + 4) != 0.0) {
    fVar1 = *(float *)(param_1 + 4);
  }
  return *(float *)(this + 0x44) * fVar1;
}



// ===== CompiledMapGenSettings::prepareCliffProgramBuilder  @ 0x1014bada8 =====

/* CompiledMapGenSettings::prepareCliffProgramBuilder(NoiseExpressionCompilationContext&) */

void CompiledMapGenSettings::prepareCliffProgramBuilder(NoiseExpressionCompilationContext *param_1)

{
  ulong uVar1;
  code *pcVar2;
  long *plVar3;
  Variable *pVVar4;
  long *plVar5;
  void *pvVar6;
  undefined8 in_x1;
  undefined8 *in_x8;
  ulong uVar7;
  long lVar8;
  long *plVar9;
  long *plVar10;
  
  in_x8[1] = 0;
  *in_x8 = in_x1;
  *(undefined4 *)(in_x8 + 5) = 0;
  in_x8[2] = 0;
  in_x8[3] = 0;
  *(undefined4 *)(in_x8 + 4) = 0;
  in_x8[7] = 0;
  in_x8[6] = 0;
  in_x8[9] = 0;
  in_x8[8] = 0;
  in_x8[0xb] = 0;
  in_x8[10] = 0;
  in_x8[0xc] = 0;
  *(undefined4 *)(in_x8 + 0xd) = 0x3f800000;
  in_x8[0xf] = 0;
  in_x8[0xe] = 0;
  in_x8[0x11] = 0;
  in_x8[0x10] = 0;
  *(undefined4 *)(in_x8 + 0x12) = 0x3f800000;
  in_x8[0x14] = 0;
  in_x8[0x13] = 0;
  in_x8[0x16] = 0;
  in_x8[0x15] = 0;
  *(undefined4 *)(in_x8 + 0x17) = 0x3f800000;
  in_x8[0x19] = 0;
  in_x8[0x1a] = 0;
  in_x8[0x18] = 0;
  *(undefined4 *)(in_x8 + 0x1b) = 0x80000001;
  if (*(long *)(param_1 + 0xa8) != 0) {
    plVar3 = operator_new(0x20);
    plVar10 = plVar3 + 4;
    in_x8[1] = plVar3;
    in_x8[2] = plVar3;
    in_x8[3] = plVar10;
    pVVar4 = NoiseExpressionStorage::getOrCreate<NoiseExpressions::Variable,char_const(&)[16]>
                       (*(NoiseExpressionStorage **)(_global + 0xb0),"cliff_elevation");
    if (plVar3 < plVar10) {
      *plVar3 = (long)(param_1 + 0x1e0);
      plVar3[1] = (long)pVVar4;
      plVar9 = plVar3 + 2;
      in_x8[2] = plVar9;
      plVar5 = plVar3;
    }
    else {
      plVar5 = operator_new(0x40);
      plVar10 = plVar5 + 8;
      *plVar5 = (long)(param_1 + 0x1e0);
      plVar5[1] = (long)pVVar4;
      plVar9 = plVar5 + 2;
      in_x8[1] = plVar5;
      in_x8[2] = plVar9;
      in_x8[3] = plVar10;
      operator_delete(plVar3);
    }
    pVVar4 = NoiseExpressionStorage::getOrCreate<NoiseExpressions::Variable,char_const(&)[11]>
                       (*(NoiseExpressionStorage **)(_global + 0xb0),"cliffiness");
    if (plVar10 <= plVar9) {
      lVar8 = (long)plVar9 - (long)plVar5 >> 4;
      uVar1 = lVar8 + 1;
      if (uVar1 >> 0x3c != 0) {
        std::
        vector<std::pair<NoiseRegisterIndex*,NoiseExpression_const*>,std::allocator<std::pair<NoiseRegisterIndex*,NoiseExpression_const*>>>
        ::__throw_length_error_abi_v160006_();
                    /* WARNING: Does not return */
        pcVar2 = (code *)SoftwareBreakpoint(1,0x1014bafa8);
        (*pcVar2)();
      }
      uVar7 = (ulong)((long)plVar10 - (long)plVar5) >> 3;
      if (uVar7 <= uVar1) {
        uVar7 = uVar1;
      }
      if (0x7fffffffffffffef < (ulong)((long)plVar10 - (long)plVar5)) {
        uVar7 = 0xfffffffffffffff;
      }
      if (uVar7 >> 0x3c == 0) {
        pvVar6 = operator_new(uVar7 << 4);
        plVar10 = (long *)((long)pvVar6 + lVar8 * 0x10);
        *plVar10 = (long)(param_1 + 0x1e4);
        plVar10[1] = (long)pVVar4;
        plVar3 = plVar10;
        for (; plVar9 != plVar5; plVar9 = plVar9 + -2) {
          lVar8 = plVar9[-2];
          plVar3[-1] = plVar9[-1];
          plVar3[-2] = lVar8;
          plVar3 = plVar3 + -2;
        }
        in_x8[1] = plVar3;
        in_x8[2] = plVar10 + 2;
        in_x8[3] = (void *)((long)pvVar6 + uVar7 * 0x10);
        operator_delete(plVar5);
        return;
      }
                    /* WARNING: Subroutine does not return */
      std::__throw_bad_array_new_length_abi_v160006_();
    }
    *plVar9 = (long)(param_1 + 0x1e4);
    plVar9[1] = (long)pVVar4;
    in_x8[2] = plVar9 + 2;
  }
  return;
}



// ===== CliffCraterPlacer::tryToPlaceCliffAsCrater  @ 0x1014b48d0 =====

/* CliffCraterPlacer::tryToPlaceCliffAsCrater(Surface&, MapPosition const&, CliffPrototype const&,
   CraterPlacementDefinition const&, RandomGenerator&) */

undefined8 __thiscall
CliffCraterPlacer::tryToPlaceCliffAsCrater
          (CliffCraterPlacer *this,Surface *param_1,MapPosition *param_2,CliffPrototype *param_3,
          CraterPlacementDefinition *param_4,RandomGenerator *param_5)

{
  long lVar1;
  void **ppvVar2;
  MapPosition *local_1e0;
  undefined8 uStack_1d8;
  void *local_1d0;
  undefined2 local_1c8;
  undefined1 local_1c6;
  undefined8 local_1c0;
  undefined8 local_1b8;
  undefined8 uStack_1b0;
  undefined8 local_1a8;
  undefined8 uStack_1a0;
  undefined8 local_198;
  undefined8 uStack_190;
  undefined8 local_188;
  undefined8 local_180;
  undefined8 uStack_178;
  undefined8 local_170;
  undefined4 uStack_168;
  undefined3 uStack_164;
  undefined1 local_161;
  undefined8 local_160;
  undefined1 local_158;
  undefined8 local_150;
  undefined8 uStack_148;
  void *local_140;
  void *local_138;
  void **local_80;
  void **ppvStack_78;
  long local_70;
  
  local_70 = *(long *)PTR____stack_chk_guard_102d481b8;
  calculateCliffSegments(this,param_1,param_2,param_3,param_4,param_5);
  ppvVar2 = local_80;
  if ((ulong)*(uint *)param_3 <=
      (ulong)(((long)ppvStack_78 - (long)local_80 >> 2) * -0x5555555555555555) &&
      local_80 != ppvStack_78) {
    do {
      uStack_1d8 = *(undefined8 *)(this + 0xb8);
      local_1d0 = *ppvVar2;
      local_1c8 = 0x300;
      local_1c6 = CorePrototypes::normalQuality;
      local_1c0 = 0;
      uStack_1b0 = 0x7fffffff7fffffff;
      local_1b8 = 0x7fffffff7fffffff;
      local_1a8 = 0;
      uStack_1a0 = 0;
      uStack_190 = 0x7fffffff7fffffff;
      local_198 = 0x7fffffff7fffffff;
      local_180 = 0;
      uStack_178 = 0;
      local_188 = 0;
      uStack_164 = 0;
      uStack_168 = 0;
      local_170 = 0x7fffffff7fffffff;
      local_160 = 0x10000ff00000000;
      local_158 = 0;
      local_150 = 0;
      uStack_148 = 0;
      local_161 = *(undefined1 *)(ppvVar2 + 1);
      local_1e0 = param_2;
      lVar1 = (**(code **)(*(long *)param_2 + 0x6b0))(param_2,&local_1e0);
      if (lVar1 != 0) {
        Surface::addEntity((Surface *)this,lVar1,0,0,0,0,1);
      }
      ppvVar2 = (void **)((long)ppvVar2 + 0xc);
    } while (ppvVar2 != ppvStack_78);
  }
  if ((local_80 != &local_140) && (local_140 != (void *)0x0)) {
    local_138 = local_140;
    operator_delete(local_140);
  }
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_70) {
    return 1;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}



// ===== CliffCraterPlacer::calculateCliffSegments  @ 0x1014b4a98 =====

/* CliffCraterPlacer::calculateCliffSegments(Surface const&, MapPosition const&, CliffPrototype
   const&, CraterPlacementDefinition const&, RandomGenerator&) */

void __thiscall
CliffCraterPlacer::calculateCliffSegments
          (CliffCraterPlacer *this,Surface *param_1,MapPosition *param_2,CliffPrototype *param_3,
          CraterPlacementDefinition *param_4,RandomGenerator *param_5)

{
  float *pfVar1;
  float *pfVar2;
  uint uVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  undefined8 uVar6;
  ulong uVar7;
  bool bVar8;
  SmallVector<Pair<MapPosition,CliffOrientation>,16ul,0ul> *in_x8;
  float fVar9;
  byte bVar10;
  byte bVar13;
  byte bVar14;
  byte bVar15;
  byte bVar16;
  byte bVar17;
  byte bVar18;
  undefined8 uVar11;
  ulong uVar12;
  byte bVar19;
  undefined8 uVar20;
  undefined8 local_b0;
  undefined8 local_a8;
  undefined8 local_a0;
  long local_98;
  
  local_98 = *(long *)PTR____stack_chk_guard_102d481b8;
  *(SmallVector<Pair<MapPosition,CliffOrientation>,16ul,0ul> **)(in_x8 + 0xc0) = in_x8;
  *(SmallVector<Pair<MapPosition,CliffOrientation>,16ul,0ul> **)(in_x8 + 200) = in_x8;
  uVar7 = DAT_1029732c0;
  uVar6 = DAT_1029732b8;
  uVar5 = DAT_1029732b0;
  uVar4 = DAT_1029732a8;
  local_a0 = 0xb030a0209010800;
  pfVar1 = *(float **)(param_3 + 8);
  pfVar2 = *(float **)(param_3 + 0x10);
  do {
    if (pfVar1 == pfVar2) {
      if (*(long *)PTR____stack_chk_guard_102d481b8 == local_98) {
        return;
      }
                    /* WARNING: Subroutine does not return */
      ___stack_chk_fail();
    }
    local_b0 = CONCAT44(*(int *)(param_1 + 4) + ((int)*(short *)((long)pfVar1 + 6) >> 2),
                        *(int *)param_1 + ((int)*(short *)(pfVar1 + 1) >> 2));
    local_a8 = (**(code **)(*(long *)param_2 + 0x120))(param_2,&local_b0,0x10);
    fVar9 = *pfVar1;
    bVar8 = false;
    if ((0.0 <= fVar9) && (bVar8 = false, !NAN(fVar9))) {
      bVar8 = fVar9 < 1.0;
    }
    if (!bVar8) {
      fVar9 = (fVar9 - (float)(int)fVar9) + 1.0;
      fVar9 = fVar9 - (float)(int)fVar9;
    }
    local_b0 = CONCAT71(local_b0._1_7_,
                        *(undefined1 *)((long)&local_a0 + (ulong)(uint)(int)(fVar9 * 8.0)));
    fVar9 = *(float *)(param_3 + 4);
    if (0.0 < fVar9) {
      if (fVar9 < 1.0) {
        uVar11 = *(undefined8 *)param_4;
        uVar20 = NEON_ushl(uVar11,uVar4,4);
        uVar20 = NEON_ushl(CONCAT17((byte)((ulong)uVar20 >> 0x38) ^ (byte)((ulong)uVar11 >> 0x38),
                                    CONCAT16((byte)((ulong)uVar20 >> 0x30) ^
                                             (byte)((ulong)uVar11 >> 0x30),
                                             CONCAT15((byte)((ulong)uVar20 >> 0x28) ^
                                                      (byte)((ulong)uVar11 >> 0x28),
                                                      CONCAT14((byte)((ulong)uVar20 >> 0x20) ^
                                                               (byte)((ulong)uVar11 >> 0x20),
                                                               CONCAT13((byte)((ulong)uVar20 >> 0x18
                                                                              ) ^ (byte)((ulong)
                                                  uVar11 >> 0x18),
                                                  CONCAT12((byte)((ulong)uVar20 >> 0x10) ^
                                                           (byte)((ulong)uVar11 >> 0x10),
                                                           CONCAT11((byte)((ulong)uVar20 >> 8) ^
                                                                    (byte)((ulong)uVar11 >> 8),
                                                                    (byte)uVar20 ^ (byte)uVar11)))))
                                            )),uVar5,4);
        uVar12 = NEON_ushl(uVar11,uVar6,4);
        uVar12 = uVar12 & uVar7;
        bVar10 = (byte)uVar20 | (byte)uVar12;
        bVar13 = (byte)((ulong)uVar20 >> 8) | (byte)(uVar12 >> 8);
        bVar14 = (byte)((ulong)uVar20 >> 0x10) | (byte)(uVar12 >> 0x10);
        bVar15 = (byte)((ulong)uVar20 >> 0x18) | (byte)(uVar12 >> 0x18);
        bVar16 = (byte)((ulong)uVar20 >> 0x20) | (byte)(uVar12 >> 0x20);
        bVar17 = (byte)((ulong)uVar20 >> 0x28) | (byte)(uVar12 >> 0x28);
        bVar18 = (byte)((ulong)uVar20 >> 0x30) | (byte)(uVar12 >> 0x30);
        bVar19 = (byte)((ulong)uVar20 >> 0x38) | (byte)(uVar12 >> 0x38);
        *(ulong *)param_4 =
             CONCAT17(bVar19,CONCAT16(bVar18,CONCAT15(bVar17,CONCAT14(bVar16,CONCAT13(bVar15,
                                                  CONCAT12(bVar14,CONCAT11(bVar13,bVar10)))))));
        uVar3 = *(uint *)(param_4 + 8);
        uVar3 = (uVar3 & 0x7ff0) << 0x11 | (uVar3 ^ uVar3 << 3) >> 0xb;
        *(uint *)(param_4 + 8) = uVar3;
        if ((double)fVar9 <=
            (double)(CONCAT13(bVar19 ^ bVar15,
                              CONCAT12(bVar18 ^ bVar14,CONCAT11(bVar17 ^ bVar13,bVar16 ^ bVar10))) ^
                    uVar3) * 2.3283064365386963e-10) goto LAB_1014b4b40;
      }
      uVar12 = Surface::wouldCollide((Surface *)this,param_2,&local_a8);
      if ((uVar12 & 1) == 0) {
        SmallVector<Pair<MapPosition,CliffOrientation>,16ul,0ul>::
        emplaceBackInternal<MapPosition&,CliffOrientation&>
                  (in_x8,(MapPosition *)&local_a8,(CliffOrientation *)&local_b0);
      }
    }
LAB_1014b4b40:
    pfVar1 = pfVar1 + 2;
  } while( true );
}



// ===== Cliff::getNeighborPosition  @ 0x1007135e0 =====

/* Cliff::getNeighborPosition(CellSide) const */

undefined8 __thiscall Cliff::getNeighborPosition(Cliff *this,undefined4 param_2)

{
  bool bVar1;
  bool bVar2;
  undefined1 *puVar3;
  double dVar4;
  
  switch(param_2) {
  case 0:
    puVar3 = (undefined1 *)(*(double *)(*(long *)(this + 0x48) + 0xb38) * 256.0);
    bVar1 = true;
    if ((!NAN((double)puVar3)) && (bVar1 = false, !NAN((double)puVar3))) {
      bVar1 = (double)puVar3 == INFINITY;
    }
    bVar2 = true;
    if ((!bVar1) && (bVar2 = false, !NAN((double)puVar3))) {
      bVar2 = (double)puVar3 == -INFINITY;
    }
    if (!bVar2) {
      if ((double)puVar3 <= -2147483648.0) {
        puVar3 = &DAT_c1e0000000000000;
      }
      dVar4 = (double)NEON_fminnm(puVar3,0x41dfffffffc00000);
      return CONCAT44(*(int *)(this + 0x54) - (int)dVar4,*(undefined4 *)(this + 0x50));
    }
    break;
  case 1:
    return CONCAT44(*(undefined4 *)(this + 0x54),
                    *(int *)(this + 0x50) +
                    (int)(*(double *)(*(long *)(this + 0x48) + 0xb30) * 256.0));
  case 2:
    return CONCAT44(*(int *)(this + 0x54) +
                    (int)(*(double *)(*(long *)(this + 0x48) + 0xb38) * 256.0),
                    *(undefined4 *)(this + 0x50));
  case 3:
    puVar3 = (undefined1 *)(*(double *)(*(long *)(this + 0x48) + 0xb30) * 256.0);
    bVar1 = true;
    if ((!NAN((double)puVar3)) && (bVar1 = false, !NAN((double)puVar3))) {
      bVar1 = (double)puVar3 == INFINITY;
    }
    bVar2 = true;
    if ((!bVar1) && (bVar2 = false, !NAN((double)puVar3))) {
      bVar2 = (double)puVar3 == -INFINITY;
    }
    if (!bVar2) {
      if ((double)puVar3 <= -2147483648.0) {
        puVar3 = &DAT_c1e0000000000000;
      }
      dVar4 = (double)NEON_fminnm(puVar3,0x41dfffffffc00000);
      return CONCAT44(*(undefined4 *)(this + 0x54),*(int *)(this + 0x50) - (int)dVar4);
    }
    break;
  default:
                    /* WARNING: Subroutine does not return */
    Logging::logEnumAndAbortOrThrow<CellSide>
              ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Entity/Cliff.cpp"
               ,0x1f2,9);
  }
                    /* WARNING: Subroutine does not return */
  Logging::logAndAbortOrThrow
            ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Util/FixedPointNumber.hpp"
             ,0x1f,9,"double value not in range for fixed point number: %f");
}



// ===== Cliff::neighborSidesForOrientation  @ 0x100712dc8 =====

/* Cliff::neighborSidesForOrientation(CliffOrientation) */

void __thiscall
Cliff::neighborSidesForOrientation(SmallVector<CellSide,2ul,0ul> *param_1,undefined4 param_2)

{
  CellSide local_22;
  CellSide local_21;
  
  switch(param_2) {
  case 0:
  case 2:
    local_21 = 3;
    local_22 = 1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x18) = param_1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x20) = param_1;
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_21);
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_22);
    break;
  case 1:
  case 3:
    local_21 = 0;
    local_22 = 2;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x18) = param_1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x20) = param_1;
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_21);
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_22);
    break;
  case 4:
  case 9:
    local_21 = 3;
    local_22 = 0;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x18) = param_1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x20) = param_1;
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_21);
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_22);
    break;
  case 5:
  case 10:
    local_21 = 1;
    local_22 = 0;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x18) = param_1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x20) = param_1;
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_21);
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_22);
    break;
  case 6:
  case 0xb:
    local_21 = 1;
    local_22 = 2;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x18) = param_1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x20) = param_1;
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_21);
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_22);
    break;
  case 7:
  case 8:
    local_21 = 3;
    local_22 = 2;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x18) = param_1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x20) = param_1;
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_21);
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_22);
    break;
  case 0xc:
  case 0xf:
    local_21 = 3;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x18) = param_1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x20) = param_1;
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_21);
    break;
  case 0xd:
  case 0xe:
    local_21 = 1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x18) = param_1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x20) = param_1;
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_21);
    break;
  case 0x10:
  case 0x13:
    local_21 = 0;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x18) = param_1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x20) = param_1;
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_21);
    break;
  case 0x11:
  case 0x12:
    local_21 = 2;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x18) = param_1;
    *(SmallVector<CellSide,2ul,0ul> **)(param_1 + 0x20) = param_1;
    SmallVector<CellSide,2ul,0ul>::emplaceBackInternal<CellSide_const&>(param_1,&local_21);
    break;
  default:
                    /* WARNING: Subroutine does not return */
    Logging::logEnumAndAbortOrThrow<CliffOrientation>
              ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Entity/Cliff.cpp"
               ,0x218,9);
  }
  return;
}



// ===== CliffPrototype::getOrientationInfo  @ 0x100712604 =====

/* CliffPrototype::getOrientationInfo(CliffOrientation) const */

CliffPrototype * __thiscall
CliffPrototype::getOrientationInfo(CliffPrototype *this,undefined4 param_2)

{
  switch(param_2) {
  case 0:
    return this + 0x590;
  case 1:
    return this + 0x5d8;
  case 2:
    return this + 0x620;
  case 3:
    return this + 0x668;
  case 4:
    return this + 0x6b0;
  case 5:
    return this + 0x6f8;
  case 6:
    return this + 0x740;
  case 7:
    return this + 0x788;
  case 8:
    return this + 2000;
  case 9:
    return this + 0x818;
  case 10:
    return this + 0x860;
  case 0xb:
    return this + 0x8a8;
  case 0xc:
    return this + 0x8f0;
  case 0xd:
    return this + 0x938;
  case 0xe:
    return this + 0xa10;
  case 0xf:
    return this + 0xa58;
  case 0x10:
    return this + 0x980;
  case 0x11:
    return this + 0x9c8;
  case 0x12:
    return this + 0xaa0;
  case 0x13:
    return this + 0xae8;
  default:
                    /* WARNING: Subroutine does not return */
    Logging::logAndAbortOrThrow
              ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Entity/CliffPrototype.cpp"
               ,0xd1,9,"Invalid cliff orientation: %u");
  }
}



