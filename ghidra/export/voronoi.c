// Decompiled from factorio-arm64 (Space Age 2.0).
// Functions: 8

// ===== 0x10226c098 VoronoiPoints =====

/* WARNING: Type propagation algorithm not settling */
/* NoiseOperations::VoronoiPoints::VoronoiPoints(NoiseOperations::VoronoiNoise const&, RegionBounds
   const&, unsigned int) */

VoronoiPoints * __thiscall
NoiseOperations::VoronoiPoints::VoronoiPoints
          (VoronoiPoints *this,VoronoiNoise *param_1,RegionBounds *param_2,uint param_3)

{
  ulong uVar1;
  uint uVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  byte bVar7;
  int iVar8;
  uint7 uVar9;
  uint7 uVar10;
  undefined4 uVar11;
  code *pcVar12;
  void *pvVar13;
  int iVar14;
  int iVar15;
  VoronoiPoints *pVVar16;
  long lVar17;
  undefined8 *puVar18;
  int iVar19;
  long lVar20;
  undefined8 *puVar21;
  undefined8 *puVar22;
  ulong uVar23;
  undefined8 *puVar24;
  undefined8 *puVar25;
  undefined8 *puVar26;
  float fVar27;
  float fVar28;
  int iVar29;
  int iVar30;
  byte bVar33;
  int iVar32;
  undefined1 auVar31 [16];
  int iVar34;
  int iVar35;
  undefined8 uVar36;
  
  fVar27 = (float)NEON_ucvtf((uint)*(ushort *)(param_1 + 0x24));
  fVar28 = (float)(int)(*(float *)param_2 / fVar27);
  if (NAN(fVar28)) {
    iVar14 = 0;
    fVar28 = *(float *)(param_2 + 4);
  }
  else if (2.1474836e+09 <= fVar28) {
    iVar14 = 0x7fffffff;
    fVar28 = *(float *)(param_2 + 4);
  }
  else if (fVar28 <= -2.1474836e+09) {
    iVar14 = -0x80000000;
    fVar28 = *(float *)(param_2 + 4);
  }
  else {
    iVar14 = (int)fVar28;
    fVar28 = *(float *)(param_2 + 4);
  }
  uVar11 = (undefined4)(fVar28 / fVar27);
  if (NAN((float)uVar11)) {
    iVar15 = 0;
  }
  else {
    iVar19 = -0x80000000;
    if (-2.1474836e+09 < (float)uVar11) {
      iVar19 = (int)(float)uVar11;
    }
    iVar15 = 0x7fffffff;
    if ((float)uVar11 < 2.1474836e+09) {
      iVar15 = iVar19;
    }
  }
  iVar14 = iVar14 - param_3;
  uVar6 = iVar15 - param_3;
  *(ulong *)this = CONCAT44(uVar6,iVar14);
  pVVar16 = this + 0x10;
  *(ulong *)pVVar16 = 0;
  *(undefined8 *)(this + 0x18) = 0;
  *(undefined8 *)(this + 0x20) = 0;
  fVar27 = (float)NEON_ucvtf((uint)*(ushort *)(param_1 + 0x24));
  fVar28 = (float)(int)(*(float *)(param_2 + 8) / fVar27);
  if (NAN(fVar28)) {
    iVar15 = 0;
    fVar28 = *(float *)(param_2 + 0xc);
  }
  else if (2.1474836e+09 <= fVar28) {
    iVar15 = 0x7fffffff;
    fVar28 = *(float *)(param_2 + 0xc);
  }
  else if (-2.1474836e+09 < fVar28) {
    iVar15 = (int)fVar28;
    fVar28 = *(float *)(param_2 + 0xc);
  }
  else {
    iVar15 = -0x80000000;
    fVar28 = *(float *)(param_2 + 0xc);
  }
  fVar27 = (float)(int)(fVar28 / fVar27);
  if (NAN(fVar27)) {
    iVar19 = 0;
  }
  else if (2.1474836e+09 <= fVar27) {
    iVar19 = 0x7fffffff;
  }
  else if (fVar27 <= -2.1474836e+09) {
    iVar19 = -0x80000000;
  }
  else {
    iVar19 = (int)fVar27;
  }
  iVar15 = iVar15 + param_3;
  iVar29 = (iVar15 - iVar14) + 1;
  *(int *)(this + 8) = iVar29;
  iVar19 = iVar19 + param_3;
  iVar29 = (iVar19 - uVar6) * iVar29;
  if (iVar29 != 0) {
    if (iVar29 < 0) {
      std::
      vector<NoiseOperations::VoronoiPoints::Point,std::allocator<NoiseOperations::VoronoiPoints::Point>>
      ::__throw_length_error_abi_v160006_();
LAB_10226c650:
                    /* WARNING: Does not return */
      pcVar12 = (code *)SoftwareBreakpoint(1,0x10226c654);
      (*pcVar12)();
    }
    pvVar13 = operator_new((long)iVar29 * 0xc);
    *(void **)(this + 0x10) = pvVar13;
    *(void **)(this + 0x18) = pvVar13;
    *(void **)(this + 0x20) = (void *)((long)pvVar13 + (long)iVar29 * 0xc);
  }
  if (((int)uVar6 <= iVar19) && (iVar14 <= iVar15)) {
    do {
      iVar14 = *(int *)this;
      if (iVar14 <= iVar15) {
        uVar5 = *(uint *)(param_1 + 0x20);
        uVar2 = (uVar6 >> 0x10 | uVar6 << 0x10) * 0x1001 + 0x7ed55d16;
        iVar29 = (uVar2 ^ uVar2 >> 0x13 ^ 0xc761c23c) * 0x21;
        uVar2 = (iVar29 + 0xe9f8cc1dU ^ (iVar29 + 0x165667b1) * 0x200) * 9 + 0xfd7046c5;
        do {
          uVar3 = iVar14 * 0x1001 + 0x7ed55d16;
          iVar29 = (uVar3 ^ uVar3 >> 0x13 ^ 0xc761c23c) * 0x21;
          uVar3 = (iVar29 + 0xe9f8cc1dU ^ (iVar29 + 0x165667b1) * 0x200) * 9 + 0xfd7046c5;
          uVar4 = uVar5 ^ uVar2 >> 0x10 ^ uVar3 >> 0x10 ^ uVar2 ^ uVar3;
          uVar3 = uVar4 * 0x1001 + 0x7ed55d16;
          iVar29 = (uVar3 ^ uVar3 >> 0x13 ^ 0xc761c23c) * 0x21;
          iVar8 = uVar4 * 0x1001;
          uVar3 = iVar8 + 0x7ed56d17;
          iVar30 = (uVar3 ^ uVar3 >> 0x13 ^ 0xc761c23c) * 0x21;
          fVar27 = *(float *)(param_1 + 0x28);
          iVar34 = iVar29 + -0x160733e3;
          iVar35 = iVar30 + -0x160733e3;
          iVar29 = (iVar29 + 0x165667b1) * 0x200;
          iVar32 = (iVar30 + 0x165667b1) * 0x200;
          iVar29 = CONCAT13((byte)((uint)iVar34 >> 0x18) ^ (byte)((uint)iVar29 >> 0x18),
                            CONCAT12((byte)((uint)iVar34 >> 0x10) ^ (byte)((uint)iVar29 >> 0x10),
                                     CONCAT11((byte)((uint)iVar34 >> 8) ^ (byte)((uint)iVar29 >> 8),
                                              (char)iVar34)));
          iVar30 = iVar29 * 9 + -0x28fb93b;
          iVar29 = (int)(CONCAT17((byte)((uint)iVar35 >> 0x18) ^ (byte)((uint)iVar32 >> 0x18),
                                  CONCAT16((byte)((uint)iVar35 >> 0x10) ^
                                           (byte)((uint)iVar32 >> 0x10),
                                           CONCAT15((byte)((uint)iVar35 >> 8) ^
                                                    (byte)((uint)iVar32 >> 8),
                                                    CONCAT14((char)iVar35,iVar29)))) >> 0x20) * 9 +
                   -0x28fb93b;
          bVar33 = (byte)((uint)iVar29 >> 0x10);
          bVar7 = (byte)((uint)iVar29 >> 0x18);
          uVar9 = CONCAT16(bVar33,CONCAT15((char)((uint)iVar29 >> 8),CONCAT14((char)iVar29,iVar30)))
          ;
          uVar10 = uVar9 ^ 0xb55a4f09;
          uVar9 = uVar9 ^ 0x4f09b55a4f09;
          uVar9 = CONCAT16(bVar33,CONCAT15((byte)(uVar9 >> 0x28) ^ bVar7,
                                           CONCAT14((byte)(uVar9 >> 0x20) ^ bVar33,
                                                    CONCAT13((char)(uVar10 >> 0x18),
                                                             CONCAT12((char)(uVar10 >> 0x10),
                                                                      CONCAT11((byte)(uVar10 >> 8) ^
                                                                               (byte)((uint)iVar30
                                                                                     >> 0x18),
                                                                               (byte)iVar30 ^ 9 ^
                                                                               (byte)((uint)iVar30
                                                                                     >> 0x10)))))));
          auVar31._0_8_ = (ulong)uVar9 & 0xffffffff;
          auVar31._8_4_ = (uint)(CONCAT17(bVar7,uVar9) >> 0x20) ^ 0xb55a0000;
          auVar31._12_4_ = 0;
          auVar31 = NEON_ucvtf(auVar31,8);
          fVar28 = (1.0 - fVar27) * 0.5;
          uVar36 = CONCAT44((float)(auVar31._8_8_ * 2.3283064365386963e-10) * fVar27 + fVar28,
                            (float)(auVar31._0_8_ * 2.3283064365386963e-10) * fVar27 + fVar28);
          uVar3 = iVar8 + 0x7ed57d18;
          iVar29 = (uVar3 ^ uVar3 >> 0x13 ^ 0xc761c23c) * 0x21;
          uVar3 = (iVar29 + 0xe9f8cc1dU ^ (iVar29 + 0x165667b1) * 0x200) * 9 + 0xfd7046c5;
          fVar27 = (float)((double)(uVar3 ^ uVar3 >> 0x10 ^ 0xb55a4f09) * 2.3283064365386963e-10);
          puVar25 = *(undefined8 **)(this + 0x18);
          if (puVar25 < *(undefined8 **)(this + 0x20)) {
            *puVar25 = uVar36;
            *(float *)(puVar25 + 1) = fVar27;
            *(ulong *)(this + 0x18) = (long)puVar25 + 0xc;
          }
          else {
            puVar26 = *(undefined8 **)pVVar16;
            lVar20 = (long)puVar25 - (long)puVar26 >> 2;
            uVar1 = lVar20 * -0x5555555555555555 + 1;
            if (0x1555555555555555 < uVar1) {
              std::
              vector<NoiseOperations::VoronoiPoints::Point,std::allocator<NoiseOperations::VoronoiPoints::Point>>
              ::__throw_length_error_abi_v160006_();
              goto LAB_10226c650;
            }
            lVar17 = (long)*(undefined8 **)(this + 0x20) - (long)puVar26 >> 2;
            uVar23 = lVar17 * 0x5555555555555556;
            if (uVar23 < uVar1 || uVar23 - uVar1 == 0) {
              uVar23 = uVar1;
            }
            if (0xaaaaaaaaaaaaaa9 < (ulong)(lVar17 * -0x5555555555555555)) {
              uVar23 = 0x1555555555555555;
            }
            if (uVar23 == 0) {
              pvVar13 = (void *)0x0;
            }
            else {
              if (0x1555555555555555 < uVar23) {
                    /* WARNING: Subroutine does not return */
                std::__throw_bad_array_new_length_abi_v160006_();
              }
              pvVar13 = operator_new(uVar23 * 0xc);
            }
            puVar18 = (undefined8 *)((long)pvVar13 + lVar20 * 4);
            *puVar18 = uVar36;
            *(float *)(puVar18 + 1) = fVar27;
            puVar21 = puVar18;
            puVar22 = puVar18;
            if (puVar25 != puVar26) {
              do {
                puVar24 = (undefined8 *)((long)puVar25 - 0xc);
                uVar11 = *(undefined4 *)((long)puVar25 - 4);
                puVar22 = (undefined8 *)((long)puVar21 + -0xc);
                *puVar22 = *puVar24;
                *(undefined4 *)((long)puVar21 + -4) = uVar11;
                puVar21 = puVar22;
                puVar25 = puVar24;
              } while (puVar24 != puVar26);
              puVar25 = *(undefined8 **)pVVar16;
            }
            *(undefined8 **)(this + 0x10) = puVar22;
            *(long *)(this + 0x18) = (long)puVar18 + 0xc;
            *(void **)(this + 0x20) = (void *)((long)pvVar13 + uVar23 * 0xc);
            if (puVar25 != (undefined8 *)0x0) {
              operator_delete(puVar25);
            }
          }
          iVar14 = iVar14 + 1;
        } while (iVar14 <= iVar15);
      }
      uVar6 = uVar6 + 1;
    } while ((int)uVar6 <= iVar19);
  }
  return this;
}



