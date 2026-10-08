// Decompiled from factorio-arm64 (Space Age 2.0).
// Functions: 6

// ===== 0x1015f1450 run =====

/* NoiseOperations::Terrace::run(NoiseCache&) const */

void __thiscall NoiseOperations::Terrace::run(Terrace *this,NoiseCache *param_1)

{
  undefined8 *puVar1;
  undefined8 *puVar2;
  undefined8 *puVar3;
  ulong uVar4;
  long lVar5;
  ulong uVar6;
  float *pfVar7;
  float *pfVar8;
  ulong uVar9;
  long lVar10;
  float *pfVar11;
  undefined8 *puVar12;
  undefined8 *puVar13;
  undefined8 *puVar14;
  float fVar15;
  float fVar16;
  float fVar17;
  float fVar18;
  undefined1 auVar19 [16];
  float fVar20;
  float fVar21;
  float fVar22;
  float fVar23;
  float fVar24;
  float fVar25;
  float fVar26;
  float fVar27;
  float fVar28;
  float fVar29;
  int iVar30;
  int iVar31;
  int iVar32;
  int iVar33;
  
  puVar1 = (undefined8 *)NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 8));
  puVar2 = (undefined8 *)NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0xc));
  puVar3 = (undefined8 *)NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x10));
  uVar4 = *(ulong *)(param_1 + 0x10);
  if (uVar4 != 0) {
    fVar16 = *(float *)(this + 0x14);
    fVar15 = *(float *)(this + 0x18);
    if ((uVar4 < 4) ||
       ((ulong)((long)puVar1 - (long)puVar3) < 0x10 || (ulong)((long)puVar1 - (long)puVar2) < 0x10))
    {
      uVar6 = 0;
    }
    else {
      uVar6 = uVar4 & 0xfffffffffffffffc;
      auVar19 = NEON_fmov(0x3f800000,4);
      uVar9 = uVar6;
      puVar12 = puVar1;
      puVar13 = puVar2;
      puVar14 = puVar3;
      do {
        fVar22 = ((float)*puVar13 - fVar16) / fVar15;
        fVar23 = ((float)((ulong)*puVar13 >> 0x20) - fVar16) / fVar15;
        fVar24 = ((float)puVar13[1] - fVar16) / fVar15;
        fVar25 = ((float)((ulong)puVar13[1] >> 0x20) - fVar16) / fVar15;
        fVar26 = (float)(int)fVar22;
        fVar27 = (float)(int)fVar23;
        fVar28 = (float)(int)fVar24;
        fVar29 = (float)(int)fVar25;
        fVar22 = fVar22 - fVar26;
        fVar23 = fVar23 - fVar27;
        fVar24 = fVar24 - fVar28;
        fVar25 = fVar25 - fVar29;
        fVar17 = (float)*puVar14;
        iVar30 = -(uint)(fVar17 < fVar22);
        fVar18 = (float)((ulong)*puVar14 >> 0x20);
        iVar31 = -(uint)(fVar18 < fVar23);
        fVar21 = (float)puVar14[1];
        iVar32 = -(uint)(fVar21 < fVar24);
        fVar20 = (float)((ulong)puVar14[1] >> 0x20);
        iVar33 = -(uint)(fVar20 < fVar25);
        fVar17 = (fVar22 - fVar17) / (auVar19._0_4_ - fVar17);
        fVar18 = (fVar23 - fVar18) / (auVar19._4_4_ - fVar18);
        fVar21 = (fVar24 - fVar21) / (auVar19._8_4_ - fVar21);
        fVar20 = (fVar25 - fVar20) / (auVar19._12_4_ - fVar20);
        fVar17 = (float)CONCAT13((byte)((uint)fVar17 >> 0x18) & (byte)((uint)iVar30 >> 0x18),
                                 CONCAT12((byte)((uint)fVar17 >> 0x10) &
                                          (byte)((uint)iVar30 >> 0x10),
                                          CONCAT11((byte)((uint)fVar17 >> 8) &
                                                   (byte)((uint)iVar30 >> 8),
                                                   SUB41(fVar17,0) & (byte)iVar30)));
        fVar21 = (float)CONCAT13((byte)((uint)fVar21 >> 0x18) & (byte)((uint)iVar32 >> 0x18),
                                 CONCAT12((byte)((uint)fVar21 >> 0x10) &
                                          (byte)((uint)iVar32 >> 0x10),
                                          CONCAT11((byte)((uint)fVar21 >> 8) &
                                                   (byte)((uint)iVar32 >> 8),
                                                   SUB41(fVar21,0) & (byte)iVar32)));
        puVar12[1] = CONCAT44(fVar16 + (fVar29 + (float)(CONCAT17((byte)((uint)fVar20 >> 0x18) &
                                                                  (byte)((uint)iVar33 >> 0x18),
                                                                  CONCAT16((byte)((uint)fVar20 >>
                                                                                 0x10) &
                                                                           (byte)((uint)iVar33 >>
                                                                                 0x10),
                                                                           CONCAT15((byte)((uint)
                                                  fVar20 >> 8) & (byte)((uint)iVar33 >> 8),
                                                  CONCAT14(SUB41(fVar20,0) & (byte)iVar33,fVar21))))
                                                  >> 0x20)) * fVar15,
                              fVar16 + (fVar28 + fVar21) * fVar15);
        *puVar12 = CONCAT44(fVar16 + (fVar27 + (float)(CONCAT17((byte)((uint)fVar18 >> 0x18) &
                                                                (byte)((uint)iVar31 >> 0x18),
                                                                CONCAT16((byte)((uint)fVar18 >> 0x10
                                                                               ) & (byte)((uint)
                                                  iVar31 >> 0x10),
                                                  CONCAT15((byte)((uint)fVar18 >> 8) &
                                                           (byte)((uint)iVar31 >> 8),
                                                           CONCAT14(SUB41(fVar18,0) & (byte)iVar31,
                                                                    fVar17)))) >> 0x20)) * fVar15,
                            fVar16 + (fVar26 + fVar17) * fVar15);
        uVar9 = uVar9 - 4;
        puVar12 = puVar12 + 2;
        puVar13 = puVar13 + 2;
        puVar14 = puVar14 + 2;
      } while (uVar9 != 0);
      if (uVar4 == uVar6) {
        return;
      }
    }
    lVar5 = uVar4 - uVar6;
    lVar10 = uVar6 * 4;
    pfVar8 = (float *)((long)puVar2 + lVar10);
    pfVar11 = (float *)((long)puVar3 + lVar10);
    pfVar7 = (float *)((long)puVar1 + lVar10);
    do {
      fVar18 = *pfVar11;
      fVar20 = (*pfVar8 - fVar16) / fVar15;
      fVar17 = (float)(int)fVar20;
      fVar20 = fVar20 - fVar17;
      fVar21 = 0.0;
      if (fVar18 < fVar20) {
        fVar21 = (fVar20 - fVar18) / (1.0 - fVar18);
      }
      *pfVar7 = fVar16 + fVar15 * (fVar17 + fVar21);
      pfVar8 = pfVar8 + 1;
      pfVar11 = pfVar11 + 1;
      lVar5 = lVar5 + -1;
      pfVar7 = pfVar7 + 1;
    } while (lVar5 != 0);
  }
  return;
}



