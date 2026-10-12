// ===== AutoplaceSpecification::operator<  @ 0x10221e6cc =====

/* AutoplaceSpecification::TEMPNAMEPLACEHOLDERVALUE(AutoplaceSpecification const&) const */

uint __thiscall
AutoplaceSpecification::operator<(AutoplaceSpecification *this,AutoplaceSpecification *param_1)

{
  AutoplaceSpecification *pAVar1;
  ulong uVar2;
  AutoplaceSpecification *pAVar3;
  ulong uVar4;
  size_t sVar5;
  AutoplaceSpecification AVar6;
  bool bVar7;
  uint uVar8;
  int iVar9;
  
  AVar6 = param_1[0x17f];
  pAVar1 = *(AutoplaceSpecification **)(param_1 + 0x168);
  if (-1 < (char)AVar6) {
    pAVar1 = param_1 + 0x168;
  }
  uVar2 = *(ulong *)(param_1 + 0x170);
  if (-1 < (char)AVar6) {
    uVar2 = (ulong)(byte)AVar6;
  }
  AVar6 = this[0x17f];
  uVar4 = *(ulong *)(this + 0x170);
  if (-1 < (char)AVar6) {
    uVar4 = (ulong)(byte)AVar6;
  }
  sVar5 = uVar2;
  if (uVar4 <= uVar2) {
    sVar5 = uVar4;
  }
  if (sVar5 != 0) {
    pAVar3 = *(AutoplaceSpecification **)(this + 0x168);
    if (-1 < (char)AVar6) {
      pAVar3 = this + 0x168;
    }
    uVar8 = _memcmp(pAVar3,pAVar1,sVar5);
    if (uVar8 != 0) {
      return uVar8 >> 0x1f;
    }
  }
  bVar7 = uVar4 < uVar2;
  if (uVar2 == uVar4) {
    AVar6 = param_1[0x27];
    pAVar1 = *(AutoplaceSpecification **)(param_1 + 0x10);
    if (-1 < (char)AVar6) {
      pAVar1 = param_1 + 0x10;
    }
    uVar2 = *(ulong *)(param_1 + 0x18);
    if (-1 < (char)AVar6) {
      uVar2 = (ulong)(byte)AVar6;
    }
    AVar6 = this[0x27];
    uVar4 = *(ulong *)(this + 0x18);
    if (-1 < (char)AVar6) {
      uVar4 = (ulong)(byte)AVar6;
    }
    sVar5 = uVar2;
    if (uVar4 <= uVar2) {
      sVar5 = uVar4;
    }
    if (sVar5 != 0) {
      pAVar3 = *(AutoplaceSpecification **)(this + 0x10);
      if (-1 < (char)AVar6) {
        pAVar3 = this + 0x10;
      }
      uVar8 = _memcmp(pAVar3,pAVar1,sVar5);
      if (uVar8 != 0) {
        return uVar8 >> 0x1f;
      }
    }
    bVar7 = uVar4 < uVar2;
    if (uVar2 == uVar4) {
      AVar6 = this[0x167];
      pAVar1 = *(AutoplaceSpecification **)(this + 0x150);
      if (-1 < (char)AVar6) {
        pAVar1 = this + 0x150;
      }
      uVar2 = *(ulong *)(this + 0x158);
      if (-1 < (char)AVar6) {
        uVar2 = (ulong)(byte)AVar6;
      }
      AVar6 = param_1[0x167];
      pAVar3 = *(AutoplaceSpecification **)(param_1 + 0x150);
      if (-1 < (char)AVar6) {
        pAVar3 = param_1 + 0x150;
      }
      uVar4 = *(ulong *)(param_1 + 0x158);
      if (-1 < (char)AVar6) {
        uVar4 = (ulong)(byte)AVar6;
      }
      sVar5 = uVar4;
      if (uVar2 <= uVar4) {
        sVar5 = uVar2;
      }
      if ((sVar5 == 0) || (iVar9 = _memcmp(pAVar1,pAVar3,sVar5), iVar9 == 0)) {
        if (uVar2 < uVar4) {
          return 1;
        }
      }
      else if (iVar9 < 0) {
        return 1;
      }
      return 0;
    }
  }
  return (uint)bVar7;
}