// ===== 0x10161290c parseDistanceType =====

/* NoiseOperations::VoronoiNoise::parseDistanceType(NoiseExpressionConstant const&) */

uint NoiseOperations::VoronoiNoise::parseDistanceType(NoiseExpressionConstant *param_1)

{
  string *psVar1;
  ulong uVar2;
  NoiseExpressionConstant NVar3;
  int iVar4;
  RuntimeError *this;
  undefined8 uVar5;
  uint uVar6;
  string *psVar7;
  double dVar8;
  string asStack_48 [24];
  
  if (*param_1 == (NoiseExpressionConstant)0x3) {
    psVar7 = (string *)(param_1 + 8);
    NVar3 = param_1[0x1f];
    psVar1 = *(string **)psVar7;
    if (-1 < (char)NVar3) {
      psVar1 = psVar7;
    }
    uVar2 = *(ulong *)(param_1 + 0x10);
    if (-1 < (char)NVar3) {
      uVar2 = (ulong)(byte)NVar3;
    }
    if (uVar2 == 10) {
      iVar4 = _memcmp(psVar1,"minkowski3",10);
      if (iVar4 == 0) {
        return 3;
      }
    }
    else if (uVar2 == 9) {
      if (*(long *)psVar1 == 0x6568737962656863 && psVar1[8] == (string)0x76) {
        return 0;
      }
      if (*(long *)psVar1 == 0x61747461686e616d && psVar1[8] == (string)0x6e) {
        return 1;
      }
      if (*(long *)psVar1 == 0x616564696c637565 && psVar1[8] == (string)0x6e) {
        return 2;
      }
    }
    this = (RuntimeError *)___cxa_allocate_exception(0x10);
    std::operator+("Invalid distance: ",psVar7);
    RuntimeError::RuntimeError(this,asStack_48);
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(this,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  if (*param_1 != (NoiseExpressionConstant)0x1) {
    uVar5 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError((char *)param_1,"distance_type");
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(uVar5,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  dVar8 = *(double *)(param_1 + 8);
  if (!NAN(dVar8)) {
    if (255.0 <= dVar8) {
      uVar6 = 0xff;
      goto LAB_101612a54;
    }
    if (0.0 < dVar8) {
      uVar6 = (uint)dVar8;
      goto LAB_101612a54;
    }
  }
  uVar6 = 0;
LAB_101612a54:
  if (2 < uVar6) {
    uVar6 = 3;
  }
  return uVar6;
}



// ===== 0x101612f98 run =====

/* NoiseOperations::VoronoiNoise::run(NoiseCache&) const */

void __thiscall NoiseOperations::VoronoiNoise::run(VoronoiNoise *this,NoiseCache *param_1)

{
  switch(this[0x26]) {
  case (VoronoiNoise)0x0:
    runInternal<(NoiseOperations::VoronoiNoise::DistanceType)0>(this,param_1);
    return;
  case (VoronoiNoise)0x1:
    runInternal<(NoiseOperations::VoronoiNoise::DistanceType)1>(this,param_1);
    return;
  case (VoronoiNoise)0x2:
    runInternal<(NoiseOperations::VoronoiNoise::DistanceType)2>(this,param_1);
    return;
  case (VoronoiNoise)0x3:
    runInternal<(NoiseOperations::VoronoiNoise::DistanceType)3>(this,param_1);
    return;
  default:
    return;
  }
}



// ===== 0x101612fd0 runInternal<(NoiseOperations::VoronoiNoise::DistanceType)0> =====

/* WARNING: Type propagation algorithm not settling */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* void 
   NoiseOperations::VoronoiNoise::runInternal<(NoiseOperations::VoronoiNoise::DistanceType)0>(NoiseCache&)
   const */

void __thiscall
NoiseOperations::VoronoiNoise::runInternal<(NoiseOperations::VoronoiNoise::DistanceType)0>
          (VoronoiNoise *this,NoiseCache *param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  bool bVar4;
  long lVar5;
  long lVar6;
  long lVar7;
  long lVar8;
  long lVar9;
  long lVar10;
  float *pfVar11;
  float *pfVar12;
  int iVar13;
  int iVar14;
  long lVar15;
  long lVar16;
  ulong uVar17;
  ulong uVar18;
  uint uVar19;
  long lVar20;
  uint uVar21;
  uint uVar22;
  uint uVar23;
  uint uVar24;
  int iVar25;
  uint uVar26;
  float fVar27;
  ulong uVar28;
  undefined8 uVar29;
  undefined8 uVar30;
  float fVar31;
  float fVar32;
  float fVar33;
  float fVar34;
  float fVar35;
  float fVar36;
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
  float local_110;
  float fStack_10c;
  ulong local_108;
  uint local_100;
  uint local_fc;
  int iStack_f8;
  void *local_f0;
  void *local_e8;
  undefined8 local_d8;
  undefined8 local_d0;
  float local_c8;
  float fStack_c4;
  float local_c0;
  float fStack_bc;
  float local_b8;
  float fStack_b4;
  float local_b0;
  float fStack_ac;
  
  if (*(int *)(this + 8) == -1) {
    lVar5 = 0;
    iVar13 = *(int *)(this + 0xc);
  }
  else {
    lVar5 = NoiseCache::getFloatRegister(param_1);
    iVar13 = *(int *)(this + 0xc);
  }
  if (iVar13 == -1) {
    lVar6 = 0;
    iVar13 = *(int *)(this + 0x10);
  }
  else {
    lVar6 = NoiseCache::getFloatRegister(param_1);
    iVar13 = *(int *)(this + 0x10);
  }
  if (iVar13 == -1) {
    lVar7 = 0;
    iVar13 = *(int *)(this + 0x14);
  }
  else {
    lVar7 = NoiseCache::getFloatRegister(param_1);
    iVar13 = *(int *)(this + 0x14);
  }
  if (iVar13 == -1) {
    lVar8 = 0;
  }
  else {
    lVar8 = NoiseCache::getFloatRegister(param_1);
  }
  lVar9 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x18));
  lVar10 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x1c));
  if ((this[0x26] != (VoronoiNoise)0x0) || (uVar22 = 2, *(float *)(this + 0x28) <= 0.25)) {
    uVar21 = 2;
    if (*(float *)(this + 0x28) <= 0.5) {
      uVar21 = 1;
    }
    uVar22 = 1;
    if (this[0x26] == (VoronoiNoise)0x1) {
      uVar22 = uVar21;
    }
  }
  iVar13 = *(int *)(this + 0x1c);
  if (((iVar13 == 1) && (*(int *)(this + 0x18) == 0)) && (param_1[0x28] != (NoiseCache)0x0)) {
    uVar28 = *(ulong *)(param_1 + 0x2c);
    uVar30 = NEON_ucvtf(CONCAT44((int)((ulong)*(undefined8 *)(param_1 + 0x34) >> 0x20) + -1,
                                 (int)*(undefined8 *)(param_1 + 0x34) + -1),4);
    fStack_10c = (float)(uVar28 >> 0x20);
    local_108 = CONCAT44(fStack_10c +
                         (float)((ulong)uVar30 >> 0x20) * (float)*(undefined8 *)(param_1 + 0x3c),
                         (float)uVar28 + (float)uVar30 * (float)*(undefined8 *)(param_1 + 0x3c));
  }
  else {
    pfVar12 = (float *)NoiseCache::getFloatRegister(param_1);
    pfVar11 = (float *)NoiseCache::getFloatRegister(param_1,iVar13);
    lVar15 = *(long *)(param_1 + 0x10);
    if (lVar15 == 0) {
      local_108 = 0xff800000ff800000;
      uVar28 = 0x7f800000;
      fStack_10c = INFINITY;
    }
    else {
      local_108 = 0xff800000ff800000;
      fStack_10c = INFINITY;
      uVar17 = 0x7f800000;
      do {
        fVar27 = *pfVar12;
        uVar28 = (ulong)(uint)fVar27;
        if ((float)uVar17 <= fVar27) {
          uVar28 = uVar17;
        }
        fVar34 = *pfVar11;
        fVar33 = fVar34;
        if (fStack_10c <= fVar34) {
          fVar33 = fStack_10c;
        }
        fStack_10c = fVar33;
        local_108 = local_108 ^
                    (local_108 ^ CONCAT44(fVar34,fVar27)) &
                    CONCAT44(-(uint)((float)(local_108 >> 0x20) < fVar34),
                             -(uint)((float)local_108 < fVar27));
        lVar15 = lVar15 + -1;
        pfVar11 = pfVar11 + 1;
        pfVar12 = pfVar12 + 1;
        uVar17 = uVar28;
      } while (lVar15 != 0);
    }
  }
  local_110 = (float)uVar28;
  VoronoiPoints::VoronoiPoints((VoronoiPoints *)&local_100,this,(RegionBounds *)&local_110,uVar22);
  uVar30 = ram0x000102973648;
  lVar15 = *(long *)(param_1 + 0x10);
  if (lVar15 != 0) {
    lVar16 = 0;
    fVar27 = (float)NEON_ucvtf((uint)*(ushort *)(this + 0x24));
    uVar21 = -uVar22;
    uVar29 = NEON_fmov(0xbf800000,4);
    do {
      lVar20 = lVar16 * 4;
      fVar33 = *(float *)(lVar9 + lVar20) / fVar27;
      fVar34 = (float)(int)fVar33;
      if (NAN(fVar34)) {
        iVar13 = 0;
        fVar34 = *(float *)(lVar10 + lVar20) / fVar27;
        fVar36 = (float)(int)fVar34;
        if (NAN(fVar36)) goto LAB_10161397c;
LAB_1016132f0:
        if (2.1474836e+09 <= fVar36) {
          iVar14 = 0x7fffffff;
        }
        else if (fVar36 <= -2.1474836e+09) {
          iVar14 = -0x80000000;
        }
        else {
          iVar14 = (int)fVar36;
        }
      }
      else {
        if (2.1474836e+09 <= fVar34) {
          iVar13 = 0x7fffffff;
          fVar34 = *(float *)(lVar10 + lVar20);
        }
        else if (fVar34 <= -2.1474836e+09) {
          iVar13 = -0x80000000;
          fVar34 = *(float *)(lVar10 + lVar20);
        }
        else {
          iVar13 = (int)fVar34;
          fVar34 = *(float *)(lVar10 + lVar20);
        }
        fVar34 = fVar34 / fVar27;
        fVar36 = (float)(int)fVar34;
        if (!NAN(fVar36)) goto LAB_1016132f0;
LAB_10161397c:
        iVar14 = 0;
      }
      iVar25 = (iVar14 + ~local_fc) * iStack_f8;
      iVar2 = iVar13 + ~local_100;
      pfVar11 = (float *)((long)local_f0 + (long)(iVar2 + iVar25) * 0xc);
      iVar3 = iVar13 - local_100;
      pfVar12 = (float *)((long)local_f0 + (long)(iVar3 + iVar25) * 0xc);
      fVar33 = fVar33 - (float)iVar13;
      fVar34 = fVar34 - (float)iVar14;
      fVar35 = ABS((*pfVar12 + (float)uVar30) - fVar33);
      fVar36 = ABS((*pfVar11 + (float)((ulong)uVar30 >> 0x20)) - fVar33);
      fVar37 = ABS((pfVar12[1] + (float)uVar29) - fVar34);
      fVar38 = ABS((pfVar11[1] + (float)((ulong)uVar29 >> 0x20)) - fVar34);
      if (fVar36 <= fVar38) {
        fVar36 = fVar38;
      }
      bVar4 = fVar36 < 3.4028235e+38;
      if (!bVar4) {
        fVar36 = 3.4028235e+38;
      }
      uVar23 = -(uint)bVar4;
      if (fVar35 <= fVar37) {
        fVar35 = fVar37;
      }
      if (fVar36 <= fVar35) {
        fVar37 = 3.4028235e+38;
        uVar24 = uVar23;
        if (fVar35 < 3.4028235e+38) {
          fVar37 = fVar35;
        }
      }
      else {
        uVar23 = 0xffffffff;
        fVar37 = fVar36;
        fVar36 = fVar35;
        uVar24 = 0;
      }
      iVar1 = iVar3 + 1;
      pfVar11 = (float *)((long)local_f0 + (long)(iVar1 + iVar25) * 0xc);
      fVar35 = ABS((*pfVar11 + 1.0) - fVar33);
      fVar38 = ABS((pfVar11[1] + -1.0) - fVar34);
      if (fVar35 <= fVar38) {
        fVar35 = fVar38;
      }
      if (fVar36 <= fVar35) {
        if (fVar35 < fVar37) {
          fVar37 = fVar35;
        }
      }
      else {
        uVar24 = 1;
        uVar23 = 0xffffffff;
        fVar37 = fVar36;
        fVar36 = fVar35;
      }
      iVar25 = (iVar14 - local_fc) * iStack_f8;
      pfVar11 = (float *)((long)local_f0 + (long)(iVar2 + iVar25) * 0xc);
      fVar35 = ABS((*pfVar11 + -1.0) - fVar33);
      fVar38 = ABS((pfVar11[1] + 0.0) - fVar34);
      if (fVar35 <= fVar38) {
        fVar35 = fVar38;
      }
      if (fVar36 <= fVar35) {
        if (fVar35 < fVar37) {
          fVar37 = fVar35;
        }
      }
      else {
        uVar23 = 0;
        uVar24 = 0xffffffff;
        fVar37 = fVar36;
        fVar36 = fVar35;
      }
      pfVar11 = (float *)((long)local_f0 + (long)(iVar3 + iVar25) * 0xc);
      fVar35 = ABS((*pfVar11 + 0.0) - fVar33);
      fVar38 = ABS((pfVar11[1] + 0.0) - fVar34);
      if (fVar35 <= fVar38) {
        fVar35 = fVar38;
      }
      if (fVar36 <= fVar35) {
        if (fVar35 < fVar37) {
          fVar37 = fVar35;
        }
      }
      else {
        uVar23 = 0;
        uVar24 = 0;
        fVar37 = fVar36;
        fVar36 = fVar35;
      }
      pfVar11 = (float *)((long)local_f0 + (long)(iVar1 + iVar25) * 0xc);
      fVar35 = ABS((*pfVar11 + 1.0) - fVar33);
      fVar38 = ABS((pfVar11[1] + 0.0) - fVar34);
      if (fVar35 <= fVar38) {
        fVar35 = fVar38;
      }
      if (fVar36 <= fVar35) {
        if (fVar35 < fVar37) {
          fVar37 = fVar35;
        }
      }
      else {
        uVar23 = 0;
        uVar24 = 1;
        fVar37 = fVar36;
        fVar36 = fVar35;
      }
      iVar25 = iStack_f8 + iStack_f8 * (iVar14 - local_fc);
      pfVar11 = (float *)((long)local_f0 + (long)(iVar2 + iVar25) * 0xc);
      fVar35 = ABS((*pfVar11 + -1.0) - fVar33);
      fVar38 = ABS((pfVar11[1] + 1.0) - fVar34);
      if (fVar35 <= fVar38) {
        fVar35 = fVar38;
      }
      if (fVar36 <= fVar35) {
        if (fVar35 < fVar37) {
          fVar37 = fVar35;
        }
      }
      else {
        uVar24 = 0xffffffff;
        uVar23 = 1;
        fVar37 = fVar36;
        fVar36 = fVar35;
      }
      pfVar11 = (float *)((long)local_f0 + (long)(iVar3 + iVar25) * 0xc);
      fVar35 = ABS((*pfVar11 + 0.0) - fVar33);
      fVar38 = ABS((pfVar11[1] + 1.0) - fVar34);
      if (fVar35 <= fVar38) {
        fVar35 = fVar38;
      }
      if (fVar36 <= fVar35) {
        if (fVar35 < fVar37) {
          fVar37 = fVar35;
        }
      }
      else {
        uVar24 = 0;
        uVar23 = 1;
        fVar37 = fVar36;
        fVar36 = fVar35;
      }
      pfVar11 = (float *)((long)local_f0 + (long)(iVar1 + iVar25) * 0xc);
      fVar35 = ABS((*pfVar11 + 1.0) - fVar33);
      fVar38 = ABS((pfVar11[1] + 1.0) - fVar34);
      if (fVar35 <= fVar38) {
        fVar35 = fVar38;
      }
      if (fVar36 <= fVar35) {
        if (fVar35 < fVar37) {
          fVar37 = fVar35;
        }
      }
      else {
        uVar23 = 1;
        uVar24 = 1;
        fVar37 = fVar36;
        fVar36 = fVar35;
      }
      if (lVar5 != 0) {
        *(float *)(lVar5 + lVar16 * 4) = fVar36;
      }
      if (lVar6 != 0) {
        *(float *)(lVar6 + lVar16 * 4) = fVar37 - fVar36;
      }
      if (lVar7 != 0) {
        pfVar11 = (float *)((long)local_f0 +
                           (long)(int)(((uVar24 + iVar13) - local_100) +
                                      ((uVar23 + iVar14) - local_fc) * iStack_f8) * 0xc);
        fVar36 = (fVar33 - ((*pfVar11 + (float)(int)uVar24) - fVar33)) * 0.75;
        fVar37 = (fVar34 - ((pfVar11[1] + (float)(int)uVar23) - fVar34)) * 0.75;
        fVar35 = fVar36 + fVar37;
        fVar37 = fVar37 - fVar36;
        fVar38 = fVar33 * 0.75 + fVar34 * 0.75;
        fVar39 = fVar34 * 0.75 - fVar33 * 0.75;
        iVar2 = (uVar21 - local_100) + iVar13 + iStack_f8 * ((uVar21 - local_fc) + iVar14);
        fVar36 = 3.4028235e+38;
        uVar26 = uVar21;
        do {
          lVar20 = (ulong)uVar22 + (long)(int)uVar24;
          uVar28 = (ulong)uVar22 << 1 | 1;
          uVar19 = uVar21;
          iVar25 = iVar2;
          do {
            if ((lVar20 != 0) || (uVar26 != uVar23)) {
              pfVar11 = (float *)((long)local_f0 + (long)iVar25 * 0xc);
              fVar40 = (fVar33 - ((*pfVar11 + (float)(int)uVar19) - fVar33)) * 0.75;
              fStack_ac = (fVar34 - ((pfVar11[1] + (float)(int)uVar26) - fVar34)) * 0.75;
              local_b0 = fVar40 + fStack_ac;
              fStack_ac = fStack_ac - fVar40;
              local_c0 = (fVar35 + local_b0) * 0.5;
              fStack_bc = (fVar37 + fStack_ac) * 0.5;
              fVar40 = fVar35;
              if (local_b0 <= fVar35) {
                fVar40 = local_b0;
              }
              local_c8 = fVar35;
              if (fVar35 <= local_b0) {
                local_c8 = local_b0;
              }
              fVar41 = fVar37;
              if (fStack_ac <= fVar37) {
                fVar41 = fStack_ac;
              }
              fStack_c4 = fVar37;
              if (fVar37 <= fStack_ac) {
                fStack_c4 = fStack_ac;
              }
              fVar43 = (fVar40 - local_c8) * (fVar40 - local_c8);
              fVar41 = (fVar41 - fStack_c4) * (fVar41 - fStack_c4);
              fVar40 = fVar43;
              if (fVar43 <= fVar41) {
                fVar40 = fVar41;
              }
              uVar17 = (ulong)(fVar40 == fVar43);
              uVar18 = (ulong)(fVar40 != fVar43);
              fVar44 = *(float *)((ulong)&local_b0 | uVar18 << 2);
              fVar45 = *(float *)((ulong)&local_110 | uVar18 << 2);
              fVar46 = *(float *)((ulong)&local_c0 | uVar17 << 2);
              fVar41 = ABS(*(float *)((ulong)&local_110 | uVar17 << 2) - fVar46);
              local_d0 = CONCAT44(fVar37,fVar35);
              fVar31 = *(float *)((ulong)&local_c0 | uVar18 << 2);
              if (fVar44 <= fVar45) {
                fVar41 = -fVar41;
              }
              *(float *)((ulong)&local_d0 | uVar18 << 2) = fVar31 + fVar41;
              fVar46 = ABS(*(float *)((ulong)&local_b0 | uVar17 << 2) - fVar46);
              fVar41 = -fVar46;
              if (fVar44 <= fVar45) {
                fVar41 = fVar46;
              }
              fVar45 = *(float *)((ulong)&local_d0 | uVar17 << 2);
              fVar44 = 1.0;
              if (fVar45 != *(float *)((ulong)&local_c8 | uVar17 << 2)) {
                fVar44 = -1.0;
              }
              local_d8 = CONCAT44(fStack_ac,local_b0);
              *(float *)((ulong)&local_d8 | uVar18 << 2) = fVar31 + fVar41;
              fVar42 = *(float *)((ulong)&local_b8 | uVar17 << 2);
              fVar31 = local_b0 - fVar35;
              fVar46 = fStack_ac - fVar37;
              fVar41 = fVar44;
              if (fVar40 == fVar43) {
                fVar41 = 0.0;
              }
              fVar32 = 0.0;
              if (fVar40 == fVar43) {
                fVar32 = fVar44;
              }
              fVar40 = (fVar31 * (fVar38 - fVar35) + fVar46 * (fVar39 - fVar37)) /
                       (fVar31 * fVar31 + fVar46 * fVar46);
              fVar43 = -(fVar44 * (fVar42 - *(float *)((ulong)&local_d8 | uVar17 << 2)));
              fVar44 = fVar44 * (fVar42 - fVar45);
              if (fVar40 <= 0.0) {
                fVar40 = 0.0;
              }
              fVar40 = (float)NEON_fminnm(fVar40,0x3f800000);
              if (fVar44 <= 0.0) {
                fVar44 = 0.0;
              }
              if (fVar43 <= 0.0) {
                fVar43 = 0.0;
              }
              fVar31 = (fVar35 + fVar31 * fVar40) - fVar38;
              fVar40 = (fVar37 + fVar46 * fVar40) - fVar39;
              fVar40 = fVar31 * fVar31 + fVar40 * fVar40;
              fVar45 = (fVar35 + fVar41 * fVar44) - fVar38;
              fVar31 = (fVar37 + fVar32 * fVar44) - fVar39;
              fVar31 = fVar45 * fVar45 + fVar31 * fVar31;
              fVar44 = (local_b0 - fVar41 * fVar43) - fVar38;
              fVar41 = (fStack_ac - fVar32 * fVar43) - fVar39;
              fVar41 = fVar44 * fVar44 + fVar41 * fVar41;
              if (fVar41 <= fVar31) {
                fVar31 = fVar41;
              }
              if (fVar31 <= fVar40) {
                fVar40 = fVar31;
              }
              local_110 = fVar35;
              fStack_10c = fVar37;
              local_b8 = fVar38;
              fStack_b4 = fVar39;
              if (SQRT(fVar40) <= fVar36) {
                fVar36 = SQRT(fVar40);
              }
            }
            lVar20 = lVar20 + -1;
            iVar25 = iVar25 + 1;
            uVar19 = uVar19 + 1;
            uVar28 = uVar28 - 1;
          } while (uVar28 != 0);
          iVar2 = iVar2 + iStack_f8;
          bVar4 = uVar26 != uVar22;
          uVar26 = uVar26 + 1;
        } while (bVar4);
        *(float *)(lVar7 + lVar16 * 4) = fVar36;
      }
      if (lVar8 != 0) {
        *(undefined4 *)(lVar8 + lVar16 * 4) =
             *(undefined4 *)
              ((long)local_f0 +
              (long)(int)(((uVar24 + iVar13) - local_100) +
                         ((uVar23 + iVar14) - local_fc) * iStack_f8) * 0xc + 8);
      }
      lVar16 = lVar16 + 1;
    } while (lVar16 != lVar15);
  }
  if (local_f0 != (void *)0x0) {
    local_e8 = local_f0;
    operator_delete(local_f0);
  }
  return;
}



