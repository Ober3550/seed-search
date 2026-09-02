// ===== 1015dd638 asNoiseLayerID =====

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



TOTAL 1
