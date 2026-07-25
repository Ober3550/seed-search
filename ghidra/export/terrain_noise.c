// ===== run  @ 0x1015edd54 =====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* NoiseExpressions::QuickMultioctaveNoise::run(NoiseRegisterIndex, std::array<NoiseRegisterIndex,
   2ul> const&, std::span<NoiseExpressionConstant const, 10ul> const&) */

void NoiseExpressions::QuickMultioctaveNoise::run
               (undefined8 param_1,undefined8 param_2,long *param_3)

{
  int iVar1;
  char cVar2;
  undefined8 uVar3;
  undefined8 uVar4;
  undefined *puVar5;
  undefined *puVar6;
  undefined8 uVar7;
  NoiseCache *pNVar8;
  byte *pbVar9;
  void *pvVar10;
  undefined8 *puVar11;
  undefined8 *puVar12;
  undefined1 *puVar13;
  long lVar14;
  undefined8 extraout_x8;
  char *pcVar15;
  int iVar16;
  int iVar17;
  int iVar18;
  double dVar19;
  double dVar20;
  double dVar21;
  double dVar22;
  BasisNoise *pBVar24;
  float fVar23;
  undefined1 auStack_ad0 [8];
  undefined4 local_ac8;
  undefined4 uStack_ac4;
  undefined4 local_ac0;
  undefined1 auStack_abc [2568];
  undefined8 local_b4;
  undefined4 local_ac;
  undefined4 local_a8;
  char local_a4;
  long local_a0;
  
  local_a0 = *(long *)PTR____stack_chk_guard_102d481b8;
  pcVar15 = (char *)*param_3;
  if (*pcVar15 == '\x01') {
    dVar19 = *(double *)(pcVar15 + 8);
    iVar1 = 0;
    if (0.0 < dVar19) {
      iVar1 = (int)dVar19;
    }
    iVar18 = -1;
    if (dVar19 < 4294967295.0) {
      iVar18 = iVar1;
    }
    iVar1 = 0;
    if (!NAN(dVar19)) {
      iVar1 = iVar18;
    }
    uVar7 = NoiseExpressionConstant::asNoiseLayerID
                      ((NoiseExpressionConstant *)(pcVar15 + 0x20),"seed1");
    puVar5 = getSharedNoiseCache()::cache;
    lVar14 = *param_3;
    if (*(char *)(lVar14 + 0x40) == '\x01') {
      dVar19 = *(double *)(lVar14 + 0x48);
      if (NAN(dVar19)) {
        iVar17 = 0;
        cVar2 = *(char *)(lVar14 + 0x60);
      }
      else {
        iVar18 = 0;
        if (0.0 < dVar19) {
          iVar18 = (int)dVar19;
        }
        iVar17 = -1;
        if (dVar19 < 4294967295.0) {
          iVar17 = iVar18;
        }
        cVar2 = *(char *)(lVar14 + 0x60);
      }
      if (cVar2 == '\x01') {
        if (*(char *)(lVar14 + 0x80) == '\x01') {
          if (*(char *)(lVar14 + 0xa0) == '\x01') {
            if (*(char *)(lVar14 + 0xc0) == '\x01') {
              if (*(char *)(lVar14 + 0xe0) == '\x01') {
                if (*(char *)(lVar14 + 0x100) == '\x01') {
                  if (*(char *)(lVar14 + 0x120) == '\x01') {
                    dVar19 = *(double *)(lVar14 + 0x128);
                    if (NAN(dVar19)) {
                      iVar18 = 0;
                    }
                    else if (2147483647.0 <= dVar19) {
                      iVar18 = 0x7fffffff;
                    }
                    else if (dVar19 <= -2147483648.0) {
                      iVar18 = -0x80000000;
                    }
                    else {
                      iVar18 = (int)dVar19;
                    }
                    if (iVar17 != 0) {
                      dVar19 = *(double *)(lVar14 + 0xa8);
                      dVar20 = *(double *)(lVar14 + 200);
                      dVar21 = *(double *)(lVar14 + 0xe8);
                      dVar22 = *(double *)(lVar14 + 0x108);
                      pBVar24._0_4_ = (BasisNoise *)(float)*(double *)(lVar14 + 0x68);
                      fVar23 = (float)*(double *)(lVar14 + 0x88);
                      pNVar8 = (NoiseCache *)(*(code *)getSharedNoiseCache()::cache)();
                      puVar6 = getSharedNoiseCache()::cache;
                      uVar4 = _UNK_102970ca8;
                      uVar3 = _DAT_102970ca0;
                      iVar16 = 0;
                      do {
                        NoiseOperations::BasisNoise::BasisNoise
                                  (pBVar24._0_4_,fVar23,(float)dVar19,(float)dVar20,auStack_ad0,
                                   param_1,param_2,iVar1,uVar7,iVar16 != 0);
                        pbVar9 = (byte *)(*(code *)puVar6)(&getSharedNoiseCache()::cache);
                        if ((*pbVar9 & 1) == 0) {
                          puVar11 = (undefined8 *)(*(code *)puVar5)(&getSharedNoiseCache()::cache);
                          *puVar11 = 1;
                          *(undefined4 *)(puVar11 + 1) = 5;
                          puVar11[3] = uVar4;
                          puVar11[2] = uVar3;
                          puVar12 = operator_new__(0x20);
                          puVar12[1] = 0;
                          *puVar12 = 0;
                          puVar12[3] = 0;
                          puVar12[2] = 0;
                          puVar11[4] = puVar12;
                          *(undefined1 *)(puVar11 + 5) = 0;
                          *(undefined8 *)((long)puVar11 + 0x34) = 0;
                          *(undefined8 *)((long)puVar11 + 0x2c) = 0;
                          *(undefined4 *)((long)puVar11 + 0x3c) = 0;
                          puVar11[8] = 5;
                          pvVar10 = operator_new__(0x14);
                          lVar14 = (*(code *)puVar5)(pvVar10,&getSharedNoiseCache()::cache);
                          *(undefined8 *)(lVar14 + 0x48) = extraout_x8;
                          __tlv_atexit(NoiseCache::~NoiseCache,lVar14,0x100000000);
                          puVar13 = (undefined1 *)(*(code *)puVar6)(&getSharedNoiseCache()::cache);
                          *puVar13 = 1;
                        }
                        if (local_a4 == '\0') {
                          pvVar10 = (void *)NoiseCache::getFloatRegister(pNVar8,local_ac8);
                          if (*(long *)(pNVar8 + 0x10) != 0) {
                            _bzero(pvVar10,*(long *)(pNVar8 + 0x10) << 2);
                          }
                        }
                        Noise::noise((Noise *)local_b4,local_b4._4_4_,local_ac,local_a8,auStack_abc,
                                     local_ac8,uStack_ac4,local_ac0,pNVar8);
                        pBVar24._0_4_ = (BasisNoise *)((float)pBVar24._0_4_ * (float)dVar21);
                        fVar23 = fVar23 * (float)dVar22;
                        iVar1 = iVar1 + iVar18;
                        iVar16 = iVar16 + 1;
                      } while (iVar17 != iVar16);
                    }
                    if (*(long *)PTR____stack_chk_guard_102d481b8 == local_a0) {
                      return;
                    }
                    /* WARNING: Subroutine does not return */
                    ___stack_chk_fail();
                  }
                  uVar7 = ___cxa_allocate_exception(0x10);
                  NoiseExpressionConstant::getInvalidParameterError
                            ((char *)(lVar14 + 0x120),"octave_seed0_shift");
                }
                else {
                  uVar7 = ___cxa_allocate_exception(0x10);
                  NoiseExpressionConstant::getInvalidParameterError
                            ((char *)(lVar14 + 0x100),"octave_output_scale_multiplier");
                }
              }
              else {
                uVar7 = ___cxa_allocate_exception(0x10);
                NoiseExpressionConstant::getInvalidParameterError
                          ((char *)(lVar14 + 0xe0),"octave_input_scale_multiplier");
              }
            }
            else {
              uVar7 = ___cxa_allocate_exception(0x10);
              NoiseExpressionConstant::getInvalidParameterError((char *)(lVar14 + 0xc0),"offset_y");
            }
          }
          else {
            uVar7 = ___cxa_allocate_exception(0x10);
            NoiseExpressionConstant::getInvalidParameterError((char *)(lVar14 + 0xa0),"offset_x");
          }
        }
        else {
          uVar7 = ___cxa_allocate_exception(0x10);
          NoiseExpressionConstant::getInvalidParameterError((char *)(lVar14 + 0x80),"output_scale");
        }
      }
      else {
        uVar7 = ___cxa_allocate_exception(0x10);
        NoiseExpressionConstant::getInvalidParameterError((char *)(lVar14 + 0x60),"input_scale");
      }
    }
    else {
      uVar7 = ___cxa_allocate_exception(0x10);
      NoiseExpressionConstant::getInvalidParameterError((char *)(lVar14 + 0x40),"octaves");
    }
  }
  else {
    uVar7 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(pcVar15,"seed0");
  }
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(uVar7,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



// ===== BasisNoise  @ 0x1015ff718 =====

/* NoiseOperations::BasisNoise::BasisNoise(NoiseRegisterIndex, std::array<NoiseRegisterIndex, 2ul>
   const&, unsigned int, unsigned int, float, float, float, float, bool) */

BasisNoise * __thiscall
NoiseOperations::BasisNoise::BasisNoise
          (float param_1,undefined4 param_2,float param_3,float param_4,BasisNoise *this,
          undefined4 param_6,undefined8 *param_7,int param_8,undefined8 param_9,BasisNoise param_10)

{
  RuntimeError *this_00;
  undefined8 uVar1;
  
  uVar1 = *param_7;
  *(undefined4 *)(this + 8) = param_6;
  *(undefined8 *)(this + 0xc) = uVar1;
  *(undefined ***)this = &PTR__BasisNoise_102f850b0;
  _bzero(this + 0x21c,0x800);
  Noise::setSeed((Noise *)(this + 0x14),param_8 + ((uint)((ulong)param_9 >> 8) & 0xffffff) * 7,
                 (uchar)param_9);
  *(float *)(this + 0xa1c) = param_1;
  *(undefined4 *)(this + 0xa20) = param_2;
  *(float *)(this + 0xa24) = param_3;
  *(float *)(this + 0xa28) = param_4;
  this[0xa2c] = param_10;
  if ((param_1 < 0.0) || (ABS(param_1) == INFINITY)) {
    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError
              (this_00,"MultioctaveNoise::input_scale must be >= 0 and can\'t be infinite");
  }
  else if (ABS(param_3) == INFINITY) {
    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(this_00,"MultioctaveNoise::offset_x can\'t be infinite");
  }
  else {
    if (ABS(param_4) != INFINITY) {
      return this;
    }
    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(this_00,"MultioctaveNoise::offset_y can\'t be infinite");
  }
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this_00,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



// ===== setSeed  @ 0x1015dae7c =====

/* Noise::setSeed(unsigned int, unsigned char) */

void __thiscall Noise::setSeed(Noise *this,uint param_1,uchar param_2)

{
  uint uVar1;
  Noise *pNVar2;
  Noise *pNVar3;
  uint uVar4;
  undefined1 uVar5;
  Noise NVar6;
  long lVar7;
  uint uVar8;
  ulong uVar9;
  long lVar10;
  undefined8 uVar11;
  undefined8 uVar12;
  undefined8 uVar13;
  undefined8 uVar14;
  undefined8 uVar15;
  byte bVar16;
  byte bVar18;
  byte bVar19;
  byte bVar20;
  byte bVar21;
  byte bVar22;
  byte bVar23;
  undefined8 uVar17;
  byte bVar24;
  ulong uVar25;
  undefined8 uVar26;
  undefined8 local_150;
  undefined8 uStack_148;
  undefined8 uStack_140;
  undefined8 uStack_138;
  undefined8 local_130;
  undefined8 uStack_128;
  undefined8 uStack_120;
  undefined8 uStack_118;
  undefined8 local_110;
  undefined8 uStack_108;
  undefined8 uStack_100;
  undefined8 uStack_f8;
  undefined8 local_f0;
  undefined8 uStack_e8;
  undefined8 uStack_e0;
  undefined8 uStack_d8;
  undefined8 local_d0;
  undefined8 uStack_c8;
  undefined8 uStack_c0;
  undefined8 uStack_b8;
  undefined8 local_b0;
  undefined8 uStack_a8;
  undefined8 uStack_a0;
  undefined8 uStack_98;
  undefined8 local_90;
  undefined8 uStack_88;
  undefined8 uStack_80;
  undefined8 uStack_78;
  undefined8 local_70;
  undefined8 uStack_68;
  undefined8 uStack_60;
  undefined8 uStack_58;
  long local_48;
  
  local_48 = *(long *)PTR____stack_chk_guard_102d481b8;
  _memcpy(this,&defaultNoise,0x206);
  pNVar2 = this + 0x208;
  if (((Noise *)&DAT_103350164 < this + 0xa04 && pNVar2 < (Noise *)0x103350960) ||
     (((Noise *)0x103350963 >= this + 0x20c && (Noise *)((long)&DAT_103350164 + 3U) < this + 0xa08)
      && ((Noise *)0x103350963 < this + 0x20c ||
         this + 0xa08 != (Noise *)((long)&DAT_103350164 + 4U)))) {
    lVar10 = 0;
    do {
      *(undefined8 *)(pNVar2 + lVar10) = *(undefined8 *)((long)&DAT_103350164 + lVar10);
      lVar10 = lVar10 + 8;
    } while (lVar10 != 0x800);
  }
  else {
    lVar10 = 0;
    do {
      uVar13 = *(undefined8 *)((long)&DAT_103350164 + lVar10);
      uVar12 = *(undefined8 *)(lVar10 + 0x10335017c);
      uVar11 = *(undefined8 *)(&DAT_103350174 + lVar10);
      uVar15 = *(undefined8 *)(lVar10 + 0x10335018c);
      uVar14 = *(undefined8 *)(&DAT_103350184 + lVar10);
      uVar26 = *(undefined8 *)(lVar10 + 0x10335019c);
      uVar17 = *(undefined8 *)(&DAT_103350194 + lVar10);
      pNVar3 = pNVar2 + lVar10;
      *(undefined8 *)(pNVar3 + 8) = *(undefined8 *)((long)&DAT_10335016c + lVar10);
      *(undefined8 *)pNVar3 = uVar13;
      *(undefined8 *)(pNVar3 + 0x18) = uVar12;
      *(undefined8 *)(pNVar3 + 0x10) = uVar11;
      *(undefined8 *)(pNVar3 + 0x28) = uVar15;
      *(undefined8 *)(pNVar3 + 0x20) = uVar14;
      *(undefined8 *)(pNVar3 + 0x38) = uVar26;
      *(undefined8 *)(pNVar3 + 0x30) = uVar17;
      lVar10 = lVar10 + 0x40;
    } while (lVar10 != 0x800);
  }
  *(uint *)this = param_1;
  this[4] = (Noise)param_2;
  uVar9 = DAT_1029735e0;
  uVar13 = DAT_1029735d8;
  uVar12 = DAT_1029735d0;
  uVar11 = DAT_1029735c8;
  if (param_1 < 0x156) {
    param_1 = 0x155;
  }
  uStack_88 = *(undefined8 *)(this + 0xce);
  local_90 = *(undefined8 *)(this + 0xc6);
  uStack_78 = *(undefined8 *)(this + 0xde);
  uStack_80 = *(undefined8 *)(this + 0xd6);
  uStack_68 = *(undefined8 *)(this + 0xee);
  local_70 = *(undefined8 *)(this + 0xe6);
  uStack_58 = *(undefined8 *)(this + 0xfe);
  uStack_60 = *(undefined8 *)(this + 0xf6);
  uStack_c8 = *(undefined8 *)(this + 0x8e);
  local_d0 = *(undefined8 *)(this + 0x86);
  uStack_b8 = *(undefined8 *)(this + 0x9e);
  uStack_c0 = *(undefined8 *)(this + 0x96);
  uStack_a8 = *(undefined8 *)(this + 0xae);
  local_b0 = *(undefined8 *)(this + 0xa6);
  uStack_98 = *(undefined8 *)(this + 0xbe);
  uStack_a0 = *(undefined8 *)(this + 0xb6);
  uStack_108 = *(undefined8 *)(this + 0x4e);
  local_110 = *(undefined8 *)(this + 0x46);
  uStack_f8 = *(undefined8 *)(this + 0x5e);
  uStack_100 = *(undefined8 *)(this + 0x56);
  uStack_e8 = *(undefined8 *)(this + 0x6e);
  local_f0 = *(undefined8 *)(this + 0x66);
  uStack_d8 = *(undefined8 *)(this + 0x7e);
  uStack_e0 = *(undefined8 *)(this + 0x76);
  uStack_148 = *(undefined8 *)(this + 0xe);
  local_150 = *(undefined8 *)(this + 6);
  uStack_138 = *(undefined8 *)(this + 0x1e);
  uStack_140 = *(undefined8 *)(this + 0x16);
  uStack_128 = *(undefined8 *)(this + 0x2e);
  local_130 = *(undefined8 *)(this + 0x26);
  uStack_118 = *(undefined8 *)(this + 0x3e);
  uStack_120 = *(undefined8 *)(this + 0x36);
  lVar10 = 0xff;
  uVar17 = CONCAT44(param_1,param_1);
  do {
    uVar1 = (int)lVar10 + 1;
    param_1 = (param_1 & 0xffffe) << 0xc | (param_1 ^ param_1 << 0xd) >> 0x13;
    uVar25 = NEON_ushl(uVar17,DAT_1029735d0,4);
    uVar26 = NEON_ushl(uVar17,DAT_1029735c8,4);
    uVar17 = NEON_ushl(CONCAT17((byte)((ulong)uVar26 >> 0x38) ^ (byte)((ulong)uVar17 >> 0x38),
                                CONCAT16((byte)((ulong)uVar26 >> 0x30) ^
                                         (byte)((ulong)uVar17 >> 0x30),
                                         CONCAT15((byte)((ulong)uVar26 >> 0x28) ^
                                                  (byte)((ulong)uVar17 >> 0x28),
                                                  CONCAT14((byte)((ulong)uVar26 >> 0x20) ^
                                                           (byte)((ulong)uVar17 >> 0x20),
                                                           CONCAT13((byte)((ulong)uVar26 >> 0x18) ^
                                                                    (byte)((ulong)uVar17 >> 0x18),
                                                                    CONCAT12((byte)((ulong)uVar26 >>
                                                                                   0x10) ^
                                                                             (byte)((ulong)uVar17 >>
                                                                                   0x10),
                                                                             CONCAT11((byte)((ulong)
                                                  uVar26 >> 8) ^ (byte)((ulong)uVar17 >> 8),
                                                  (byte)uVar26 ^ (byte)uVar17))))))),DAT_1029735d8,4
                      );
    uVar25 = uVar25 & DAT_1029735e0;
    bVar16 = (byte)uVar17 | (byte)uVar25;
    bVar18 = (byte)((ulong)uVar17 >> 8) | (byte)(uVar25 >> 8);
    bVar19 = (byte)((ulong)uVar17 >> 0x10) | (byte)(uVar25 >> 0x10);
    bVar20 = (byte)((ulong)uVar17 >> 0x18) | (byte)(uVar25 >> 0x18);
    bVar21 = (byte)((ulong)uVar17 >> 0x20) | (byte)(uVar25 >> 0x20);
    bVar22 = (byte)((ulong)uVar17 >> 0x28) | (byte)(uVar25 >> 0x28);
    bVar23 = (byte)((ulong)uVar17 >> 0x30) | (byte)(uVar25 >> 0x30);
    bVar24 = (byte)((ulong)uVar17 >> 0x38) | (byte)(uVar25 >> 0x38);
    uVar17 = CONCAT17(bVar24,CONCAT16(bVar23,CONCAT15(bVar22,CONCAT14(bVar21,CONCAT13(bVar20,
                                                  CONCAT12(bVar19,CONCAT11(bVar18,bVar16)))))));
    uVar4 = CONCAT13(bVar24 ^ bVar20,
                     CONCAT12(bVar23 ^ bVar19,CONCAT11(bVar22 ^ bVar18,bVar21 ^ bVar16))) ^ param_1;
    uVar8 = 0;
    if (uVar1 != 0) {
      uVar8 = uVar4 / uVar1;
    }
    uVar25 = (ulong)(uVar4 - uVar8 * uVar1);
    uVar5 = *(undefined1 *)((long)&local_150 + lVar10);
    *(undefined1 *)((long)&local_150 + lVar10) = *(undefined1 *)((long)&local_150 + uVar25);
    *(undefined1 *)((long)&local_150 + uVar25) = uVar5;
    lVar10 = lVar10 + -1;
  } while (lVar10 != 0);
  this[5] = *(Noise *)((long)&local_150 + (ulong)param_2);
  lVar10 = 0x105;
  do {
    uVar4 = (int)lVar10 - 5;
    param_1 = (param_1 & 0xffffe) << 0xc | (param_1 ^ param_1 << 0xd) >> 0x13;
    uVar26 = NEON_ushl(uVar17,uVar11,4);
    uVar25 = NEON_ushl(uVar17,uVar12,4);
    uVar17 = NEON_ushl(CONCAT17((byte)((ulong)uVar26 >> 0x38) ^ (byte)((ulong)uVar17 >> 0x38),
                                CONCAT16((byte)((ulong)uVar26 >> 0x30) ^
                                         (byte)((ulong)uVar17 >> 0x30),
                                         CONCAT15((byte)((ulong)uVar26 >> 0x28) ^
                                                  (byte)((ulong)uVar17 >> 0x28),
                                                  CONCAT14((byte)((ulong)uVar26 >> 0x20) ^
                                                           (byte)((ulong)uVar17 >> 0x20),
                                                           CONCAT13((byte)((ulong)uVar26 >> 0x18) ^
                                                                    (byte)((ulong)uVar17 >> 0x18),
                                                                    CONCAT12((byte)((ulong)uVar26 >>
                                                                                   0x10) ^
                                                                             (byte)((ulong)uVar17 >>
                                                                                   0x10),
                                                                             CONCAT11((byte)((ulong)
                                                  uVar26 >> 8) ^ (byte)((ulong)uVar17 >> 8),
                                                  (byte)uVar26 ^ (byte)uVar17))))))),uVar13,4);
    uVar25 = uVar25 & uVar9;
    bVar16 = (byte)uVar17 | (byte)uVar25;
    bVar18 = (byte)((ulong)uVar17 >> 8) | (byte)(uVar25 >> 8);
    bVar19 = (byte)((ulong)uVar17 >> 0x10) | (byte)(uVar25 >> 0x10);
    bVar20 = (byte)((ulong)uVar17 >> 0x18) | (byte)(uVar25 >> 0x18);
    bVar21 = (byte)((ulong)uVar17 >> 0x20) | (byte)(uVar25 >> 0x20);
    bVar22 = (byte)((ulong)uVar17 >> 0x28) | (byte)(uVar25 >> 0x28);
    bVar23 = (byte)((ulong)uVar17 >> 0x30) | (byte)(uVar25 >> 0x30);
    bVar24 = (byte)((ulong)uVar17 >> 0x38) | (byte)(uVar25 >> 0x38);
    uVar17 = CONCAT17(bVar24,CONCAT16(bVar23,CONCAT15(bVar22,CONCAT14(bVar21,CONCAT13(bVar20,
                                                  CONCAT12(bVar19,CONCAT11(bVar18,bVar16)))))));
    uVar1 = CONCAT13(bVar24 ^ bVar20,
                     CONCAT12(bVar23 ^ bVar19,CONCAT11(bVar22 ^ bVar18,bVar21 ^ bVar16))) ^ param_1;
    uVar8 = 0;
    if (uVar4 != 0) {
      uVar8 = uVar1 / uVar4;
    }
    uVar25 = (ulong)(uVar1 - uVar8 * uVar4);
    NVar6 = this[lVar10];
    this[lVar10] = this[uVar25 + 6];
    this[uVar25 + 6] = NVar6;
    lVar10 = lVar10 + -1;
  } while (lVar10 != 6);
  lVar10 = 0;
  do {
    uVar1 = (int)lVar10 + 0x100;
    param_1 = (param_1 & 0xffffe) << 0xc | (param_1 ^ param_1 << 0xd) >> 0x13;
    uVar26 = NEON_ushl(uVar17,uVar11,4);
    uVar25 = NEON_ushl(uVar17,uVar12,4);
    uVar17 = NEON_ushl(CONCAT17((byte)((ulong)uVar26 >> 0x38) ^ (byte)((ulong)uVar17 >> 0x38),
                                CONCAT16((byte)((ulong)uVar26 >> 0x30) ^
                                         (byte)((ulong)uVar17 >> 0x30),
                                         CONCAT15((byte)((ulong)uVar26 >> 0x28) ^
                                                  (byte)((ulong)uVar17 >> 0x28),
                                                  CONCAT14((byte)((ulong)uVar26 >> 0x20) ^
                                                           (byte)((ulong)uVar17 >> 0x20),
                                                           CONCAT13((byte)((ulong)uVar26 >> 0x18) ^
                                                                    (byte)((ulong)uVar17 >> 0x18),
                                                                    CONCAT12((byte)((ulong)uVar26 >>
                                                                                   0x10) ^
                                                                             (byte)((ulong)uVar17 >>
                                                                                   0x10),
                                                                             CONCAT11((byte)((ulong)
                                                  uVar26 >> 8) ^ (byte)((ulong)uVar17 >> 8),
                                                  (byte)uVar26 ^ (byte)uVar17))))))),uVar13,4);
    uVar25 = uVar25 & uVar9;
    bVar16 = (byte)uVar17 | (byte)uVar25;
    bVar18 = (byte)((ulong)uVar17 >> 8) | (byte)(uVar25 >> 8);
    bVar19 = (byte)((ulong)uVar17 >> 0x10) | (byte)(uVar25 >> 0x10);
    bVar20 = (byte)((ulong)uVar17 >> 0x18) | (byte)(uVar25 >> 0x18);
    bVar21 = (byte)((ulong)uVar17 >> 0x20) | (byte)(uVar25 >> 0x20);
    bVar22 = (byte)((ulong)uVar17 >> 0x28) | (byte)(uVar25 >> 0x28);
    bVar23 = (byte)((ulong)uVar17 >> 0x30) | (byte)(uVar25 >> 0x30);
    bVar24 = (byte)((ulong)uVar17 >> 0x38) | (byte)(uVar25 >> 0x38);
    uVar17 = CONCAT17(bVar24,CONCAT16(bVar23,CONCAT15(bVar22,CONCAT14(bVar21,CONCAT13(bVar20,
                                                  CONCAT12(bVar19,CONCAT11(bVar18,bVar16)))))));
    uVar4 = CONCAT13(bVar24 ^ bVar20,
                     CONCAT12(bVar23 ^ bVar19,CONCAT11(bVar22 ^ bVar18,bVar21 ^ bVar16))) ^ param_1;
    uVar8 = 0;
    if (uVar1 != 0) {
      uVar8 = uVar4 / uVar1;
    }
    uVar25 = (ulong)(uVar4 - uVar8 * uVar1);
    NVar6 = this[lVar10 + 0x205];
    this[lVar10 + 0x205] = this[uVar25 + 0x106];
    this[uVar25 + 0x106] = NVar6;
    lVar10 = lVar10 + -1;
  } while (lVar10 != -0xff);
  lVar10 = 0x140;
  do {
    uVar4 = (int)lVar10 - 0x40;
    uVar26 = NEON_ushl(uVar17,uVar11,4);
    uVar25 = NEON_ushl(uVar17,uVar12,4);
    uVar17 = NEON_ushl(CONCAT17((byte)((ulong)uVar26 >> 0x38) ^ (byte)((ulong)uVar17 >> 0x38),
                                CONCAT16((byte)((ulong)uVar26 >> 0x30) ^
                                         (byte)((ulong)uVar17 >> 0x30),
                                         CONCAT15((byte)((ulong)uVar26 >> 0x28) ^
                                                  (byte)((ulong)uVar17 >> 0x28),
                                                  CONCAT14((byte)((ulong)uVar26 >> 0x20) ^
                                                           (byte)((ulong)uVar17 >> 0x20),
                                                           CONCAT13((byte)((ulong)uVar26 >> 0x18) ^
                                                                    (byte)((ulong)uVar17 >> 0x18),
                                                                    CONCAT12((byte)((ulong)uVar26 >>
                                                                                   0x10) ^
                                                                             (byte)((ulong)uVar17 >>
                                                                                   0x10),
                                                                             CONCAT11((byte)((ulong)
                                                  uVar26 >> 8) ^ (byte)((ulong)uVar17 >> 8),
                                                  (byte)uVar26 ^ (byte)uVar17))))))),uVar13,4);
    uVar25 = uVar25 & uVar9;
    bVar16 = (byte)uVar17 | (byte)uVar25;
    bVar18 = (byte)((ulong)uVar17 >> 8) | (byte)(uVar25 >> 8);
    bVar19 = (byte)((ulong)uVar17 >> 0x10) | (byte)(uVar25 >> 0x10);
    bVar20 = (byte)((ulong)uVar17 >> 0x18) | (byte)(uVar25 >> 0x18);
    bVar21 = (byte)((ulong)uVar17 >> 0x20) | (byte)(uVar25 >> 0x20);
    bVar22 = (byte)((ulong)uVar17 >> 0x28) | (byte)(uVar25 >> 0x28);
    bVar23 = (byte)((ulong)uVar17 >> 0x30) | (byte)(uVar25 >> 0x30);
    bVar24 = (byte)((ulong)uVar17 >> 0x38) | (byte)(uVar25 >> 0x38);
    uVar17 = CONCAT17(bVar24,CONCAT16(bVar23,CONCAT15(bVar22,CONCAT14(bVar21,CONCAT13(bVar20,
                                                  CONCAT12(bVar19,CONCAT11(bVar18,bVar16)))))));
    param_1 = (param_1 & 0xffffe) << 0xc | (param_1 ^ param_1 << 0xd) >> 0x13;
    uVar1 = CONCAT13(bVar24 ^ bVar20,
                     CONCAT12(bVar23 ^ bVar19,CONCAT11(bVar22 ^ bVar18,bVar21 ^ bVar16))) ^ param_1;
    uVar8 = 0;
    if (uVar4 != 0) {
      uVar8 = uVar1 / uVar4;
    }
    lVar7 = (ulong)(uVar1 - uVar8 * uVar4) * 8;
    uVar26 = *(undefined8 *)(this + lVar10 * 8);
    *(undefined8 *)(this + lVar10 * 8) = *(undefined8 *)(pNVar2 + lVar7);
    *(undefined8 *)(pNVar2 + lVar7) = uVar26;
    lVar10 = lVar10 + -1;
  } while (lVar10 != 0x41);
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_48) {
    return;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}



// ===== ___cxa_allocate_exception  @ 0x1000ec8f0 =====

undefined8 ___cxa_allocate_exception(ulong param_1)

{
  size_t sVar1;
  long lVar2;
  long lVar3;
  undefined8 uVar4;
  
  sVar1 = __cxxabiv1::cxa_exception_size_from_exception_thrown_size(param_1);
  lVar2 = __cxxabiv1::get_cxa_exception_offset();
  lVar3 = __cxxabiv1::__aligned_malloc_with_fallback(lVar2 + sVar1);
  if (lVar3 == 0) {
                    /* WARNING: Subroutine does not return */
    std::terminate();
  }
  _bzero((__cxa_exception *)(lVar3 + lVar2),sVar1);
  uVar4 = __cxxabiv1::thrown_object_from_cxa_exception((__cxa_exception *)(lVar3 + lVar2));
  return uVar4;
}



// ===== RuntimeError  @ 0x10011f7b4 =====

/* RuntimeError::RuntimeError(char const*) */

RuntimeError * __thiscall RuntimeError::RuntimeError(RuntimeError *this,char *param_1)

{
  undefined8 *puVar1;
  long *plVar2;
  
  puVar1 = (undefined8 *)std::runtime_error::runtime_error((runtime_error *)this,param_1);
  *puVar1 = &PTR__RuntimeError_102d65d58;
  if ((logStackTraceOnNonCrticalException & 1) != 0) {
    Logging::log("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/RuntimeError.cpp"
                 ,0x18,9,"%s");
    if ((_global == 0) || (plVar2 = *(long **)(_global + 0x2c8), plVar2 == (long *)0x0)) {
      Logger::writeStacktrace((WriteStream *)&StdoutWriteStream::instance,(StackTraceInfo *)0x0);
    }
    else {
      (**(code **)(*plVar2 + 0x18))(plVar2,0);
    }
  }
  return this;
}



// ===== ___cxa_throw  @ 0x1000ecc60 =====

void ___cxa_throw(void *param_1,undefined8 param_2,undefined8 param_3)

{
  long lVar1;
  __cxa_exception *p_Var2;
  undefined8 uVar3;
  
  lVar1 = ___cxa_get_globals();
  p_Var2 = (__cxa_exception *)__cxxabiv1::cxa_exception_from_thrown_object(param_1);
  uVar3 = std::get_unexpected();
  *(undefined8 *)(p_Var2 + 0x20) = uVar3;
  uVar3 = std::get_terminate();
  *(undefined8 *)(p_Var2 + 0x28) = uVar3;
  *(undefined8 *)(p_Var2 + 0x10) = param_2;
  *(undefined8 *)(p_Var2 + 0x18) = param_3;
  __cxxabiv1::setOurExceptionClass((_Unwind_Exception *)(p_Var2 + 0x60));
  *(undefined8 *)(p_Var2 + 8) = 1;
  *(int *)(lVar1 + 8) = *(int *)(lVar1 + 8) + 1;
  *(code **)(p_Var2 + 0x68) = __cxxabiv1::exception_cleanup_func;
  __Unwind_RaiseException((_Unwind_Exception *)(p_Var2 + 0x60));
                    /* WARNING: Subroutine does not return */
  __cxxabiv1::failed_throw(p_Var2);
}



// ===== getInvalidParameterError  @ 0x1015dd34c =====

/* WARNING: Removing unreachable block (ram,0x0001015dd514) */
/* WARNING: Removing unreachable block (ram,0x0001015dd524) */
/* NoiseExpressionConstant::getInvalidParameterError(char const*, char const*) const */

void NoiseExpressionConstant::getInvalidParameterError(char *param_1,char *param_2)

{
  long *plVar1;
  runtime_error *in_x8;
  string local_38 [24];
  
  switch(*param_1) {
  case '\0':
    break;
  case '\x01':
    break;
  case '\x02':
    break;
  case '\x03':
    break;
  case '\x04':
    break;
  default:
                    /* WARNING: Subroutine does not return */
    Logging::logEnumAndAbortOrThrow<NoiseExpressionConstant::Type>
              ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Noise/NoiseExpressionConstant.cpp"
               ,0xb4,9);
  }
  ssprintf("Parameter \'%s\' expects %s, %s given.",local_38);
  std::runtime_error::runtime_error(in_x8,local_38);
  *(undefined ***)in_x8 = &PTR__RuntimeError_102d65d58;
  if ((RuntimeError::logStackTraceOnNonCrticalException & 1) != 0) {
    Logging::log("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/RuntimeError.cpp"
                 ,0x18,9,"%s");
    if ((_global == 0) || (plVar1 = *(long **)(_global + 0x2c8), plVar1 == (long *)0x0)) {
      Logger::writeStacktrace((WriteStream *)&StdoutWriteStream::instance,(StackTraceInfo *)0x0);
    }
    else {
      (**(code **)(*plVar1 + 0x18))(plVar1,0);
    }
  }
  return;
}



// ===== log  @ 0x1000f3b68 =====

/* Logging::log(char const*, unsigned int, LogLevel, char const*, ...) */

void Logging::log(undefined8 param_1,undefined8 param_2,undefined8 param_3,char *param_4,...)

{
  void *local_50 [2];
  char local_39;
  
  vssprintf(param_4,&stack0x00000000);
  logRecord(param_1,param_2,param_3,local_50);
  if (-1 < local_39) {
    return;
  }
  operator_delete(local_50[0]);
  return;
}



// ===== writeStacktrace  @ 0x101a80184 =====

/* Logger::writeStacktrace(WriteStream*, StackTraceInfo*) */

void Logger::writeStacktrace(WriteStream *param_1,StackTraceInfo *param_2)

{
  ulong uVar1;
  undefined8 *puVar2;
  undefined8 uVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  char *pcVar6;
  
  if (*PTR_skipStacktrace_102d52ed8 != '\0') {
    if (param_2 != (StackTraceInfo *)0x0) {
      *(undefined2 *)param_2 = 0xffff;
    }
    if (*PTR_skipStacktraceSilent_102d52ee0 != '\0') {
      return;
    }
    pcVar6 = operator_new(0x30);
    pcVar6[0x20] = '\n';
    uVar5 = s_Logger__writeStacktrace_skipped__102c20501._24_8_;
    uVar4 = s_Logger__writeStacktrace_skipped__102c20501._16_8_;
    uVar3 = s_Logger__writeStacktrace_skipped__102c20501._0_8_;
    pcVar6[0x21] = '\0';
    *(undefined8 *)(pcVar6 + 8) = s_Logger__writeStacktrace_skipped__102c20501._8_8_;
    *(undefined8 *)pcVar6 = uVar3;
    *(undefined8 *)(pcVar6 + 0x18) = uVar5;
    *(undefined8 *)(pcVar6 + 0x10) = uVar4;
    (**(code **)(*(long *)param_1 + 0x10))(param_1,pcVar6,0x21);
    goto LAB_101a80374;
  }
  uVar1 = DAT_103350c70;
  if (-1 < (char)DAT_103350c78._7_1_) {
    uVar1 = (ulong)DAT_103350c78._7_1_;
  }
  if (uVar1 != 0) {
    puVar2 = _loggerPrefix;
    if (-1 < (char)DAT_103350c78._7_1_) {
      puVar2 = &_loggerPrefix;
    }
    (**(code **)(*(long *)param_1 + 0x10))(param_1,puVar2);
    (**(code **)(*(long *)param_1 + 0x10))(param_1," ",1);
  }
  (**(code **)(*(long *)param_1 + 0x10))
            (param_1,"Factorio crashed. Generating symbolized stacktrace, please wait ...\n",0x44);
  (**(code **)(*(long *)param_1 + 0x18))(param_1);
  if (Util::backtraceState == 0) {
    Util::backtraceState = _backtrace_create_state(0,0,Util::errorCallback,0);
    if (Util::backtraceState != 0) goto LAB_101a80288;
  }
  else {
LAB_101a80288:
    _backtrace_full(Util::backtraceState,0,Util::stackFrameCallback,Util::errorCallback,param_1);
  }
  uVar1 = DAT_103350c70;
  if (-1 < (char)DAT_103350c78._7_1_) {
    uVar1 = (ulong)DAT_103350c78._7_1_;
  }
  if (uVar1 != 0) {
    puVar2 = _loggerPrefix;
    if (-1 < (char)DAT_103350c78._7_1_) {
      puVar2 = &_loggerPrefix;
    }
    (**(code **)(*(long *)param_1 + 0x10))(param_1,puVar2);
    (**(code **)(*(long *)param_1 + 0x10))(param_1," ",1);
  }
  pcVar6 = operator_new(0x20);
  uVar3 = s_Stack_trace_logging_done_102c20568._0_8_;
  *(ulong *)(pcVar6 + 8) =
       CONCAT71(s_Stack_trace_logging_done_102c20568._9_7_,s_Stack_trace_logging_done_102c20568[8]);
  *(undefined8 *)pcVar6 = uVar3;
  uVar3 = CONCAT17(s_Stack_trace_logging_done_102c20568[0x10],
                   s_Stack_trace_logging_done_102c20568._9_7_);
  *(undefined8 *)(pcVar6 + 0x11) = s_Stack_trace_logging_done_102c20568._17_8_;
  *(undefined8 *)(pcVar6 + 9) = uVar3;
  pcVar6[0x19] = '\0';
  (**(code **)(*(long *)param_1 + 0x10))(param_1,pcVar6,0x19);
LAB_101a80374:
  operator_delete(pcVar6);
  return;
}



// ===== ssprintf  @ 0x1025ecd68 =====

/* ssprintf(char const*, ...) */

void ssprintf(char *param_1,...)

{
  string *psVar1;
  ulong uVar2;
  string sVar3;
  uint uVar4;
  char *pcVar5;
  size_t sVar6;
  string *in_x8;
  string *psVar7;
  
  *(undefined8 *)in_x8 = 0;
  *(undefined8 *)(in_x8 + 8) = 0;
  *(undefined8 *)(in_x8 + 0x10) = 0;
  pcVar5 = (char *)(*(code *)_ssprintf_buffer)();
  uVar4 = _trio_vsnprintf(pcVar5,0x200,param_1,&stack0x00000000);
  if ((int)uVar4 < 0x200) {
    sVar6 = _strlen(pcVar5);
    std::string::__assign_external(in_x8,pcVar5,sVar6);
  }
  else {
    std::string::append((ulong)in_x8,(char)uVar4);
    psVar1 = *(string **)in_x8;
    if (-1 < (char)in_x8[0x17]) {
      psVar1 = in_x8;
    }
    _trio_vsnprintf(psVar1,(long)(int)(uVar4 + 1),param_1,&stack0x00000000);
    sVar3 = in_x8[0x17];
    psVar7 = *(string **)in_x8;
    psVar1 = psVar7;
    if (-1 < (char)sVar3) {
      psVar1 = in_x8;
    }
    sVar6 = _strnlen((char *)psVar1,(ulong)uVar4);
    uVar2 = *(ulong *)(in_x8 + 8);
    if (-1 < (char)sVar3) {
      uVar2 = (ulong)(byte)sVar3;
    }
    if (sVar6 < uVar2 || sVar6 - uVar2 == 0) {
      if (-1 < (char)sVar3) {
        in_x8[0x17] = SUB81(sVar6,0);
        in_x8[sVar6] = (string)0x0;
        return;
      }
      *(size_t *)(in_x8 + 8) = sVar6;
      psVar7[sVar6] = (string)0x0;
      return;
    }
    std::string::append((ulong)in_x8,(char)(sVar6 - uVar2));
  }
  return;
}



// ===== logEnumAndAbortOrThrow<NoiseExpressionConstant::Type>  @ 0x1015dd7c0 =====

/* void Logging::logEnumAndAbortOrThrow<NoiseExpressionConstant::Type>(char const*, unsigned int,
   LogLevel, NoiseExpressionConstant::Type) */

void Logging::logEnumAndAbortOrThrow<NoiseExpressionConstant::Type>(void)

{
                    /* WARNING: Subroutine does not return */
  logAndAbortOrThrow();
}



// ===== runtime_error  @ 0x1000298f8 =====

/* std::runtime_error::runtime_error(std::string const&) */

runtime_error * __thiscall std::runtime_error::runtime_error(runtime_error *this,string *param_1)

{
  char *pcVar1;
  
  exception::exception_abi_v160006_((exception *)this);
  *(undefined ***)this = &PTR__runtime_error_102d61000;
  pcVar1 = (char *)string::c_str_abi_v160006_(param_1);
  __libcpp_refstring::__libcpp_refstring((__libcpp_refstring *)(this + 8),pcVar1);
  return this;
}



// ===== getFloatRegister  @ 0x1014b34a4 =====

/* NoiseCache::getFloatRegister(NoiseRegisterIndex) */

long __thiscall NoiseCache::getFloatRegister(NoiseCache *this,uint param_2)

{
  RuntimeError *this_00;
  string asStack_48 [24];
  
  if (param_2 < *(uint *)(this + 8)) {
    return *(long *)(this + 0x48) + *(long *)this * (ulong)param_2 * 4;
  }
  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
  ssprintf("Noise register index %u out of range [0, %u)",asStack_48);
  RuntimeError::RuntimeError(this_00,asStack_48);
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this_00,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



// ===== RuntimeError  @ 0x1000f158c =====

/* RuntimeError::RuntimeError(std::string const&) */

RuntimeError * __thiscall RuntimeError::RuntimeError(RuntimeError *this,string *param_1)

{
  undefined8 *puVar1;
  long *plVar2;
  
  puVar1 = (undefined8 *)std::runtime_error::runtime_error((runtime_error *)this,param_1);
  *puVar1 = &PTR__RuntimeError_102d65d58;
  if ((logStackTraceOnNonCrticalException & 1) != 0) {
    Logging::log("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/RuntimeError.cpp"
                 ,0x18,9,"%s");
    if ((_global == 0) || (plVar2 = *(long **)(_global + 0x2c8), plVar2 == (long *)0x0)) {
      Logger::writeStacktrace((WriteStream *)&StdoutWriteStream::instance,(StackTraceInfo *)0x0);
    }
    else {
      (**(code **)(*plVar2 + 0x18))(plVar2,0);
    }
  }
  return this;
}



// ===== asNoiseLayerID  @ 0x1015dd638 =====

/* NoiseExpressionConstant::asNoiseLayerID(char const*) const */

ulong __thiscall
NoiseExpressionConstant::asNoiseLayerID(NoiseExpressionConstant *this,char *param_1)

{
  NoiseExpressionConstant *pNVar1;
  NoiseExpressionConstant NVar2;
  uint uVar3;
  ulong uVar4;
  undefined8 uVar5;
  double dVar6;
  
  switch(*this) {
  case (NoiseExpressionConstant)0x0:
  case (NoiseExpressionConstant)0x2:
  case (NoiseExpressionConstant)0x4:
    uVar5 = ___cxa_allocate_exception(0x10);
    getInvalidParameterError((char *)this,param_1);
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(uVar5,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  case (NoiseExpressionConstant)0x1:
    break;
  case (NoiseExpressionConstant)0x3:
    NVar2 = this[0x1f];
    pNVar1 = *(NoiseExpressionConstant **)(this + 8);
    if (-1 < (char)NVar2) {
      pNVar1 = this + 8;
    }
    uVar4 = *(ulong *)(this + 0x10);
    if (-1 < (char)NVar2) {
      uVar4 = (ulong)(byte)NVar2;
    }
    uVar3 = crc32_fast((void *)0x0,0,0);
    uVar4 = crc32_fast(pNVar1,uVar4,uVar3);
    return uVar4;
  default:
                    /* WARNING: Subroutine does not return */
    Logging::logEnumAndAbortOrThrow<NoiseExpressionConstant::Type>
              ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Noise/NoiseExpressionConstant.cpp"
               ,0x62,9);
  }
  dVar6 = *(double *)(this + 8);
  if (!NAN(dVar6)) {
    if (4294967295.0 <= dVar6) {
      return 0xffffffff;
    }
    if (0.0 < dVar6) {
      return (ulong)(uint)(int)dVar6;
    }
  }
  return 0;
}



// ===== crc32_fast  @ 0x10275dccc =====

/* crc32_fast(void const*, unsigned long, unsigned int) */

uint crc32_fast(void *param_1,ulong param_2,uint param_3)

{
  uint uVar1;
  uint uVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  uint uVar7;
  uint uVar8;
  uint uVar9;
  
  uVar9 = ~param_3;
  for (; 0x3f < param_2; param_2 = param_2 - 0x40) {
    uVar1 = *(uint *)((long)param_1 + 8);
    uVar4 = *(uint *)((long)param_1 + 0xc);
    uVar5 = *(uint *)((long)param_1 + 4);
    uVar9 = *(uint *)param_1 ^ uVar9;
    uVar2 = *(uint *)((long)param_1 + 0x18);
    uVar6 = *(uint *)((long)param_1 + 0x1c);
    uVar7 = *(uint *)((long)param_1 + 0x14);
    uVar3 = *(uint *)((long)param_1 + 0x28);
    uVar8 = *(uint *)((long)param_1 + 0x2c);
    uVar9 = *(uint *)((long)param_1 + 0x10) ^
            *(uint *)(&DAT_102b5aec0 + (ulong)(uVar9 >> 8 & 0xff) * 4) ^
            *(uint *)(&DAT_102b5b2c0 + (ulong)(uVar9 & 0xff) * 4) ^
            *(uint *)(&DAT_102b57ac0 + ((ulong)(uVar4 >> 0x10) & 0xff) * 4) ^
            *(uint *)(&DAT_102b57ec0 + ((ulong)(uVar4 >> 8) & 0xff) * 4) ^
            *(uint *)(&_Crc32Lookup + ((ulong)(uVar4 >> 0x16) & 0x3fc)) ^
            *(uint *)(&DAT_102b582c0 + ((ulong)uVar4 & 0xff) * 4) ^
            *(uint *)(&DAT_102b586c0 + ((ulong)(uVar1 >> 0x16) & 0x3fc)) ^
            *(uint *)(&DAT_102b58ac0 + ((ulong)(uVar1 >> 0x10) & 0xff) * 4) ^
            *(uint *)(&DAT_102b58ec0 + ((ulong)(uVar1 >> 8) & 0xff) * 4) ^
            *(uint *)(&DAT_102b592c0 + ((ulong)uVar1 & 0xff) * 4) ^
            *(uint *)(&DAT_102b596c0 + ((ulong)(uVar5 >> 0x16) & 0x3fc)) ^
            *(uint *)(&DAT_102b59ac0 + ((ulong)(uVar5 >> 0x10) & 0xff) * 4) ^
            *(uint *)(&DAT_102b59ec0 + ((ulong)(uVar5 >> 8) & 0xff) * 4) ^
            *(uint *)(&DAT_102b5a2c0 + ((ulong)uVar5 & 0xff) * 4) ^
            *(uint *)(&DAT_102b5a6c0 + (ulong)(uVar9 >> 0x18) * 4) ^
            *(uint *)(&DAT_102b5aac0 + (ulong)(uVar9 >> 0x10 & 0xff) * 4);
    uVar4 = *(uint *)((long)param_1 + 0x24);
    uVar1 = *(uint *)((long)param_1 + 0x38);
    uVar5 = *(uint *)((long)param_1 + 0x3c);
    uVar9 = *(uint *)((long)param_1 + 0x20) ^ *(uint *)(&DAT_102b5b2c0 + (ulong)(uVar9 & 0xff) * 4)
            ^ *(uint *)(&DAT_102b57ac0 + ((ulong)(uVar6 >> 0x10) & 0xff) * 4) ^
              *(uint *)(&DAT_102b57ec0 + ((ulong)(uVar6 >> 8) & 0xff) * 4) ^
              *(uint *)(&_Crc32Lookup + ((ulong)(uVar6 >> 0x16) & 0x3fc)) ^
              *(uint *)(&DAT_102b582c0 + ((ulong)uVar6 & 0xff) * 4) ^
              *(uint *)(&DAT_102b586c0 + ((ulong)(uVar2 >> 0x16) & 0x3fc)) ^
              *(uint *)(&DAT_102b58ac0 + ((ulong)(uVar2 >> 0x10) & 0xff) * 4) ^
              *(uint *)(&DAT_102b58ec0 + ((ulong)(uVar2 >> 8) & 0xff) * 4) ^
              *(uint *)(&DAT_102b592c0 + ((ulong)uVar2 & 0xff) * 4) ^
              *(uint *)(&DAT_102b596c0 + ((ulong)(uVar7 >> 0x16) & 0x3fc)) ^
              *(uint *)(&DAT_102b59ac0 + ((ulong)(uVar7 >> 0x10) & 0xff) * 4) ^
              *(uint *)(&DAT_102b59ec0 + ((ulong)(uVar7 >> 8) & 0xff) * 4) ^
              *(uint *)(&DAT_102b5a2c0 + ((ulong)uVar7 & 0xff) * 4) ^
              *(uint *)(&DAT_102b5a6c0 + (ulong)(uVar9 >> 0x18) * 4) ^
              *(uint *)(&DAT_102b5aac0 + (ulong)(uVar9 >> 0x10 & 0xff) * 4) ^
              *(uint *)(&DAT_102b5aec0 + (ulong)(uVar9 >> 8 & 0xff) * 4);
    uVar2 = *(uint *)((long)param_1 + 0x34);
    uVar9 = *(uint *)((long)param_1 + 0x30) ^ *(uint *)(&DAT_102b5b2c0 + (ulong)(uVar9 & 0xff) * 4)
            ^ *(uint *)(&DAT_102b57ac0 + ((ulong)(uVar8 >> 0x10) & 0xff) * 4) ^
              *(uint *)(&DAT_102b57ec0 + ((ulong)(uVar8 >> 8) & 0xff) * 4) ^
              *(uint *)(&_Crc32Lookup + ((ulong)(uVar8 >> 0x16) & 0x3fc)) ^
              *(uint *)(&DAT_102b582c0 + ((ulong)uVar8 & 0xff) * 4) ^
              *(uint *)(&DAT_102b586c0 + ((ulong)(uVar3 >> 0x16) & 0x3fc)) ^
              *(uint *)(&DAT_102b58ac0 + ((ulong)(uVar3 >> 0x10) & 0xff) * 4) ^
              *(uint *)(&DAT_102b58ec0 + ((ulong)(uVar3 >> 8) & 0xff) * 4) ^
              *(uint *)(&DAT_102b592c0 + ((ulong)uVar3 & 0xff) * 4) ^
              *(uint *)(&DAT_102b596c0 + ((ulong)(uVar4 >> 0x16) & 0x3fc)) ^
              *(uint *)(&DAT_102b59ac0 + ((ulong)(uVar4 >> 0x10) & 0xff) * 4) ^
              *(uint *)(&DAT_102b59ec0 + ((ulong)(uVar4 >> 8) & 0xff) * 4) ^
              *(uint *)(&DAT_102b5a2c0 + ((ulong)uVar4 & 0xff) * 4) ^
              *(uint *)(&DAT_102b5a6c0 + (ulong)(uVar9 >> 0x18) * 4) ^
              *(uint *)(&DAT_102b5aac0 + (ulong)(uVar9 >> 0x10 & 0xff) * 4) ^
              *(uint *)(&DAT_102b5aec0 + (ulong)(uVar9 >> 8 & 0xff) * 4);
    uVar9 = *(uint *)(&DAT_102b57ac0 + ((ulong)(uVar5 >> 0x10) & 0xff) * 4) ^
            *(uint *)(&DAT_102b57ec0 + ((ulong)(uVar5 >> 8) & 0xff) * 4) ^
            *(uint *)(&_Crc32Lookup + ((ulong)(uVar5 >> 0x16) & 0x3fc)) ^
            *(uint *)(&DAT_102b582c0 + ((ulong)uVar5 & 0xff) * 4) ^
            *(uint *)(&DAT_102b586c0 + ((ulong)(uVar1 >> 0x16) & 0x3fc)) ^
            *(uint *)(&DAT_102b58ac0 + ((ulong)(uVar1 >> 0x10) & 0xff) * 4) ^
            *(uint *)(&DAT_102b58ec0 + ((ulong)(uVar1 >> 8) & 0xff) * 4) ^
            *(uint *)(&DAT_102b592c0 + ((ulong)uVar1 & 0xff) * 4) ^
            *(uint *)(&DAT_102b596c0 + ((ulong)(uVar2 >> 0x16) & 0x3fc)) ^
            *(uint *)(&DAT_102b59ac0 + ((ulong)(uVar2 >> 0x10) & 0xff) * 4) ^
            *(uint *)(&DAT_102b59ec0 + ((ulong)(uVar2 >> 8) & 0xff) * 4) ^
            *(uint *)(&DAT_102b5a2c0 + ((ulong)uVar2 & 0xff) * 4) ^
            *(uint *)(&DAT_102b5a6c0 + (ulong)(uVar9 >> 0x18) * 4) ^
            *(uint *)(&DAT_102b5aac0 + (ulong)(uVar9 >> 0x10 & 0xff) * 4) ^
            *(uint *)(&DAT_102b5aec0 + (ulong)(uVar9 >> 8 & 0xff) * 4) ^
            *(uint *)(&DAT_102b5b2c0 + (ulong)(uVar9 & 0xff) * 4);
    param_1 = (void *)((long)param_1 + 0x40);
  }
  for (; param_2 != 0; param_2 = param_2 - 1) {
    uVar9 = *(uint *)(&_Crc32Lookup + (ulong)(uVar9 & 0xff ^ (uint)(byte)*(uint *)param_1) * 4) ^
            uVar9 >> 8;
    param_1 = (uint *)((long)param_1 + 1);
  }
  return ~uVar9;
}



// ===== noise  @ 0x1015db35c =====

/* Noise::noise(NoiseRegisterIndex, NoiseRegisterIndex, NoiseRegisterIndex, float, float, float,
   float, NoiseCache&) const */

void __thiscall
Noise::noise(float param_1,float param_2,float param_3,float param_4,Noise *this,undefined8 param_6,
            undefined8 param_7,undefined8 param_8,NoiseCache *param_9)

{
  uint uVar1;
  uint uVar2;
  float *pfVar3;
  float *pfVar4;
  float *pfVar5;
  ulong uVar6;
  float fVar7;
  float fVar8;
  float fVar9;
  
  if (((0.0 < param_1 && (int)param_8 == 1) && (int)param_7 == 0) &&
      param_9[0x28] != (NoiseCache)0x0) {
    uVar1 = *(uint *)(param_9 + 0x34);
    fVar9 = *(float *)(param_9 + 0x3c);
    if ((long)(fVar9 * (float)uVar1 * param_1) + 1U <= *(ulong *)(param_9 + 0x18)) {
      fVar7 = *(float *)(param_9 + 0x2c);
      fVar8 = *(float *)(param_9 + 0x30);
      uVar2 = *(uint *)(param_9 + 0x38);
      pfVar3 = (float *)NoiseCache::getFloatRegister(param_9,param_6);
      noise(this,fVar7 + param_3,fVar8 + param_4,uVar1,uVar2,fVar9,param_1,param_2,
            (NoiseScratch *)(param_9 + 0x18),pfVar3);
      return;
    }
  }
  uVar6 = *(ulong *)(param_9 + 0x10);
  pfVar3 = (float *)NoiseCache::getFloatRegister(param_9,param_7);
  pfVar4 = (float *)NoiseCache::getFloatRegister(param_9,param_8);
  pfVar5 = (float *)NoiseCache::getFloatRegister(param_9,param_6);
  noise(this,uVar6,pfVar3,pfVar4,param_1,param_2,param_3,param_4,(NoiseScratch *)(param_9 + 0x18),
        pfVar5);
  return;
}



// ===== noise  @ 0x1015db970 =====

/* Noise::noise(unsigned long, float const*, float const*, float, float, float, float,
   NoiseScratch&, float*) const */

void __thiscall
Noise::noise(Noise *this,ulong param_1,float *param_2,float *param_3,float param_4,float param_5,
            float param_6,float param_7,NoiseScratch *param_8,float *param_9)

{
  uint uVar1;
  float *pfVar2;
  float *pfVar3;
  float *pfVar4;
  ulong uVar5;
  Noise NVar6;
  Noise NVar7;
  uint uVar8;
  bool bVar9;
  bool bVar10;
  bool bVar11;
  long lVar12;
  long lVar13;
  long lVar14;
  float *pfVar15;
  ulong uVar16;
  float *pfVar17;
  long lVar18;
  float *pfVar19;
  long lVar20;
  long lVar21;
  int iVar22;
  long lVar23;
  long lVar24;
  uint uVar25;
  ulong uVar26;
  ulong uVar27;
  float in_s16;
  float in_register_00005204;
  float in_s17;
  float in_register_00005224;
  float in_s18;
  float in_register_00005244;
  float in_s19;
  float in_register_00005264;
  float fVar28;
  float fVar29;
  float fVar30;
  float fVar31;
  float fVar32;
  float fVar33;
  undefined8 uVar34;
  float fVar35;
  float fVar36;
  float fVar37;
  float fVar38;
  undefined8 uVar39;
  
  if (param_1 != 0) {
    lVar14 = *(long *)(param_8 + 8);
    lVar20 = *(long *)param_8 + -1;
    lVar21 = lVar14 + *(long *)param_8 * 8;
    NVar6 = this[5];
    uVar39 = NEON_fmov(0x3f800000,4);
    uVar16 = 0;
    lVar18 = 0;
    uVar26 = 0;
    uVar25 = 0;
    do {
      fVar28 = (float)(int)((param_3[uVar16] + param_7) * param_4);
      uVar5 = 0x8000000000000000;
      if (-9.223372e+18 < fVar28) {
        uVar5 = (long)fVar28;
      }
      uVar27 = 0x7fffffffffffffff;
      if (fVar28 < 9.223372e+18) {
        uVar27 = uVar5;
      }
      uVar5 = 0;
      if (!NAN(fVar28)) {
        uVar5 = uVar27;
      }
      fVar28 = (param_2[uVar16] + param_6) * param_4;
      fVar29 = (float)(int)fVar28;
      lVar23 = -0x8000000000000000;
      if (-9.223372e+18 < fVar29) {
        lVar23 = (long)fVar29;
      }
      lVar24 = 0x7fffffffffffffff;
      if (fVar29 < 9.223372e+18) {
        lVar24 = lVar23;
      }
      lVar23 = 0;
      if (!NAN(fVar29)) {
        lVar23 = lVar24;
      }
      fVar28 = (float)(int)fVar28;
      if (NAN(fVar28)) {
        lVar24 = 0;
joined_r0x0001015dbaa8:
        if (param_1 <= uVar16 + 1) goto LAB_1015dbbc4;
LAB_1015dbaac:
        fVar28 = (float)(long)(uVar5 + 1);
        lVar12 = 1;
        do {
          fVar29 = (param_3[uVar16 + lVar12] + param_7) * param_4;
          bVar9 = false;
          bVar10 = false;
          bVar11 = false;
          if ((float)(long)uVar5 <= fVar29) {
            bVar9 = false;
            bVar10 = false;
            bVar11 = true;
            if (!NAN(fVar29) && !NAN(fVar28)) {
              bVar9 = fVar29 < fVar28;
              bVar10 = fVar29 == fVar28;
              bVar11 = false;
            }
          }
          lVar13 = lVar12;
          if (!bVar10 && bVar9 == bVar11) break;
          fVar29 = (param_2[uVar16 + lVar12] + param_6) * param_4;
          if ((float)lVar23 <= fVar29) {
            if ((float)lVar24 < fVar29) {
              if ((float)(lVar23 + lVar20) < fVar29) break;
              fVar29 = (float)(int)fVar29;
              if (NAN(fVar29)) {
                lVar24 = 0;
              }
              else if (9.223372e+18 <= fVar29) {
                lVar24 = 0x7fffffffffffffff;
              }
              else if (fVar29 <= -9.223372e+18) {
                lVar24 = -0x8000000000000000;
              }
              else {
                lVar24 = (long)fVar29;
              }
            }
          }
          else {
            if (fVar29 < (float)(lVar24 - lVar20)) break;
            fVar29 = (float)(int)fVar29;
            if (NAN(fVar29)) {
              lVar23 = 0;
            }
            else if (9.223372e+18 <= fVar29) {
              lVar23 = 0x7fffffffffffffff;
            }
            else if (fVar29 <= -9.223372e+18) {
              lVar23 = -0x8000000000000000;
            }
            else {
              lVar23 = (long)fVar29;
            }
          }
          lVar12 = lVar12 + 1;
          lVar13 = param_1 - uVar16;
        } while (param_1 - uVar16 != lVar12);
      }
      else {
        if (9.223372e+18 <= fVar28) {
          lVar24 = 0x7fffffffffffffff;
        }
        else {
          if (fVar28 <= -9.223372e+18) {
            lVar24 = -0x8000000000000000;
            goto joined_r0x0001015dbaa8;
          }
          lVar24 = (long)fVar28;
        }
        if (uVar16 + 1 < param_1) goto LAB_1015dbaac;
LAB_1015dbbc4:
        lVar13 = 1;
      }
      iVar22 = (int)lVar23;
      uVar8 = (int)lVar24 - iVar22;
      uVar1 = uVar8 + 1;
      uVar27 = (ulong)uVar1;
      if (((uVar26 == uVar5 - 1) && (uVar8 <= uVar25)) && (lVar18 == lVar23)) {
        lVar24 = lVar21;
        lVar21 = lVar14;
        if (uVar1 != 0) {
          uVar26 = 0;
          NVar7 = this[(uVar5 + 1 & 0xff) + 6];
          do {
            *(undefined8 *)(lVar14 + uVar26 * 8) =
                 *(undefined8 *)
                  (this + (ulong)(byte)((byte)NVar7 ^ (byte)NVar6 ^
                                       (byte)this[((ulong)(uint)((int)lVar18 + (int)uVar26) & 0xff)
                                                  + 0x106]) * 8 + 0x208);
            uVar26 = uVar26 + 1;
          } while (uVar27 != uVar26);
        }
      }
      else {
        lVar24 = lVar14;
        if (uVar1 != 0) {
          uVar26 = 0;
          NVar7 = this[(uVar5 & 0xff) + 6];
          do {
            *(undefined8 *)(lVar14 + uVar26 * 8) =
                 *(undefined8 *)
                  (this + (ulong)(byte)((byte)NVar7 ^ (byte)NVar6 ^
                                       (byte)this[((ulong)(uint)(iVar22 + (int)uVar26) & 0xff) +
                                                  0x106]) * 8 + 0x208);
            uVar26 = uVar26 + 1;
          } while (uVar27 != uVar26);
          uVar26 = 0;
          NVar7 = this[(uVar5 + 1 & 0xff) + 6];
          do {
            *(undefined8 *)(lVar21 + uVar26 * 8) =
                 *(undefined8 *)
                  (this + (ulong)(byte)((byte)NVar7 ^ (byte)NVar6 ^
                                       (byte)this[((ulong)(uint)(iVar22 + (int)uVar26) & 0xff) +
                                                  0x106]) * 8 + 0x208);
            uVar26 = uVar26 + 1;
          } while (uVar27 != uVar26);
        }
      }
      lVar14 = lVar24;
      uVar27 = uVar16;
      if (uVar16 < lVar13 + uVar16) {
        uVar27 = lVar13 + uVar16;
        pfVar17 = param_3 + uVar16;
        pfVar19 = param_2 + uVar16;
        fVar28 = 1.0;
        fVar29 = 0.0;
        pfVar15 = param_9;
        do {
          fVar31 = (*pfVar19 + param_6) * param_4;
          bVar9 = true;
          if ((fVar31 <= fVar29) && (bVar9 = false, !NAN(fVar31) && !NAN(fVar28))) {
            bVar9 = fVar31 < fVar28;
          }
          if (bVar9) {
            fVar28 = (float)(int)fVar31;
            fVar29 = (float)(int)fVar31;
            lVar18 = (ulong)(uint)(int)(fVar28 - (float)lVar23) * 8;
            pfVar2 = (float *)(lVar14 + lVar18);
            lVar24 = (ulong)(uint)(int)(fVar29 - (float)lVar23) * 8;
            pfVar3 = (float *)(lVar14 + lVar24);
            pfVar4 = (float *)(lVar21 + lVar18);
            in_s16 = *pfVar2;
            in_s17 = pfVar2[1];
            in_s18 = *pfVar3;
            in_s19 = pfVar3[1];
            in_register_00005224 = *pfVar4;
            in_register_00005204 = pfVar4[1];
            pfVar2 = (float *)(lVar21 + lVar24);
            in_register_00005244 = *pfVar2;
            in_register_00005264 = pfVar2[1];
          }
          fVar30 = (*pfVar17 + param_7) * param_4 - (float)(long)uVar5;
          fVar31 = fVar31 - fVar28;
          fVar32 = fVar31 + -1.0;
          fVar36 = fVar30 + -1.0;
          uVar34 = NEON_fminnm(CONCAT44(fVar31 * fVar31 + fVar36 * fVar36,
                                        fVar31 * fVar31 + fVar30 * fVar30),uVar39,4);
          fVar33 = (float)uVar39 - (float)uVar34;
          fVar38 = (float)((ulong)uVar39 >> 0x20);
          fVar35 = fVar38 - (float)((ulong)uVar34 >> 0x20);
          uVar34 = NEON_fminnm(CONCAT44(fVar32 * fVar32 + fVar36 * fVar36,
                                        fVar32 * fVar32 + fVar30 * fVar30),uVar39,4);
          fVar37 = (float)uVar39 - (float)uVar34;
          fVar38 = fVar38 - (float)((ulong)uVar34 >> 0x20);
          param_9 = pfVar15 + 1;
          *pfVar15 = *pfVar15 +
                     ((fVar30 * in_s17 + fVar31 * in_s16) * fVar33 * fVar33 * fVar33 +
                      (in_s18 * fVar32 + fVar30 * in_s19) * fVar37 * fVar37 * fVar37 +
                     (fVar31 * in_register_00005224 + fVar36 * in_register_00005204) *
                     fVar35 * fVar35 * fVar35 +
                     (in_register_00005244 * fVar32 + fVar36 * in_register_00005264) *
                     fVar38 * fVar38 * fVar38) * param_5;
          pfVar17 = pfVar17 + 1;
          pfVar19 = pfVar19 + 1;
          lVar13 = lVar13 + -1;
          pfVar15 = param_9;
        } while (lVar13 != 0);
      }
      uVar16 = uVar27;
      lVar18 = lVar23;
      uVar26 = uVar5;
      uVar25 = uVar8;
    } while (uVar27 < param_1);
  }
  return;
}



// ===== noise  @ 0x1015db4cc =====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* Noise::noise(float, float, unsigned int, unsigned int, float, float, float, NoiseScratch&,
   float*) const */

void __thiscall
Noise::noise(Noise *this,float param_1,float param_2,uint param_3,uint param_4,float param_5,
            float param_6,float param_7,NoiseScratch *param_8,float *param_9)

{
  uint uVar1;
  float *pfVar2;
  float *pfVar3;
  Noise NVar4;
  Noise NVar5;
  undefined *puVar6;
  float *pfVar7;
  undefined8 *puVar8;
  ulong uVar9;
  int iVar10;
  ulong uVar11;
  ulong uVar12;
  undefined8 *puVar13;
  uint *puVar14;
  ulong uVar15;
  float *pfVar16;
  uint uVar17;
  uint *puVar18;
  undefined8 *puVar19;
  ulong uVar20;
  float *pfVar21;
  ulong uVar22;
  ulong uVar23;
  float fVar24;
  float fVar25;
  int iVar26;
  int iVar27;
  float fVar28;
  float fVar29;
  undefined1 auVar30 [16];
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
  undefined8 uVar44;
  float fVar45;
  float afStack_60 [2];
  long local_58;
  
  local_58 = *(long *)PTR____stack_chk_guard_102d481b8;
  fVar25 = (float)(int)(param_1 * param_6);
  fVar24 = (float)(int)(param_1 * param_6 + (float)(param_3 - 1) * param_5 * param_6) - fVar25;
  if (NAN(fVar24)) {
                    /* WARNING: Subroutine does not return */
    ReleaseAssertFailed("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/FloatCast.hpp"
                        ,0x21,"!std::isnan(input)");
  }
  if (ABS(fVar24) == INFINITY) {
                    /* WARNING: Subroutine does not return */
    ReleaseAssertFailed("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/FloatCast.hpp"
                        ,0x22,"!std::isinf(input)");
  }
  if (fVar24 < 0.0) {
                    /* WARNING: Subroutine does not return */
    FloatCastCheckFailed(fVar24,"<",0.0);
  }
  if (4.294967e+09 < fVar24) {
                    /* WARNING: Subroutine does not return */
    FloatCastCheckFailed(fVar24,">",4.294967e+09);
  }
  uVar1 = (int)fVar24 + 1;
  uVar9 = (ulong)uVar1;
  uVar11 = (ulong)fVar25;
  puVar8 = *(undefined8 **)(param_8 + 8);
  puVar13 = puVar8 + *(long *)param_8;
  uVar12 = (ulong)param_3;
  uVar15 = (ulong)param_3 * 4 + 0xf & 0x7fffffff0;
  puVar14 = (uint *)((long)afStack_60 - uVar15);
  pfVar16 = (float *)((long)puVar14 - uVar15);
  iVar10 = (int)uVar11;
  if (param_3 != 0) {
    if (param_3 < 4) {
      uVar15 = 0;
    }
    else {
      uVar15 = uVar12 & 0xfffffffc;
      iVar26 = (int)_UNK_102971388;
      iVar27 = (int)((ulong)_UNK_102971388 >> 0x20);
      uVar20 = uVar15;
      pfVar7 = pfVar16;
      puVar18 = puVar14;
      puVar6 = PTR___mh_execute_header_102971380;
      do {
        auVar30._8_4_ = iVar26;
        auVar30._0_8_ = puVar6;
        auVar30._12_4_ = iVar27;
        auVar30 = NEON_ucvtf(auVar30,4);
        fVar24 = (auVar30._0_4_ * param_5 + param_1) * param_6;
        fVar25 = (auVar30._4_4_ * param_5 + param_1) * param_6;
        fVar28 = (auVar30._8_4_ * param_5 + param_1) * param_6;
        fVar29 = (auVar30._12_4_ * param_5 + param_1) * param_6;
        fVar31 = (float)(int)fVar24;
        fVar32 = (float)(int)fVar25;
        fVar33 = (float)(int)fVar28;
        fVar34 = (float)(int)fVar29;
        *(ulong *)(puVar18 + 2) = CONCAT44((int)(long)fVar34 - iVar10,(int)(long)fVar33 - iVar10);
        *(ulong *)puVar18 = CONCAT44((int)((long)fVar32 - uVar11),(int)(long)fVar31 - iVar10);
        pfVar7[2] = fVar28 - fVar33;
        pfVar7[3] = fVar29 - fVar34;
        *pfVar7 = fVar24 - fVar31;
        pfVar7[1] = fVar25 - fVar32;
        puVar6 = (undefined *)CONCAT44((int)((ulong)puVar6 >> 0x20) + 4,(int)puVar6 + 4);
        iVar26 = iVar26 + 4;
        iVar27 = iVar27 + 4;
        uVar20 = uVar20 - 4;
        pfVar7 = pfVar7 + 4;
        puVar18 = puVar18 + 4;
      } while (uVar20 != 0);
      if (uVar15 == uVar12) goto LAB_1015db650;
    }
    do {
      fVar24 = ((float)(uVar15 & 0xffffffff) * param_5 + param_1) * param_6;
      puVar14[uVar15] = (int)(long)fVar24 - iVar10;
      pfVar16[uVar15] = fVar24 - (float)(int)fVar24;
      uVar15 = uVar15 + 1;
    } while (uVar12 != uVar15);
  }
LAB_1015db650:
  uVar15 = (ulong)(param_2 * param_6);
  NVar4 = this[5];
  if (uVar1 != 0) {
    NVar5 = this[(uVar15 & 0xff) + 6];
    puVar19 = puVar13;
    uVar20 = uVar9;
    do {
      *puVar19 = *(undefined8 *)
                  (this + (ulong)(byte)((byte)NVar5 ^ (byte)NVar4 ^
                                       (byte)this[(uVar11 & 0xff) + 0x106]) * 8 + 0x208);
      uVar11 = uVar11 + 1;
      uVar20 = uVar20 - 1;
      puVar19 = puVar19 + 1;
    } while (uVar20 != 0);
  }
  if (param_4 != 0) {
    uVar17 = 0;
    uVar11 = 0xffffffff;
    do {
      fVar24 = ((float)uVar17 * param_5 + param_2) * param_6;
      uVar20 = (long)fVar24 - uVar15;
      if ((int)uVar11 + 1 == (int)uVar20) {
        puVar19 = puVar13;
        uVar11 = uVar20;
        puVar13 = puVar8;
        if (uVar1 != 0) {
          uVar20 = 0;
          NVar5 = this[((ulong)((int)(long)fVar24 + 1) & 0xff) + 6];
          do {
            puVar8[uVar20] =
                 *(undefined8 *)
                  (this + (ulong)(byte)((byte)NVar5 ^ (byte)NVar4 ^
                                       (byte)this[((ulong)(uint)(iVar10 + (int)uVar20) & 0xff) +
                                                  0x106]) * 8 + 0x208);
            uVar20 = uVar20 + 1;
          } while (uVar9 != uVar20);
        }
      }
      else {
        puVar19 = puVar8;
        if ((int)uVar11 != (int)uVar20 && uVar1 != 0) {
          uVar22 = 0;
          uVar20 = uVar15 + (uVar20 & 0xffffffff);
          NVar5 = this[(uVar20 & 0xff) + 6];
          do {
            puVar8[uVar22] =
                 *(undefined8 *)
                  (this + (ulong)(byte)((byte)NVar5 ^ (byte)NVar4 ^
                                       (byte)this[((ulong)(uint)(iVar10 + (int)uVar22) & 0xff) +
                                                  0x106]) * 8 + 0x208);
            uVar22 = uVar22 + 1;
          } while (uVar9 != uVar22);
          uVar22 = 0;
          NVar5 = this[((ulong)((int)uVar20 + 1) & 0xff) + 6];
          do {
            puVar13[uVar22] =
                 *(undefined8 *)
                  (this + (ulong)(byte)((byte)NVar5 ^ (byte)NVar4 ^
                                       (byte)this[((ulong)(uint)(iVar10 + (int)uVar22) & 0xff) +
                                                  0x106]) * 8 + 0x208);
            uVar22 = uVar22 + 1;
          } while (uVar9 != uVar22);
        }
      }
      puVar8 = puVar19;
      if (param_3 != 0) {
        fVar24 = fVar24 - (float)(int)fVar24;
        fVar28 = 1.0 - fVar24 * fVar24;
        fVar25 = fVar24 + -1.0;
        fVar29 = 1.0 - fVar25 * fVar25;
        fVar31 = 0.0;
        fVar32 = 0.0;
        uVar22 = 0xffffffff;
        fVar35 = 0.0;
        fVar36 = 0.0;
        fVar33 = 0.0;
        fVar34 = 0.0;
        fVar37 = 0.0;
        fVar38 = 0.0;
        pfVar7 = param_9;
        uVar20 = uVar12;
        pfVar21 = pfVar16;
        puVar18 = puVar14;
        do {
          uVar23 = (ulong)*puVar18;
          if ((uint)uVar22 != *puVar18) {
            pfVar2 = (float *)(puVar8 + uVar23);
            fVar31 = *pfVar2;
            pfVar3 = (float *)(puVar13 + uVar23);
            fVar33 = *pfVar3;
            fVar35 = pfVar2[1] * fVar24;
            fVar36 = pfVar2[3] * fVar24;
            fVar37 = pfVar3[1] * fVar25;
            fVar38 = pfVar3[3] * fVar25;
            fVar32 = pfVar2[2];
            fVar34 = pfVar3[2];
            uVar22 = uVar23;
          }
          fVar39 = *pfVar21;
          fVar40 = fVar39 + -1.0;
          uVar44 = NEON_fmaxnm(CONCAT44(fVar28 - fVar40 * fVar40,fVar28 - fVar39 * fVar39),0,4);
          fVar43 = (float)uVar44;
          fVar45 = (float)((ulong)uVar44 >> 0x20);
          uVar44 = NEON_fmaxnm(CONCAT44(fVar29 - fVar40 * fVar40,fVar29 - fVar39 * fVar39),0,4);
          fVar41 = (float)uVar44;
          fVar42 = (float)((ulong)uVar44 >> 0x20);
          param_9 = pfVar7 + 1;
          *pfVar7 = *pfVar7 + ((fVar39 * fVar31 + fVar35) * fVar43 * fVar43 * fVar43 +
                               (fVar39 * fVar33 + fVar37) * fVar41 * fVar41 * fVar41 +
                              (fVar40 * fVar32 + fVar36) * fVar45 * fVar45 * fVar45 +
                              (fVar40 * fVar34 + fVar38) * fVar42 * fVar42 * fVar42) * param_7;
          puVar18 = puVar18 + 1;
          uVar20 = uVar20 - 1;
          pfVar7 = param_9;
          pfVar21 = pfVar21 + 1;
        } while (uVar20 != 0);
      }
      uVar17 = uVar17 + 1;
    } while (uVar17 != param_4);
  }
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_58) {
    return;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}



// ===== run  @ 0x1015efa28 =====

/* NoiseOperations::MultioctaveNoise::run(NoiseCache&) const */

void __thiscall NoiseOperations::MultioctaveNoise::run(MultioctaveNoise *this,NoiseCache *param_1)

{
  uint uVar1;
  uint uVar2;
  void *pvVar3;
  float *pfVar4;
  float *pfVar5;
  float *pfVar6;
  ulong uVar7;
  float fVar8;
  float fVar9;
  float fVar10;
  float fVar11;
  float fVar12;
  float fVar13;
  float fVar14;
  float fVar15;
  float fVar16;
  
  pvVar3 = (void *)NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 8));
  uVar7 = *(ulong *)(param_1 + 0x10);
  if (0 < (long)(uVar7 * 4)) {
    _bzero(pvVar3,(uVar7 - ((uVar7 & 0x3fffffffffffffff) != 0)) * 4 + 4);
  }
  if (((param_1[0x28] != (NoiseCache)0x0 && *(int *)(this + 0xc) == 0) && *(int *)(this + 0x10) == 1
      ) && (fVar8 = *(float *)(this + 0xa24), 0.0 < fVar8)) {
    uVar1 = *(uint *)(param_1 + 0x34);
    fVar9 = *(float *)(param_1 + 0x3c);
    if (((long)(fVar8 * fVar9 * (float)uVar1) << 1 | 1U) <= *(ulong *)(param_1 + 0x18)) {
      fVar10 = *(float *)(this + 0xa2c);
      fVar12 = *(float *)(param_1 + 0x2c);
      fVar14 = *(float *)(param_1 + 0x30);
      fVar11 = *(float *)(this + 0xa30);
      uVar2 = *(uint *)(param_1 + 0x38);
      fVar13 = *(float *)(this + 0xa28);
      fVar15 = *(float *)(this + 0xa20);
      fVar16 = *(float *)(this + 0x14);
      pfVar6 = (float *)NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 8));
      Noise::multioctaveNoise
                ((Noise *)(this + 0x18),fVar12 + fVar10,fVar14 + fVar11,uVar1,uVar2,fVar9,fVar8,
                 fVar13,fVar15,fVar16,(NoiseScratch *)(param_1 + 0x18),pfVar6);
      return;
    }
  }
  pfVar4 = (float *)NoiseCache::getFloatRegister(param_1);
  pfVar5 = (float *)NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x10));
  fVar8 = *(float *)(this + 0xa24);
  fVar9 = *(float *)(this + 0xa28);
  fVar10 = *(float *)(this + 0xa2c);
  fVar11 = *(float *)(this + 0xa30);
  fVar12 = *(float *)(this + 0xa20);
  fVar14 = *(float *)(this + 0x14);
  pfVar6 = (float *)NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 8));
  if (Noise::vectorMultioctaveNoiseImplementationId == 0) {
    Noise::vectorMultioctaveNoiseImplementationId = 0;
    for (; uVar7 != 0; uVar7 = uVar7 - 1) {
      Noise::multioctaveNoise
                ((Noise *)(this + 0x18),fVar10 + *pfVar4,fVar11 + *pfVar5,1,1,1.0,fVar8,fVar9,fVar12
                 ,fVar14,(NoiseScratch *)(param_1 + 0x18),pfVar6);
      pfVar6 = pfVar6 + 1;
      pfVar4 = pfVar4 + 1;
      pfVar5 = pfVar5 + 1;
    }
    return;
  }
  Noise::fastVectorMultioctaveNoise
            ((Noise *)(this + 0x18),uVar7,pfVar4,pfVar5,fVar8,fVar9,fVar10,fVar11,fVar12,fVar14,
             (NoiseScratch *)(param_1 + 0x18),pfVar6);
  return;
}



