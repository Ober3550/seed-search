// ===== NoiseExpressions::ExpressionInRange::peakToNoiseExpression @ 0x1015f42d0 =====

/* NoiseExpressions::ExpressionInRange::peakToNoiseExpression(NoiseExpression const&, double,
   double) */

undefined8
NoiseExpressions::ExpressionInRange::peakToNoiseExpression
          (NoiseExpression *param_1,double param_2,double param_3)

{
  undefined *puVar1;
  NoiseExpression *pNVar2;
  NoiseExpression *pNVar3;
  long lVar4;
  long *plVar5;
  long *plVar6;
  undefined8 uVar7;
  undefined8 uVar8;
  ComplexExpressionWithOperation *pCVar9;
  NoiseExpressionStorage *this;
  NoiseExpressionStorage *this_00;
  undefined8 uVar10;
  undefined1 auVar11 [16];
  undefined8 *local_b8;
  undefined8 *local_b0;
  undefined8 *puStack_a8;
  long *local_98;
  long local_90;
  long lStack_88;
  undefined4 local_80;
  long local_78;
  
  local_78 = *(long *)PTR____stack_chk_guard_102d481b8;
  this = *(NoiseExpressionStorage **)(_global + 0xb0);
  pNVar2 = (NoiseExpression *)NoiseExpressionStorage::getOrCreate(this,param_3);
  this_00 = *(NoiseExpressionStorage **)(_global + 0xb0);
  pNVar3 = (NoiseExpression *)NoiseExpressionStorage::getOrCreate(this_00,param_2);
  NoiseExpressions::
  BinaryExpression<NoiseOperations::BinaryOperation<(NoiseOperationType)3,&NoiseOperations::Functions::subtract,2ull>,false,&NoiseExpressions::Folding::subtract>
  ::computeHash(param_1,pNVar3);
  local_98 = &local_90;
  auVar11 = std::
            __tree<std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>,std::__map_value_compare<SHA1Digest,std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>,std::less<SHA1Digest>,true>,std::allocator<std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>>>
            ::
            __emplace_unique_key_args<SHA1Digest,std::piecewise_construct_t_const&,std::tuple<SHA1Digest_const&>,std::tuple<>>
                      ((SHA1Digest *)(this_00 + 0x20),(piecewise_construct_t *)&local_90,
                       (tuple *)&std::piecewise_construct,(tuple *)&local_98);
  puVar1 = PTR_vtable_102d561e8;
  lVar4 = auVar11._0_8_;
  if ((auVar11._8_8_ & 0xff) != 0) {
    plVar5 = operator_new(0x30);
    *plVar5 = (long)(puVar1 + 0x10);
    plVar5[4] = (long)param_1;
    plVar5[5] = (long)pNVar3;
    plVar6 = *(long **)(lVar4 + 0x38);
    *(undefined8 *)(lVar4 + 0x38) = 0;
    if (plVar6 != (long *)0x0) {
      (**(code **)(*plVar6 + 8))();
    }
    *(long **)(lVar4 + 0x38) = plVar5;
    plVar5[2] = lStack_88;
    plVar5[1] = local_90;
    *(undefined4 *)(plVar5 + 3) = local_80;
  }
  uVar10 = *(undefined8 *)(lVar4 + 0x38);
  uVar7 = NoiseExpressionStorage::getOrCreate(*(NoiseExpressionStorage **)(_global + 0xb0),0.0);
  uVar8 = NoiseExpressionStorage::getOrCreate(*(NoiseExpressionStorage **)(_global + 0xb0),INFINITY)
  ;
  local_b8 = operator_new(0x18);
  local_b0 = local_b8 + 3;
  *local_b8 = uVar10;
  local_b8[1] = uVar7;
  local_b8[2] = uVar8;
  puStack_a8 = local_b0;
  pCVar9 = NoiseExpressionStorage::
           getOrCreate<NoiseExpressions::ComplexExpressionWithOperation<NoiseOperations::Ridge,(unsigned_char)3,(unsigned_char)0>,std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>>
                     (this_00,(vector *)&local_b8);
  NoiseExpressions::
  BinaryExpression<NoiseOperations::BinaryOperation<(NoiseOperationType)3,&NoiseOperations::Functions::subtract,2ull>,false,&NoiseExpressions::Folding::subtract>
  ::computeHash(pNVar2,(NoiseExpression *)pCVar9);
  local_98 = &local_90;
  auVar11 = std::
            __tree<std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>,std::__map_value_compare<SHA1Digest,std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>,std::less<SHA1Digest>,true>,std::allocator<std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>>>
            ::
            __emplace_unique_key_args<SHA1Digest,std::piecewise_construct_t_const&,std::tuple<SHA1Digest_const&>,std::tuple<>>
                      ((SHA1Digest *)(this + 0x20),(piecewise_construct_t *)&local_90,
                       (tuple *)&std::piecewise_construct,(tuple *)&local_98);
  lVar4 = auVar11._0_8_;
  if ((auVar11._8_8_ & 0xff) != 0) {
    plVar5 = operator_new(0x30);
    *plVar5 = (long)(puVar1 + 0x10);
    plVar5[4] = (long)pNVar2;
    plVar5[5] = (long)pCVar9;
    plVar6 = *(long **)(lVar4 + 0x38);
    *(undefined8 *)(lVar4 + 0x38) = 0;
    if (plVar6 != (long *)0x0) {
      (**(code **)(*plVar6 + 8))();
    }
    *(long **)(lVar4 + 0x38) = plVar5;
    plVar5[2] = lStack_88;
    plVar5[1] = local_90;
    *(undefined4 *)(plVar5 + 3) = local_80;
  }
  uVar7 = *(undefined8 *)(lVar4 + 0x38);
  if (local_b8 != (undefined8 *)0x0) {
    local_b0 = local_b8;
    operator_delete(local_b8);
  }
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_78) {
    return uVar7;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}