// ===== 0x1016139c4 runInternal<(NoiseOperations::VoronoiNoise::DistanceType)1> =====

/* WARNING: Type propagation algorithm not settling */
/* void 
   NoiseOperations::VoronoiNoise::runInternal<(NoiseOperations::VoronoiNoise::DistanceType)1>(NoiseCache&)
   const */

void __thiscall
NoiseOperations::VoronoiNoise::runInternal<(NoiseOperations::VoronoiNoise::DistanceType)1>
          (VoronoiNoise *this,NoiseCache *param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  bool bVar4;
  int iVar5;
  long lVar6;
  long lVar7;
  long lVar8;
  long lVar9;
  long lVar10;
  long lVar11;
  float *pfVar12;
  float *pfVar13;
  int iVar14;
  int iVar15;
  long lVar16;
  long lVar17;
  ulong uVar18;
  ulong uVar19;
  uint uVar20;
  long lVar21;
  uint uVar22;
  uint uVar23;
  uint uVar24;
  uint uVar25;
  uint uVar26;
  float fVar27;
  ulong uVar28;
  undefined8 uVar29;
  float fVar30;
  float fVar31;
  float fVar32;
  float fVar33;
  float fVar34;
  float fVar35;
  float fVar36;
  float fVar37;
  float fVar38;
  float fVar39;
  float fVar40;
  float fVar41;
  float fVar42;
  float fVar43;
  float local_f0;
  float fStack_ec;
  ulong local_e8;
  uint local_e0;
  uint local_dc;
  int iStack_d8;
  void *local_d0;
  void *local_c8;
  undefined8 local_b8;
  undefined8 local_b0;
  float local_a8;
  float fStack_a4;
  float local_a0;
  float fStack_9c;
  float local_98;
  float fStack_94;
  float local_90;
  float fStack_8c;
  
  if (*(int *)(this + 8) == -1) {
    lVar6 = 0;
    iVar14 = *(int *)(this + 0xc);
  }
  else {
    lVar6 = NoiseCache::getFloatRegister(param_1);
    iVar14 = *(int *)(this + 0xc);
  }
  if (iVar14 == -1) {
    lVar7 = 0;
    iVar14 = *(int *)(this + 0x10);
  }
  else {
    lVar7 = NoiseCache::getFloatRegister(param_1);
    iVar14 = *(int *)(this + 0x10);
  }
  if (iVar14 == -1) {
    lVar8 = 0;
    iVar14 = *(int *)(this + 0x14);
  }
  else {
    lVar8 = NoiseCache::getFloatRegister(param_1);
    iVar14 = *(int *)(this + 0x14);
  }
  if (iVar14 == -1) {
    lVar9 = 0;
  }
  else {
    lVar9 = NoiseCache::getFloatRegister(param_1);
  }
  lVar10 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x18));
  lVar11 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x1c));
  if ((this[0x26] != (VoronoiNoise)0x0) || (uVar23 = 2, *(float *)(this + 0x28) <= 0.25)) {
    uVar22 = 2;
    if (*(float *)(this + 0x28) <= 0.5) {
      uVar22 = 1;
    }
    uVar23 = 1;
    if (this[0x26] == (VoronoiNoise)0x1) {
      uVar23 = uVar22;
    }
  }
  iVar14 = *(int *)(this + 0x1c);
  if (((iVar14 == 1) && (*(int *)(this + 0x18) == 0)) && (param_1[0x28] != (NoiseCache)0x0)) {
    uVar28 = *(ulong *)(param_1 + 0x2c);
    uVar29 = NEON_ucvtf(CONCAT44((int)((ulong)*(undefined8 *)(param_1 + 0x34) >> 0x20) + -1,
                                 (int)*(undefined8 *)(param_1 + 0x34) + -1),4);
    fStack_ec = (float)(uVar28 >> 0x20);
    local_e8 = CONCAT44(fStack_ec +
                        (float)((ulong)uVar29 >> 0x20) * (float)*(undefined8 *)(param_1 + 0x3c),
                        (float)uVar28 + (float)uVar29 * (float)*(undefined8 *)(param_1 + 0x3c));
  }
  else {
    pfVar12 = (float *)NoiseCache::getFloatRegister(param_1);
    pfVar13 = (float *)NoiseCache::getFloatRegister(param_1,iVar14);
    lVar16 = *(long *)(param_1 + 0x10);
    if (lVar16 == 0) {
      local_e8 = 0xff800000ff800000;
      uVar28 = 0x7f800000;
      fStack_ec = INFINITY;
    }
    else {
      local_e8 = 0xff800000ff800000;
      fStack_ec = INFINITY;
      uVar18 = 0x7f800000;
      do {
        fVar27 = *pfVar12;
        uVar28 = (ulong)(uint)fVar27;
        if ((float)uVar18 <= fVar27) {
          uVar28 = uVar18;
        }
        fVar31 = *pfVar13;
        fVar30 = fVar31;
        if (fStack_ec <= fVar31) {
          fVar30 = fStack_ec;
        }
        fStack_ec = fVar30;
        local_e8 = local_e8 ^
                   (local_e8 ^ CONCAT44(fVar31,fVar27)) &
                   CONCAT44(-(uint)((float)(local_e8 >> 0x20) < fVar31),
                            -(uint)((float)local_e8 < fVar27));
        lVar16 = lVar16 + -1;
        pfVar13 = pfVar13 + 1;
        pfVar12 = pfVar12 + 1;
        uVar18 = uVar28;
      } while (lVar16 != 0);
    }
  }
  local_f0 = (float)uVar28;
  VoronoiPoints::VoronoiPoints((VoronoiPoints *)&local_e0,this,(RegionBounds *)&local_f0,uVar23);
  lVar16 = *(long *)(param_1 + 0x10);
  if (lVar16 != 0) {
    lVar17 = 0;
    fVar27 = (float)NEON_ucvtf((uint)*(ushort *)(this + 0x24));
    uVar22 = -uVar23;
    do {
      lVar21 = lVar17 * 4;
      fVar30 = *(float *)(lVar10 + lVar21) / fVar27;
      fVar31 = (float)(int)fVar30;
      if (NAN(fVar31)) {
        iVar14 = 0;
        fVar31 = *(float *)(lVar11 + lVar21) / fVar27;
        fVar32 = (float)(int)fVar31;
        if (NAN(fVar32)) goto LAB_1016142e8;
LAB_101613ccc:
        if (2.1474836e+09 <= fVar32) {
          iVar15 = 0x7fffffff;
        }
        else if (fVar32 <= -2.1474836e+09) {
          iVar15 = -0x80000000;
        }
        else {
          iVar15 = (int)fVar32;
        }
      }
      else {
        if (2.1474836e+09 <= fVar31) {
          iVar14 = 0x7fffffff;
          fVar31 = *(float *)(lVar11 + lVar21);
        }
        else if (fVar31 <= -2.1474836e+09) {
          iVar14 = -0x80000000;
          fVar31 = *(float *)(lVar11 + lVar21);
        }
        else {
          iVar14 = (int)fVar31;
          fVar31 = *(float *)(lVar11 + lVar21);
        }
        fVar31 = fVar31 / fVar27;
        fVar32 = (float)(int)fVar31;
        if (!NAN(fVar32)) goto LAB_101613ccc;
LAB_1016142e8:
        iVar15 = 0;
      }
      fVar30 = fVar30 - (float)iVar14;
      fVar31 = fVar31 - (float)iVar15;
      iVar5 = (iVar15 + ~local_dc) * iStack_d8;
      iVar2 = iVar14 + ~local_e0;
      pfVar13 = (float *)((long)local_d0 + (long)(iVar2 + iVar5) * 0xc);
      fVar32 = ABS((*pfVar13 + -1.0) - fVar30) + ABS((pfVar13[1] + -1.0) - fVar31);
      bVar4 = fVar32 < 3.4028235e+38;
      if (!bVar4) {
        fVar32 = 3.4028235e+38;
      }
      uVar24 = -(uint)bVar4;
      iVar3 = iVar14 - local_e0;
      pfVar13 = (float *)((long)local_d0 + (long)(iVar3 + iVar5) * 0xc);
      fVar34 = ABS((*pfVar13 + 0.0) - fVar30) + ABS((pfVar13[1] + -1.0) - fVar31);
      if (fVar32 <= fVar34) {
        fVar33 = 3.4028235e+38;
        uVar25 = uVar24;
        if (fVar34 < 3.4028235e+38) {
          fVar33 = fVar34;
        }
      }
      else {
        uVar24 = 0xffffffff;
        fVar33 = fVar32;
        fVar32 = fVar34;
        uVar25 = 0;
      }
      iVar1 = iVar3 + 1;
      pfVar13 = (float *)((long)local_d0 + (long)(iVar1 + iVar5) * 0xc);
      fVar34 = ABS((*pfVar13 + 1.0) - fVar30) + ABS((pfVar13[1] + -1.0) - fVar31);
      if (fVar32 <= fVar34) {
        if (fVar34 < fVar33) {
          fVar33 = fVar34;
        }
      }
      else {
        uVar25 = 1;
        uVar24 = 0xffffffff;
        fVar33 = fVar32;
        fVar32 = fVar34;
      }
      iVar5 = (iVar15 - local_dc) * iStack_d8;
      pfVar13 = (float *)((long)local_d0 + (long)(iVar2 + iVar5) * 0xc);
      fVar34 = ABS((*pfVar13 + -1.0) - fVar30) + ABS((pfVar13[1] + 0.0) - fVar31);
      if (fVar32 <= fVar34) {
        if (fVar34 < fVar33) {
          fVar33 = fVar34;
        }
      }
      else {
        uVar24 = 0;
        uVar25 = 0xffffffff;
        fVar33 = fVar32;
        fVar32 = fVar34;
      }
      pfVar13 = (float *)((long)local_d0 + (long)(iVar3 + iVar5) * 0xc);
      fVar34 = ABS((*pfVar13 + 0.0) - fVar30) + ABS((pfVar13[1] + 0.0) - fVar31);
      if (fVar32 <= fVar34) {
        if (fVar34 < fVar33) {
          fVar33 = fVar34;
        }
      }
      else {
        uVar24 = 0;
        uVar25 = 0;
        fVar33 = fVar32;
        fVar32 = fVar34;
      }
      pfVar13 = (float *)((long)local_d0 + (long)(iVar1 + iVar5) * 0xc);
      fVar34 = ABS((*pfVar13 + 1.0) - fVar30) + ABS((pfVar13[1] + 0.0) - fVar31);
      if (fVar32 <= fVar34) {
        if (fVar34 < fVar33) {
          fVar33 = fVar34;
        }
      }
      else {
        uVar24 = 0;
        uVar25 = 1;
        fVar33 = fVar32;
        fVar32 = fVar34;
      }
      iVar5 = iStack_d8 + iStack_d8 * (iVar15 - local_dc);
      pfVar13 = (float *)((long)local_d0 + (long)(iVar2 + iVar5) * 0xc);
      fVar34 = ABS((*pfVar13 + -1.0) - fVar30) + ABS((pfVar13[1] + 1.0) - fVar31);
      if (fVar32 <= fVar34) {
        if (fVar34 < fVar33) {
          fVar33 = fVar34;
        }
      }
      else {
        uVar25 = 0xffffffff;
        uVar24 = 1;
        fVar33 = fVar32;
        fVar32 = fVar34;
      }
      pfVar13 = (float *)((long)local_d0 + (long)(iVar3 + iVar5) * 0xc);
      fVar34 = ABS((*pfVar13 + 0.0) - fVar30) + ABS((pfVar13[1] + 1.0) - fVar31);
      if (fVar32 <= fVar34) {
        if (fVar34 < fVar33) {
          fVar33 = fVar34;
        }
      }
      else {
        uVar25 = 0;
        uVar24 = 1;
        fVar33 = fVar32;
        fVar32 = fVar34;
      }
      pfVar13 = (float *)((long)local_d0 + (long)(iVar1 + iVar5) * 0xc);
      fVar34 = ABS((*pfVar13 + 1.0) - fVar30) + ABS((pfVar13[1] + 1.0) - fVar31);
      if (fVar32 <= fVar34) {
        if (fVar34 < fVar33) {
          fVar33 = fVar34;
        }
      }
      else {
        uVar24 = 1;
        uVar25 = 1;
        fVar33 = fVar32;
        fVar32 = fVar34;
      }
      if (lVar6 != 0) {
        *(float *)(lVar6 + lVar17 * 4) = fVar32;
      }
      if (lVar7 != 0) {
        *(float *)(lVar7 + lVar17 * 4) = fVar33 - fVar32;
      }
      if (lVar8 != 0) {
        pfVar13 = (float *)((long)local_d0 +
                           (long)(int)(((uVar25 + iVar14) - local_e0) +
                                      ((uVar24 + iVar15) - local_dc) * iStack_d8) * 0xc);
        fVar34 = fVar30 - ((*pfVar13 + (float)(int)uVar25) - fVar30);
        fVar33 = fVar31 - ((pfVar13[1] + (float)(int)uVar24) - fVar31);
        iVar2 = (uVar22 - local_e0) + iVar14 + iStack_d8 * ((uVar22 - local_dc) + iVar15);
        fVar32 = 3.4028235e+38;
        uVar26 = uVar22;
        do {
          uVar28 = (ulong)uVar23 << 1 | 1;
          lVar21 = (ulong)uVar23 + (long)(int)uVar25;
          uVar20 = uVar22;
          iVar5 = iVar2;
          do {
            if ((lVar21 != 0) || (uVar26 != uVar24)) {
              pfVar13 = (float *)((long)local_d0 + (long)iVar5 * 0xc);
              local_90 = fVar30 - ((*pfVar13 + (float)(int)uVar20) - fVar30);
              fStack_8c = fVar31 - ((pfVar13[1] + (float)(int)uVar26) - fVar31);
              local_a0 = (fVar34 + local_90) * 0.5;
              fStack_9c = (fVar33 + fStack_8c) * 0.5;
              fVar37 = fVar34;
              if (local_90 <= fVar34) {
                fVar37 = local_90;
              }
              local_a8 = fVar34;
              if (fVar34 <= local_90) {
                local_a8 = local_90;
              }
              fVar36 = fVar33;
              if (fStack_8c <= fVar33) {
                fVar36 = fStack_8c;
              }
              fStack_a4 = fVar33;
              if (fVar33 <= fStack_8c) {
                fStack_a4 = fStack_8c;
              }
              fVar35 = (fVar37 - local_a8) * (fVar37 - local_a8);
              fVar36 = (fVar36 - fStack_a4) * (fVar36 - fStack_a4);
              fVar37 = fVar35;
              if (fVar35 <= fVar36) {
                fVar37 = fVar36;
              }
              uVar18 = (ulong)(fVar37 == fVar35);
              uVar19 = (ulong)(fVar37 != fVar35);
              fVar38 = *(float *)((ulong)&local_90 | uVar19 << 2);
              fVar39 = *(float *)((ulong)&local_f0 | uVar19 << 2);
              fVar40 = *(float *)((ulong)&local_a0 | uVar18 << 2);
              fVar36 = ABS(*(float *)((ulong)&local_f0 | uVar18 << 2) - fVar40);
              local_b0 = CONCAT44(fVar33,fVar34);
              fVar41 = *(float *)((ulong)&local_a0 | uVar19 << 2);
              if (fVar38 <= fVar39) {
                fVar36 = -fVar36;
              }
              *(float *)((ulong)&local_b0 | uVar19 << 2) = fVar41 + fVar36;
              fVar40 = ABS(*(float *)((ulong)&local_90 | uVar18 << 2) - fVar40);
              fVar36 = -fVar40;
              if (fVar38 <= fVar39) {
                fVar36 = fVar40;
              }
              fVar39 = *(float *)((ulong)&local_b0 | uVar18 << 2);
              fVar38 = 1.0;
              if (fVar39 != *(float *)((ulong)&local_a8 | uVar18 << 2)) {
                fVar38 = -1.0;
              }
              local_b8 = CONCAT44(fStack_8c,local_90);
              *(float *)((ulong)&local_b8 | uVar19 << 2) = fVar41 + fVar36;
              fVar41 = *(float *)((ulong)&local_98 | uVar18 << 2);
              fVar42 = local_90 - fVar34;
              fVar43 = fStack_8c - fVar33;
              fVar40 = 0.0;
              fVar36 = fVar38;
              if (fVar37 == fVar35) {
                fVar36 = 0.0;
                fVar40 = fVar38;
              }
              fVar35 = (fVar42 * (fVar30 - fVar34) + fVar43 * (fVar31 - fVar33)) /
                       (fVar42 * fVar42 + fVar43 * fVar43);
              fVar37 = -(fVar38 * (fVar41 - *(float *)((ulong)&local_b8 | uVar18 << 2)));
              fVar38 = fVar38 * (fVar41 - fVar39);
              if (fVar35 <= 0.0) {
                fVar35 = 0.0;
              }
              fVar35 = (float)NEON_fminnm(fVar35,0x3f800000);
              if (fVar38 <= 0.0) {
                fVar38 = 0.0;
              }
              if (fVar37 <= 0.0) {
                fVar37 = 0.0;
              }
              fVar39 = (fVar34 + fVar42 * fVar35) - fVar30;
              fVar35 = (fVar33 + fVar43 * fVar35) - fVar31;
              fVar35 = fVar39 * fVar39 + fVar35 * fVar35;
              fVar39 = (fVar34 + fVar36 * fVar38) - fVar30;
              fVar38 = (fVar33 + fVar40 * fVar38) - fVar31;
              fVar38 = fVar39 * fVar39 + fVar38 * fVar38;
              fVar36 = (local_90 - fVar36 * fVar37) - fVar30;
              fVar37 = (fStack_8c - fVar40 * fVar37) - fVar31;
              fVar37 = fVar36 * fVar36 + fVar37 * fVar37;
              if (fVar37 <= fVar38) {
                fVar38 = fVar37;
              }
              if (fVar38 <= fVar35) {
                fVar35 = fVar38;
              }
              local_f0 = fVar34;
              fStack_ec = fVar33;
              local_98 = fVar30;
              fStack_94 = fVar31;
              if (SQRT(fVar35) <= fVar32) {
                fVar32 = SQRT(fVar35);
              }
            }
            lVar21 = lVar21 + -1;
            iVar5 = iVar5 + 1;
            uVar20 = uVar20 + 1;
            uVar28 = uVar28 - 1;
          } while (uVar28 != 0);
          iVar2 = iVar2 + iStack_d8;
          bVar4 = uVar26 != uVar23;
          uVar26 = uVar26 + 1;
        } while (bVar4);
        *(float *)(lVar8 + lVar17 * 4) = fVar32;
      }
      if (lVar9 != 0) {
        *(undefined4 *)(lVar9 + lVar17 * 4) =
             *(undefined4 *)
              ((long)local_d0 +
              (long)(int)(((uVar25 + iVar14) - local_e0) +
                         ((uVar24 + iVar15) - local_dc) * iStack_d8) * 0xc + 8);
      }
      lVar17 = lVar17 + 1;
    } while (lVar17 != lVar16);
  }
  if (local_d0 != (void *)0x0) {
    local_c8 = local_d0;
    operator_delete(local_d0);
  }
  return;
}