// ===== NoiseOperations::RandomPenalty::run  @ 0x1015f0384 =====

/* NoiseOperations::RandomPenalty::run(NoiseCache&) const */

void __thiscall NoiseOperations::RandomPenalty::run(RandomPenalty *this,NoiseCache *param_1)

{
  int iVar1;
  undefined8 uVar2;
  undefined8 uVar3;
  undefined8 uVar4;
  ulong uVar5;
  long lVar6;
  long lVar7;
  float *pfVar8;
  float *pfVar9;
  long lVar10;
  uint uVar11;
  int iVar12;
  long lVar13;
  byte bVar14;
  byte bVar17;
  byte bVar18;
  float fVar15;
  byte bVar19;
  byte bVar20;
  byte bVar21;
  byte bVar22;
  undefined8 uVar16;
  byte bVar23;
  double dVar24;
  undefined8 uVar25;
  ulong uVar26;
  
  if (*(long *)(param_1 + 0x10) == 0) {
    return;
  }
  lVar6 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 8));
  lVar7 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x14));
  pfVar8 = (float *)NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0xc));
  pfVar9 = (float *)NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x10));
  uVar5 = DAT_1029735e0;
  uVar4 = DAT_1029735d8;
  uVar3 = DAT_1029735d0;
  uVar2 = DAT_1029735c8;
  fVar15 = *pfVar8;
  iVar1 = 0x3fbe2c;
  if (-9.223372e+18 < fVar15) {
    iVar1 = (int)(long)fVar15 * 0x1eef + 0x3fbe2c;
  }
  iVar12 = 0x3f9f3d;
  if (fVar15 < 9.223372e+18) {
    iVar12 = iVar1;
  }
  iVar1 = 0x3fbe2c;
  if (!NAN(fVar15)) {
    iVar1 = iVar12;
  }
  fVar15 = (float)NEON_ucvtf(*(undefined4 *)(this + 0x18));
  fVar15 = *pfVar9 + fVar15;
  if (!NAN(fVar15)) {
    if (9.223372e+18 <= fVar15) {
      iVar12 = -0x1ee3;
      lVar10 = *(long *)(param_1 + 0x10);
      goto joined_r0x0001015f0474;
    }
    if (-9.223372e+18 < fVar15) {
      iVar12 = (int)(long)fVar15 * 0x1ee3;
      lVar10 = *(long *)(param_1 + 0x10);
      goto joined_r0x0001015f0474;
    }
  }
  iVar12 = 0;
  lVar10 = *(long *)(param_1 + 0x10);