// ===== NoiseExpressions::ExpressionInRange::clampedPeakToNoiseExpression @ 0x1015f4738 =====

/* NoiseExpressions::ExpressionInRange::clampedPeakToNoiseExpression(NoiseExpression const&, double,
   double, double, double) */

NoiseExpression *
NoiseExpressions::ExpressionInRange::clampedPeakToNoiseExpression
          (NoiseExpression *param_1,double param_2,double param_3,double param_4,double param_5)

{
  ComplexExpressionWithOperation *pCVar1;
  NoiseExpression *pNVar2;
  long lVar3;
  long *plVar4;
  long *plVar5;
  undefined8 uVar6;
  undefined8 uVar7;
  NoiseExpressionStorage *pNVar8;
  undefined1 auVar9 [16];
  undefined8 **local_78;
  undefined8 *local_70;
  undefined8 *puStack_68;
  undefined8 *local_60;
  long local_58;
  
  local_58 = *(long *)PTR____stack_chk_guard_102d481b8;
  pCVar1 = (ComplexExpressionWithOperation *)peakToNoiseExpression(param_1,param_2,param_3);
  if (param_4 != 1.0) {
    pNVar8 = *(NoiseExpressionStorage **)(_global + 0xb0);
    pNVar2 = (NoiseExpression *)NoiseExpressionStorage::getOrCreate(pNVar8,param_4);
    NoiseExpressions::
    BinaryExpression<NoiseOperations::BinaryOperation<(NoiseOperationType)4,&NoiseOperations::Functions::multiply,2ull>,true,&NoiseExpressions::Folding::multiply>
    ::computeHash((NoiseExpression *)pCVar1,pNVar2);
    local_78 = &local_70;
    auVar9 = std::
             __tree<std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>,std::__map_value_compare<SHA1Digest,std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>,std::less<SHA1Digest>,true>,std::allocator<std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>>>
             ::
             __emplace_unique_key_args<SHA1Digest,std::piecewise_construct_t_const&,std::tuple<SHA1Digest_const&>,std::tuple<>>
                       ((SHA1Digest *)(pNVar8 + 0x20),(piecewise_construct_t *)&local_70,
                        (tuple *)&std::piecewise_construct,(tuple *)&local_78);
    lVar3 = auVar9._0_8_;
    if ((auVar9._8_8_ & 0xff) != 0) {
      plVar4 = operator_new(0x30);
      *plVar4 = (long)(PTR_vtable_102d561f0 + 0x10);
      plVar4[4] = (long)pCVar1;
      plVar4[5] = (long)pNVar2;
      plVar5 = *(long **)(lVar3 + 0x38);
      *(undefined8 *)(lVar3 + 0x38) = 0;
      if (plVar5 != (long *)0x0) {
        (**(code **)(*plVar5 + 8))();
      }
      *(long **)(lVar3 + 0x38) = plVar4;
      plVar4[2] = (long)puStack_68;
      plVar4[1] = (long)local_70;
      *(undefined4 *)(plVar4 + 3) = local_60._0_4_;
    }
    pCVar1 = *(ComplexExpressionWithOperation **)(lVar3 + 0x38);
  }
  if (param_5 < INFINITY) {
    uVar6 = NoiseExpressionStorage::getOrCreate
                      (*(NoiseExpressionStorage **)(_global + 0xb0),param_5);
    pNVar8 = *(NoiseExpressionStorage **)(_global + 0xb0);
    uVar7 = NoiseExpressionStorage::getOrCreate(pNVar8,-INFINITY);
    local_70 = operator_new(0x18);
    puStack_68 = local_70 + 3;
    *local_70 = pCVar1;
    local_70[1] = uVar7;
    local_70[2] = uVar6;
    local_60 = puStack_68;
    pCVar1 = NoiseExpressionStorage::
             getOrCreate<NoiseExpressions::ComplexExpressionWithOperation<NoiseOperations::Clamp,(unsigned_char)3,(unsigned_char)0>,std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>>
                       (pNVar8,(vector *)&local_70);
    if (local_70 != (undefined8 *)0x0) {
      puStack_68 = local_70;
      operator_delete(local_70);
    }
  }
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_58) {
    return (NoiseExpression *)pCVar1;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}