// ===== 0x101614328 runInternal<(NoiseOperations::VoronoiNoise::DistanceType)2> =====

/* WARNING: Type propagation algorithm not settling */
/* void 
   NoiseOperations::VoronoiNoise::runInternal<(NoiseOperations::VoronoiNoise::DistanceType)2>(NoiseCache&)
   const */

void __thiscall
NoiseOperations::VoronoiNoise::runInternal<(NoiseOperations::VoronoiNoise::DistanceType)2>
          (VoronoiNoise *this,NoiseCache *param_1)

{
  int iVar1;
  ulong uVar2;
  ulong uVar3;
  ulong uVar4;
  ulong uVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  ulong uVar9;
  bool bVar10;
  long lVar11;
  long lVar12;
  long lVar13;
  long lVar14;
  long lVar15;
  long lVar16;
  float *pfVar17;
  int iVar18;
  long lVar19;
  long lVar20;
  long lVar21;
  float *pfVar22;
  ulong uVar23;
  ulong uVar24;
  int iVar25;
  uint uVar26;
  uint uVar27;
  int iVar28;
  int iVar29;
  int iVar30;
  float fVar31;
  ulong uVar32;
  ulong uVar33;
  undefined8 uVar34;
  float fVar35;
  float fVar36;
  float fVar37;
  float fVar38;
  float fVar39;
  float fVar40;
  float fVar41;
  float fVar42;
  float fVar43;
  float fVar44;
  float fVar45;
  undefined4 local_a8;
  float fStack_a4;
  ulong local_a0;
  uint local_98;
  uint local_94;
  int iStack_90;
  void *local_88;
  void *local_80;
  
  if (*(int *)(this + 8) == -1) {
    lVar11 = 0;
    iVar6 = *(int *)(this + 0xc);
  }
  else {
    lVar11 = NoiseCache::getFloatRegister(param_1);
    iVar6 = *(int *)(this + 0xc);
  }
  if (iVar6 == -1) {
    lVar12 = 0;
    iVar6 = *(int *)(this + 0x10);
  }
  else {
    lVar12 = NoiseCache::getFloatRegister(param_1);
    iVar6 = *(int *)(this + 0x10);
  }
  if (iVar6 == -1) {
    lVar13 = 0;
    iVar6 = *(int *)(this + 0x14);
  }
  else {
    lVar13 = NoiseCache::getFloatRegister(param_1);
    iVar6 = *(int *)(this + 0x14);
  }
  if (iVar6 == -1) {
    lVar14 = 0;
  }
  else {
    lVar14 = NoiseCache::getFloatRegister(param_1);
  }
  lVar15 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x18));
  lVar16 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x1c));
  if ((this[0x26] != (VoronoiNoise)0x0) || (uVar27 = 2, *(float *)(this + 0x28) <= 0.25)) {
    uVar26 = 2;
    if (*(float *)(this + 0x28) <= 0.5) {
      uVar26 = 1;
    }
    uVar27 = 1;
    if (this[0x26] == (VoronoiNoise)0x1) {
      uVar27 = uVar26;
    }
  }
  iVar6 = *(int *)(this + 0x1c);
  if (((iVar6 == 1) && (*(int *)(this + 0x18) == 0)) && (param_1[0x28] != (NoiseCache)0x0)) {
    uVar32 = *(ulong *)(param_1 + 0x2c);
    uVar34 = NEON_ucvtf(CONCAT44((int)((ulong)*(undefined8 *)(param_1 + 0x34) >> 0x20) + -1,
                                 (int)*(undefined8 *)(param_1 + 0x34) + -1),4);
    fStack_a4 = (float)(uVar32 >> 0x20);
    local_a0 = CONCAT44(fStack_a4 +
                        (float)((ulong)uVar34 >> 0x20) * (float)*(undefined8 *)(param_1 + 0x3c),
                        (float)uVar32 + (float)uVar34 * (float)*(undefined8 *)(param_1 + 0x3c));
  }
  else {
    pfVar17 = (float *)NoiseCache::getFloatRegister(param_1);
    pfVar22 = (float *)NoiseCache::getFloatRegister(param_1,iVar6);
    lVar19 = *(long *)(param_1 + 0x10);
    if (lVar19 == 0) {
      local_a0 = 0xff800000ff800000;
      uVar32 = 0x7f800000;
      fStack_a4 = INFINITY;
    }
    else {
      local_a0 = 0xff800000ff800000;
      fStack_a4 = INFINITY;
      uVar33 = 0x7f800000;
      do {
        fVar31 = *pfVar17;
        uVar32 = (ulong)(uint)fVar31;
        if ((float)uVar33 <= fVar31) {
          uVar32 = uVar33;
        }
        fVar37 = *pfVar22;
        fVar36 = fVar37;
        if (fStack_a4 <= fVar37) {
          fVar36 = fStack_a4;
        }
        fStack_a4 = fVar36;
        local_a0 = local_a0 ^
                   (local_a0 ^ CONCAT44(fVar37,fVar31)) &
                   CONCAT44(-(uint)((float)(local_a0 >> 0x20) < fVar37),
                            -(uint)((float)local_a0 < fVar31));
        lVar19 = lVar19 + -1;
        pfVar22 = pfVar22 + 1;
        pfVar17 = pfVar17 + 1;
        uVar33 = uVar32;
      } while (lVar19 != 0);
    }
  }
  local_a8 = (undefined4)uVar32;
  VoronoiPoints::VoronoiPoints((VoronoiPoints *)&local_98,this,(RegionBounds *)&local_a8,uVar27);
  lVar19 = *(long *)(param_1 + 0x10);
  if (lVar19 != 0) {
    lVar20 = 0;
    fVar31 = (float)NEON_ucvtf((uint)*(ushort *)(this + 0x24));
    iVar6 = -uVar27;
    lVar21 = (long)iVar6;
    uVar23 = (ulong)(uVar27 + 1);
    uVar32 = lVar21 + 1;
    uVar33 = lVar21 + 2;
    uVar2 = lVar21 + 3;
    uVar3 = lVar21 + 4;
    uVar4 = lVar21 + 5;
    uVar5 = lVar21 + 6;
    do {
      lVar21 = lVar20 * 4;
      fVar36 = *(float *)(lVar15 + lVar21) / fVar31;
      fVar37 = (float)(int)fVar36;
      if (NAN(fVar37)) {
        iVar28 = 0;
        fVar37 = *(float *)(lVar16 + lVar21) / fVar31;
        fVar38 = (float)(int)fVar37;
        if (NAN(fVar38)) goto LAB_1016150f4;
LAB_101614648:
        if (2.1474836e+09 <= fVar38) {
          iVar29 = 0x7fffffff;
        }
        else if (fVar38 <= -2.1474836e+09) {
          iVar29 = -0x80000000;
        }
        else {
          iVar29 = (int)fVar38;
        }
      }
      else {
        if (2.1474836e+09 <= fVar37) {
          iVar28 = 0x7fffffff;
          fVar37 = *(float *)(lVar16 + lVar21);
        }
        else if (fVar37 <= -2.1474836e+09) {
          iVar28 = -0x80000000;
          fVar37 = *(float *)(lVar16 + lVar21);
        }
        else {
          iVar28 = (int)fVar37;
          fVar37 = *(float *)(lVar16 + lVar21);
        }
        fVar37 = fVar37 / fVar31;
        fVar38 = (float)(int)fVar37;
        if (!NAN(fVar38)) goto LAB_101614648;
LAB_1016150f4:
        iVar29 = 0;
      }
      fVar36 = fVar36 - (float)iVar28;
      fVar37 = fVar37 - (float)iVar29;
      iVar7 = (iVar29 + ~local_94) * iStack_90;
      iVar18 = iVar28 + ~local_98;
      pfVar22 = (float *)((long)local_88 + (long)(iVar18 + iVar7) * 0xc);
      fVar38 = (*pfVar22 + -1.0) - fVar36;
      fVar39 = (pfVar22[1] + -1.0) - fVar37;
      fVar38 = SQRT(fVar38 * fVar38 + fVar39 * fVar39);
      bVar10 = fVar38 < 3.4028235e+38;
      if (!bVar10) {
        fVar38 = 3.4028235e+38;
      }
      iVar30 = -(uint)bVar10;
      iVar8 = iVar28 - local_98;
      pfVar22 = (float *)((long)local_88 + (long)(iVar8 + iVar7) * 0xc);
      fVar39 = (*pfVar22 + 0.0) - fVar36;
      fVar40 = (pfVar22[1] + -1.0) - fVar37;
      fVar39 = SQRT(fVar39 * fVar39 + fVar40 * fVar40);
      if (fVar38 <= fVar39) {
        fVar40 = 3.4028235e+38;
        iVar25 = iVar30;
        if (fVar39 < 3.4028235e+38) {
          fVar40 = fVar39;
        }
      }
      else {
        iVar30 = -1;
        fVar40 = fVar38;
        fVar38 = fVar39;
        iVar25 = 0;
      }
      iVar1 = iVar8 + 1;
      pfVar22 = (float *)((long)local_88 + (long)(iVar1 + iVar7) * 0xc);
      fVar39 = (*pfVar22 + 1.0) - fVar36;
      fVar41 = (pfVar22[1] + -1.0) - fVar37;
      fVar39 = SQRT(fVar39 * fVar39 + fVar41 * fVar41);
      if (fVar38 <= fVar39) {
        if (fVar39 < fVar40) {
          fVar40 = fVar39;
        }
      }
      else {
        iVar25 = 1;
        iVar30 = -1;
        fVar40 = fVar38;
        fVar38 = fVar39;
      }
      iVar7 = (iVar29 - local_94) * iStack_90;
      pfVar22 = (float *)((long)local_88 + (long)(iVar18 + iVar7) * 0xc);
      fVar39 = (*pfVar22 + -1.0) - fVar36;
      fVar41 = (pfVar22[1] + 0.0) - fVar37;
      fVar39 = SQRT(fVar39 * fVar39 + fVar41 * fVar41);
      if (fVar38 <= fVar39) {
        if (fVar39 < fVar40) {
          fVar40 = fVar39;
        }
      }
      else {
        iVar30 = 0;
        iVar25 = -1;
        fVar40 = fVar38;
        fVar38 = fVar39;
      }
      pfVar22 = (float *)((long)local_88 + (long)(iVar8 + iVar7) * 0xc);
      fVar39 = (*pfVar22 + 0.0) - fVar36;
      fVar41 = (pfVar22[1] + 0.0) - fVar37;
      fVar39 = SQRT(fVar39 * fVar39 + fVar41 * fVar41);
      if (fVar38 <= fVar39) {
        if (fVar39 < fVar40) {
          fVar40 = fVar39;
        }
      }
      else {
        iVar30 = 0;
        iVar25 = 0;
        fVar40 = fVar38;
        fVar38 = fVar39;
      }
      pfVar22 = (float *)((long)local_88 + (long)(iVar1 + iVar7) * 0xc);
      fVar39 = (*pfVar22 + 1.0) - fVar36;
      fVar41 = (pfVar22[1] + 0.0) - fVar37;
      fVar39 = SQRT(fVar39 * fVar39 + fVar41 * fVar41);
      if (fVar38 <= fVar39) {
        if (fVar39 < fVar40) {
          fVar40 = fVar39;
        }
      }
      else {
        iVar30 = 0;
        iVar25 = 1;
        fVar40 = fVar38;
        fVar38 = fVar39;
      }
      iVar7 = iStack_90 + iStack_90 * (iVar29 - local_94);
      pfVar22 = (float *)((long)local_88 + (long)(iVar18 + iVar7) * 0xc);
      fVar39 = (*pfVar22 + -1.0) - fVar36;
      fVar41 = (pfVar22[1] + 1.0) - fVar37;
      fVar39 = SQRT(fVar39 * fVar39 + fVar41 * fVar41);
      if (fVar38 <= fVar39) {
        if (fVar39 < fVar40) {
          fVar40 = fVar39;
        }
      }
      else {
        iVar25 = -1;
        iVar30 = 1;
        fVar40 = fVar38;
        fVar38 = fVar39;
      }
      pfVar22 = (float *)((long)local_88 + (long)(iVar8 + iVar7) * 0xc);
      fVar39 = (*pfVar22 + 0.0) - fVar36;
      fVar41 = (pfVar22[1] + 1.0) - fVar37;
      fVar39 = SQRT(fVar39 * fVar39 + fVar41 * fVar41);
      if (fVar38 <= fVar39) {
        if (fVar39 < fVar40) {
          fVar40 = fVar39;
        }
      }
      else {
        iVar25 = 0;
        iVar30 = 1;
        fVar40 = fVar38;
        fVar38 = fVar39;
      }
      pfVar22 = (float *)((long)local_88 + (long)(iVar1 + iVar7) * 0xc);
      fVar39 = (*pfVar22 + 1.0) - fVar36;
      fVar41 = (pfVar22[1] + 1.0) - fVar37;
      fVar39 = SQRT(fVar39 * fVar39 + fVar41 * fVar41);
      if (fVar38 <= fVar39) {
        if (fVar39 < fVar40) {
          fVar40 = fVar39;
        }
      }
      else {
        iVar30 = 1;
        iVar25 = 1;
        fVar40 = fVar38;
        fVar38 = fVar39;
      }
      if (lVar11 != 0) {
        *(float *)(lVar11 + lVar20 * 4) = fVar38;
      }
      if (lVar12 != 0) {
        *(float *)(lVar12 + lVar20 * 4) = fVar40 - fVar38;
      }
      if (lVar13 != 0) {
        uVar26 = 0;
        pfVar22 = (float *)((long)local_88 +
                           (long)(int)(((iVar25 + iVar28) - local_98) +
                                      ((iVar30 + iVar29) - local_94) * iStack_90) * 0xc);
        fVar39 = (*pfVar22 + (float)iVar25) - fVar36;
        fVar40 = (pfVar22[1] + (float)iVar30) - fVar37;
        uVar24 = (ulong)iVar25;
        iVar18 = (iVar28 - local_98) + iStack_90 * ((iVar6 - local_94) + iVar29);
        fVar38 = 3.4028235e+38;
        do {
          fVar41 = (float)(int)(iVar6 + uVar26);
          if ((iVar6 - iVar30) + uVar26 == 0) {
            if (iVar25 != iVar6) {
              pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18) * 0xc);
              fVar44 = (*pfVar22 + (float)iVar6) - fVar36;
              fVar45 = (pfVar22[1] + fVar41) - fVar37;
              fVar43 = fVar44 - fVar39;
              fVar42 = fVar45 - fVar40;
              if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                fVar43 = fVar43 / fVar35;
                fVar42 = fVar42 / fVar35;
              }
              fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
              if (fVar42 <= fVar38) {
                fVar38 = fVar42;
              }
            }
            if (uVar32 != uVar23) {
              if (uVar32 != uVar24) {
                pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 1) * 0xc);
                fVar44 = (*pfVar22 + (float)(int)uVar32) - fVar36;
                fVar45 = (pfVar22[1] + fVar41) - fVar37;
                fVar43 = fVar44 - fVar39;
                fVar42 = fVar45 - fVar40;
                if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                  fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                  fVar43 = fVar43 / fVar35;
                  fVar42 = fVar42 / fVar35;
                }
                fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
                if (fVar42 <= fVar38) {
                  fVar38 = fVar42;
                }
              }
              if (uVar33 != uVar23) {
                if (uVar33 != uVar24) {
                  pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 2) * 0xc);
                  fVar44 = (*pfVar22 + (float)(int)uVar33) - fVar36;
                  fVar45 = (pfVar22[1] + fVar41) - fVar37;
                  fVar43 = fVar44 - fVar39;
                  fVar42 = fVar45 - fVar40;
                  if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                    fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                    fVar43 = fVar43 / fVar35;
                    fVar42 = fVar42 / fVar35;
                  }
                  fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
                  if (fVar42 <= fVar38) {
                    fVar38 = fVar42;
                  }
                }
                if (uVar2 != uVar23) {
                  if (uVar2 != uVar24) {
                    pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 3) * 0xc);
                    fVar44 = (*pfVar22 + (float)(int)uVar2) - fVar36;
                    fVar45 = (pfVar22[1] + fVar41) - fVar37;
                    fVar43 = fVar44 - fVar39;
                    fVar42 = fVar45 - fVar40;
                    if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                      fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                      fVar43 = fVar43 / fVar35;
                      fVar42 = fVar42 / fVar35;
                    }
                    fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
                    if (fVar42 <= fVar38) {
                      fVar38 = fVar42;
                    }
                  }
                  if (uVar3 != uVar23) {
                    if (uVar3 != uVar24) {
                      pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 4) * 0xc);
                      fVar44 = (*pfVar22 + (float)(int)uVar3) - fVar36;
                      fVar45 = (pfVar22[1] + fVar41) - fVar37;
                      fVar43 = fVar44 - fVar39;
                      fVar42 = fVar45 - fVar40;
                      if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                        fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                        fVar43 = fVar43 / fVar35;
                        fVar42 = fVar42 / fVar35;
                      }
                      fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
                      if (fVar42 <= fVar38) {
                        fVar38 = fVar42;
                      }
                    }
                    if (uVar4 != uVar23) {
                      if (uVar4 != uVar24) {
                        pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 5) * 0xc);
                        fVar44 = (*pfVar22 + (float)(int)uVar4) - fVar36;
                        fVar45 = (pfVar22[1] + fVar41) - fVar37;
                        fVar43 = fVar44 - fVar39;
                        fVar42 = fVar45 - fVar40;
                        if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                          fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                          fVar43 = fVar43 / fVar35;
                          fVar42 = fVar42 / fVar35;
                        }
                        fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43
                        ;
                        if (fVar42 <= fVar38) {
                          fVar38 = fVar42;
                        }
                      }
                      uVar9 = uVar24;
                      if (uVar5 != uVar23) goto joined_r0x00010161506c;
                    }
                  }
                }
              }
            }
          }
          else {
            pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18) * 0xc);
            fVar44 = (*pfVar22 + (float)iVar6) - fVar36;
            fVar45 = (pfVar22[1] + fVar41) - fVar37;
            fVar43 = fVar44 - fVar39;
            fVar42 = fVar45 - fVar40;
            if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
              fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
              fVar43 = fVar43 / fVar35;
              fVar42 = fVar42 / fVar35;
            }
            fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
            if (fVar42 <= fVar38) {
              fVar38 = fVar42;
            }
            if (uVar32 != uVar23) {
              pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 1) * 0xc);
              fVar44 = (*pfVar22 + (float)(int)uVar32) - fVar36;
              fVar45 = (pfVar22[1] + fVar41) - fVar37;
              fVar43 = fVar44 - fVar39;
              fVar42 = fVar45 - fVar40;
              if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                fVar43 = fVar43 / fVar35;
                fVar42 = fVar42 / fVar35;
              }
              fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
              if (fVar42 <= fVar38) {
                fVar38 = fVar42;
              }
              if (uVar33 != uVar23) {
                pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 2) * 0xc);
                fVar44 = (*pfVar22 + (float)(int)uVar33) - fVar36;
                fVar45 = (pfVar22[1] + fVar41) - fVar37;
                fVar43 = fVar44 - fVar39;
                fVar42 = fVar45 - fVar40;
                if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                  fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                  fVar43 = fVar43 / fVar35;
                  fVar42 = fVar42 / fVar35;
                }
                fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
                if (fVar42 <= fVar38) {
                  fVar38 = fVar42;
                }
                if (uVar2 != uVar23) {
                  pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 3) * 0xc);
                  fVar44 = (*pfVar22 + (float)(int)uVar2) - fVar36;
                  fVar45 = (pfVar22[1] + fVar41) - fVar37;
                  fVar43 = fVar44 - fVar39;
                  fVar42 = fVar45 - fVar40;
                  if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                    fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                    fVar43 = fVar43 / fVar35;
                    fVar42 = fVar42 / fVar35;
                  }
                  fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
                  if (fVar42 <= fVar38) {
                    fVar38 = fVar42;
                  }
                  if (uVar3 != uVar23) {
                    pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 4) * 0xc);
                    fVar44 = (*pfVar22 + (float)(int)uVar3) - fVar36;
                    fVar45 = (pfVar22[1] + fVar41) - fVar37;
                    fVar43 = fVar44 - fVar39;
                    fVar42 = fVar45 - fVar40;
                    if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                      fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                      fVar43 = fVar43 / fVar35;
                      fVar42 = fVar42 / fVar35;
                    }
                    fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
                    if (fVar42 <= fVar38) {
                      fVar38 = fVar42;
                    }
                    if (uVar4 != uVar23) {
                      pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 5) * 0xc);
                      fVar44 = (*pfVar22 + (float)(int)uVar4) - fVar36;
                      fVar45 = (pfVar22[1] + fVar41) - fVar37;
                      fVar43 = fVar44 - fVar39;
                      fVar42 = fVar45 - fVar40;
                      if ((fVar43 != 0.0) || (fVar42 != 0.0)) {
                        fVar35 = SQRT(fVar43 * fVar43 + fVar42 * fVar42);
                        fVar43 = fVar43 / fVar35;
                        fVar42 = fVar42 / fVar35;
                      }
                      fVar42 = (fVar40 + fVar45) * 0.5 * fVar42 + (fVar39 + fVar44) * 0.5 * fVar43;
                      uVar9 = uVar23;
                      if (fVar42 <= fVar38) {
                        fVar38 = fVar42;
                      }