// ===== 0x1015f144c Terrace =====

/* NoiseOperations::Terrace::Terrace(NoiseRegisterIndex, std::array<NoiseRegisterIndex, 2ul> const&,
   std::span<NoiseExpressionConstant const, 2ul> const&) */

void __thiscall
NoiseOperations::Terrace::Terrace
          (Terrace *this,undefined4 param_2,undefined4 *param_3,undefined8 *param_4)

{
  char cVar1;
  undefined8 uVar2;
  char *pcVar3;
  
  *(undefined4 *)(this + 8) = param_2;
  *(undefined ***)this = &PTR__Terrace_102f85d08;
  *(undefined4 *)(this + 0xc) = *param_3;
  *(undefined4 *)(this + 0x10) = param_3[1];
  pcVar3 = (char *)*param_4;
  if (*pcVar3 == '\x01') {
    cVar1 = pcVar3[0x20];
    *(float *)(this + 0x14) = (float)*(double *)(pcVar3 + 8);
    if (cVar1 == '\x01') {
      *(float *)(this + 0x18) = (float)*(double *)(pcVar3 + 0x28);
      return;
    }
    uVar2 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(pcVar3 + 0x20,"stripe_width");
  }
  else {
    uVar2 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(pcVar3,"stripe_offset");
  }
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(uVar2,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



// ===== 0x101611718 save =====

/* NoiseOperations::Terrace::save(Serialiser&) const */

void __thiscall NoiseOperations::Terrace::save(Terrace *this,Serialiser *param_1)

{
  undefined4 local_24;
  
  if (param_1[8] != (Serialiser)0x0) {
    (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),"<",1);
    *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 1;
    (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),"terrace",7);
    *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 7;
    (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),">",1);
    *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 1;
  }
  NoiseOperation::save((NoiseOperation *)this,param_1);
  local_24 = *(undefined4 *)(this + 8);
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),&local_24,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  local_24 = *(undefined4 *)(this + 0xc);
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),&local_24,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  local_24 = *(undefined4 *)(this + 0x10);
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),&local_24,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x14,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x18,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  if (param_1[8] != (Serialiser)0x0) {
    (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),"</",2);
    *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 2;
    (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),"terrace",7);
    *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 7;
    (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),">",1);
    *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 1;
  }
  return;
}



