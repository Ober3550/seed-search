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



// ===== MapGenerator::countFixedNeighborsOfKind  @ 0x1014f6cf4 =====

/* MapGenerator::countFixedNeighborsOfKind(TileProxy&, TilePosition, ID<TilePrototype, unsigned
   short>) */

int MapGenerator::countFixedNeighborsOfKind(long *param_1,undefined8 param_2,short param_3)

{
  long *plVar1;
  uint uVar2;
  uint uVar3;
  short *psVar4;
  int iVar5;
  int iVar6;
  long lVar7;
  int iVar8;
  ulong uVar9;
  int *piVar10;
  long lVar11;
  ulong uVar12;
  
  iVar8 = 0;
  lVar7 = *param_1;
  lVar11 = param_1[1];
  uVar12 = (ulong)*(uint *)(param_1 + 2);
  uVar9 = (ulong)*(uint *)((long)param_1 + 0x14);
  piVar10 = &neighborCoords;
  do {
    uVar2 = *piVar10 + (int)param_2;
    uVar3 = piVar10[1] + (int)((ulong)param_2 >> 0x20);
    iVar5 = (int)uVar2 >> 5;
    iVar6 = (int)uVar3 >> 5;
    if ((int)uVar12 == iVar5 && (int)uVar9 == iVar6) {
LAB_1014f6de0:
      psVar4 = (short *)(lVar11 + (ulong)(uVar2 & 0x1f) * 0x60 + (ulong)(uVar3 & 0x1f) * 3);
      if ((psVar4 != (short *)0x0) && (*psVar4 == param_3)) {
        iVar8 = iVar8 + 1;
      }
    }
    else {
      if ((iVar5 < -*(int *)(lVar7 + 0x24)) ||
         (iVar5 = *(int *)(lVar7 + 0x24) + iVar5, *(int *)(lVar7 + 0x20) <= iVar5)) {
LAB_1014f6d28:
        param_1[1] = 0;
      }
      else {
        plVar1 = (long *)(*(long *)(lVar7 + 0x18) + (long)iVar5 * 0x10);
        if (plVar1 == (long *)0x0) goto LAB_1014f6d28;
        lVar11 = *(long *)(lVar7 + 0x18) + (long)iVar5 * 0x10;
        iVar5 = *(int *)(lVar11 + 0xc);
        if (((iVar6 < -iVar5) || (iVar5 = iVar5 + iVar6, *(int *)(lVar11 + 8) <= iVar5)) ||
           (plVar1 = (long *)(*plVar1 + (long)iVar5 * 8), plVar1 == (long *)0x0))
        goto LAB_1014f6d28;
        lVar11 = *plVar1;
        param_1[1] = lVar11;
        if (lVar11 != 0) {
          uVar12 = *(ulong *)(lVar11 + 0xc48);
          param_1[2] = uVar12;
          uVar9 = uVar12 >> 0x20;
          goto LAB_1014f6de0;
        }
      }
      lVar11 = 0;
      param_1[2] = 0x7fffffff7fffffff;
      uVar9 = 0x7fffffff;
      uVar12 = 0x7fffffff;
    }
    piVar10 = piVar10 + 2;
    if (piVar10 == (int *)&TilePrototype::anyTileNeedsCorrection) {
      return iVar8;
    }
  } while( true );
}



// ===== MapGenerator::checkForWeakDiagonalSupport  @ 0x1014f6e0c =====

/* MapGenerator::checkForWeakDiagonalSupport(TileProxy&, TilePosition const&, bool, TilePrototype
   const&, std::vector<TilePosition, std::allocator<TilePosition> > const*) */

bool MapGenerator::checkForWeakDiagonalSupport
               (TileProxy *param_1,TilePosition *param_2,bool param_3,TilePrototype *param_4,
               vector *param_5)