joined_r0x0001015f0474:
  if (lVar10 != 0) {
    uVar11 = iVar12 + iVar1;
    if (uVar11 < 0x156) {
      uVar11 = 0x155;
    }
    uVar16 = CONCAT44(uVar11,uVar11);
    do {
      lVar13 = lVar10 + -1;
      fVar15 = *(float *)(lVar7 + -4 + lVar10 * 4);
      dVar24 = (double)fVar15;
      if (0.0 < fVar15) {
        uVar25 = NEON_ushl(uVar16,uVar2,4);
        uVar26 = NEON_ushl(uVar16,uVar3,4);
        uVar16 = NEON_ushl(CONCAT17((byte)((ulong)uVar25 >> 0x38) ^ (byte)((ulong)uVar16 >> 0x38),
                                    CONCAT16((byte)((ulong)uVar25 >> 0x30) ^
                                             (byte)((ulong)uVar16 >> 0x30),
                                             CONCAT15((byte)((ulong)uVar25 >> 0x28) ^
                                                      (byte)((ulong)uVar16 >> 0x28),
                                                      CONCAT14((byte)((ulong)uVar25 >> 0x20) ^
                                                               (byte)((ulong)uVar16 >> 0x20),
                                                               CONCAT13((byte)((ulong)uVar25 >> 0x18
                                                                              ) ^ (byte)((ulong)
                                                  uVar16 >> 0x18),
                                                  CONCAT12((byte)((ulong)uVar25 >> 0x10) ^
                                                           (byte)((ulong)uVar16 >> 0x10),
                                                           CONCAT11((byte)((ulong)uVar25 >> 8) ^
                                                                    (byte)((ulong)uVar16 >> 8),
                                                                    (byte)uVar25 ^ (byte)uVar16)))))
                                            )),uVar4,4);
        uVar26 = uVar26 & uVar5;
        bVar14 = (byte)uVar16 | (byte)uVar26;
        bVar17 = (byte)((ulong)uVar16 >> 8) | (byte)(uVar26 >> 8);
        bVar18 = (byte)((ulong)uVar16 >> 0x10) | (byte)(uVar26 >> 0x10);
        bVar19 = (byte)((ulong)uVar16 >> 0x18) | (byte)(uVar26 >> 0x18);
        bVar20 = (byte)((ulong)uVar16 >> 0x20) | (byte)(uVar26 >> 0x20);
        bVar21 = (byte)((ulong)uVar16 >> 0x28) | (byte)(uVar26 >> 0x28);
        bVar22 = (byte)((ulong)uVar16 >> 0x30) | (byte)(uVar26 >> 0x30);
        bVar23 = (byte)((ulong)uVar16 >> 0x38) | (byte)(uVar26 >> 0x38);
        uVar16 = CONCAT17(bVar23,CONCAT16(bVar22,CONCAT15(bVar21,CONCAT14(bVar20,CONCAT13(bVar19,
                                                  CONCAT12(bVar18,CONCAT11(bVar17,bVar14)))))));
        uVar11 = (uVar11 & 0xffffe) << 0xc | (uVar11 ^ uVar11 << 0xd) >> 0x13;
        dVar24 = dVar24 + (double)(CONCAT13(bVar23 ^ bVar19,
                                            CONCAT12(bVar22 ^ bVar18,
                                                     CONCAT11(bVar21 ^ bVar17,bVar20 ^ bVar14))) ^
                                  uVar11) * -2.3283064365386963e-10 *
                          (double)*(float *)(this + 0x1c);
      }
      *(float *)(lVar6 + -4 + lVar10 * 4) = (float)dVar24;
      lVar10 = lVar13;
    } while (lVar13 != 0);
  }
  return;
}



// ===== NoiseExpressions::ComplexExpressionWithOperation<NoiseOperations::RandomPenalty,(unsigned_char)3,(unsigned_char)2>::computeConstant  @ 0x1015eff14 =====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* NoiseExpressions::ComplexExpressionWithOperation<NoiseOperations::RandomPenalty, (unsigned
   char)3, (unsigned char)2>::computeConstant(std::span<NoiseExpressionConstant const, 3ul> const&,
   std::span<NoiseExpressionConstant const, 2ul> const&) */

void __thiscall
NoiseExpressions::
ComplexExpressionWithOperation<NoiseOperations::RandomPenalty,(unsigned_char)3,(unsigned_char)2>::
computeConstant(ComplexExpressionWithOperation<NoiseOperations::RandomPenalty,(unsigned_char)3,(unsigned_char)2>
                *this,span *param_1,span *param_2)