joined_r0x00010161506c:
                      if (uVar5 != uVar9) {
                        pfVar22 = (float *)((long)local_88 + (long)(iVar6 + iVar18 + 6) * 0xc);
                        fVar43 = (*pfVar22 + (float)(int)uVar5) - fVar36;
                        fVar44 = (pfVar22[1] + fVar41) - fVar37;
                        fVar42 = fVar43 - fVar39;
                        fVar41 = fVar44 - fVar40;
                        if ((fVar42 != 0.0) || (fVar41 != 0.0)) {
                          fVar45 = SQRT(fVar42 * fVar42 + fVar41 * fVar41);
                          fVar42 = fVar42 / fVar45;
                          fVar41 = fVar41 / fVar45;
                        }
                        fVar41 = (fVar40 + fVar44) * 0.5 * fVar41 + (fVar39 + fVar43) * 0.5 * fVar42
                        ;
                        if (fVar41 <= fVar38) {
                          fVar38 = fVar41;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          uVar26 = uVar26 + 1;
          iVar18 = iVar18 + iStack_90;
        } while ((uVar27 << 1 | 1) != uVar26);
        *(float *)(lVar13 + lVar20 * 4) = fVar38;
      }
      if (lVar14 != 0) {
        *(undefined4 *)(lVar14 + lVar20 * 4) =
             *(undefined4 *)
              ((long)local_88 +
              (long)(int)(((iVar25 + iVar28) - local_98) +
                         ((iVar30 + iVar29) - local_94) * iStack_90) * 0xc + 8);
      }
      lVar20 = lVar20 + 1;
    } while (lVar20 != lVar19);
  }
  if (local_88 != (void *)0x0) {
    local_80 = local_88;
    operator_delete(local_88);
  }
  return;
}