// ===== 0x10161193c getRegisterReferences =====

/* NoiseOperations::Terrace::getRegisterReferences(std::vector<NoiseRegisterIndex*,
   std::allocator<NoiseRegisterIndex*> >&) */

void __thiscall NoiseOperations::Terrace::getRegisterReferences(Terrace *this,vector *param_1)

{
  Terrace *pTVar1;
  ulong uVar2;
  void *pvVar3;
  ulong uVar4;
  long *plVar5;
  ulong uVar6;
  long *plVar7;
  long *plVar8;
  long *plVar9;
  long lVar10;
  
  NoiseOperationWithSingleResult::getRegisterReferences
            ((NoiseOperationWithSingleResult *)this,param_1);
  pTVar1 = this + 0xc;
  plVar8 = *(long **)(param_1 + 8);
  if (plVar8 < *(long **)(param_1 + 0x10)) {
    plVar7 = plVar8 + 1;
    *plVar8 = (long)pTVar1;
    *(long **)(param_1 + 8) = plVar7;
LAB_101611a30:
    pTVar1 = this + 0x10;
    if (plVar7 < *(long **)(param_1 + 0x10)) {
      *plVar7 = (long)pTVar1;
      *(long **)(param_1 + 8) = plVar7 + 1;
      return;
    }
    plVar8 = *(long **)param_1;
    lVar10 = (long)plVar7 - (long)plVar8 >> 3;
    uVar2 = lVar10 + 1;
    if (uVar2 >> 0x3d == 0) {
      uVar4 = (long)*(long **)(param_1 + 0x10) - (long)plVar8;
      uVar6 = uVar4 >> 2;
      if (uVar6 <= uVar2) {
        uVar6 = uVar2;
      }
      if (0x7ffffffffffffff7 < uVar4) {
        uVar6 = 0x1fffffffffffffff;
      }
      if (uVar6 == 0) {
        plVar9 = (long *)(lVar10 * 8);
        pvVar3 = (void *)0x0;
        *plVar9 = (long)pTVar1;
joined_r0x000101611af0:
        plVar5 = plVar9 + 1;
        if (plVar7 == plVar8) {
          *(long **)param_1 = plVar9;
          *(long **)(param_1 + 8) = plVar5;
          *(void **)(param_1 + 0x10) = pvVar3;
        }
        else {
          do {
            plVar7 = plVar7 + -1;
            plVar9 = plVar9 + -1;
            *plVar9 = *plVar7;
          } while (plVar7 != plVar8);
          plVar7 = *(long **)param_1;
          *(long **)param_1 = plVar9;
          *(long **)(param_1 + 8) = plVar5;
          *(void **)(param_1 + 0x10) = pvVar3;
        }
        if (plVar7 == (long *)0x0) {
          return;
        }
        operator_delete(plVar7);
        return;
      }
      if (uVar6 >> 0x3d == 0) {
        pvVar3 = operator_new(uVar6 << 3);
        plVar9 = (long *)((long)pvVar3 + lVar10 * 8);
        pvVar3 = (void *)((long)pvVar3 + uVar6 * 8);
        *plVar9 = (long)pTVar1;
        goto joined_r0x000101611af0;
      }
      goto LAB_101611b34;
    }
  }
  else {
    plVar9 = *(long **)param_1;
    lVar10 = (long)plVar8 - (long)plVar9 >> 3;
    uVar2 = lVar10 + 1;
    if (uVar2 >> 0x3d == 0) {
      uVar4 = (long)*(long **)(param_1 + 0x10) - (long)plVar9;
      uVar6 = uVar4 >> 2;
      if (uVar6 <= uVar2) {
        uVar6 = uVar2;
      }
      if (0x7ffffffffffffff7 < uVar4) {
        uVar6 = 0x1fffffffffffffff;
      }
      if (uVar6 == 0) {
        plVar5 = (long *)(lVar10 * 8);
        pvVar3 = (void *)0x0;
        *plVar5 = (long)pTVar1;
      }
      else {
        if (uVar6 >> 0x3d != 0) goto LAB_101611b34;
        pvVar3 = operator_new(uVar6 << 3);
        plVar5 = (long *)((long)pvVar3 + lVar10 * 8);
        pvVar3 = (void *)((long)pvVar3 + uVar6 * 8);
        *plVar5 = (long)pTVar1;
      }
      plVar7 = plVar5 + 1;
      if (plVar8 != plVar9) {
        do {
          plVar8 = plVar8 + -1;
          plVar5 = plVar5 + -1;
          *plVar5 = *plVar8;
        } while (plVar8 != plVar9);
        plVar8 = *(long **)param_1;
      }
      *(long **)param_1 = plVar5;
      *(long **)(param_1 + 8) = plVar7;
      *(void **)(param_1 + 0x10) = pvVar3;
      if (plVar8 != (long *)0x0) {
        operator_delete(plVar8);
        plVar7 = *(long **)(param_1 + 8);
      }
      goto LAB_101611a30;
    }
  }
  std::vector<NoiseRegisterIndex*,std::allocator<NoiseRegisterIndex*>>::
  __throw_length_error_abi_v160006_();
LAB_101611b34:
                    /* WARNING: Subroutine does not return */
  std::__throw_bad_array_new_length_abi_v160006_();
}



