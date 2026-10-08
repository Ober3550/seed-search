// ===== caller: NoiseExpressions::expressionInRange @ 1015de034 calls 1015f49b0 =====

/* NoiseExpressions::expressionInRange(std::vector<NoiseExpression const*,
   std::allocator<NoiseExpression const*> > const&) */

NoiseExpression * NoiseExpressions::expressionInRange(vector *param_1)

{
  uint uVar1;
  void *pvVar2;
  void *pvVar3;
  void *pvVar4;
  NoiseExpression *pNVar5;
  undefined8 uVar6;
  NoiseExpression *pNVar7;
  uint uVar8;
  char local_b0 [8];
  void *local_a8;
  void *local_a0;
  char local_91;
  char local_90 [8];
  void *local_88;
  void *local_80;
  char local_71;
  
  (**(code **)(*(long *)**(undefined8 **)param_1 + 0x18))(local_90);
  pvVar2 = local_88;
  if (local_90[0] != '\x01') {
    uVar6 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(local_90,"arg0");
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(uVar6,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  (**(code **)(**(long **)(*(long *)param_1 + 8) + 0x18))(local_90);
  pvVar3 = local_88;
  if (local_90[0] != '\x01') {
    uVar6 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(local_90,"arg1");
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(uVar6,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  uVar1 = (uint)(*(int *)(param_1 + 8) - *(int *)param_1) >> 3 & 0xff;
  pNVar5 = (NoiseExpression *)
           NoiseExpressionStorage::getOrCreate
                     (*(NoiseExpressionStorage **)(_global + 0xb0),INFINITY);
  if (4 < uVar1) {
    uVar8 = 0;
    uVar1 = uVar1 * 0x5556 - 0xaaac;
    uVar1 = (uVar1 >> 0x10) - ((int)uVar1 >> 0x1f) & 0xffff;
    do {
      pNVar7 = *(NoiseExpression **)(*(long *)param_1 + (ulong)(uVar8 + 2) * 8);
      (**(code **)(**(long **)(*(long *)param_1 + (ulong)(uVar8 + uVar1 + 2) * 8) + 0x18))(local_90)
      ;
      pvVar4 = local_88;
      if (local_90[0] != '\x01') {
        uVar6 = ___cxa_allocate_exception(0x10);
        NoiseExpressionConstant::getInvalidParameterError(local_90,"range_from");
                    /* WARNING: Subroutine does not return */
        ___cxa_throw(uVar6,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
      }
      (**(code **)(**(long **)(*(long *)param_1 + (ulong)(uVar8 + uVar1 + 2 + uVar1) * 8) + 0x18))
                (local_b0);
      if (local_b0[0] != '\x01') {
        uVar6 = ___cxa_allocate_exception(0x10);
        NoiseExpressionConstant::getInvalidParameterError(local_b0,"range_to");
                    /* WARNING: Subroutine does not return */
        ___cxa_throw(uVar6,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
      }
      pNVar5 = (NoiseExpression *)
               ExpressionInRange::dimensionsToNoiseExpression
                         (pNVar5,pNVar7,(double)pvVar4,(double)local_a8,(double)pvVar2,
                          (double)pvVar3);
      if (local_b0[0] == '\x04') {
        if (local_a8 != (void *)0x0) {
          local_a0 = local_a8;
          goto LAB_1015de1fc;
        }
      }
      else if ((local_b0[0] == '\x03') && (local_91 < '\0')) {
LAB_1015de1fc:
        operator_delete(local_a8);
      }
      if (local_90[0] == '\x04') {
        if (local_88 != (void *)0x0) {
          local_80 = local_88;
          goto LAB_1015de13c;
        }
      }
      else if ((local_90[0] == '\x03') && (local_71 < '\0')) {
LAB_1015de13c:
        operator_delete(local_88);
      }
      uVar8 = uVar8 + 1 & 0xff;
    } while (uVar8 < uVar1);
  }
  return pNVar5;
}


// ===== caller: NoiseExpressions::ExpressionInRange::dimensionsToNoiseExpression @ 1015f49b0 calls 1015f4738 =====

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


