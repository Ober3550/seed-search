// ===== VariablePersistenceMultioctaveNoise @0x101611c50 =====

/* NoiseOperations::VariablePersistenceMultioctaveNoise::VariablePersistenceMultioctaveNoise(NoiseRegisterIndex,
   std::array<NoiseRegisterIndex, 3ul> const&, std::span<NoiseExpressionConstant const, 7ul> const&)
    */

VariablePersistenceMultioctaveNoise * __thiscall
NoiseOperations::VariablePersistenceMultioctaveNoise::VariablePersistenceMultioctaveNoise
          (VariablePersistenceMultioctaveNoise *this,undefined4 param_2,undefined8 *param_3,
          long *param_4)

{
  uint uVar1;
  char cVar2;
  RuntimeError *this_00;
  char *pcVar3;
  long lVar4;
  uint uVar5;
  int iVar6;
  undefined8 uVar7;
  double dVar8;
  double dVar9;
  
  uVar7 = *param_3;
  *(undefined4 *)(this + 8) = param_2;
  *(undefined8 *)(this + 0xc) = uVar7;
  *(undefined ***)this = &PTR__VariablePersistenceMultioctaveNoise_102f85d58;
  *(undefined4 *)(this + 0x14) = *(undefined4 *)(param_3 + 1);
  pcVar3 = (char *)*param_4;
  if (*pcVar3 == '\x01') {
    dVar8 = *(double *)(pcVar3 + 8);
    if (NAN(dVar8)) {
      iVar6 = 0;
    }
    else if (4294967295.0 <= dVar8) {
      iVar6 = -1;
    }
    else {
      iVar6 = 0;
      if (0.0 < dVar8) {
        iVar6 = (int)dVar8;
      }
    }
    uVar7 = NoiseExpressionConstant::asNoiseLayerID
                      ((NoiseExpressionConstant *)(pcVar3 + 0x20),"seed1");
    _bzero(this + 0x220,0x800);
    Noise::setSeed((Noise *)(this + 0x18),iVar6 + ((uint)((ulong)uVar7 >> 8) & 0xffffff) * 7,
                   (uchar)uVar7);
    lVar4 = *param_4;
    if (*(char *)(lVar4 + 0x40) == '\x01') {
      dVar8 = *(double *)(lVar4 + 0x48);
      if (NAN(dVar8)) {
        uVar5 = 0;
        *(undefined4 *)(this + 0xa20) = 0;
        cVar2 = *(char *)(lVar4 + 0x60);
      }
      else {
        uVar1 = 0;
        if (0.0 < dVar8) {
          uVar1 = (int)dVar8;
        }
        uVar5 = 0xffffffff;
        if (dVar8 < 4294967295.0) {
          uVar5 = uVar1;
        }
        *(uint *)(this + 0xa20) = uVar5;
        cVar2 = *(char *)(lVar4 + 0x60);
      }
      if (cVar2 == '\x01') {
        cVar2 = *(char *)(lVar4 + 0x80);
        *(float *)(this + 0xa24) = (float)*(double *)(lVar4 + 0x68) * 0.5;
        if (cVar2 == '\x01') {
          dVar8 = *(double *)(lVar4 + 0x88);
          dVar9 = (double)Math::powPrecise(2.0,(double)uVar5);
          *(float *)(this + 0xa28) = (float)(dVar9 * (double)(float)dVar8);
          lVar4 = *param_4;
          if (*(char *)(lVar4 + 0xa0) == '\x01') {
            cVar2 = *(char *)(lVar4 + 0xc0);
            dVar8 = *(double *)(lVar4 + 0xa8);
            *(float *)(this + 0xa2c) = (float)dVar8;
            if (cVar2 == '\x01') {
              cVar2 = *(char *)(lVar4 + 0x40);
              dVar9 = *(double *)(lVar4 + 200);
              *(float *)(this + 0xa30) = (float)dVar9;
              if (cVar2 == '\x01') {
                if ((*(double *)(lVar4 + 0x48) <= 0.0) ||
                   (ABS(*(double *)(lVar4 + 0x48)) == INFINITY)) {
                  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                  RuntimeError::RuntimeError
                            (this_00,
                             "VariablePersistenceMultioctaveNoise::octaves must be > 0 and can\'t be infinite"
                            );
                }
                else if ((*(float *)(this + 0xa24) < 0.0) ||
                        (ABS(*(float *)(this + 0xa24)) == INFINITY)) {
                  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                  RuntimeError::RuntimeError
                            (this_00,
                             "MultioctaveNoise::input_scale must be >= 0 and can\'t be infinite");
                }
                else if (ABS((float)dVar8) == INFINITY) {
                  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                  RuntimeError::RuntimeError
                            (this_00,
                             "VariablePersistenceMultioctaveNoise::offset_x can\'t be infinite");
                }
                else {
                  if (ABS((float)dVar9) != INFINITY) {
                    return this;
                  }
                  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                  RuntimeError::RuntimeError
                            (this_00,
                             "VariablePersistenceMultioctaveNoise::offset_y can\'t be infinite");
                }
              }
              else {
                this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                NoiseExpressionConstant::getInvalidParameterError
                          ((char *)(lVar4 + 0x40),(char *)0x0);
              }
            }
            else {
              this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
              NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0xc0),"offset_y");
            }
          }
          else {
            this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
            NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0xa0),"offset_x");
          }
        }
        else {
          this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
          NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0x80),"output_scale");
        }
      }
      else {
        this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
        NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0x60),"input_scale");
      }
    }
    else {
      this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
      NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0x40),"octaves");
    }
  }
  else {
    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(pcVar3,"seed0");
  }
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this_00,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