{
  undefined *puVar1;
  ushort *puVar2;
  ulong uVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  int *piVar7;
  int *piVar8;
  long lVar9;
  
  puVar1 = PTR_indexToPrototype_102d4c598;
  uVar3 = (ulong)*(uint *)param_2;
  iVar4 = *(int *)(param_2 + 4);
  iVar5 = *(uint *)param_2 - 1;
  if (param_3) {
    if (param_5 == (vector *)0x0) {
LAB_1014f6ebc:
      puVar2 = (ushort *)TileProxy::getTile(param_1,CONCAT44(iVar4,iVar5));
      if (*(ushort *)(param_4 + 0x1a0) <
          *(ushort *)
           (*(long *)(*(long *)PTR_indexToPrototype_102d4c598 + (ulong)*puVar2 * 8) + 0x1a0)) {
        uVar3 = (ulong)*(uint *)param_2;
        iVar4 = *(int *)(param_2 + 4);
        goto LAB_1014f6ef0;
      }
    }
    else {
      piVar7 = *(int **)param_5;
      lVar9 = (long)*(int **)(param_5 + 8) - (long)piVar7;
      if (lVar9 == 0) {
LAB_1014f6eb4:
        if (piVar7 != *(int **)(param_5 + 8)) goto LAB_1014f6ebc;
      }
      else {
        lVar9 = (lVar9 >> 3) << 3;
        do {
          if (*piVar7 == iVar5 && piVar7[1] == iVar4) goto LAB_1014f6eb4;
          piVar7 = piVar7 + 2;
          lVar9 = lVar9 + -8;
        } while (lVar9 != 0);
      }
LAB_1014f6ef0:
      if (param_5 != (vector *)0x0) {
        piVar7 = *(int **)param_5;
        lVar9 = (long)*(int **)(param_5 + 8) - (long)piVar7;
        if (lVar9 != 0) {
          lVar9 = (lVar9 >> 3) << 3;
          while (*piVar7 != (int)uVar3 || piVar7[1] != iVar4 - 1U) {
            piVar7 = piVar7 + 2;
            lVar9 = lVar9 + -8;
            if (lVar9 == 0) {
              return true;
            }
          }
        }
        if (piVar7 == *(int **)(param_5 + 8)) {
          return true;
        }
      }
      puVar2 = (ushort *)TileProxy::getTile(param_1,uVar3 | (ulong)(iVar4 - 1U) << 0x20);
      if (*(ushort *)(param_4 + 0x1a0) <
          *(ushort *)
           (*(long *)(*(long *)PTR_indexToPrototype_102d4c598 + (ulong)*puVar2 * 8) + 0x1a0)) {
        return true;
      }
    }
    uVar3 = (ulong)*(uint *)param_2;
    iVar5 = *(int *)(param_2 + 4);
    iVar4 = *(uint *)param_2 + 1;
    if (param_5 == (vector *)0x0) {
LAB_1014f7094:
      puVar2 = (ushort *)TileProxy::getTile(param_1,CONCAT44(iVar5,iVar4));
      if (*(ushort *)
           (*(long *)(*(long *)PTR_indexToPrototype_102d4c598 + (ulong)*puVar2 * 8) + 0x1a0) <=
          *(ushort *)(param_4 + 0x1a0)) {
        return false;
      }
      uVar3 = (ulong)*(uint *)param_2;
      iVar5 = *(int *)(param_2 + 4);
    }
    else {
      piVar7 = *(int **)param_5;
      lVar9 = (long)*(int **)(param_5 + 8) - (long)piVar7;
      if (lVar9 == 0) {
LAB_1014f708c:
        if (piVar7 != *(int **)(param_5 + 8)) goto LAB_1014f7094;
      }
      else {
        lVar9 = (lVar9 >> 3) << 3;
        do {
          if (*piVar7 == iVar4 && piVar7[1] == iVar5) goto LAB_1014f708c;
          piVar7 = piVar7 + 2;
          lVar9 = lVar9 + -8;
        } while (lVar9 != 0);
      }
    }
    uVar6 = iVar5 + 1;
    if (param_5 == (vector *)0x0) goto LAB_1014f7194;
    piVar7 = *(int **)param_5;
    piVar8 = *(int **)(param_5 + 8);
    if ((long)piVar8 - (long)piVar7 != 0) {
      lVar9 = ((long)piVar8 - (long)piVar7 >> 3) << 3;
      while (*piVar7 != (int)uVar3 || piVar7[1] != uVar6) {
        piVar7 = piVar7 + 2;
        lVar9 = lVar9 + -8;
        if (lVar9 == 0) {
          return true;
        }
      }
    }
  }
  else {
    if (param_5 == (vector *)0x0) {
LAB_1014f6f34:
      puVar2 = (ushort *)TileProxy::getTile(param_1,CONCAT44(iVar4,iVar5));
      if (*(ushort *)(param_4 + 0x1a0) <
          *(ushort *)(*(long *)(*(long *)puVar1 + (ulong)*puVar2 * 8) + 0x1a0)) {
        uVar3 = (ulong)*(uint *)param_2;
        iVar4 = *(int *)(param_2 + 4);
        goto LAB_1014f6f60;
      }
    }
    else {
      piVar7 = *(int **)param_5;
      lVar9 = (long)*(int **)(param_5 + 8) - (long)piVar7;
      if (lVar9 == 0) {
LAB_1014f6f2c:
        if (piVar7 != *(int **)(param_5 + 8)) goto LAB_1014f6f34;
      }
      else {
        lVar9 = (lVar9 >> 3) << 3;
        do {
          if (*piVar7 == iVar5 && piVar7[1] == iVar4) goto LAB_1014f6f2c;
          piVar7 = piVar7 + 2;
          lVar9 = lVar9 + -8;
        } while (lVar9 != 0);
      }
LAB_1014f6f60:
      if (param_5 != (vector *)0x0) {
        piVar7 = *(int **)param_5;
        lVar9 = (long)*(int **)(param_5 + 8) - (long)piVar7;
        if (lVar9 != 0) {
          lVar9 = (lVar9 >> 3) << 3;
          while (*piVar7 != (int)uVar3 || piVar7[1] != iVar4 + 1U) {
            piVar7 = piVar7 + 2;
            lVar9 = lVar9 + -8;
            if (lVar9 == 0) {
              return true;
            }
          }
        }
        if (piVar7 == *(int **)(param_5 + 8)) {
          return true;
        }
      }
      puVar2 = (ushort *)TileProxy::getTile(param_1,uVar3 | (ulong)(iVar4 + 1U) << 0x20);
      if (*(ushort *)(param_4 + 0x1a0) <
          *(ushort *)(*(long *)(*(long *)puVar1 + (ulong)*puVar2 * 8) + 0x1a0)) {
        return true;
      }
    }
    uVar3 = (ulong)*(uint *)param_2;
    iVar5 = *(int *)(param_2 + 4);
    iVar4 = *(uint *)param_2 + 1;
    if (param_5 == (vector *)0x0) {
LAB_1014f710c:
      puVar2 = (ushort *)TileProxy::getTile(param_1,CONCAT44(iVar5,iVar4));
      if (*(ushort *)(*(long *)(*(long *)puVar1 + (ulong)*puVar2 * 8) + 0x1a0) <=
          *(ushort *)(param_4 + 0x1a0)) {
        return false;
      }
      uVar3 = (ulong)*(uint *)param_2;
      iVar5 = *(int *)(param_2 + 4);
    }
    else {
      piVar7 = *(int **)param_5;
      lVar9 = (long)*(int **)(param_5 + 8) - (long)piVar7;
      if (lVar9 == 0) {
LAB_1014f7104:
        if (piVar7 != *(int **)(param_5 + 8)) goto LAB_1014f710c;
      }
      else {
        lVar9 = (lVar9 >> 3) << 3;
        do {
          if (*piVar7 == iVar4 && piVar7[1] == iVar5) goto LAB_1014f7104;
          piVar7 = piVar7 + 2;
          lVar9 = lVar9 + -8;
        } while (lVar9 != 0);
      }
    }
    uVar6 = iVar5 - 1;
    if (param_5 == (vector *)0x0) goto LAB_1014f7194;
    piVar7 = *(int **)param_5;
    piVar8 = *(int **)(param_5 + 8);
    if ((long)piVar8 - (long)piVar7 != 0) {
      lVar9 = ((long)piVar8 - (long)piVar7 >> 3) << 3;
      while (*piVar7 != (int)uVar3 || piVar7[1] != uVar6) {
        piVar7 = piVar7 + 2;
        lVar9 = lVar9 + -8;
        if (lVar9 == 0) {
          return true;
        }
      }
    }
  }
  if (piVar7 == piVar8) {
    return true;
  }
LAB_1014f7194:
  puVar2 = (ushort *)TileProxy::getTile(param_1,uVar3 | (ulong)uVar6 << 0x20);
  return *(ushort *)(param_4 + 0x1a0) <
         *(ushort *)
          (*(long *)(*(long *)PTR_indexToPrototype_102d4c598 + (ulong)*puVar2 * 8) + 0x1a0);
}