// ===== 0x101615130 runInternal<(NoiseOperations::VoronoiNoise::DistanceType)3> =====

/* WARNING: Type propagation algorithm not settling */
/* void 
   NoiseOperations::VoronoiNoise::runInternal<(NoiseOperations::VoronoiNoise::DistanceType)3>(NoiseCache&)
   const */

void __thiscall
NoiseOperations::VoronoiNoise::runInternal<(NoiseOperations::VoronoiNoise::DistanceType)3>
          (VoronoiNoise *this,NoiseCache *param_1)

{
  uint uVar1;
  uint uVar2;
  float fVar3;
  long lVar4;
  long lVar5;
  long lVar6;
  long lVar7;
  long lVar8;
  float *pfVar9;
  long lVar10;
  float *pfVar11;
  uint uVar12;
  int iVar13;
  int iVar14;
  uint uVar15;
  uint uVar16;
  uint uVar17;
  float fVar18;
  float fVar19;
  float fVar20;
  float fVar21;
  float fVar22;
  ulong uVar23;
  ulong uVar24;
  float fVar25;
  undefined8 uVar26;
  float fVar27;
  float fVar28;
  uint local_134;
  long local_f0;
  undefined4 local_e0;
  float fStack_dc;
  ulong local_d8;
  uint local_d0;
  int iStack_cc;
  int local_c8;
  void *local_c0;
  void *local_b8;
  
  if (*(int *)(this + 8) == -1) {
    lVar4 = 0;
    iVar13 = *(int *)(this + 0xc);
  }
  else {
    lVar4 = NoiseCache::getFloatRegister(param_1);
    iVar13 = *(int *)(this + 0xc);
  }
  if (iVar13 == -1) {
    lVar5 = 0;
    iVar13 = *(int *)(this + 0x10);
  }
  else {
    lVar5 = NoiseCache::getFloatRegister(param_1);
    iVar13 = *(int *)(this + 0x10);
  }
  if (iVar13 == -1) {
    local_f0 = 0;
    iVar13 = *(int *)(this + 0x14);
  }
  else {
    local_f0 = NoiseCache::getFloatRegister(param_1);
    iVar13 = *(int *)(this + 0x14);
  }
  if (iVar13 == -1) {
    lVar6 = 0;
  }
  else {
    lVar6 = NoiseCache::getFloatRegister(param_1);
  }
  lVar7 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x18));
  lVar8 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x1c));
  local_134 = 2;
  if ((this[0x26] != (VoronoiNoise)0x0) || (*(float *)(this + 0x28) <= 0.25)) {
    uVar12 = 2;
    if (*(float *)(this + 0x28) <= 0.5) {
      uVar12 = 1;
    }
    local_134 = 1;
    if (this[0x26] == (VoronoiNoise)0x1) {
      local_134 = uVar12;
    }
  }
  iVar13 = *(int *)(this + 0x1c);
  if (((iVar13 == 1) && (*(int *)(this + 0x18) == 0)) && (param_1[0x28] != (NoiseCache)0x0)) {
    uVar23 = *(ulong *)(param_1 + 0x2c);
    uVar26 = NEON_ucvtf(CONCAT44((int)((ulong)*(undefined8 *)(param_1 + 0x34) >> 0x20) + -1,
                                 (int)*(undefined8 *)(param_1 + 0x34) + -1),4);
    fStack_dc = (float)(uVar23 >> 0x20);
    local_d8 = CONCAT44(fStack_dc +
                        (float)((ulong)uVar26 >> 0x20) * (float)*(undefined8 *)(param_1 + 0x3c),
                        (float)uVar23 + (float)uVar26 * (float)*(undefined8 *)(param_1 + 0x3c));
  }
  else {
    pfVar9 = (float *)NoiseCache::getFloatRegister(param_1);
    pfVar11 = (float *)NoiseCache::getFloatRegister(param_1,iVar13);
    lVar10 = *(long *)(param_1 + 0x10);
    if (lVar10 == 0) {
      local_d8 = 0xff800000ff800000;
      uVar23 = 0x7f800000;
      fStack_dc = INFINITY;
    }
    else {
      local_d8 = 0xff800000ff800000;
      fStack_dc = INFINITY;
      uVar24 = 0x7f800000;
      do {
        fVar18 = *pfVar9;
        uVar23 = (ulong)(uint)fVar18;
        if ((float)uVar24 <= fVar18) {
          uVar23 = uVar24;
        }
        fVar25 = *pfVar11;
        fVar21 = fVar25;
        if (fStack_dc <= fVar25) {
          fVar21 = fStack_dc;
        }
        fStack_dc = fVar21;
        local_d8 = local_d8 ^
                   (local_d8 ^ CONCAT44(fVar25,fVar18)) &
                   CONCAT44(-(uint)((float)(local_d8 >> 0x20) < fVar25),
                            -(uint)((float)local_d8 < fVar18));
        lVar10 = lVar10 + -1;
        pfVar11 = pfVar11 + 1;
        pfVar9 = pfVar9 + 1;
        uVar24 = uVar23;
      } while (lVar10 != 0);
    }
  }
  local_e0 = (undefined4)uVar23;
  VoronoiPoints::VoronoiPoints((VoronoiPoints *)&local_d0,this,(RegionBounds *)&local_e0,local_134);
  if (*(long *)(param_1 + 0x10) != 0) {
    uVar23 = 0;
    uVar12 = -local_134;
    do {
      fVar21 = (float)NEON_ucvtf((uint)*(ushort *)(this + 0x24));
      fVar18 = *(float *)(lVar7 + uVar23 * 4) / fVar21;
      fVar25 = (float)(int)fVar18;
      if (NAN(fVar25)) {
        iVar13 = 0;
      }
      else if (2.1474836e+09 <= fVar25) {
        iVar13 = 0x7fffffff;
      }
      else if (fVar25 <= -2.1474836e+09) {
        iVar13 = -0x80000000;
      }
      else {
        iVar13 = (int)fVar25;
      }
      fVar21 = *(float *)(lVar8 + uVar23 * 4) / fVar21;
      fVar25 = (float)(int)fVar21;
      if (NAN(fVar25)) {
        iVar14 = 0;
      }
      else if (2.1474836e+09 <= fVar25) {
        iVar14 = 0x7fffffff;
      }
      else if (fVar25 <= -2.1474836e+09) {
        iVar14 = -0x80000000;
      }
      else {
        iVar14 = (int)fVar25;
      }
      uVar15 = 0;
      fVar18 = fVar18 - (float)iVar13;
      fVar21 = fVar21 - (float)iVar14;
      fVar20 = 3.4028235e+38;
      fVar25 = 3.4028235e+38;
      uVar1 = 0xffffffff;
      uVar16 = 0;
      do {
        while( true ) {
          uVar17 = uVar1;
          fVar28 = (float)(int)uVar17;
          pfVar11 = (float *)((long)local_c0 +
                             (long)(int)(iVar13 + ~local_d0 +
                                        ((iVar14 + uVar17) - iStack_cc) * local_c8) * 0xc);
          fVar19 = ABS((*pfVar11 + -1.0) - fVar18);
          fVar22 = ABS((pfVar11[1] + fVar28) - fVar21);
          fVar22 = fVar19 * fVar19 * fVar19 + fVar22 * fVar22 * fVar22;
          fVar19 = 0.0;
          if (fVar22 != 0.0) {
            fVar19 = (float)Math::log2(fVar22);
            fVar19 = (float)Math::exp2f(fVar19 * 0.33333334);
          }
          if (fVar19 < fVar25) {
            fVar25 = fVar19;
          }
          uVar1 = uVar17;
          fVar3 = fVar19;
          fVar22 = fVar20;
          if (fVar20 <= fVar19) {
            uVar1 = uVar16;
            fVar3 = fVar20;
            fVar22 = fVar25;
          }
          uVar2 = 0xffffffff;
          if (fVar20 <= fVar19) {
            uVar2 = uVar15;
          }
          pfVar11 = (float *)((long)local_c0 +
                             (long)(int)((iVar13 - local_d0) +
                                        ((iVar14 + uVar17) - iStack_cc) * local_c8) * 0xc);
          fVar20 = 0.0;
          fVar25 = ABS((*pfVar11 + 0.0) - fVar18);
          fVar19 = ABS((pfVar11[1] + fVar28) - fVar21);
          fVar25 = fVar25 * fVar25 * fVar25 + fVar19 * fVar19 * fVar19;
          fVar19 = 0.0;
          if (fVar25 != 0.0) {
            fVar25 = (float)Math::log2(fVar25);
            fVar19 = (float)Math::exp2f(fVar25 * 0.33333334);
          }
          if (fVar19 < fVar22) {
            fVar22 = fVar19;
          }
          uVar16 = uVar17;
          fVar25 = fVar19;
          fVar27 = fVar3;
          if (fVar3 <= fVar19) {
            uVar16 = uVar1;
            fVar25 = fVar3;
            fVar27 = fVar22;
          }
          uVar15 = 0;
          if (fVar3 <= fVar19) {
            uVar15 = uVar2;
          }
          pfVar11 = (float *)((long)local_c0 +
                             (long)(int)(((iVar13 + 1) - local_d0) +
                                        ((iVar14 + uVar17) - iStack_cc) * local_c8) * 0xc);
          fVar19 = ABS((*pfVar11 + 1.0) - fVar18);
          fVar22 = ABS((pfVar11[1] + fVar28) - fVar21);
          fVar19 = fVar19 * fVar19 * fVar19 + fVar22 * fVar22 * fVar22;
          if (fVar19 != 0.0) break;
          if (0.0 < fVar25) goto LAB_1016154ac;
LAB_10161564c:
          if (fVar20 < fVar27) {
            fVar27 = fVar20;
          }
          uVar1 = uVar17 + 1;
          fVar20 = fVar25;
          fVar25 = fVar27;
          uVar17 = uVar16;
          if (uVar1 == 2) goto LAB_101615668;
        }
        fVar20 = (float)Math::log2(fVar19);
        fVar20 = (float)Math::exp2f(fVar20 * 0.33333334);
        if (fVar25 <= fVar20) goto LAB_10161564c;
LAB_1016154ac:
        uVar15 = 1;
        uVar1 = uVar17 + 1;
        uVar16 = uVar17;
      } while (uVar17 + 1 != 2);
LAB_101615668:
      if (lVar4 != 0) {
        *(float *)(lVar4 + uVar23 * 4) = fVar20;
      }
      if (lVar5 != 0) {
        *(float *)(lVar5 + uVar23 * 4) = fVar25 - fVar20;
      }
      if (local_f0 != 0) {
        if ((local_134 + 1 != uVar12) &&
           (((((uVar17 != uVar12 || (uVar15 != uVar12)) ||
              ((uVar15 != local_134 || ((1 - local_134 != uVar17 || (uVar15 != uVar12)))))) ||
             ((uVar15 != local_134 ||
              (((2 - local_134 != uVar17 || (uVar15 != uVar12)) || (uVar15 != local_134)))))) ||
            ((2 - local_134 != local_134 &&
             ((((((local_134 ^ 3) != uVar17 || (uVar15 != uVar12)) ||
                ((uVar15 != local_134 || ((4 - local_134 != uVar17 || (uVar15 != uVar12)))))) ||
               (uVar15 != local_134)) ||
              ((4 - local_134 != local_134 &&
               (((((5 - local_134 != uVar17 || (uVar15 != uVar12)) || (uVar15 != local_134)) ||
                 ((6 - local_134 != uVar17 || (uVar15 != uVar12)))) || (uVar15 != local_134)))))))))
            ))) {
                    /* WARNING: Subroutine does not return */
          Logging::logEnumAndAbortOrThrow<NoiseOperations::VoronoiNoise::DistanceType>
                    ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Noise/Operation/VoronoiNoise.cpp"
                     ,0x106,9,3);
        }
        *(undefined4 *)(local_f0 + uVar23 * 4) = 0x7f7fffff;
      }
      if (lVar6 != 0) {
        *(undefined4 *)(lVar6 + uVar23 * 4) =
             *(undefined4 *)
              ((long)local_c0 +
              (long)(int)(((uVar15 + iVar13) - local_d0) +
                         ((uVar17 + iVar14) - iStack_cc) * local_c8) * 0xc + 8);
      }
      uVar23 = uVar23 + 1;
    } while (uVar23 < *(ulong *)(param_1 + 0x10));
  }
  if (local_c0 != (void *)0x0) {
    local_b8 = local_c0;
    operator_delete(local_c0);
  }
  return;
}



