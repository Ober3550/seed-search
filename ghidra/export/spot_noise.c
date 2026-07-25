// ===== generateSpotList  @ 0x1015e66ec =====

/* ThreadSafeSpotNoiseCache::SpotListGenerator::generateSpotList() */

void __thiscall
ThreadSafeSpotNoiseCache::SpotListGenerator::generateSpotList(SpotListGenerator *this)

{
  NoiseCache *pNVar1;
  undefined8 *puVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  int iVar6;
  long lVar7;
  long lVar8;
  long lVar9;
  uint uVar10;
  ulong uVar11;
  undefined8 *puVar12;
  long lVar13;
  
  generatePoints(this);
  lVar13 = *(long *)(this + 0x68);
  uVar3 = *(uint *)(*(long *)this + 0x5c);
  pNVar1 = (NoiseCache *)(this + 0x18);
  lVar7 = NoiseCache::getFloatRegister(pNVar1,0);
  lVar8 = NoiseCache::getFloatRegister(pNVar1,1);
  uVar10 = 0;
  lVar9 = *(long *)this;
  uVar4 = *(uint *)(lVar9 + 100);
  uVar5 = *(uint *)(lVar9 + 0x5c);
  if (uVar4 < uVar5) {
    uVar11 = 0;
    iVar6 = *(int *)(lVar9 + 0x68);
    do {
      *(undefined4 *)(lVar7 + uVar11 * 4) = *(undefined4 *)(lVar13 + (ulong)uVar4 * 4);
      *(undefined4 *)(lVar8 + uVar11 * 4) =
           *(undefined4 *)(lVar13 + (ulong)uVar3 * 4 + (ulong)uVar4 * 4);
      uVar10 = (int)uVar11 + 1;
      uVar11 = (ulong)uVar10;
      uVar4 = uVar4 + iVar6;
    } while (uVar4 < uVar5);
  }
  if (*(uint *)(this + 8) != uVar10) {
                    /* WARNING: Subroutine does not return */
    ReleaseAssertFailed("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Noise/SpotNoiseCache.cpp"
                        ,0x96,"this->candidateSpotCount == candidateSpotCount");
  }
  puVar2 = *(undefined8 **)(lVar9 + 0x28);
  for (puVar12 = *(undefined8 **)(lVar9 + 0x20); puVar12 != puVar2; puVar12 = puVar12 + 1) {
    (**(code **)(*(long *)*puVar12 + 0x18))((long *)*puVar12,pNVar1);
  }
  sortSpotCandidates(this);
  placeSpots();
  return;
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



// ===== sortSpotCandidates  @ 0x1015e6aec =====

/* ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates() */

void __thiscall
ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates(SpotListGenerator *this)

{
  bool bVar1;
  void *pvVar2;
  ulong uVar3;
  long lVar4;
  ulong uVar5;
  undefined8 local_48;
  
  lVar4 = *(long *)(this + 0x68);
  if (*(int *)(this + 8) != 0) {
    uVar3 = 0;
    do {
      *(int *)(lVar4 + uVar3 * 4) = (int)uVar3;
      uVar3 = uVar3 + 1;
    } while (uVar3 < *(uint *)(this + 8));
  }
  local_48 = NoiseCache::getFloatRegister
                       ((NoiseCache *)(this + 0x18),*(undefined4 *)(*(long *)this + 0x44));
  uVar5 = (ulong)*(uint *)(this + 8);
  uVar3 = uVar5;
  if (0x80 < *(uint *)(this + 8)) {
    do {
      pvVar2 = operator_new(uVar3 << 2,(nothrow_t *)&std::nothrow);
      if (pvVar2 != (void *)0x0) goto LAB_1015e6b8c;
      bVar1 = 1 < uVar3;
      uVar3 = uVar3 >> 1;
    } while (bVar1);
  }
  pvVar2 = (void *)0x0;
  uVar3 = 0;
LAB_1015e6b8c:
  std::
  __stable_sort<std::_ClassicAlgPolicy,ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates()::__0&,unsigned_int*>
            (lVar4,lVar4 + uVar5 * 4,&local_48,uVar5,pvVar2,uVar3);
  if (pvVar2 != (void *)0x0) {
    operator_delete(pvVar2);
  }
  return;
}



// ===== __stable_sort<std::_ClassicAlgPolicy,ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates()::$_0&,unsigned_int*>  @ 0x102267288 =====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* void std::__stable_sort<std::_ClassicAlgPolicy,
   ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates()::$_0&, unsigned int*>(unsigned
   int*, unsigned int*, ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates()::$_0&,
   std::iterator_traits<unsigned int*>::difference_type, std::iterator_traits<unsigned
   int*>::value_type*, long) */

void std::
     __stable_sort<std::_ClassicAlgPolicy,ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates()::__0&,unsigned_int*>
               (uint *param_1,uint *param_2,long *param_3,ulong param_4,uint *param_5,long param_6)

{
  uint *puVar1;
  undefined8 *puVar2;
  undefined8 *puVar3;
  uint uVar4;
  uint *puVar5;
  uint *puVar6;
  long lVar7;
  uint *puVar8;
  uint *puVar9;
  long lVar10;
  uint *puVar11;
  long lVar12;
  ulong uVar13;
  ulong uVar14;
  ulong uVar15;
  float fVar16;
  undefined8 uVar17;
  float fVar18;
  undefined8 uVar19;
  undefined8 uVar20;
  undefined8 uVar21;
  undefined8 uVar22;
  undefined8 uVar23;
  undefined8 uVar24;
  
  if (1 < param_4) {
    if (param_4 == 2) {
      uVar4 = *param_1;
      if (*(float *)(*param_3 + (ulong)uVar4 * 4) < *(float *)(*param_3 + (ulong)param_2[-1] * 4)) {
        *param_1 = param_2[-1];
        param_2[-1] = uVar4;
      }
    }
    else if ((long)param_4 < 0x81) {
      if ((param_1 != param_2) && (puVar5 = param_1 + 1, puVar5 != param_2)) {
        lVar7 = 0;
        lVar10 = *param_3;
        do {
          uVar4 = *puVar5;
          puVar8 = param_1;
          if (puVar5 != param_1) {
            fVar16 = *(float *)(lVar10 + (ulong)uVar4 * 4);
            lVar12 = lVar7;
            do {
              puVar1 = (uint *)((long)param_1 + lVar12);
              if (fVar16 <= *(float *)(lVar10 + (ulong)*puVar1 * 4)) {
                puVar8 = puVar1 + 1;
                break;
              }
              puVar1[1] = *puVar1;
              lVar12 = lVar12 + -4;
            } while (lVar12 != -4);
          }
          *puVar8 = uVar4;
          puVar5 = puVar5 + 1;
          lVar7 = lVar7 + 4;
        } while (puVar5 != param_2);
      }
    }
    else {
      uVar15 = param_4 >> 1;
      puVar5 = param_1 + uVar15;
      lVar7 = param_4 - uVar15;
      if (param_6 < (long)param_4) {
        __stable_sort<std::_ClassicAlgPolicy,ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates()::__0&,unsigned_int*>
                  ();
        __stable_sort<std::_ClassicAlgPolicy,ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates()::__0&,unsigned_int*>
                  (puVar5,param_2,param_3,lVar7,param_5,param_6);
        __inplace_merge<std::_ClassicAlgPolicy,ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates()::__0&,unsigned_int*>
                  (param_1,puVar5,param_2,param_3,uVar15,lVar7,param_5,param_6);
        return;
      }
      __stable_sort_move<std::_ClassicAlgPolicy,ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates()::__0&,unsigned_int*>
                (param_1,puVar5,param_3,uVar15);
      puVar8 = param_5 + uVar15;
      __stable_sort_move<std::_ClassicAlgPolicy,ThreadSafeSpotNoiseCache::SpotListGenerator::sortSpotCandidates()::__0&,unsigned_int*>
                (puVar5,param_2,param_3,lVar7,puVar8);
      puVar1 = param_5 + param_4;
      puVar5 = param_5;
      puVar11 = param_1;
      if ((uVar15 & 0x3fffffffffffffff) != 0) {
        lVar7 = *param_3;
        puVar5 = puVar8;
        puVar9 = param_5;
        puVar6 = param_1;
        do {
          if (puVar5 == puVar1) {
            if (puVar9 == puVar8) {
              return;
            }
            uVar15 = (long)param_5 + (uVar15 * 4 - (long)puVar9) + -4;
            if ((0x3b < uVar15) && (0x3f < (ulong)((long)param_1 - (long)puVar9))) {
              lVar7 = 0;
              uVar15 = (uVar15 >> 2) + 1;
              uVar13 = uVar15 & 0x7ffffffffffffff0;
              uVar14 = uVar13;
              do {
                puVar2 = (undefined8 *)((long)puVar6 + lVar7);
                puVar3 = (undefined8 *)((long)puVar9 + lVar7 + 0x20);
                uVar17 = puVar3[-4];
                uVar20 = puVar3[-1];
                uVar19 = puVar3[-2];
                uVar22 = puVar3[1];
                uVar21 = *puVar3;
                uVar24 = puVar3[3];
                uVar23 = puVar3[2];
                puVar2[1] = puVar3[-3];
                *puVar2 = uVar17;
                puVar2[3] = uVar20;
                puVar2[2] = uVar19;
                puVar2[5] = uVar22;
                puVar2[4] = uVar21;
                puVar2[7] = uVar24;
                puVar2[6] = uVar23;
                lVar7 = lVar7 + 0x40;
                uVar14 = uVar14 - 0x10;
              } while (uVar14 != 0);
              puVar6 = puVar6 + uVar13;
              puVar9 = puVar9 + uVar13;
              if (uVar15 == uVar13) {
                return;
              }
            }
            do {
              puVar5 = puVar9 + 1;
              *puVar6 = *puVar9;
              puVar6 = puVar6 + 1;
              puVar9 = puVar5;
            } while (puVar5 != puVar8);
            return;
          }
          fVar16 = *(float *)(lVar7 + (ulong)*puVar5 * 4);
          fVar18 = *(float *)(lVar7 + (ulong)*puVar9 * 4);
          uVar4 = *puVar9;
          if (fVar18 < fVar16) {
            uVar4 = *puVar5;
          }
          puVar9 = puVar9 + (fVar16 <= fVar18);
          puVar5 = puVar5 + (fVar18 < fVar16);
          puVar11 = puVar6 + 1;
          *puVar6 = uVar4;
          param_1 = param_1 + 1;
          puVar6 = puVar11;
        } while (puVar9 != puVar8);
      }
      if (puVar5 != puVar1) {
        uVar15 = (long)param_5 + (param_4 * 4 - (long)puVar5) + -4;
        if ((0x3b < uVar15) && (0x3f < (ulong)((long)puVar11 - (long)puVar5))) {
          uVar15 = (uVar15 >> 2) + 1;
          uVar13 = uVar15 & 0x7ffffffffffffff0;
          puVar8 = puVar5 + 8;
          puVar9 = puVar11 + 8;
          uVar14 = uVar13;
          do {
            uVar17 = *(undefined8 *)(puVar8 + -8);
            uVar20 = *(undefined8 *)(puVar8 + -2);
            uVar19 = *(undefined8 *)(puVar8 + -4);
            uVar22 = *(undefined8 *)(puVar8 + 2);
            uVar21 = *(undefined8 *)puVar8;
            uVar24 = *(undefined8 *)(puVar8 + 6);
            uVar23 = *(undefined8 *)(puVar8 + 4);
            *(undefined8 *)(puVar9 + -6) = *(undefined8 *)(puVar8 + -6);
            *(undefined8 *)(puVar9 + -8) = uVar17;
            *(undefined8 *)(puVar9 + -2) = uVar20;
            *(undefined8 *)(puVar9 + -4) = uVar19;
            *(undefined8 *)(puVar9 + 2) = uVar22;
            *(undefined8 *)puVar9 = uVar21;
            *(undefined8 *)(puVar9 + 6) = uVar24;
            *(undefined8 *)(puVar9 + 4) = uVar23;
            uVar14 = uVar14 - 0x10;
            puVar8 = puVar8 + 0x10;
            puVar9 = puVar9 + 0x10;
          } while (uVar14 != 0);
          puVar11 = puVar11 + uVar13;
          puVar5 = puVar5 + uVar13;
          if (uVar15 == uVar13) {
            return;
          }
        }
        do {
          puVar8 = puVar5 + 1;
          *puVar11 = *puVar5;
          puVar11 = puVar11 + 1;
          puVar5 = puVar8;
        } while (puVar8 != puVar1);
      }
    }
  }
  return;
}



// ===== placeSpots  @ 0x1015e6be4 =====

/* ThreadSafeSpotNoiseCache::SpotListGenerator::placeSpots() */

void ThreadSafeSpotNoiseCache::SpotListGenerator::placeSpots(void)

{
  undefined4 *puVar1;
  NoiseCache *pNVar2;
  uint uVar3;
  float fVar4;
  code *pcVar5;
  long *in_x0;
  long lVar6;
  long lVar7;
  long lVar8;
  long lVar9;
  long lVar10;
  void *pvVar11;
  ulong *in_x8;
  ulong uVar12;
  undefined4 *puVar13;
  ulong uVar14;
  float *pfVar15;
  undefined4 *puVar16;
  long lVar17;
  undefined4 *puVar18;
  long lVar19;
  ulong uVar20;
  undefined4 *puVar21;
  float fVar22;
  float fVar23;
  undefined8 uVar24;
  undefined8 uVar25;
  float fVar26;
  float fVar27;
  undefined4 uVar28;
  undefined4 uVar29;
  
  lVar19 = in_x0[0xd];
  pNVar2 = (NoiseCache *)(in_x0 + 3);
  lVar6 = NoiseCache::getFloatRegister(pNVar2,0);
  lVar7 = NoiseCache::getFloatRegister(pNVar2,1);
  lVar8 = NoiseCache::getFloatRegister(pNVar2,*(undefined4 *)(*in_x0 + 0x3c));
  lVar9 = NoiseCache::getFloatRegister(pNVar2,*(undefined4 *)(*in_x0 + 0x40));
  in_x8[1] = 0;
  in_x8[2] = 0;
  *in_x8 = 0;
  lVar10 = NoiseCache::getFloatRegister(pNVar2,*(undefined4 *)(*in_x0 + 0x38));
  uVar3 = *(uint *)(in_x0 + 1);
  uVar12 = (ulong)uVar3;
  if (uVar3 == 0) {
    fVar22 = 0.0;
  }
  else {
    if (uVar3 < 4) {
      uVar14 = 0;
      fVar22 = 0.0;
    }
    else {
      uVar14 = uVar12 & 0xfffffffc;
      fVar22 = 0.0;
      pfVar15 = (float *)(lVar10 + 8);
      uVar20 = uVar14;
      do {
        fVar22 = fVar22 + pfVar15[-2] + pfVar15[-1] + *pfVar15 + pfVar15[1];
        uVar20 = uVar20 - 4;
        pfVar15 = pfVar15 + 4;
      } while (uVar20 != 0);
      if (uVar14 == uVar12) goto LAB_1015e6cf8;
    }
    lVar17 = uVar12 - uVar14;
    pfVar15 = (float *)(lVar10 + uVar14 * 4);
    do {
      fVar22 = fVar22 + *pfVar15;
      lVar17 = lVar17 + -1;
      pfVar15 = pfVar15 + 1;
    } while (lVar17 != 0);
  }
LAB_1015e6cf8:
  if ((uVar3 != 0) &&
     (fVar22 = (fVar22 / (float)uVar3) *
               (float)(uint)(*(int *)(*in_x0 + 0x58) * *(int *)(*in_x0 + 0x58)), 0.0 < fVar22)) {
    uVar20 = 0;
    fVar27 = 0.0;
    puVar18 = (undefined4 *)0x0;
    do {
      lVar10 = (ulong)*(uint *)(lVar19 + uVar20 * 4) * 4;
      fVar23 = *(float *)(lVar8 + lVar10);
      fVar26 = *(float *)(*in_x0 + 0x54);
      if (*(float *)(lVar9 + lVar10) <= fVar26) {
        fVar26 = *(float *)(lVar9 + lVar10);
      }
      puVar13 = puVar18;
      if ((0.0 < fVar23) && (0.0 < fVar26)) {
        if (*(char *)(*in_x0 + 0x6c) != '\0') {
          fVar4 = fVar23;
          if (fVar22 - fVar27 <= fVar23) {
            fVar4 = fVar22 - fVar27;
          }
          fVar23 = (float)Math::log2(fVar4 / fVar23);
          fVar23 = (float)Math::exp2f(fVar23 * 0.33333334);
          fVar26 = fVar26 * fVar23;
          fVar23 = fVar4;
        }
        fVar4 = (fVar23 * 3.0) / (fVar26 * 3.1416 * fVar26);
        uVar29 = *(undefined4 *)(lVar6 + lVar10);
        uVar28 = *(undefined4 *)(lVar7 + lVar10);
        if (puVar18 < (undefined4 *)in_x8[2]) {
          *puVar18 = uVar29;
          puVar18[1] = uVar28;
          puVar18[2] = fVar23;
          puVar18[3] = fVar4;
          puVar18[4] = fVar4 / fVar26;
          puVar13 = puVar18 + 5;
          in_x8[1] = (ulong)puVar13;
        }
        else {
          puVar21 = (undefined4 *)*in_x8;
          lVar10 = (long)puVar18 - (long)puVar21 >> 2;
          uVar12 = lVar10 * -0x3333333333333333 + 1;
          if (0xccccccccccccccc < uVar12) {
            std::
            vector<ThreadSafeSpotNoiseCache::Spot,std::allocator<ThreadSafeSpotNoiseCache::Spot>>::
            __throw_length_error_abi_v160006_();
                    /* WARNING: Does not return */
            pcVar5 = (code *)SoftwareBreakpoint(1,0x1015e6f84);
            (*pcVar5)();
          }
          lVar17 = (long)in_x8[2] - (long)puVar21 >> 2;
          uVar14 = lVar17 * -0x6666666666666666;
          if (uVar14 < uVar12 || uVar14 - uVar12 == 0) {
            uVar14 = uVar12;
          }
          if (0x666666666666665 < (ulong)(lVar17 * -0x3333333333333333)) {
            uVar14 = 0xccccccccccccccc;
          }
          if (uVar14 == 0) {
            pvVar11 = (void *)0x0;
          }
          else {
            if (0xccccccccccccccc < uVar14) {
                    /* WARNING: Subroutine does not return */
              std::__throw_bad_array_new_length_abi_v160006_();
            }
            pvVar11 = operator_new(uVar14 * 0x14);
          }
          puVar13 = (undefined4 *)((long)pvVar11 + lVar10 * 4);
          *puVar13 = uVar29;
          puVar13[1] = uVar28;
          puVar13[2] = fVar23;
          puVar13[3] = fVar4;
          puVar13[4] = fVar4 / fVar26;
          puVar16 = puVar13;
          if (puVar18 != puVar21) {
            do {
              uVar25 = *(undefined8 *)(puVar18 + -3);
              uVar24 = *(undefined8 *)(puVar18 + -5);
              puVar1 = puVar18 + -1;
              puVar18 = puVar18 + -5;
              puVar16[-1] = *puVar1;
              *(undefined8 *)(puVar16 + -3) = uVar25;
              *(undefined8 *)(puVar16 + -5) = uVar24;
              puVar16 = puVar16 + -5;
            } while (puVar18 != puVar21);
            puVar18 = (undefined4 *)*in_x8;
          }
          puVar13 = puVar13 + 5;
          *in_x8 = (ulong)puVar16;
          in_x8[1] = (ulong)puVar13;
          in_x8[2] = (ulong)((long)pvVar11 + uVar14 * 0x14);
          if (puVar18 != (undefined4 *)0x0) {
            operator_delete(puVar18);
          }
        }
        fVar27 = fVar27 + fVar23;
        uVar12 = (ulong)*(uint *)(in_x0 + 1);
      }
      uVar20 = uVar20 + 1;
    } while ((uVar20 < uVar12) && (puVar18 = puVar13, fVar27 < fVar22));
  }
  return;
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



// ===== __throw_bad_array_new_length[abi:v160006]  @ 0x1000350f0 =====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* std::__throw_bad_array_new_length[abi:v160006]() */

void std::__throw_bad_array_new_length_abi_v160006_(void)

{
  bad_array_new_length *this;
  
  this = (bad_array_new_length *)___cxa_allocate_exception(8);
  bad_array_new_length::bad_array_new_length(this);
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this,&bad_array_new_length::typeinfo,bad_array_new_length::~bad_array_new_length);
}



// ===== __throw_length_error[abi:v160006]  @ 0x101d7cb30 =====

/* std::vector<ThreadSafeSpotNoiseCache::Spot, std::allocator<ThreadSafeSpotNoiseCache::Spot>
   >::__throw_length_error[abi:v160006]() const */

void std::vector<ThreadSafeSpotNoiseCache::Spot,std::allocator<ThreadSafeSpotNoiseCache::Spot>>::
     __throw_length_error_abi_v160006_(void)

{
                    /* WARNING: Subroutine does not return */
  std::__throw_length_error_abi_v160006_("vector");
}



// ===== ReleaseAssertFailed  @ 0x100156914 =====

/* ReleaseAssertFailed(char const*, unsigned int, char const*) */

void ReleaseAssertFailed(char *param_1,uint param_2,char *param_3)

{
                    /* WARNING: Subroutine does not return */
  Logging::logAndAbortOrThrow(param_1,param_2,9,"%s was not true");
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



// ===== generatePoints  @ 0x1015e67f4 =====

/* ThreadSafeSpotNoiseCache::SpotListGenerator::generatePoints() */

void __thiscall ThreadSafeSpotNoiseCache::SpotListGenerator::generatePoints(SpotListGenerator *this)

{
  float *pfVar1;
  uint uVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  uint uVar6;
  undefined8 uVar7;
  undefined8 uVar8;
  undefined8 uVar9;
  undefined8 uVar10;
  ulong uVar11;
  float *pfVar12;
  ulong uVar13;
  ulong uVar14;
  long lVar15;
  uint uVar16;
  float fVar17;
  float fVar18;
  uint uVar19;
  undefined8 uVar20;
  float fVar21;
  undefined8 uVar22;
  float fVar23;
  ulong uVar24;
  float fVar25;
  ulong uVar26;
  uint uVar27;
  float fVar28;
  
  uVar10 = DAT_102973568;
  uVar13 = DAT_102973560;
  uVar9 = DAT_102973558;
  uVar8 = DAT_102973550;
  uVar7 = DAT_102973548;
  lVar15 = *(long *)this;
  uVar11 = (ulong)*(uint *)(lVar15 + 0x5c);
  if (*(uint *)(lVar15 + 0x5c) != 0) {
    uVar16 = *(uint *)(lVar15 + 0x58);
    iVar3 = (int)((-(uVar16 >> 1) + *(int *)(this + 0xc) * uVar16) * 0x100) >> 8;
    iVar4 = (int)((-(uVar16 >> 1) + *(int *)(this + 0x10) * uVar16) * 0x100) >> 8;
    pfVar12 = *(float **)(this + 0x68);
    pfVar1 = pfVar12 + uVar11;
    fVar17 = *(float *)(lVar15 + 0x60) * *(float *)(lVar15 + 0x60);
    if (uVar16 << 8 < 0x200) {
      uVar13 = 0;
      fVar18 = (float)iVar3;
      fVar21 = (float)iVar4;
      do {
        if (uVar13 != 0) {
          do {
            uVar14 = 0;
            pfVar12[uVar13] = fVar18;
            pfVar1[uVar13] = fVar21;
            while (fVar17 <= (fVar18 - pfVar12[uVar14]) * (fVar18 - pfVar12[uVar14]) +
                             (fVar21 - pfVar12[uVar11 + uVar14]) *
                             (fVar21 - pfVar12[uVar11 + uVar14])) {
              uVar14 = uVar14 + 1;
              if (uVar13 == uVar14) goto LAB_1015e6854;
            }
            fVar17 = fVar17 * 0.9375;
          } while( true );
        }
        *pfVar12 = fVar18;
        *pfVar1 = fVar21;
LAB_1015e6854:
        uVar13 = uVar13 + 1;
      } while (uVar13 != uVar11);
    }
    else {
      uVar14 = 0;
      uVar5 = (int)(uVar16 << 8) >> 8;
      uVar16 = *(int *)(this + 0x10) * 0x1ee3 + *(int *)(this + 0xc) * 0x1eef +
               *(int *)(lVar15 + 0x4c) * 0x1ef7 + 0x3fbe2cU ^ *(uint *)(lVar15 + 0x48);
      if (uVar16 < 0x156) {
        uVar16 = 0x155;
      }
      uVar20 = CONCAT44(uVar16,uVar16);
      fVar18 = fVar17;
LAB_1015e6930:
      do {
        uVar22 = NEON_ushl(uVar20,uVar7,4);
        uVar24 = NEON_ushl(uVar20,uVar8,4);
        uVar2 = uVar16 ^ uVar16 << 3;
        uVar16 = (uVar16 & 0x7ff0) << 0x11 | uVar2 >> 0xb;
        uVar22 = NEON_ushl(CONCAT17((byte)((ulong)uVar22 >> 0x38) ^ (byte)((ulong)uVar20 >> 0x38),
                                    CONCAT16((byte)((ulong)uVar22 >> 0x30) ^
                                             (byte)((ulong)uVar20 >> 0x30),
                                             CONCAT15((byte)((ulong)uVar22 >> 0x28) ^
                                                      (byte)((ulong)uVar20 >> 0x28),
                                                      CONCAT14((byte)((ulong)uVar22 >> 0x20) ^
                                                               (byte)((ulong)uVar20 >> 0x20),
                                                               CONCAT13((byte)((ulong)uVar22 >> 0x18
                                                                              ) ^ (byte)((ulong)
                                                  uVar20 >> 0x18),
                                                  CONCAT12((byte)((ulong)uVar22 >> 0x10) ^
                                                           (byte)((ulong)uVar20 >> 0x10),
                                                           CONCAT11((byte)((ulong)uVar22 >> 8) ^
                                                                    (byte)((ulong)uVar20 >> 8),
                                                                    (byte)uVar22 ^ (byte)uVar20)))))
                                            )),uVar9,4);
        uVar26 = uVar24 & uVar13;
        uVar19 = CONCAT13((byte)((ulong)uVar22 >> 0x18) | (byte)(uVar26 >> 0x18),
                          CONCAT12((byte)((ulong)uVar22 >> 0x10) | (byte)(uVar26 >> 0x10),
                                   CONCAT11((byte)((ulong)uVar22 >> 8) | (byte)(uVar26 >> 8),
                                            (byte)uVar22 | (byte)uVar26)));
        uVar22 = CONCAT17((byte)((ulong)uVar22 >> 0x38) | (byte)(uVar26 >> 0x38),
                          CONCAT16((byte)((ulong)uVar22 >> 0x30) | (byte)(uVar26 >> 0x30),
                                   CONCAT15((byte)((ulong)uVar22 >> 0x28) | (byte)(uVar26 >> 0x28),
                                            CONCAT14((byte)((ulong)uVar22 >> 0x20) |
                                                     (byte)(uVar26 >> 0x20),uVar19))));
        uVar27 = (uint)((ulong)uVar22 >> 0x20);
        uVar19 = uVar19 ^ uVar16 ^ uVar27;
        uVar6 = 0;
        if (uVar5 != 0) {
          uVar6 = uVar19 / uVar5;
        }
        fVar21 = (float)(int)((uVar19 - uVar6 * uVar5) + iVar3);
        uVar26 = NEON_ushl(uVar22,uVar8,4);
        pfVar12[uVar14] = fVar21;
        uVar20 = NEON_ushl(CONCAT44(uVar27,(int)uVar20),uVar10,4);
        uVar20 = NEON_ushl(CONCAT17((byte)((ulong)uVar20 >> 0x38) ^ (byte)(uVar24 >> 0x38),
                                    CONCAT16((byte)((ulong)uVar20 >> 0x30) ^ (byte)(uVar24 >> 0x30),
                                             CONCAT15((byte)((ulong)uVar20 >> 0x28) ^
                                                      (byte)(uVar24 >> 0x28),
                                                      CONCAT14((byte)((ulong)uVar20 >> 0x20) ^
                                                               (byte)(uVar24 >> 0x20),
                                                               CONCAT13((byte)((ulong)uVar20 >> 0x18
                                                                              ) ^ (byte)(uVar24 >>
                                                                                        0x18),
                                                                        CONCAT12((byte)((ulong)
                                                  uVar20 >> 0x10) ^ (byte)(uVar24 >> 0x10),
                                                  CONCAT11((byte)((ulong)uVar20 >> 8) ^
                                                           (byte)(uVar24 >> 8),
                                                           (byte)uVar20 ^ (byte)uVar24))))))),uVar9,
                           4);
        uVar26 = uVar26 & uVar13;
        uVar19 = CONCAT13((byte)((ulong)uVar20 >> 0x18) | (byte)(uVar26 >> 0x18),
                          CONCAT12((byte)((ulong)uVar20 >> 0x10) | (byte)(uVar26 >> 0x10),
                                   CONCAT11((byte)((ulong)uVar20 >> 8) | (byte)(uVar26 >> 8),
                                            (byte)uVar20 | (byte)uVar26)));
        uVar20 = CONCAT17((byte)((ulong)uVar20 >> 0x38) | (byte)(uVar26 >> 0x38),
                          CONCAT16((byte)((ulong)uVar20 >> 0x30) | (byte)(uVar26 >> 0x30),
                                   CONCAT15((byte)((ulong)uVar20 >> 0x28) | (byte)(uVar26 >> 0x28),
                                            CONCAT14((byte)((ulong)uVar20 >> 0x20) |
                                                     (byte)(uVar26 >> 0x20),uVar19))));
        uVar16 = (uVar2 & 0x3ff8000) << 6 | (uVar16 ^ uVar16 << 3) >> 0xb;
        uVar2 = uVar19 ^ uVar16 ^ (uint)((ulong)uVar20 >> 0x20);
        uVar19 = 0;
        if (uVar5 != 0) {
          uVar19 = uVar2 / uVar5;
        }
        fVar23 = (float)(int)((uVar2 - uVar19 * uVar5) + iVar4);
        pfVar1[uVar14] = fVar23;
        fVar25 = fVar18;
        if (uVar14 != 0) {
          uVar24 = 0;
          do {
            fVar25 = fVar21 - pfVar12[uVar24];
            fVar28 = fVar23 - pfVar12[uVar11 + uVar24];
            if (fVar25 * fVar25 + fVar28 * fVar28 < fVar17) {
              fVar17 = fVar17 * 0.9375;
              goto LAB_1015e6930;
            }
            uVar24 = uVar24 + 1;
            fVar25 = fVar17;
          } while (uVar14 != uVar24);
        }
        uVar14 = uVar14 + 1;
        fVar17 = fVar25;
        fVar18 = fVar25;
      } while (uVar14 != uVar11);
    }
  }
  return;
}



// ===== computeRegionBounds  @ 0x1015dccf0 =====

/* NoiseCache::computeRegionBounds(NoiseRegisterIndex, NoiseRegisterIndex) */

void __thiscall NoiseCache::computeRegionBounds(NoiseCache *this,int param_2,undefined8 param_3)

{
  float *pfVar1;
  float *pfVar2;
  long lVar3;
  float fVar4;
  float fVar5;
  float fVar6;
  float fVar7;
  float fVar8;
  float fVar9;
  float fVar10;
  float fVar11;
  
  if ((((int)param_3 != 1) || (param_2 != 0)) || (this[0x28] == (NoiseCache)0x0)) {
    pfVar1 = (float *)getFloatRegister(this);
    pfVar2 = (float *)getFloatRegister(this,param_3);
    lVar3 = *(long *)(this + 0x10);
    if (lVar3 == 0) {
      return;
    }
    fVar4 = INFINITY;
    fVar6 = INFINITY;
    fVar8 = -INFINITY;
    fVar9 = -INFINITY;
    do {
      fVar10 = *pfVar1;
      fVar5 = fVar10;
      if (fVar4 <= fVar10) {
        fVar5 = fVar4;
      }
      fVar11 = *pfVar2;
      fVar7 = fVar11;
      if (fVar6 <= fVar11) {
        fVar7 = fVar6;
      }
      if (fVar10 <= fVar8) {
        fVar10 = fVar8;
      }
      if (fVar11 <= fVar9) {
        fVar11 = fVar9;
      }
      lVar3 = lVar3 + -1;
      pfVar2 = pfVar2 + 1;
      pfVar1 = pfVar1 + 1;
      fVar4 = fVar5;
      fVar6 = fVar7;
      fVar8 = fVar10;
      fVar9 = fVar11;
    } while (lVar3 != 0);
  }
  return;
}



// ===== run  @ 0x101610ac0 =====

/* NoiseOperations::SpotNoise::run(NoiseCache&) const */

void NoiseOperations::SpotNoise::run(NoiseCache *param_1)

{
  ulong uVar1;
  float *pfVar2;
  undefined8 uVar3;
  undefined8 uVar4;
  __assoc_sub_state *this;
  code *pcVar5;
  bool bVar6;
  bool bVar7;
  bool bVar8;
  NoiseCache *pNVar9;
  float *pfVar10;
  float *pfVar11;
  NoiseCache *in_x1;
  int iVar12;
  float *pfVar13;
  ulong uVar14;
  ulong uVar15;
  int iVar16;
  NoiseCache *pNVar17;
  int iVar18;
  float *pfVar19;
  ulong uVar20;
  float *pfVar21;
  NoiseCache *pNVar22;
  long lVar23;
  long lVar24;
  int iVar25;
  int iVar26;
  undefined4 uVar27;
  float fVar28;
  float fVar29;
  float fVar30;
  undefined1 *puVar31;
  float in_s1;
  undefined1 *puVar32;
  double dVar33;
  float in_s2;
  double dVar34;
  float in_s3;
  double dVar35;
  double dVar36;
  double dVar37;
  __assoc_sub_state *local_a0;
  undefined8 local_98;
  mutex *local_90;
  char local_88;
  
  pNVar9 = (NoiseCache *)NoiseCache::getFloatRegister();
  pfVar10 = (float *)NoiseCache::getFloatRegister();
  pfVar11 = (float *)NoiseCache::getFloatRegister();
  uVar14 = *(ulong *)(in_x1 + 0x10);
  if (0 < (long)(uVar14 * 4)) {
    pNVar22 = param_1 + 0x50;
    uVar15 = uVar14 & 0x3fffffffffffffff;
    uVar1 = (uVar15 - (uVar15 != 0)) + 1;
    pNVar17 = pNVar9;
    if (0xf < uVar1) {
      lVar24 = uVar14 * 4 + 4;
      if (uVar15 != 0) {
        lVar24 = uVar14 * 4;
      }
      if ((param_1 + 0x54 <= pNVar9) || (pNVar9 + lVar24 <= pNVar22)) {
        uVar20 = uVar1 & 0xfffffffffffffff0;
        uVar15 = uVar15 - uVar20;
        pNVar17 = pNVar9 + 0x20;
        uVar14 = uVar20;
        do {
          uVar27 = (undefined4)*(undefined8 *)pNVar22;
          uVar3 = CONCAT44(uVar27,uVar27);
          uVar4 = CONCAT44(uVar27,uVar27);
          *(undefined8 *)(pNVar17 + -0x18) = uVar4;
          *(undefined8 *)(pNVar17 + -0x20) = uVar3;
          *(undefined8 *)(pNVar17 + -8) = uVar4;
          *(undefined8 *)(pNVar17 + -0x10) = uVar3;
          *(undefined8 *)(pNVar17 + 8) = uVar4;
          *(undefined8 *)pNVar17 = uVar3;
          *(undefined8 *)(pNVar17 + 0x18) = uVar4;
          *(undefined8 *)(pNVar17 + 0x10) = uVar3;
          uVar14 = uVar14 - 0x10;
          pNVar17 = pNVar17 + 0x40;
        } while (uVar14 != 0);
        pNVar17 = pNVar9 + uVar20 * 4;
        if (uVar1 == uVar20) goto LAB_101610bd0;
      }
    }
    uVar15 = uVar15 + 1;
    do {
      *(undefined4 *)pNVar17 = *(undefined4 *)pNVar22;
      uVar15 = uVar15 - 1;
      pNVar17 = pNVar17 + 4;
    } while (1 < uVar15);
  }
LAB_101610bd0:
  fVar28 = (float)computeRegionBounds((SpotNoise *)param_1,in_x1);
  puVar32 = (undefined1 *)((double)fVar28 * 256.0);
  bVar6 = true;
  if ((!NAN((double)puVar32)) && (bVar6 = false, !NAN((double)puVar32))) {
    bVar6 = (double)puVar32 == INFINITY;
  }
  bVar7 = true;
  if ((!bVar6) && (bVar7 = false, !NAN((double)puVar32))) {
    bVar7 = (double)puVar32 == -INFINITY;
  }
  if (!bVar7) {
    dVar34 = (double)in_s1 * 256.0;
    bVar6 = true;
    if ((!NAN(dVar34)) && (bVar6 = false, !NAN(dVar34))) {
      bVar6 = dVar34 == INFINITY;
    }
    bVar7 = true;
    if ((!bVar6) && (bVar7 = false, !NAN(dVar34))) {
      bVar7 = dVar34 == -INFINITY;
    }
    if ((((!bVar7) && (puVar31 = (undefined1 *)((double)in_s2 * 256.0), (double)puVar31 != INFINITY)
         ) && ((double)puVar31 != -INFINITY)) &&
       ((dVar35 = (double)in_s3 * 256.0, dVar35 != INFINITY && (dVar35 != -INFINITY)))) {
      if ((double)puVar32 <= -2147483648.0) {
        puVar32 = &DAT_c1e0000000000000;
      }
      dVar33 = (double)NEON_fminnm(puVar32,0x41dfffffffc00000);
      dVar34 = (double)NEON_fminnm(dVar34,0x41dfffffffc00000);
      dVar36 = (double)(*(uint *)(param_1 + 0x58) >> 1);
      dVar37 = (double)(int)*(uint *)(param_1 + 0x58);
      iVar16 = (int)(((double)(int)dVar33 * 0.00390625 + dVar36) / dVar37);
      iVar18 = (int)(((double)(int)dVar34 * 0.00390625 + dVar36) / dVar37);
      if ((double)puVar31 <= -2147483648.0) {
        puVar31 = &DAT_c1e0000000000000;
      }
      dVar34 = (double)NEON_fminnm(puVar31,0x41dfffffffc00000);
      dVar35 = (double)NEON_fminnm(dVar35,0x41dfffffffc00000);
      iVar26 = (int)(((double)(int)dVar34 * 0.00390625 + dVar36) / dVar37);
      iVar12 = (int)(((double)(int)dVar35 * 0.00390625 + dVar36) / dVar37);
      iVar25 = iVar16;
      if (iVar18 < iVar12 && iVar16 < iVar26) {
        do {
          ThreadSafeSpotNoiseCache::getSpotListFuture
                    (&local_a0,&DAT_1032b5150,param_1,CONCAT44(iVar18,iVar25));
          this = local_a0;
          local_90 = (mutex *)(local_a0 + 0x18);
          local_88 = '\x01';
          std::mutex::lock(local_90);
          std::__assoc_sub_state::__sub_wait(this,(unique_lock *)&local_90);
          local_98 = 0;
          lVar24 = *(long *)(this + 0x10);
          std::exception_ptr::~exception_ptr((exception_ptr *)&local_98);
          if (lVar24 != 0) {
            std::exception_ptr::exception_ptr
                      ((exception_ptr *)&local_98,(exception_ptr *)(this + 0x10));
            std::rethrow_exception(&local_98);
                    /* WARNING: Does not return */
            pcVar5 = (code *)SoftwareBreakpoint(1,0x101610f90);
            (*pcVar5)();
          }
          if (local_88 != '\0') {
            std::mutex::unlock(local_90);
          }
          pfVar13 = *(float **)(this + 0x90);
          pfVar2 = *(float **)(this + 0x98);
          if (pfVar13 != pfVar2) {
            lVar24 = *(long *)(in_x1 + 0x10);
            if (lVar24 == 0) {
              do {
                pfVar13 = pfVar13 + 5;
              } while (pfVar13 != pfVar2);
            }
            else {
              do {
                fVar29 = *pfVar13;
                bVar6 = false;
                bVar7 = false;
                bVar8 = false;
                if (fVar28 <= fVar29) {
                  bVar6 = false;
                  bVar7 = false;
                  bVar8 = true;
                  if (!NAN(fVar29) && !NAN(in_s2)) {
                    bVar6 = fVar29 < in_s2;
                    bVar7 = fVar29 == in_s2;
                    bVar8 = false;
                  }
                }
                if (bVar7 || bVar6 != bVar8) {
                  fVar29 = pfVar13[1];
                  bVar6 = false;
                  bVar7 = false;
                  bVar8 = false;
                  if (in_s1 <= fVar29) {
                    bVar6 = false;
                    bVar7 = false;
                    bVar8 = true;
                    if (!NAN(fVar29) && !NAN(in_s3)) {
                      bVar6 = fVar29 < in_s3;
                      bVar7 = fVar29 == in_s3;
                      bVar8 = false;
                    }
                  }
                  pfVar19 = pfVar10;
                  pfVar21 = pfVar11;
                  pNVar22 = pNVar9;
                  lVar23 = lVar24;
                  if (bVar7 || bVar6 != bVar8) {
                    do {
                      fVar29 = SQRT((*pfVar19 - *pfVar13) * (*pfVar19 - *pfVar13) +
                                    (*pfVar21 - pfVar13[1]) * (*pfVar21 - pfVar13[1]));
                      if (fVar29 <= *(float *)(param_1 + 0x54)) {
                        fVar30 = pfVar13[3] - fVar29 * pfVar13[4];
                        fVar29 = *(float *)pNVar22;
                        if (*(float *)pNVar22 <= fVar30) {
                          fVar29 = fVar30;
                        }
                        *(float *)pNVar22 = fVar29;
                      }
                      pNVar22 = pNVar22 + 4;
                      pfVar21 = pfVar21 + 1;
                      pfVar19 = pfVar19 + 1;
                      lVar23 = lVar23 + -1;
                    } while (lVar23 != 0);
                  }
                }
                pfVar13 = pfVar13 + 5;
              } while (pfVar13 != pfVar2);
            }
          }
          LOAcquire();
          lVar24 = *(long *)(this + 8);
          *(long *)(this + 8) = lVar24 + -1;
          LORelease();
          if (lVar24 == 0) {
            (**(code **)(*(long *)this + 0x10))(this);
          }
          iVar25 = iVar25 + 1;
        } while ((iVar25 != iVar26) || (iVar18 = iVar18 + 1, iVar25 = iVar16, iVar18 != iVar12));
      }
      return;
    }
  }
                    /* WARNING: Subroutine does not return */
  Logging::logAndAbortOrThrow
            ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Util/FixedPointNumber.hpp"
             ,0x1f,9,"double value not in range for fixed point number: %f");
}



// ===== exception_ptr  @ 0x100022fdc =====

/* std::exception_ptr::exception_ptr(std::exception_ptr const&) */

exception_ptr * __thiscall
std::exception_ptr::exception_ptr(exception_ptr *this,exception_ptr *param_1)

{
  exception_ptr(this,param_1);
  return this;
}



// ===== exception_ptr  @ 0x100022f9c =====

/* std::exception_ptr::exception_ptr(std::exception_ptr const&) */

exception_ptr * __thiscall
std::exception_ptr::exception_ptr(exception_ptr *this,exception_ptr *param_1)

{
  *(undefined8 *)this = *(undefined8 *)param_1;
  ___cxa_increment_exception_refcount(*(undefined8 *)this);
  return this;
}



// ===== unlock  @ 0x1000284d8 =====

/* std::mutex::unlock() */

void __thiscall std::mutex::unlock(mutex *this)

{
  __libcpp_mutex_unlock_abi_v160006_((_opaque_pthread_mutex_t *)this);
  return;
}



// ===== __libcpp_mutex_unlock[abi:v160006]  @ 0x100027574 =====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* std::__libcpp_mutex_unlock[abi:v160006](_opaque_pthread_mutex_t*) */

int std::__libcpp_mutex_unlock_abi_v160006_(_opaque_pthread_mutex_t *param_1)

{
  int iVar1;
  
  iVar1 = _pthread_mutex_unlock(param_1);
  return iVar1;
}



// ===== rethrow_exception  @ 0x100023304 =====

/* std::rethrow_exception(std::exception_ptr) */

void std::rethrow_exception(undefined8 *param_1)

{
  ___cxa_rethrow_primary_exception(*param_1);
                    /* WARNING: Subroutine does not return */
  terminate();
}



// ===== ___cxa_rethrow_primary_exception  @ 0x1000ed474 =====

void ___cxa_rethrow_primary_exception(void *param_1)

{
  long lVar1;
  long lVar2;
  undefined8 uVar3;
  
  if (param_1 != (void *)0x0) {
    lVar1 = __cxxabiv1::cxa_exception_from_thrown_object(param_1);
    lVar2 = ___cxa_allocate_dependent_exception();
    *(void **)(lVar2 + 8) = param_1;
    ___cxa_increment_exception_refcount(param_1);
    *(undefined8 *)(lVar2 + 0x10) = *(undefined8 *)(lVar1 + 0x10);
    uVar3 = std::get_unexpected();
    *(undefined8 *)(lVar2 + 0x20) = uVar3;
    uVar3 = std::get_terminate();
    *(undefined8 *)(lVar2 + 0x28) = uVar3;
    __cxxabiv1::setDependentExceptionClass((_Unwind_Exception *)(lVar2 + 0x60));
    lVar1 = ___cxa_get_globals();
    *(int *)(lVar1 + 8) = *(int *)(lVar1 + 8) + 1;
    *(code **)(lVar2 + 0x68) = __cxxabiv1::dependent_exception_cleanup;
    __Unwind_RaiseException((_Unwind_Exception *)(lVar2 + 0x60));
    ___cxa_begin_catch(lVar2 + 0x60);
  }
  return;
}



// ===== terminate  @ 0x1000e7a88 =====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* std::terminate() */

void std::terminate(void)

{
  uint uVar1;
  long *plVar2;
  _func_void *p_Var3;
  long lVar4;
  
  plVar2 = (long *)___cxa_get_globals_fast();
  if (((plVar2 != (long *)0x0) && (lVar4 = *plVar2, lVar4 != 0)) &&
     (uVar1 = __cxxabiv1::__isOurExceptionClass((_Unwind_Exception *)(lVar4 + 0x60)),
     (uVar1 & 1) != 0)) {
                    /* WARNING: Subroutine does not return */
    __terminate(*(_func_void **)(lVar4 + 0x28));
  }
  p_Var3 = (_func_void *)get_terminate();
                    /* WARNING: Subroutine does not return */
  __terminate(p_Var3);
}



// ===== ~exception_ptr  @ 0x100022f70 =====

/* std::exception_ptr::~exception_ptr() */

exception_ptr * __thiscall std::exception_ptr::~exception_ptr(exception_ptr *this)

{
  ~exception_ptr(this);
  return this;
}



// ===== ~exception_ptr  @ 0x100022f40 =====

/* std::exception_ptr::~exception_ptr() */

exception_ptr * __thiscall std::exception_ptr::~exception_ptr(exception_ptr *this)

{
  ___cxa_decrement_exception_refcount(*(undefined8 *)this);
  return this;
}



// ===== lock  @ 0x100028424 =====

/* std::mutex::lock() */

void __thiscall std::mutex::lock(mutex *this)

{
  int iVar1;
  
  iVar1 = __libcpp_mutex_lock_abi_v160006_((_opaque_pthread_mutex_t *)this);
  if (iVar1 != 0) {
    __throw_system_error(iVar1,"mutex lock failed");
  }
  return;
}



// ===== __libcpp_mutex_lock[abi:v160006]  @ 0x100027520 =====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* std::__libcpp_mutex_lock[abi:v160006](_opaque_pthread_mutex_t*) */

int std::__libcpp_mutex_lock_abi_v160006_(_opaque_pthread_mutex_t *param_1)

{
  int iVar1;
  
  iVar1 = _pthread_mutex_lock(param_1);
  return iVar1;
}



// ===== __throw_system_error  @ 0x10003b140 =====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* std::__throw_system_error(int, char const*) */

void std::__throw_system_error(int param_1,char *param_2)

{
  int iVar1;
  system_error *psVar2;
  error_category *peVar3;
  undefined8 local_30;
  undefined8 local_28;
  char *local_20;
  int local_14;
  
  local_20 = param_2;
  local_14 = param_1;
  psVar2 = (system_error *)___cxa_allocate_exception(0x20);
  iVar1 = local_14;
  peVar3 = (error_category *)system_category();
  error_code::error_code_abi_v160006_((error_code *)&local_30,iVar1,peVar3);
  system_error::system_error(psVar2,local_30,local_28,local_20);
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(psVar2,&system_error::typeinfo,system_error::~system_error);
}



// ===== getSpotListFuture  @ 0x1015e623c =====

/* ThreadSafeSpotNoiseCache::getSpotListFuture(NoiseOperations::SpotNoise const&, RegionPosition) */

void ThreadSafeSpotNoiseCache::getSpotListFuture
               (long *param_1_00,mutex *param_1,long param_3,long param_4)

{
  bool bVar1;
  piecewise_construct_t *ppVar2;
  long *plVar3;
  undefined8 *puVar4;
  int iVar5;
  long lVar6;
  long lVar7;
  long *plVar8;
  __tree_node_base *p_Var9;
  __tree_node_base *p_Var10;
  uint uVar11;
  undefined8 *puVar12;
  undefined8 *puVar13;
  int iVar14;
  mutex *this;
  int iVar15;
  undefined8 *puVar16;
  piecewise_construct_t *local_68;
  
  std::mutex::lock(param_1);
  ppVar2 = (piecewise_construct_t *)(param_3 + 0x6d);
  local_68 = ppVar2;
  lVar7 = std::
          __tree<std::__value_type<SHA1Digest,std::map<RegionPosition,ThreadSafeSpotNoiseCache::Entry,std::less<RegionPosition>,std::allocator<std::pair<RegionPosition_const,ThreadSafeSpotNoiseCache::Entry>>>>,std::__map_value_compare<SHA1Digest,std::__value_type<SHA1Digest,std::map<RegionPosition,ThreadSafeSpotNoiseCache::Entry,std::less<RegionPosition>,std::allocator<std::pair<RegionPosition_const,ThreadSafeSpotNoiseCache::Entry>>>>,std::less<SHA1Digest>,true>,std::allocator<std::__value_type<SHA1Digest,std::map<RegionPosition,ThreadSafeSpotNoiseCache::Entry,std::less<RegionPosition>,std::allocator<std::pair<RegionPosition_const,ThreadSafeSpotNoiseCache::Entry>>>>>>
          ::
          __emplace_unique_key_args<SHA1Digest,std::piecewise_construct_t_const&,std::tuple<SHA1Digest_const&>,std::tuple<>>
                    ((SHA1Digest *)(param_1 + 0x40),ppVar2,(tuple *)&std::piecewise_construct,
                     (tuple *)&local_68);
  puVar16 = (undefined8 *)(lVar7 + 0x40);
  puVar13 = (undefined8 *)*puVar16;
  iVar14 = (int)param_4;
  iVar15 = (int)((ulong)param_4 >> 0x20);
  puVar12 = puVar16;
  if (puVar13 != (undefined8 *)0x0) {
    do {
      bVar1 = *(int *)(puVar13 + 4) < iVar14;
      if (*(int *)(puVar13 + 4) == iVar14) {
        bVar1 = *(int *)((long)puVar13 + 0x24) != iVar15 && *(int *)((long)puVar13 + 0x24) < iVar15;
      }
      puVar4 = puVar13;
      if (bVar1) {
        puVar4 = puVar12;
        puVar13 = puVar13 + 1;
      }
      puVar13 = (undefined8 *)*puVar13;
      puVar12 = puVar4;
    } while (puVar13 != (undefined8 *)0x0);
    if (puVar4 != puVar16) {
      bVar1 = iVar14 < *(int *)(puVar4 + 4);
      if (*(int *)(puVar4 + 4) == iVar14) {
        bVar1 = *(int *)((long)puVar4 + 0x24) != iVar15 && iVar15 < *(int *)((long)puVar4 + 0x24);
      }
      if (!bVar1) {
        *(undefined1 *)(puVar4 + 6) = 1;
        lVar7 = puVar4[5];
        *param_1_00 = lVar7;
        if (lVar7 != 0) {
          *(long *)(lVar7 + 8) = *(long *)(lVar7 + 8) + 1;
        }
        goto LAB_1015e653c;
      }
    }
  }
  uVar11 = *(uint *)(param_1 + 0x58);
  if (100 < uVar11) {
    runGarbageCollection((ThreadSafeSpotNoiseCache *)param_1,(SHA1Digest *)ppVar2);
    uVar11 = *(uint *)(param_1 + 0x58);
  }
  *(uint *)(param_1 + 0x58) = uVar11 + 1;
  plVar8 = operator_new(0xb8);
  plVar8[1] = 0;
  this = (mutex *)(plVar8 + 3);
  *(undefined8 *)this = 0x32aaaba7;
  plVar8[2] = 0;
  plVar8[5] = 0;
  plVar8[4] = 0;
  plVar8[7] = 0;
  plVar8[6] = 0;
  plVar8[9] = 0;
  plVar8[8] = 0;
  plVar8[10] = 0;
  plVar8[0xb] = 0x3cb0b1bb;
  plVar8[0xd] = 0;
  plVar8[0xc] = 0;
  plVar8[0xf] = 0;
  plVar8[0xe] = 0;
  plVar8[0x10] = 0;
  *plVar8 = (long)&PTR____deferred_assoc_state_10305ba78;
  plVar8[0x15] = param_3;
  plVar8[0x16] = param_4;
  *(undefined4 *)(plVar8 + 0x11) = 8;
  std::mutex::lock(this);
  if ((*(uint *)(plVar8 + 0x11) >> 1 & 1) != 0) {
                    /* WARNING: Subroutine does not return */
    std::__throw_future_error_abi_v160006_(1);
  }
  plVar3 = plVar8 + 1;
  *plVar3 = *plVar3 + 1;
  *(uint *)(plVar8 + 0x11) = *(uint *)(plVar8 + 0x11) | 2;
  std::mutex::unlock(this);
  LOAcquire();
  lVar6 = *plVar3;
  *plVar3 = lVar6 + -1;
  LORelease();
  if (lVar6 == 0) {
    (**(code **)(*plVar8 + 0x10))(plVar8);
    *param_1_00 = (long)plVar8;
    puVar13 = (undefined8 *)*puVar16;
  }
  else {
    *param_1_00 = (long)plVar8;
    puVar13 = (undefined8 *)*puVar16;
  }
  puVar12 = puVar16;
  if (puVar13 != (undefined8 *)0x0) {
    do {
      while (puVar16 = puVar13, iVar5 = *(int *)(puVar16 + 4), iVar5 != iVar14) {
        if (iVar5 <= iVar14) {
          if (iVar5 < iVar14) goto LAB_1015e6488;
LAB_1015e6500:
          p_Var9 = (__tree_node_base *)(puVar16 + 5);
          goto LAB_1015e6504;
        }
LAB_1015e6440:
        puVar13 = (undefined8 *)*puVar16;
        puVar12 = puVar16;
        if ((undefined8 *)*puVar16 == (undefined8 *)0x0) goto LAB_1015e6494;
      }
      iVar5 = *(int *)((long)puVar16 + 0x24);
      if (iVar15 < iVar5) goto LAB_1015e6440;
      if (iVar5 == iVar15 || iVar15 <= iVar5) goto LAB_1015e6500;
LAB_1015e6488:
      puVar13 = (undefined8 *)puVar16[1];
    } while ((undefined8 *)puVar16[1] != (undefined8 *)0x0);
    puVar12 = puVar16 + 1;
  }
LAB_1015e6494:
  p_Var9 = operator_new(0x38);
  *(undefined8 *)(p_Var9 + 0x28) = 0;
  *(undefined8 *)(p_Var9 + 0x30) = 0;
  *(long *)(p_Var9 + 0x20) = param_4;
  p_Var9[0x30] = (__tree_node_base)0x1;
  *(undefined8 *)p_Var9 = 0;
  *(undefined8 *)(p_Var9 + 8) = 0;
  *(undefined8 **)(p_Var9 + 0x10) = puVar16;
  *puVar12 = p_Var9;
  p_Var10 = p_Var9;
  if (**(long **)(lVar7 + 0x38) != 0) {
    *(long *)(lVar7 + 0x38) = **(long **)(lVar7 + 0x38);
    p_Var10 = (__tree_node_base *)*puVar12;
  }
  std::__tree_balance_after_insert_abi_v160006_<std::__tree_node_base<void*>*>
            (*(__tree_node_base **)(lVar7 + 0x40),p_Var10);
  *(long *)(lVar7 + 0x48) = *(long *)(lVar7 + 0x48) + 1;
  plVar8 = (long *)*param_1_00;
  p_Var9 = p_Var9 + 0x28;
  if (plVar8 == (long *)0x0) {
    plVar8 = *(long **)p_Var9;
  }
  else {
LAB_1015e6504:
    plVar8[1] = plVar8[1] + 1;
    plVar8 = *(long **)p_Var9;
  }
  if (plVar8 != (long *)0x0) {
    LOAcquire();
    lVar7 = plVar8[1];
    plVar8[1] = lVar7 + -1;
    LORelease();
    if (lVar7 == 0) {
      (**(code **)(*plVar8 + 0x10))();
    }
  }
  *(long *)p_Var9 = *param_1_00;
LAB_1015e653c:
  std::mutex::unlock(param_1);
  return;
}



// ===== __on_zero_shared  @ 0x102266e74 =====

/* std::__assoc_state<std::vector<ThreadSafeSpotNoiseCache::Spot,
   std::allocator<ThreadSafeSpotNoiseCache::Spot> > >::__on_zero_shared() */

void __thiscall
std::
__assoc_state<std::vector<ThreadSafeSpotNoiseCache::Spot,std::allocator<ThreadSafeSpotNoiseCache::Spot>>>
::__on_zero_shared(__assoc_state<std::vector<ThreadSafeSpotNoiseCache::Spot,std::allocator<ThreadSafeSpotNoiseCache::Spot>>>
                   *this)

{
  void *pvVar1;
  
  if ((((byte)this[0x88] & 1) != 0) && (pvVar1 = *(void **)(this + 0x90), pvVar1 != (void *)0x0)) {
    *(void **)(this + 0x98) = pvVar1;
    operator_delete(pvVar1);
  }
                    /* WARNING: Could not recover jumptable at 0x000102266eb0. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  (**(code **)(*(long *)this + 8))(this);
  return;
}



// ===== __throw_future_error[abi:v160006]  @ 0x10002388c =====

/* std::__throw_future_error[abi:v160006](std::future_errc) */

void std::__throw_future_error_abi_v160006_(undefined4 param_1)

{
  future_error *pfVar1;
  undefined1 auVar2 [16];
  
  pfVar1 = (future_error *)___cxa_allocate_exception(0x20);
  auVar2 = make_error_code_abi_v160006_(param_1);
  future_error::future_error(pfVar1,auVar2._0_8_,auVar2._8_8_);
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(pfVar1,&future_error::typeinfo,future_error::~future_error);
}



// ===== __emplace_unique_key_args<SHA1Digest,std::piecewise_construct_t_const&,std::tuple<SHA1Digest_const&>,std::tuple<>>  @ 0x102266d54 =====

/* std::pair<std::__tree_iterator<std::__value_type<SHA1Digest, std::map<RegionPosition,
   ThreadSafeSpotNoiseCache::Entry, std::less<RegionPosition>,
   std::allocator<std::pair<RegionPosition const, ThreadSafeSpotNoiseCache::Entry> > > >,
   std::__tree_node<std::__value_type<SHA1Digest, std::map<RegionPosition,
   ThreadSafeSpotNoiseCache::Entry, std::less<RegionPosition>,
   std::allocator<std::pair<RegionPosition const, ThreadSafeSpotNoiseCache::Entry> > > >, void*>*,
   long>, bool> std::__tree<std::__value_type<SHA1Digest, std::map<RegionPosition,
   ThreadSafeSpotNoiseCache::Entry, std::less<RegionPosition>,
   std::allocator<std::pair<RegionPosition const, ThreadSafeSpotNoiseCache::Entry> > > >,
   std::__map_value_compare<SHA1Digest, std::__value_type<SHA1Digest, std::map<RegionPosition,
   ThreadSafeSpotNoiseCache::Entry, std::less<RegionPosition>,
   std::allocator<std::pair<RegionPosition const, ThreadSafeSpotNoiseCache::Entry> > > >,
   std::less<SHA1Digest>, true>, std::allocator<std::__value_type<SHA1Digest,
   std::map<RegionPosition, ThreadSafeSpotNoiseCache::Entry, std::less<RegionPosition>,
   std::allocator<std::pair<RegionPosition const, ThreadSafeSpotNoiseCache::Entry> > > > >
   >::__emplace_unique_key_args<SHA1Digest, std::piecewise_construct_t const&, std::tuple<SHA1Digest
   const&>, std::tuple<> >(SHA1Digest const&, std::piecewise_construct_t const&,
   std::tuple<SHA1Digest const&>&&, std::tuple<>&&) */

undefined1  [16]
std::
__tree<std::__value_type<SHA1Digest,std::map<RegionPosition,ThreadSafeSpotNoiseCache::Entry,std::less<RegionPosition>,std::allocator<std::pair<RegionPosition_const,ThreadSafeSpotNoiseCache::Entry>>>>,std::__map_value_compare<SHA1Digest,std::__value_type<SHA1Digest,std::map<RegionPosition,ThreadSafeSpotNoiseCache::Entry,std::less<RegionPosition>,std::allocator<std::pair<RegionPosition_const,ThreadSafeSpotNoiseCache::Entry>>>>,std::less<SHA1Digest>,true>,std::allocator<std::__value_type<SHA1Digest,std::map<RegionPosition,ThreadSafeSpotNoiseCache::Entry,std::less<RegionPosition>,std::allocator<std::pair<RegionPosition_const,ThreadSafeSpotNoiseCache::Entry>>>>>>
::
__emplace_unique_key_args<SHA1Digest,std::piecewise_construct_t_const&,std::tuple<SHA1Digest_const&>,std::tuple<>>
          (SHA1Digest *param_1,piecewise_construct_t *param_2,tuple *param_3,tuple *param_4)

{
  undefined4 uVar1;
  bool bVar2;
  __tree_node_base *p_Var3;
  SHA1Digest *pSVar4;
  undefined8 *puVar5;
  SHA1Digest *pSVar6;
  SHA1Digest *pSVar7;
  undefined8 uVar8;
  undefined1 auVar9 [16];
  undefined1 auVar10 [16];
  
  pSVar4 = *(SHA1Digest **)(param_1 + 8);
  pSVar6 = param_1 + 8;
  while (pSVar7 = pSVar6, pSVar4 != (SHA1Digest *)0x0) {
    while( true ) {
      pSVar7 = pSVar4;
      bVar2 = operator<[abi:v160006]<unsigned_char,20ul>((array *)param_2,(array *)(pSVar7 + 0x20));
      if (bVar2) break;
      bVar2 = operator<[abi:v160006]<unsigned_char,20ul>((array *)(pSVar7 + 0x20),(array *)param_2);
      if (!bVar2) {
        if (*(ulong *)pSVar6 != 0) {
          auVar10._8_8_ = 0;
          auVar10._0_8_ = *(ulong *)pSVar6;
          return auVar10;
        }
        goto LAB_102266dcc;
      }
      pSVar6 = pSVar7 + 8;
      pSVar4 = *(SHA1Digest **)pSVar6;
      if (*(SHA1Digest **)pSVar6 == (SHA1Digest *)0x0) goto LAB_102266dcc;
    }
    pSVar6 = pSVar7;
    pSVar4 = *(SHA1Digest **)pSVar7;
  }
LAB_102266dcc:
  auVar9._0_8_ = operator_new(0x50);
  puVar5 = *(undefined8 **)param_4;
  uVar1 = *(undefined4 *)(puVar5 + 2);
  uVar8 = *puVar5;
  *(undefined8 *)(auVar9._0_8_ + 0x28) = puVar5[1];
  *(undefined8 *)(auVar9._0_8_ + 0x20) = uVar8;
  *(undefined4 *)(auVar9._0_8_ + 0x30) = uVar1;
  *(undefined8 *)(auVar9._0_8_ + 0x48) = 0;
  *(undefined8 *)(auVar9._0_8_ + 0x40) = 0;
  *(__tree_node_base **)(auVar9._0_8_ + 0x38) = auVar9._0_8_ + 0x40;
  *(undefined8 *)auVar9._0_8_ = 0;
  *(undefined8 *)(auVar9._0_8_ + 8) = 0;
  *(SHA1Digest **)(auVar9._0_8_ + 0x10) = pSVar7;
  *(__tree_node_base **)pSVar6 = auVar9._0_8_;
  p_Var3 = auVar9._0_8_;
  if (**(long **)param_1 != 0) {
    *(long *)param_1 = **(long **)param_1;
    p_Var3 = *(__tree_node_base **)pSVar6;
  }
  __tree_balance_after_insert_abi_v160006_<std::__tree_node_base<void*>*>
            (*(__tree_node_base **)(param_1 + 8),p_Var3);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 1;
  auVar9._8_8_ = 1;
  return auVar9;
}



// ===== __tree_balance_after_insert[abi:v160006]<std::__tree_node_base<void*>*>  @ 0x101b51c40 =====

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* void 
   std::__tree_balance_after_insert[abi:v160006]<std::__tree_node_base<void*>*>(std::__tree_node_base<void*>*,
   std::__tree_node_base<void*>*) */

void std::__tree_balance_after_insert_abi_v160006_<std::__tree_node_base<void*>*>
               (__tree_node_base *param_1,__tree_node_base *param_2)

{
  __tree_node_base _Var1;
  __tree_node_base *p_Var2;
  __tree_node_base *p_Var3;
  long *plVar4;
  long lVar5;
  __tree_node_base *p_Var6;
  
  _Var1 = (__tree_node_base)(param_2 == param_1);
  param_2[0x18] = _Var1;
  while( true ) {
    if ((bool)_Var1) {
      return;
    }
    p_Var3 = *(__tree_node_base **)(param_2 + 0x10);
    if (p_Var3[0x18] != (__tree_node_base)0x0) break;
    p_Var2 = *(__tree_node_base **)(p_Var3 + 0x10);
    p_Var6 = *(__tree_node_base **)p_Var2;
    if (p_Var6 == p_Var3) {
      if ((*(long *)(p_Var2 + 8) == 0) ||
         (p_Var6 = (__tree_node_base *)(*(long *)(p_Var2 + 8) + 0x18),
         *p_Var6 != (__tree_node_base)0x0)) {
        if (*(__tree_node_base **)p_Var3 == param_2) {
          p_Var3[0x18] = (__tree_node_base)0x1;
          p_Var2[0x18] = (__tree_node_base)0x0;
          lVar5 = *(long *)(p_Var3 + 8);
          *(long *)p_Var2 = lVar5;
        }
        else {
          plVar4 = *(long **)(p_Var3 + 8);
          lVar5 = *plVar4;
          *(long *)(p_Var3 + 8) = lVar5;
          if (lVar5 != 0) {
            *(__tree_node_base **)(lVar5 + 0x10) = p_Var3;
            p_Var2 = *(__tree_node_base **)(p_Var3 + 0x10);
          }
          plVar4[2] = (long)p_Var2;
          (*(undefined8 **)(p_Var3 + 0x10))
          [(__tree_node_base *)**(undefined8 **)(p_Var3 + 0x10) != p_Var3] = plVar4;
          *plVar4 = (long)p_Var3;
          *(long **)(p_Var3 + 0x10) = plVar4;
          p_Var2 = (__tree_node_base *)plVar4[2];
          p_Var3 = *(__tree_node_base **)p_Var2;
          *(undefined1 *)(plVar4 + 3) = 1;
          p_Var2[0x18] = (__tree_node_base)0x0;
          lVar5 = *(long *)(p_Var3 + 8);
          *(long *)p_Var2 = lVar5;
        }
        if (lVar5 != 0) {
          *(__tree_node_base **)(lVar5 + 0x10) = p_Var2;
        }
        *(long *)(p_Var3 + 0x10) = *(long *)(p_Var2 + 0x10);
        (*(undefined8 **)(p_Var2 + 0x10))
        [(__tree_node_base *)**(undefined8 **)(p_Var2 + 0x10) != p_Var2] = p_Var3;
        *(__tree_node_base **)(p_Var3 + 8) = p_Var2;
        *(__tree_node_base **)(p_Var2 + 0x10) = p_Var3;
        return;
      }
    }
    else if ((p_Var6 == (__tree_node_base *)0x0) ||
            (p_Var6 = p_Var6 + 0x18, *p_Var6 != (__tree_node_base)0x0)) {
      if (*(__tree_node_base **)p_Var3 == param_2) {
        lVar5 = *(long *)(param_2 + 8);
        *(long *)p_Var3 = lVar5;
        if (lVar5 != 0) {
          *(__tree_node_base **)(lVar5 + 0x10) = p_Var3;
          p_Var2 = *(__tree_node_base **)(p_Var3 + 0x10);
        }
        *(__tree_node_base **)(param_2 + 0x10) = p_Var2;
        (*(undefined8 **)(p_Var3 + 0x10))
        [(__tree_node_base *)**(undefined8 **)(p_Var3 + 0x10) != p_Var3] = param_2;
        *(__tree_node_base **)(param_2 + 8) = p_Var3;
        *(__tree_node_base **)(p_Var3 + 0x10) = param_2;
        p_Var2 = *(__tree_node_base **)(param_2 + 0x10);
        p_Var3 = param_2;
      }
      p_Var3[0x18] = (__tree_node_base)0x1;
      p_Var2[0x18] = (__tree_node_base)0x0;
      plVar4 = *(long **)(p_Var2 + 8);
      lVar5 = *plVar4;
      *(long *)(p_Var2 + 8) = lVar5;
      if (lVar5 != 0) {
        *(__tree_node_base **)(lVar5 + 0x10) = p_Var2;
      }
      plVar4[2] = *(long *)(p_Var2 + 0x10);
      (*(undefined8 **)(p_Var2 + 0x10))
      [(__tree_node_base *)**(undefined8 **)(p_Var2 + 0x10) != p_Var2] = plVar4;
      *plVar4 = (long)p_Var2;
      *(long **)(p_Var2 + 0x10) = plVar4;
      return;
    }
    p_Var3[0x18] = (__tree_node_base)0x1;
    _Var1 = (__tree_node_base)(p_Var2 == param_1);
    p_Var2[0x18] = _Var1;
    *p_Var6 = (__tree_node_base)0x1;
    param_2 = p_Var2;
  }
  return;
}



// ===== runGarbageCollection  @ 0x1015e602c =====

/* ThreadSafeSpotNoiseCache::runGarbageCollection(SHA1Digest const&) */

void __thiscall
ThreadSafeSpotNoiseCache::runGarbageCollection(ThreadSafeSpotNoiseCache *this,SHA1Digest *param_1)

{
  long lVar1;
  bool bVar2;
  long lVar3;
  long *plVar4;
  __tree_node_base *p_Var5;
  __tree<std::__value_type<RegionPosition,ThreadSafeSpotNoiseCache::Entry>,std::__map_value_compare<RegionPosition,std::__value_type<RegionPosition,ThreadSafeSpotNoiseCache::Entry>,std::less<RegionPosition>,true>,std::allocator<std::__value_type<RegionPosition,ThreadSafeSpotNoiseCache::Entry>>>
  *this_00;
  __tree_node_base *p_Var6;
  __tree_node_base *p_Var7;
  __tree_node_base *p_Var8;
  __tree_node_base *p_Var9;
  
  *(undefined4 *)(this + 0x58) = 0;
  p_Var6 = *(__tree_node_base **)(this + 0x40);
joined_r0x0001015e6058:
  do {
    if (p_Var6 == (__tree_node_base *)(this + 0x48)) {
      return;
    }
    this_00 = (__tree<std::__value_type<RegionPosition,ThreadSafeSpotNoiseCache::Entry>,std::__map_value_compare<RegionPosition,std::__value_type<RegionPosition,ThreadSafeSpotNoiseCache::Entry>,std::less<RegionPosition>,true>,std::allocator<std::__value_type<RegionPosition,ThreadSafeSpotNoiseCache::Entry>>>
               *)(p_Var6 + 0x38);
    p_Var8 = *(__tree_node_base **)this_00;
    while (p_Var8 != p_Var6 + 0x40) {
      if (p_Var8[0x30] == (__tree_node_base)0x0) {
        p_Var5 = *(__tree_node_base **)(p_Var8 + 8);
        p_Var7 = p_Var8;
        if (*(__tree_node_base **)(p_Var8 + 8) == (__tree_node_base *)0x0) {
          do {
            p_Var9 = *(__tree_node_base **)(p_Var7 + 0x10);
            bVar2 = *(__tree_node_base **)p_Var9 != p_Var7;
            p_Var7 = p_Var9;
          } while (bVar2);
        }
        else {
          do {
            p_Var9 = p_Var5;
            p_Var5 = *(__tree_node_base **)p_Var9;
          } while (*(__tree_node_base **)p_Var9 != (__tree_node_base *)0x0);
        }
        if (*(__tree_node_base **)this_00 == p_Var8) {
          *(__tree_node_base **)this_00 = p_Var9;
        }
        *(long *)(p_Var6 + 0x48) = *(long *)(p_Var6 + 0x48) + -1;
        std::__tree_remove_abi_v160006_<std::__tree_node_base<void*>*>
                  (*(__tree_node_base **)(p_Var6 + 0x40),p_Var8);
        plVar4 = *(long **)(p_Var8 + 0x28);
        if (plVar4 != (long *)0x0) {
          LOAcquire();
          lVar3 = plVar4[1];
          plVar4[1] = lVar3 + -1;
          LORelease();
          if (lVar3 == 0) {
            (**(code **)(*plVar4 + 0x10))();
          }
        }
        operator_delete(p_Var8);
        p_Var8 = p_Var9;
      }
      else {
        p_Var8[0x30] = (__tree_node_base)0x0;
        p_Var5 = *(__tree_node_base **)(p_Var8 + 8);
        p_Var7 = p_Var8;
        if (*(__tree_node_base **)(p_Var8 + 8) == (__tree_node_base *)0x0) {
          do {
            p_Var8 = *(__tree_node_base **)(p_Var7 + 0x10);
            bVar2 = *(__tree_node_base **)p_Var8 != p_Var7;
            p_Var7 = p_Var8;
          } while (bVar2);
        }
        else {
          do {
            p_Var8 = p_Var5;
            p_Var5 = *(__tree_node_base **)p_Var8;
          } while (*(__tree_node_base **)p_Var8 != (__tree_node_base *)0x0);
        }
      }
    }
    lVar3 = 0;
    if (*(long *)(p_Var6 + 0x48) == 0) {
      do {
        lVar1 = lVar3 + 0x20;
        p_Var8 = (__tree_node_base *)(param_1 + lVar3);
        if (lVar3 == 0x13) break;
        lVar3 = lVar3 + 1;
      } while (p_Var6[lVar1] == *p_Var8);
      if (p_Var6[lVar1] != *p_Var8) {
        p_Var8 = *(__tree_node_base **)(p_Var6 + 8);
        p_Var5 = p_Var6;
        if (*(__tree_node_base **)(p_Var6 + 8) == (__tree_node_base *)0x0) {
          do {
            p_Var7 = *(__tree_node_base **)(p_Var5 + 0x10);
            bVar2 = *(__tree_node_base **)p_Var7 != p_Var5;
            p_Var5 = p_Var7;
          } while (bVar2);
        }
        else {
          do {
            p_Var7 = p_Var8;
            p_Var8 = *(__tree_node_base **)p_Var7;
          } while (*(__tree_node_base **)p_Var7 != (__tree_node_base *)0x0);
        }
        if (*(__tree_node_base **)(this + 0x40) == p_Var6) {
          *(__tree_node_base **)(this + 0x40) = p_Var7;
        }
        *(long *)(this + 0x50) = *(long *)(this + 0x50) + -1;
        std::__tree_remove_abi_v160006_<std::__tree_node_base<void*>*>
                  (*(__tree_node_base **)(this + 0x48),p_Var6);
        std::
        __tree<std::__value_type<RegionPosition,ThreadSafeSpotNoiseCache::Entry>,std::__map_value_compare<RegionPosition,std::__value_type<RegionPosition,ThreadSafeSpotNoiseCache::Entry>,std::less<RegionPosition>,true>,std::allocator<std::__value_type<RegionPosition,ThreadSafeSpotNoiseCache::Entry>>>
        ::destroy(this_00,*(__tree_node **)(p_Var6 + 0x40));
        operator_delete(p_Var6);
        p_Var6 = p_Var7;
        goto joined_r0x0001015e6058;
      }
    }
    p_Var8 = *(__tree_node_base **)(p_Var6 + 8);
    p_Var5 = p_Var6;
    if (*(__tree_node_base **)(p_Var6 + 8) == (__tree_node_base *)0x0) {
      do {
        p_Var6 = *(__tree_node_base **)(p_Var5 + 0x10);
        bVar2 = *(__tree_node_base **)p_Var6 != p_Var5;
        p_Var5 = p_Var6;
      } while (bVar2);
    }
    else {
      do {
        p_Var6 = p_Var8;
        p_Var8 = *(__tree_node_base **)p_Var6;
      } while (*(__tree_node_base **)p_Var6 != (__tree_node_base *)0x0);
    }
  } while( true );
}



// ===== __sub_wait  @ 0x100023cb8 =====

/* std::__assoc_sub_state::__sub_wait(std::unique_lock<std::mutex>&) */

void __thiscall std::__assoc_sub_state::__sub_wait(__assoc_sub_state *this,unique_lock *param_1)

{
  ulong uVar1;
  
  uVar1 = __is_ready_abi_v160006_(this);
  if ((uVar1 & 1) == 0) {
    if ((*(uint *)(this + 0x88) & 8) == 0) {
      while (uVar1 = __is_ready_abi_v160006_(this), (uVar1 & 1) == 0) {
        condition_variable::wait((condition_variable *)(this + 0x58),param_1);
      }
    }
    else {
      *(uint *)(this + 0x88) = *(uint *)(this + 0x88) & 0xfffffff7;
      unique_lock<std::mutex>::unlock((unique_lock<std::mutex> *)param_1);
      (**(code **)(*(long *)this + 0x18))();
    }
  }
  return;
}



// ===== __is_ready[abi:v160006]  @ 0x100023e00 =====

/* std::__assoc_sub_state::__is_ready[abi:v160006]() const */

bool __thiscall std::__assoc_sub_state::__is_ready_abi_v160006_(__assoc_sub_state *this)

{
  return (*(uint *)(this + 0x88) & 4) != 0;
}



// ===== unlock  @ 0x100023e24 =====

/* std::unique_lock<std::mutex>::unlock() */

void __thiscall std::unique_lock<std::mutex>::unlock(unique_lock<std::mutex> *this)

{
  if (((byte)this[8] & 1) == 0) {
    __throw_system_error(1,"unique_lock::unlock: not locked");
  }
  mutex::unlock(*(mutex **)this);
  this[8] = (unique_lock<std::mutex>)0x0;
  return;
}



// ===== wait  @ 0x100022624 =====

/* std::condition_variable::wait(std::unique_lock<std::mutex>&) */

void __thiscall std::condition_variable::wait(condition_variable *this,unique_lock *param_1)

{
  code *pcVar1;
  int iVar2;
  ulong uVar3;
  mutex *this_00;
  _opaque_pthread_mutex_t *p_Var4;
  
  uVar3 = unique_lock<std::mutex>::owns_lock_abi_v160006_((unique_lock<std::mutex> *)param_1);
  if ((uVar3 & 1) == 0) {
    __throw_system_error(1,"condition_variable::wait: mutex not locked");
                    /* WARNING: Does not return */
    pcVar1 = (code *)SoftwareBreakpoint(1,0x100022668);
    (*pcVar1)();
  }
  this_00 = (mutex *)unique_lock<std::mutex>::mutex_abi_v160006_((unique_lock<std::mutex> *)param_1)
  ;
  p_Var4 = (_opaque_pthread_mutex_t *)mutex::native_handle_abi_v160006_(this_00);
  iVar2 = __libcpp_condvar_wait_abi_v160006_((_opaque_pthread_cond_t *)this,p_Var4);
  if (iVar2 != 0) {
    __throw_system_error(iVar2,"condition_variable wait failed");
                    /* WARNING: Does not return */
    pcVar1 = (code *)SoftwareBreakpoint(1,0x1000226c4);
    (*pcVar1)();
  }
  return;
}



// ===== computeRegionBounds  @ 0x101611020 =====

/* NoiseOperations::SpotNoise::computeRegionBounds(NoiseCache&) const */

float __thiscall
NoiseOperations::SpotNoise::computeRegionBounds(SpotNoise *this,NoiseCache *param_1)

{
  int iVar1;
  float *pfVar2;
  float *pfVar3;
  long lVar4;
  float fVar5;
  float fVar6;
  float fVar7;
  float fVar8;
  float fVar9;
  float fVar10;
  float fVar11;
  float fVar12;
  
  iVar1 = *(int *)(this + 0x10);
  if ((iVar1 == 1 && *(int *)(this + 0xc) == 0) && param_1[0x28] != (NoiseCache)0x0) {
    fVar6 = *(float *)(param_1 + 0x2c);
  }
  else {
    pfVar2 = (float *)NoiseCache::getFloatRegister(param_1);
    pfVar3 = (float *)NoiseCache::getFloatRegister(param_1,iVar1);
    lVar4 = *(long *)(param_1 + 0x10);
    if (lVar4 == 0) {
      fVar6 = INFINITY;
    }
    else {
      fVar5 = INFINITY;
      fVar7 = INFINITY;
      fVar9 = -INFINITY;
      fVar10 = -INFINITY;
      do {
        fVar11 = *pfVar2;
        fVar6 = fVar11;
        if (fVar5 <= fVar11) {
          fVar6 = fVar5;
        }
        fVar12 = *pfVar3;
        fVar8 = fVar12;
        if (fVar7 <= fVar12) {
          fVar8 = fVar7;
        }
        if (fVar11 <= fVar9) {
          fVar11 = fVar9;
        }
        if (fVar12 <= fVar10) {
          fVar12 = fVar10;
        }
        lVar4 = lVar4 + -1;
        pfVar3 = pfVar3 + 1;
        pfVar2 = pfVar2 + 1;
        fVar5 = fVar6;
        fVar7 = fVar8;
        fVar9 = fVar11;
        fVar10 = fVar12;
      } while (lVar4 != 0);
    }
  }
  return fVar6 - *(float *)(this + 0x54);
}



// ===== SpotNoise  @ 0x10160f924 =====

/* WARNING: Removing unreachable block (ram,0x00010160fe68) */
/* NoiseOperations::SpotNoise::SpotNoise(NoiseRegisterIndex, std::array<NoiseRegisterIndex, 2ul>
   const&, std::array<NoiseExpressionConstant, 11ul> const&, std::array<NoiseRegisterIndex, 4ul>
   const&, NoiseProgram&&, MapGenSettings const*) */

SpotNoise * __thiscall
NoiseOperations::SpotNoise::SpotNoise
          (SpotNoise *this,undefined4 param_2,undefined8 *param_3,char *param_4,undefined4 *param_5,
          undefined4 *param_6,MapGenSettings *param_7)

{
  uint uVar1;
  RuntimeError *pRVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  char cVar6;
  SpotNoise SVar7;
  char *pcVar8;
  undefined8 uVar9;
  double dVar10;
  string asStack_48 [24];
  
  uVar9 = *param_3;
  *(undefined4 *)(this + 8) = param_2;
  *(undefined8 *)(this + 0xc) = uVar9;
  *(undefined ***)this = &PTR__SpotNoise_102f85cb8;
  *(undefined4 *)(this + 0x18) = *param_6;
  *(undefined8 *)(this + 0x28) = 0;
  *(undefined8 *)(this + 0x30) = 0;
  *(undefined8 *)(this + 0x20) = 0;
  uVar9 = *(undefined8 *)(param_6 + 2);
  *(undefined8 *)(this + 0x28) = *(undefined8 *)(param_6 + 4);
  *(undefined8 *)(this + 0x20) = uVar9;
  *(undefined8 *)(this + 0x30) = *(undefined8 *)(param_6 + 6);
  *(undefined8 *)(param_6 + 4) = 0;
  *(undefined8 *)(param_6 + 6) = 0;
  *(undefined8 *)(param_6 + 2) = 0;
  *(undefined4 *)(this + 0x38) = *param_5;
  *(undefined4 *)(this + 0x3c) = param_5[1];
  *(undefined4 *)(this + 0x40) = param_5[2];
  *(undefined4 *)(this + 0x44) = param_5[3];
  if (*param_4 != '\x01') {
    uVar9 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(param_4,"seed0");
    goto LAB_1016101e0;
  }
  dVar10 = *(double *)(param_4 + 8);
  if (NAN(dVar10)) {
    *(undefined4 *)(this + 0x48) = 0;
    cVar6 = param_4[0x20];
  }
  else {
    iVar4 = 0;
    if (0.0 < dVar10) {
      iVar4 = (int)dVar10;
    }
    iVar5 = -1;
    if (dVar10 < 4294967295.0) {
      iVar5 = iVar4;
    }
    *(int *)(this + 0x48) = iVar5;
    cVar6 = param_4[0x20];
  }
  if (cVar6 != '\x01') {
    uVar9 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(param_4 + 0x20,"seed1");
    goto LAB_1016101e0;
  }
  dVar10 = *(double *)(param_4 + 0x28);
  if (NAN(dVar10)) {
LAB_10160fbb0:
    *(undefined4 *)(this + 0x4c) = 0;
    cVar6 = param_4[0x40];
  }
  else if (4294967295.0 <= dVar10) {
    *(undefined4 *)(this + 0x4c) = 0xffffffff;
    cVar6 = param_4[0x40];
  }
  else {
    if (dVar10 <= 0.0) goto LAB_10160fbb0;
    *(int *)(this + 0x4c) = (int)dVar10;
    cVar6 = param_4[0x40];
  }
  if (cVar6 != '\x01') {
    uVar9 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(param_4 + 0x40,"basement_value");
    goto LAB_1016101e0;
  }
  cVar6 = param_4[0x60];
  *(float *)(this + 0x50) = (float)*(double *)(param_4 + 0x48);
  if (cVar6 != '\x01') {
    uVar9 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(param_4 + 0x60,"maximum_spot_basement_radius")
    ;
    goto LAB_1016101e0;
  }
  pcVar8 = param_4 + 0x80;
  cVar6 = *pcVar8;
  *(float *)(this + 0x54) = (float)*(double *)(param_4 + 0x68);
  if (cVar6 != '\x01') {
    uVar9 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(pcVar8,"region_size");
    goto LAB_1016101e0;
  }
  dVar10 = *(double *)(param_4 + 0x88);
  if (NAN(dVar10)) {
LAB_10160fbf4:
    iVar4 = 0;
    *(undefined4 *)(this + 0x58) = 0;
    *(undefined4 *)(this + 0x5c) = 0x100;
    cVar6 = param_4[0xa0];
  }
  else if (4294967295.0 <= dVar10) {
    iVar4 = -1;
    *(undefined4 *)(this + 0x58) = 0xffffffff;
    *(undefined4 *)(this + 0x5c) = 0x100;
    cVar6 = param_4[0xa0];
  }
  else {
    if (dVar10 <= 0.0) goto LAB_10160fbf4;
    iVar4 = (int)dVar10;
    *(int *)(this + 0x58) = iVar4;
    *(undefined4 *)(this + 0x5c) = 0x100;
    cVar6 = param_4[0xa0];
  }
  if (cVar6 != '\x01') {
    uVar9 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(param_4 + 0xa0,"skip_offset");
    goto LAB_1016101e0;
  }
  dVar10 = *(double *)(param_4 + 0xa8);
  if (NAN(dVar10)) {
LAB_10160fc40:
    *(undefined4 *)(this + 100) = 0;
    cVar6 = param_4[0xc0];
  }
  else if (4294967295.0 <= dVar10) {
    *(undefined4 *)(this + 100) = 0xffffffff;
    cVar6 = param_4[0xc0];
  }
  else {
    if (dVar10 <= 0.0) goto LAB_10160fc40;
    *(int *)(this + 100) = (int)dVar10;
    cVar6 = param_4[0xc0];
  }
  if (cVar6 != '\x01') {
    uVar9 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(param_4 + 0xc0,"skip_span");
    goto LAB_1016101e0;
  }
  dVar10 = *(double *)(param_4 + 200);
  if (NAN(dVar10)) {
LAB_10160fc88:
    iVar5 = 0;
    *(undefined4 *)(this + 0x68) = 0;
    cVar6 = param_4[0xe0];
    if (cVar6 == '\0') goto LAB_10160fc9c;
LAB_10160fb98:
    if (cVar6 != '\x01') {
      uVar9 = ___cxa_allocate_exception(0x10);
      NoiseExpressionConstant::getInvalidParameterError
                (param_4 + 0xe0,"hard_region_target_quantity");
      goto LAB_1016101e0;
    }
    SVar7 = (SpotNoise)(0.0 < *(double *)(param_4 + 0xe8));
  }
  else {
    if (4294967295.0 <= dVar10) {
      iVar5 = -1;
      *(undefined4 *)(this + 0x68) = 0xffffffff;
      cVar6 = param_4[0xe0];
    }
    else {
      if (dVar10 <= 0.0) goto LAB_10160fc88;
      iVar5 = (int)dVar10;
      *(int *)(this + 0x68) = iVar5;
      cVar6 = param_4[0xe0];
    }
    if (cVar6 != '\0') goto LAB_10160fb98;
LAB_10160fc9c:
    SVar7 = (SpotNoise)0x1;
  }
  this[0x6c] = SVar7;
  *(undefined8 *)(this + 0x75) = 0;
  *(undefined8 *)(this + 0x6d) = 0;
  *(undefined4 *)(this + 0x7d) = 0;
  if (*pcVar8 != '\x01') {
    uVar9 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(pcVar8,(char *)0x0);
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(uVar9,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  if ((*(double *)(param_4 + 0x88) < 0.0) || (ABS(*(double *)(param_4 + 0x88)) == INFINITY)) {
    pRVar2 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(pRVar2,"SpotNoise::region_size must be >= 0 and can\'t be infinite.")
    ;
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(pRVar2,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  if (param_4[0xa0] != '\x01') {
    uVar9 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(param_4 + 0xa0,(char *)0x0);
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(uVar9,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  if ((*(double *)(param_4 + 0xa8) < 0.0) || (ABS(*(double *)(param_4 + 0xa8)) == INFINITY)) {
    pRVar2 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(pRVar2,"SpotNoise::skip_offset must be >= 0 and can\'t be infinite.")
    ;
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(pRVar2,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  if (param_4[0xc0] != '\x01') {
    uVar9 = ___cxa_allocate_exception(0x10);
    NoiseExpressionConstant::getInvalidParameterError(param_4 + 0xc0,(char *)0x0);
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(uVar9,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  if ((*(double *)(param_4 + 200) < 0.0) || (ABS(*(double *)(param_4 + 200)) == INFINITY)) {
    pRVar2 = (RuntimeError *)___cxa_allocate_exception(0x10);
    RuntimeError::RuntimeError(pRVar2,"SpotNoise::skip_span must be >= 0 and can\'t be infinite.");
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(pRVar2,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  }
  if (param_4[0x100] == '\0') {
    if (param_4[0x120] != '\0') {
      if (param_4[0x120] != '\x01') {
        uVar9 = ___cxa_allocate_exception(0x10);
        NoiseExpressionConstant::getInvalidParameterError(param_4 + 0x120,"candidate_spot_count");
        goto LAB_1016101e0;
      }
      dVar10 = *(double *)(param_4 + 0x128);
      if (NAN(dVar10)) {
LAB_10160fe88:
        uVar3 = 0;
        *(undefined4 *)(this + 0x5c) = 0;
      }
      else {
        if (4294967295.0 <= dVar10) {
          uVar3 = -iVar5;
          *(uint *)(this + 0x5c) = uVar3;
        }
        else {
          if (dVar10 <= 0.0) goto LAB_10160fe88;
          uVar3 = (int)dVar10 * iVar5;
          *(uint *)(this + 0x5c) = uVar3;
        }
joined_r0x00010160fd7c:
        if (10000 < uVar3) {
LAB_10160fea0:
          pRVar2 = (RuntimeError *)___cxa_allocate_exception(0x10);
          ssprintf("candidate_point_count (%u; skipSpan=%u) too high",asStack_48);
          RuntimeError::RuntimeError(pRVar2,asStack_48);
                    /* WARNING: Subroutine does not return */
          ___cxa_throw(pRVar2,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
        }
      }
      goto LAB_10160fd80;
    }
    uVar3 = 0x100;
    cVar6 = param_4[0x140];
  }
  else {
    if (param_4[0x100] != '\x01') {
      uVar9 = ___cxa_allocate_exception(0x10);
      NoiseExpressionConstant::getInvalidParameterError(param_4 + 0x100,"candidate_point_count");
      goto LAB_1016101e0;
    }
    dVar10 = *(double *)(param_4 + 0x108);
    if (!NAN(dVar10)) {
      if (4294967295.0 <= dVar10) {
        *(undefined4 *)(this + 0x5c) = 0xffffffff;
        goto LAB_10160fea0;
      }
      if (0.0 < dVar10) {
        uVar3 = (uint)dVar10;
        *(uint *)(this + 0x5c) = uVar3;
        goto joined_r0x00010160fd7c;
      }
    }
    uVar3 = 0;
    *(undefined4 *)(this + 0x5c) = 0;
LAB_10160fd80:
    cVar6 = param_4[0x140];
  }
  if (cVar6 == '\0') {
    uVar1 = 0;
    if (uVar3 != 0) {
      uVar1 = (uint)(iVar4 * iVar4) / uVar3;
    }
    dVar10 = SQRT((double)uVar1) * 0.5;
  }
  else {
    if (cVar6 != '\x01') {
      uVar9 = ___cxa_allocate_exception(0x10);
      NoiseExpressionConstant::getInvalidParameterError
                (param_4 + 0x140,"suggested_minimum_candidate_point_spacing");
LAB_1016101e0:
                    /* WARNING: Subroutine does not return */
      ___cxa_throw(uVar9,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
    }
    dVar10 = *(double *)(param_4 + 0x148);
  }
  *(float *)(this + 0x60) = (float)dVar10;
  initializeCacheKey(this,param_7);
  return this;
}



// ===== initializeCacheKey  @ 0x1016102a0 =====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* NoiseOperations::SpotNoise::initializeCacheKey(MapGenSettings const*) */

void __thiscall
NoiseOperations::SpotNoise::initializeCacheKey(SpotNoise *this,MapGenSettings *param_1)

{
  undefined **local_118;
  undefined4 local_110;
  undefined8 local_108;
  undefined8 local_100;
  undefined8 uStack_f8;
  undefined8 uStack_f0;
  undefined8 uStack_e8;
  undefined8 local_e0;
  undefined8 uStack_d8;
  undefined4 local_d0;
  undefined ***local_c8;
  undefined4 local_bc;
  undefined **local_b8;
  undefined8 local_b0;
  undefined8 uStack_a8;
  undefined4 local_70;
  undefined8 local_68;
  undefined8 local_60;
  undefined8 uStack_58;
  undefined8 local_50;
  undefined8 uStack_48;
  undefined4 local_40;
  long local_38;
  
  local_38 = *(long *)PTR____stack_chk_guard_102d481b8;
  local_b8 = &PTR__SHA1WriteStream_102fbc258;
  local_c8 = &local_b8;
  local_68 = 0;
  uStack_58 = _UNK_102971028;
  local_60 = _DAT_102971020;
  uStack_48 = _UNK_102971038;
  local_50 = _DAT_102971030;
  local_40 = 0xca62c1d6;
  local_118 = &PTR__Serialiser_102f95900;
  local_110 = 0;
  uStack_f8 = 0;
  local_100 = 0;
  uStack_e8 = 0;
  uStack_f0 = 0;
  uStack_d8 = 0;
  local_e0 = 0;
  local_d0 = 1;
  uStack_a8 = CONCAT44((int)*(undefined8 *)(this + 100),(int)*(undefined8 *)(this + 0x58));
  local_b0 = *(undefined8 *)(this + 0x48);
  local_70 = 0x10;
  local_108 = 0x10;
  SHA1WriteStream::write((SHA1WriteStream *)&local_b8,(char *)(this + 0x68),4);
  local_108 = 0x14;
  (*(code *)local_b8[2])(&local_b8,this + 0x5c,4);
  local_108 = 0x18;
  (*(code *)local_b8[2])(&local_b8,this + 0x60,4);
  local_108 = 0x1c;
  (*(code *)local_b8[2])(&local_b8,this + 0x6c,1);
  local_108 = 0x1d;
  local_bc = *(undefined4 *)(this + 0x38);
  (*(code *)local_b8[2])(&local_b8,&local_bc,4);
  local_108 = 0x21;
  local_bc = *(undefined4 *)(this + 0x3c);
  (*(code *)local_b8[2])(&local_b8,&local_bc,4);
  local_108 = 0x25;
  local_bc = *(undefined4 *)(this + 0x40);
  (*(code *)local_b8[2])(&local_b8,&local_bc,4);
  local_108 = 0x29;
  local_bc = *(undefined4 *)(this + 0x44);
  (*(code *)local_b8[2])(&local_b8,&local_bc,4);
  local_108 = 0x2d;
  if (param_1 != (MapGenSettings *)0x0) {
    MapGenSettings::save(param_1,(Serialiser *)&local_118);
  }
  SHA1::finalise();
  Serialiser::~Serialiser((Serialiser *)&local_118);
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_38) {
    return;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}



// ===== ~Serialiser  @ 0x10150961c =====

/* Serialiser::~Serialiser() */

Serialiser * __thiscall Serialiser::~Serialiser(Serialiser *this)

{
  __tree<std::__value_type<std::string,unsigned_long>,std::__map_value_compare<std::string,std::__value_type<std::string,unsigned_long>,std::less<std::string>,true>,std::allocator<std::__value_type<std::string,unsigned_long>>>
  *this_00;
  
  *(undefined ***)this = &PTR__Serialiser_102f95900;
  if ((*(int *)(this + 0x48) == 0) && (*(long **)(this + 0x50) != (long *)0x0)) {
    (**(code **)(**(long **)(this + 0x50) + 8))();
  }
  logSavingStatistics(this);
  this_00 = *(__tree<std::__value_type<std::string,unsigned_long>,std::__map_value_compare<std::string,std::__value_type<std::string,unsigned_long>,std::less<std::string>,true>,std::allocator<std::__value_type<std::string,unsigned_long>>>
              **)(this + 0x38);
  *(undefined8 *)(this + 0x38) = 0;
  if (this_00 !=
      (__tree<std::__value_type<std::string,unsigned_long>,std::__map_value_compare<std::string,std::__value_type<std::string,unsigned_long>,std::less<std::string>,true>,std::allocator<std::__value_type<std::string,unsigned_long>>>
       *)0x0) {
    std::
    __tree<std::__value_type<std::string,unsigned_long>,std::__map_value_compare<std::string,std::__value_type<std::string,unsigned_long>,std::less<std::string>,true>,std::allocator<std::__value_type<std::string,unsigned_long>>>
    ::destroy(this_00,*(__tree_node **)(this_00 + 8));
    operator_delete(this_00);
  }
  if (-1 < (char)this[0x37]) {
    return this;
  }
  operator_delete(*(void **)(this + 0x20));
  return this;
}



// ===== finalise  @ 0x101ab586c =====

/* SHA1::finalise() */

void SHA1::finalise(void)

{
  uint uVar1;
  long lVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  uint uVar7;
  undefined4 uVar8;
  SHA1_CTX *in_x0;
  undefined1 *in_x8;
  
  uVar7 = *(uint *)(in_x0 + 0x40);
  in_x0[uVar7] = (SHA1_CTX)0x80;
  uVar1 = uVar7 + 1;
  if (uVar7 < 0x38) {
    if (uVar1 < 0x38) {
      _bzero(in_x0 + (ulong)uVar7 + 1,(ulong)(0x36 - uVar7) + 1);
    }
  }
  else {
    if (uVar1 < 0x40) {
      _bzero(in_x0 + uVar1,(ulong)(0x3e - uVar7) + 1);
    }
    sha1_transform(in_x0,(uchar *)in_x0);
    *(undefined8 *)(in_x0 + 0x30) = 0;
    *(undefined8 *)(in_x0 + 0x18) = 0;
    *(undefined8 *)(in_x0 + 0x10) = 0;
    *(undefined8 *)(in_x0 + 0x28) = 0;
    *(undefined8 *)(in_x0 + 0x20) = 0;
    *(undefined8 *)(in_x0 + 8) = 0;
    *(undefined8 *)in_x0 = 0;
  }
  lVar2 = *(long *)(in_x0 + 0x48) + (ulong)(uint)(*(int *)(in_x0 + 0x40) << 3);
  *(long *)(in_x0 + 0x48) = lVar2;
  in_x0[0x3f] = SUB81(lVar2,0);
  in_x0[0x3e] = SUB81((ulong)lVar2 >> 8,0);
  in_x0[0x3d] = SUB81((ulong)lVar2 >> 0x10,0);
  in_x0[0x3c] = SUB81((ulong)lVar2 >> 0x18,0);
  in_x0[0x3b] = SUB81((ulong)lVar2 >> 0x20,0);
  in_x0[0x3a] = SUB81((ulong)lVar2 >> 0x28,0);
  in_x0[0x39] = SUB81((ulong)lVar2 >> 0x30,0);
  in_x0[0x38] = SUB81((ulong)lVar2 >> 0x38,0);
  sha1_transform(in_x0,(uchar *)in_x0);
  uVar3 = *(undefined4 *)(in_x0 + 0x50);
  uVar5 = *(undefined4 *)(in_x0 + 0x54);
  uVar4 = *(undefined4 *)(in_x0 + 0x58);
  uVar6 = *(undefined4 *)(in_x0 + 0x5c);
  uVar8 = *(undefined4 *)(in_x0 + 0x60);
  *in_x8 = (char)((uint)uVar3 >> 0x18);
  in_x8[4] = (char)((uint)uVar5 >> 0x18);
  in_x8[8] = (char)((uint)uVar4 >> 0x18);
  in_x8[0xc] = (char)((uint)uVar6 >> 0x18);
  in_x8[0x10] = (char)((uint)uVar8 >> 0x18);
  in_x8[1] = (char)((uint)uVar3 >> 0x10);
  in_x8[5] = (char)((uint)uVar5 >> 0x10);
  in_x8[9] = (char)((uint)uVar4 >> 0x10);
  in_x8[0xd] = (char)((uint)uVar6 >> 0x10);
  in_x8[0x11] = (char)((uint)uVar8 >> 0x10);
  in_x8[2] = (char)((uint)uVar3 >> 8);
  in_x8[6] = (char)((uint)uVar5 >> 8);
  in_x8[10] = (char)((uint)uVar4 >> 8);
  in_x8[0xe] = (char)((uint)uVar6 >> 8);
  in_x8[0x12] = (char)((uint)uVar8 >> 8);
  in_x8[3] = (char)uVar3;
  in_x8[7] = (char)uVar5;
  in_x8[0xb] = (char)uVar4;
  in_x8[0xf] = (char)uVar6;
  in_x8[0x13] = (char)uVar8;
  return;
}



// ===== save  @ 0x1015053e8 =====

/* MapGenSettings::save(Serialiser&) const */

void __thiscall MapGenSettings::save(MapGenSettings *this,Serialiser *param_1)

{
  SerialiserHelper<Serialiser>::
  saveValue<std::string,MapGenSettingsHelpers::FrequencySizeRichness,std::less<std::string>>
            (param_1,(map *)(this + 0x18));
  SerialiserHelper<Serialiser>::
  saveValue<std::string,MapGenSettingsHelpers::AutoplaceSettings,std::less<std::string>>
            (param_1,(map *)(this + 0x30));
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x48,1);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 1;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x4c,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x50,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x54,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x78,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x7c,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x80,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x84,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x88,2);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 2;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x8a,2);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 2;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x70,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x74,1);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 1;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0x75,1);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 1;
  SerialiserHelper<Serialiser>::saveVector<std::vector<MapPosition,std::allocator<MapPosition>>>
            (param_1,(vector *)(this + 0x58));
  SerialiserHelper<Serialiser>::saveValue<std::string,std::string,std::less<std::string>>
            (param_1,(map *)this);
  SerialiserHelper<Serialiser>::saveValue(param_1,(string *)(this + 0x90));
  SerialiserHelper<Serialiser>::saveValue(param_1,(string *)(this + 0xb0));
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 200,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0xcc,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0xd0,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  (**(code **)(**(long **)(param_1 + 0x50) + 0x10))(*(long **)(param_1 + 0x50),this + 0xd4,4);
  *(long *)(param_1 + 0x10) = *(long *)(param_1 + 0x10) + 4;
  MapGenSettingsHelpers::TerritorySettings::save((TerritorySettings *)(this + 0xd8),param_1);
  return;
}



// ===== write  @ 0x101b94a50 =====

/* SHA1WriteStream::write(char const*, unsigned long long) */

void __thiscall SHA1WriteStream::write(SHA1WriteStream *this,char *param_1,ulonglong param_2)

{
  SHA1_CTX *pSVar1;
  uint uVar2;
  
  if (param_2 != 0) {
    pSVar1 = (SHA1_CTX *)(this + 8);
    uVar2 = *(uint *)(this + 0x48);
    do {
      pSVar1[uVar2] = (SHA1_CTX)*param_1;
      uVar2 = *(int *)(this + 0x48) + 1;
      *(uint *)(this + 0x48) = uVar2;
      if (uVar2 == 0x40) {
        sha1_transform(pSVar1,(uchar *)pSVar1);
        uVar2 = 0;
        *(long *)(this + 0x50) = *(long *)(this + 0x50) + 0x200;
        *(undefined4 *)(this + 0x48) = 0;
      }
      param_1 = param_1 + 1;
      param_2 = param_2 - 1;
    } while (param_2 != 0);
  }
  return;
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



// ===== logEnumAndAbortOrThrow<NoiseExpressionConstant::Type>  @ 0x1015dd7c0 =====

/* void Logging::logEnumAndAbortOrThrow<NoiseExpressionConstant::Type>(char const*, unsigned int,
   LogLevel, NoiseExpressionConstant::Type) */

void Logging::logEnumAndAbortOrThrow<NoiseExpressionConstant::Type>(void)

{
                    /* WARNING: Subroutine does not return */
  logAndAbortOrThrow();
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



// ===== runtime_error  @ 0x1000299b0 =====

/* std::runtime_error::runtime_error(char const*) */

runtime_error * __thiscall std::runtime_error::runtime_error(runtime_error *this,char *param_1)

{
  exception::exception_abi_v160006_((exception *)this);
  *(undefined ***)this = &PTR__runtime_error_102d61000;
  __libcpp_refstring::__libcpp_refstring((__libcpp_refstring *)(this + 8),param_1);
  return this;
}



