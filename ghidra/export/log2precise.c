// ==== 0x1025eac10 log2 ====

/* Math::log2(float) */

float Math::log2(float param_1)

{
  float fVar1;
  
  fVar1 = (float)((uint)param_1 & 0x7fffff | 0x3f000000);
  return (float)(uint)param_1 * 1.1920929e-07 + -124.22552 + fVar1 * -1.4980303 +
         -1.72588 / (fVar1 + 0.35208872);
}



// ==== 0x1025eac78 log2Precise ====

/* Math::log2Precise(double) */

undefined1  [16] Math::log2Precise(double param_1)

{
  double dVar1;
  uint uVar2;
  int iVar3;
  double dVar4;
  undefined1 auVar5 [16];
  double dVar6;
  double dVar7;
  double dVar8;
  double dVar9;
  
  if ((long)param_1 < 0) {
LAB_1025eacb4:
    dVar4 = NAN;
    if (ABS(param_1) == 0.0) {
      dVar4 = -INFINITY;
    }
    if (((long)param_1 < 0) || (ABS(param_1) == 0.0)) goto LAB_1025eae74;
    param_1 = param_1 * 18014398509481984.0;
    uVar2 = (uint)((ulong)param_1 >> 0x20);
    iVar3 = -0x435;
  }
  else {
    uVar2 = (uint)((ulong)param_1 >> 0x20);
    if (uVar2 >> 0x14 == 0) goto LAB_1025eacb4;
    dVar4 = param_1;
    if (0x7fe < uVar2 >> 0x14) goto LAB_1025eae74;
    if (uVar2 == 0x3ff00000) {
      if (SUB84(param_1,0) == 0) {
        return ZEXT816(0);
      }
      iVar3 = -0x3ff;
      uVar2 = 0x3ff00000;
    }
    else {
      iVar3 = -0x3ff;
    }
  }
  dVar4 = (double)((ulong)param_1 & 0xffffffff |
                  (ulong)((uVar2 + 0x95f62 & 0xfffff) + 0x3fe6a09e) << 0x20) + -1.0;
  dVar6 = dVar4 * dVar4 * 0.5;
  dVar7 = dVar4 / (dVar4 + 2.0);
  dVar8 = dVar7 * dVar7;
  dVar9 = dVar8 * dVar8;
  dVar1 = (double)((ulong)(dVar4 - dVar6) & 0xffffffff00000000);
  dVar6 = ((dVar4 - dVar1) - dVar6) +
          dVar7 * (dVar6 + dVar9 * (dVar9 * (dVar9 * 0.15313837699209373 + 0.22222198432149784) +
                                   0.3999999999940942) +
                           dVar8 * (dVar9 * (dVar9 * (dVar9 * 0.14798198605116586 +
                                                     0.1818357216161805) + 0.2857142874366239) +
                                   0.6666666666666735));
  dVar7 = (double)(int)(iVar3 + (uVar2 + 0x95f62 >> 0x14));
  dVar4 = dVar1 * 1.4426950407214463 + dVar7;
  dVar4 = dVar4 + dVar1 * 1.4426950407214463 + (dVar7 - dVar4) +
                  dVar6 * 1.4426950407214463 + (dVar6 + dVar1) * 1.6751713164886512e-10;
LAB_1025eae74:
  auVar5._8_8_ = 0;
  auVar5._0_8_ = dVar4;
  return auVar5;
}