// ===== 0x1015f3c90 compile =====

/* NoiseExpressions::VoronoiNoiseWrapper::compile(NoiseProgramBuilder&) const */

void NoiseExpressions::VoronoiNoiseWrapper::compile(NoiseProgramBuilder *param_1)

{
  long lVar1;
  RuntimeError *this;
  NoiseProgramBuilder *in_x1;
  undefined1 *in_x8;
  int *piVar2;
  int iVar3;
  
  lVar1 = NoiseProgramBuilder::compileExpression(in_x1,*(NoiseExpression **)(param_1 + 0x20));
  if (3 < (byte)param_1[0x28]) {
    piVar2 = (int *)0x0;
    iVar3 = iRam0000000000000000;
    goto joined_r0x0001015f3d04;
  }
  lVar1 = *(long *)(*(long *)(in_x1 + 0x30) + (ulong)*(uint *)(lVar1 + 0x24) * 8);
  switch(param_1[0x28]) {
  case (NoiseProgramBuilder)0x0:
    piVar2 = (int *)(lVar1 + 8);
    iVar3 = *piVar2;
    if (iVar3 != -1) goto LAB_1015f3d5c;
    goto LAB_1015f3d44;
  case (NoiseProgramBuilder)0x1:
    piVar2 = (int *)(lVar1 + 0xc);
    iVar3 = *piVar2;
    break;
  case (NoiseProgramBuilder)0x2:
    if (*(char *)(lVar1 + 0x26) == '\x03') {
      this = (RuntimeError *)___cxa_allocate_exception(0x10);
      RuntimeError::RuntimeError
                (this,"Voronoi pyramid noise with Minkowski3 distance is not supported");
      goto LAB_1015f3dac;
    }
    piVar2 = (int *)(lVar1 + 0x10);
    iVar3 = *piVar2;
    break;
  case (NoiseProgramBuilder)0x3:
    piVar2 = (int *)(lVar1 + 0x14);
    iVar3 = *piVar2;
  }
joined_r0x0001015f3d04:
  if (iVar3 == -1) {
LAB_1015f3d44:
    iVar3 = *(int *)(in_x1 + 0xd8);
    if (iVar3 == -1) {
      this = (RuntimeError *)___cxa_allocate_exception(0x10);
      RuntimeError::RuntimeError(this,"Too many registers");
LAB_1015f3dac:
                    /* WARNING: Subroutine does not return */
      ___cxa_throw(this,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
    }
    *(int *)(in_x1 + 0xd8) = iVar3 + 1;
    *piVar2 = iVar3;
  }
LAB_1015f3d5c:
  *in_x8 = 0;
  *(int *)(in_x8 + 0x20) = iVar3;
  *(undefined4 *)(in_x8 + 0x24) = 0xffffffff;
  return;
}



