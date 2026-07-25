// ===== MultioctaveNoise  @ 0x1015efa24 =====

/* NoiseOperations::MultioctaveNoise::MultioctaveNoise(NoiseRegisterIndex,
   std::array<NoiseRegisterIndex, 2ul> const&, std::span<NoiseExpressionConstant const, 8ul> const&)
    */

MultioctaveNoise * __thiscall
NoiseOperations::MultioctaveNoise::MultioctaveNoise
          (MultioctaveNoise *this,undefined4 param_2,undefined8 *param_3,long *param_4)

{
  char cVar1;
  bool bVar2;
  RuntimeError *this_00;
  char *pcVar3;
  long lVar4;
  int iVar5;
  float fVar6;
  undefined8 uVar7;
  double dVar8;
  float fVar9;
  double dVar10;
  
  uVar7 = *param_3;
  *(undefined4 *)(this + 8) = param_2;
  *(undefined8 *)(this + 0xc) = uVar7;
  *(undefined ***)this = &PTR__MultioctaveNoise_102f85240;
  pcVar3 = (char *)*param_4;
  if (*pcVar3 == '\x01') {
    cVar1 = pcVar3[0x20];
    *(float *)(this + 0x14) = (float)*(double *)(pcVar3 + 8);
    if (cVar1 == '\x01') {
      dVar8 = *(double *)(pcVar3 + 0x28);
      if (NAN(dVar8)) {
        iVar5 = 0;
      }
      else if (4294967295.0 <= dVar8) {
        iVar5 = -1;
      }
      else {
        iVar5 = 0;
        if (0.0 < dVar8) {
          iVar5 = (int)dVar8;
        }
      }
      uVar7 = NoiseExpressionConstant::asNoiseLayerID
                        ((NoiseExpressionConstant *)(pcVar3 + 0x40),"seed1");
      _bzero(this + 0x220,0x800);
      Noise::setSeed((Noise *)(this + 0x18),iVar5 + ((uint)((ulong)uVar7 >> 8) & 0xffffff) * 7,
                     (uchar)uVar7);
      lVar4 = *param_4;
      if (*(char *)(lVar4 + 0x60) == '\x01') {
        cVar1 = *(char *)(lVar4 + 0x80);
        fVar6 = (float)*(double *)(lVar4 + 0x68);
        *(float *)(this + 0xa20) = fVar6;
        if (cVar1 == '\x01') {
          cVar1 = *(char *)(lVar4 + 0xa0);
          fVar9 = (float)*(double *)(lVar4 + 0x88);
          *(float *)(this + 0xa24) = fVar9;
          if (cVar1 == '\x01') {
            cVar1 = *(char *)(lVar4 + 0xc0);
            *(float *)(this + 0xa28) = (float)*(double *)(lVar4 + 0xa8);
            if (cVar1 == '\x01') {
              cVar1 = *(char *)(lVar4 + 0xe0);
              dVar8 = *(double *)(lVar4 + 200);
              *(float *)(this + 0xa2c) = (float)dVar8;
              if (cVar1 == '\x01') {
                dVar10 = *(double *)(lVar4 + 0xe8);
                *(float *)(this + 0xa30) = (float)dVar10;
                bVar2 = true;
                if ((0.0 < fVar6) && (bVar2 = false, !NAN(ABS(fVar6)))) {
                  bVar2 = ABS(fVar6) == INFINITY;
                }
                if (bVar2) {
                  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                  RuntimeError::RuntimeError
                            (this_00,"MultioctaveNoise::octaves must be > 0 and can\'t be infinite")
                  ;
                }
                else {
                  bVar2 = true;
                  if ((0.0 <= fVar9) && (bVar2 = false, !NAN(ABS(fVar9)))) {
                    bVar2 = ABS(fVar9) == INFINITY;
                  }
                  if (bVar2) {
                    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                    RuntimeError::RuntimeError
                              (this_00,
                               "MultioctaveNoise::input_scale must be >= 0 and can\'t be infinite");
                  }
                  else if (ABS((float)dVar8) == INFINITY) {
                    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                    RuntimeError::RuntimeError
                              (this_00,"MultioctaveNoise::offset_x can\'t be infinite");
                  }
                  else {
                    if (ABS((float)dVar10) != INFINITY) {
                      return this;
                    }
                    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                    RuntimeError::RuntimeError
                              (this_00,"MultioctaveNoise::offset_y can\'t be infinite");
                  }
                }
              }
              else {
                this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0xe0),"offset_y")
                ;
              }
            }
            else {
              this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
              NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0xc0),"offset_x");
            }
          }
          else {
            this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
            NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0xa0),"output_scale")
            ;
          }
        }
        else {
          this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
          NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0x80),"input_scale");
        }
      }
      else {
        this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
        NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0x60),"octaves");
      }
    }
    else {
      this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
      NoiseExpressionConstant::getInvalidParameterError(pcVar3 + 0x20,"seed0");
    }
  }
  else {
    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(pcVar3,"persistence");
  }
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this_00,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