// ===== TileCorrectionMapGenerationTask::countFixedNeighborsOfKind  @ 0x1015203f0 =====

/* TileCorrectionMapGenerationTask::countFixedNeighborsOfKind(TileCorrectionMapGenerationTask::AreaPosition
   const&, ID<TilePrototype, unsigned short>) const */

char __thiscall
TileCorrectionMapGenerationTask::countFixedNeighborsOfKind
          (TileCorrectionMapGenerationTask *this,uint *param_1,short param_3)

{
  uint uVar1;
  uint uVar2;
  uint uVar3;
  char cVar4;
  uint uVar5;
  
  uVar1 = *param_1;
  uVar2 = param_1[1];
  uVar3 = uVar2 - 1;
  if ((((int)uVar1 < 0) || (0x5f < uVar3)) || (0x5f < uVar1)) {
    cVar4 = false;
    if ((int)(uVar1 + 1) < 0) goto joined_r0x0001015204b8;
  }
  else {
    cVar4 = *(short *)(this + (ulong)uVar3 * 2 + (ulong)uVar1 * 0xc0 + 0x20) == param_3;
  }
  uVar5 = uVar1 + 1;
  if (((uVar3 < 0x60) && (uVar5 < 0x60)) &&
     (*(short *)(this + (ulong)uVar3 * 2 + (ulong)uVar5 * 0xc0 + 0x20) == param_3)) {
    cVar4 = cVar4 + '\x01';
  }
  if (((uVar2 < 0x60) && (uVar5 < 0x60)) &&
     (*(short *)(this + (ulong)uVar2 * 2 + (ulong)uVar5 * 0xc0 + 0x20) == param_3)) {
    cVar4 = cVar4 + '\x01';
  }
  if (((uVar2 + 1 < 0x60) && (uVar5 < 0x60)) &&
     (*(short *)(this + (ulong)(uVar2 + 1) * 2 + (ulong)uVar5 * 0xc0 + 0x20) == param_3)) {
    cVar4 = cVar4 + '\x01';
  }
joined_r0x0001015204b8:
  if (((-1 < (int)uVar1) && (uVar2 + 1 < 0x60)) &&
     ((uVar1 < 0x60 &&
      (*(short *)(this + (ulong)(uVar2 + 1) * 2 + (ulong)uVar1 * 0xc0 + 0x20) == param_3)))) {
    cVar4 = cVar4 + '\x01';
  }
  uVar1 = uVar1 - 1;
  if (-1 < (int)uVar1) {
    if (((uVar2 + 1 < 0x60) && (uVar1 < 0x60)) &&
       (*(short *)(this + (ulong)(uVar2 + 1) * 2 + (ulong)uVar1 * 0xc0 + 0x20) == param_3)) {
      cVar4 = cVar4 + '\x01';
    }
    if (((uVar2 < 0x60) && (uVar1 < 0x60)) &&
       (*(short *)(this + (ulong)uVar2 * 2 + (ulong)uVar1 * 0xc0 + 0x20) == param_3)) {
      cVar4 = cVar4 + '\x01';
    }
    if (((uVar3 < 0x60) && (uVar1 < 0x60)) &&
       (*(short *)(this + (ulong)uVar3 * 2 + (ulong)uVar1 * 0xc0 + 0x20) == param_3)) {
      cVar4 = cVar4 + '\x01';
    }
  }
  return cVar4;
}



