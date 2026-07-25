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



// ===== FloatCastCheckFailed  @ 0x1001d60c4 =====

/* FloatCastCheckFailed(float, char const*, float) */

void FloatCastCheckFailed(float param_1,char *param_2,float param_3)

{
                    /* WARNING: Subroutine does not return */
  Logging::logAndAbortOrThrow
            ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/FloatCast.cpp"
             ,0xc,9,"%f %s %f");
}



// ===== logAndAbortOrThrow  @ 0x1000f3c08 =====

/* Logging::logAndAbortOrThrow(char const*, unsigned int, LogLevel, char const*, ...) */

void Logging::logAndAbortOrThrow
               (undefined8 param_1,undefined8 param_2,undefined8 param_3,char *param_4,...)

{
  code *pcVar1;
  undefined1 auStack_50 [24];
  
  vssprintf(param_4,&stack0x00000000);
  logAndAbortOrThrow(param_1,param_2,param_3,auStack_50);
                    /* WARNING: Does not return */
  pcVar1 = (code *)SoftwareBreakpoint(1,0x1000f3c58);
  (*pcVar1)();
}



// ===== ReleaseAssertFailed  @ 0x100156914 =====

/* ReleaseAssertFailed(char const*, unsigned int, char const*) */

void ReleaseAssertFailed(char *param_1,uint param_2,char *param_3)

{
                    /* WARNING: Subroutine does not return */
  Logging::logAndAbortOrThrow(param_1,param_2,9,"%s was not true");
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



// ===== log2  @ 0x1025eac10 =====

/* Math::log2(float) */

float Math::log2(float param_1)

{
  float fVar1;
  
  fVar1 = (float)((uint)param_1 & 0x7fffff | 0x3f000000);
  return (float)(uint)param_1 * 1.1920929e-07 + -124.22552 + fVar1 * -1.4980303 +
         -1.72588 / (fVar1 + 0.35208872);
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