// ===== fastVectorMultioctaveNoise  @ 0x1015dc590 =====

/* Noise::fastVectorMultioctaveNoise(unsigned long, float const*, float const*, float, float, float,
   float, float, float, NoiseScratch&, float*) const */

void __thiscall
Noise::fastVectorMultioctaveNoise
          (Noise *this,ulong param_1,float *param_2,float *param_3,float param_4,float param_5,
          float param_6,float param_7,float param_8,float param_9,NoiseScratch *param_10,
          float *param_11)

{
  float *pfVar1;
  float *pfVar2;
  char *pcVar3;
  ulong uVar4;
  uint uVar5;
  uint uVar6;
  float fVar7;
  float fVar8;
  double dVar9;
  float fVar10;
  float fVar11;
  float fVar12;
  
  uVar4 = param_1 << 2;
  if (param_1 >> 0x3e != 0) {
    uVar4 = 0xffffffffffffffff;
  }
  pfVar1 = operator_new__(uVar4);
  pfVar2 = operator_new__(uVar4);
  fVar11 = (float)(int)param_8;
  if (NAN(fVar11)) {
    pcVar3 = "!std::isnan(input)";
    uVar5 = 0x21;
  }
  else {
    if (ABS(fVar11) != INFINITY) {
      if (fVar11 < 0.0) {
        fVar7 = 0.0;
        pcVar3 = "<";
      }
      else {
        fVar7 = 4.294967e+09;
        if (fVar11 <= 4.294967e+09) {
          fVar12 = (float)NEON_ucvtf((int)fVar11);
          fVar7 = (float)Math::exp2f(fVar12 - param_8);
          uVar5 = (uint)fVar11;
          fVar10 = 1.0 / param_9;
          fVar11 = fVar7;
          if (1.99999 <= fVar7) {
            fVar11 = 1.99999;
          }
          fVar8 = 1.0;
          if (1.0 <= fVar7) {
            fVar8 = fVar11;
          }
          if (fVar10 == 1.0) {
            param_5 = param_5 / SQRT((float)uVar5);
          }
          else if (fVar10 != 0.0) {
            fVar11 = (float)Math::log2(fVar10 * fVar10);
            fVar11 = (float)Math::exp2f(fVar11 * fVar12);
            param_5 = SQRT((fVar10 * fVar10 + -1.0) / (fVar11 + -1.0)) * param_5;
          }
          if (uVar5 != 0) {
            if (param_1 == 0) {
              do {
                noise(this,0,pfVar1,pfVar2,1.0,param_5,param_6,param_7,param_10,param_11);
                param_5 = fVar10 * param_5;
                uVar5 = uVar5 - 1;
              } while (uVar5 != 0);
            }
            else {
              uVar6 = 0;
              fVar8 = fVar8 * param_4;
              dVar9 = 0.0;
              do {
                uVar4 = 0;
                do {
                  pfVar1[uVar4] = (float)(dVar9 * 17.17 + (double)(fVar8 * param_2[uVar4]));
                  pfVar2[uVar4] = fVar8 * param_3[uVar4];
                  uVar4 = (ulong)((int)uVar4 + 1);
                } while (uVar4 < param_1);
                noise(this,param_1,pfVar1,pfVar2,1.0,param_5,param_6,param_7,param_10,param_11);
                fVar8 = fVar8 * 0.5;
                param_5 = fVar10 * param_5;
                dVar9 = dVar9 + 1.0;
                uVar6 = uVar6 + 1;
              } while (uVar6 != uVar5);
            }
          }
          operator_delete__(pfVar2);
          operator_delete__(pfVar1);
          return;
        }
        pcVar3 = ">";
      }
                    /* WARNING: Subroutine does not return */
      FloatCastCheckFailed(fVar11,pcVar3,fVar7);
    }
    pcVar3 = "!std::isinf(input)";
    uVar5 = 0x22;
  }
                    /* WARNING: Subroutine does not return */
  ReleaseAssertFailed("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/FloatCast.hpp"
                      ,uVar5,pcVar3);
}