// ===== TileCorrectionMapGenerationTask::checkForWeakDiagonalSupport  @ 0x101520558 =====

/* TileCorrectionMapGenerationTask::checkForWeakDiagonalSupport(TileCorrectionMapGenerationTask::AreaPosition
   const&, bool, TilePrototype const&, std::array<std::array<bool, 96ul>, 96ul> const*) const */

bool __thiscall
TileCorrectionMapGenerationTask::checkForWeakDiagonalSupport
          (TileCorrectionMapGenerationTask *this,AreaPosition *param_1,bool param_2,
          TilePrototype *param_3,array *param_4)

{
  long lVar1;
  uint uVar2;
  uint uVar3;
  ushort uVar4;
  uint uVar5;
  ulong uVar6;
  long lVar7;
  
  uVar2 = *(uint *)param_1;
  uVar3 = *(uint *)(param_1 + 4);
  uVar6 = (ulong)uVar3;
  uVar5 = uVar2 - 1;
  if (!param_2) {
    if ((((int)uVar5 < 0) || (0x5f < uVar3)) || (0x5f < uVar5)) {
      if ((int)uVar2 < 0) {
        return true;
      }
LAB_1015206e8:
      uVar5 = uVar3 + 1;
      if (0x5f < uVar5) {
        return true;
      }
      if (0x5f < uVar2) {
        return true;
      }
      if ((param_4 != (array *)0x0) && (param_4[(ulong)uVar5 + (ulong)uVar2 * 0x60] == (array)0x0))
      {
        return true;
      }
      lVar7 = *(long *)PTR_indexToPrototype_102d4c598;
      uVar4 = *(ushort *)(param_3 + 0x1a0);
      if (uVar4 < *(ushort *)
                   (*(long *)(lVar7 + (ulong)*(ushort *)
                                              (this + (ulong)uVar5 * 2 + (ulong)uVar2 * 0xc0 + 0x20)
                                      * 8) + 0x1a0)) {
        return true;
      }
    }
    else {
      if ((param_4 != (array *)0x0) && (param_4[uVar6 + (ulong)uVar5 * 0x60] == (array)0x0))
      goto LAB_1015206e8;
      lVar7 = *(long *)PTR_indexToPrototype_102d4c598;
      uVar4 = *(ushort *)(param_3 + 0x1a0);
      if (uVar4 < *(ushort *)
                   (*(long *)(lVar7 + (ulong)*(ushort *)
                                              (this + uVar6 * 2 + (ulong)uVar5 * 0xc0 + 0x20) * 8) +
                   0x1a0)) goto LAB_1015206e8;
    }
    if ((((uVar3 < 0x60) && (uVar2 < 0x5f)) &&
        ((lVar1 = (ulong)uVar2 + 1, param_4 == (array *)0x0 ||
         (param_4[uVar6 + lVar1 * 0x60] != (array)0x0)))) &&
       (*(ushort *)
         (*(long *)(lVar7 + (ulong)*(ushort *)(this + uVar6 * 2 + lVar1 * 0xc0 + 0x20) * 8) + 0x1a0)
        <= uVar4)) {
      return false;
    }
    uVar6 = (ulong)(uVar3 - 1);
    if (0x5f < uVar3 - 1) {
      return true;
    }
    if (0x5f < uVar2) {
      return true;
    }
    goto joined_r0x0001015207a4;
  }
  if ((((int)uVar5 < 0) || (0x5f < uVar3)) || (0x5f < uVar5)) {
    if ((int)uVar2 < 0) {
      return true;
    }
LAB_101520620:
    uVar5 = uVar3 - 1;
    if (0x5f < uVar5) {
      return true;
    }
    if (0x5f < uVar2) {
      return true;
    }
    if ((param_4 != (array *)0x0) && (param_4[(ulong)uVar5 + (ulong)uVar2 * 0x60] == (array)0x0)) {
      return true;
    }
    lVar7 = *(long *)PTR_indexToPrototype_102d4c598;
    uVar4 = *(ushort *)(param_3 + 0x1a0);
    if (uVar4 < *(ushort *)
                 (*(long *)(lVar7 + (ulong)*(ushort *)
                                            (this + (ulong)uVar5 * 2 + (ulong)uVar2 * 0xc0 + 0x20) *
                                    8) + 0x1a0)) {
      return true;
    }
  }
  else {
    if ((param_4 != (array *)0x0) && (param_4[uVar6 + (ulong)uVar5 * 0x60] == (array)0x0))
    goto LAB_101520620;
    lVar7 = *(long *)PTR_indexToPrototype_102d4c598;
    uVar4 = *(ushort *)(param_3 + 0x1a0);
    if (uVar4 < *(ushort *)
                 (*(long *)(lVar7 + (ulong)*(ushort *)
                                            (this + uVar6 * 2 + (ulong)uVar5 * 0xc0 + 0x20) * 8) +
                 0x1a0)) goto LAB_101520620;
  }
  if ((((uVar3 < 0x60) && (uVar2 < 0x5f)) &&
      ((lVar1 = (ulong)uVar2 + 1, param_4 == (array *)0x0 ||
       (param_4[uVar6 + lVar1 * 0x60] != (array)0x0)))) &&
     (*(ushort *)
       (*(long *)(lVar7 + (ulong)*(ushort *)(this + uVar6 * 2 + lVar1 * 0xc0 + 0x20) * 8) + 0x1a0)
      <= uVar4)) {
    return false;
  }
  if (0x5e < uVar3) {
    return true;
  }
  if (0x5f < uVar2) {
    return true;
  }
  uVar6 = uVar6 + 1;
joined_r0x0001015207a4:
  if ((param_4 != (array *)0x0) && (param_4[uVar6 + (ulong)uVar2 * 0x60] == (array)0x0)) {
    return true;
  }
  return uVar4 < *(ushort *)
                  (*(long *)(lVar7 + (ulong)*(ushort *)
                                             (this + uVar6 * 2 + (ulong)uVar2 * 0xc0 + 0x20) * 8) +
                  0x1a0);
}