// ===== MultioctaveNoise  @ 0x101602218 =====

/* NoiseOperations::MultioctaveNoise::MultioctaveNoise(NoiseRegisterIndex,
   std::array<NoiseRegisterIndex, 2ul> const&, std::span<NoiseExpressionConstant const, 8ul> const&)
    */

MultioctaveNoise * __thiscall
NoiseOperations::MultioctaveNoise::MultioctaveNoise
          (MultioctaveNoise *this,undefined4 param_2,undefined8 *param_3,long *param_4)

{
  char cVar1;
  bool bVar2;
  RuntimeError *this_00;
  char *pcVar3;
  long lVar4;
  int iVar5;
  float fVar6;
  undefined8 uVar7;
  double dVar8;
  float fVar9;
  double dVar10;
  
  uVar7 = *param_3;
  *(undefined4 *)(this + 8) = param_2;
  *(undefined8 *)(this + 0xc) = uVar7;
  *(undefined ***)this = &PTR__MultioctaveNoise_102f85240;
  pcVar3 = (char *)*param_4;
  if (*pcVar3 == '\x01') {
    cVar1 = pcVar3[0x20];
    *(float *)(this + 0x14) = (float)*(double *)(pcVar3 + 8);
    if (cVar1 == '\x01') {
      dVar8 = *(double *)(pcVar3 + 0x28);
      if (NAN(dVar8)) {
        iVar5 = 0;
      }
      else if (4294967295.0 <= dVar8) {
        iVar5 = -1;
      }
      else {
        iVar5 = 0;
        if (0.0 < dVar8) {
          iVar5 = (int)dVar8;
        }
      }
      uVar7 = NoiseExpressionConstant::asNoiseLayerID
                        ((NoiseExpressionConstant *)(pcVar3 + 0x40),"seed1");
      _bzero(this + 0x220,0x800);
      Noise::setSeed((Noise *)(this + 0x18),iVar5 + ((uint)((ulong)uVar7 >> 8) & 0xffffff) * 7,
                     (uchar)uVar7);
      lVar4 = *param_4;
      if (*(char *)(lVar4 + 0x60) == '\x01') {
        cVar1 = *(char *)(lVar4 + 0x80);
        fVar6 = (float)*(double *)(lVar4 + 0x68);
        *(float *)(this + 0xa20) = fVar6;
        if (cVar1 == '\x01') {
          cVar1 = *(char *)(lVar4 + 0xa0);
          fVar9 = (float)*(double *)(lVar4 + 0x88);
          *(float *)(this + 0xa24) = fVar9;
          if (cVar1 == '\x01') {
            cVar1 = *(char *)(lVar4 + 0xc0);
            *(float *)(this + 0xa28) = (float)*(double *)(lVar4 + 0xa8);
            if (cVar1 == '\x01') {
              cVar1 = *(char *)(lVar4 + 0xe0);
              dVar8 = *(double *)(lVar4 + 200);
              *(float *)(this + 0xa2c) = (float)dVar8;
              if (cVar1 == '\x01') {
                dVar10 = *(double *)(lVar4 + 0xe8);
                *(float *)(this + 0xa30) = (float)dVar10;
                bVar2 = true;
                if ((0.0 < fVar6) && (bVar2 = false, !NAN(ABS(fVar6)))) {
                  bVar2 = ABS(fVar6) == INFINITY;
                }
                if (bVar2) {
                  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                  RuntimeError::RuntimeError
                            (this_00,"MultioctaveNoise::octaves must be > 0 and can\'t be infinite")
                  ;
                }
                else {
                  bVar2 = true;
                  if ((0.0 <= fVar9) && (bVar2 = false, !NAN(ABS(fVar9)))) {
                    bVar2 = ABS(fVar9) == INFINITY;
                  }
                  if (bVar2) {
                    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                    RuntimeError::RuntimeError
                              (this_00,
                               "MultioctaveNoise::input_scale must be >= 0 and can\'t be infinite");
                  }
                  else if (ABS((float)dVar8) == INFINITY) {
                    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                    RuntimeError::RuntimeError
                              (this_00,"MultioctaveNoise::offset_x can\'t be infinite");
                  }
                  else {
                    if (ABS((float)dVar10) != INFINITY) {
                      return this;
                    }
                    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                    RuntimeError::RuntimeError
                              (this_00,"MultioctaveNoise::offset_y can\'t be infinite");
                  }
                }
              }
              else {
                this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0xe0),"offset_y")
                ;
              }
            }
            else {
              this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
              NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0xc0),"offset_x");
            }
          }
          else {
            this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
            NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0xa0),"output_scale")
            ;
          }
        }
        else {
          this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
          NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0x80),"input_scale");
        }
      }
      else {
        this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
        NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0x60),"octaves");
      }
    }
    else {
      this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
      NoiseExpressionConstant::getInvalidParameterError(pcVar3 + 0x20,"seed0");
    }
  }
  else {
    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(pcVar3,"persistence");
  }
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this_00,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
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