{
  undefined *puVar1;
  undefined *puVar2;
  NoiseCache *pNVar3;
  byte *pbVar4;
  float *pfVar5;
  undefined8 *puVar6;
  undefined8 *puVar7;
  void *pvVar8;
  NoiseCache *pNVar9;
  undefined1 *puVar10;
  undefined8 uVar11;
  undefined1 *in_x8;
  char *pcVar12;
  undefined8 extraout_x8;
  undefined8 extraout_x8_00;
  undefined8 extraout_x8_01;
  long lVar13;
  float fVar14;
  double dVar15;
  RandomPenalty aRStack_a0 [32];
  undefined4 local_80;
  undefined4 local_7c;
  undefined4 local_78;
  
  puVar1 = getSharedNoiseCache()::cache;
  pNVar3 = (NoiseCache *)(*(code *)getSharedNoiseCache()::cache)(&getSharedNoiseCache()::cache);
  puVar2 = getSharedNoiseCache()::cache;
  local_80 = 0;
  pcVar12 = *(char **)this;
  if (*pcVar12 == '\x01') {
    dVar15 = *(double *)(pcVar12 + 8);
    pbVar4 = (byte *)(*(code *)getSharedNoiseCache()::cache)(&getSharedNoiseCache()::cache);
    if ((*pbVar4 & 1) == 0) {
      puVar6 = (undefined8 *)(*(code *)puVar1)(&getSharedNoiseCache()::cache);
      *puVar6 = 1;
      *(undefined4 *)(puVar6 + 1) = 5;
      uVar11 = _DAT_102970ca0;
      puVar6[3] = _UNK_102970ca8;
      puVar6[2] = uVar11;
      puVar7 = operator_new__(0x20);
      puVar7[1] = 0;
      *puVar7 = 0;
      puVar7[3] = 0;
      puVar7[2] = 0;
      puVar6[4] = puVar7;
      *(undefined1 *)(puVar6 + 5) = 0;
      *(undefined8 *)((long)puVar6 + 0x34) = 0;
      *(undefined8 *)((long)puVar6 + 0x2c) = 0;
      *(undefined4 *)((long)puVar6 + 0x3c) = 0;
      puVar6[8] = 5;
      pvVar8 = operator_new__(0x14);
      lVar13 = (*(code *)puVar1)(pvVar8,&getSharedNoiseCache()::cache);
      *(undefined8 *)(lVar13 + 0x48) = extraout_x8;
      __tlv_atexit(NoiseCache::~NoiseCache,lVar13,0x100000000);
      puVar10 = (undefined1 *)(*(code *)puVar2)(&getSharedNoiseCache()::cache);
      *puVar10 = 1;
    }
    pfVar5 = (float *)NoiseCache::getFloatRegister(pNVar3,0);
    *pfVar5 = (float)dVar15;
    lVar13 = 1;
    local_7c = 1;
    pcVar12 = *(char **)this;
    if (pcVar12[0x20] == '\x01') {
      dVar15 = *(double *)(pcVar12 + 0x28);
      pbVar4 = (byte *)(*(code *)puVar2)(&getSharedNoiseCache()::cache);
      if ((*pbVar4 & 1) == 0) {
        puVar6 = (undefined8 *)(*(code *)puVar1)(&getSharedNoiseCache()::cache);
        *puVar6 = 1;
        *(undefined4 *)(puVar6 + 1) = 5;
        uVar11 = _DAT_102970ca0;
        puVar6[3] = _UNK_102970ca8;
        puVar6[2] = uVar11;
        puVar7 = operator_new__(0x20);
        puVar7[1] = 0;
        *puVar7 = 0;
        puVar7[3] = 0;
        puVar7[2] = 0;
        puVar6[4] = puVar7;
        *(undefined1 *)(puVar6 + 5) = 0;
        *(undefined8 *)((long)puVar6 + 0x34) = 0;
        *(undefined8 *)((long)puVar6 + 0x2c) = 0;
        *(undefined4 *)((long)puVar6 + 0x3c) = 0;
        puVar6[8] = 5;
        pvVar8 = operator_new__(0x14);
        lVar13 = (*(code *)puVar1)(pvVar8,&getSharedNoiseCache()::cache);
        *(undefined8 *)(lVar13 + 0x48) = extraout_x8_00;
        __tlv_atexit(NoiseCache::~NoiseCache,lVar13,0x100000000);
        puVar10 = (undefined1 *)(*(code *)puVar2)(&getSharedNoiseCache()::cache);
        *puVar10 = 1;
      }
      pfVar5 = (float *)NoiseCache::getFloatRegister(pNVar3,1);
      *pfVar5 = (float)dVar15;
      lVar13 = 2;
      local_78 = 2;
      pcVar12 = *(char **)this;
      if (pcVar12[0x40] == '\x01') {
        dVar15 = *(double *)(pcVar12 + 0x48);
        pbVar4 = (byte *)(*(code *)puVar2)(&getSharedNoiseCache()::cache);
        if ((*pbVar4 & 1) == 0) {
          puVar6 = (undefined8 *)(*(code *)puVar1)(&getSharedNoiseCache()::cache);
          *puVar6 = 1;
          *(undefined4 *)(puVar6 + 1) = 5;
          uVar11 = _DAT_102970ca0;
          puVar6[3] = _UNK_102970ca8;
          puVar6[2] = uVar11;
          puVar7 = operator_new__(0x20);
          puVar7[1] = 0;
          *puVar7 = 0;
          puVar7[3] = 0;
          puVar7[2] = 0;
          puVar6[4] = puVar7;
          *(undefined1 *)(puVar6 + 5) = 0;
          *(undefined8 *)((long)puVar6 + 0x34) = 0;
          *(undefined8 *)((long)puVar6 + 0x2c) = 0;
          *(undefined4 *)((long)puVar6 + 0x3c) = 0;
          puVar6[8] = 5;
          pvVar8 = operator_new__(0x14);
          lVar13 = (*(code *)puVar1)(pvVar8,&getSharedNoiseCache()::cache);
          *(undefined8 *)(lVar13 + 0x48) = extraout_x8_01;
          __tlv_atexit(NoiseCache::~NoiseCache,lVar13,0x100000000);
          puVar10 = (undefined1 *)(*(code *)puVar2)(&getSharedNoiseCache()::cache);
          *puVar10 = 1;
        }
        pfVar5 = (float *)NoiseCache::getFloatRegister(pNVar3,2);
        *pfVar5 = (float)dVar15;
        NoiseOperations::RandomPenalty::RandomPenalty(aRStack_a0,3,&local_80,param_1);
        pcVar12 = (char *)(*(code *)puVar2)(&getSharedNoiseCache()::cache);
        if (*pcVar12 != '\x01') {
          pNVar9 = (NoiseCache *)(*(code *)puVar1)(&getSharedNoiseCache()::cache);
          NoiseCache::NoiseCache(pNVar9,1,5);
          __tlv_atexit(NoiseCache::~NoiseCache,pNVar9,0x100000000);
          puVar10 = (undefined1 *)(*(code *)puVar2)(&getSharedNoiseCache()::cache);
          *puVar10 = 1;
        }
        NoiseOperations::RandomPenalty::run(aRStack_a0,pNVar3);
        pbVar4 = (byte *)(*(code *)puVar2)(&getSharedNoiseCache()::cache);
        if ((*pbVar4 & 1) == 0) {
          pNVar9 = (NoiseCache *)(*(code *)puVar1)(&getSharedNoiseCache()::cache);
          NoiseCache::NoiseCache(pNVar9,1,5);
          __tlv_atexit(NoiseCache::~NoiseCache,pNVar9,0x100000000);
          puVar10 = (undefined1 *)(*(code *)puVar2)(&getSharedNoiseCache()::cache);
          *puVar10 = 1;
        }
        pfVar5 = (float *)NoiseCache::getFloatRegister(pNVar3,3);
        fVar14 = *pfVar5;
        *in_x8 = 1;
        *(double *)(in_x8 + 8) = (double)fVar14;
        return;
      }
    }
  }
  else {
    lVar13 = 0;
  }
  uVar11 = ___cxa_allocate_exception(0x10);
  NoiseExpressionConstant::getInvalidParameterError(pcVar12 + lVar13 * 0x20,"arg_register");
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(uVar11,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