// ===== 0x101611b38 toString =====

/* WARNING: Removing unreachable block (ram,0x000101611b9c) */
/* NoiseOperations::Terrace::toString() const */

void NoiseOperations::Terrace::toString(void)

{
  long *in_x0;
  void *local_60 [2];
  char local_49;
  undefined1 local_48 [24];
  
  (**(code **)(*in_x0 + 0x20))();
  toStr(local_48);
  ssprintf("$%u = %s(",local_60);
  ssprintf("%ssource=$%u, offset=%f, width=%f, strength=$%u)");
  if (local_49 < '\0') {
    operator_delete(local_60[0]);
    return;
  }
  return;
}



// ===== 0x1015ff888 GridOperation =====

/* NoiseOperations::GridOperation::GridOperation(NoiseRegisterIndex, NoiseRegisterIndex,
   NoiseRegisterIndex) */

void __thiscall
NoiseOperations::GridOperation::GridOperation
          (GridOperation *this,undefined4 param_2,undefined4 param_3,undefined4 param_4)

{
  *(undefined ***)this = &PTR__GridOperation_102f851a0;
  *(undefined4 *)(this + 8) = param_2;
  *(undefined4 *)(this + 0xc) = param_3;
  *(undefined4 *)(this + 0x10) = param_4;
  return;
}