// ===== exp2f  @ 0x1025ea988 =====

/* Math::exp2f(float) */

undefined1  [16] Math::exp2f(float param_1)

{
  undefined1 auVar1 [16];
  float fVar2;
  
  fVar2 = 1.0;
  if (0.0 <= param_1) {
    fVar2 = 0.0;
  }
  if (param_1 <= -126.0) {
    param_1 = -126.0;
  }
  fVar2 = fVar2 + (param_1 - (float)(int)param_1);
  auVar1._0_8_ = (long)((param_1 + 121.274055 + 27.728024 / (4.8425255 - fVar2) + fVar2 * -1.4901291
                        ) * 8388608.0) & 0xffffffff;
  auVar1._8_8_ = 0;
  return auVar1;
}



// ===== FloatCastCheckFailed  @ 0x1001d60c4 =====

/* FloatCastCheckFailed(float, char const*, float) */

void FloatCastCheckFailed(float param_1,char *param_2,float param_3)

{
                    /* WARNING: Subroutine does not return */
  Logging::logAndAbortOrThrow
            ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/FloatCast.cpp"
             ,0xc,9,"%f %s %f");
}



// ===== log2  @ 0x1025eac10 =====

/* Math::log2(float) */

float Math::log2(float param_1)

{
  float fVar1;
  
  fVar1 = (float)((uint)param_1 & 0x7fffff | 0x3f000000);
  return (float)(uint)param_1 * 1.1920929e-07 + -124.22552 + fVar1 * -1.4980303 +
         -1.72588 / (fVar1 + 0.35208872);
}



