// VoronoiNoise factories + ctors (factorio-arm64 2.0.77)

// ===== 0x1015e4440 VoronoiNoise =====

/* NoiseOperations::VoronoiNoise::VoronoiNoise(Deserialiser&) */

VoronoiNoise * __thiscall
NoiseOperations::VoronoiNoise::VoronoiNoise(VoronoiNoise *this,Deserialiser *param_1)

{
  undefined4 uStack_24;
  
  *(undefined ***)this = &PTR__VoronoiNoise_102f85da8;
  Deserialiser::readOrThrow(param_1,&uStack_24,4);
  *(undefined4 *)(this + 8) = uStack_24;
  Deserialiser::readOrThrow(param_1,&uStack_24,4);
  *(undefined4 *)(this + 0xc) = uStack_24;
  Deserialiser::readOrThrow(param_1,&uStack_24,4);
  *(undefined4 *)(this + 0x10) = uStack_24;
  Deserialiser::readOrThrow(param_1,&uStack_24,4);
  *(undefined4 *)(this + 0x14) = uStack_24;
  Deserialiser::readOrThrow(param_1,&uStack_24,4);
  *(undefined4 *)(this + 0x18) = uStack_24;
  Deserialiser::readOrThrow(param_1,&uStack_24,4);
  *(undefined4 *)(this + 0x1c) = uStack_24;
  Deserialiser::readOrThrow(param_1,&uStack_24,4);
  *(undefined4 *)(this + 0x20) = uStack_24;
  Deserialiser::readOrThrow(param_1,&uStack_24,2);
  *(undefined2 *)(this + 0x24) = (undefined2)uStack_24;
  Deserialiser::readOrThrow(param_1,&uStack_24,1);
  this[0x26] = uStack_24._0_1_;
  Deserialiser::readOrThrow(param_1,&uStack_24,4);
  *(undefined4 *)(this + 0x28) = uStack_24;
  return this;
}



// ===== 0x1016126b8 VoronoiNoise =====

/* NoiseOperations::VoronoiNoise::VoronoiNoise(std::array<NoiseRegisterIndex, 2ul> const&,
   std::array<NoiseExpressionConstant, 5ul> const&) */

VoronoiNoise * __thiscall
NoiseOperations::VoronoiNoise::VoronoiNoise(VoronoiNoise *this,array *param_1,array *param_2)