// ===== NoiseExpressions::ExpressionInRange::dimensionsToNoiseExpression @ 0x1015f49b0 =====

/* NoiseExpressions::ExpressionInRange::dimensionsToNoiseExpression(NoiseExpression const&,
   NoiseExpression const&, double, double, double, double) */

ComplexExpressionWithOperation *
NoiseExpressions::ExpressionInRange::dimensionsToNoiseExpression
          (NoiseExpression *param_1,NoiseExpression *param_2,double param_3,double param_4,
          double param_5,double param_6)

{
  undefined8 uVar1;
  undefined8 uVar2;
  ComplexExpressionWithOperation *pCVar3;
  NoiseExpressionStorage *this;
  undefined8 *local_48;
  undefined8 *local_40;
  undefined8 *puStack_38;
  
  uVar1 = clampedPeakToNoiseExpression
                    (param_2,(param_3 + param_4) * 0.5,(param_4 - param_3) * 0.5,param_5,param_6);
  this = *(NoiseExpressionStorage **)(_global + 0xb0);
  uVar2 = NoiseExpressionStorage::getOrCreate(this,-INFINITY);
  local_48 = operator_new(0x18);
  local_40 = local_48 + 3;
  *local_48 = param_1;
  local_48[1] = uVar2;
  local_48[2] = uVar1;
  puStack_38 = local_40;
  pCVar3 = NoiseExpressionStorage::
           getOrCreate<NoiseExpressions::ComplexExpressionWithOperation<NoiseOperations::Clamp,(unsigned_char)3,(unsigned_char)0>,std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>>
                     (this,(vector *)&local_48);
  if (local_48 != (undefined8 *)0x0) {
    local_40 = local_48;
    operator_delete(local_48);
  }
  return pCVar3;
}



// ===== __GLOBAL__sub_I_Unity1.cpp @ 0x10249508c =====
// (failed)


// ===== NativeNoiseFunctions::NamedFunction::createDistance<(NoiseExpressions::DistanceFromNearestPointType)0>(std::vector<NoiseFunctionParameter,std::allocator<NoiseFunctionParameter>>&&)::{lambda(std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&)#1}::allocator<NoiseExpression_const*>_>_const&) @ 0x102260278 =====

/* NativeNoiseFunctions::NamedFunction::createDistance<(NoiseExpressions::DistanceFromNearestPointType)0>(std::vector<NoiseFunctionParameter,
   std::allocator<NoiseFunctionParameter> >&&)::{lambda(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&)#1}::__invoke(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&) */