// ===== VariablePersistenceMultioctaveNoise @0x1015f1c50 =====

/* NoiseOperations::VariablePersistenceMultioctaveNoise::VariablePersistenceMultioctaveNoise(NoiseRegisterIndex,
   std::array<NoiseRegisterIndex, 3ul> const&, std::span<NoiseExpressionConstant const, 7ul> const&)
    */

VariablePersistenceMultioctaveNoise * __thiscall
NoiseOperations::VariablePersistenceMultioctaveNoise::VariablePersistenceMultioctaveNoise
          (VariablePersistenceMultioctaveNoise *this,undefined4 param_2,undefined8 *param_3,
          long *param_4)

{
  uint uVar1;
  char cVar2;
  RuntimeError *this_00;
  char *pcVar3;
  long lVar4;
  uint uVar5;
  int iVar6;
  undefined8 uVar7;
  double dVar8;
  double dVar9;
  
  uVar7 = *param_3;
  *(undefined4 *)(this + 8) = param_2;
  *(undefined8 *)(this + 0xc) = uVar7;
  *(undefined ***)this = &PTR__VariablePersistenceMultioctaveNoise_102f85d58;
  *(undefined4 *)(this + 0x14) = *(undefined4 *)(param_3 + 1);
  pcVar3 = (char *)*param_4;
  if (*pcVar3 == '\x01') {
    dVar8 = *(double *)(pcVar3 + 8);
    if (NAN(dVar8)) {
      iVar6 = 0;
    }
    else if (4294967295.0 <= dVar8) {
      iVar6 = -1;
    }
    else {
      iVar6 = 0;
      if (0.0 < dVar8) {
        iVar6 = (int)dVar8;
      }
    }
    uVar7 = NoiseExpressionConstant::asNoiseLayerID
                      ((NoiseExpressionConstant *)(pcVar3 + 0x20),"seed1");
    _bzero(this + 0x220,0x800);
    Noise::setSeed((Noise *)(this + 0x18),iVar6 + ((uint)((ulong)uVar7 >> 8) & 0xffffff) * 7,
                   (uchar)uVar7);
    lVar4 = *param_4;
    if (*(char *)(lVar4 + 0x40) == '\x01') {
      dVar8 = *(double *)(lVar4 + 0x48);
      if (NAN(dVar8)) {
        uVar5 = 0;
        *(undefined4 *)(this + 0xa20) = 0;
        cVar2 = *(char *)(lVar4 + 0x60);
      }
      else {
        uVar1 = 0;
        if (0.0 < dVar8) {
          uVar1 = (int)dVar8;
        }
        uVar5 = 0xffffffff;
        if (dVar8 < 4294967295.0) {
          uVar5 = uVar1;
        }
        *(uint *)(this + 0xa20) = uVar5;
        cVar2 = *(char *)(lVar4 + 0x60);
      }
      if (cVar2 == '\x01') {
        cVar2 = *(char *)(lVar4 + 0x80);
        *(float *)(this + 0xa24) = (float)*(double *)(lVar4 + 0x68) * 0.5;
        if (cVar2 == '\x01') {
          dVar8 = *(double *)(lVar4 + 0x88);
          dVar9 = (double)Math::powPrecise(2.0,(double)uVar5);
          *(float *)(this + 0xa28) = (float)(dVar9 * (double)(float)dVar8);
          lVar4 = *param_4;
          if (*(char *)(lVar4 + 0xa0) == '\x01') {
            cVar2 = *(char *)(lVar4 + 0xc0);
            dVar8 = *(double *)(lVar4 + 0xa8);
            *(float *)(this + 0xa2c) = (float)dVar8;
            if (cVar2 == '\x01') {
              cVar2 = *(char *)(lVar4 + 0x40);
              dVar9 = *(double *)(lVar4 + 200);
              *(float *)(this + 0xa30) = (float)dVar9;
              if (cVar2 == '\x01') {
                if ((*(double *)(lVar4 + 0x48) <= 0.0) ||
                   (ABS(*(double *)(lVar4 + 0x48)) == INFINITY)) {
                  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                  RuntimeError::RuntimeError
                            (this_00,
                             "VariablePersistenceMultioctaveNoise::octaves must be > 0 and can\'t be infinite"
                            );
                }
                else if ((*(float *)(this + 0xa24) < 0.0) ||
                        (ABS(*(float *)(this + 0xa24)) == INFINITY)) {
                  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                  RuntimeError::RuntimeError
                            (this_00,
                             "MultioctaveNoise::input_scale must be >= 0 and can\'t be infinite");
                }
                else if (ABS((float)dVar8) == INFINITY) {
                  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                  RuntimeError::RuntimeError
                            (this_00,
                             "VariablePersistenceMultioctaveNoise::offset_x can\'t be infinite");
                }
                else {
                  if (ABS((float)dVar9) != INFINITY) {
                    return this;
                  }
                  this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                  RuntimeError::RuntimeError
                            (this_00,
                             "VariablePersistenceMultioctaveNoise::offset_y can\'t be infinite");
                }
              }
              else {
                this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
                NoiseExpressionConstant::getInvalidParameterError
                          ((char *)(lVar4 + 0x40),(char *)0x0);
              }
            }
            else {
              this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
              NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0xc0),"offset_y");
            }
          }
          else {
            this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
            NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0xa0),"offset_x");
          }
        }
        else {
          this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
          NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0x80),"output_scale");
        }
      }
      else {
        this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
        NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0x60),"input_scale");
      }
    }
    else {
      this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
      NoiseExpressionConstant::getInvalidParameterError((char *)(lVar4 + 0x40),"octaves");
    }
  }
  else {
    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(pcVar3,"seed0");
  }
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this_00,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



