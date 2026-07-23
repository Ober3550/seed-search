// ===== Noise  @ 0x1015daca8 =====

/* Noise::Noise(bool) */

Noise * __thiscall Noise::Noise(Noise *this,bool param_1)

{
  double dVar1;
  float fVar2;
  ulong uVar3;
  undefined1 auVar4 [16];
  undefined1 auVar5 [16];
  undefined1 auVar6 [16];
  double dVar7;
  double dVar8;
  undefined1 auVar9 [16];
  undefined1 auVar10 [16];
  undefined1 auVar11 [16];
  double dVar12;
  double dVar13;
  double dVar14;
  
  *(undefined4 *)this = 0;
  *(undefined2 *)(this + 4) = 0;
  _bzero(this + 0x208,0x800);
  uVar3 = 0;
  auVar4 = NEON_fmov(0xbfe0000000000000,8);
  auVar5 = NEON_fmov(0x3fe0000000000000,8);
  auVar6 = NEON_fmov(0x3fd0000000000000,8);
  do {
    dVar1 = (double)(float)((double)uVar3 * 0.02454369260617026) * 0.15915494309189535;
    dVar7 = dVar1 + -0.25;
    auVar9._0_8_ = -(ulong)(0.0 < dVar1);
    auVar9._8_8_ = -(ulong)(0.0 < dVar7);
    auVar10 = auVar4 ^ (auVar4 ^ auVar5) & auVar9;
    auVar11._0_8_ = (long)(dVar1 + auVar10._0_8_);
    auVar11._8_8_ = (long)(dVar7 + auVar10._8_8_);
    auVar10 = NEON_scvtf(auVar11,8);
    dVar1 = auVar6._0_8_ - ABS(dVar1 - auVar10._0_8_);
    dVar7 = auVar6._8_8_ - ABS(dVar7 - auVar10._8_8_);
    this[uVar3 + 6] = SUB81(uVar3,0);
    dVar8 = dVar1 * dVar1;
    dVar12 = dVar7 * dVar7;
    dVar13 = dVar8 * dVar8;
    dVar14 = dVar12 * dVar12;
    this[uVar3 + 0x106] = SUB81(uVar3,0);
    dVar1 = dVar1 * (dVar13 * dVar13 * 39.65735524898863 +
                    dVar8 * -41.34167506665737 + 6.283185269630412 +
                    dVar13 * (dVar8 * -76.56887678023256 + 81.60201529595571)) * 4.2;
    dVar7 = dVar7 * (dVar14 * dVar14 * 39.65735524898863 +
                    dVar12 * -41.34167506665737 + 6.283185269630412 +
                    dVar14 * (dVar12 * -76.56887678023256 + 81.60201529595571)) * 4.2;
    auVar10[8] = SUB81(dVar7,0);
    auVar10._0_8_ = dVar1;
    auVar10[9] = (char)((ulong)dVar7 >> 8);
    auVar10[10] = (char)((ulong)dVar7 >> 0x10);
    auVar10[0xb] = (char)((ulong)dVar7 >> 0x18);
    auVar10[0xc] = (char)((ulong)dVar7 >> 0x20);
    auVar10[0xd] = (char)((ulong)dVar7 >> 0x28);
    auVar10[0xe] = (char)((ulong)dVar7 >> 0x30);
    auVar10[0xf] = (char)((ulong)dVar7 >> 0x38);
    fVar2 = (float)auVar10._8_8_;
    *(ulong *)(this + uVar3 * 8 + 0x208) =
         CONCAT17((char)((uint)fVar2 >> 0x18),
                  CONCAT16((char)((uint)fVar2 >> 0x10),
                           CONCAT15((char)((uint)fVar2 >> 8),CONCAT14(SUB41(fVar2,0),(float)dVar1)))
                 );
    uVar3 = uVar3 + 1;
  } while (uVar3 != 0x100);
  return this;
}