// ===== ReleaseAssertFailed  @ 0x100156914 =====

/* ReleaseAssertFailed(char const*, unsigned int, char const*) */

void ReleaseAssertFailed(char *param_1,uint param_2,char *param_3)

{
                    /* WARNING: Subroutine does not return */
  Logging::logAndAbortOrThrow(param_1,param_2,9,"%s was not true");
}



// ===== multioctaveNoise  @ 0x1015dbe58 =====

/* Noise::multioctaveNoise(float, float, unsigned int, unsigned int, float, float, float, float,
   float, NoiseScratch&, float*) const */

void __thiscall
Noise::multioctaveNoise
          (Noise *this,float param_1,float param_2,uint param_3,uint param_4,float param_5,
          float param_6,float param_7,float param_8,float param_9,NoiseScratch *param_10,
          float *param_11)

{
  uint uVar1;
  float fVar2;
  float fVar3;
  float fVar4;
  double dVar5;
  float fVar6;
  float fVar7;
  
  fVar2 = (float)(int)param_8;
  if (NAN(fVar2)) {
                    /* WARNING: Subroutine does not return */
    ReleaseAssertFailed("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/FloatCast.hpp"
                        ,0x21,"!std::isnan(input)");
  }
  if (ABS(fVar2) == INFINITY) {
                    /* WARNING: Subroutine does not return */
    ReleaseAssertFailed("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/FloatCast.hpp"
                        ,0x22,"!std::isinf(input)");
  }
  if (fVar2 < 0.0) {
                    /* WARNING: Subroutine does not return */
    FloatCastCheckFailed(fVar2,"<",0.0);
  }
  if (4.294967e+09 < fVar2) {
                    /* WARNING: Subroutine does not return */
    FloatCastCheckFailed(fVar2,">",4.294967e+09);
  }
  uVar1 = (uint)fVar2;
  fVar4 = (float)NEON_ucvtf((int)fVar2);
  fVar7 = 1.0 / param_9;
  fVar3 = (float)Math::exp2f(fVar4 - param_8);
  fVar2 = fVar3;
  if (1.99999 <= fVar3) {
    fVar2 = 1.99999;
  }
  fVar6 = 1.0;
  if (1.0 <= fVar3) {
    fVar6 = fVar2;
  }
  if (fVar7 == 1.0) {
    param_7 = param_7 / SQRT((float)uVar1);
  }
  else if (fVar7 != 0.0) {
    fVar2 = (float)Math::log2(fVar7 * fVar7);
    fVar2 = (float)Math::exp2f(fVar2 * fVar4);
    param_7 = SQRT((fVar7 * fVar7 + -1.0) / (fVar2 + -1.0)) * param_7;
  }
  if (uVar1 != 0) {
    fVar6 = fVar6 * param_5;
    dVar5 = 0.0;
    do {
      noise(this,(float)((dVar5 * 17.17) / (double)param_6 + (double)((param_1 / param_5) * fVar6)),
            (param_2 / param_5) * fVar6,param_3,param_4,fVar6,param_6,param_7,param_10,param_11);
      fVar6 = fVar6 * 0.5;
      param_7 = fVar7 * param_7;
      dVar5 = dVar5 + 1.0;
      uVar1 = uVar1 - 1;
    } while (uVar1 != 0);
  }
  return;
}