{
  undefined2 uVar1;
  undefined2 uVar2;
  bool bVar3;
  bool bVar4;
  bool bVar5;
  VoronoiNoise VVar6;
  int iVar7;
  RuntimeError *this_00;
  array *paVar8;
  float fVar9;
  double dVar10;
  
  *(undefined ***)this = &PTR__VoronoiNoise_102f85da8;
  *(undefined8 *)(this + 8) = 0xffffffffffffffff;
  *(undefined8 *)(this + 0x10) = 0xffffffffffffffff;
  *(undefined4 *)(this + 0x18) = *(undefined4 *)param_1;
  *(undefined4 *)(this + 0x1c) = *(undefined4 *)(param_1 + 4);
  if (*param_2 == (array)0x1) {
    dVar10 = *(double *)(param_2 + 8);
    iVar7 = NoiseExpressionConstant::asNoiseLayerID
                      ((NoiseExpressionConstant *)(param_2 + 0x20),"seed1");
    *(int *)(this + 0x20) = iVar7 + (int)dVar10;
    paVar8 = param_2 + 0x40;
    if (*paVar8 == (array)0x1) {
      dVar10 = *(double *)(param_2 + 0x48);
      uVar2 = 0;
      if (0.0 < dVar10) {
        uVar2 = (short)(int)dVar10;
      }
      uVar1 = 0xffff;
      if (dVar10 < 65535.0) {
        uVar1 = uVar2;
      }
      uVar2 = 0;
      if (!NAN(dVar10)) {
        uVar2 = uVar1;
      }
      *(undefined2 *)(this + 0x24) = uVar2;
      VVar6 = (VoronoiNoise)parseDistanceType((NoiseExpressionConstant *)(param_2 + 0x60));
      this[0x26] = VVar6;
      if (param_2[0x80] == (array)0x1) {
        fVar9 = (float)*(double *)(param_2 + 0x88);
        *(float *)(this + 0x28) = fVar9;
        if (param_2[0x40] == (array)0x1) {
          if ((*(double *)(param_2 + 0x48) < 1.0) || (65535.0 < *(double *)(param_2 + 0x48))) {
            this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
            RuntimeError::RuntimeError
                      (this_00,"VoronoiNoise::grid_size must be in [1, 65536] range.");
          }
          else {
            bVar3 = false;
            bVar4 = false;
            bVar5 = false;
            if (0.0 <= fVar9) {
              bVar3 = false;
              bVar4 = false;
              bVar5 = true;
              if (!NAN(fVar9)) {
                bVar3 = fVar9 < 1.0;
                bVar4 = fVar9 == 1.0;
                bVar5 = false;
              }
            }
            if (bVar4 || bVar3 != bVar5) {
              return this;
            }
            this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
            RuntimeError::RuntimeError(this_00,"VoronoiNoise::jitter must be in [0,1] range");
          }
        }
        else {
          this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
          NoiseExpressionConstant::getInvalidParameterError((char *)paVar8,(char *)0x0);
        }
      }
      else {
        this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
        NoiseExpressionConstant::getInvalidParameterError((char *)(param_2 + 0x80),"jitter");
      }
    }
    else {
      this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
      NoiseExpressionConstant::getInvalidParameterError((char *)paVar8,"grid_size");
    }
  }
  else {
    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError((char *)param_2,"seed0");
  }
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this_00,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



// ===== 0x101612b74 VoronoiNoise =====

/* NoiseOperations::VoronoiNoise::VoronoiNoise(std::array<NoiseRegisterIndex, 2ul> const&,
   std::array<NoiseExpressionConstant, 5ul> const&) */

VoronoiNoise * __thiscall
NoiseOperations::VoronoiNoise::VoronoiNoise(VoronoiNoise *this,array *param_1,array *param_2)

{
  undefined2 uVar1;
  undefined2 uVar2;
  bool bVar3;
  bool bVar4;
  bool bVar5;
  VoronoiNoise VVar6;
  int iVar7;
  RuntimeError *this_00;
  array *paVar8;
  float fVar9;
  double dVar10;
  
  *(undefined ***)this = &PTR__VoronoiNoise_102f85da8;
  *(undefined8 *)(this + 8) = 0xffffffffffffffff;
  *(undefined8 *)(this + 0x10) = 0xffffffffffffffff;
  *(undefined4 *)(this + 0x18) = *(undefined4 *)param_1;
  *(undefined4 *)(this + 0x1c) = *(undefined4 *)(param_1 + 4);
  if (*param_2 == (array)0x1) {
    dVar10 = *(double *)(param_2 + 8);
    iVar7 = NoiseExpressionConstant::asNoiseLayerID
                      ((NoiseExpressionConstant *)(param_2 + 0x20),"seed1");
    *(int *)(this + 0x20) = iVar7 + (int)dVar10;
    paVar8 = param_2 + 0x40;
    if (*paVar8 == (array)0x1) {
      dVar10 = *(double *)(param_2 + 0x48);
      uVar2 = 0;
      if (0.0 < dVar10) {
        uVar2 = (short)(int)dVar10;
      }
      uVar1 = 0xffff;
      if (dVar10 < 65535.0) {
        uVar1 = uVar2;
      }
      uVar2 = 0;
      if (!NAN(dVar10)) {
        uVar2 = uVar1;
      }
      *(undefined2 *)(this + 0x24) = uVar2;
      VVar6 = (VoronoiNoise)parseDistanceType((NoiseExpressionConstant *)(param_2 + 0x60));
      this[0x26] = VVar6;
      if (param_2[0x80] == (array)0x1) {
        fVar9 = (float)*(double *)(param_2 + 0x88);
        *(float *)(this + 0x28) = fVar9;
        if (param_2[0x40] == (array)0x1) {
          if ((*(double *)(param_2 + 0x48) < 1.0) || (65535.0 < *(double *)(param_2 + 0x48))) {
            this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
            RuntimeError::RuntimeError
                      (this_00,"VoronoiNoise::grid_size must be in [1, 65536] range.");
          }
          else {
            bVar3 = false;
            bVar4 = false;
            bVar5 = false;
            if (0.0 <= fVar9) {
              bVar3 = false;
              bVar4 = false;
              bVar5 = true;
              if (!NAN(fVar9)) {
                bVar3 = fVar9 < 1.0;
                bVar4 = fVar9 == 1.0;
                bVar5 = false;
              }
            }
            if (bVar4 || bVar3 != bVar5) {
              return this;
            }
            this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
            RuntimeError::RuntimeError(this_00,"VoronoiNoise::jitter must be in [0,1] range");
          }
        }
        else {
          this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
          NoiseExpressionConstant::getInvalidParameterError((char *)paVar8,(char *)0x0);
        }
      }
      else {
        this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
        NoiseExpressionConstant::getInvalidParameterError((char *)(param_2 + 0x80),"jitter");
      }
    }
    else {
      this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
      NoiseExpressionConstant::getInvalidParameterError((char *)paVar8,"grid_size");
    }
  }
  else {
    this_00 = (RuntimeError *)___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError((char *)param_2,"seed0");
  }
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this_00,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
}



// ===== 0x102261b24 getOrCreate<NoiseExpressions::VoronoiNoise,std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&> =====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* NoiseExpressions::VoronoiNoise const&
   NoiseExpressionStorage::getOrCreate<NoiseExpressions::VoronoiNoise, std::vector<NoiseExpression
   const*, std::allocator<NoiseExpression const*> > const&>(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&) */

VoronoiNoise * __thiscall
NoiseExpressionStorage::
getOrCreate<NoiseExpressions::VoronoiNoise,std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&>
          (NoiseExpressionStorage *this,vector *param_1)

{
  long *plVar1;
  long *plVar2;
  ulong uVar3;
  long lVar4;
  long lVar5;
  long lVar6;
  long lVar7;
  long lVar8;
  long lVar9;
  long lVar10;
  undefined1 auVar11 [16];
  long local_e8;
  long lStack_e0;
  undefined4 local_d8;
  long *local_d0 [8];
  uint local_90;
  long local_88;
  undefined8 local_80;
  undefined8 uStack_78;
  undefined8 uStack_70;
  undefined8 uStack_68;
  undefined4 local_60;
  long local_58;
  
  local_58 = *(long *)PTR____stack_chk_guard_102d481b8;
  local_88 = 0;
  local_60 = 0xca62c1d6;
  local_d0[0] = (long *)CONCAT71(local_d0[0]._1_7_,0x26);
  uVar3 = 1;
  local_90 = 1;
  plVar1 = *(long **)(param_1 + 8);
  uStack_78 = _UNK_102971028;
  local_80 = _DAT_102971020;
  uStack_68 = _UNK_102971038;
  uStack_70 = _DAT_102971030;
  for (plVar2 = *(long **)param_1; plVar2 != plVar1; plVar2 = plVar2 + 1) {
    lVar4 = *plVar2;
    lVar5 = 8;
    do {
      *(undefined1 *)((long)local_d0 + uVar3) = *(undefined1 *)(lVar4 + lVar5);
      local_90 = local_90 + 1;
      uVar3 = (ulong)local_90;
      if (local_90 == 0x40) {
        sha1_transform((SHA1_CTX *)local_d0,(uchar *)local_d0);
        uVar3 = 0;
        local_88 = local_88 + 0x200;
        local_90 = 0;
      }
      lVar5 = lVar5 + 1;
    } while (lVar5 != 0x1c);
  }
  SHA1::finalise();
  local_d0[0] = &local_e8;
  auVar11 = std::
            __tree<std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>,std::__map_value_compare<SHA1Digest,std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>,std::less<SHA1Digest>,true>,std::allocator<std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>>>
            ::
            __emplace_unique_key_args<SHA1Digest,std::piecewise_construct_t_const&,std::tuple<SHA1Digest_const&>,std::tuple<>>
                      ((SHA1Digest *)(this + 0x20),(piecewise_construct_t *)&local_e8,
                       (tuple *)&std::piecewise_construct,(tuple *)local_d0);
  lVar5 = auVar11._0_8_;
  if ((auVar11._8_8_ & 0xff) != 0) {
    plVar1 = operator_new(0x58);
    plVar1[1] = 0;
    plVar1[2] = 0;
    *(undefined4 *)(plVar1 + 3) = 0;
    *plVar1 = (long)(PTR_vtable_102d56228 + 0x10);
    plVar2 = *(long **)param_1;
    if (*(long *)(param_1 + 8) - (long)plVar2 != 0x38) {
                    /* WARNING: Subroutine does not return */
      ReleaseAssertFailed("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Noise/Expression/ComplexNoiseExpressions.cpp"
                          ,0x1a,"args.size() == N");
    }
    lVar6 = plVar2[1];
    lVar4 = *plVar2;
    lVar8 = plVar2[3];
    lVar7 = plVar2[2];
    lVar10 = plVar2[5];
    lVar9 = plVar2[4];
    plVar1[10] = plVar2[6];
    plVar1[7] = lVar8;
    plVar1[6] = lVar7;
    plVar1[9] = lVar10;
    plVar1[8] = lVar9;
    plVar1[5] = lVar6;
    plVar1[4] = lVar4;
    *plVar1 = (long)&PTR__VoronoiNoise_102fb0798;
    plVar2 = *(long **)(lVar5 + 0x38);
    *(undefined8 *)(lVar5 + 0x38) = 0;
    if (plVar2 != (long *)0x0) {
      (**(code **)(*plVar2 + 8))();
    }
    *(long **)(lVar5 + 0x38) = plVar1;
    plVar1[2] = lStack_e0;
    plVar1[1] = local_e8;
    *(undefined4 *)(plVar1 + 3) = local_d8;
  }
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_58) {
    return *(VoronoiNoise **)(lVar5 + 0x38);
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}



// ===== 0x102261ad8 allocator<NoiseExpression_const*>_>_const&) =====

/* NativeNoiseFunctions::NamedFunction::create<(NoiseExpressions::VoronoiType)0>(std::vector<NoiseFunctionParameter,
   std::allocator<NoiseFunctionParameter> >&&)::{lambda(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&)#1}::__invoke(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&) */

void NativeNoiseFunctions::NamedFunction::
     create<(NoiseExpressions::VoronoiType)0>(std::vector<NoiseFunctionParameter,std::allocator<NoiseFunctionParameter>>&&)
     ::{lambda(std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&)#1}
     ::allocator<NoiseExpression_const*>_>_const__(vector *param_1)

{
  VoronoiNoise *pVVar1;
  VoronoiType local_21;
  
  pVVar1 = NoiseExpressionStorage::
           getOrCreate<NoiseExpressions::VoronoiNoise,std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&>
                     (*(NoiseExpressionStorage **)(_global + 0xb0),param_1);
  local_21 = 0;
  NoiseExpressionStorage::
  getOrCreate<NoiseExpressions::VoronoiNoiseWrapper,NoiseExpressions::VoronoiNoise_const&,NoiseExpressions::VoronoiType>
            (*(NoiseExpressionStorage **)(_global + 0xb0),pVVar1,&local_21);
  return;
}



// ===== 0x102261ef4 allocator<NoiseExpression_const*>_>_const&) =====

/* NativeNoiseFunctions::NamedFunction::create<(NoiseExpressions::VoronoiType)1>(std::vector<NoiseFunctionParameter,
   std::allocator<NoiseFunctionParameter> >&&)::{lambda(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&)#1}::__invoke(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&) */

void NativeNoiseFunctions::NamedFunction::
     create<(NoiseExpressions::VoronoiType)1>(std::vector<NoiseFunctionParameter,std::allocator<NoiseFunctionParameter>>&&)
     ::{lambda(std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&)#1}
     ::allocator<NoiseExpression_const*>_>_const__(vector *param_1)

{
  VoronoiNoise *pVVar1;
  VoronoiType local_21;
  
  pVVar1 = NoiseExpressionStorage::
           getOrCreate<NoiseExpressions::VoronoiNoise,std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&>
                     (*(NoiseExpressionStorage **)(_global + 0xb0),param_1);
  local_21 = 1;
  NoiseExpressionStorage::
  getOrCreate<NoiseExpressions::VoronoiNoiseWrapper,NoiseExpressions::VoronoiNoise_const&,NoiseExpressions::VoronoiType>
            (*(NoiseExpressionStorage **)(_global + 0xb0),pVVar1,&local_21);
  return;
}



// ===== 0x102261f44 allocator<NoiseExpression_const*>_>_const&) =====

/* NativeNoiseFunctions::NamedFunction::create<(NoiseExpressions::VoronoiType)2>(std::vector<NoiseFunctionParameter,
   std::allocator<NoiseFunctionParameter> >&&)::{lambda(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&)#1}::__invoke(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&) */

void NativeNoiseFunctions::NamedFunction::
     create<(NoiseExpressions::VoronoiType)2>(std::vector<NoiseFunctionParameter,std::allocator<NoiseFunctionParameter>>&&)
     ::{lambda(std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&)#1}
     ::allocator<NoiseExpression_const*>_>_const__(vector *param_1)

{
  VoronoiNoise *pVVar1;
  VoronoiType local_21;
  
  pVVar1 = NoiseExpressionStorage::
           getOrCreate<NoiseExpressions::VoronoiNoise,std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&>
                     (*(NoiseExpressionStorage **)(_global + 0xb0),param_1);
  local_21 = 2;
  NoiseExpressionStorage::
  getOrCreate<NoiseExpressions::VoronoiNoiseWrapper,NoiseExpressions::VoronoiNoise_const&,NoiseExpressions::VoronoiType>
            (*(NoiseExpressionStorage **)(_global + 0xb0),pVVar1,&local_21);
  return;
}



// ===== 0x102261f94 allocator<NoiseExpression_const*>_>_const&) =====

/* NativeNoiseFunctions::NamedFunction::create<(NoiseExpressions::VoronoiType)3>(std::vector<NoiseFunctionParameter,
   std::allocator<NoiseFunctionParameter> >&&)::{lambda(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&)#1}::__invoke(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&) */

void NativeNoiseFunctions::NamedFunction::
     create<(NoiseExpressions::VoronoiType)3>(std::vector<NoiseFunctionParameter,std::allocator<NoiseFunctionParameter>>&&)
     ::{lambda(std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&)#1}
     ::allocator<NoiseExpression_const*>_>_const__(vector *param_1)

{
  VoronoiNoise *pVVar1;
  VoronoiType local_21;
  
  pVVar1 = NoiseExpressionStorage::
           getOrCreate<NoiseExpressions::VoronoiNoise,std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&>
                     (*(NoiseExpressionStorage **)(_global + 0xb0),param_1);
  local_21 = 3;
  NoiseExpressionStorage::
  getOrCreate<NoiseExpressions::VoronoiNoiseWrapper,NoiseExpressions::VoronoiNoise_const&,NoiseExpressions::VoronoiType>
            (*(NoiseExpressionStorage **)(_global + 0xb0),pVVar1,&local_21);
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