void NativeNoiseFunctions::NamedFunction::
     createDistance<(NoiseExpressions::DistanceFromNearestPointType)0>(std::vector<NoiseFunctionParameter,std::allocator<NoiseFunctionParameter>>&&)
     ::{lambda(std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&)#1}
     ::allocator<NoiseExpression_const*>_>_const__(vector *param_1)

{
  DistanceFromNearestPoint *pDVar1;
  undefined8 *puVar2;
  long *plVar3;
  long lVar4;
  undefined1 auVar5 [16];
  undefined8 *local_58;
  undefined8 local_50;
  undefined8 uStack_48;
  undefined4 local_40;
  long local_38;
  
  local_38 = *(long *)PTR____stack_chk_guard_102d481b8;
  pDVar1 = NoiseExpressionStorage::
           getOrCreate<NoiseExpressions::DistanceFromNearestPoint,std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&>
                     (*(NoiseExpressionStorage **)(_global + 0xb0),param_1);
  lVar4 = *(long *)(_global + 0xb0);
  NoiseExpressions::DistanceFromNearestPointWrapper::computeHash(&local_50,pDVar1,0);
  local_58 = &local_50;
  auVar5 = std::
           __tree<std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>,std::__map_value_compare<SHA1Digest,std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>,std::less<SHA1Digest>,true>,std::allocator<std::__value_type<SHA1Digest,UniquePointer<NoiseExpression,SimpleDeleter<NoiseExpression>,true>>>>
           ::
           __emplace_unique_key_args<SHA1Digest,std::piecewise_construct_t_const&,std::tuple<SHA1Digest_const&>,std::tuple<>>
                     ((SHA1Digest *)(lVar4 + 0x20),(piecewise_construct_t *)&local_50,
                      (tuple *)&std::piecewise_construct,(tuple *)&local_58);
  lVar4 = auVar5._0_8_;
  if ((auVar5._8_8_ & 0xff) != 0) {
    puVar2 = operator_new(0x30);
    *puVar2 = &PTR__DistanceFromNearestPointWrapper_102f849c0;
    puVar2[4] = pDVar1;
    *(undefined1 *)(puVar2 + 5) = 0;
    plVar3 = *(long **)(lVar4 + 0x38);
    *(undefined8 *)(lVar4 + 0x38) = 0;
    if (plVar3 != (long *)0x0) {
      (**(code **)(*plVar3 + 8))();
    }
    *(undefined8 **)(lVar4 + 0x38) = puVar2;
    puVar2[2] = uStack_48;
    puVar2[1] = local_50;
    *(undefined4 *)(puVar2 + 3) = local_40;
  }
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_38) {
    return;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail(*(undefined8 *)(lVar4 + 0x38));
}



// ===== NativeNoiseFunctions::NamedFunction::createDistance<(NoiseExpressions::DistanceFromNearestPointType)1>(std::vector<NoiseFunctionParameter,std::allocator<NoiseFunctionParameter>>&&)::{lambda(std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&)#1}::allocator<NoiseExpression_const*>_>_const&) @ 0x102260580 =====

/* NativeNoiseFunctions::NamedFunction::createDistance<(NoiseExpressions::DistanceFromNearestPointType)1>(std::vector<NoiseFunctionParameter,
   std::allocator<NoiseFunctionParameter> >&&)::{lambda(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&)#1}::__invoke(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&) */

void NativeNoiseFunctions::NamedFunction::
     createDistance<(NoiseExpressions::DistanceFromNearestPointType)1>(std::vector<NoiseFunctionParameter,std::allocator<NoiseFunctionParameter>>&&)
     ::{lambda(std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&)#1}
     ::allocator<NoiseExpression_const*>_>_const__(vector *param_1)

{
  _lambda_std__vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const___1_
  a_Stack_18 [8];
  
  operator()(a_Stack_18,param_1);
  return;
}



// ===== NativeNoiseFunctions::NamedFunction::createDistance<(NoiseExpressions::DistanceFromNearestPointType)2>(std::vector<NoiseFunctionParameter,std::allocator<NoiseFunctionParameter>>&&)::{lambda(std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&)#1}::allocator<NoiseExpression_const*>_>_const&) @ 0x1022607a8 =====

/* NativeNoiseFunctions::NamedFunction::createDistance<(NoiseExpressions::DistanceFromNearestPointType)2>(std::vector<NoiseFunctionParameter,
   std::allocator<NoiseFunctionParameter> >&&)::{lambda(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&)#1}::__invoke(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&) */

void NativeNoiseFunctions::NamedFunction::
     createDistance<(NoiseExpressions::DistanceFromNearestPointType)2>(std::vector<NoiseFunctionParameter,std::allocator<NoiseFunctionParameter>>&&)
     ::{lambda(std::vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const&)#1}
     ::allocator<NoiseExpression_const*>_>_const__(vector *param_1)

{
  _lambda_std__vector<NoiseExpression_const*,std::allocator<NoiseExpression_const*>>const___1_
  a_Stack_18 [8];
  
  operator()(a_Stack_18,param_1);
  return;
}



// ===== NoiseExpressions::DistanceFromNearestPoint::compile @ 0x1015f1ec4 =====

/* NoiseExpressions::DistanceFromNearestPoint::compile(NoiseProgramBuilder&) const */

void NoiseExpressions::DistanceFromNearestPoint::compile(NoiseProgramBuilder *param_1)

{
  int iVar1;
  int iVar2;
  undefined8 *puVar3;
  int iVar4;
  CompiledNoiseExpression *pCVar5;
  CompiledNoiseExpression *pCVar6;
  DistanceFromNearestPoint *pDVar7;
  RuntimeError *pRVar8;
  NoiseProgramBuilder *in_x1;
  undefined1 *in_x8;
  char local_e0 [8];
  void *local_d8;
  void *local_d0;
  char local_c1;
  char local_c0;
  void *local_b8;
  void *local_b0;
  char local_a1;
  undefined4 local_a0;
  undefined4 local_9c;
  char local_98;
  void *local_90;
  void *local_88;
  char local_79;
  char local_78;
  void *local_70;
  void *local_68;
  char local_59;
  undefined1 local_58;
  undefined1 *local_50;
  DistanceFromNearestPoint *local_48;
  
  local_98 = '\0';
  local_78 = '\0';
  local_58 = 0;
  pCVar5 = (CompiledNoiseExpression *)
           NoiseProgramBuilder::compileExpression(in_x1,*(NoiseExpression **)(param_1 + 0x20));
  if (*pCVar5 == (CompiledNoiseExpression)0x0) {
    local_58 = 0;
  }
  pCVar6 = (CompiledNoiseExpression *)
           NoiseProgramBuilder::compileExpression(in_x1,*(NoiseExpression **)(param_1 + 0x28));
  if (*pCVar6 == (CompiledNoiseExpression)0x0) {
    local_58 = 0;
  }
  local_a0 = NoiseProgramBuilder::requestRegister(in_x1,pCVar5);
  local_9c = NoiseProgramBuilder::requestRegister(in_x1,pCVar6);
  NoiseExpressions::
  ComplexExpression<NoiseOperations::DistanceFromNearestPoint,(unsigned_char)2,(unsigned_char)2,(unsigned_char)0>
  ::compileConstantArguments(param_1);
  iVar4 = *(int *)(in_x1 + 0xd8);
  if (iVar4 == -1) {
    pRVar8 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(pRVar8,"Too many registers");
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(pRVar8,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  iVar1 = iVar4 + 1;
  *(int *)(in_x1 + 0xd8) = iVar1;
  if (iVar1 == -1) {
    pRVar8 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(pRVar8,"Too many registers");
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(pRVar8,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  iVar2 = iVar4 + 2;
  *(int *)(in_x1 + 0xd8) = iVar2;
  if (iVar2 == -1) {
    pRVar8 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(pRVar8,"Too many registers");
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(pRVar8,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  *(int *)(in_x1 + 0xd8) = iVar4 + 3;
  pDVar7 = operator_new(0x40);
  local_50 = local_e0;
  NoiseOperations::DistanceFromNearestPoint::DistanceFromNearestPoint
            (pDVar7,iVar4,iVar1,iVar2,&local_a0,&local_50);
  puVar3 = *(undefined8 **)(in_x1 + 0x38);
  local_48 = pDVar7;
  if (puVar3 < *(undefined8 **)(in_x1 + 0x40)) {
    *puVar3 = pDVar7;
    *(undefined8 **)(in_x1 + 0x38) = puVar3 + 1;
  }
  else {
    std::
    vector<UniquePointer<NoiseOperation,SimpleDeleter<NoiseOperation>,true>,std::allocator<UniquePointer<NoiseOperation,SimpleDeleter<NoiseOperation>,true>>>
    ::__emplace_back_slow_path<NoiseOperations::DistanceFromNearestPoint*>
              ((vector<UniquePointer<NoiseOperation,SimpleDeleter<NoiseOperation>,true>,std::allocator<UniquePointer<NoiseOperation,SimpleDeleter<NoiseOperation>,true>>>
                *)(in_x1 + 0x30),&local_48);
  }
  *in_x8 = 0;
  *(undefined8 *)(in_x8 + 0x20) = 0xffffffffffffffff;
  if (local_c0 != '\0') {
    if (local_c0 == '\x04') {
      if (local_b8 != (void *)0x0) {
        local_b0 = local_b8;
        goto LAB_1015f2024;
      }
    }
    else if ((local_c0 == '\x03') && (local_a1 < '\0')) {
LAB_1015f2024:
      operator_delete(local_b8);
    }
    local_c0 = '\0';
  }
  if (local_e0[0] == '\x03') {
    if (local_c1 < '\0') goto LAB_1015f205c;
  }
  else if ((local_e0[0] == '\x04') && (local_d8 != (void *)0x0)) {
    local_d0 = local_d8;
LAB_1015f205c:
    operator_delete(local_d8);
  }
  if (local_78 == '\0') goto LAB_1015f209c;
  if (local_78 == '\x04') {
    if (local_70 != (void *)0x0) {
      local_68 = local_70;
      goto LAB_1015f2094;
    }
  }
  else if ((local_78 == '\x03') && (local_59 < '\0')) {
LAB_1015f2094:
    operator_delete(local_70);
  }
  local_78 = '\0';
LAB_1015f209c:
  if (local_98 == '\x03') {
    if (-1 < local_79) {
      return;
    }
  }
  else {
    if ((local_98 != '\x04') || (local_90 == (void *)0x0)) {
      return;
    }
    local_88 = local_90;
  }
  operator_delete(local_90);
  return;
}



// ===== NoiseExpressions::SpotNoise::compile @ 0x1015f34d8 =====

/* WARNING: Removing unreachable block (ram,0x0001015f3998) */
/* WARNING: Removing unreachable block (ram,0x0001015f39e0) */
/* NoiseExpressions::SpotNoise::compile(NoiseProgramBuilder&) const */

void NoiseExpressions::SpotNoise::compile(NoiseProgramBuilder *param_1)

{
  undefined8 *puVar1;
  int iVar2;
  ulong *puVar3;
  code *pcVar4;
  CompiledNoiseExpression *pCVar5;
  CompiledNoiseExpression *pCVar6;
  ulong *puVar7;
  void *pvVar8;
  SpotNoise *pSVar9;
  long *plVar10;
  RuntimeError *this;
  NoiseProgramBuilder *in_x1;
  undefined1 *in_x8;
  ulong uVar11;
  ulong uVar12;
  ulong uVar13;
  long *plVar14;
  long lVar15;
  undefined1 auStack_328 [8];
  long *local_320;
  long *local_318;
  undefined8 local_308;
  ulong *local_300;
  ulong *local_2f8;
  ulong *local_2f0;
  undefined4 local_2e8;
  undefined4 local_2e0;
  undefined8 local_2d8;
  undefined8 uStack_2d0;
  undefined8 local_2c8;
  undefined8 uStack_2c0;
  undefined8 local_2b8;
  undefined8 uStack_2b0;
  undefined8 local_2a8;
  undefined4 local_2a0;
  undefined8 local_298;
  undefined8 uStack_290;
  undefined8 local_288;
  undefined8 uStack_280;
  undefined4 local_278;
  undefined8 local_270;
  undefined8 uStack_268;
  undefined8 local_260;
  undefined8 uStack_258;
  undefined4 local_250;
  undefined8 local_248;
  undefined8 local_240;
  undefined8 uStack_238;
  undefined4 local_230;
  undefined1 auStack_228 [8];
  undefined1 auStack_220 [4];
  undefined1 auStack_21c [4];
  array<NoiseExpressionConstant,11ul> aaStack_218 [352];
  undefined4 local_b8;
  undefined4 local_b4;
  char local_b0;
  void *local_a8;
  void *local_a0;
  char local_90;
  void *local_88;
  void *local_80;
  undefined1 local_70;
  SpotNoise *local_68;
  
  local_b0 = '\0';
  local_90 = '\0';
  local_70 = 0;
  pCVar5 = (CompiledNoiseExpression *)
           NoiseProgramBuilder::compileExpression(in_x1,*(NoiseExpression **)(param_1 + 0x20));
  if (*pCVar5 == (CompiledNoiseExpression)0x0) {
    local_70 = 0;
  }
  pCVar6 = (CompiledNoiseExpression *)
           NoiseProgramBuilder::compileExpression(in_x1,*(NoiseExpression **)(param_1 + 0x28));
  if (*pCVar6 == (CompiledNoiseExpression)0x0) {
    local_70 = 0;
  }
  local_b8 = NoiseProgramBuilder::requestRegister(in_x1,pCVar5);
  local_b4 = NoiseProgramBuilder::requestRegister(in_x1,pCVar6);
  NoiseExpressions::
  ComplexExpression<NoiseOperations::SpotNoise,(unsigned_char)2,(unsigned_char)11,(unsigned_char)4>
  ::compileConstantArguments(param_1);
  local_308 = *(undefined8 *)in_x1;
  local_300 = (ulong *)0x0;
  local_2f8 = (ulong *)0x0;
  local_2f0 = (ulong *)0x0;
  local_2e0 = 0;
  local_2e8 = 0;
  uStack_2d0 = 0;
  local_2d8 = 0;
  uStack_2c0 = 0;
  local_2c8 = 0;
  uStack_2b0 = 0;
  local_2b8 = 0;
  local_2a8 = 0;
  local_2a0 = 0x3f800000;
  uStack_290 = 0;
  local_298 = 0;
  uStack_280 = 0;
  local_288 = 0;
  uStack_268 = 0;
  local_270 = 0;
  uStack_258 = 0;
  local_260 = 0;
  local_278 = 0x3f800000;
  local_250 = 0x3f800000;
  local_240 = 0;
  uStack_238 = 0;
  local_248 = 0;
  local_230 = 0x80000001;
  puVar7 = operator_new(0x40);
  local_2f0 = puVar7 + 8;
  local_300 = puVar7;
  if (puVar7 < local_2f0) {
    uVar11 = *(ulong *)(param_1 + 0x30);
    *puVar7 = (ulong)auStack_228;
    puVar7[1] = uVar11;
    local_2f8 = puVar7 + 2;
    uVar11 = (ulong)auStack_228 | 4;
    if (local_2f8 < local_2f0) goto LAB_1015f3618;
LAB_1015f3670:
    puVar7 = local_2f8;
    puVar3 = local_300;
    lVar15 = (long)local_2f8 - (long)local_300 >> 4;
    uVar13 = lVar15 + 1;
    if (uVar13 >> 0x3c != 0) goto LAB_1015f3a08;
    uVar12 = (ulong)((long)local_2f0 - (long)local_300) >> 3;
    if (uVar12 <= uVar13) {
      uVar12 = uVar13;
    }
    if (0x7fffffffffffffef < (ulong)((long)local_2f0 - (long)local_300)) {
      uVar12 = 0xfffffffffffffff;
    }
    if (uVar12 >> 0x3c != 0) goto LAB_1015f3a18;
    pvVar8 = operator_new(uVar12 << 4);
    local_300 = (ulong *)((long)pvVar8 + lVar15 * 0x10);
    uVar13 = *(ulong *)(param_1 + 0x38);
    local_2f0 = (ulong *)((long)pvVar8 + uVar12 * 0x10);
    *local_300 = uVar11;
    local_300[1] = uVar13;
    local_2f8 = local_300 + 2;
    for (; puVar7 != puVar3; puVar7 = puVar7 + -2) {
      uVar11 = puVar7[-2];
      local_300[-1] = puVar7[-1];
      local_300[-2] = uVar11;
      local_300 = local_300 + -2;
    }
    if (puVar3 != (ulong *)0x0) {
      operator_delete(puVar3);
    }
  }
  else {
    local_2f8 = puVar7;
    local_300 = operator_new(0x80);
    uVar11 = *(ulong *)(param_1 + 0x30);
    *local_300 = (ulong)auStack_228;
    local_300[1] = uVar11;
    local_2f8 = local_300 + 2;
    local_2f0 = local_300 + 0x10;
    operator_delete(puVar7);
    uVar11 = (ulong)auStack_228 | 4;
    if (local_2f0 <= local_2f8) goto LAB_1015f3670;
LAB_1015f3618:
    *local_2f8 = uVar11;
    local_2f8[1] = *(ulong *)(param_1 + 0x38);
    local_2f8 = local_2f8 + 2;
  }
  puVar7 = local_2f8;
  puVar3 = local_300;
  if (local_2f8 < local_2f0) {
    *local_2f8 = (ulong)auStack_220;
    local_2f8[1] = *(ulong *)(param_1 + 0x40);
    local_2f8 = local_2f8 + 2;
  }
  else {
    lVar15 = (long)local_2f8 - (long)local_300 >> 4;
    uVar11 = lVar15 + 1;
    if (uVar11 >> 0x3c != 0) goto LAB_1015f3a08;
    uVar13 = (ulong)((long)local_2f0 - (long)local_300) >> 3;
    if (uVar13 <= uVar11) {
      uVar13 = uVar11;
    }
    if (0x7fffffffffffffef < (ulong)((long)local_2f0 - (long)local_300)) {
      uVar13 = 0xfffffffffffffff;
    }
    if (uVar13 >> 0x3c != 0) goto LAB_1015f3a18;
    pvVar8 = operator_new(uVar13 << 4);
    local_300 = (ulong *)((long)pvVar8 + lVar15 * 0x10);
    uVar11 = *(ulong *)(param_1 + 0x40);
    local_2f0 = (ulong *)((long)pvVar8 + uVar13 * 0x10);
    *local_300 = (ulong)auStack_220;
    local_300[1] = uVar11;
    local_2f8 = local_300 + 2;
    for (; puVar7 != puVar3; puVar7 = puVar7 + -2) {
      uVar11 = puVar7[-2];
      local_300[-1] = puVar7[-1];
      local_300[-2] = uVar11;
      local_300 = local_300 + -2;
    }
    if (puVar3 != (ulong *)0x0) {
      operator_delete(puVar3);
    }
  }
  puVar7 = local_2f8;
  puVar3 = local_300;
  if (local_2f8 < local_2f0) {
    *local_2f8 = (ulong)auStack_21c;
    local_2f8[1] = *(ulong *)(param_1 + 0x48);
    local_2f8 = local_2f8 + 2;
  }
  else {
    lVar15 = (long)local_2f8 - (long)local_300 >> 4;
    uVar11 = lVar15 + 1;
    if (uVar11 >> 0x3c != 0) {
LAB_1015f3a08:
      std::
      vector<std::pair<NoiseRegisterIndex*,NoiseExpression_const*>,std::allocator<std::pair<NoiseRegisterIndex*,NoiseExpression_const*>>>
      ::__throw_length_error_abi_v160006_();
                    /* WARNING: Does not return */
      pcVar4 = (code *)SoftwareBreakpoint(1,0x1015f3a54);
      (*pcVar4)();
    }
    uVar13 = (ulong)((long)local_2f0 - (long)local_300) >> 3;
    if (uVar13 <= uVar11) {
      uVar13 = uVar11;
    }
    if (0x7fffffffffffffef < (ulong)((long)local_2f0 - (long)local_300)) {
      uVar13 = 0xfffffffffffffff;
    }
    if (uVar13 >> 0x3c != 0) {
LAB_1015f3a18:
                    /* WARNING: Subroutine does not return */
      std::__throw_bad_array_new_length_abi_v160006_();
    }
    pvVar8 = operator_new(uVar13 << 4);
    local_300 = (ulong *)((long)pvVar8 + lVar15 * 0x10);
    uVar11 = *(ulong *)(param_1 + 0x48);
    local_2f0 = (ulong *)((long)pvVar8 + uVar13 * 0x10);
    *local_300 = (ulong)auStack_21c;
    local_300[1] = uVar11;
    local_2f8 = local_300 + 2;
    for (; puVar7 != puVar3; puVar7 = puVar7 + -2) {
      uVar11 = puVar7[-2];
      local_300[-1] = puVar7[-1];
      local_300[-2] = uVar11;
      local_300 = local_300 + -2;
    }
    if (puVar3 != (ulong *)0x0) {
      operator_delete(puVar3);
    }
  }
  iVar2 = *(int *)(in_x1 + 0xd8);
  if (iVar2 == -1) {
    this = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(this,"Too many registers");
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(this,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  *(int *)(in_x1 + 0xd8) = iVar2 + 1;
  NoiseProgramBuilder::build();
  lVar15 = *(long *)in_x1;
  pSVar9 = operator_new(0x88);
  NoiseOperations::SpotNoise::SpotNoise
            (pSVar9,iVar2,&local_b8,aaStack_218,auStack_228,auStack_328,
             *(undefined8 *)(lVar15 + 0x68));
  puVar1 = *(undefined8 **)(in_x1 + 0x38);
  local_68 = pSVar9;
  if (puVar1 < *(undefined8 **)(in_x1 + 0x40)) {
    *puVar1 = pSVar9;
    *(undefined8 **)(in_x1 + 0x38) = puVar1 + 1;
  }
  else {
    std::
    vector<UniquePointer<NoiseOperation,SimpleDeleter<NoiseOperation>,true>,std::allocator<UniquePointer<NoiseOperation,SimpleDeleter<NoiseOperation>,true>>>
    ::__emplace_back_slow_path<NoiseOperations::SpotNoise*>
              ((vector<UniquePointer<NoiseOperation,SimpleDeleter<NoiseOperation>,true>,std::allocator<UniquePointer<NoiseOperation,SimpleDeleter<NoiseOperation>,true>>>
                *)(in_x1 + 0x30),&local_68);
  }
  plVar14 = local_318;
  if (local_320 != (long *)0x0) {
    while (plVar14 != local_320) {
      plVar14 = plVar14 + -1;
      plVar10 = (long *)*plVar14;
      *plVar14 = 0;
      if (plVar10 != (long *)0x0) {
        (**(code **)(*plVar10 + 8))();
      }
    }
    operator_delete(local_320);
  }
  *in_x8 = 0;
  *(int *)(in_x8 + 0x20) = iVar2;
  *(undefined4 *)(in_x8 + 0x24) = 0xffffffff;
  NoiseProgramBuilder::~NoiseProgramBuilder((NoiseProgramBuilder *)&local_308);
  std::array<NoiseExpressionConstant,11ul>::~array(aaStack_218);
  if (local_90 != '\0') {
    if ((local_90 == '\x04') && (local_88 != (void *)0x0)) {
      local_80 = local_88;
      operator_delete(local_88);
    }
    local_90 = '\0';
  }
  if (((local_b0 != '\x03') && (local_b0 == '\x04')) && (local_a8 != (void *)0x0)) {
    local_a0 = local_a8;
    operator_delete(local_a8);
  }
  return;
}



