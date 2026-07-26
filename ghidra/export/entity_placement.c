/* ============================================================================
 * EntityMapGenerationTask::generateEntities @ 0x1014cb5fc — DECODED
 *
 * The per-CHUNK resource placement. Confirms the exact rules crude-oil needs.
 *
 * PER-CHUNK RNG SEED:
 *   seed = chunk_y * 0x1ee3 (7907) + chunk_x * 0x1eef (7919) + 0x3fbe2c
 *   if (seed < 0x156 [342]) seed = 0x155 [341]
 *   rng = taus88(seed, seed, seed)   // == rng.zig Rng.init(seed)
 *   (chunk_y = this+0x64, chunk_x = this+0x60; chunk coords = tile>>5)
 *
 * TWO PASSES over the 32x32 chunk's tiles (tile i -> (x,y) via NoiseCache float
 * registers 0/1 = X/Y; standard row-major fill):
 *
 *  PASS 1 (NO RNG) — pick the winning resource per tile:
 *    for each resource (in patch-list order), for each tile:
 *      fVar35 = probability_register[tile]      // = clamp(all_patches,0,1)*random_penalty
 *      if tile collides with resource (Tile::collisionMasks[type] & res.mask) skip
 *      if fVar35 > best[tile]  (tie -> higher richness wins), and neighbor
 *         tile_restriction ok: best[tile]=fVar35, winner[tile]=res, rich[tile]=richness
 *
 *  PASS 2 (RNG) — iterate tiles in REVERSE index order (i = N-1 .. 0):
 *    if winner[tile] != 0 and winner.count(=*(u32*)(proto+0x400+0x28)) != 0:
 *      repeat `count` times:
 *        r = rng.next()   // s1^s2^s3
 *        if (double)r * 2^-32 < best[tile]:  generateEntityOnTile(...)
 *    (so each WINNING tile consumes `count` draws from the shared per-chunk rng,
 *     in reverse tile order; non-winning tiles consume none.)
 *
 * IMPLICATION FOR EXACT OIL: the rng is shared across ALL resources, consumed
 * only by winning tiles in reverse order. So oil's dot positions depend on which
 * tiles iron/copper/etc win too — exact oil requires per-chunk all-resource
 * generation with this winner selection, not oil alone.
 * ============================================================================ */

/* generateEntities @ 0x1014cb5fc */

/* EntityMapGenerationTask::generateEntities(NoiseCache&) */

void __thiscall
EntityMapGenerationTask::generateEntities(EntityMapGenerationTask *this,NoiseCache *param_1)