// ===== run  @ 0x1015f1c54 =====

/* NoiseOperations::VariablePersistenceMultioctaveNoise::run(NoiseCache&) const */

void __thiscall
NoiseOperations::VariablePersistenceMultioctaveNoise::run
          (VariablePersistenceMultioctaveNoise *this,NoiseCache *param_1)

{
  VariablePersistenceMultioctaveNoise *pVVar1;
  VariablePersistenceMultioctaveNoise *pVVar2;
  ulong uVar3;
  long lVar4;
  ulong uVar5;
  VariablePersistenceMultioctaveNoise *pVVar6;
  VariablePersistenceMultioctaveNoise *pVVar7;
  ulong uVar8;
  int iVar9;
  float fVar10;
  undefined8 uVar11;
  undefined8 uVar12;
  undefined8 uVar13;
  undefined8 uVar14;
  undefined8 uVar15;
  undefined8 uVar16;
  undefined8 uVar17;
  Noise *pNVar18;
  
  pVVar1 = (VariablePersistenceMultioctaveNoise *)
           NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 8));
  pVVar2 = (VariablePersistenceMultioctaveNoise *)
           NoiseCache::getFloatRegister(param_1,*(undefined4 *)(this + 0x14));
                    /* WARNING: Load size is inaccurate */
  pNVar18._0_4_ = *(Noise **)(this + 0xa24);
  uVar3 = *(ulong *)(param_1 + 0x10);
  if (0 < (long)(uVar3 * 4)) {
    _bzero(pVVar1,(uVar3 - ((uVar3 & 0x3fffffffffffffff) != 0)) * 4 + 4);
  }
  iVar9 = *(int *)(this + 0xa20) + -1;
  if (iVar9 != 0) {
    do {
      Noise::noise(pNVar18._0_4_,0x3f800000,*(undefined4 *)(this + 0xa2c),
                   *(undefined4 *)(this + 0xa30),this + 0x18,*(undefined4 *)(this + 8),
                   *(undefined4 *)(this + 0xc),*(undefined4 *)(this + 0x10),param_1);
      uVar3 = *(ulong *)(param_1 + 0x10);
      if (uVar3 != 0) {
        if ((uVar3 < 0x10) || (pVVar1 < pVVar2 + uVar3 * 4 && pVVar2 < pVVar1 + uVar3 * 4)) {
          uVar5 = 0;
        }
        else {
          uVar5 = uVar3 & 0xfffffffffffffff0;
          pVVar6 = pVVar1 + 0x20;
          pVVar7 = pVVar2 + 0x20;
          uVar8 = uVar5;
          do {
            uVar11 = *(undefined8 *)(pVVar7 + -0x20);
            uVar13 = *(undefined8 *)(pVVar7 + -8);
            uVar12 = *(undefined8 *)(pVVar7 + -0x10);
            uVar15 = *(undefined8 *)(pVVar7 + 8);
            uVar14 = *(undefined8 *)pVVar7;
            uVar17 = *(undefined8 *)(pVVar7 + 0x18);
            uVar16 = *(undefined8 *)(pVVar7 + 0x10);
            *(ulong *)(pVVar6 + -0x18) =
                 CONCAT44((float)((ulong)*(undefined8 *)(pVVar7 + -0x18) >> 0x20) *
                          (float)((ulong)*(undefined8 *)(pVVar6 + -0x18) >> 0x20),
                          (float)*(undefined8 *)(pVVar7 + -0x18) *
                          (float)*(undefined8 *)(pVVar6 + -0x18));
            *(ulong *)(pVVar6 + -0x20) =
                 CONCAT44((float)((ulong)uVar11 >> 0x20) *
                          (float)((ulong)*(undefined8 *)(pVVar6 + -0x20) >> 0x20),
                          (float)uVar11 * (float)*(undefined8 *)(pVVar6 + -0x20));
            *(ulong *)(pVVar6 + -8) =
                 CONCAT44((float)((ulong)uVar13 >> 0x20) *
                          (float)((ulong)*(undefined8 *)(pVVar6 + -8) >> 0x20),
                          (float)uVar13 * (float)*(undefined8 *)(pVVar6 + -8));
            *(ulong *)(pVVar6 + -0x10) =
                 CONCAT44((float)((ulong)uVar12 >> 0x20) *
                          (float)((ulong)*(undefined8 *)(pVVar6 + -0x10) >> 0x20),
                          (float)uVar12 * (float)*(undefined8 *)(pVVar6 + -0x10));
            *(ulong *)(pVVar6 + 8) =
                 CONCAT44((float)((ulong)uVar15 >> 0x20) *
                          (float)((ulong)*(undefined8 *)(pVVar6 + 8) >> 0x20),
                          (float)uVar15 * (float)*(undefined8 *)(pVVar6 + 8));
            *(ulong *)pVVar6 =
                 CONCAT44((float)((ulong)uVar14 >> 0x20) *
                          (float)((ulong)*(undefined8 *)pVVar6 >> 0x20),
                          (float)uVar14 * (float)*(undefined8 *)pVVar6);
            *(ulong *)(pVVar6 + 0x18) =
                 CONCAT44((float)((ulong)uVar17 >> 0x20) *
                          (float)((ulong)*(undefined8 *)(pVVar6 + 0x18) >> 0x20),
                          (float)uVar17 * (float)*(undefined8 *)(pVVar6 + 0x18));
            *(ulong *)(pVVar6 + 0x10) =
                 CONCAT44((float)((ulong)uVar16 >> 0x20) *
                          (float)((ulong)*(undefined8 *)(pVVar6 + 0x10) >> 0x20),
                          (float)uVar16 * (float)*(undefined8 *)(pVVar6 + 0x10));
            uVar8 = uVar8 - 0x10;
            pVVar6 = pVVar6 + 0x40;
            pVVar7 = pVVar7 + 0x40;
          } while (uVar8 != 0);
          if (uVar3 == uVar5) goto LAB_1015f1ce8;
        }
        lVar4 = uVar3 - uVar5;
        pVVar6 = pVVar1 + uVar5 * 4;
        pVVar7 = pVVar2 + uVar5 * 4;
        do {
          *(float *)pVVar6 = *(float *)pVVar7 * *(float *)pVVar6;
          lVar4 = lVar4 + -1;
          pVVar6 = pVVar6 + 4;
          pVVar7 = pVVar7 + 4;
        } while (lVar4 != 0);
      }
LAB_1015f1ce8:
      pNVar18._0_4_ = (Noise *)((float)pNVar18._0_4_ * 0.5);
      iVar9 = iVar9 + -1;
    } while (iVar9 != 0);
  }
  Noise::noise(pNVar18._0_4_,0x3f800000,*(undefined4 *)(this + 0xa2c),*(undefined4 *)(this + 0xa30),
               this + 0x18,*(undefined4 *)(this + 8),*(undefined4 *)(this + 0xc),
               *(undefined4 *)(this + 0x10),param_1);
  uVar3 = *(ulong *)(param_1 + 0x10);
  if (uVar3 != 0) {
    pVVar2 = this + 0xa28;
    if ((uVar3 < 0x10) || ((pVVar1 < this + 0xa2c && (pVVar2 < pVVar1 + uVar3 * 4)))) {
      uVar5 = 0;
    }
    else {
      uVar5 = uVar3 & 0xfffffffffffffff0;
      pVVar6 = pVVar1 + 0x20;
      uVar8 = uVar5;
      do {
        fVar10 = (float)*(undefined8 *)pVVar2;
        *(ulong *)(pVVar6 + -0x18) =
             CONCAT44((float)((ulong)*(undefined8 *)(pVVar6 + -0x18) >> 0x20) * fVar10,
                      (float)*(undefined8 *)(pVVar6 + -0x18) * fVar10);
        *(ulong *)(pVVar6 + -0x20) =
             CONCAT44((float)((ulong)*(undefined8 *)(pVVar6 + -0x20) >> 0x20) * fVar10,
                      (float)*(undefined8 *)(pVVar6 + -0x20) * fVar10);
        *(ulong *)(pVVar6 + -8) =
             CONCAT44((float)((ulong)*(undefined8 *)(pVVar6 + -8) >> 0x20) * fVar10,
                      (float)*(undefined8 *)(pVVar6 + -8) * fVar10);
        *(ulong *)(pVVar6 + -0x10) =
             CONCAT44((float)((ulong)*(undefined8 *)(pVVar6 + -0x10) >> 0x20) * fVar10,
                      (float)*(undefined8 *)(pVVar6 + -0x10) * fVar10);
        *(ulong *)(pVVar6 + 8) =
             CONCAT44((float)((ulong)*(undefined8 *)(pVVar6 + 8) >> 0x20) * fVar10,
                      (float)*(undefined8 *)(pVVar6 + 8) * fVar10);
        *(ulong *)pVVar6 =
             CONCAT44((float)((ulong)*(undefined8 *)pVVar6 >> 0x20) * fVar10,
                      (float)*(undefined8 *)pVVar6 * fVar10);
        *(ulong *)(pVVar6 + 0x18) =
             CONCAT44((float)((ulong)*(undefined8 *)(pVVar6 + 0x18) >> 0x20) * fVar10,
                      (float)*(undefined8 *)(pVVar6 + 0x18) * fVar10);
        *(ulong *)(pVVar6 + 0x10) =
             CONCAT44((float)((ulong)*(undefined8 *)(pVVar6 + 0x10) >> 0x20) * fVar10,
                      (float)*(undefined8 *)(pVVar6 + 0x10) * fVar10);
        uVar8 = uVar8 - 0x10;
        pVVar6 = pVVar6 + 0x40;
      } while (uVar8 != 0);
      if (uVar3 == uVar5) {
        return;
      }
    }
    lVar4 = uVar3 - uVar5;
    pVVar1 = pVVar1 + uVar5 * 4;
    do {
      *(float *)pVVar1 = *(float *)pVVar2 * *(float *)pVVar1;
      lVar4 = lVar4 + -1;
      pVVar1 = pVVar1 + 4;
    } while (lVar4 != 0);
  }
  return;
}