{
  long *plVar1;
  uint uVar2;
  ushort uVar3;
  undefined8 *puVar4;
  undefined8 *puVar5;
  size_t sVar6;
  int iVar7;
  long *plVar8;
  ushort *puVar9;
  ushort uVar10;
  ushort uVar11;
  ushort uVar12;
  long lVar13;
  long lVar14;
  undefined8 uVar15;
  undefined8 uVar16;
  undefined8 uVar17;
  code *pcVar18;
  int iVar19;
  long lVar20;
  long lVar21;
  long lVar22;
  long lVar23;
  ulong uVar24;
  long lVar25;
  long lVar26;
  long lVar27;
  ushort *puVar28;
  ulong uVar29;
  uint uVar30;
  ulong uVar31;
  long *plVar32;
  long lVar33;
  byte bVar34;
  byte bVar38;
  byte bVar39;
  float fVar35;
  float fVar36;
  float fVar37;
  byte bVar40;
  byte bVar41;
  byte bVar42;
  byte bVar43;
  byte bVar44;
  undefined8 uVar45;
  EntityMapGenerationTask *pEVar46;
  void *local_e0;
  void *local_d8;
  void *local_c0;
  undefined8 local_a8;
  uint local_a0;
  
  local_a0 = *(int *)(this + 100) * 0x1ee3 + *(int *)(this + 0x60) * 0x1eef + 0x3fbe2c;
  if (local_a0 < 0x156) {
    local_a0 = 0x155;
  }
  local_a8 = CONCAT44(local_a0,local_a0);
  lVar20 = NoiseCache::getFloatRegister(param_1,0);
  lVar21 = NoiseCache::getFloatRegister(param_1,1);
  uVar29 = *(ulong *)(param_1 + 0x10);
  local_c0 = (void *)0x0;
  if (uVar29 == 0) {
    local_e0 = (void *)0x0;
    local_d8 = (void *)0x0;
LAB_1014cb74c:
    uVar29 = DAT_1029732c0;
    uVar17 = DAT_1029732b8;
    uVar16 = DAT_1029732b0;
    uVar15 = DAT_1029732a8;
    plVar32 = (long *)(*(long *)(this + 0x70) + 400);
    if (*(long **)(this + 0x80) != (long *)0x0) {
      plVar32 = *(long **)(this + 0x80);
    }
    plVar8 = (long *)plVar32[1];
    if (plVar8 != (long *)*plVar32) {
      plVar32 = (long *)*plVar32;
      do {
        lVar22 = NoiseCache::getFloatRegister(param_1,(int)plVar32[1]);
        lVar23 = NoiseCache::getFloatRegister(param_1,*(undefined4 *)((long)plVar32 + 0xc));
        lVar33 = *(long *)(param_1 + 0x10);
        if (lVar33 != 0) {
          iVar19 = *(int *)(this + 0x4890);
          iVar7 = *(int *)(this + 0x4894);
          lVar25 = lVar33;
          do {
            lVar25 = lVar25 + -1;
            lVar26 = lVar25 * 4;
            uVar30 = iVar19 + (int)*(float *)(lVar20 + lVar26);
            lVar13 = (ulong)uVar30 * 0xc0 + 0x90;
            uVar2 = iVar7 + (int)*(float *)(lVar21 + lVar26);
            uVar31 = (ulong)uVar2;
            uVar12 = *(ushort *)(this + uVar31 * 2 + lVar13);
            lVar27 = *plVar32;
            if ((*(ulong *)(&Tile::collisionMasks + (ulong)uVar12 * 8) & *(ulong *)(lVar27 + 0x2a8)
                & 0xffffffffffffff) == 0) {
              fVar35 = *(float *)(lVar22 + lVar26);
              if ((*(float *)((long)local_c0 + lVar26) < fVar35) ||
                 ((fVar35 == *(float *)((long)local_c0 + lVar26) &&
                  (*(float *)((long)local_e0 + lVar26) < *(float *)(lVar23 + lVar26))))) {
                puVar28 = *(ushort **)(*(long *)(lVar27 + 0x400) + 0x118);
                puVar9 = *(ushort **)(*(long *)(lVar27 + 0x400) + 0x120);
                if (puVar28 == puVar9) {
LAB_1014cb7f8:
                  *(float *)((long)local_c0 + lVar26) = fVar35;
                  *(long *)((long)local_d8 + lVar25 * 8) = lVar27;
                  *(undefined4 *)((long)local_e0 + lVar26) = *(undefined4 *)(lVar23 + lVar26);
                }
                else {
                  lVar14 = (ulong)(uVar30 - 1) * 0xc0 + 0x90;
                  uVar24 = (ulong)(uVar2 - 1);
                  do {
                    uVar10 = puVar28[8];
                    uVar11 = *puVar28;
                    if (uVar10 == 0) {
                      if (uVar12 == uVar11) goto LAB_1014cb7f8;
                    }
                    else {
                      uVar3 = uVar10;
                      if (*(ushort *)
                           (*(long *)(*(long *)PTR_indexToPrototype_102d4c598 + (ulong)uVar10 * 8) +
                           0x1a0) <=
                          *(ushort *)
                           (*(long *)(*(long *)PTR_indexToPrototype_102d4c598 + (ulong)uVar11 * 8) +
                           0x1a0)) {
                        uVar3 = uVar11;
                        uVar11 = uVar10;
                      }
                      if ((uVar12 == uVar11) &&
                         ((((*(ushort *)(this + uVar24 * 2 + lVar14) == uVar3 ||
                            (*(ushort *)(this + uVar31 * 2 + lVar14) == uVar3)) ||
                           (*(ushort *)(this + (uVar31 + 1) * 2 + lVar14) == uVar3)) ||
                          (*(ushort *)(this + uVar24 * 2 + lVar13) == uVar3)))) goto LAB_1014cb7f8;
                    }
                    puVar28 = puVar28 + 0x10;
                  } while (puVar28 != puVar9);
                }
              }
            }
          } while (lVar25 != 0);
        }
        plVar1 = plVar32 + 2;
        if (plVar1 == plVar8) {
joined_r0x0001014cb9ac:
          while (lVar33 != 0) {
LAB_1014cb9d4:
            lVar33 = lVar33 + -1;
            lVar22 = *(long *)((long)local_d8 + lVar33 * 8);
            if ((lVar22 != 0) && (lVar23 = *(long *)(lVar22 + 0x400), *(int *)(lVar23 + 0x28) != 0))
            {
              uVar30 = 0;
              lVar25 = lVar33 * 4;
              fVar35 = *(float *)(lVar20 + lVar25);
              fVar36 = *(float *)(lVar21 + lVar25);
              fVar37 = *(float *)((long)local_c0 + lVar25);
                    /* WARNING: Load size is inaccurate */
              pEVar46._0_4_ = *(EntityMapGenerationTask **)((long)local_e0 + lVar25);
              do {
                uVar45 = NEON_ushl(local_a8,uVar15,4);
                uVar45 = NEON_ushl(CONCAT17((byte)((ulong)uVar45 >> 0x38) ^
                                            (byte)((ulong)local_a8 >> 0x38),
                                            CONCAT16((byte)((ulong)uVar45 >> 0x30) ^
                                                     (byte)((ulong)local_a8 >> 0x30),
                                                     CONCAT15((byte)((ulong)uVar45 >> 0x28) ^
                                                              (byte)((ulong)local_a8 >> 0x28),
                                                              CONCAT14((byte)((ulong)uVar45 >> 0x20)
                                                                       ^ (byte)((ulong)local_a8 >>
                                                                               0x20),
                                                                       CONCAT13((byte)((ulong)uVar45
                                                                                      >> 0x18) ^
                                                                                (byte)((ulong)
                                                  local_a8 >> 0x18),
                                                  CONCAT12((byte)((ulong)uVar45 >> 0x10) ^
                                                           (byte)((ulong)local_a8 >> 0x10),
                                                           CONCAT11((byte)((ulong)uVar45 >> 8) ^
                                                                    (byte)((ulong)local_a8 >> 8),
                                                                    (byte)uVar45 ^ (byte)local_a8)))
                                                  )))),uVar16,4);
                uVar31 = NEON_ushl(local_a8,uVar17,4);
                uVar31 = uVar31 & uVar29;
                bVar34 = (byte)uVar45 | (byte)uVar31;
                bVar38 = (byte)((ulong)uVar45 >> 8) | (byte)(uVar31 >> 8);
                bVar39 = (byte)((ulong)uVar45 >> 0x10) | (byte)(uVar31 >> 0x10);
                bVar40 = (byte)((ulong)uVar45 >> 0x18) | (byte)(uVar31 >> 0x18);
                bVar41 = (byte)((ulong)uVar45 >> 0x20) | (byte)(uVar31 >> 0x20);
                bVar42 = (byte)((ulong)uVar45 >> 0x28) | (byte)(uVar31 >> 0x28);
                bVar43 = (byte)((ulong)uVar45 >> 0x30) | (byte)(uVar31 >> 0x30);
                bVar44 = (byte)((ulong)uVar45 >> 0x38) | (byte)(uVar31 >> 0x38);
                local_a8 = CONCAT17(bVar44,CONCAT16(bVar43,CONCAT15(bVar42,CONCAT14(bVar41,CONCAT13(
                                                  bVar40,CONCAT12(bVar39,CONCAT11(bVar38,bVar34)))))
                                                  ));
                local_a0 = (local_a0 & 0x7ff0) << 0x11 | (local_a0 ^ local_a0 << 3) >> 0xb;
                if ((double)(CONCAT13(bVar44 ^ bVar40,
                                      CONCAT12(bVar43 ^ bVar39,
                                               CONCAT11(bVar42 ^ bVar38,bVar41 ^ bVar34))) ^
                            local_a0) * 2.3283064365386963e-10 < (double)fVar37) {
                  generateEntityOnTile
                            (pEVar46._0_4_,this,CONCAT44((int)fVar36,(int)fVar35),lVar22,&local_a8);
                  lVar23 = *(long *)(lVar22 + 0x400);
                }
                uVar30 = uVar30 + 1;
              } while (uVar30 < *(uint *)(lVar23 + 0x28));
            }
            *(undefined4 *)((long)local_c0 + lVar33 * 4) = 0xff800000;
            *(undefined8 *)((long)local_d8 + lVar33 * 8) = 0;
          }
        }
        else {
          lVar22 = *(long *)(plVar32[2] + 0x400);
          lVar23 = *(long *)(*plVar32 + 0x400);
          bVar34 = *(byte *)(lVar22 + 0x27);
          puVar4 = *(void **)(lVar22 + 0x10);
          if (-1 < (char)bVar34) {
            puVar4 = (undefined8 *)(lVar22 + 0x10);
          }
          uVar31 = *(ulong *)(lVar22 + 0x18);
          if (-1 < (char)bVar34) {
            uVar31 = (ulong)bVar34;
          }
          bVar34 = *(byte *)(lVar23 + 0x27);
          puVar5 = *(void **)(lVar23 + 0x10);
          if (-1 < (char)bVar34) {
            puVar5 = (undefined8 *)(lVar23 + 0x10);
          }
          uVar24 = *(ulong *)(lVar23 + 0x18);
          if (-1 < (char)bVar34) {
            uVar24 = (ulong)bVar34;
          }
          sVar6 = uVar24;
          if (uVar31 <= uVar24) {
            sVar6 = uVar31;
          }
          if ((sVar6 == 0) || (iVar19 = _memcmp(puVar4,puVar5,sVar6), iVar19 == 0)) {
            if (uVar24 < uVar31 && lVar33 != 0) goto LAB_1014cb9d4;
          }
          else if (-1 < iVar19) goto joined_r0x0001014cb9ac;
        }
        plVar32 = plVar1;
      } while (plVar1 != plVar8);
    }
    if (local_e0 != (void *)0x0) {
      operator_delete(local_e0);
    }
    if (local_d8 != (void *)0x0) {
      operator_delete(local_d8);
    }
    if (local_c0 != (void *)0x0) {
      operator_delete(local_c0);
      return;
    }
    return;
  }
  if (uVar29 >> 0x3e == 0) {
    uVar31 = uVar29 * 4;
    local_c0 = operator_new(uVar31);
    if (uVar31 != 0) {
      _bzero(local_c0,uVar31);
    }
    if (uVar29 >> 0x3d == 0) {
      uVar29 = uVar29 * 8;
      local_d8 = operator_new(uVar29);
      if (uVar29 != 0) {
        _bzero(local_d8,uVar29);
      }
      local_e0 = operator_new(uVar31);
      if (uVar31 != 0) {
        _bzero(local_e0,uVar31);
      }
      _memset_pattern16(local_c0,&DAT_102973120,uVar31);
      goto LAB_1014cb74c;
    }
    std::vector<EntityPrototype_const*,std::allocator<EntityPrototype_const*>>::
    __throw_length_error_abi_v160006_();
  }
  else {
    std::vector<float,std::allocator<float>>::__throw_length_error_abi_v160006_();
  }
                    /* WARNING: Does not return */
  pcVar18 = (code *)SoftwareBreakpoint(1,0x1014cbb40);
  (*pcVar18)();
}



/* getFloatRegister @ 0x1014b34a4 */

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



/* ___cxa_allocate_exception @ 0x1000ec8f0 */

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



/* ___cxa_throw @ 0x1000ecc60 */

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



/* ssprintf @ 0x1025ecd68 */

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



/* RuntimeError @ 0x1000f158c */

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



/* _memcmp @ 0x1027db634 */

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

int _memcmp(void *param_1,void *param_2,size_t param_3)

{
  int iVar1;
  
                    /* WARNING: Could not recover jumptable at 0x0001027db63c. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  iVar1 = (*(code *)PTR__memcmp_10309cd38)((int)param_1);
  return iVar1;
}



/* __throw_length_error[abi:v160006] @ 0x101b897dc */

/* std::vector<EntityPrototype const*, std::allocator<EntityPrototype const*>
   >::__throw_length_error[abi:v160006]() const */

void std::vector<EntityPrototype_const*,std::allocator<EntityPrototype_const*>>::
     __throw_length_error_abi_v160006_(void)

{
                    /* WARNING: Subroutine does not return */
  std::__throw_length_error_abi_v160006_("vector");
}



/* __throw_length_error[abi:v160006] @ 0x100032b00 */

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* std::__throw_length_error[abi:v160006](char const*) */

void std::__throw_length_error_abi_v160006_(char *param_1)

{
  length_error *this;
  
  this = (length_error *)___cxa_allocate_exception(0x10);
  length_error::length_error_abi_v160006_(this,param_1);
                    /* WARNING: Subroutine does not return */
  ___cxa_throw(this,&length_error::typeinfo,length_error::~length_error);
}



/* _memset_pattern16 @ 0x1027db664 */

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void _memset_pattern16(void *param_1,void *param_2,size_t param_3)

{
                    /* WARNING: Could not recover jumptable at 0x0001027db66c. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  (*(code *)PTR__memset_pattern16_10309cd58)();
  return;
}



/* generateEntityOnTile @ 0x1014cd43c */

/* EntityMapGenerationTask::generateEntityOnTile(TilePosition, EntityPrototype const&, float,
   RandomGenerator&) */

void __thiscall
EntityMapGenerationTask::generateEntityOnTile
          (EntityMapGenerationTask *param_1,EntityMapGenerationTask *this,undefined8 param_3,
          long *param_4,uint *param_5)

{
  long lVar1;
  uint uVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  uint uVar7;
  uint uVar8;
  char cVar9;
  int iVar10;
  long lVar11;
  uint uVar12;
  ulong local_68;
  
  cVar9 = *(char *)(param_4[0x80] + 0x148);
  lVar1 = param_4[0x80] + 0x130;
  if (cVar9 != '\0') {
    lVar1 = 0;
  }
  iVar10 = (int)param_3 << 8;
  uVar12 = (uint)((ulong)param_3 >> 0x18);
  local_68 = CONCAT44(uVar12,iVar10) & 0xffffff00ffffffff;
  lVar11 = (**(code **)(*param_4 + 0x4a8))(param_4);
  if (lVar11 == 0) {
    if ((*(byte *)(param_4 + 0x57) >> 4 & 1) == 0) {
      local_68 = (**(code **)(*param_4 + 0x120))(param_4,&local_68,0);
    }
    else {
      uVar6 = *param_5;
      uVar7 = param_5[1];
      uVar2 = uVar6 << 0xc & 0xffffe000 | (uVar6 ^ uVar6 << 0xd) >> 0x13;
      uVar3 = uVar7 << 4 & 0xffffff80 | (uVar7 ^ uVar7 << 2) >> 0x19;
      uVar8 = param_5[2];
      uVar5 = uVar8 ^ uVar8 << 3;
      uVar8 = (uVar8 & 0x7ff0) << 0x11 | uVar5 >> 0xb;
      uVar4 = (uVar2 & 0xffffe) << 0xc | (uVar6 << 0xc ^ uVar2 << 0xd) >> 0x13;
      uVar6 = (uVar7 << 4 ^ uVar7 << 6) >> 0x19 | (uVar3 >> 3) << 7;
      *param_5 = uVar4;
      param_5[1] = uVar6;
      uVar5 = (uVar5 & 0x3ff8000) << 6 | (uVar8 ^ uVar8 << 3) >> 0xb;
      param_5[2] = uVar5;
      local_68 = CONCAT44((uVar12 & 0xffffff00) +
                          (int)((double)(uVar6 ^ uVar4 ^ uVar5) * 2.3283064365386963e-10 * 256.0),
                          (int)local_68 +
                          (int)((double)(uVar3 ^ uVar2 ^ uVar8) * 2.3283064365386963e-10 * 256.0)) &
                 0xfffffff0fffffff0;
    }
    tryToAddEntity(param_1._0_4_,this,local_68,0,param_4,cVar9,lVar1);
  }
  else {
    local_68 = CONCAT44(uVar12,iVar10) & 0xffffff00ffffffff | 0x8000000080;
    if (0.0 < (float)param_1._0_4_) {
      tryToAddEntity(param_1._0_4_,this,local_68,0,param_4,cVar9,lVar1);
      return;
    }
  }
  return;
}



/* tryToAddEntity @ 0x1014cd868 */

/* EntityMapGenerationTask::tryToAddEntity(MapPosition, Direction, EntityPrototype const&, ForceID,
   float, std::string const*) */

uint __thiscall
EntityMapGenerationTask::tryToAddEntity
          (undefined4 param_1,EntityMapGenerationTask *this,undefined8 param_3,undefined1 param_4,
          long param_5,undefined1 param_6,undefined8 param_7)

{
  undefined8 *puVar1;
  ulong uVar2;
  undefined8 *puVar3;
  undefined2 uVar4;
  uint uVar5;
  void *pvVar6;
  long lVar7;
  long lVar8;
  undefined8 *puVar9;
  ulong uVar10;
  undefined8 *puVar11;
  undefined8 *puVar12;
  undefined8 uVar13;
  undefined8 uVar14;
  
  uVar5 = wouldCollide(this,param_5 + 0x244,*(undefined8 *)(param_5 + 0x2a8),param_3,param_4);
  if ((uVar5 & 1) == 0) {
    uVar4 = *(undefined2 *)(param_5 + 0x188);
    puVar11 = *(undefined8 **)(this + 0x20);
    if (puVar11 < *(undefined8 **)(this + 0x28)) {
      *puVar11 = param_7;
      *(undefined4 *)(puVar11 + 1) = param_1;
      *(undefined2 *)((long)puVar11 + 0xc) = uVar4;
      *(undefined1 *)((long)puVar11 + 0xe) = param_6;
      *(undefined1 *)((long)puVar11 + 0xf) = param_4;
      puVar11[2] = param_3;
      *(undefined8 **)(this + 0x20) = puVar11 + 3;
    }
    else {
      puVar12 = *(undefined8 **)(this + 0x18);
      lVar8 = (long)puVar11 - (long)puVar12 >> 3;
      uVar2 = lVar8 * -0x5555555555555555 + 1;
      if (0xaaaaaaaaaaaaaaa < uVar2) {
        std::
        vector<EntityMapGenerationTask::EntityAddition,std::allocator<EntityMapGenerationTask::EntityAddition>>
        ::__throw_length_error_abi_v160006_();
LAB_1014cda1c:
                    /* WARNING: Subroutine does not return */
        std::__throw_bad_array_new_length_abi_v160006_();
      }
      lVar7 = (long)*(undefined8 **)(this + 0x28) - (long)puVar12 >> 3;
      uVar10 = lVar7 * 0x5555555555555556;
      if (uVar10 < uVar2 || uVar10 - uVar2 == 0) {
        uVar10 = uVar2;
      }
      if (0x555555555555554 < (ulong)(lVar7 * -0x5555555555555555)) {
        uVar10 = 0xaaaaaaaaaaaaaaa;
      }
      if (uVar10 == 0) {
        pvVar6 = (void *)0x0;
      }
      else {
        if (0xaaaaaaaaaaaaaaa < uVar10) goto LAB_1014cda1c;
        pvVar6 = operator_new(uVar10 * 0x18);
      }
      puVar9 = (undefined8 *)((long)pvVar6 + lVar8 * 8);
      *puVar9 = param_7;
      *(undefined4 *)(puVar9 + 1) = param_1;
      *(undefined2 *)((long)puVar9 + 0xc) = uVar4;
      *(undefined1 *)((long)puVar9 + 0xe) = param_6;
      *(undefined1 *)((long)puVar9 + 0xf) = param_4;
      puVar9[2] = param_3;
      puVar3 = puVar9 + 3;
      if (puVar11 != puVar12) {
        do {
          uVar14 = puVar11[-2];
          uVar13 = puVar11[-3];
          puVar1 = puVar11 + -1;
          puVar11 = puVar11 + -3;
          puVar9[-1] = *puVar1;
          puVar9[-2] = uVar14;
          puVar9[-3] = uVar13;
          puVar9 = puVar9 + -3;
        } while (puVar11 != puVar12);
        puVar11 = *(undefined8 **)(this + 0x18);
      }
      *(undefined8 **)(this + 0x18) = puVar9;
      *(undefined8 **)(this + 0x20) = puVar3;
      *(void **)(this + 0x28) = (void *)((long)pvVar6 + uVar10 * 0x18);
      if (puVar11 != (undefined8 *)0x0) {
        operator_delete(puVar11);
      }
    }
  }
  return uVar5 ^ 1;
}



/* operator.new @ 0x1027dade8 */

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* operator new(unsigned long) */

void * operator_new(ulong param_1)

{
  void *pvVar1;
  
                    /* WARNING: Could not recover jumptable at 0x0001027dadf0. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  pvVar1 = (void *)(*(code *)PTR_operator_new_102d59650)();
  return pvVar1;
}



/* operator.delete @ 0x1027dadb8 */

/* WARNING: Unknown calling convention -- yet parameter storage is locked */
/* operator delete(void*) */

void operator_delete(void *param_1)

{
                    /* WARNING: Could not recover jumptable at 0x0001027dadc0. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  (*(code *)PTR_operator_delete_102d59630)();
  return;
}



/* __throw_length_error[abi:v160006] @ 0x101bab1d8 */

/* std::vector<float, std::allocator<float> >::__throw_length_error[abi:v160006]() const */

void std::vector<float,std::allocator<float>>::__throw_length_error_abi_v160006_(void)

{
                    /* WARNING: Subroutine does not return */
  std::__throw_length_error_abi_v160006_("vector");
}



/* _bzero @ 0x1027db01c */

/* WARNING: Unknown calling convention -- yet parameter storage is locked */

void _bzero(void *param_1,size_t param_2)

{
                    /* WARNING: Could not recover jumptable at 0x0001027db024. Too many branches */
                    /* WARNING: Treating indirect jump as call */
  (*(code *)PTR__bzero_10309c928)();
  return;
}



