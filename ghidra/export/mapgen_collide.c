// ===== InventoryHighlights::apply  @ 0x10024eb20 =====

/* InventoryHighlights::apply() */

void __thiscall InventoryHighlights::apply(InventoryHighlights *this)

{
  bool bVar1;
  int iVar2;
  undefined8 uVar3;
  ulong uVar4;
  RelativeItemStackLocation *pRVar5;
  long lVar6;
  long lVar7;
  GameView *pGVar8;
  long *plVar9;
  InventoryHighlights *pIVar10;
  InventoryHighlights *pIVar11;
  InventoryHighlights *pIVar12;
  InventoryHighlights *pIVar13;
  undefined4 local_50;
  InventoryHighlights local_4c;
  undefined4 local_48;
  undefined1 local_44;
  
  if (*(long *)this != 0) {
    lVar6 = *(long *)(*(long *)this + 0x28);
    lVar7 = *(long *)(*(long *)(lVar6 + 0x20) + 0x480);
    if (((lVar7 != 0) && (lVar7 = *(long *)(lVar7 + 0x230), lVar7 != 0)) &&
       (*(long *)(lVar7 + 0x38) == lVar6)) {
      pIVar12 = *(InventoryHighlights **)(this + 8);
      while (pIVar12 != this + 0x10) {
        plVar9 = *(long **)this;
        if (plVar9 != (long *)0x0) {
          lVar6 = *(long *)(*(long *)(plVar9[5] + 0x20) + 0x480);
          if (((lVar6 != 0) && (pGVar8 = *(GameView **)(lVar6 + 0x230), pGVar8 != (GameView *)0x0))
             && (*(long *)(pGVar8 + 0x38) == plVar9[5])) {
            uVar3 = (**(code **)(*plVar9 + 0x1a0))(plVar9,pIVar12[0x29]);
            iVar2 = (**(code **)(*plVar9 + 0x1c0))(plVar9,uVar3);
            if (iVar2 == 0) {
              local_50 = *(undefined4 *)(pIVar12 + 0x28);
              local_4c = pIVar12[0x2c];
              plVar9 = (long *)GameView::getSlot(pGVar8,(RelativeItemStackLocation *)&local_50);
            }
            else {
              local_48 = *(undefined4 *)(pIVar12 + 0x28);
              local_44 = 2;
              plVar9 = (long *)GameView::getSlot(pGVar8,(RelativeItemStackLocation *)&local_48);
            }
            if (plVar9 != (long *)0x0) {
              (**(code **)(*plVar9 + 0x550))(plVar9,1,0);
            }
          }
        }
        pIVar10 = *(InventoryHighlights **)(pIVar12 + 8);
        pIVar13 = pIVar12;
        if (*(InventoryHighlights **)(pIVar12 + 8) == (InventoryHighlights *)0x0) {
          do {
            pIVar12 = *(InventoryHighlights **)(pIVar13 + 0x10);
            bVar1 = *(InventoryHighlights **)pIVar12 != pIVar13;
            pIVar13 = pIVar12;
          } while (bVar1);
        }
        else {
          do {
            pIVar12 = pIVar10;
            pIVar10 = *(InventoryHighlights **)pIVar12;
          } while (*(InventoryHighlights **)pIVar12 != (InventoryHighlights *)0x0);
        }
      }
      pIVar10 = *(InventoryHighlights **)(this + 0x20);
      pIVar12 = this + 0x28;
      if (pIVar10 != pIVar12) {
        plVar9 = *(long **)this;
        if (plVar9 == (long *)0x0) {
          do {
            pIVar13 = *(InventoryHighlights **)(pIVar10 + 8);
            pIVar11 = pIVar10;
            if (*(InventoryHighlights **)(pIVar10 + 8) == (InventoryHighlights *)0x0) {
              do {
                pIVar10 = *(InventoryHighlights **)(pIVar11 + 0x10);
                bVar1 = *(InventoryHighlights **)pIVar10 != pIVar11;
                pIVar11 = pIVar10;
              } while (bVar1);
            }
            else {
              do {
                pIVar10 = pIVar13;
                pIVar13 = *(InventoryHighlights **)pIVar10;
              } while (*(InventoryHighlights **)pIVar10 != (InventoryHighlights *)0x0);
            }
          } while (pIVar10 != pIVar12);
        }
        else {
          while( true ) {
            if (plVar9 != (long *)0x0) {
              lVar6 = *(long *)(*(long *)(plVar9[5] + 0x20) + 0x480);
              if (((lVar6 != 0) &&
                  (pGVar8 = *(GameView **)(lVar6 + 0x230), pGVar8 != (GameView *)0x0)) &&
                 (*(long *)(pGVar8 + 0x38) == plVar9[5])) {
                uVar3 = (**(code **)(*plVar9 + 0x1a0))(plVar9,pIVar10[0x29]);
                uVar4 = (**(code **)(*plVar9 + 0x1c0))(plVar9,uVar3);
                if ((uVar4 & 1) == 0) {
                  local_50 = *(undefined4 *)(pIVar10 + 0x28);
                  local_4c = pIVar10[0x2c];
                  pRVar5 = (RelativeItemStackLocation *)&local_50;
                }
                else {
                  local_48 = *(undefined4 *)(pIVar10 + 0x28);
                  local_44 = 2;
                  pRVar5 = (RelativeItemStackLocation *)&local_48;
                }
                plVar9 = (long *)GameView::getSlot(pGVar8,pRVar5);
                if (plVar9 != (long *)0x0) {
                  (**(code **)(*plVar9 + 0x550))(plVar9,1,0);
                }
              }
            }
            pIVar13 = *(InventoryHighlights **)(pIVar10 + 8);
            pIVar11 = pIVar10;
            if (*(InventoryHighlights **)(pIVar10 + 8) == (InventoryHighlights *)0x0) {
              do {
                pIVar10 = *(InventoryHighlights **)(pIVar11 + 0x10);
                bVar1 = *(InventoryHighlights **)pIVar10 != pIVar11;
                pIVar11 = pIVar10;
              } while (bVar1);
            }
            else {
              do {
                pIVar10 = pIVar13;
                pIVar13 = *(InventoryHighlights **)pIVar10;
              } while (*(InventoryHighlights **)pIVar10 != (InventoryHighlights *)0x0);
            }
            if (pIVar10 == pIVar12) break;
            plVar9 = *(long **)this;
          }
        }
      }
      pIVar10 = *(InventoryHighlights **)(this + 0x38);
      pIVar12 = this + 0x40;
      if (pIVar10 != pIVar12) {
        plVar9 = *(long **)this;
        if (plVar9 == (long *)0x0) {
          do {
            pIVar13 = *(InventoryHighlights **)(pIVar10 + 8);
            pIVar11 = pIVar10;
            if (*(InventoryHighlights **)(pIVar10 + 8) == (InventoryHighlights *)0x0) {
              do {
                pIVar10 = *(InventoryHighlights **)(pIVar11 + 0x10);
                bVar1 = *(InventoryHighlights **)pIVar10 != pIVar11;
                pIVar11 = pIVar10;
              } while (bVar1);
            }
            else {
              do {
                pIVar10 = pIVar13;
                pIVar13 = *(InventoryHighlights **)pIVar10;
              } while (*(InventoryHighlights **)pIVar10 != (InventoryHighlights *)0x0);
            }
          } while (pIVar10 != pIVar12);
        }
        else {
          while( true ) {
            if (plVar9 != (long *)0x0) {
              lVar6 = *(long *)(*(long *)(plVar9[5] + 0x20) + 0x480);
              if (((lVar6 != 0) &&
                  (pGVar8 = *(GameView **)(lVar6 + 0x230), pGVar8 != (GameView *)0x0)) &&
                 (*(long *)(pGVar8 + 0x38) == plVar9[5])) {
                uVar3 = (**(code **)(*plVar9 + 0x1a0))(plVar9,pIVar10[0x29]);
                uVar4 = (**(code **)(*plVar9 + 0x1c0))(plVar9,uVar3);
                if ((uVar4 & 1) == 0) {
                  local_50 = *(undefined4 *)(pIVar10 + 0x28);
                  local_4c = pIVar10[0x2c];
                  pRVar5 = (RelativeItemStackLocation *)&local_50;
                }
                else {
                  local_48 = *(undefined4 *)(pIVar10 + 0x28);
                  local_44 = 2;
                  pRVar5 = (RelativeItemStackLocation *)&local_48;
                }
                plVar9 = (long *)GameView::getSlot(pGVar8,pRVar5);
                if (plVar9 != (long *)0x0) {
                  (**(code **)(*plVar9 + 0x550))(plVar9,1,1);
                }
              }
            }
            pIVar13 = *(InventoryHighlights **)(pIVar10 + 8);
            pIVar11 = pIVar10;
            if (*(InventoryHighlights **)(pIVar10 + 8) == (InventoryHighlights *)0x0) {
              do {
                pIVar10 = *(InventoryHighlights **)(pIVar11 + 0x10);
                bVar1 = *(InventoryHighlights **)pIVar10 != pIVar11;
                pIVar11 = pIVar10;
              } while (bVar1);
            }
            else {
              do {
                pIVar10 = pIVar13;
                pIVar13 = *(InventoryHighlights **)pIVar10;
              } while (*(InventoryHighlights **)pIVar10 != (InventoryHighlights *)0x0);
            }
            if (pIVar10 == pIVar12) break;
            plVar9 = *(long **)this;
          }
        }
      }
    }
  }
  return;
}



// ===== GuiStyle::apply  @ 0x100267408 =====

/* GuiStyle::apply() */

void __thiscall GuiStyle::apply(GuiStyle *this)

{
  long lVar1;
  GuiStyle *pGVar2;
  bool bVar3;
  FrameStyleSpecification *pFVar4;
  LabelStyleSpecification *pLVar5;
  long *plVar6;
  GuiStyle *pGVar7;
  GuiStyle *pGVar8;
  __tree_node **local_48;
  __tree_node *local_40;
  undefined8 uStack_38;
  
  local_48 = &local_40;
  local_40 = (__tree_node *)0x0;
  uStack_38 = 0;
  (**(code **)(**(long **)(this + 0xf78) + 0x18))(*(long **)(this + 0xf78),&local_48);
  pGVar7 = *(GuiStyle **)(this + 0x160);
  while (pGVar7 != this + 0x168) {
    plVar6 = *(long **)(pGVar7 + 0x38);
    if (plVar6 != *(long **)(this + 0xf78)) {
      (**(code **)(*plVar6 + 0x18))(plVar6,&local_48);
    }
    pGVar2 = *(GuiStyle **)(pGVar7 + 8);
    pGVar8 = pGVar7;
    if (*(GuiStyle **)(pGVar7 + 8) == (GuiStyle *)0x0) {
      do {
        pGVar7 = *(GuiStyle **)(pGVar8 + 0x10);
        bVar3 = *(GuiStyle **)pGVar7 != pGVar8;
        pGVar8 = pGVar7;
      } while (bVar3);
    }
    else {
      do {
        pGVar7 = pGVar2;
        pGVar2 = *(GuiStyle **)pGVar7;
      } while (*(GuiStyle **)pGVar7 != (GuiStyle *)0x0);
    }
  }
  pGVar7 = *(GuiStyle **)(this + 0x178);
  while (pGVar7 != this + 0x180) {
    (**(code **)(**(long **)(pGVar7 + 0x38) + 0x18))(*(long **)(pGVar7 + 0x38),&local_48);
    pGVar2 = *(GuiStyle **)(pGVar7 + 8);
    pGVar8 = pGVar7;
    if (*(GuiStyle **)(pGVar7 + 8) == (GuiStyle *)0x0) {
      do {
        pGVar7 = *(GuiStyle **)(pGVar8 + 0x10);
        bVar3 = *(GuiStyle **)pGVar7 != pGVar8;
        pGVar8 = pGVar7;
      } while (bVar3);
    }
    else {
      do {
        pGVar7 = pGVar2;
        pGVar2 = *(GuiStyle **)pGVar7;
      } while (*(GuiStyle **)pGVar7 != (GuiStyle *)0x0);
    }
  }
  pFVar4 = (FrameStyleSpecification *)(**(code **)(**(long **)(this + 0x8d8) + 0x28))();
  FrameStyleSpecification::apply
            (pFVar4,(FrameStyle *)&agui::ToolTip::defaultToolTipStyle,(OptionalFundamentalBase *)0x0
            );
  pFVar4 = (FrameStyleSpecification *)(**(code **)(**(long **)(this + 0x838) + 0x28))();
  FrameStyleSpecification::apply
            (pFVar4,(FrameStyle *)&agui::ToolTip::defaultToolTipOuterStyle,
             (OptionalFundamentalBase *)0x0);
  pLVar5 = (LabelStyleSpecification *)(**(code **)(**(long **)(this + 0xe50) + 0x28))();
  LabelStyleSpecification::apply
            (pLVar5,(LabelStyle *)&agui::ToolTip::defaultTitleStyle,(OptionalFundamentalBase *)0x0);
  pLVar5 = (LabelStyleSpecification *)(**(code **)(**(long **)(this + 0xe48) + 0x28))();
  LabelStyleSpecification::apply
            (pLVar5,(LabelStyle *)&agui::ToolTip::defaultLabelStyle,(OptionalFundamentalBase *)0x0);
  lVar1 = agui::Gui::instance;
  if (agui::Gui::instance != 0) {
    *(long *)(agui::Gui::instance + 0x3b0) = *(long *)(this + 0xe28) + 0x120;
    *(long *)(lVar1 + 0x3a8) = *(long *)(this + 0xe18) + 0x120;
    *(undefined1 **)(lVar1 + 0x3b8) = &agui::Label::defaultStyle;
    *(long *)(lVar1 + 0x3c0) = *(long *)(this + 0xec8) + 0x120;
  }
  std::__tree<agui::Style_const*,std::less<agui::Style_const*>,std::allocator<agui::Style_const*>>::
  destroy((__tree<agui::Style_const*,std::less<agui::Style_const*>,std::allocator<agui::Style_const*>>
           *)&local_48,local_40);
  return;
}



// ===== UndoItemFiller::apply  @ 0x1003062d0 =====

/* UndoItemFiller::apply() */

void __thiscall UndoItemFiller::apply(UndoItemFiller *this)

{
  long *plVar1;
  long *plVar2;
  long *plVar3;
  
  if (this[0x5c] == (UndoItemFiller)0x0) {
    this[0x5c] = (UndoItemFiller)0x1;
    if (*(int *)(this + 0x58) == 1) {
      (**(code **)(**(long **)(this + 8) + 0x80))(*(long **)(this + 8),this + 0x10);
      plVar2 = *(long **)(this + 0x18);
      plVar3 = *(long **)(this + 0x20);
      while (plVar3 != plVar2) {
        plVar3 = plVar3 + -1;
        plVar1 = (long *)*plVar3;
        *plVar3 = 0;
        if (plVar1 != (long *)0x0) {
          (**(code **)(*plVar1 + 8))();
        }
      }
    }
    else {
      if (*(int *)(this + 0x58) != 0) {
                    /* WARNING: Subroutine does not return */
        Logging::logEnumAndAbortOrThrow<UndoStackOperation>
                  ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Undo/UndoItemFiller.cpp"
                   ,0x26,9);
      }
      (**(code **)(**(long **)(this + 8) + 0x78))(*(long **)(this + 8),this + 0x10);
      plVar2 = *(long **)(this + 0x18);
      plVar3 = *(long **)(this + 0x20);
      while (plVar3 != plVar2) {
        plVar3 = plVar3 + -1;
        plVar1 = (long *)*plVar3;
        *plVar3 = 0;
        if (plVar1 != (long *)0x0) {
          (**(code **)(*plVar1 + 8))();
        }
      }
    }
    *(long **)(this + 0x20) = plVar2;
    *(undefined8 *)(this + 0x30) = 0;
    if (this[0x50] != (UndoItemFiller)0x0) {
      this[0x50] = (UndoItemFiller)0x0;
      return;
    }
  }
  return;
}



// ===== SpeechBubbleStyleSpecification::apply  @ 0x100362cf8 =====

/* SpeechBubbleStyleSpecification::apply(SpeechBubbleStyle&, OptionalFundamentalBase*) const */

void __thiscall
SpeechBubbleStyleSpecification::apply
          (SpeechBubbleStyleSpecification *this,SpeechBubbleStyle *param_1,
          OptionalFundamentalBase *param_2)

{
  long *plVar1;
  undefined8 *puVar2;
  ElementImageSet *this_00;
  void *pvVar3;
  float *pfVar4;
  FrameStyle *this_01;
  LabelStyle *this_02;
  ElementImageSet *pEVar5;
  undefined8 local_40;
  undefined8 uStack_38;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (*(long *)(this + 0xb8) != 0) {
    this_01 = *(FrameStyle **)(param_1 + 0x68);
    if (this_01 == (FrameStyle *)0x0) {
      this_01 = operator_new(0xb8);
      agui::FrameStyle::FrameStyle(this_01,(FrameStyle *)0x0);
      plVar1 = *(long **)(param_1 + 0x68);
      *(FrameStyle **)(param_1 + 0x68) = this_01;
      if (plVar1 != (long *)0x0) {
        (**(code **)(*plVar1 + 8))();
        this_01 = *(FrameStyle **)(param_1 + 0x68);
      }
    }
    FrameStyleSpecification::apply
              (*(FrameStyleSpecification **)(this + 0xb8),this_01,(OptionalFundamentalBase *)0x0);
    puVar2 = *(undefined8 **)(this_01 + 0x18);
    if (puVar2 == (undefined8 *)0x0) {
      puVar2 = operator_new(0x20);
      puVar2[1] = 0;
      *puVar2 = 0;
      puVar2[3] = 0;
      puVar2[2] = 0;
      *(undefined8 **)(this_01 + 0x18) = puVar2;
    }
    puVar2[3] = param_1;
  }
  if (*(long *)(this + 0xc0) != 0) {
    this_02 = *(LabelStyle **)(param_1 + 0x70);
    if (this_02 == (LabelStyle *)0x0) {
      this_02 = operator_new(200);
      agui::LabelStyle::LabelStyle(this_02,(LabelStyle *)0x0);
      plVar1 = *(long **)(param_1 + 0x70);
      *(LabelStyle **)(param_1 + 0x70) = this_02;
      if (plVar1 != (long *)0x0) {
        (**(code **)(*plVar1 + 8))();
        this_02 = *(LabelStyle **)(param_1 + 0x70);
      }
    }
    LabelStyleSpecification::apply
              (*(LabelStyleSpecification **)(this + 0xc0),this_02,(OptionalFundamentalBase *)0x0);
    puVar2 = *(undefined8 **)(this_02 + 0x18);
    if (puVar2 == (undefined8 *)0x0) {
      puVar2 = operator_new(0x20);
      puVar2[1] = 0;
      *puVar2 = 0;
      puVar2[3] = 0;
      puVar2[2] = 0;
      *(undefined8 **)(this_02 + 0x18) = puVar2;
    }
    puVar2[3] = param_1;
  }
  if (*(undefined8 **)(this + 200) != (undefined8 *)0x0) {
    pEVar5 = (ElementImageSet *)**(undefined8 **)(this + 200);
    this_00 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(this_00,pEVar5);
    pEVar5 = *(ElementImageSet **)(param_1 + 0x78);
    *(ElementImageSet **)(param_1 + 0x78) = this_00;
    if (pEVar5 != (ElementImageSet *)0x0) {
      pvVar3 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar5);
      operator_delete(pvVar3);
    }
  }
  pfVar4 = *(float **)(this + 0xd0);
  if (pfVar4 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar4,pfVar4[1],pfVar4[2],pfVar4[3]);
    puVar2 = operator_new(0x10);
    puVar2[1] = uStack_38;
    *puVar2 = local_40;
    pvVar3 = *(void **)(param_1 + 0x80);
    *(undefined8 **)(param_1 + 0x80) = puVar2;
    if (pvVar3 != (void *)0x0) {
      operator_delete(pvVar3);
    }
  }
  if (this[0xe0] != (SpeechBubbleStyleSpecification)0x0) {
    *(undefined8 *)(param_1 + 0x88) = *(undefined8 *)(this + 0xd8);
    param_1[0x90] = (SpeechBubbleStyle)0x1;
  }
  if (this[0xe9] != (SpeechBubbleStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x98) = (byte)this[0xe8] | 0x100;
  }
  return;
}



// ===== FlowStyleSpecification::apply  @ 0x100362ecc =====

/* FlowStyleSpecification::apply(agui::FlowStyle&) const */

void __thiscall FlowStyleSpecification::apply(FlowStyleSpecification *this,FlowStyle *param_1)

{
  int iVar1;
  
  StyleSpecification::apply
            ((StyleSpecification *)this,(Style *)param_1,(OptionalFundamentalBase *)0x0);
  if (this[0xb8] != (FlowStyleSpecification)0x0) {
    *(undefined4 *)(param_1 + 0x68) = *(undefined4 *)(this + 0xb4);
    param_1[0x6c] = (FlowStyle)0x1;
  }
  if (this[0xc0] != (FlowStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0xbc));
    *(int *)(param_1 + 0x70) = iVar1;
    param_1[0x74] = (FlowStyle)0x1;
  }
  if (this[200] != (FlowStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0xc4));
    *(int *)(param_1 + 0x78) = iVar1;
    param_1[0x7c] = (FlowStyle)0x1;
  }
  return;
}



// ===== UpgradeMapping::apply  @ 0x10037ecd0 =====

/* UpgradeMapping::apply(UpgradeMapping::Backup&) */

void __thiscall UpgradeMapping::apply(UpgradeMapping *this,Backup *param_1)

{
  ulong uVar1;
  long lVar2;
  
  uVar1 = *(ulong *)(param_1 + 8);
  if (-1 < (char)param_1[0x17]) {
    uVar1 = (ulong)(byte)param_1[0x17];
  }
  if (uVar1 == 0) {
    uVar1 = *(ulong *)(param_1 + 0x20);
    if (-1 < (char)param_1[0x2f]) {
      uVar1 = (ulong)(byte)param_1[0x2f];
    }
    if (uVar1 == 0) {
      uVar1 = *(ulong *)(param_1 + 0x38);
      if (-1 < (char)param_1[0x47]) {
        uVar1 = (ulong)(byte)param_1[0x47];
      }
      if (uVar1 == 0) {
        uVar1 = *(ulong *)(param_1 + 0x50);
        if (-1 < (char)param_1[0x5f]) {
          uVar1 = (ulong)(byte)param_1[0x5f];
        }
        if (uVar1 == 0) goto LAB_10037ed50;
      }
    }
  }
  UpgradeFilter::applyBackup((UpgradeFilter *)this,(Backup *)param_1);
LAB_10037ed50:
  uVar1 = *(ulong *)(param_1 + 0x68);
  if (-1 < (char)param_1[0x77]) {
    uVar1 = (ulong)(byte)param_1[0x77];
  }
  if (uVar1 == 0) {
    uVar1 = *(ulong *)(param_1 + 0x80);
    if (-1 < (char)param_1[0x8f]) {
      uVar1 = (ulong)(byte)param_1[0x8f];
    }
    if (uVar1 == 0) {
      lVar2 = *(long *)(param_1 + 0x90);
      while( true ) {
        if (lVar2 == *(long *)(param_1 + 0x98)) {
          return;
        }
        uVar1 = *(ulong *)(lVar2 + 8);
        if (-1 < (char)*(byte *)(lVar2 + 0x17)) {
          uVar1 = (ulong)*(byte *)(lVar2 + 0x17);
        }
        if (uVar1 != 0) break;
        uVar1 = *(ulong *)(lVar2 + 0x20);
        if (-1 < (char)*(byte *)(lVar2 + 0x2f)) {
          uVar1 = (ulong)*(byte *)(lVar2 + 0x2f);
        }
        if (uVar1 != 0) break;
        lVar2 = lVar2 + 0x30;
      }
    }
  }
  UpgradeDestination::applyBackup((UpgradeDestination *)(this + 0x10),(Backup *)(param_1 + 0x60));
  return;
}



// ===== TransportLineDeserialiser::apply  @ 0x100414d94 =====

/* TransportLineDeserialiser::apply(Map&, SetupData const&, MapDeserialiser const&) */

void __thiscall
TransportLineDeserialiser::apply
          (TransportLineDeserialiser *this,Map *param_1,SetupData *param_2,MapDeserialiser *param_3)

{
  MapDeserialiser *pMVar1;
  AlarmCollector *pAVar2;
  TransportLineRecord *pTVar3;
  uint uVar4;
  MapDeserialiser *pMVar5;
  undefined8 *puVar6;
  long *plVar7;
  bool bVar8;
  undefined8 uVar9;
  void *pvVar10;
  TransportLineGroup *pTVar11;
  DeserialiserException *this_00;
  uint uVar12;
  uint uVar13;
  long lVar14;
  undefined8 *puVar15;
  MapDeserialiser *pMVar16;
  long *plVar17;
  long *plVar18;
  MapDeserialiser *pMVar19;
  ulong uVar20;
  long *plVar21;
  ulong uVar22;
  int iVar23;
  TransportLine *pTVar24;
  long *plVar25;
  TransportLine *pTVar26;
  TransportLineRecord *pTVar27;
  long *plVar28;
  TransportLine *this_01;
  TransportLine *pTVar29;
  long lVar30;
  TransportLine *pTVar31;
  long *plVar32;
  char *local_f8;
  long *local_e8;
  string asStack_e0 [24];
  undefined8 *local_c8;
  undefined8 *local_c0;
  undefined8 local_b8;
  TransportLine *local_b0;
  TransportLine *local_a8;
  TransportLine *local_a0;
  long *local_98;
  long *local_90;
  undefined8 local_88;
  long *local_80;
  long *local_78;
  undefined8 local_70;
  
  local_80 = (long *)0x0;
  local_78 = (long *)0x0;
  local_70 = 0;
  local_98 = (long *)0x0;
  local_90 = (long *)0x0;
  local_88 = 0;
  plVar32 = *(long **)(this + 8);
  plVar28 = *(long **)(this + 0x10);
  if (plVar32 == plVar28) {
    uVar13 = 1;
LAB_100414e24:
    local_b0 = (TransportLine *)0x0;
    std::vector<TransportLine*,std::allocator<TransportLine*>>::__append
              ((vector<TransportLine*,std::allocator<TransportLine*>> *)&local_80,(ulong)uVar13,
               &local_b0);
    plVar32 = *(long **)(this + 8);
    plVar28 = *(long **)(this + 0x10);
    plVar17 = local_98;
    if (plVar32 != plVar28) {
LAB_100414e40:
      pMVar1 = param_3 + 0x238;
      pAVar2 = (AlarmCollector *)(param_2 + 0x70);
      local_f8 = "It\'s broken.";
      do {
        local_b0 = (TransportLine *)0x0;
        plVar17 = (long *)plVar32[2];
        if (plVar17 == (long *)0x0) {
LAB_100414f38:
          bVar8 = false;
LAB_100414f48:
          WakeUpList::transferSleepersTo((WakeUpList *)(*plVar32 + 0xa0),pAVar2);
          WakeUpList::transferSleepersTo((WakeUpList *)(*plVar32 + 0xb8),pAVar2);
          *this = (TransportLineDeserialiser)0x1;
          if (local_b0 != (TransportLine *)0x0) goto LAB_100414f74;
        }
        else {
          pMVar19 = *(MapDeserialiser **)pMVar1;
          pMVar16 = pMVar1;
          if (pMVar19 != (MapDeserialiser *)0x0) {
            do {
              pMVar5 = pMVar19 + 8;
              if (plVar17 <= *(long **)(pMVar19 + 0x20)) {
                pMVar16 = pMVar19;
                pMVar5 = pMVar19;
              }
              pMVar19 = *(MapDeserialiser **)pMVar5;
            } while (pMVar19 != (MapDeserialiser *)0x0);
            if ((pMVar16 != pMVar1) && (*(long **)(pMVar16 + 0x20) <= plVar17)) {
              plVar17 = *(long **)(pMVar16 + 0x28);
            }
          }
          lVar14 = (**(code **)(*plVar17 + 0x1300))(plVar17,(char)plVar32[5]);
          local_b0 = *(TransportLine **)(lVar14 + 0x10);
          uVar22 = TransportLine::SeenSet::add((SeenSet *)&local_98,local_b0);
          if ((uVar22 & 1) == 0) {
            bVar8 = false;
            local_b0 = (TransportLine *)0x0;
            goto LAB_100414f48;
          }
          if (local_b0 == (TransportLine *)0x0) goto LAB_100414f38;
          iVar23 = *(int *)((long)plVar32 + 0x2c);
          if (iVar23 == 0) {
            bVar8 = false;
          }
          else {
            do {
              if ((*(long *)(local_b0 + 0x70) != 0) &&
                 (*(char *)(*(long *)(local_b0 + 0x70) + 0x122) != '\0')) {
LAB_10041500c:
                pTVar29 = local_b0;
                if ((*(int *)(local_b0 + 0x40) != 0 && *(int *)(local_b0 + 0x60) != 0) &&
                   (pTVar24 = local_b0 + 0x18, *(TransportLine **)pTVar24 == pTVar24)) {
                  lVar30 = *(long *)(local_b0 + 0x28);
                  plVar17 = (long *)(lVar30 + 0x48);
                  lVar14 = lVar30;
                  if ((long *)*plVar17 == plVar17) {
                    (**(code **)(**(long **)(lVar30 + 0x10) + 0x18))
                              (*(long **)(lVar30 + 0x10),lVar30);
                    lVar14 = *(long *)(pTVar29 + 0x28);
                  }
                  puVar15 = *(undefined8 **)(lVar30 + 0x50);
                  *(long **)(pTVar29 + 0x18) = plVar17;
                  *(undefined8 **)(pTVar29 + 0x20) = puVar15;
                  *puVar15 = pTVar24;
                  *(TransportLine **)(*(long *)(pTVar29 + 0x18) + 8) = pTVar24;
                  *(long *)(lVar30 + 0x40) = *(long *)(lVar30 + 0x40) + 1;
                  if (*(long *)(lVar14 + 0x58) == lVar14 + 0x48) {
                    *(TransportLine **)(lVar14 + 0x58) = pTVar24;
                  }
                }
LAB_100415094:
                bVar8 = true;
                goto LAB_100414f48;
              }
              uVar22 = TransportLine::tryToMergeInputLineInside(local_b0,pAVar2);
              if ((uVar22 & 1) == 0) {
                if (local_b0 != (TransportLine *)0x0) goto LAB_10041500c;
                goto LAB_100415094;
              }
              iVar23 = iVar23 + -1;
            } while (iVar23 != 0);
            bVar8 = false;
            if (local_b0 == (TransportLine *)0x0) goto LAB_100414f48;
          }
LAB_100414f74:
          TransportLine::swapWith(local_b0,(TransportLine *)*plVar32,true);
          if (**(int **)(*plVar32 + 0xa0) != 0) {
            uVar9 = 0x5b;
LAB_1004155ac:
                    /* WARNING: Subroutine does not return */
            Logging::logAndAbortOrThrow
                      ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Belt/TransportLineDeserialiser.cpp"
                       ,uVar9,9,local_f8);
          }
          if (**(int **)(*plVar32 + 0xb8) != 0) {
            uVar9 = 0x5d;
            goto LAB_1004155ac;
          }
          if (!bVar8) {
            uVar22 = (ulong)*(uint *)(plVar32 + 6);
            if (*(uint *)(plVar32 + 6) != 0xffffffff) {
              if ((ulong)((long)local_78 - (long)local_80 >> 3) <= uVar22) {
                    /* WARNING: Subroutine does not return */
                ReleaseAssertFailed("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Belt/TransportLineDeserialiser.cpp"
                                    ,99,"transportLineRecord.activeIndex < activeLines.size()");
              }
              if (local_80[uVar22] != 0) {
                uVar9 = 0x65;
                local_f8 = "Line already in active lines list.";
                goto LAB_1004155ac;
              }
              local_80[uVar22] = (long)local_b0;
            }
            if (plVar32[7] != -1) {
              uVar9 = std::__tree<MergeRequest,std::less<MergeRequest>,std::allocator<MergeRequest>>
                      ::__emplace_unique_impl<TransportLine*&,MapTick&,bool&,unsigned_int&>
                                ((__tree<MergeRequest,std::less<MergeRequest>,std::allocator<MergeRequest>>
                                  *)(*(long *)(param_1 + 0x140) + 0x38),&local_b0,
                                 (MapTick *)(plVar32 + 7),(bool *)(plVar32 + 8),
                                 (uint *)((long)plVar32 + 0x44));
              *(undefined8 *)(local_b0 + 0x118) = uVar9;
              local_b0[0x120] = (TransportLine)0x1;
            }
          }
        }
        plVar32 = plVar32 + 9;
        plVar17 = local_98;
      } while (plVar32 != plVar28);
    }
  }
  else {
    uVar12 = 0;
    plVar17 = plVar32;
    do {
      uVar4 = *(uint *)(plVar17 + 6);
      uVar13 = uVar12;
      if (uVar12 <= uVar4) {
        uVar13 = uVar4;
      }
      if (uVar4 != 0xffffffff) {
        uVar12 = uVar13;
      }
      plVar17 = plVar17 + 9;
    } while (plVar17 != plVar28);
    local_b0 = (TransportLine *)0x0;
    uVar13 = uVar12 + 1;
    if (uVar12 != 0xffffffff) goto LAB_100414e24;
    plVar17 = local_98;
    if (plVar32 != plVar28) goto LAB_100414e40;
  }
  for (; plVar17 != local_90; plVar17 = plVar17 + 1) {
    *(undefined1 *)(*plVar17 + 0x122) = 0;
  }
  pTVar3 = *(TransportLineRecord **)(this + 8);
  pTVar27 = *(TransportLineRecord **)(this + 0x10);
  local_90 = local_98;
  plVar32 = local_80;
  plVar28 = local_78;
  while (local_80 = plVar32, local_78 = plVar28, pTVar27 != pTVar3) {
    pTVar27 = pTVar27 + -0x48;
    std::__destroy_at_abi_v160006_<TransportLineDeserialiser::TransportLineRecord,0>(pTVar27);
    plVar32 = local_80;
    plVar28 = local_78;
  }
  *(TransportLineRecord **)(this + 0x10) = pTVar3;
  lVar14 = *(long *)(param_1 + 0x140);
  if (1 < *(ulong *)(lVar14 + 0x48)) {
    plVar17 = *(long **)(lVar14 + 0x38);
    while (plVar17 != (long *)(lVar14 + 0x40)) {
      plVar25 = (long *)plVar17[1];
      plVar18 = plVar17;
      plVar7 = plVar25;
      if (plVar25 == (long *)0x0) {
        do {
          plVar21 = (long *)plVar18[2];
          bVar8 = (long *)*plVar21 != plVar18;
          plVar18 = plVar21;
        } while (bVar8);
      }
      else {
        do {
          plVar21 = plVar7;
          plVar7 = (long *)*plVar21;
        } while ((long *)*plVar21 != (long *)0x0);
      }
      if (plVar21 == (long *)(lVar14 + 0x40)) break;
      bVar8 = (ulong)plVar21[5] <= (ulong)plVar17[5];
      if ((plVar17[5] == plVar21[5]) &&
         (bVar8 = *(uint *)((long)plVar21 + 0x34) <= *(uint *)((long)plVar17 + 0x34),
         *(uint *)((long)plVar17 + 0x34) == *(uint *)((long)plVar21 + 0x34))) {
        uVar20 = *(ulong *)(*(long *)(**(long **)(plVar17[4] + 0xf8) + 0x20) + 0xa0);
        uVar22 = *(ulong *)(*(long *)(**(long **)(plVar21[4] + 0xf8) + 0x20) + 0xa0);
        bVar8 = uVar22 <= uVar20;
        if (uVar20 == uVar22) {
          bVar8 = *(byte *)(**(long **)(plVar21[4] + 0xf8) + 1) <=
                  *(byte *)(**(long **)(plVar17[4] + 0xf8) + 1);
        }
      }
      if (bVar8) {
                    /* WARNING: Subroutine does not return */
        Logging::logAndAbortOrThrow
                  ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Belt/TransportLineDeserialiser.cpp"
                   ,0x85,9,"Requests ordering changed while loading.");
      }
      plVar18 = plVar17;
      if (plVar25 == (long *)0x0) {
        do {
          plVar17 = (long *)plVar18[2];
          bVar8 = (long *)*plVar17 != plVar18;
          plVar18 = plVar17;
        } while (bVar8);
      }
      else {
        do {
          plVar17 = plVar25;
          plVar25 = (long *)*plVar17;
        } while ((long *)*plVar17 != (long *)0x0);
      }
    }
  }
  if (plVar32 == plVar28) {
    local_a8 = (TransportLine *)0x0;
    local_a0 = (TransportLine *)0x0;
    local_b0 = (TransportLine *)0x0;
    local_e8 = (long *)(lVar14 + 0x10);
    plVar28 = (long *)*local_e8;
    plVar32 = local_98;
    if (plVar28 == local_e8) goto joined_r0x00010041546c;
  }
  else {
    do {
      lVar14 = *plVar32;
      if (((lVar14 != 0) && (plVar17 = (long *)(lVar14 + 0x18), (long *)*plVar17 == plVar17)) &&
         (*(int *)(lVar14 + 0x40) != 0)) {
        lVar30 = *(long *)(lVar14 + 0x28);
        plVar25 = (long *)(lVar30 + 0x48);
        if ((long *)*plVar25 == plVar25) {
          (**(code **)(**(long **)(lVar30 + 0x10) + 0x18))(*(long **)(lVar30 + 0x10),lVar30);
        }
        puVar15 = *(undefined8 **)(lVar30 + 0x50);
        *(long **)(lVar14 + 0x18) = plVar25;
        *(undefined8 **)(lVar14 + 0x20) = puVar15;
        *puVar15 = plVar17;
        *(long **)(*(long *)(lVar14 + 0x18) + 8) = plVar17;
        *(long *)(lVar30 + 0x40) = *(long *)(lVar30 + 0x40) + 1;
      }
      plVar32 = plVar32 + 1;
    } while (plVar32 != plVar28);
    local_a8 = (TransportLine *)0x0;
    local_a0 = (TransportLine *)0x0;
    local_b0 = (TransportLine *)0x0;
    local_e8 = (long *)(*(long *)(param_1 + 0x140) + 0x10);
    plVar28 = (long *)*local_e8;
    plVar32 = local_98;
    if (plVar28 == local_e8) goto joined_r0x00010041546c;
  }
  local_a0 = (TransportLine *)0x0;
  local_a8 = (TransportLine *)0x0;
  local_b0 = (TransportLine *)0x0;
  pTVar29 = (TransportLine *)0x0;
  do {
    pTVar24 = local_b0;
    for (plVar32 = (long *)plVar28[5]; local_b0 = pTVar24, plVar32 != plVar28 + 5;
        plVar32 = (long *)*plVar32) {
      lVar14 = (long)(plVar32 + -1);
      if (pTVar29 < local_a0) {
        pTVar31 = pTVar29 + 8;
        *(long *)pTVar29 = lVar14;
        local_a8 = pTVar31;
      }
      else {
        lVar30 = (long)pTVar29 - (long)pTVar24 >> 3;
        uVar22 = lVar30 + 1;
        if (uVar22 >> 0x3d != 0) {
                    /* WARNING: Subroutine does not return */
          std::vector<TransportLine*,std::allocator<TransportLine*>>::
          __throw_length_error_abi_v160006_();
        }
        uVar20 = (ulong)((long)local_a0 - (long)pTVar24) >> 2;
        if (uVar20 <= uVar22) {
          uVar20 = uVar22;
        }
        if (0x7ffffffffffffff7 < (ulong)((long)local_a0 - (long)pTVar24)) {
          uVar20 = 0x1fffffffffffffff;
        }
        if (uVar20 == 0) {
          pvVar10 = (void *)0x0;
          pTVar26 = (TransportLine *)(lVar30 * 8);
          pTVar31 = pTVar26 + 8;
          *(long *)pTVar26 = lVar14;
          if (pTVar29 == pTVar24) goto LAB_1004153a4;
LAB_10041537c:
          do {
            pTVar29 = pTVar29 + -8;
            pTVar26 = pTVar26 + -8;
            *(long *)pTVar26 = *(long *)pTVar29;
          } while (pTVar29 != pTVar24);
          local_a0 = (TransportLine *)((long)pvVar10 + uVar20 * 8);
          pTVar29 = local_b0;
        }
        else {
          if (uVar20 >> 0x3d != 0) {
                    /* WARNING: Subroutine does not return */
            std::__throw_bad_array_new_length_abi_v160006_();
          }
          pvVar10 = operator_new(uVar20 << 3);
          pTVar26 = (TransportLine *)((long)pvVar10 + lVar30 * 8);
          pTVar31 = pTVar26 + 8;
          *(long *)pTVar26 = lVar14;
          if (pTVar29 != pTVar24) goto LAB_10041537c;
LAB_1004153a4:
          local_a0 = (TransportLine *)((long)pvVar10 + uVar20 * 8);
        }
        local_b0 = pTVar26;
        local_a8 = pTVar31;
        if (pTVar29 != (TransportLine *)0x0) {
          operator_delete(pTVar29);
        }
      }
      pTVar29 = pTVar31;
      pTVar24 = local_b0;
    }
    plVar28 = (long *)*plVar28;
  } while (plVar28 != local_e8);
  local_c8 = (undefined8 *)0x0;
  local_c0 = (undefined8 *)0x0;
  local_b8 = 0;
  pTVar31 = pTVar24;
  if (pTVar24 != pTVar29) {
    do {
      pTVar26 = *(TransportLine **)pTVar31;
      local_c8 = local_c0;
      TransportLineGroup::getRelatedTransportLines(pTVar26,(vector *)&local_c8);
      puVar6 = local_c0;
      for (puVar15 = local_c8; puVar15 != puVar6; puVar15 = puVar15 + 1) {
        this_01 = (TransportLine *)*puVar15;
        pTVar11 = *(TransportLineGroup **)(this_01 + 0x28);
        if (pTVar11 != *(TransportLineGroup **)(pTVar26 + 0x28)) {
          if (param_3[0x4c3] == (MapDeserialiser)0x0) {
            Logging::log("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Belt/TransportLineDeserialiser.cpp"
                         ,0xa0,5,
                         "TransportLine %p interacts with TransportLine %p so they should be in the same group"
                        );
            TransportLine::logMembers(pTVar26);
            TransportLine::logMembers(this_01);
            this_00 = (DeserialiserException *)___cxa_allocate_exception(0x10);
            __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1B7v160006IDnEEPKc
                      (asStack_e0,"transport line groups are not consistent");
            DeserialiserException::DeserialiserException(this_00,asStack_e0);
                    /* WARNING: Subroutine does not return */
            ___cxa_throw(this_00,&DeserialiserException::typeinfo,
                         DeserialiserException::~DeserialiserException);
          }
          TransportLineGroup::merge(pTVar11,*(TransportLineGroup **)(pTVar26 + 0x28));
        }
      }
      pTVar31 = pTVar31 + 8;
      local_c0 = local_c8;
    } while (pTVar31 != pTVar29);
    if (local_c8 != (undefined8 *)0x0) {
      operator_delete(local_c8);
    }
  }
  plVar32 = local_98;
  if (pTVar24 != (TransportLine *)0x0) {
    local_a8 = pTVar24;
    operator_delete(pTVar24);
    plVar32 = local_98;
  }
joined_r0x00010041546c:
  for (; plVar32 != local_90; plVar32 = plVar32 + 1) {
    *(undefined1 *)(*plVar32 + 0x122) = 0;
  }
  local_90 = local_98;
  if (local_98 != (long *)0x0) {
    operator_delete(local_98);
  }
  if (local_80 != (long *)0x0) {
    local_78 = local_80;
    operator_delete(local_80);
  }
  return;
}



// ===== IDWithQuality<SignalIDBase>::apply  @ 0x1004677bc =====

/* IDWithQuality<SignalIDBase>::apply(IDWithQualityBackup&) */

void __thiscall
IDWithQuality<SignalIDBase>::apply(IDWithQuality<SignalIDBase> *this,IDWithQualityBackup *param_1)

{
  ulong uVar1;
  IDWithQualityBackup *pIVar2;
  IDWithQualityBackup IVar3;
  IDWithQuality<SignalIDBase> IVar4;
  
  SignalIDBase::applyBackup((SignalIDBase *)this,(string *)param_1);
  IVar3 = param_1[0x2f];
  uVar1 = *(ulong *)(param_1 + 0x20);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)(param_1 + 0x18);
    if (-1 < (char)IVar3) {
      pIVar2 = param_1 + 0x18;
    }
    IVar4 = (IDWithQuality<SignalIDBase>)PrototypeList<QualityPrototype>::parseSafe(pIVar2);
    if (IVar4 != (IDWithQuality<SignalIDBase>)0x0) {
      this[4] = IVar4;
      if ((char)param_1[0x2f] < '\0') {
        **(undefined1 **)(param_1 + 0x18) = 0;
        *(undefined8 *)(param_1 + 0x20) = 0;
        return;
      }
      param_1[0x18] = (IDWithQualityBackup)0x0;
      param_1[0x2f] = (IDWithQualityBackup)0x0;
    }
  }
  return;
}



// ===== ButtonStyleSpecification::apply  @ 0x100542604 =====

/* ButtonStyleSpecification::apply(agui::ButtonStyle&, OptionalFundamentalBase*) const */

void __thiscall
ButtonStyleSpecification::apply
          (ButtonStyleSpecification *this,ButtonStyle *param_1,OptionalFundamentalBase *param_2)

{
  undefined8 *puVar1;
  ulong uVar2;
  byte bVar3;
  undefined8 uVar4;
  uint uVar5;
  undefined8 uVar6;
  void *pvVar7;
  undefined8 *puVar8;
  float *pfVar9;
  undefined8 local_30;
  undefined8 uStack_28;
  
  StyleWithClickableGraphicalSetSpecification::apply
            ((StyleWithClickableGraphicalSetSpecification *)this,
             (StyleWithClickableGraphicalSet *)param_1,param_2);
  puVar8 = *(undefined8 **)(this + 0x110);
  if (puVar8 != (undefined8 *)0x0) {
    bVar3 = *(byte *)((long)puVar8 + 0x17);
    puVar1 = (undefined8 *)*puVar8;
    if (-1 < (char)bVar3) {
      puVar1 = puVar8;
    }
    uVar2 = puVar8[1];
    if (-1 < (char)bVar3) {
      uVar2 = (ulong)bVar3;
    }
    uVar6 = FontBank::getFont(*(undefined8 *)(_global + 0x270),puVar1,uVar2,0);
    *(undefined8 *)(param_1 + 0xb0) = uVar6;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  pfVar9 = *(float **)(this + 0x118);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_28;
    uVar6 = local_30;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xb8);
    *(undefined8 **)(param_1 + 0xb8) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x120);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_28;
    uVar6 = local_30;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xc0);
    *(undefined8 **)(param_1 + 0xc0) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x128);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_28;
    uVar6 = local_30;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 200);
    *(undefined8 **)(param_1 + 200) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x130);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_28;
    uVar6 = local_30;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xd0);
    *(undefined8 **)(param_1 + 0xd0) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x138);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_28;
    uVar6 = local_30;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xd8);
    *(undefined8 **)(param_1 + 0xd8) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x140);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_28;
    uVar6 = local_30;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xe0);
    *(undefined8 **)(param_1 + 0xe0) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x148);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_28;
    uVar6 = local_30;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xe8);
    *(undefined8 **)(param_1 + 0xe8) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x150);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_28;
    uVar6 = local_30;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xf0);
    *(undefined8 **)(param_1 + 0xf0) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x158);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    puVar8 = operator_new(0x10);
    puVar8[1] = uStack_28;
    *puVar8 = local_30;
    pvVar7 = *(void **)(param_1 + 0xf8);
    *(undefined8 **)(param_1 + 0xf8) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  if (this[0x164] != (ButtonStyleSpecification)0x0) {
    uVar5 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x160));
    *(uint *)(param_1 + 0x100) = uVar5;
    param_1[0x104] = (ButtonStyle)0x1;
  }
  if (this[0x169] != (ButtonStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x108) = (byte)this[0x168] | 0x100;
  }
  if (this[0x16b] != (ButtonStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x10a) = (byte)this[0x16a] | 0x100;
  }
  if (this[0x16d] != (ButtonStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x10c) = (byte)this[0x16c] | 0x100;
  }
  if (this[0x16f] != (ButtonStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x10e) = (byte)this[0x16e] | 0x100;
  }
  if (this[0x171] != (ButtonStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x110) = (byte)this[0x170] | 0x100;
  }
  return;
}



// ===== EmptyWidgetStyleSpecification::apply  @ 0x100544380 =====

/* EmptyWidgetStyleSpecification::apply(agui::EmptyWidgetStyle&, OptionalFundamentalBase*) const */

void __thiscall
EmptyWidgetStyleSpecification::apply
          (EmptyWidgetStyleSpecification *this,EmptyWidgetStyle *param_1,
          OptionalFundamentalBase *param_2)

{
  ElementImageSet *this_00;
  void *pvVar1;
  long lVar2;
  ElementImageSet *pEVar3;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  lVar2 = *(long *)(this + 0xb8);
  if (lVar2 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar2 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar2 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar2 + 0xd58));
    pEVar3 = (ElementImageSet *)**(undefined8 **)(this + 0xb8);
    this_00 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(this_00,pEVar3);
    pEVar3 = *(ElementImageSet **)(param_1 + 0x68);
    *(ElementImageSet **)(param_1 + 0x68) = this_00;
    if (pEVar3 != (ElementImageSet *)0x0) {
      pvVar1 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar3);
      operator_delete(pvVar1);
      return;
    }
  }
  return;
}



// ===== CheckBoxStyleSpecification::apply  @ 0x100544bf4 =====

/* CheckBoxStyleSpecification::apply(agui::CheckBoxStyle&, OptionalFundamentalBase*) const */

void __thiscall
CheckBoxStyleSpecification::apply
          (CheckBoxStyleSpecification *this,CheckBoxStyle *param_1,OptionalFundamentalBase *param_2)

{
  undefined8 *puVar1;
  ulong uVar2;
  byte bVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  void *pvVar6;
  undefined8 *puVar7;
  float *pfVar8;
  undefined8 local_30;
  undefined8 uStack_28;
  
  StyleWithClickableGraphicalSetSpecification::apply
            ((StyleWithClickableGraphicalSetSpecification *)this,
             (StyleWithClickableGraphicalSet *)param_1,param_2);
  puVar7 = *(undefined8 **)(this + 0x110);
  if (puVar7 != (undefined8 *)0x0) {
    bVar3 = *(byte *)((long)puVar7 + 0x17);
    puVar1 = (undefined8 *)*puVar7;
    if (-1 < (char)bVar3) {
      puVar1 = puVar7;
    }
    uVar2 = puVar7[1];
    if (-1 < (char)bVar3) {
      uVar2 = (ulong)bVar3;
    }
    uVar5 = FontBank::getFont(*(undefined8 *)(_global + 0x270),puVar1,uVar2,0);
    *(undefined8 *)(param_1 + 0xb0) = uVar5;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  pfVar8 = *(float **)(this + 0x118);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    uVar4 = uStack_28;
    uVar5 = local_30;
    puVar7 = operator_new(0x10);
    puVar7[1] = uVar4;
    *puVar7 = uVar5;
    pvVar6 = *(void **)(param_1 + 0xb8);
    *(undefined8 **)(param_1 + 0xb8) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0x120);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    puVar7 = operator_new(0x10);
    puVar7[1] = uStack_28;
    *puVar7 = local_30;
    pvVar6 = *(void **)(param_1 + 0xc0);
    *(undefined8 **)(param_1 + 0xc0) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  if (*(long *)(this + 0x128) != 0) {
    *(undefined8 *)(param_1 + 200) = *(undefined8 *)(*(long *)(this + 0x128) + 0xa0);
  }
  if (*(long *)(this + 0x130) != 0) {
    *(undefined8 *)(param_1 + 0xd0) = *(undefined8 *)(*(long *)(this + 0x130) + 0xa0);
  }
  if (*(long *)(this + 0x138) != 0) {
    *(undefined8 *)(param_1 + 0xd8) = *(undefined8 *)(*(long *)(this + 0x138) + 0xa0);
  }
  if (this[0x144] != (CheckBoxStyleSpecification)0x0) {
    *(undefined4 *)(param_1 + 0xe0) = *(undefined4 *)(this + 0x140);
    param_1[0xe4] = (CheckBoxStyle)0x1;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  return;
}



// ===== DropDownStyleSpecification::apply  @ 0x1005476a4 =====

/* DropDownStyleSpecification::apply(agui::DropDownStyle&, OptionalFundamentalBase*) const */

void __thiscall
DropDownStyleSpecification::apply
          (DropDownStyleSpecification *this,DropDownStyle *param_1,OptionalFundamentalBase *param_2)

{
  short sVar1;
  long *plVar2;
  undefined8 *puVar3;
  ButtonStyle *this_00;
  ListBoxStyle *this_01;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (*(long *)(this + 0xb8) != 0) {
    this_00 = *(ButtonStyle **)(param_1 + 0x68);
    if (this_00 == (ButtonStyle *)0x0) {
      this_00 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(this_00,(ButtonStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0x68);
      *(ButtonStyle **)(param_1 + 0x68) = this_00;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        this_00 = *(ButtonStyle **)(param_1 + 0x68);
      }
    }
    ButtonStyleSpecification::apply
              (*(ButtonStyleSpecification **)(this + 0xb8),this_00,(OptionalFundamentalBase *)0x0);
    puVar3 = *(undefined8 **)(this_00 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(this_00 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  if (*(long *)(this + 0xc0) != 0) {
    *(undefined8 *)(param_1 + 0x70) = *(undefined8 *)(*(long *)(this + 0xc0) + 0xa0);
  }
  if (*(long *)(this + 200) != 0) {
    this_01 = *(ListBoxStyle **)(param_1 + 0x80);
    if (this_01 == (ListBoxStyle *)0x0) {
      this_01 = operator_new(0x78);
      agui::ListBoxStyle::ListBoxStyle(this_01,(ListBoxStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0x80);
      *(ListBoxStyle **)(param_1 + 0x80) = this_01;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        this_01 = *(ListBoxStyle **)(param_1 + 0x80);
      }
    }
    ListBoxStyleSpecification::apply
              (*(ListBoxStyleSpecification **)(this + 200),this_01,(OptionalFundamentalBase *)0x0);
    puVar3 = *(undefined8 **)(this_01 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(this_01 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  if (this[0xd2] != (DropDownStyleSpecification)0x0) {
    sVar1 = GuiConstants::getScaled<short>(*(short *)(this + 0xd0));
    *(short *)(param_1 + 0x88) = sVar1;
    param_1[0x8a] = (DropDownStyle)0x1;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  if (this[0xd8] != (DropDownStyleSpecification)0x0) {
    *(DropDownStyleSpecification **)(param_1 + 0x78) = this + 0xe0;
  }
  return;
}



// ===== HorizontalFlowStyleSpecification::apply  @ 0x10054c3c4 =====

/* HorizontalFlowStyleSpecification::apply(agui::HorizontalFlowStyle&, OptionalFundamentalBase*)
   const */

void __thiscall
HorizontalFlowStyleSpecification::apply
          (HorizontalFlowStyleSpecification *this,HorizontalFlowStyle *param_1,
          OptionalFundamentalBase *param_2)

{
  int iVar1;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (this[0xb8] != (HorizontalFlowStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0xb4));
    *(int *)(param_1 + 0x68) = iVar1;
    param_1[0x6c] = (HorizontalFlowStyle)0x1;
  }
  return;
}



// ===== VerticalFlowStyleSpecification::apply  @ 0x10054c404 =====

/* VerticalFlowStyleSpecification::apply(agui::VerticalFlowStyle&, OptionalFundamentalBase*) const
    */

void __thiscall
VerticalFlowStyleSpecification::apply
          (VerticalFlowStyleSpecification *this,VerticalFlowStyle *param_1,
          OptionalFundamentalBase *param_2)

{
  int iVar1;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (this[0xb8] != (VerticalFlowStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0xb4));
    *(int *)(param_1 + 0x68) = iVar1;
    param_1[0x6c] = (VerticalFlowStyle)0x1;
  }
  return;
}



// ===== FrameStyleSpecification::apply  @ 0x10054d044 =====

/* FrameStyleSpecification::apply(agui::FrameStyle&, OptionalFundamentalBase*) const */

void __thiscall
FrameStyleSpecification::apply
          (FrameStyleSpecification *this,FrameStyle *param_1,OptionalFundamentalBase *param_2)

{
  int iVar1;
  ElementImageSet *pEVar2;
  void *pvVar3;
  long *plVar4;
  undefined8 *puVar5;
  undefined8 *puVar6;
  HorizontalFlowStyle *pHVar7;
  VerticalFlowStyle *this_00;
  EmptyWidgetStyle *this_01;
  LabelStyle *this_02;
  long lVar8;
  ElementImageSet *pEVar9;
  StyleSpecification *pSVar10;
  undefined8 uVar11;
  undefined8 uVar12;
  undefined8 uVar13;
  undefined8 uVar14;
  undefined8 uVar15;
  undefined8 uVar16;
  undefined8 uVar17;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (*(undefined8 **)(this + 0xb8) != (undefined8 *)0x0) {
    pEVar9 = (ElementImageSet *)**(undefined8 **)(this + 0xb8);
    pEVar2 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar2,pEVar9);
    pEVar9 = *(ElementImageSet **)(param_1 + 0x68);
    *(ElementImageSet **)(param_1 + 0x68) = pEVar2;
    if (pEVar9 != (ElementImageSet *)0x0) {
      pvVar3 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar9);
      operator_delete(pvVar3);
    }
  }
  if (*(long *)(this + 0xc0) != 0) {
    pHVar7 = *(HorizontalFlowStyle **)(param_1 + 0x90);
    if (pHVar7 == (HorizontalFlowStyle *)0x0) {
      pHVar7 = operator_new(0x70);
      agui::HorizontalFlowStyle::HorizontalFlowStyle(pHVar7,(HorizontalFlowStyle *)0x0);
      plVar4 = *(long **)(param_1 + 0x90);
      *(HorizontalFlowStyle **)(param_1 + 0x90) = pHVar7;
      if (plVar4 != (long *)0x0) {
        (**(code **)(*plVar4 + 8))();
        pHVar7 = *(HorizontalFlowStyle **)(param_1 + 0x90);
      }
    }
    pSVar10 = *(StyleSpecification **)(this + 0xc0);
    StyleSpecification::apply(pSVar10,(Style *)pHVar7,(OptionalFundamentalBase *)0x0);
    if (pSVar10[0xb8] != (StyleSpecification)0x0) {
      iVar1 = GuiConstants::getScaled<int>(*(int *)(pSVar10 + 0xb4));
      *(int *)(pHVar7 + 0x68) = iVar1;
      *(Style *)(pHVar7 + 0x6c) = (Style)0x1;
    }
    puVar5 = *(undefined8 **)(pHVar7 + 0x18);
    if (puVar5 == (undefined8 *)0x0) {
      puVar5 = operator_new(0x20);
      puVar5[1] = 0;
      *puVar5 = 0;
      puVar5[3] = 0;
      puVar5[2] = 0;
      *(undefined8 **)(pHVar7 + 0x18) = puVar5;
    }
    puVar5[3] = param_1;
  }
  if (*(long *)(this + 200) != 0) {
    this_00 = *(VerticalFlowStyle **)(param_1 + 0x88);
    if (this_00 == (VerticalFlowStyle *)0x0) {
      this_00 = operator_new(0x70);
      agui::VerticalFlowStyle::VerticalFlowStyle(this_00,(VerticalFlowStyle *)0x0);
      plVar4 = *(long **)(param_1 + 0x88);
      *(VerticalFlowStyle **)(param_1 + 0x88) = this_00;
      if (plVar4 != (long *)0x0) {
        (**(code **)(*plVar4 + 8))();
        this_00 = *(VerticalFlowStyle **)(param_1 + 0x88);
      }
    }
    pSVar10 = *(StyleSpecification **)(this + 200);
    StyleSpecification::apply(pSVar10,(Style *)this_00,(OptionalFundamentalBase *)0x0);
    if (pSVar10[0xb8] != (StyleSpecification)0x0) {
      iVar1 = GuiConstants::getScaled<int>(*(int *)(pSVar10 + 0xb4));
      *(int *)(this_00 + 0x68) = iVar1;
      *(Style *)(this_00 + 0x6c) = (Style)0x1;
    }
    puVar5 = *(undefined8 **)(this_00 + 0x18);
    if (puVar5 == (undefined8 *)0x0) {
      puVar5 = operator_new(0x20);
      puVar5[1] = 0;
      *puVar5 = 0;
      puVar5[3] = 0;
      puVar5[2] = 0;
      *(undefined8 **)(this_00 + 0x18) = puVar5;
    }
    puVar5[3] = param_1;
  }
  if (*(long *)(this + 0xd0) != 0) {
    pHVar7 = *(HorizontalFlowStyle **)(param_1 + 0x98);
    if (pHVar7 == (HorizontalFlowStyle *)0x0) {
      pHVar7 = operator_new(0x70);
      agui::HorizontalFlowStyle::HorizontalFlowStyle(pHVar7,(HorizontalFlowStyle *)0x0);
      plVar4 = *(long **)(param_1 + 0x98);
      *(HorizontalFlowStyle **)(param_1 + 0x98) = pHVar7;
      if (plVar4 != (long *)0x0) {
        (**(code **)(*plVar4 + 8))();
        pHVar7 = *(HorizontalFlowStyle **)(param_1 + 0x98);
      }
    }
    pSVar10 = *(StyleSpecification **)(this + 0xd0);
    StyleSpecification::apply(pSVar10,(Style *)pHVar7,(OptionalFundamentalBase *)0x0);
    if (pSVar10[0xb8] != (StyleSpecification)0x0) {
      iVar1 = GuiConstants::getScaled<int>(*(int *)(pSVar10 + 0xb4));
      *(int *)(pHVar7 + 0x68) = iVar1;
      *(Style *)(pHVar7 + 0x6c) = (Style)0x1;
    }
    puVar5 = *(undefined8 **)(pHVar7 + 0x18);
    if (puVar5 == (undefined8 *)0x0) {
      puVar5 = operator_new(0x20);
      puVar5[1] = 0;
      *puVar5 = 0;
      puVar5[3] = 0;
      puVar5[2] = 0;
      *(undefined8 **)(pHVar7 + 0x18) = puVar5;
    }
    puVar5[3] = param_1;
  }
  if (*(long *)(this + 0xd8) != 0) {
    this_01 = *(EmptyWidgetStyle **)(param_1 + 0xa0);
    if (this_01 == (EmptyWidgetStyle *)0x0) {
      this_01 = operator_new(0x70);
      agui::EmptyWidgetStyle::EmptyWidgetStyle(this_01,(EmptyWidgetStyle *)0x0);
      plVar4 = *(long **)(param_1 + 0xa0);
      *(EmptyWidgetStyle **)(param_1 + 0xa0) = this_01;
      if (plVar4 != (long *)0x0) {
        (**(code **)(*plVar4 + 8))();
        this_01 = *(EmptyWidgetStyle **)(param_1 + 0xa0);
      }
    }
    EmptyWidgetStyleSpecification::apply
              (*(EmptyWidgetStyleSpecification **)(this + 0xd8),this_01,
               (OptionalFundamentalBase *)0x0);
    puVar5 = *(undefined8 **)(this_01 + 0x18);
    if (puVar5 == (undefined8 *)0x0) {
      puVar5 = operator_new(0x20);
      puVar5[1] = 0;
      *puVar5 = 0;
      puVar5[3] = 0;
      puVar5[2] = 0;
      *(undefined8 **)(this_01 + 0x18) = puVar5;
    }
    puVar5[3] = param_1;
  }
  if (*(long *)(this + 0xe0) != 0) {
    this_02 = *(LabelStyle **)(param_1 + 0xa8);
    if (this_02 == (LabelStyle *)0x0) {
      this_02 = operator_new(200);
      agui::LabelStyle::LabelStyle(this_02,(LabelStyle *)0x0);
      plVar4 = *(long **)(param_1 + 0xa8);
      *(LabelStyle **)(param_1 + 0xa8) = this_02;
      if (plVar4 != (long *)0x0) {
        (**(code **)(*plVar4 + 8))();
        this_02 = *(LabelStyle **)(param_1 + 0xa8);
      }
    }
    LabelStyleSpecification::apply
              (*(LabelStyleSpecification **)(this + 0xe0),this_02,(OptionalFundamentalBase *)0x0);
    puVar5 = *(undefined8 **)(this_02 + 0x18);
    if (puVar5 == (undefined8 *)0x0) {
      puVar5 = operator_new(0x20);
      puVar5[1] = 0;
      *puVar5 = 0;
      puVar5[3] = 0;
      puVar5[2] = 0;
      *(undefined8 **)(this_02 + 0x18) = puVar5;
    }
    puVar5[3] = param_1;
  }
  if (this[0xf9] != (FrameStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x70) = (byte)this[0xf8] | 0x100;
  }
  if (this[0xfb] != (FrameStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x72) = (byte)this[0xfa] | 0x100;
  }
  if (*(undefined8 **)(this + 0xe8) != (undefined8 *)0x0) {
    pEVar9 = (ElementImageSet *)**(undefined8 **)(this + 0xe8);
    pEVar2 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar2,pEVar9);
    pEVar9 = *(ElementImageSet **)(param_1 + 0x78);
    *(ElementImageSet **)(param_1 + 0x78) = pEVar2;
    if (pEVar9 != (ElementImageSet *)0x0) {
      pvVar3 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar9);
      operator_delete(pvVar3);
    }
  }
  lVar8 = *(long *)(this + 0xf0);
  if (lVar8 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar8 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar8 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar8 + 0xd58));
    pEVar9 = (ElementImageSet *)**(undefined8 **)(this + 0xf0);
    pEVar2 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar2,pEVar9);
    pEVar9 = *(ElementImageSet **)(param_1 + 0x80);
    *(ElementImageSet **)(param_1 + 0x80) = pEVar2;
    if (pEVar9 != (ElementImageSet *)0x0) {
      pvVar3 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar9);
      operator_delete(pvVar3);
    }
  }
  lVar8 = *(long *)(this + 0x100);
  if (lVar8 != 0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(lVar8 + 4));
    *(int *)(*(long *)(lVar8 + 0x968) + 4) = iVar1;
    puVar6 = *(undefined8 **)(*(long *)(this + 0x100) + 0x968);
    puVar5 = operator_new(0x80);
    uVar11 = puVar6[4];
    uVar13 = puVar6[7];
    uVar12 = puVar6[6];
    uVar17 = puVar6[1];
    uVar16 = *puVar6;
    uVar15 = puVar6[3];
    uVar14 = puVar6[2];
    puVar5[5] = puVar6[5];
    puVar5[4] = uVar11;
    puVar5[7] = uVar13;
    puVar5[6] = uVar12;
    puVar5[1] = uVar17;
    *puVar5 = uVar16;
    puVar5[3] = uVar15;
    puVar5[2] = uVar14;
    uVar11 = puVar6[0xc];
    uVar13 = puVar6[0xf];
    uVar12 = puVar6[0xe];
    uVar17 = puVar6[9];
    uVar16 = puVar6[8];
    uVar15 = puVar6[0xb];
    uVar14 = puVar6[10];
    puVar5[0xd] = puVar6[0xd];
    puVar5[0xc] = uVar11;
    puVar5[0xf] = uVar13;
    puVar5[0xe] = uVar12;
    puVar5[9] = uVar17;
    puVar5[8] = uVar16;
    puVar5[0xb] = uVar15;
    puVar5[10] = uVar14;
    pvVar3 = *(void **)(param_1 + 0xb0);
    *(undefined8 **)(param_1 + 0xb0) = puVar5;
    if (pvVar3 != (void *)0x0) {
      operator_delete(pvVar3);
      return;
    }
  }
  return;
}



// ===== LabelStyleSpecification::apply  @ 0x100556694 =====

/* LabelStyleSpecification::apply(agui::LabelStyle&, OptionalFundamentalBase*) const */

void __thiscall
LabelStyleSpecification::apply
          (LabelStyleSpecification *this,LabelStyle *param_1,OptionalFundamentalBase *param_2)

{
  undefined8 *puVar1;
  ulong uVar2;
  byte bVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  void *pvVar6;
  undefined8 *puVar7;
  float *pfVar8;
  undefined8 local_30;
  undefined8 uStack_28;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  puVar7 = *(undefined8 **)(this + 0xb8);
  if (puVar7 != (undefined8 *)0x0) {
    bVar3 = *(byte *)((long)puVar7 + 0x17);
    puVar1 = (undefined8 *)*puVar7;
    if (-1 < (char)bVar3) {
      puVar1 = puVar7;
    }
    uVar2 = puVar7[1];
    if (-1 < (char)bVar3) {
      uVar2 = (ulong)bVar3;
    }
    uVar5 = FontBank::getFont(*(undefined8 *)(_global + 0x270),puVar1,uVar2,0);
    *(undefined8 *)(param_1 + 0x68) = uVar5;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  pfVar8 = *(float **)(this + 0xc0);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    uVar4 = uStack_28;
    uVar5 = local_30;
    puVar7 = operator_new(0x10);
    puVar7[1] = uVar4;
    *puVar7 = uVar5;
    pvVar6 = *(void **)(param_1 + 0x70);
    *(undefined8 **)(param_1 + 0x70) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 200);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    uVar4 = uStack_28;
    uVar5 = local_30;
    puVar7 = operator_new(0x10);
    puVar7[1] = uVar4;
    *puVar7 = uVar5;
    pvVar6 = *(void **)(param_1 + 0x78);
    *(undefined8 **)(param_1 + 0x78) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0xd0);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    uVar4 = uStack_28;
    uVar5 = local_30;
    puVar7 = operator_new(0x10);
    puVar7[1] = uVar4;
    *puVar7 = uVar5;
    pvVar6 = *(void **)(param_1 + 0x80);
    *(undefined8 **)(param_1 + 0x80) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0xd8);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    uVar4 = uStack_28;
    uVar5 = local_30;
    puVar7 = operator_new(0x10);
    puVar7[1] = uVar4;
    *puVar7 = uVar5;
    pvVar6 = *(void **)(param_1 + 0x88);
    *(undefined8 **)(param_1 + 0x88) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0xe0);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    uVar4 = uStack_28;
    uVar5 = local_30;
    puVar7 = operator_new(0x10);
    puVar7[1] = uVar4;
    *puVar7 = uVar5;
    pvVar6 = *(void **)(param_1 + 0x90);
    *(undefined8 **)(param_1 + 0x90) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0xe8);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    uVar4 = uStack_28;
    uVar5 = local_30;
    puVar7 = operator_new(0x10);
    puVar7[1] = uVar4;
    *puVar7 = uVar5;
    pvVar6 = *(void **)(param_1 + 0x98);
    *(undefined8 **)(param_1 + 0x98) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  if (this[0xf9] != (LabelStyleSpecification)0x0) {
    agui::LabelStyle::setSingleLine(param_1,(bool)this[0xf8]);
  }
  if (this[0xfb] != (LabelStyleSpecification)0x0) {
    agui::LabelStyle::setUnderlined(param_1,(bool)this[0xfa]);
  }
  if (*(RichTextSetting **)(this + 0xf0) != (RichTextSetting *)0x0) {
    agui::LabelStyle::setRichTextSetting(param_1,*(RichTextSetting **)(this + 0xf0));
  }
  pfVar8 = *(float **)(this + 0x100);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    uVar4 = uStack_28;
    uVar5 = local_30;
    puVar7 = operator_new(0x10);
    puVar7[1] = uVar4;
    *puVar7 = uVar5;
    pvVar6 = *(void **)(param_1 + 0xa8);
    *(undefined8 **)(param_1 + 0xa8) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0x108);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    uVar4 = uStack_28;
    uVar5 = local_30;
    puVar7 = operator_new(0x10);
    puVar7[1] = uVar4;
    *puVar7 = uVar5;
    pvVar6 = *(void **)(param_1 + 0xb0);
    *(undefined8 **)(param_1 + 0xb0) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0x110);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    puVar7 = operator_new(0x10);
    puVar7[1] = uStack_28;
    *puVar7 = local_30;
    pvVar6 = *(void **)(param_1 + 0xb8);
    *(undefined8 **)(param_1 + 0xb8) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  return;
}



// ===== LineStyleSpecification::apply  @ 0x1005570e8 =====

/* LineStyleSpecification::apply(agui::LineStyle&, OptionalFundamentalBase*) const */

void __thiscall
LineStyleSpecification::apply
          (LineStyleSpecification *this,LineStyle *param_1,OptionalFundamentalBase *param_2)

{
  int iVar1;
  long lVar2;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  lVar2 = *(long *)(this + 0xb8);
  if (lVar2 != 0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(lVar2 + 4));
    *(int *)(*(long *)(lVar2 + 0x968) + 4) = iVar1;
    agui::LineStyle::setBorder(param_1,*(BorderImageSet **)(*(long *)(this + 0xb8) + 0x968));
    return;
  }
  return;
}



// ===== ListBoxStyleSpecification::apply  @ 0x100557d98 =====

/* ListBoxStyleSpecification::apply(agui::ListBoxStyle&, OptionalFundamentalBase*) const */

void __thiscall
ListBoxStyleSpecification::apply
          (ListBoxStyleSpecification *this,ListBoxStyle *param_1,OptionalFundamentalBase *param_2)

{
  long *plVar1;
  undefined8 *puVar2;
  ButtonStyle *this_00;
  ScrollPaneStyle *this_01;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (*(long *)(this + 0xb8) != 0) {
    this_00 = *(ButtonStyle **)(param_1 + 0x68);
    if (this_00 == (ButtonStyle *)0x0) {
      this_00 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(this_00,(ButtonStyle *)0x0);
      plVar1 = *(long **)(param_1 + 0x68);
      *(ButtonStyle **)(param_1 + 0x68) = this_00;
      if (plVar1 != (long *)0x0) {
        (**(code **)(*plVar1 + 8))();
        this_00 = *(ButtonStyle **)(param_1 + 0x68);
      }
    }
    ButtonStyleSpecification::apply
              (*(ButtonStyleSpecification **)(this + 0xb8),this_00,(OptionalFundamentalBase *)0x0);
    puVar2 = *(undefined8 **)(this_00 + 0x18);
    if (puVar2 == (undefined8 *)0x0) {
      puVar2 = operator_new(0x20);
      puVar2[1] = 0;
      *puVar2 = 0;
      puVar2[3] = 0;
      puVar2[2] = 0;
      *(undefined8 **)(this_00 + 0x18) = puVar2;
    }
    puVar2[3] = param_1;
  }
  if (*(long *)(this + 0xc0) != 0) {
    this_01 = *(ScrollPaneStyle **)(param_1 + 0x70);
    if (this_01 == (ScrollPaneStyle *)0x0) {
      this_01 = operator_new(0xd8);
      agui::ScrollPaneStyle::ScrollPaneStyle(this_01,(ScrollPaneStyle *)0x0);
      plVar1 = *(long **)(param_1 + 0x70);
      *(ScrollPaneStyle **)(param_1 + 0x70) = this_01;
      if (plVar1 != (long *)0x0) {
        (**(code **)(*plVar1 + 8))();
        this_01 = *(ScrollPaneStyle **)(param_1 + 0x70);
      }
    }
    ScrollPaneStyleSpecification::apply
              (*(ScrollPaneStyleSpecification **)(this + 0xc0),this_01,
               (OptionalFundamentalBase *)0x0);
    puVar2 = *(undefined8 **)(this_01 + 0x18);
    if (puVar2 == (undefined8 *)0x0) {
      puVar2 = operator_new(0x20);
      puVar2[1] = 0;
      *puVar2 = 0;
      puVar2[3] = 0;
      puVar2[2] = 0;
      *(undefined8 **)(this_01 + 0x18) = puVar2;
    }
    puVar2[3] = param_1;
  }
  return;
}



// ===== ProgressBarStyleSpecification::apply  @ 0x100559da0 =====

/* ProgressBarStyleSpecification::apply(agui::ProgressBarStyle&, OptionalFundamentalBase*) const */

void __thiscall
ProgressBarStyleSpecification::apply
          (ProgressBarStyleSpecification *this,ProgressBarStyle *param_1,
          OptionalFundamentalBase *param_2)

{
  ulong uVar1;
  double *pdVar2;
  byte bVar3;
  double *pdVar4;
  short sVar5;
  uint uVar6;
  undefined8 *puVar7;
  void *pvVar8;
  ElementImageSet *pEVar9;
  undefined8 uVar10;
  float *pfVar11;
  long *plVar12;
  void *pvVar13;
  double *pdVar14;
  undefined8 *puVar15;
  ElementImageSet *pEVar16;
  void *pvVar17;
  ElementImageSet *local_b8;
  double local_b0;
  double dStack_a8;
  uint local_a0;
  void *local_90;
  double *pdStack_88;
  double *local_80;
  double local_70;
  double dStack_68;
  uint local_60;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (this[0xb8] != (ProgressBarStyleSpecification)0x0) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xb4));
    *(uint *)(param_1 + 0x68) = uVar6;
    param_1[0x6c] = (ProgressBarStyle)0x1;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  pfVar11 = *(float **)(this + 0xc0);
  if (pfVar11 != (float *)0x0) {
    agui::Color::Color((Color *)&local_90,*pfVar11,pfVar11[1],pfVar11[2],pfVar11[3]);
    pdVar14 = pdStack_88;
    pvVar8 = local_90;
    puVar7 = operator_new(0x10);
    puVar7[1] = pdVar14;
    *puVar7 = pvVar8;
    pvVar8 = *(void **)(param_1 + 0x70);
    *(undefined8 **)(param_1 + 0x70) = puVar7;
    if (pvVar8 != (void *)0x0) {
      operator_delete(pvVar8);
    }
  }
  plVar12 = *(long **)(this + 200);
  if (plVar12 == (long *)0x0) {
LAB_10055a024:
    if (*(undefined8 **)(this + 0xd0) != (undefined8 *)0x0) {
      pEVar16 = (ElementImageSet *)**(undefined8 **)(this + 0xd0);
      pEVar9 = operator_new(600);
      agui::ElementImageSet::ElementImageSet(pEVar9,pEVar16);
      pEVar16 = *(ElementImageSet **)(param_1 + 0x88);
      *(ElementImageSet **)(param_1 + 0x88) = pEVar9;
      if (pEVar16 != (ElementImageSet *)0x0) {
        pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar16);
        operator_delete(pvVar8);
      }
    }
    if (*(undefined8 **)(this + 0xd8) != (undefined8 *)0x0) {
      pEVar16 = (ElementImageSet *)**(undefined8 **)(this + 0xd8);
      pEVar9 = operator_new(600);
      agui::ElementImageSet::ElementImageSet(pEVar9,pEVar16);
      pEVar16 = *(ElementImageSet **)(param_1 + 0x80);
      *(ElementImageSet **)(param_1 + 0x80) = pEVar9;
      if (pEVar16 != (ElementImageSet *)0x0) {
        pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar16);
        operator_delete(pvVar8);
      }
    }
    puVar7 = *(undefined8 **)(this + 0xe8);
    if (puVar7 != (undefined8 *)0x0) {
      bVar3 = *(byte *)((long)puVar7 + 0x17);
      puVar15 = (undefined8 *)*puVar7;
      if (-1 < (char)bVar3) {
        puVar15 = puVar7;
      }
      uVar1 = puVar7[1];
      if (-1 < (char)bVar3) {
        uVar1 = (ulong)bVar3;
      }
      uVar10 = FontBank::getFont(*(undefined8 *)(_global + 0x270),puVar15,uVar1,0);
      *(undefined8 *)(param_1 + 0x90) = uVar10;
      if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
        agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
      }
    }
    pfVar11 = *(float **)(this + 0xf0);
    if (pfVar11 != (float *)0x0) {
      agui::Color::Color((Color *)&local_90,*pfVar11,pfVar11[1],pfVar11[2],pfVar11[3]);
      pdVar14 = pdStack_88;
      pvVar8 = local_90;
      puVar7 = operator_new(0x10);
      puVar7[1] = pdVar14;
      *puVar7 = pvVar8;
      pvVar8 = *(void **)(param_1 + 0x98);
      *(undefined8 **)(param_1 + 0x98) = puVar7;
      if (pvVar8 != (void *)0x0) {
        operator_delete(pvVar8);
      }
    }
    pfVar11 = *(float **)(this + 0xf8);
    if (pfVar11 != (float *)0x0) {
      agui::Color::Color((Color *)&local_90,*pfVar11,pfVar11[1],pfVar11[2],pfVar11[3]);
      pdVar14 = pdStack_88;
      pvVar8 = local_90;
      puVar7 = operator_new(0x10);
      puVar7[1] = pdVar14;
      *puVar7 = pvVar8;
      pvVar8 = *(void **)(param_1 + 0xa0);
      *(undefined8 **)(param_1 + 0xa0) = puVar7;
      if (pvVar8 != (void *)0x0) {
        operator_delete(pvVar8);
      }
    }
    if (this[0x101] != (ProgressBarStyleSpecification)0x0) {
      *(ushort *)(param_1 + 0xa8) = (byte)this[0x100] | 0x100;
      if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
        agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
      }
    }
    if (this[0x104] != (ProgressBarStyleSpecification)0x0) {
      sVar5 = GuiConstants::getScaled<short>(*(short *)(this + 0x102));
      *(short *)(param_1 + 0xaa) = sVar5;
      param_1[0xac] = (ProgressBarStyle)0x1;
      if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
        agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
      }
    }
    return;
  }
  pdStack_88 = (double *)0x0;
  local_80 = (double *)0x0;
  local_90 = (void *)0x0;
  std::vector<agui::ProgressBarStyle::OtherColor,std::allocator<agui::ProgressBarStyle::OtherColor>>
  ::reserve((vector<agui::ProgressBarStyle::OtherColor,std::allocator<agui::ProgressBarStyle::OtherColor>>
             *)&local_90,(plVar12[1] - *plVar12 >> 3) * -0x3333333333333333);
  pdVar14 = (double *)**(long **)(this + 200);
  pdVar2 = (double *)(*(long **)(this + 200))[1];
joined_r0x000100559e70:
  if (pdVar14 != pdVar2) {
    do {
      if (*(char *)(pdVar14 + 3) == '\0') {
        local_b0 = (double)((ulong)local_b0 & 0xffffffffffffff00);
        local_a0 = local_a0 & 0xffffff00;
        puVar7 = (undefined8 *)pdVar14[4];
        if (puVar7 == (undefined8 *)0x0) goto LAB_100559ef4;
LAB_100559ecc:
        local_b8 = (ElementImageSet *)*puVar7;
        if (local_80 <= pdStack_88) goto LAB_100559e7c;
      }
      else {
        agui::Color::Color((Color *)&local_70,*(float *)(pdVar14 + 1),
                           *(float *)((long)pdVar14 + 0xc),*(float *)(pdVar14 + 2),
                           *(float *)((long)pdVar14 + 0x14));
        dStack_a8 = dStack_68;
        local_b0 = local_70;
        local_a0 = CONCAT31(local_a0._1_3_,1);
        puVar7 = (undefined8 *)pdVar14[4];
        if (puVar7 != (undefined8 *)0x0) goto LAB_100559ecc;
LAB_100559ef4:
        local_b8 = (ElementImageSet *)0x0;
        if (local_80 <= pdStack_88) goto LAB_100559e7c;
      }
      pdVar4 = pdStack_88;
      dStack_68 = dStack_a8;
      local_70 = local_b0;
      local_60 = local_a0;
      *pdStack_88 = *pdVar14;
      pdStack_88[2] = dStack_a8;
      pdStack_88[1] = local_b0;
      *(uint *)(pdStack_88 + 3) = local_a0;
      *(ElementImageSet *)(pdStack_88 + 4) = (ElementImageSet)0x0;
      *(undefined1 *)(pdStack_88 + 0x4f) = 0;
      if (local_b8 != (ElementImageSet *)0x0) {
        agui::ElementImageSet::ElementImageSet((ElementImageSet *)(pdStack_88 + 4),local_b8);
        *(undefined1 *)(pdVar4 + 0x4f) = 1;
      }
      pdStack_88 = pdVar4 + 0x50;
      pdVar14 = pdVar14 + 5;
      if (pdVar14 == pdVar2) break;
    } while( true );
  }
  puVar7 = operator_new(0x18);
  puVar7[1] = pdStack_88;
  *puVar7 = local_90;
  puVar7[2] = local_80;
  pdStack_88 = (void *)0x0;
  local_80 = (double *)0x0;
  local_90 = (void *)0x0;
  puVar15 = *(undefined8 **)(param_1 + 0x78);
  *(undefined8 **)(param_1 + 0x78) = puVar7;
  if (puVar15 != (undefined8 *)0x0) {
    pvVar8 = (void *)*puVar15;
    if (pvVar8 != (void *)0x0) {
      pvVar17 = pvVar8;
      pvVar13 = (void *)puVar15[1];
      if ((void *)puVar15[1] != pvVar8) {
        do {
          pvVar17 = (void *)((long)pvVar13 + -0x280);
          if (*(char *)((long)pvVar13 + -8) != '\0') {
            agui::ElementImageSet::~ElementImageSet((ElementImageSet *)((long)pvVar13 + -0x260));
          }
          pvVar13 = pvVar17;
        } while (pvVar17 != pvVar8);
        pvVar17 = (void *)*puVar15;
      }
      puVar15[1] = pvVar8;
      operator_delete(pvVar17);
    }
    operator_delete(puVar15);
    pvVar8 = local_90;
    pdVar14 = pdStack_88;
    if (local_90 != (void *)0x0) {
      while (pvVar17 = pdVar14, pvVar17 != pvVar8) {
        pdVar14 = (void *)((long)pvVar17 + -0x280);
        if (*(char *)((long)pvVar17 + -8) != '\0') {
          agui::ElementImageSet::~ElementImageSet((ElementImageSet *)((long)pvVar17 + -0x260));
        }
      }
      pdStack_88 = pvVar8;
      operator_delete(local_90);
    }
  }
  goto LAB_10055a024;
LAB_100559e7c:
  std::vector<agui::ProgressBarStyle::OtherColor,std::allocator<agui::ProgressBarStyle::OtherColor>>
  ::__emplace_back_slow_path<double_const&,std::optional<agui::Color>,agui::ElementImageSet*>
            ((vector<agui::ProgressBarStyle::OtherColor,std::allocator<agui::ProgressBarStyle::OtherColor>>
              *)&local_90,pdVar14,(optional *)&local_b0,&local_b8);
  pdVar14 = pdVar14 + 5;
  goto joined_r0x000100559e70;
}



// ===== RadioButtonStyleSpecification::apply  @ 0x10055a9e4 =====

/* RadioButtonStyleSpecification::apply(agui::RadioButtonStyle&, OptionalFundamentalBase*) const */

void __thiscall
RadioButtonStyleSpecification::apply
          (RadioButtonStyleSpecification *this,RadioButtonStyle *param_1,
          OptionalFundamentalBase *param_2)

{
  undefined8 *puVar1;
  ulong uVar2;
  byte bVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  void *pvVar6;
  undefined8 *puVar7;
  float *pfVar8;
  undefined8 local_30;
  undefined8 uStack_28;
  
  StyleWithClickableGraphicalSetSpecification::apply
            ((StyleWithClickableGraphicalSetSpecification *)this,
             (StyleWithClickableGraphicalSet *)param_1,param_2);
  puVar7 = *(undefined8 **)(this + 0x110);
  if (puVar7 != (undefined8 *)0x0) {
    bVar3 = *(byte *)((long)puVar7 + 0x17);
    puVar1 = (undefined8 *)*puVar7;
    if (-1 < (char)bVar3) {
      puVar1 = puVar7;
    }
    uVar2 = puVar7[1];
    if (-1 < (char)bVar3) {
      uVar2 = (ulong)bVar3;
    }
    uVar5 = FontBank::getFont(*(undefined8 *)(_global + 0x270),puVar1,uVar2,0);
    *(undefined8 *)(param_1 + 0xb0) = uVar5;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  pfVar8 = *(float **)(this + 0x118);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    uVar4 = uStack_28;
    uVar5 = local_30;
    puVar7 = operator_new(0x10);
    puVar7[1] = uVar4;
    *puVar7 = uVar5;
    pvVar6 = *(void **)(param_1 + 0xb8);
    *(undefined8 **)(param_1 + 0xb8) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0x120);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    puVar7 = operator_new(0x10);
    puVar7[1] = uStack_28;
    *puVar7 = local_30;
    pvVar6 = *(void **)(param_1 + 0xc0);
    *(undefined8 **)(param_1 + 0xc0) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  if (this[300] != (RadioButtonStyleSpecification)0x0) {
    *(undefined4 *)(param_1 + 200) = *(undefined4 *)(this + 0x128);
    param_1[0xcc] = (RadioButtonStyle)0x1;
  }
  return;
}



// ===== ScrollPaneStyleSpecification::apply  @ 0x10055b358 =====

/* ScrollPaneStyleSpecification::apply(agui::ScrollPaneStyle&, OptionalFundamentalBase*) const */

void __thiscall
ScrollPaneStyleSpecification::apply
          (ScrollPaneStyleSpecification *this,ScrollPaneStyle *param_1,
          OptionalFundamentalBase *param_2)

{
  int iVar1;
  long *plVar2;
  undefined8 *puVar3;
  ElementImageSet *pEVar4;
  void *pvVar5;
  VerticalFlowStyle *this_00;
  ScrollBarStyle *pSVar6;
  long lVar7;
  StyleSpecification *this_01;
  ElementImageSet *pEVar8;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (*(long *)(this + 0xb8) != 0) {
    this_00 = *(VerticalFlowStyle **)(param_1 + 0x68);
    if (this_00 == (VerticalFlowStyle *)0x0) {
      this_00 = operator_new(0x70);
      agui::VerticalFlowStyle::VerticalFlowStyle(this_00,(VerticalFlowStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0x68);
      *(VerticalFlowStyle **)(param_1 + 0x68) = this_00;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        this_00 = *(VerticalFlowStyle **)(param_1 + 0x68);
      }
    }
    this_01 = *(StyleSpecification **)(this + 0xb8);
    StyleSpecification::apply(this_01,(Style *)this_00,(OptionalFundamentalBase *)0x0);
    if (this_01[0xb8] != (StyleSpecification)0x0) {
      iVar1 = GuiConstants::getScaled<int>(*(int *)(this_01 + 0xb4));
      *(int *)(this_00 + 0x68) = iVar1;
      *(Style *)(this_00 + 0x6c) = (Style)0x1;
    }
    puVar3 = *(undefined8 **)(this_00 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(this_00 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  if (*(long *)(this + 0xc0) != 0) {
    pSVar6 = *(ScrollBarStyle **)(param_1 + 0x70);
    if (pSVar6 == (ScrollBarStyle *)0x0) {
      pSVar6 = operator_new(0x78);
      agui::ScrollBarStyle::ScrollBarStyle(pSVar6,(ScrollBarStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0x70);
      *(ScrollBarStyle **)(param_1 + 0x70) = pSVar6;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        pSVar6 = *(ScrollBarStyle **)(param_1 + 0x70);
      }
    }
    ScrollBarStyleSpecification::apply(*(ScrollBarStyleSpecification **)(this + 0xc0),pSVar6);
    puVar3 = *(undefined8 **)(pSVar6 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(pSVar6 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  if (*(long *)(this + 200) != 0) {
    pSVar6 = *(ScrollBarStyle **)(param_1 + 0x78);
    if (pSVar6 == (ScrollBarStyle *)0x0) {
      pSVar6 = operator_new(0x78);
      agui::ScrollBarStyle::ScrollBarStyle(pSVar6,(ScrollBarStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0x78);
      *(ScrollBarStyle **)(param_1 + 0x78) = pSVar6;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        pSVar6 = *(ScrollBarStyle **)(param_1 + 0x78);
      }
    }
    ScrollBarStyleSpecification::apply(*(ScrollBarStyleSpecification **)(this + 200),pSVar6);
    puVar3 = *(undefined8 **)(pSVar6 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(pSVar6 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  lVar7 = *(long *)(this + 0xd0);
  if (lVar7 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar7 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar7 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar7 + 0xd58));
    pEVar8 = (ElementImageSet *)**(undefined8 **)(this + 0xd0);
    pEVar4 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar4,pEVar8);
    pEVar8 = *(ElementImageSet **)(param_1 + 0x80);
    *(ElementImageSet **)(param_1 + 0x80) = pEVar4;
    if (pEVar8 != (ElementImageSet *)0x0) {
      pvVar5 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar8);
      operator_delete(pvVar5);
    }
  }
  lVar7 = *(long *)(this + 0xd8);
  if (lVar7 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar7 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar7 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar7 + 0xd58));
    pEVar8 = (ElementImageSet *)**(undefined8 **)(this + 0xd8);
    pEVar4 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar4,pEVar8);
    pEVar8 = *(ElementImageSet **)(param_1 + 0x88);
    *(ElementImageSet **)(param_1 + 0x88) = pEVar4;
    if (pEVar8 != (ElementImageSet *)0x0) {
      pvVar5 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar8);
      operator_delete(pvVar5);
    }
  }
  if (this[0xe4] != (ScrollPaneStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0xe0));
    *(int *)(param_1 + 0x90) = iVar1;
    param_1[0x94] = (ScrollPaneStyle)0x1;
  }
  if (this[0xec] != (ScrollPaneStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0xe8));
    *(int *)(param_1 + 0x98) = iVar1;
    param_1[0x9c] = (ScrollPaneStyle)0x1;
  }
  if (this[0xf4] != (ScrollPaneStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0xf0));
    *(int *)(param_1 + 0xa0) = iVar1;
    param_1[0xa4] = (ScrollPaneStyle)0x1;
  }
  if (this[0xfc] != (ScrollPaneStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0xf8));
    *(int *)(param_1 + 0xa8) = iVar1;
    param_1[0xac] = (ScrollPaneStyle)0x1;
  }
  if (this[0x104] != (ScrollPaneStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0x100));
    *(int *)(param_1 + 0xb0) = iVar1;
    param_1[0xb4] = (ScrollPaneStyle)0x1;
  }
  if (this[0x10c] != (ScrollPaneStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0x108));
    *(int *)(param_1 + 0xb8) = iVar1;
    param_1[0xbc] = (ScrollPaneStyle)0x1;
  }
  if (this[0x114] != (ScrollPaneStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0x110));
    *(int *)(param_1 + 0xc0) = iVar1;
    param_1[0xc4] = (ScrollPaneStyle)0x1;
  }
  if (this[0x11c] != (ScrollPaneStyleSpecification)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(this + 0x118));
    *(int *)(param_1 + 200) = iVar1;
    param_1[0xcc] = (ScrollPaneStyle)0x1;
  }
  if (this[0x121] != (ScrollPaneStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0xd0) = (byte)this[0x120] | 0x100;
  }
  if (this[0x123] != (ScrollPaneStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0xd2) = (byte)this[0x122] | 0x100;
  }
  if (this[0x125] != (ScrollPaneStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0xd4) = (byte)this[0x124] | 0x100;
  }
  return;
}



// ===== SliderStyleSpecification::apply  @ 0x10055c600 =====

/* SliderStyleSpecification::apply(agui::SliderStyle&, OptionalFundamentalBase*) */

void __thiscall
SliderStyleSpecification::apply
          (SliderStyleSpecification *this,SliderStyle *param_1,OptionalFundamentalBase *param_2)

{
  ElementImageSet *pEVar1;
  void *pvVar2;
  long *plVar3;
  undefined8 *puVar4;
  long lVar5;
  ButtonStyle *pBVar6;
  ElementImageSet *pEVar7;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  lVar5 = *(long *)(this + 0xb8);
  if (lVar5 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0xd58));
    pEVar7 = (ElementImageSet *)**(undefined8 **)(this + 0xb8);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar7);
    pEVar7 = *(ElementImageSet **)(param_1 + 0x68);
    *(ElementImageSet **)(param_1 + 0x68) = pEVar1;
    if (pEVar7 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar7);
      operator_delete(pvVar2);
    }
  }
  lVar5 = *(long *)(this + 0xc0);
  if (lVar5 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0xd58));
    pEVar7 = (ElementImageSet *)**(undefined8 **)(this + 0xc0);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar7);
    pEVar7 = *(ElementImageSet **)(param_1 + 0x70);
    *(ElementImageSet **)(param_1 + 0x70) = pEVar1;
    if (pEVar7 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar7);
      operator_delete(pvVar2);
    }
  }
  lVar5 = *(long *)(this + 200);
  if (lVar5 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0xd58));
    pEVar7 = (ElementImageSet *)**(undefined8 **)(this + 200);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar7);
    pEVar7 = *(ElementImageSet **)(param_1 + 0x78);
    *(ElementImageSet **)(param_1 + 0x78) = pEVar1;
    if (pEVar7 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar7);
      operator_delete(pvVar2);
    }
  }
  lVar5 = *(long *)(this + 0xd0);
  if (lVar5 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0xd58));
    pEVar7 = (ElementImageSet *)**(undefined8 **)(this + 0xd0);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar7);
    pEVar7 = *(ElementImageSet **)(param_1 + 0x80);
    *(ElementImageSet **)(param_1 + 0x80) = pEVar1;
    if (pEVar7 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar7);
      operator_delete(pvVar2);
    }
  }
  if (this[0xd9] != (SliderStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x88) = (byte)this[0xd8] | 0x100;
  }
  lVar5 = *(long *)(this + 0xe0);
  if (lVar5 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0xd58));
    pEVar7 = (ElementImageSet *)**(undefined8 **)(this + 0xe0);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar7);
    pEVar7 = *(ElementImageSet **)(param_1 + 0x90);
    *(ElementImageSet **)(param_1 + 0x90) = pEVar1;
    if (pEVar7 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar7);
      operator_delete(pvVar2);
    }
  }
  if (*(long *)(this + 0xe8) != 0) {
    pBVar6 = *(ButtonStyle **)(param_1 + 0x98);
    if (pBVar6 == (ButtonStyle *)0x0) {
      pBVar6 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(pBVar6,(ButtonStyle *)0x0);
      plVar3 = *(long **)(param_1 + 0x98);
      *(ButtonStyle **)(param_1 + 0x98) = pBVar6;
      if (plVar3 != (long *)0x0) {
        (**(code **)(*plVar3 + 8))();
        pBVar6 = *(ButtonStyle **)(param_1 + 0x98);
      }
    }
    ButtonStyleSpecification::apply
              (*(ButtonStyleSpecification **)(this + 0xe8),pBVar6,(OptionalFundamentalBase *)0x0);
    puVar4 = *(undefined8 **)(pBVar6 + 0x18);
    if (puVar4 == (undefined8 *)0x0) {
      puVar4 = operator_new(0x20);
      puVar4[1] = 0;
      *puVar4 = 0;
      puVar4[3] = 0;
      puVar4[2] = 0;
      *(undefined8 **)(pBVar6 + 0x18) = puVar4;
    }
    puVar4[3] = param_1;
  }
  if (*(long *)(this + 0xf0) != 0) {
    pBVar6 = *(ButtonStyle **)(param_1 + 0xa0);
    if (pBVar6 == (ButtonStyle *)0x0) {
      pBVar6 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(pBVar6,(ButtonStyle *)0x0);
      plVar3 = *(long **)(param_1 + 0xa0);
      *(ButtonStyle **)(param_1 + 0xa0) = pBVar6;
      if (plVar3 != (long *)0x0) {
        (**(code **)(*plVar3 + 8))();
        pBVar6 = *(ButtonStyle **)(param_1 + 0xa0);
      }
    }
    ButtonStyleSpecification::apply
              (*(ButtonStyleSpecification **)(this + 0xf0),pBVar6,(OptionalFundamentalBase *)0x0);
    puVar4 = *(undefined8 **)(pBVar6 + 0x18);
    if (puVar4 == (undefined8 *)0x0) {
      puVar4 = operator_new(0x20);
      puVar4[1] = 0;
      *puVar4 = 0;
      puVar4[3] = 0;
      puVar4[2] = 0;
      *(undefined8 **)(pBVar6 + 0x18) = puVar4;
    }
    puVar4[3] = param_1;
  }
  return;
}



// ===== ImageStyleSpecification::apply  @ 0x10055d98c =====

/* ImageStyleSpecification::apply(agui::ImageStyle&, OptionalFundamentalBase*) const */

void __thiscall
ImageStyleSpecification::apply
          (ImageStyleSpecification *this,ImageStyle *param_1,OptionalFundamentalBase *param_2)

{
  ElementImageSet *this_00;
  void *pvVar1;
  ElementImageSet *pEVar2;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (*(undefined8 **)(this + 0xb8) != (undefined8 *)0x0) {
    pEVar2 = (ElementImageSet *)**(undefined8 **)(this + 0xb8);
    this_00 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(this_00,pEVar2);
    pEVar2 = *(ElementImageSet **)(param_1 + 0x68);
    *(ElementImageSet **)(param_1 + 0x68) = this_00;
    if (pEVar2 != (ElementImageSet *)0x0) {
      pvVar1 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar2);
      operator_delete(pvVar1);
    }
  }
  if (this[0xc1] != (ImageStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x70) = (byte)this[0xc0] | 0x100;
  }
  if (this[0xc3] != (ImageStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x72) = (byte)this[0xc2] | 0x100;
  }
  return;
}



// ===== SwitchStyleSpecification::apply  @ 0x100560284 =====

/* SwitchStyleSpecification::apply(agui::SwitchStyle&, OptionalFundamentalBase*) const */

void __thiscall
SwitchStyleSpecification::apply
          (SwitchStyleSpecification *this,SwitchStyle *param_1,OptionalFundamentalBase *param_2)

{
  uint uVar1;
  long *plVar2;
  undefined8 *puVar3;
  LabelStyle *pLVar4;
  ButtonStyle *this_00;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (this[0xb8] != (SwitchStyleSpecification)0x0) {
    uVar1 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xb4));
    *(uint *)(param_1 + 0x68) = uVar1;
    param_1[0x6c] = (SwitchStyle)0x1;
  }
  if (this[0xc0] != (SwitchStyleSpecification)0x0) {
    uVar1 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xbc));
    *(uint *)(param_1 + 0x70) = uVar1;
    param_1[0x74] = (SwitchStyle)0x1;
  }
  if (this[200] != (SwitchStyleSpecification)0x0) {
    uVar1 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xc4));
    *(uint *)(param_1 + 0x78) = uVar1;
    param_1[0x7c] = (SwitchStyle)0x1;
  }
  if (*(long *)(this + 0xd0) != 0) {
    *(undefined8 *)(param_1 + 0x80) = *(undefined8 *)(*(long *)(this + 0xd0) + 0xa0);
  }
  if (*(long *)(this + 0xd8) != 0) {
    *(undefined8 *)(param_1 + 0x88) = *(undefined8 *)(*(long *)(this + 0xd8) + 0xa0);
  }
  if (*(long *)(this + 0xe0) != 0) {
    *(undefined8 *)(param_1 + 0x90) = *(undefined8 *)(*(long *)(this + 0xe0) + 0xa0);
  }
  if (*(long *)(this + 0xf0) != 0) {
    pLVar4 = *(LabelStyle **)(param_1 + 0x98);
    if (pLVar4 == (LabelStyle *)0x0) {
      pLVar4 = operator_new(200);
      agui::LabelStyle::LabelStyle(pLVar4,(LabelStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0x98);
      *(LabelStyle **)(param_1 + 0x98) = pLVar4;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        pLVar4 = *(LabelStyle **)(param_1 + 0x98);
      }
    }
    LabelStyleSpecification::apply
              (*(LabelStyleSpecification **)(this + 0xf0),pLVar4,(OptionalFundamentalBase *)0x0);
    puVar3 = *(undefined8 **)(pLVar4 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(pLVar4 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  if (*(long *)(this + 0xf8) != 0) {
    pLVar4 = *(LabelStyle **)(param_1 + 0xa0);
    if (pLVar4 == (LabelStyle *)0x0) {
      pLVar4 = operator_new(200);
      agui::LabelStyle::LabelStyle(pLVar4,(LabelStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0xa0);
      *(LabelStyle **)(param_1 + 0xa0) = pLVar4;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        pLVar4 = *(LabelStyle **)(param_1 + 0xa0);
      }
    }
    LabelStyleSpecification::apply
              (*(LabelStyleSpecification **)(this + 0xf8),pLVar4,(OptionalFundamentalBase *)0x0);
    puVar3 = *(undefined8 **)(pLVar4 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(pLVar4 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  if (*(long *)(this + 0xe8) != 0) {
    this_00 = *(ButtonStyle **)(param_1 + 0xa8);
    if (this_00 == (ButtonStyle *)0x0) {
      this_00 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(this_00,(ButtonStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0xa8);
      *(ButtonStyle **)(param_1 + 0xa8) = this_00;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        this_00 = *(ButtonStyle **)(param_1 + 0xa8);
      }
    }
    ButtonStyleSpecification::apply
              (*(ButtonStyleSpecification **)(this + 0xe8),this_00,(OptionalFundamentalBase *)0x0);
    puVar3 = *(undefined8 **)(this_00 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(this_00 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  return;
}



// ===== TabStyleSpecification::apply  @ 0x100561534 =====

/* TabStyleSpecification::apply(agui::TabStyle&, OptionalFundamentalBase*) const */

void __thiscall
TabStyleSpecification::apply
          (TabStyleSpecification *this,TabStyle *param_1,OptionalFundamentalBase *param_2)

{
  undefined8 *puVar1;
  ulong uVar2;
  byte bVar3;
  undefined8 uVar4;
  short sVar5;
  undefined8 uVar6;
  void *pvVar7;
  undefined8 *puVar8;
  float *pfVar9;
  long lVar10;
  undefined8 local_40;
  undefined8 uStack_38;
  
  StyleWithClickableGraphicalSetSpecification::apply
            ((StyleWithClickableGraphicalSetSpecification *)this,
             (StyleWithClickableGraphicalSet *)param_1,param_2);
  puVar8 = *(undefined8 **)(this + 0x110);
  if (puVar8 != (undefined8 *)0x0) {
    bVar3 = *(byte *)((long)puVar8 + 0x17);
    puVar1 = (undefined8 *)*puVar8;
    if (-1 < (char)bVar3) {
      puVar1 = puVar8;
    }
    uVar2 = puVar8[1];
    if (-1 < (char)bVar3) {
      uVar2 = (ulong)bVar3;
    }
    uVar6 = FontBank::getFont(*(undefined8 *)(_global + 0x270),puVar1,uVar2,0);
    *(undefined8 *)(param_1 + 0xb0) = uVar6;
  }
  puVar8 = *(undefined8 **)(this + 0x118);
  if (puVar8 != (undefined8 *)0x0) {
    bVar3 = *(byte *)((long)puVar8 + 0x17);
    puVar1 = (undefined8 *)*puVar8;
    if (-1 < (char)bVar3) {
      puVar1 = puVar8;
    }
    uVar2 = puVar8[1];
    if (-1 < (char)bVar3) {
      uVar2 = (ulong)bVar3;
    }
    uVar6 = FontBank::getFont(*(undefined8 *)(_global + 0x270),puVar1,uVar2,0);
    *(undefined8 *)(param_1 + 0xb8) = uVar6;
  }
  if (this[0x122] != (TabStyleSpecification)0x0) {
    sVar5 = GuiConstants::getScaled<short>(*(short *)(this + 0x120));
    *(short *)(param_1 + 0xc0) = sVar5;
    param_1[0xc2] = (TabStyle)0x1;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  pfVar9 = *(float **)(this + 0x128);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_38;
    uVar6 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 200);
    *(undefined8 **)(param_1 + 200) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x130);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_38;
    uVar6 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xd0);
    *(undefined8 **)(param_1 + 0xd0) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x138);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_38;
    uVar6 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xd8);
    *(undefined8 **)(param_1 + 0xd8) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x140);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_38;
    uVar6 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xe0);
    *(undefined8 **)(param_1 + 0xe0) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x148);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar4 = uStack_38;
    uVar6 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar4;
    *puVar8 = uVar6;
    pvVar7 = *(void **)(param_1 + 0xe8);
    *(undefined8 **)(param_1 + 0xe8) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x150);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    puVar8 = operator_new(0x10);
    puVar8[1] = uStack_38;
    *puVar8 = local_40;
    pvVar7 = *(void **)(param_1 + 0xf0);
    *(undefined8 **)(param_1 + 0xf0) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  if (this[0x159] != (TabStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0xf8) = (byte)this[0x158] | 0x100;
  }
  if (this[0x15b] != (TabStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0xfa) = (byte)this[0x15a] | 0x100;
  }
  lVar10 = *(long *)(this + 0x160);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    agui::TabStyle::initGraphicalSet(param_1,6,**(undefined8 **)(this + 0x160));
  }
  lVar10 = *(long *)(this + 0x168);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    agui::TabStyle::initGraphicalSet(param_1,7,**(undefined8 **)(this + 0x168));
  }
  lVar10 = *(long *)(this + 0x170);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    agui::TabStyle::initBadgeGraphicalSet(param_1,0,**(undefined8 **)(this + 0x170));
  }
  lVar10 = *(long *)(this + 0x178);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    agui::TabStyle::initBadgeGraphicalSet(param_1,1,**(undefined8 **)(this + 0x178));
  }
  lVar10 = *(long *)(this + 0x180);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    agui::TabStyle::initBadgeGraphicalSet(param_1,2,**(undefined8 **)(this + 0x180));
  }
  lVar10 = *(long *)(this + 0x188);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    agui::TabStyle::initBadgeGraphicalSet(param_1,4,**(undefined8 **)(this + 0x188));
  }
  lVar10 = *(long *)(this + 400);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    agui::TabStyle::initBadgeGraphicalSet(param_1,5,**(undefined8 **)(this + 400));
  }
  if (this[0x199] != (TabStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x138) = (byte)this[0x198] | 0x100;
  }
  return;
}



// ===== TabbedPaneStyleSpecification::apply  @ 0x100562574 =====

/* TabbedPaneStyleSpecification::apply(agui::TabbedPaneStyle&, OptionalFundamentalBase*) const */

void __thiscall
TabbedPaneStyleSpecification::apply
          (TabbedPaneStyleSpecification *this,TabbedPaneStyle *param_1,
          OptionalFundamentalBase *param_2)

{
  uint uVar1;
  long *plVar2;
  undefined8 *puVar3;
  FrameStyle *this_00;
  TableStyle *this_01;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (this[0xb8] != (TabbedPaneStyleSpecification)0x0) {
    uVar1 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xb4));
    *(uint *)(param_1 + 0x68) = uVar1;
    param_1[0x6c] = (TabbedPaneStyle)0x1;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  if (*(long *)(this + 0xc0) != 0) {
    this_00 = *(FrameStyle **)(param_1 + 0x70);
    if (this_00 == (FrameStyle *)0x0) {
      this_00 = operator_new(0xb8);
      agui::FrameStyle::FrameStyle(this_00,(FrameStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0x70);
      *(FrameStyle **)(param_1 + 0x70) = this_00;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        this_00 = *(FrameStyle **)(param_1 + 0x70);
      }
    }
    FrameStyleSpecification::apply
              (*(FrameStyleSpecification **)(this + 0xc0),this_00,(OptionalFundamentalBase *)0x0);
    puVar3 = *(undefined8 **)(this_00 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(this_00 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  if (*(long *)(this + 200) != 0) {
    this_01 = *(TableStyle **)(param_1 + 0x78);
    if (this_01 == (TableStyle *)0x0) {
      this_01 = operator_new(0x140);
      agui::TableStyle::TableStyle(this_01,(TableStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0x78);
      *(TableStyle **)(param_1 + 0x78) = this_01;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        this_01 = *(TableStyle **)(param_1 + 0x78);
      }
    }
    TableStyleSpecification::apply
              (*(TableStyleSpecification **)(this + 200),this_01,(OptionalFundamentalBase *)0x0);
    puVar3 = *(undefined8 **)(this_01 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(this_01 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  return;
}



// ===== TableStyleSpecification::apply  @ 0x100563c80 =====

/* TableStyleSpecification::apply(agui::TableStyle&, OptionalFundamentalBase*) const */

void __thiscall
TableStyleSpecification::apply
          (TableStyleSpecification *this,TableStyle *param_1,OptionalFundamentalBase *param_2)

{
  undefined1 *puVar1;
  short sVar2;
  int iVar3;
  int iVar4;
  ElementImageSet *pEVar5;
  void *pvVar6;
  undefined8 *puVar7;
  float *pfVar8;
  undefined1 *puVar9;
  undefined1 *puVar11;
  ulong uVar12;
  ulong uVar13;
  ulong uVar14;
  undefined8 *puVar15;
  long lVar16;
  ButtonStyleSpecification *pBVar17;
  ElementImageSet *pEVar18;
  long *plVar19;
  int *piVar20;
  ButtonStyle *pBVar21;
  int *piVar22;
  undefined8 uVar23;
  undefined8 uVar24;
  undefined8 uVar25;
  undefined8 uVar26;
  undefined8 uVar27;
  undefined8 uVar28;
  undefined8 uVar29;
  undefined1 *local_70;
  undefined1 *puStack_68;
  undefined1 *local_60;
  undefined1 *local_58;
  undefined8 uStack_50;
  undefined1 *puVar10;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (*(Spacings **)(this + 0xb8) != (Spacings *)0x0) {
    createScaledAguiSpacings(*(Spacings **)(this + 0xb8));
    agui::Style::setProperty<agui::TableStyle,agui::TableStyle::Spacings>
              ((Style *)param_1,(Spacings_ *)&DAT_00000068,(Spacings *)&local_70);
    if (puStack_68 != (undefined1 *)0x0) {
      local_60 = puStack_68;
      operator_delete(puStack_68);
    }
  }
  if (*(Spacings **)(this + 0xc0) != (Spacings *)0x0) {
    createScaledAguiSpacings(*(Spacings **)(this + 0xc0));
    agui::Style::setProperty<agui::TableStyle,agui::TableStyle::Spacings>
              ((Style *)param_1,(Spacings_ *)0x70,(Spacings *)&local_70);
    if (puStack_68 != (undefined1 *)0x0) {
      local_60 = puStack_68;
      operator_delete(puStack_68);
    }
  }
  if (this[0xca] != (TableStyleSpecification)0x0) {
    sVar2 = GuiConstants::getScaled<short>(*(short *)(this + 200));
    *(short *)(param_1 + 0x78) = sVar2;
    param_1[0x7a] = (TableStyle)0x1;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  if (this[0xce] != (TableStyleSpecification)0x0) {
    sVar2 = GuiConstants::getScaled<short>(*(short *)(this + 0xcc));
    *(short *)(param_1 + 0x7c) = sVar2;
    param_1[0x7e] = (TableStyle)0x1;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  if (this[0xd2] != (TableStyleSpecification)0x0) {
    sVar2 = GuiConstants::getScaled<short>(*(short *)(this + 0xd0));
    *(short *)(param_1 + 0x80) = sVar2;
    param_1[0x82] = (TableStyle)0x1;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  if (this[0xd6] != (TableStyleSpecification)0x0) {
    sVar2 = GuiConstants::getScaled<short>(*(short *)(this + 0xd4));
    *(short *)(param_1 + 0x84) = sVar2;
    param_1[0x86] = (TableStyle)0x1;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  if (this[0xd9] != (TableStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x88) = (byte)this[0xd8] | 0x100;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  if (this[0xdb] != (TableStyleSpecification)0x0) {
    *(ushort *)(param_1 + 0x8a) = (byte)this[0xda] | 0x100;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  lVar16 = *(long *)(this + 0xe0);
  if (lVar16 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0xd58));
    pEVar18 = (ElementImageSet *)**(undefined8 **)(this + 0xe0);
    pEVar5 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar5,pEVar18);
    pEVar18 = *(ElementImageSet **)(param_1 + 0x90);
    *(ElementImageSet **)(param_1 + 0x90) = pEVar5;
    if (pEVar18 != (ElementImageSet *)0x0) {
      pvVar6 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar18);
      operator_delete(pvVar6);
    }
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  lVar16 = *(long *)(this + 0xe8);
  if (lVar16 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0xd58));
    pEVar18 = (ElementImageSet *)**(undefined8 **)(this + 0xe8);
    pEVar5 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar5,pEVar18);
    pEVar18 = *(ElementImageSet **)(param_1 + 0x98);
    *(ElementImageSet **)(param_1 + 0x98) = pEVar5;
    if (pEVar18 != (ElementImageSet *)0x0) {
      pvVar6 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar18);
      operator_delete(pvVar6);
    }
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  lVar16 = *(long *)(this + 0xf0);
  if (lVar16 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0xd58));
    pEVar18 = (ElementImageSet *)**(undefined8 **)(this + 0xf0);
    pEVar5 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar5,pEVar18);
    pEVar18 = *(ElementImageSet **)(param_1 + 0xa0);
    *(ElementImageSet **)(param_1 + 0xa0) = pEVar5;
    if (pEVar18 != (ElementImageSet *)0x0) {
      pvVar6 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar18);
      operator_delete(pvVar6);
    }
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  lVar16 = *(long *)(this + 0xf8);
  if (lVar16 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0xd58));
    pEVar18 = (ElementImageSet *)**(undefined8 **)(this + 0xf8);
    pEVar5 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar5,pEVar18);
    pEVar18 = *(ElementImageSet **)(param_1 + 0xa8);
    *(ElementImageSet **)(param_1 + 0xa8) = pEVar5;
    if (pEVar18 != (ElementImageSet *)0x0) {
      pvVar6 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar18);
      operator_delete(pvVar6);
    }
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  lVar16 = *(long *)(this + 0x100);
  if (lVar16 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0xd58));
    pEVar18 = (ElementImageSet *)**(undefined8 **)(this + 0x100);
    pEVar5 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar5,pEVar18);
    pEVar18 = *(ElementImageSet **)(param_1 + 0xb0);
    *(ElementImageSet **)(param_1 + 0xb0) = pEVar5;
    if (pEVar18 != (ElementImageSet *)0x0) {
      pvVar6 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar18);
      operator_delete(pvVar6);
    }
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  lVar16 = *(long *)(this + 0x108);
  if (lVar16 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0xd58));
    pEVar18 = (ElementImageSet *)**(undefined8 **)(this + 0x108);
    pEVar5 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar5,pEVar18);
    pEVar18 = *(ElementImageSet **)(param_1 + 0xb8);
    *(ElementImageSet **)(param_1 + 0xb8) = pEVar5;
    if (pEVar18 != (ElementImageSet *)0x0) {
      pvVar6 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar18);
      operator_delete(pvVar6);
    }
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  lVar16 = *(long *)(this + 0x110);
  if (lVar16 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0xd58));
    pEVar18 = (ElementImageSet *)**(undefined8 **)(this + 0x110);
    pEVar5 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar5,pEVar18);
    pEVar18 = *(ElementImageSet **)(param_1 + 0xc0);
    *(ElementImageSet **)(param_1 + 0xc0) = pEVar5;
    if (pEVar18 != (ElementImageSet *)0x0) {
      pvVar6 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar18);
      operator_delete(pvVar6);
    }
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  lVar16 = *(long *)(this + 0x118);
  if (lVar16 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0xd58));
    pEVar18 = (ElementImageSet *)**(undefined8 **)(this + 0x118);
    pEVar5 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar5,pEVar18);
    pEVar18 = *(ElementImageSet **)(param_1 + 200);
    *(ElementImageSet **)(param_1 + 200) = pEVar5;
    if (pEVar18 != (ElementImageSet *)0x0) {
      pvVar6 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar18);
      operator_delete(pvVar6);
    }
  }
  lVar16 = *(long *)(this + 0x120);
  if (lVar16 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0xd58));
    pEVar18 = (ElementImageSet *)**(undefined8 **)(this + 0x120);
    pEVar5 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar5,pEVar18);
    pEVar18 = *(ElementImageSet **)(param_1 + 0xd0);
    *(ElementImageSet **)(param_1 + 0xd0) = pEVar5;
    if (pEVar18 != (ElementImageSet *)0x0) {
      pvVar6 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar18);
      operator_delete(pvVar6);
    }
  }
  lVar16 = *(long *)(this + 0x128);
  if (lVar16 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar16 + 0xd58));
    pEVar18 = (ElementImageSet *)**(undefined8 **)(this + 0x128);
    pEVar5 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar5,pEVar18);
    pEVar18 = *(ElementImageSet **)(param_1 + 0xe0);
    *(ElementImageSet **)(param_1 + 0xe0) = pEVar5;
    if (pEVar18 != (ElementImageSet *)0x0) {
      pvVar6 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar18);
      operator_delete(pvVar6);
    }
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  plVar19 = *(long **)(this + 0x130);
  if (plVar19 == (long *)0x0) goto LAB_100564240;
  puStack_68 = (undefined1 *)0x0;
  local_60 = (undefined1 *)0x0;
  local_70 = (undefined1 *)0x0;
  uVar12 = plVar19[1] - *plVar19;
  if (uVar12 != 0) {
    if ((long)uVar12 < 0) {
                    /* WARNING: Subroutine does not return */
      std::vector<agui::AreaAlign,std::allocator<agui::AreaAlign>>::
      __throw_length_error_abi_v160006_();
    }
    local_70 = operator_new(uVar12);
    local_60 = local_70 + uVar12;
    puVar9 = (undefined1 *)*plVar19;
    puVar1 = (undefined1 *)plVar19[1];
    puStack_68 = local_70;
    if (puVar9 != puVar1) {
      uVar12 = (long)puVar1 - (long)puVar9;
      puVar10 = puVar9;
      puVar11 = local_70;
      if ((0x3f < uVar12) && (0x3f < (ulong)((long)local_70 - (long)puVar9))) {
        uVar14 = 0;
        uVar13 = uVar12 & 0xffffffffffffffc0;
        puVar10 = puVar9 + uVar13;
        puVar11 = local_70 + uVar13;
        do {
          puVar7 = (undefined8 *)(puVar9 + uVar14);
          puVar15 = (undefined8 *)(local_70 + uVar14);
          uVar23 = *puVar7;
          uVar25 = puVar7[3];
          uVar24 = puVar7[2];
          uVar27 = puVar7[5];
          uVar26 = puVar7[4];
          uVar29 = puVar7[7];
          uVar28 = puVar7[6];
          puVar15[1] = puVar7[1];
          *puVar15 = uVar23;
          puVar15[3] = uVar25;
          puVar15[2] = uVar24;
          puVar15[5] = uVar27;
          puVar15[4] = uVar26;
          puVar15[7] = uVar29;
          puVar15[6] = uVar28;
          uVar14 = uVar14 + 0x40;
        } while (uVar13 != uVar14);
        puStack_68 = puVar11;
        if (uVar12 == uVar13) goto LAB_100564220;
      }
      do {
        puVar9 = puVar10 + 1;
        puStack_68 = puVar11 + 1;
        *puVar11 = *puVar10;
        puVar10 = puVar9;
        puVar11 = puStack_68;
      } while (puVar9 != puVar1);
    }
  }
LAB_100564220:
  agui::Style::setProperty<agui::TableStyle,agui::TableStyle::AreaAlignments>
            ((Style *)param_1,(AreaAlignments_ *)0xe8,(AreaAlignments *)&local_70);
  if (local_70 != (undefined1 *)0x0) {
    puStack_68 = local_70;
    operator_delete(local_70);
  }
LAB_100564240:
  piVar20 = *(int **)(this + 0x138);
  if (piVar20 != (int *)0x0) {
    local_70 = (undefined1 *)((ulong)local_70 & 0xffffffffffffff00);
    puStack_68 = (undefined1 *)((ulong)puStack_68 & 0xffffffffffffff00);
    local_58 = (undefined1 *)0x0;
    uStack_50 = 0;
    local_60 = (undefined1 *)0x0;
    if ((char)piVar20[2] != '\0') {
      iVar3 = GuiConstants::getScaled<int>(*piVar20);
      iVar4 = GuiConstants::getScaled<int>(piVar20[1]);
      agui::TableStyle::Widths::setUnifiedColumnWidth((Widths *)&local_70,CONCAT44(iVar4,iVar3));
      piVar20 = *(int **)(this + 0x138);
    }
    lVar16 = *(long *)(piVar20 + 4);
    if (*(long *)(piVar20 + 6) != lVar16) {
      uVar12 = 0;
      do {
        iVar3 = *(int *)(lVar16 + uVar12 * 8);
        piVar22 = (int *)(lVar16 + uVar12 * 8 + 4);
        if (iVar3 != 0 || *piVar22 != 0) {
          iVar3 = GuiConstants::getScaled<int>(iVar3);
          iVar4 = GuiConstants::getScaled<int>(*piVar22);
          agui::TableStyle::Widths::setItem((Widths *)&local_70,uVar12,CONCAT44(iVar4,iVar3));
          piVar20 = *(int **)(this + 0x138);
        }
        uVar12 = (ulong)((int)uVar12 + 1);
        lVar16 = *(long *)(piVar20 + 4);
      } while (uVar12 < (ulong)(*(long *)(piVar20 + 6) - lVar16 >> 3));
    }
    agui::Style::setProperty<agui::TableStyle,agui::TableStyle::Widths>
              ((Style *)param_1,(Widths_ *)0xf0,(Widths *)&local_70);
    if (local_60 != (undefined1 *)0x0) {
      local_58 = local_60;
      operator_delete(local_60);
    }
  }
  pfVar8 = *(float **)(this + 0x140);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_70,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    puVar1 = puStack_68;
    puVar9 = local_70;
    puVar7 = operator_new(0x10);
    puVar7[1] = puVar1;
    *puVar7 = puVar9;
    pvVar6 = *(void **)(param_1 + 0xf8);
    *(undefined8 **)(param_1 + 0xf8) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0x148);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_70,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    puVar1 = puStack_68;
    puVar9 = local_70;
    puVar7 = operator_new(0x10);
    puVar7[1] = puVar1;
    *puVar7 = puVar9;
    pvVar6 = *(void **)(param_1 + 0x100);
    *(undefined8 **)(param_1 + 0x100) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0x150);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_70,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    puVar1 = puStack_68;
    puVar9 = local_70;
    puVar7 = operator_new(0x10);
    puVar7[1] = puVar1;
    *puVar7 = puVar9;
    pvVar6 = *(void **)(param_1 + 0x108);
    *(undefined8 **)(param_1 + 0x108) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pfVar8 = *(float **)(this + 0x158);
  if (pfVar8 != (float *)0x0) {
    agui::Color::Color((Color *)&local_70,*pfVar8,pfVar8[1],pfVar8[2],pfVar8[3]);
    puVar1 = puStack_68;
    puVar9 = local_70;
    puVar7 = operator_new(0x10);
    puVar7[1] = puVar1;
    *puVar7 = puVar9;
    pvVar6 = *(void **)(param_1 + 0x110);
    *(undefined8 **)(param_1 + 0x110) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  pBVar17 = *(ButtonStyleSpecification **)(this + 0x160);
  if (pBVar17 != (ButtonStyleSpecification *)0x0) {
    pBVar21 = *(ButtonStyle **)(param_1 + 0x118);
    if (pBVar21 == (ButtonStyle *)0x0) {
      pBVar21 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(pBVar21,(ButtonStyle *)0x0);
      plVar19 = *(long **)(param_1 + 0x118);
      *(ButtonStyle **)(param_1 + 0x118) = pBVar21;
      if (plVar19 != (long *)0x0) {
        (**(code **)(*plVar19 + 8))();
        pBVar21 = *(ButtonStyle **)(param_1 + 0x118);
      }
    }
    ButtonStyleSpecification::apply(pBVar17,pBVar21,(OptionalFundamentalBase *)0x0);
  }
  pBVar17 = *(ButtonStyleSpecification **)(this + 0x168);
  if (pBVar17 != (ButtonStyleSpecification *)0x0) {
    pBVar21 = *(ButtonStyle **)(param_1 + 0x120);
    if (pBVar21 == (ButtonStyle *)0x0) {
      pBVar21 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(pBVar21,(ButtonStyle *)0x0);
      plVar19 = *(long **)(param_1 + 0x120);
      *(ButtonStyle **)(param_1 + 0x120) = pBVar21;
      if (plVar19 != (long *)0x0) {
        (**(code **)(*plVar19 + 8))();
        pBVar21 = *(ButtonStyle **)(param_1 + 0x120);
      }
    }
    ButtonStyleSpecification::apply(pBVar17,pBVar21,(OptionalFundamentalBase *)0x0);
  }
  pBVar17 = *(ButtonStyleSpecification **)(this + 0x170);
  if (pBVar17 != (ButtonStyleSpecification *)0x0) {
    pBVar21 = *(ButtonStyle **)(param_1 + 0x128);
    if (pBVar21 == (ButtonStyle *)0x0) {
      pBVar21 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(pBVar21,(ButtonStyle *)0x0);
      plVar19 = *(long **)(param_1 + 0x128);
      *(ButtonStyle **)(param_1 + 0x128) = pBVar21;
      if (plVar19 != (long *)0x0) {
        (**(code **)(*plVar19 + 8))();
        pBVar21 = *(ButtonStyle **)(param_1 + 0x128);
      }
    }
    ButtonStyleSpecification::apply(pBVar17,pBVar21,(OptionalFundamentalBase *)0x0);
  }
  pBVar17 = *(ButtonStyleSpecification **)(this + 0x178);
  if (pBVar17 != (ButtonStyleSpecification *)0x0) {
    pBVar21 = *(ButtonStyle **)(param_1 + 0x130);
    if (pBVar21 == (ButtonStyle *)0x0) {
      pBVar21 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(pBVar21,(ButtonStyle *)0x0);
      plVar19 = *(long **)(param_1 + 0x130);
      *(ButtonStyle **)(param_1 + 0x130) = pBVar21;
      if (plVar19 != (long *)0x0) {
        (**(code **)(*plVar19 + 8))();
        pBVar21 = *(ButtonStyle **)(param_1 + 0x130);
      }
    }
    ButtonStyleSpecification::apply(pBVar17,pBVar21,(OptionalFundamentalBase *)0x0);
  }
  lVar16 = *(long *)(this + 0x180);
  if (lVar16 != 0) {
    iVar3 = GuiConstants::getScaled<int>(*(int *)(lVar16 + 4));
    *(int *)(*(long *)(lVar16 + 0x968) + 4) = iVar3;
    puVar15 = *(undefined8 **)(*(long *)(this + 0x180) + 0x968);
    puVar7 = operator_new(0x80);
    uVar23 = puVar15[4];
    uVar25 = puVar15[7];
    uVar24 = puVar15[6];
    uVar29 = puVar15[1];
    uVar28 = *puVar15;
    uVar27 = puVar15[3];
    uVar26 = puVar15[2];
    puVar7[5] = puVar15[5];
    puVar7[4] = uVar23;
    puVar7[7] = uVar25;
    puVar7[6] = uVar24;
    puVar7[1] = uVar29;
    *puVar7 = uVar28;
    puVar7[3] = uVar27;
    puVar7[2] = uVar26;
    uVar23 = puVar15[0xc];
    uVar25 = puVar15[0xf];
    uVar24 = puVar15[0xe];
    uVar29 = puVar15[9];
    uVar28 = puVar15[8];
    uVar27 = puVar15[0xb];
    uVar26 = puVar15[10];
    puVar7[0xd] = puVar15[0xd];
    puVar7[0xc] = uVar23;
    puVar7[0xf] = uVar25;
    puVar7[0xe] = uVar24;
    puVar7[9] = uVar29;
    puVar7[8] = uVar28;
    puVar7[0xb] = uVar27;
    puVar7[10] = uVar26;
    pvVar6 = *(void **)(param_1 + 0x138);
    *(undefined8 **)(param_1 + 0x138) = puVar7;
    if (pvVar6 != (void *)0x0) {
      operator_delete(pvVar6);
    }
  }
  return;
}



// ===== TextBoxStyleSpecification::apply  @ 0x10056558c =====

/* TextBoxStyleSpecification::apply(agui::TextBoxStyle&, OptionalFundamentalBase*) const */

void __thiscall
TextBoxStyleSpecification::apply
          (TextBoxStyleSpecification *this,TextBoxStyle *param_1,OptionalFundamentalBase *param_2)

{
  undefined8 *puVar1;
  ulong uVar2;
  byte bVar3;
  undefined8 uVar4;
  undefined8 uVar5;
  Font *pFVar6;
  void *pvVar7;
  undefined8 *puVar8;
  float *pfVar9;
  long lVar10;
  undefined8 local_40;
  undefined8 uStack_38;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  puVar8 = *(undefined8 **)(this + 0xb8);
  if (puVar8 != (undefined8 *)0x0) {
    bVar3 = *(byte *)((long)puVar8 + 0x17);
    puVar1 = (undefined8 *)*puVar8;
    if (-1 < (char)bVar3) {
      puVar1 = puVar8;
    }
    uVar2 = puVar8[1];
    if (-1 < (char)bVar3) {
      uVar2 = (ulong)bVar3;
    }
    pFVar6 = (Font *)FontBank::getFont(*(undefined8 *)(_global + 0x270),puVar1,uVar2,0);
    agui::TextBoxStyle::setFont(param_1,pFVar6);
  }
  pfVar9 = *(float **)(this + 0xc0);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar5 = uStack_38;
    uVar4 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar5;
    *puVar8 = uVar4;
    pvVar7 = *(void **)(param_1 + 0x70);
    *(undefined8 **)(param_1 + 0x70) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 200);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar5 = uStack_38;
    uVar4 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar5;
    *puVar8 = uVar4;
    pvVar7 = *(void **)(param_1 + 0x78);
    *(undefined8 **)(param_1 + 0x78) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0xd0);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar5 = uStack_38;
    uVar4 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar5;
    *puVar8 = uVar4;
    pvVar7 = *(void **)(param_1 + 0x80);
    *(undefined8 **)(param_1 + 0x80) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  lVar10 = *(long *)(this + 0xd8);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    (**(code **)(*(long *)param_1 + 0x40))(param_1,**(undefined8 **)(this + 0xd8));
  }
  lVar10 = *(long *)(this + 0xe0);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    (**(code **)(*(long *)param_1 + 0x50))(param_1,**(undefined8 **)(this + 0xe0));
  }
  lVar10 = *(long *)(this + 0xe8);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    (**(code **)(*(long *)param_1 + 0x60))(param_1,**(undefined8 **)(this + 0xe8));
  }
  lVar10 = *(long *)(this + 0xf0);
  if (lVar10 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar10 + 0xd58));
    (**(code **)(*(long *)param_1 + 0x70))(param_1,**(undefined8 **)(this + 0xf0));
  }
  if (*(RichTextSetting **)(this + 0xf8) != (RichTextSetting *)0x0) {
    agui::TextBoxStyle::setRichTextSettings(param_1,*(RichTextSetting **)(this + 0xf8));
  }
  pfVar9 = *(float **)(this + 0x100);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar5 = uStack_38;
    uVar4 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar5;
    *puVar8 = uVar4;
    pvVar7 = *(void **)(param_1 + 0xb0);
    *(undefined8 **)(param_1 + 0xb0) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x108);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar5 = uStack_38;
    uVar4 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar5;
    *puVar8 = uVar4;
    pvVar7 = *(void **)(param_1 + 0xb8);
    *(undefined8 **)(param_1 + 0xb8) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x110);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar5 = uStack_38;
    uVar4 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar5;
    *puVar8 = uVar4;
    pvVar7 = *(void **)(param_1 + 0xc0);
    *(undefined8 **)(param_1 + 0xc0) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x118);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar5 = uStack_38;
    uVar4 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar5;
    *puVar8 = uVar4;
    pvVar7 = *(void **)(param_1 + 200);
    *(undefined8 **)(param_1 + 200) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x120);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    uVar5 = uStack_38;
    uVar4 = local_40;
    puVar8 = operator_new(0x10);
    puVar8[1] = uVar5;
    *puVar8 = uVar4;
    pvVar7 = *(void **)(param_1 + 0xd0);
    *(undefined8 **)(param_1 + 0xd0) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  pfVar9 = *(float **)(this + 0x128);
  if (pfVar9 != (float *)0x0) {
    agui::Color::Color((Color *)&local_40,*pfVar9,pfVar9[1],pfVar9[2],pfVar9[3]);
    puVar8 = operator_new(0x10);
    puVar8[1] = uStack_38;
    *puVar8 = local_40;
    pvVar7 = *(void **)(param_1 + 0xd8);
    *(undefined8 **)(param_1 + 0xd8) = puVar8;
    if (pvVar7 != (void *)0x0) {
      operator_delete(pvVar7);
    }
  }
  return;
}



// ===== TriggerEffect::apply  @ 0x100639e48 =====

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */
/* TriggerEffect::apply(TriggerContext const&) const */

void __thiscall TriggerEffect::apply(TriggerEffect *this,TriggerContext *param_1)

{
  undefined8 *puVar1;
  TriggerContext TVar2;
  int iVar3;
  long lVar4;
  undefined8 *puVar5;
  LatencyState *pLVar6;
  long *plVar7;
  undefined4 local_c8 [2];
  TriggerEffect *local_c0;
  undefined8 uStack_b8;
  undefined8 local_b0;
  undefined8 uStack_a8;
  undefined4 local_a0;
  undefined8 local_98;
  undefined8 uStack_90;
  undefined4 local_88;
  undefined8 local_84;
  undefined4 local_78;
  undefined8 local_70;
  undefined8 uStack_68;
  undefined8 uStack_60;
  undefined5 uStack_58;
  undefined3 local_53;
  undefined5 uStack_50;
  undefined8 uStack_4b;
  undefined8 local_40;
  undefined1 local_38;
  
  pLVar6 = *(LatencyState **)(param_1 + 0xe8);
  if (pLVar6 == (LatencyState *)0x0) goto LAB_100639f08;
  plVar7 = *(long **)(param_1 + 0x40);
  if ((plVar7 == (long *)0x0) || ((*(ushort *)(plVar7 + 0xb) >> 4 & 1) != 0)) {
    local_98 = 0;
    uStack_90 = 0;
  }
  else {
    lVar4 = (**(code **)(*plVar7 + 0xc70))(plVar7);
    if ((lVar4 == 0) && (lVar4 = (**(code **)(*plVar7 + 0xd20))(plVar7), lVar4 == 0)) {
      lVar4 = (**(code **)(*plVar7 + 0xdb0))(plVar7);
      local_98 = _DAT_102970aa0;
      uStack_90 = _UNK_102970aa8;
      if (lVar4 == 0) goto LAB_100639ebc;
      puVar5 = (undefined8 *)(lVar4 + 0x1a8);
    }
    else {
      puVar5 = (undefined8 *)(lVar4 + 0xa0);
    }
    local_98 = *puVar5;
    uStack_90 = 1;
  }
LAB_100639ebc:
  local_c8[0] = 10;
  uStack_b8 = 0;
  local_b0 = 0;
  uStack_a8 = 0;
  local_a0 = 0;
  local_88 = 0;
  local_84 = 0;
  local_78 = 0;
  uStack_68 = 0;
  local_70 = 0;
  uStack_58 = 0;
  uStack_60 = 0;
  uStack_4b = 0;
  local_53 = 0;
  uStack_50 = 0;
  local_40 = 0;
  local_38 = 0;
  local_c0 = this;
  iVar3 = LatencyState::tryToAddOneTimeEffect(pLVar6,local_c8,*(undefined8 *)(pLVar6 + 0xab8));
  if (iVar3 == 0) {
    return;
  }
LAB_100639f08:
  puVar5 = *(undefined8 **)this;
  puVar1 = *(undefined8 **)(this + 8);
  do {
    if (puVar5 == puVar1) {
      return;
    }
    lVar4 = *(long *)((TriggerEffectItem *)*puVar5 + 0x10);
    if (lVar4 == 0) {
LAB_100639f10:
      TriggerEffectItem::apply((TriggerEffectItem *)*puVar5,param_1);
    }
    else {
      TVar2 = param_1[0xdc];
      if (((ulong)(byte)TVar2 == 0) ||
         ((uint)*(byte *)(lVar4 + 0x70) ==
          ((uint)(*(ulong *)(lVar4 + ((ulong)((byte)TVar2 >> 3) & 0x18) + 0x38) >>
                 ((ulong)(byte)TVar2 & 0x3f)) & 1))) goto LAB_100639f10;
    }
    puVar5 = puVar5 + 1;
  } while( true );
}



// ===== Trigger::apply  @ 0x10064b424 =====

/* Trigger::apply(TriggerContext const&) const */

void __thiscall Trigger::apply(Trigger *this,TriggerContext *param_1)

{
  undefined8 *puVar1;
  undefined8 *puVar2;
  
  puVar1 = *(undefined8 **)(this + 8);
  for (puVar2 = *(undefined8 **)this; puVar2 != puVar1; puVar2 = puVar2 + 1) {
    (**(code **)(*(long *)*puVar2 + 0x20))((long *)*puVar2,param_1);
  }
  return;
}



// ===== AttackReaction::apply  @ 0x100796998 =====

/* AttackReaction::apply(TriggerContext const&, DamageHit const&) const */

void __thiscall
AttackReaction::apply(AttackReaction *this,TriggerContext *param_1,DamageHit *param_2)

{
  undefined8 *puVar1;
  undefined8 *puVar2;
  
  puVar1 = *(undefined8 **)(this + 8);
  for (puVar2 = *(undefined8 **)this; puVar2 != puVar1; puVar2 = puVar2 + 1) {
    AttackReactionItem::apply((AttackReactionItem *)*puVar2,param_1,param_2);
  }
  return;
}



// ===== ExplosionDefinitions::apply  @ 0x1007981e8 =====

/* ExplosionDefinitions::apply(Surface&, MapPosition, Direction, ForceID) const */

void __thiscall
ExplosionDefinitions::apply
          (ExplosionDefinitions *this,undefined8 param_1,undefined8 param_3,undefined1 param_4,
          undefined1 param_5)

{
  ExplosionDefinition *pEVar1;
  ExplosionDefinition *pEVar2;
  
  pEVar2 = *(ExplosionDefinition **)(this + 0x28);
  for (pEVar1 = *(ExplosionDefinition **)(this + 0x20); pEVar1 != pEVar2; pEVar1 = pEVar1 + 0x20) {
    ExplosionDefinition::apply(pEVar1,param_1,param_3,param_4,param_5);
  }
  return;
}



// ===== ExplosionDefinition::apply  @ 0x1007a0fc0 =====

/* ExplosionDefinition::apply(Surface&, MapPosition, Direction, ForceID) const */

void __thiscall
ExplosionDefinition::apply
          (ExplosionDefinition *this,Surface *param_1,undefined8 param_3,undefined1 param_4,
          undefined1 param_5)

{
  long lVar1;
  long *plVar2;
  undefined8 uVar3;
  long *local_f0;
  double dStack_e8;
  undefined8 local_e0;
  undefined1 local_d8;
  undefined1 local_d7;
  undefined1 local_d6;
  undefined8 local_d0;
  undefined8 local_c8;
  undefined8 uStack_c0;
  undefined8 local_b8;
  undefined8 uStack_b0;
  undefined8 local_a8;
  undefined8 uStack_a0;
  undefined8 local_98;
  undefined8 uStack_90;
  undefined8 local_88;
  undefined8 uStack_80;
  undefined4 uStack_78;
  undefined3 uStack_74;
  undefined1 local_71;
  undefined8 local_70;
  undefined1 local_68;
  undefined8 local_60;
  undefined8 uStack_58;
  
  plVar2 = *(long **)(*(long *)PTR_indexToPrototype_102d4c840 + (ulong)*(ushort *)this * 8);
  uVar3 = *(undefined8 *)(param_1 + 0xb8);
  dStack_e8 = *(double *)(this + 0x18);
  local_f0 = *(long **)(this + 0x10);
  Vector2<double,Vector>::rotate(&local_f0,param_4);
  local_e0 = CONCAT44((int)(dStack_e8 * 256.0) + (int)((ulong)param_3 >> 0x20),
                      (int)((double)local_f0 * 256.0) + (int)param_3);
  local_d6 = CorePrototypes::normalQuality;
  local_d0 = 0;
  uStack_c0 = 0x7fffffff7fffffff;
  local_c8 = 0x7fffffff7fffffff;
  local_b8 = 0;
  uStack_b0 = 0;
  uStack_a0 = 0x7fffffff7fffffff;
  local_a8 = 0x7fffffff7fffffff;
  local_98 = 0;
  uStack_90 = 0;
  local_88 = 0;
  uStack_80 = 0x7fffffff7fffffff;
  uStack_74 = 0;
  uStack_78 = 0;
  local_71 = 0x14;
  local_70 = 0x10000ff00000000;
  local_68 = 0;
  local_60 = 0;
  uStack_58 = 0;
  local_f0 = plVar2;
  dStack_e8 = (double)uVar3;
  local_d8 = param_4;
  local_d7 = param_5;
  if (plVar2 != (long *)0x0) {
    lVar1 = (**(code **)(*plVar2 + 0x6b0))(plVar2,&local_f0);
    if (lVar1 != 0) {
      Surface::addEntity(param_1,lVar1,0,1,0,0,1);
    }
    return;
  }
                    /* WARNING: Subroutine does not return */
  Logging::logAndAbortOrThrow
            ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Entity/EntityCreationParameters.cpp"
             ,0x5b,9,"Trying to create entity from nullptr EntityPrototype");
}



// ===== EffectTriggerer::apply  @ 0x10096bf44 =====

/* EffectTriggerer::apply(TriggerContext const&) */

void __thiscall EffectTriggerer::apply(EffectTriggerer *this,TriggerContext *param_1)

{
  double *pdVar1;
  ulong uVar2;
  long *plVar3;
  double *pdVar4;
  long lVar5;
  long lVar6;
  ulong uVar7;
  double dVar8;
  EffectTriggerer EVar9;
  EffectTriggerer EVar10;
  ulong uVar11;
  ulong uVar12;
  double dVar13;
  
  if (this[0x39] != (EffectTriggerer)0x0) {
    plVar3 = *(long **)this;
    lVar5 = *plVar3;
    if (plVar3[1] == lVar5) {
      EVar9 = (EffectTriggerer)0x0;
      EVar10 = (EffectTriggerer)0x0;
    }
    else {
      EVar10 = (EffectTriggerer)0x0;
      EVar9 = (EffectTriggerer)0x0;
      lVar6 = *(long *)(this + 0x28);
      uVar2 = 1;
      uVar12 = 0;
      do {
        uVar11 = uVar2;
        pdVar1 = (double *)(lVar6 + uVar12 * 0x10);
        dVar13 = *pdVar1;
        dVar8 = pdVar1[1];
        if (dVar13 <= 0.0 && dVar8 == 0.0) {
          pdVar4 = (double *)(lVar5 + uVar12 * 0x38);
          *pdVar1 = *pdVar4;
          pdVar1[1] = pdVar4[2];
          TriggerEffect::apply((TriggerEffect *)(pdVar4 + 4),param_1);
          lVar6 = *(long *)(this + 0x28);
          plVar3 = *(long **)this;
          lVar5 = *plVar3;
          pdVar1 = (double *)(lVar6 + uVar12 * 0x10);
          dVar13 = *pdVar1;
          dVar8 = pdVar1[1];
        }
        EVar9 = (EffectTriggerer)((dVar13 <= 0.0 && dVar8 == 0.0) | (byte)EVar9);
        EVar10 = (EffectTriggerer)((0.0 < dVar13 || dVar8 != 0.0) | (byte)EVar10);
        uVar7 = (plVar3[1] - lVar5 >> 3) * 0x6db6db6db6db6db7;
        uVar2 = (ulong)((int)uVar11 + 1);
        uVar12 = uVar11;
      } while (uVar11 <= uVar7 && uVar7 - uVar11 != 0);
    }
    this[0x38] = EVar10;
    this[0x39] = EVar9;
  }
  return;
}



// ===== ManageModsPane::apply  @ 0x1010067e8 =====

/* ManageModsPane::apply() */

byte __thiscall ManageModsPane::apply(ManageModsPane *this)

{
  ulong uVar1;
  size_t sVar2;
  size_t sVar3;
  undefined8 *puVar4;
  ulong *puVar5;
  ulong *puVar6;
  undefined4 uVar7;
  char cVar8;
  byte bVar9;
  ushort uVar10;
  ushort uVar11;
  ushort uVar12;
  ushort uVar13;
  __tree_node **pp_Var14;
  __tree_node _Var15;
  bool bVar16;
  undefined1 uVar17;
  int iVar18;
  long lVar19;
  long *plVar20;
  __tree_node *p_Var21;
  ModManager *pMVar22;
  Mod *this_00;
  void *pvVar23;
  long *plVar24;
  __tree_node *p_Var25;
  long *plVar26;
  ulong *puVar27;
  long *plVar28;
  long *plVar29;
  ulong uVar30;
  long lVar31;
  undefined8 *puVar32;
  long *plVar33;
  long *plVar34;
  undefined8 *puVar35;
  long *plVar36;
  undefined8 *puVar37;
  byte bVar38;
  __tree_node *p_Var39;
  undefined8 *puVar40;
  long lVar41;
  undefined8 *local_d0;
  __tree_node **local_c8;
  __tree_node *local_c0;
  long local_b8;
  __tree_node *local_b0;
  __tree_node *p_Stack_a8;
  undefined8 local_a0;
  undefined4 local_98;
  undefined2 uStack_94;
  undefined4 local_90;
  __tree_node **local_88;
  __tree_node *local_80;
  long local_78;
  __tree_node **local_68;
  
  plVar33 = *(long **)(this + 0xd78);
  plVar24 = *(long **)(this + 0xd80);
  if (plVar33 == plVar24) {
    bVar38 = 0;
  }
  else {
    bVar38 = 0;
    do {
      plVar36 = (long *)**(undefined8 **)*plVar33;
      uVar17 = agui::ToggleButton::isChecked((ToggleButton *)((undefined8 *)*plVar33 + 1));
      *(undefined1 *)((long)plVar36 + 0x37) = uVar17;
      lVar31 = *(long *)(_global + 0x160);
      p_Stack_a8 = (__tree_node *)0x0;
      local_a0 = 0;
      local_b0 = (__tree_node *)&p_Stack_a8;
      lVar19 = std::
               __tree<std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>,std::__map_value_compare<std::string,std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>,std::less<std::string>,true>,std::allocator<std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>>>
               ::find<std::string>((__tree<std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>,std::__map_value_compare<std::string,std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>,std::less<std::string>,true>,std::allocator<std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>>>
                                    *)(lVar31 + 0x80),(string *)(plVar36 + 1));
      if (lVar31 + 0x88 != lVar19) {
        plVar34 = *(long **)(lVar19 + 0x38);
        uVar30 = local_a0;
        while (plVar34 != (long *)(lVar19 + 0x40)) {
          p_Var21 = (__tree_node *)&p_Stack_a8;
          p_Var39 = (__tree_node *)&p_Stack_a8;
          if (p_Stack_a8 != (__tree_node *)0x0) {
            uVar10 = *(ushort *)(plVar34 + 4);
            uVar11 = *(ushort *)((long)plVar34 + 0x22);
            uVar12 = *(ushort *)((long)plVar34 + 0x24);
            p_Var25 = p_Stack_a8;
            do {
              while( true ) {
                p_Var21 = p_Var25;
                uVar13 = *(ushort *)(p_Var21 + 0x1a);
                if (uVar10 == uVar13) break;
                if (uVar10 < uVar13) goto LAB_1010068f4;
                if (uVar10 <= uVar13) goto LAB_101006af8;
LAB_101006960:
                p_Var25 = *(__tree_node **)(p_Var21 + 8);
                if (*(__tree_node **)(p_Var21 + 8) == (__tree_node *)0x0) {
                  p_Var39 = p_Var21 + 8;
                  goto LAB_10100696c;
                }
              }
              uVar13 = *(ushort *)(p_Var21 + 0x1c);
              if (uVar11 != uVar13) {
                if (uVar11 < uVar13) goto LAB_1010068f4;
                if (uVar13 < uVar11) goto LAB_101006960;
                goto LAB_101006af8;
              }
              uVar13 = *(ushort *)(p_Var21 + 0x1e);
              if (uVar13 <= uVar12) {
                if (uVar13 != uVar12 && uVar13 < uVar12) goto LAB_101006960;
                goto LAB_101006af8;
              }
LAB_1010068f4:
              p_Var25 = *(__tree_node **)p_Var21;
              p_Var39 = p_Var21;
            } while (*(__tree_node **)p_Var21 != (__tree_node *)0x0);
          }
LAB_10100696c:
          p_Var25 = operator_new(0x20);
          lVar31 = plVar34[4];
          *(undefined2 *)(p_Var25 + 0x1e) = *(undefined2 *)((long)plVar34 + 0x24);
          *(int *)(p_Var25 + 0x1a) = (int)lVar31;
          *(long *)p_Var25 = 0;
          *(long *)(p_Var25 + 8) = 0;
          *(__tree_node **)(p_Var25 + 0x10) = p_Var21;
          *(__tree_node **)p_Var39 = p_Var25;
          if (*(__tree_node **)local_b0 != (__tree_node *)0x0) {
            p_Var25 = *(__tree_node **)p_Var39;
            local_b0 = *(__tree_node **)local_b0;
          }
          _Var15 = (__tree_node)(p_Var25 == p_Stack_a8);
          p_Var25[0x18] = _Var15;
joined_r0x0001010069b8:
          if (((bool)_Var15) || (plVar28 = *(long **)(p_Var25 + 0x10), (char)plVar28[3] != '\0'))
          goto LAB_101006af0;
          p_Var21 = (__tree_node *)plVar28[2];
          plVar20 = *(long **)p_Var21;
          if (plVar20 != plVar28) {
            if ((plVar20 == (long *)0x0) || (plVar20 = plVar20 + 3, (char)*plVar20 != '\0')) {
              if ((__tree_node *)*plVar28 == p_Var25) {
                lVar31 = *(long *)(p_Var25 + 8);
                *plVar28 = lVar31;
                if (lVar31 != 0) {
                  *(long **)(lVar31 + 0x10) = plVar28;
                  p_Var21 = (__tree_node *)plVar28[2];
                }
                *(__tree_node **)(p_Var25 + 0x10) = p_Var21;
                ((undefined8 *)plVar28[2])[*(long **)plVar28[2] != plVar28] = p_Var25;
                *(long **)(p_Var25 + 8) = plVar28;
                plVar28[2] = (long)p_Var25;
                p_Var21 = *(__tree_node **)(p_Var25 + 0x10);
                p_Var25[0x18] = (__tree_node)0x1;
                p_Var21[0x18] = (__tree_node)0x0;
                plVar28 = *(long **)(p_Var21 + 8);
                lVar31 = *plVar28;
                *(long *)(p_Var21 + 8) = lVar31;
              }
              else {
                *(undefined1 *)(plVar28 + 3) = 1;
                p_Var21[0x18] = (__tree_node)0x0;
                plVar28 = *(long **)(p_Var21 + 8);
                lVar31 = *plVar28;
                *(long *)(p_Var21 + 8) = lVar31;
              }
              if (lVar31 != 0) {
                *(__tree_node **)(lVar31 + 0x10) = p_Var21;
              }
              plVar28[2] = *(long *)(p_Var21 + 0x10);
              (*(undefined8 **)(p_Var21 + 0x10))
              [(__tree_node *)**(undefined8 **)(p_Var21 + 0x10) != p_Var21] = plVar28;
              *plVar28 = (long)p_Var21;
              goto LAB_101006aec;
            }
LAB_1010069c0:
            *(undefined1 *)(plVar28 + 3) = 1;
            _Var15 = (__tree_node)(p_Var21 == p_Stack_a8);
            p_Var21[0x18] = _Var15;
            *(char *)plVar20 = '\x01';
            p_Var25 = p_Var21;
            goto joined_r0x0001010069b8;
          }
          if ((*(long *)(p_Var21 + 8) != 0) &&
             (plVar20 = (long *)(*(long *)(p_Var21 + 8) + 0x18), *(char *)plVar20 == '\0'))
          goto LAB_1010069c0;
          if ((__tree_node *)*plVar28 == p_Var25) {
            *(undefined1 *)(plVar28 + 3) = 1;
            p_Var21[0x18] = (__tree_node)0x0;
            lVar31 = plVar28[1];
            *(long *)p_Var21 = lVar31;
          }
          else {
            plVar20 = (long *)plVar28[1];
            lVar31 = *plVar20;
            plVar28[1] = lVar31;
            if (lVar31 != 0) {
              *(long **)(lVar31 + 0x10) = plVar28;
              p_Var21 = (__tree_node *)plVar28[2];
            }
            plVar20[2] = (long)p_Var21;
            ((undefined8 *)plVar28[2])[*(long **)plVar28[2] != plVar28] = plVar20;
            *plVar20 = (long)plVar28;
            plVar28[2] = (long)plVar20;
            p_Var21 = (__tree_node *)plVar20[2];
            plVar28 = *(long **)p_Var21;
            *(undefined1 *)(plVar20 + 3) = 1;
            p_Var21[0x18] = (__tree_node)0x0;
            lVar31 = plVar28[1];
            *(long *)p_Var21 = lVar31;
          }
          if (lVar31 != 0) {
            *(__tree_node **)(lVar31 + 0x10) = p_Var21;
          }
          plVar28[2] = *(long *)(p_Var21 + 0x10);
          (*(undefined8 **)(p_Var21 + 0x10))
          [(__tree_node *)**(undefined8 **)(p_Var21 + 0x10) != p_Var21] = plVar28;
          plVar28[1] = (long)p_Var21;
LAB_101006aec:
          *(long **)(p_Var21 + 0x10) = plVar28;
LAB_101006af0:
          uVar30 = uVar30 + 1;
          local_a0 = uVar30;
LAB_101006af8:
          plVar28 = (long *)plVar34[1];
          plVar20 = plVar34;
          if ((long *)plVar34[1] == (long *)0x0) {
            do {
              plVar34 = (long *)plVar20[2];
              bVar16 = (long *)*plVar34 != plVar20;
              plVar20 = plVar34;
            } while (bVar16);
          }
          else {
            do {
              plVar34 = plVar28;
              plVar28 = (long *)*plVar34;
            } while ((long *)*plVar34 != (long *)0x0);
          }
        }
      }
      if (local_a0 == 0) {
LAB_101006c10:
        *(undefined4 *)(plVar36 + 6) = 0;
        *(undefined2 *)((long)plVar36 + 0x34) = 0;
        cVar8 = *(char *)(*(long *)*plVar33 + 0xe);
      }
      else {
        p_Var21 = p_Stack_a8;
        p_Var39 = (__tree_node *)&p_Stack_a8;
        if (p_Stack_a8 == (__tree_node *)0x0) {
          do {
            p_Var25 = *(__tree_node **)(p_Var39 + 0x10);
            bVar16 = *(__tree_node **)p_Var25 == p_Var39;
            p_Var39 = p_Var25;
          } while (bVar16);
        }
        else {
          do {
            p_Var25 = p_Var21;
            p_Var21 = *(__tree_node **)(p_Var25 + 8);
          } while (*(__tree_node **)(p_Var25 + 8) != (__tree_node *)0x0);
        }
        lVar19 = *(long *)*plVar33;
        if (((*(short *)(lVar19 + 8) == *(short *)(p_Var25 + 0x1a)) &&
            (*(short *)(lVar19 + 10) == *(short *)(p_Var25 + 0x1c))) &&
           (*(short *)(lVar19 + 0xc) == *(short *)(p_Var25 + 0x1e))) goto LAB_101006c10;
        uVar7 = *(undefined4 *)(lVar19 + 8);
        *(undefined2 *)((long)plVar36 + 0x34) = *(undefined2 *)(lVar19 + 0xc);
        *(undefined4 *)(plVar36 + 6) = uVar7;
        cVar8 = *(char *)(*(long *)*plVar33 + 0xe);
      }
      if (cVar8 != '\0') {
        *(undefined1 *)((long)plVar36 + 0x37) = 0;
        std::__tree<Filesystem::Path,std::less<Filesystem::Path>,std::allocator<Filesystem::Path>>::
        __emplace_unique_key_args<Filesystem::Path,Filesystem::Path_const&>
                  ((__tree<Filesystem::Path,std::less<Filesystem::Path>,std::allocator<Filesystem::Path>>
                    *)&FileUtil::filesToDeleteAtShutdown,(Path *)(*plVar36 + 0x40),
                   (Path *)(*plVar36 + 0x40));
        lVar31 = *(long *)(_global + 0x160);
        lVar19 = std::
                 __tree<std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>,std::__map_value_compare<std::string,std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>,std::less<std::string>,true>,std::allocator<std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>>>
                 ::find<std::string>((__tree<std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>,std::__map_value_compare<std::string,std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>,std::less<std::string>,true>,std::allocator<std::__value_type<std::string,std::set<ModManager::DuplicateVersion,std::less<ModManager::DuplicateVersion>,std::allocator<ModManager::DuplicateVersion>>>>>
                                      *)(lVar31 + 0x80),(string *)(plVar36 + 1));
        if (lVar31 + 0x88 == lVar19) {
          bVar38 = 1;
        }
        else {
          plVar36 = *(long **)(lVar19 + 0x38);
          while (plVar36 != (long *)(lVar19 + 0x40)) {
            plVar20 = (long *)&DAT_103350c58;
            plVar34 = plVar36 + 6;
            plVar28 = DAT_103350c58;
            if (DAT_103350c58 == (long *)0x0) {
              plVar26 = (long *)&DAT_103350c58;
              plVar29 = plVar20;
            }
            else {
              do {
                while( true ) {
                  plVar29 = plVar28;
                  plVar26 = plVar29 + 4;
                  bVar38 = *(byte *)((long)plVar29 + 0x37);
                  plVar28 = (long *)*plVar26;
                  if (-1 < (char)bVar38) {
                    plVar28 = plVar26;
                  }
                  uVar30 = plVar29[5];
                  if (-1 < (char)bVar38) {
                    uVar30 = (ulong)bVar38;
                  }
                  iVar18 = std::__fs::filesystem::path::__compare(plVar34,plVar28,uVar30);
                  if (iVar18 < 0) break;
                  bVar38 = *(byte *)((long)plVar36 + 0x47);
                  plVar28 = (long *)plVar36[6];
                  if (-1 < (char)bVar38) {
                    plVar28 = plVar34;
                  }
                  uVar30 = plVar36[7];
                  if (-1 < (char)bVar38) {
                    uVar30 = (ulong)bVar38;
                  }
                  iVar18 = std::__fs::filesystem::path::__compare(plVar26,plVar28,uVar30);
                  if (-1 < iVar18) {
                    plVar26 = plVar20;
                    if (*plVar20 != 0) {
                      plVar34 = (long *)plVar36[1];
                      goto joined_r0x000101006ec0;
                    }
                    goto LAB_101006d5c;
                  }
                  plVar26 = plVar29 + 1;
                  plVar28 = (long *)*plVar26;
                  plVar20 = plVar26;
                  if ((long *)*plVar26 == (long *)0x0) goto LAB_101006d5c;
                }
                plVar28 = (long *)*plVar29;
                plVar20 = plVar29;
                plVar26 = plVar29;
              } while ((long *)*plVar29 != (long *)0x0);
            }
LAB_101006d5c:
            plVar20 = operator_new(0x38);
            plVar28 = plVar20 + 4;
            if (*(char *)((long)plVar36 + 0x47) < '\0') {
              pvVar23 = (void *)plVar36[6];
              uVar30 = plVar36[7];
              if (uVar30 < 0x17) {
                *(char *)((long)plVar20 + 0x37) = (char)uVar30;
              }
              else {
                if (0x7fffffffffffffef < uVar30) {
                    /* WARNING: Subroutine does not return */
                  std::string::__throw_length_error_abi_v160006_();
                }
                uVar1 = (uVar30 | 0xf) + 1;
                plVar28 = operator_new(uVar1);
                plVar20[5] = uVar30;
                plVar20[6] = uVar1 | 0x8000000000000000;
                plVar20[4] = (long)plVar28;
              }
              _memmove(plVar28,pvVar23,uVar30 + 1);
              *plVar20 = 0;
              plVar20[1] = 0;
              plVar20[2] = (long)plVar29;
              *plVar26 = (long)plVar20;
              plVar34 = (long *)*FileUtil::filesToDeleteAtShutdown;
              plVar28 = DAT_103350c58;
            }
            else {
              lVar41 = plVar36[7];
              lVar31 = *plVar34;
              plVar20[6] = plVar36[8];
              plVar20[5] = lVar41;
              *plVar28 = lVar31;
              *plVar20 = 0;
              plVar20[1] = 0;
              plVar20[2] = (long)plVar29;
              *plVar26 = (long)plVar20;
              plVar34 = (long *)*FileUtil::filesToDeleteAtShutdown;
              plVar28 = DAT_103350c58;
            }
            if (plVar34 != (long *)0x0) {
              plVar20 = (long *)*plVar26;
              FileUtil::filesToDeleteAtShutdown = plVar34;
            }
            bVar16 = plVar20 == plVar28;
            DAT_103350c58 = plVar28;
            *(bool *)(plVar20 + 3) = bVar16;
joined_r0x000101006db8:
            if ((bVar16) || (plVar34 = (long *)plVar20[2], (char)plVar34[3] != '\0'))
            goto LAB_101006f18;
            plVar26 = (long *)plVar34[2];
            plVar29 = (long *)*plVar26;
            if (plVar29 != plVar34) {
              if ((plVar29 == (long *)0x0) || (plVar29 = plVar29 + 3, (char)*plVar29 != '\0')) {
                if ((long *)*plVar34 == plVar20) {
                  lVar31 = plVar20[1];
                  *plVar34 = lVar31;
                  if (lVar31 != 0) {
                    *(long **)(lVar31 + 0x10) = plVar34;
                    plVar26 = (long *)plVar34[2];
                  }
                  plVar20[2] = (long)plVar26;
                  ((undefined8 *)plVar34[2])[*(long **)plVar34[2] != plVar34] = plVar20;
                  plVar20[1] = (long)plVar34;
                  plVar34[2] = (long)plVar20;
                  plVar26 = (long *)plVar20[2];
                  *(undefined1 *)(plVar20 + 3) = 1;
                  *(undefined1 *)(plVar26 + 3) = 0;
                  plVar34 = (long *)plVar26[1];
                  lVar31 = *plVar34;
                  plVar26[1] = lVar31;
                }
                else {
                  *(undefined1 *)(plVar34 + 3) = 1;
                  *(undefined1 *)(plVar26 + 3) = 0;
                  plVar34 = (long *)plVar26[1];
                  lVar31 = *plVar34;
                  plVar26[1] = lVar31;
                }
                if (lVar31 != 0) {
                  *(long **)(lVar31 + 0x10) = plVar26;
                }
                plVar34[2] = plVar26[2];
                ((undefined8 *)plVar26[2])[*(long **)plVar26[2] != plVar26] = plVar34;
                *plVar34 = (long)plVar26;
                goto LAB_101006f14;
              }
LAB_101006dc0:
              *(undefined1 *)(plVar34 + 3) = 1;
              bVar16 = plVar26 == plVar28;
              *(bool *)(plVar26 + 3) = bVar16;
              *(char *)plVar29 = '\x01';
              plVar20 = plVar26;
              goto joined_r0x000101006db8;
            }
            if ((plVar26[1] != 0) &&
               (plVar29 = (long *)(plVar26[1] + 0x18), *(char *)plVar29 == '\0'))
            goto LAB_101006dc0;
            if ((long *)*plVar34 == plVar20) {
              *(undefined1 *)(plVar34 + 3) = 1;
              *(undefined1 *)(plVar26 + 3) = 0;
              lVar31 = plVar34[1];
              *plVar26 = lVar31;
            }
            else {
              plVar28 = (long *)plVar34[1];
              lVar31 = *plVar28;
              plVar34[1] = lVar31;
              if (lVar31 != 0) {
                *(long **)(lVar31 + 0x10) = plVar34;
                plVar26 = (long *)plVar34[2];
              }
              plVar28[2] = (long)plVar26;
              ((undefined8 *)plVar34[2])[*(long **)plVar34[2] != plVar34] = plVar28;
              *plVar28 = (long)plVar34;
              plVar34[2] = (long)plVar28;
              plVar26 = (long *)plVar28[2];
              plVar34 = (long *)*plVar26;
              *(undefined1 *)(plVar28 + 3) = 1;
              *(undefined1 *)(plVar26 + 3) = 0;
              lVar31 = plVar34[1];
              *plVar26 = lVar31;
            }
            if (lVar31 != 0) {
              *(long **)(lVar31 + 0x10) = plVar26;
            }
            plVar34[2] = plVar26[2];
            ((undefined8 *)plVar26[2])[*(long **)plVar26[2] != plVar26] = plVar34;
            plVar34[1] = (long)plVar26;
LAB_101006f14:
            plVar26[2] = (long)plVar34;
LAB_101006f18:
            DAT_103350c60 = DAT_103350c60 + 1;
            plVar34 = (long *)plVar36[1];
joined_r0x000101006ec0:
            plVar28 = plVar36;
            if (plVar34 == (long *)0x0) {
              do {
                plVar36 = (long *)plVar28[2];
                bVar16 = (long *)*plVar36 != plVar28;
                plVar28 = plVar36;
              } while (bVar16);
            }
            else {
              do {
                plVar36 = plVar34;
                plVar34 = (long *)*plVar36;
              } while ((long *)*plVar36 != (long *)0x0);
            }
          }
          bVar38 = 1;
        }
      }
      std::__tree<ModVersion,std::less<ModVersion>,std::allocator<ModVersion>>::destroy
                ((__tree<ModVersion,std::less<ModVersion>,std::allocator<ModVersion>> *)&local_b0,
                 p_Stack_a8);
      plVar33 = plVar33 + 1;
    } while (plVar33 != plVar24);
  }
  plVar33 = *(long **)(_global + 0x160);
  puVar5 = (ulong *)*plVar33;
  puVar6 = (ulong *)plVar33[1];
  if (puVar5 == puVar6) {
    puVar37 = *(undefined8 **)(this + 0xd78);
    local_d0 = *(undefined8 **)(this + 0xd80);
    if (puVar37 == local_d0) goto LAB_1010074f4;
LAB_10100715c:
    bVar16 = false;
    puVar32 = puVar37;
    do {
      if (*(char *)((long)*(long **)*puVar32 + 0xe) == '\0') {
        cVar8 = *(char *)(**(long **)*puVar32 + 0x37);
        bVar16 = (bool)(cVar8 != *(char *)(*(long *)(_global + 0x240) + 0xf18) | bVar16);
        bVar38 = cVar8 != '\0' | bVar38;
      }
      puVar32 = puVar32 + 1;
    } while (puVar32 != local_d0);
LAB_1010072e8:
    if (!bVar16) goto LAB_1010074f4;
    local_80 = (__tree_node *)0x0;
    local_78 = 0;
    local_88 = &local_80;
    do {
      lVar19 = **(long **)*puVar37;
      puVar40 = (undefined8 *)(lVar19 + 8);
      puVar35 = (undefined8 *)*puVar40;
      bVar38 = *(byte *)(lVar19 + 0x1f);
      puVar32 = puVar35;
      if (-1 < (char)bVar38) {
        puVar32 = puVar40;
      }
      p_Var39 = *(__tree_node **)(lVar19 + 0x10);
      p_Var21 = p_Var39;
      if (-1 < (char)bVar38) {
        p_Var21 = (__tree_node *)(ulong)bVar38;
      }
      plVar24 = (long *)*plVar33;
      plVar36 = (long *)plVar33[1];
      if (plVar24 != plVar36) {
        if (p_Var21 == (__tree_node *)0x0) {
          do {
            bVar9 = *(byte *)(*plVar24 + 0x1f);
            uVar30 = (ulong)bVar9;
            if ((char)bVar9 < '\0') {
              uVar30 = *(ulong *)(*plVar24 + 0x10);
            }
            if (uVar30 == 0) goto LAB_101007304;
            plVar24 = plVar24 + 1;
          } while (plVar24 != plVar36);
        }
        else {
          do {
            lVar31 = *plVar24;
            bVar9 = *(byte *)(lVar31 + 0x1f);
            puVar4 = *(void **)(lVar31 + 8);
            if (-1 < (char)bVar9) {
              puVar4 = (undefined8 *)(lVar31 + 8);
            }
            p_Var25 = *(__tree_node **)(lVar31 + 0x10);
            if (-1 < (char)bVar9) {
              p_Var25 = (__tree_node *)(ulong)bVar9;
            }
            if ((p_Var21 == p_Var25) &&
               (iVar18 = _memcmp(puVar32,puVar4,(size_t)p_Var21), iVar18 == 0)) goto LAB_101007304;
            plVar24 = plVar24 + 1;
          } while (plVar24 != plVar36);
        }
      }
      uVar17 = *(undefined1 *)(lVar19 + 0x37);
      if ((char)bVar38 < '\0') {
        if ((__tree_node *)&DAT_00000016 < p_Var39) {
          if ((__tree_node *)0x7fffffffffffffef < p_Var39) {
                    /* WARNING: Subroutine does not return */
            std::string::__throw_length_error_abi_v160006_();
          }
          uVar30 = ((ulong)p_Var39 | 0xf) + 1;
          p_Var21 = operator_new(uVar30);
          local_a0 = uVar30 | 0x8000000000000000;
          local_b0 = p_Var21;
          p_Stack_a8 = p_Var39;
        }
        else {
          local_a0 = CONCAT17((char)p_Var39,(undefined7)local_a0);
          p_Var21 = (__tree_node *)&local_b0;
        }
        _memmove(p_Var21,puVar35,(size_t)(p_Var39 + 1));
      }
      else {
        p_Stack_a8 = *(__tree_node **)(lVar19 + 0x10);
        local_b0 = (__tree_node *)*puVar40;
        local_a0 = *(ulong *)(lVar19 + 0x18);
      }
      uStack_94 = 0;
      local_98 = 0;
      local_90 = 0;
      ModID::checkNameSize((ModID *)&local_b0);
      local_68 = &local_b0;
      lVar19 = std::
               __tree<std::__value_type<ModID,bool>,std::__map_value_compare<ModID,std::__value_type<ModID,bool>,std::less<ModID>,true>,std::allocator<std::__value_type<ModID,bool>>>
               ::
               __emplace_unique_key_args<ModID,std::piecewise_construct_t_const&,std::tuple<ModID&&>,std::tuple<>>
                         ((ModID *)&local_88,(piecewise_construct_t *)&local_b0,
                          (tuple *)&std::piecewise_construct,(tuple *)&local_68);
      *(undefined1 *)(lVar19 + 0x48) = uVar17;
      if ((long)local_a0 < 0) {
        operator_delete(local_b0);
      }
LAB_101007304:
      puVar37 = puVar37 + 1;
    } while (puVar37 != local_d0);
    pMVar22 = *(ModManager **)(_global + 0x160);
    local_c8 = local_88;
    local_c0 = local_80;
    local_b8 = local_78;
    pp_Var14 = &local_c0;
    if (local_78 != 0) {
      *(__tree_node ***)(local_80 + 0x10) = &local_c0;
      local_80 = (__tree_node *)0x0;
      local_78 = 0;
      pp_Var14 = local_c8;
      local_88 = &local_80;
    }
    local_c8 = pp_Var14;
    ModManager::writeModlist(pMVar22,&local_c8);
    std::
    __tree<std::__value_type<ModID,bool>,std::__map_value_compare<ModID,std::__value_type<ModID,bool>,std::less<ModID>,true>,std::allocator<std::__value_type<ModID,bool>>>
    ::destroy((__tree<std::__value_type<ModID,bool>,std::__map_value_compare<ModID,std::__value_type<ModID,bool>,std::less<ModID>,true>,std::allocator<std::__value_type<ModID,bool>>>
               *)&local_c8,local_c0);
    *(undefined1 *)(*(long *)(_global + 0x160) + 0x98) = 0;
    std::
    __tree<std::__value_type<ModID,bool>,std::__map_value_compare<ModID,std::__value_type<ModID,bool>,std::less<ModID>,true>,std::allocator<std::__value_type<ModID,bool>>>
    ::destroy((__tree<std::__value_type<ModID,bool>,std::__map_value_compare<ModID,std::__value_type<ModID,bool>,std::less<ModID>,true>,std::allocator<std::__value_type<ModID,bool>>>
               *)&local_88,local_80);
  }
  else {
    plVar24 = plVar33 + 0x18;
    puVar27 = puVar5;
    if ((long *)*plVar24 != (long *)0x0) {
      do {
        uVar30 = *puVar27;
        plVar36 = plVar24;
        plVar34 = (long *)*plVar24;
        do {
          plVar28 = plVar34 + 1;
          if (uVar30 <= (ulong)plVar34[4]) {
            plVar36 = plVar34;
            plVar28 = plVar34;
          }
          plVar34 = (long *)*plVar28;
        } while (plVar34 != (long *)0x0);
        if (((((plVar36 == plVar24) || (uVar30 < (ulong)plVar36[4])) ||
             (*(char *)(uVar30 + 0x37) != (char)plVar36[5])) ||
            ((*(short *)(uVar30 + 0x30) != *(short *)((long)plVar36 + 0x2a) ||
             (*(short *)(uVar30 + 0x32) != *(short *)((long)plVar36 + 0x2c))))) ||
           (*(short *)(uVar30 + 0x34) != *(short *)((long)plVar36 + 0x2e))) {
          bVar38 = 1;
          puVar37 = *(undefined8 **)(this + 0xd78);
          local_d0 = *(undefined8 **)(this + 0xd80);
          if (puVar37 == local_d0) goto LAB_1010074f4;
          goto LAB_10100714c;
        }
        puVar27 = puVar27 + 1;
      } while (puVar27 != puVar6);
      puVar37 = *(undefined8 **)(this + 0xd78);
      local_d0 = *(undefined8 **)(this + 0xd80);
      if (puVar37 == local_d0) goto LAB_1010074f4;
LAB_10100714c:
      if (puVar5 == puVar6) goto LAB_10100715c;
LAB_1010071d4:
      plVar24 = (long *)(_global + 0x240);
      bVar16 = false;
      puVar32 = puVar37;
      do {
        plVar36 = *(long **)*puVar32;
        lVar19 = *plVar36;
        bVar9 = *(byte *)(lVar19 + 0x1f);
        puVar35 = *(void **)(lVar19 + 8);
        if (-1 < (char)bVar9) {
          puVar35 = (undefined8 *)(lVar19 + 8);
        }
        sVar2 = *(size_t *)(lVar19 + 0x10);
        if (-1 < (char)bVar9) {
          sVar2 = (ulong)bVar9;
        }
        puVar27 = puVar5;
        if (sVar2 == 0) {
          do {
            bVar9 = *(byte *)(*puVar27 + 0x1f);
            uVar30 = (ulong)bVar9;
            if ((char)bVar9 < '\0') {
              uVar30 = *(ulong *)(*puVar27 + 0x10);
            }
            if (uVar30 == 0) goto LAB_1010071e8;
            puVar27 = puVar27 + 1;
          } while (puVar27 != puVar6);
        }
        else {
          do {
            uVar30 = *puVar27;
            bVar9 = *(byte *)(uVar30 + 0x1f);
            puVar40 = *(void **)(uVar30 + 8);
            if (-1 < (char)bVar9) {
              puVar40 = (undefined8 *)(uVar30 + 8);
            }
            sVar3 = *(size_t *)(uVar30 + 0x10);
            if (-1 < (char)bVar9) {
              sVar3 = (ulong)bVar9;
            }
            if ((sVar2 == sVar3) && (iVar18 = _memcmp(puVar35,puVar40,sVar2), iVar18 == 0))
            goto LAB_1010071e8;
            puVar27 = puVar27 + 1;
          } while (puVar27 != puVar6);
        }
        if (*(char *)((long)plVar36 + 0xe) == '\0') {
          bVar16 = (bool)(*(char *)(lVar19 + 0x37) != *(char *)(*plVar24 + 0xf18) | bVar16);
          bVar38 = *(char *)(lVar19 + 0x37) != '\0' | bVar38;
        }
LAB_1010071e8:
        puVar32 = puVar32 + 1;
      } while (puVar32 != local_d0);
      goto LAB_1010072e8;
    }
    puVar37 = *(undefined8 **)(this + 0xd78);
    local_d0 = *(undefined8 **)(this + 0xd80);
    if (puVar37 != local_d0) {
      bVar38 = 1;
      goto LAB_1010071d4;
    }
  }
  bVar38 = 1;
LAB_1010074f4:
  puVar37 = *(undefined8 **)(this + 0xd50);
  puVar32 = *(undefined8 **)(this + 0xd48);
  while (puVar37 != puVar32) {
    puVar37 = puVar37 + -1;
    this_00 = (Mod *)*puVar37;
    *puVar37 = 0;
    if (this_00 != (Mod *)0x0) {
      pvVar23 = (void *)Mod::~Mod(this_00);
      operator_delete(pvVar23);
    }
  }
  *(undefined8 **)(this + 0xd50) = puVar32;
  return bVar38;
}



// ===== ActivityBarStyleSpecification::apply  @ 0x101140b50 =====

/* ActivityBarStyleSpecification::apply(agui::ActivityBarStyle&) const */

void __thiscall
ActivityBarStyleSpecification::apply(ActivityBarStyleSpecification *this,ActivityBarStyle *param_1)

{
  uint uVar1;
  undefined8 *puVar2;
  void *pvVar3;
  float *pfVar4;
  undefined8 local_30;
  undefined8 uStack_28;
  
  StyleSpecification::apply
            ((StyleSpecification *)this,(Style *)param_1,(OptionalFundamentalBase *)0x0);
  if (this[0xb8] != (ActivityBarStyleSpecification)0x0) {
    *(undefined4 *)(param_1 + 0x68) = *(undefined4 *)(this + 0xb4);
    param_1[0x6c] = (ActivityBarStyle)0x1;
  }
  if (this[0xc0] != (ActivityBarStyleSpecification)0x0) {
    uVar1 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xbc));
    *(uint *)(param_1 + 0x70) = uVar1;
    param_1[0x74] = (ActivityBarStyle)0x1;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  pfVar4 = *(float **)(this + 200);
  if (pfVar4 != (float *)0x0) {
    agui::Color::Color((Color *)&local_30,*pfVar4,pfVar4[1],pfVar4[2],pfVar4[3]);
    puVar2 = operator_new(0x10);
    puVar2[1] = uStack_28;
    *puVar2 = local_30;
    pvVar3 = *(void **)(param_1 + 0x78);
    *(undefined8 **)(param_1 + 0x78) = puVar2;
    if (pvVar3 != (void *)0x0) {
      operator_delete(pvVar3);
    }
  }
  if (*(undefined8 **)(this + 0xd0) != (undefined8 *)0x0) {
    *(undefined8 *)(param_1 + 0x90) = **(undefined8 **)(this + 0xd0);
  }
  if (*(undefined8 **)(this + 0xd8) != (undefined8 *)0x0) {
    *(undefined8 *)(param_1 + 0x80) = **(undefined8 **)(this + 0xd8);
  }
  if (this[0xe4] != (ActivityBarStyleSpecification)0x0) {
    *(undefined4 *)(param_1 + 0x88) = *(undefined4 *)(this + 0xe0);
    param_1[0x8c] = (ActivityBarStyle)0x1;
  }
  return;
}



// ===== StyleSpecification::apply  @ 0x101140c3c =====

/* StyleSpecification::apply(agui::Style&, OptionalFundamentalBase*) const */

void __thiscall
StyleSpecification::apply(StyleSpecification *this,Style *param_1,OptionalFundamentalBase *param_2)

{
  undefined8 *puVar1;
  StyleSpecification SVar2;
  byte bVar3;
  short sVar4;
  int iVar5;
  uint uVar6;
  StyleSpecification *pSVar7;
  long *plVar8;
  undefined8 uVar9;
  string *this_00;
  RuntimeError *pRVar10;
  undefined8 *puVar11;
  ulong uVar12;
  code *pcVar13;
  ulong uVar14;
  LocaleProvider *pLVar15;
  string *psVar16;
  undefined4 uVar17;
  string asStack_58 [24];
  
  puVar11 = *(undefined8 **)(this + 0x40);
  if (puVar11 == (undefined8 *)0x0) {
    if (this[8] == (StyleSpecification)0x0) {
      pcVar13 = *(code **)(*(long *)this + 0x50);
      pSVar7 = this;
      goto LAB_101140cec;
    }
  }
  else {
    bVar3 = *(byte *)((long)puVar11 + 0x17);
    puVar1 = (undefined8 *)*puVar11;
    if (-1 < (char)bVar3) {
      puVar1 = puVar11;
    }
    uVar12 = puVar11[1];
    if (-1 < (char)bVar3) {
      uVar12 = (ulong)bVar3;
    }
    pSVar7 = (StyleSpecification *)
             GuiStyle::getStyle(*(undefined8 *)(_global + 0x260),puVar1,uVar12);
    if (pSVar7 == (StyleSpecification *)0x0) {
      uVar9 = (**(code **)(*(long *)this + 0x50))(this);
      (**(code **)(*(long *)param_1 + 0x10))(param_1,uVar9);
      pRVar10 = (RuntimeError *)___cxa_allocate_exception(0x10);
      getName(this);
      ssprintf("Style of type %s has parent element %s which does not exist",asStack_58);
      RuntimeError::RuntimeError(pRVar10,asStack_58);
                    /* WARNING: Subroutine does not return */
      ___cxa_throw(pRVar10,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
    }
    plVar8 = (long *)(**(code **)(*(long *)pSVar7 + 0x28))();
    if (plVar8 == (long *)0x0) {
                    /* WARNING: Subroutine does not return */
      ___cxa_bad_typeid();
    }
    uVar12 = *(ulong *)(*(long *)(*(long *)this + -8) + 8);
    uVar14 = *(ulong *)(*(long *)(*plVar8 + -8) + 8);
    if ((uVar12 != uVar14) &&
       ((-1 < (long)(uVar14 & uVar12) ||
        (iVar5 = _strcmp((char *)(uVar12 & 0x7fffffffffffffff),(char *)(uVar14 & 0x7fffffffffffffff)
                        ), iVar5 != 0)))) {
      pRVar10 = (RuntimeError *)___cxa_allocate_exception(0x10);
      getName(this);
      ssprintf("Style of type %s has parent element %s which has wrong type",asStack_58);
      RuntimeError::RuntimeError(pRVar10,asStack_58);
                    /* WARNING: Subroutine does not return */
      ___cxa_throw(pRVar10,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
    }
    pcVar13 = *(code **)(*(long *)pSVar7 + 0x20);
LAB_101140cec:
    uVar9 = (*pcVar13)(pSVar7);
    (**(code **)(*(long *)param_1 + 0x10))(param_1,uVar9);
  }
  psVar16 = *(string **)(this + 0x38);
  if (psVar16 != (string *)0x0) {
    this_00 = *(string **)(param_1 + 0x18);
    if (this_00 == (string *)0x0) {
      this_00 = operator_new(0x20);
      *(undefined8 *)(this_00 + 8) = 0;
      *(undefined8 *)this_00 = 0;
      *(undefined8 *)(this_00 + 0x18) = 0;
      *(undefined8 *)(this_00 + 0x10) = 0;
      *(string **)(param_1 + 0x18) = this_00;
    }
    std::string::operator=(this_00,psVar16);
  }
  if (this[0xb] != (StyleSpecification)0x0) {
    SVar2 = this[10];
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 1;
    *(StyleSpecification *)(param_1 + 0x26) = SVar2;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if (this[0xd] != (StyleSpecification)0x0) {
    SVar2 = this[0xc];
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 2;
    *(StyleSpecification *)(param_1 + 0x27) = SVar2;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if (this[0xf] != (StyleSpecification)0x0) {
    agui::Style::setIgnoredBySearch(param_1,(bool)this[0xe]);
  }
  if (this[0x11] != (StyleSpecification)0x0) {
    agui::Style::setNeverHiddenBySearch(param_1,(bool)this[0x10]);
  }
  if (*(undefined1 **)(this + 0x18) != (undefined1 *)0x0) {
    agui::Style::setHorizontallyStretchable(param_1,**(undefined1 **)(this + 0x18));
  }
  if (*(undefined1 **)(this + 0x20) != (undefined1 *)0x0) {
    agui::Style::setVerticallyStretchable(param_1,**(undefined1 **)(this + 0x20));
  }
  if (*(undefined1 **)(this + 0x28) != (undefined1 *)0x0) {
    agui::Style::setHorizontallySquashable(param_1,**(undefined1 **)(this + 0x28));
  }
  if (*(undefined1 **)(this + 0x30) != (undefined1 *)0x0) {
    agui::Style::setVerticallySquashable(param_1,**(undefined1 **)(this + 0x30));
  }
  if ((this[0x4c] != (StyleSpecification)0x0) &&
     ((param_2 == (OptionalFundamentalBase *)0x0 || (this + 0x48 == (StyleSpecification *)param_2)))
     ) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x48));
    agui::Style::setMinimalWidth(param_1,uVar6);
  }
  if ((this[0x54] != (StyleSpecification)0x0) &&
     ((param_2 == (OptionalFundamentalBase *)0x0 || (this + 0x50 == (StyleSpecification *)param_2)))
     ) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x50));
    agui::Style::setMaximalWidth(param_1,uVar6);
  }
  if ((this[0x5c] != (StyleSpecification)0x0) &&
     ((param_2 == (OptionalFundamentalBase *)0x0 || (this + 0x58 == (StyleSpecification *)param_2)))
     ) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x58));
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x4000;
    *(uint *)(param_1 + 0x30) = uVar6;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if ((this[100] != (StyleSpecification)0x0) &&
     ((param_2 == (OptionalFundamentalBase *)0x0 || (this + 0x60 == (StyleSpecification *)param_2)))
     ) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x60));
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x8000;
    *(uint *)(param_1 + 0x34) = uVar6;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if ((this[0x6c] != (StyleSpecification)0x0) &&
     ((param_2 == (OptionalFundamentalBase *)0x0 || (this + 0x68 == (StyleSpecification *)param_2)))
     ) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x68));
    agui::Style::setMinimalHeight(param_1,uVar6);
  }
  if ((this[0x74] != (StyleSpecification)0x0) &&
     ((param_2 == (OptionalFundamentalBase *)0x0 || (this + 0x70 == (StyleSpecification *)param_2)))
     ) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x70));
    agui::Style::setMaximalHeight(param_1,uVar6);
  }
  if (this[0x7a] != (StyleSpecification)0x0) {
    sVar4 = GuiConstants::getScaled<short>(*(short *)(this + 0x78));
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x40;
    *(short *)(param_1 + 0x40) = sVar4;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if (this[0x7e] != (StyleSpecification)0x0) {
    sVar4 = GuiConstants::getScaled<short>(*(short *)(this + 0x7c));
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x80;
    *(short *)(param_1 + 0x42) = sVar4;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if (this[0x82] != (StyleSpecification)0x0) {
    sVar4 = GuiConstants::getScaled<short>(*(short *)(this + 0x80));
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x100;
    *(short *)(param_1 + 0x44) = sVar4;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if (this[0x86] != (StyleSpecification)0x0) {
    sVar4 = GuiConstants::getScaled<short>(*(short *)(this + 0x84));
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x200;
    *(short *)(param_1 + 0x46) = sVar4;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if (this[0x8a] != (StyleSpecification)0x0) {
    sVar4 = GuiConstants::getScaled<short>(*(short *)(this + 0x88));
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x10000;
    *(short *)(param_1 + 0x48) = sVar4;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if (this[0x8e] != (StyleSpecification)0x0) {
    sVar4 = GuiConstants::getScaled<short>(*(short *)(this + 0x8c));
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x20000;
    *(short *)(param_1 + 0x4a) = sVar4;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if (this[0x92] != (StyleSpecification)0x0) {
    sVar4 = GuiConstants::getScaled<short>(*(short *)(this + 0x90));
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x40000;
    *(short *)(param_1 + 0x4c) = sVar4;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  if (this[0x96] != (StyleSpecification)0x0) {
    sVar4 = GuiConstants::getScaled<short>(*(short *)(this + 0x94));
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x80000;
    *(short *)(param_1 + 0x4e) = sVar4;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  psVar16 = *(string **)(this + 0x98);
  if (psVar16 != (string *)0x0) {
    uVar12 = *(ulong *)(psVar16 + 8);
    if (-1 < (char)psVar16[0x17]) {
      uVar12 = (ulong)(byte)psVar16[0x17];
    }
    if (uVar12 == 0) {
      *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x100000;
      *(undefined8 *)(param_1 + 0x50) = 0;
      plVar8 = *(long **)(param_1 + 0x10);
    }
    else {
      if (*(CustomGuiEffects **)(_global + 0x290) == (CustomGuiEffects *)0x0) goto LAB_101141140;
      uVar9 = CustomGuiEffects::getEffect(*(CustomGuiEffects **)(_global + 0x290),psVar16);
      *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x100000;
      *(undefined8 *)(param_1 + 0x50) = uVar9;
      plVar8 = *(long **)(param_1 + 0x10);
    }
    if (plVar8 != (long *)0x0) {
      (**(code **)(*plVar8 + 0x4b0))();
    }
  }
LAB_101141140:
  if (this[0xa4] != (StyleSpecification)0x0) {
    uVar17 = *(undefined4 *)(this + 0xa0);
    *(uint *)(param_1 + 0x20) = *(uint *)(param_1 + 0x20) | 0x200000;
    *(undefined4 *)(param_1 + 0x58) = uVar17;
    if (*(long **)(param_1 + 0x10) != (long *)0x0) {
      (**(code **)(**(long **)(param_1 + 0x10) + 0x4b0))();
    }
  }
  pLVar15 = *(LocaleProvider **)(this + 0xa8);
  if (pLVar15 != (LocaleProvider *)0x0) {
    ::LocalisedString::updateTranslationIfNeeded(pLVar15);
    agui::Style::setToolTip(param_1,(string *)(pLVar15 + 0x38));
    return;
  }
  return;
}



// ===== StyleWithClickableGraphicalSetSpecification::apply  @ 0x101149298 =====

/* StyleWithClickableGraphicalSetSpecification::apply(agui::StyleWithClickableGraphicalSet&,
   OptionalFundamentalBase*) const */

void __thiscall
StyleWithClickableGraphicalSetSpecification::apply
          (StyleWithClickableGraphicalSetSpecification *this,StyleWithClickableGraphicalSet *param_1
          ,OptionalFundamentalBase *param_2)

{
  ElementImageSet *pEVar1;
  void *pvVar2;
  ElementImageSet *pEVar3;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (*(undefined8 **)(this + 0xb8) != (undefined8 *)0x0) {
    pEVar3 = (ElementImageSet *)**(undefined8 **)(this + 0xb8);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar3);
    pEVar3 = *(ElementImageSet **)(param_1 + 0x70);
    *(ElementImageSet **)(param_1 + 0x70) = pEVar1;
    if (pEVar3 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar3);
      operator_delete(pvVar2);
    }
  }
  if (*(undefined8 **)(this + 0xc0) != (undefined8 *)0x0) {
    pEVar3 = (ElementImageSet *)**(undefined8 **)(this + 0xc0);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar3);
    pEVar3 = *(ElementImageSet **)(param_1 + 0x78);
    *(ElementImageSet **)(param_1 + 0x78) = pEVar1;
    if (pEVar3 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar3);
      operator_delete(pvVar2);
    }
  }
  if (*(undefined8 **)(this + 200) != (undefined8 *)0x0) {
    pEVar3 = (ElementImageSet *)**(undefined8 **)(this + 200);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar3);
    pEVar3 = *(ElementImageSet **)(param_1 + 0x80);
    *(ElementImageSet **)(param_1 + 0x80) = pEVar1;
    if (pEVar3 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar3);
      operator_delete(pvVar2);
    }
  }
  if (*(undefined8 **)(this + 0xd0) != (undefined8 *)0x0) {
    pEVar3 = (ElementImageSet *)**(undefined8 **)(this + 0xd0);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar3);
    pEVar3 = *(ElementImageSet **)(param_1 + 0x88);
    *(ElementImageSet **)(param_1 + 0x88) = pEVar1;
    if (pEVar3 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar3);
      operator_delete(pvVar2);
    }
  }
  if (*(undefined8 **)(this + 0xd8) != (undefined8 *)0x0) {
    pEVar3 = (ElementImageSet *)**(undefined8 **)(this + 0xd8);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar3);
    pEVar3 = *(ElementImageSet **)(param_1 + 0x90);
    *(ElementImageSet **)(param_1 + 0x90) = pEVar1;
    if (pEVar3 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar3);
      operator_delete(pvVar2);
    }
  }
  if (*(undefined8 **)(this + 0xe0) != (undefined8 *)0x0) {
    pEVar3 = (ElementImageSet *)**(undefined8 **)(this + 0xe0);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar3);
    pEVar3 = *(ElementImageSet **)(param_1 + 0x98);
    *(ElementImageSet **)(param_1 + 0x98) = pEVar1;
    if (pEVar3 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar3);
      operator_delete(pvVar2);
    }
  }
  if (*(undefined8 **)(this + 0xe8) != (undefined8 *)0x0) {
    pEVar3 = (ElementImageSet *)**(undefined8 **)(this + 0xe8);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar3);
    pEVar3 = *(ElementImageSet **)(param_1 + 0xa0);
    *(ElementImageSet **)(param_1 + 0xa0) = pEVar1;
    if (pEVar3 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar3);
      operator_delete(pvVar2);
    }
  }
  if (*(undefined8 **)(this + 0xf0) != (undefined8 *)0x0) {
    pEVar3 = (ElementImageSet *)**(undefined8 **)(this + 0xf0);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar3);
    pEVar3 = *(ElementImageSet **)(param_1 + 0xa8);
    *(ElementImageSet **)(param_1 + 0xa8) = pEVar1;
    if (pEVar3 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar3);
      operator_delete(pvVar2);
    }
  }
  if (this[0xf8] != (StyleWithClickableGraphicalSetSpecification)0x0) {
    *(StyleWithClickableGraphicalSetSpecification **)(param_1 + 0x68) = this + 0x100;
  }
  return;
}



// ===== GlowStyleSpecification::apply  @ 0x101154140 =====

/* GlowStyleSpecification::apply(GlowStyle&, OptionalFundamentalBase*) const */

void __thiscall
GlowStyleSpecification::apply
          (GlowStyleSpecification *this,GlowStyle *param_1,OptionalFundamentalBase *param_2)

{
  ElementImageSet *this_00;
  void *pvVar1;
  ElementImageSet *pEVar2;
  
  StyleSpecification::apply((StyleSpecification *)this,(Style *)param_1,param_2);
  if (*(undefined8 **)(this + 0xb8) != (undefined8 *)0x0) {
    pEVar2 = (ElementImageSet *)**(undefined8 **)(this + 0xb8);
    this_00 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(this_00,pEVar2);
    pEVar2 = *(ElementImageSet **)(param_1 + 0x68);
    *(ElementImageSet **)(param_1 + 0x68) = this_00;
    if (pEVar2 != (ElementImageSet *)0x0) {
      pvVar1 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar2);
      operator_delete(pvVar1);
      return;
    }
  }
  return;
}



// ===== GraphStyleSpecification::apply  @ 0x101155910 =====

/* GraphStyleSpecification::apply(agui::GraphStyle&) const */

void __thiscall GraphStyleSpecification::apply(GraphStyleSpecification *this,GraphStyle *param_1)

{
  undefined8 *puVar1;
  char cVar2;
  byte bVar3;
  ulong uVar4;
  undefined4 *puVar5;
  undefined4 uVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  code *pcVar10;
  uint uVar11;
  undefined8 *puVar12;
  void *pvVar13;
  undefined8 uVar14;
  float *pfVar15;
  undefined4 *puVar16;
  undefined4 *puVar17;
  ulong uVar18;
  undefined4 *puVar19;
  LabelStyleSpecification *pLVar20;
  LabelStyle *pLVar21;
  float *pfVar22;
  long *plVar23;
  long lVar24;
  double dVar25;
  undefined4 *local_b0;
  undefined4 *puStack_a8;
  undefined4 *local_a0;
  undefined4 local_90;
  undefined4 uStack_8c;
  undefined4 local_88;
  undefined4 uStack_84;
  
  StyleSpecification::apply
            ((StyleSpecification *)this,(Style *)param_1,(OptionalFundamentalBase *)0x0);
  pfVar15 = *(float **)(this + 0xb8);
  if (pfVar15 != (float *)0x0) {
    agui::Color::Color((Color *)&local_b0,*pfVar15,pfVar15[1],pfVar15[2],pfVar15[3]);
    puVar5 = puStack_a8;
    puVar19 = local_b0;
    puVar12 = operator_new(0x10);
    puVar12[1] = puVar5;
    *puVar12 = puVar19;
    pvVar13 = *(void **)(param_1 + 0x68);
    *(undefined8 **)(param_1 + 0x68) = puVar12;
    if (pvVar13 != (void *)0x0) {
      operator_delete(pvVar13);
    }
  }
  plVar23 = *(long **)(this + 0xc0);
  if (plVar23 != (long *)0x0) {
    puStack_a8 = (undefined4 *)0x0;
    local_a0 = (undefined4 *)0x0;
    local_b0 = (undefined4 *)0x0;
    pfVar15 = (float *)*plVar23;
    pfVar22 = (float *)plVar23[1];
    uVar4 = (long)pfVar22 - (long)pfVar15;
    puVar19 = puStack_a8;
    if (uVar4 != 0) {
      if ((long)uVar4 < 0) {
        std::vector<agui::Color,std::allocator<agui::Color>>::__throw_length_error_abi_v160006_();
LAB_101155e00:
                    /* WARNING: Does not return */
        pcVar10 = (code *)SoftwareBreakpoint(1,0x101155e04);
        (*pcVar10)();
      }
      puStack_a8 = operator_new(uVar4);
      local_a0 = puStack_a8 + ((long)uVar4 >> 4) * 4;
      pfVar15 = (float *)*plVar23;
      pfVar22 = (float *)plVar23[1];
      puVar19 = puStack_a8;
    }
    for (; local_b0 = puVar19, pfVar15 != pfVar22; pfVar15 = pfVar15 + 4) {
      agui::Color::Color((Color *)&local_90,*pfVar15,pfVar15[1],pfVar15[2],pfVar15[3]);
      uVar9 = uStack_84;
      uVar8 = local_88;
      uVar7 = uStack_8c;
      uVar6 = local_90;
      puVar19 = puStack_a8;
      puVar5 = local_b0;
      if (puStack_a8 < local_a0) {
        *puStack_a8 = local_90;
        puStack_a8[1] = uStack_8c;
        puStack_a8[2] = local_88;
        puStack_a8[3] = uStack_84;
        puStack_a8 = puStack_a8 + 4;
      }
      else {
        lVar24 = (long)puStack_a8 - (long)local_b0 >> 4;
        uVar4 = lVar24 + 1;
        if (uVar4 >> 0x3c != 0) {
          std::vector<agui::Color,std::allocator<agui::Color>>::__throw_length_error_abi_v160006_();
          goto LAB_101155e00;
        }
        uVar18 = (ulong)((long)local_a0 - (long)local_b0) >> 3;
        if (uVar18 <= uVar4) {
          uVar18 = uVar4;
        }
        if (0x7fffffffffffffef < (ulong)((long)local_a0 - (long)local_b0)) {
          uVar18 = 0xfffffffffffffff;
        }
        if (uVar18 == 0) {
          pvVar13 = (void *)0x0;
          puVar16 = (undefined4 *)(lVar24 * 0x10);
          *puVar16 = local_90;
          puVar16[1] = uStack_8c;
          puVar16[2] = local_88;
          puVar16[3] = uStack_84;
          puVar17 = puVar16;
          if (puStack_a8 == local_b0) goto LAB_101155a78;
LAB_101155aac:
          do {
            puVar12 = (undefined8 *)(puVar19 + -2);
            uVar14 = *(undefined8 *)(puVar19 + -4);
            puVar19 = puVar19 + -4;
            *(undefined8 *)(puVar17 + -2) = *puVar12;
            *(undefined8 *)(puVar17 + -4) = uVar14;
            puVar17 = puVar17 + -4;
          } while (puVar19 != puVar5);
          local_a0 = (undefined4 *)((long)pvVar13 + uVar18 * 0x10);
          puVar19 = local_b0;
        }
        else {
          if (uVar18 >> 0x3c != 0) {
                    /* WARNING: Subroutine does not return */
            std::__throw_bad_array_new_length_abi_v160006_();
          }
          pvVar13 = operator_new(uVar18 << 4);
          puVar16 = (undefined4 *)((long)pvVar13 + lVar24 * 0x10);
          *puVar16 = uVar6;
          puVar16[1] = uVar7;
          puVar16[2] = uVar8;
          puVar16[3] = uVar9;
          puVar17 = puVar16;
          if (puVar19 != puVar5) goto LAB_101155aac;
LAB_101155a78:
          local_a0 = (undefined4 *)((long)pvVar13 + uVar18 * 0x10);
          puVar17 = puVar16;
        }
        local_b0 = puVar17;
        puStack_a8 = puVar16 + 4;
        if (puVar19 != (undefined4 *)0x0) {
          operator_delete(puVar19);
        }
      }
      puVar19 = local_b0;
    }
    agui::GraphStyle::setLineColors(param_1,(vector *)&local_b0);
    if (local_b0 != (undefined4 *)0x0) {
      puStack_a8 = local_b0;
      operator_delete(local_b0);
    }
  }
  pLVar20 = *(LabelStyleSpecification **)(this + 0x120);
  if (pLVar20 != (LabelStyleSpecification *)0x0) {
    pLVar21 = *(LabelStyle **)(param_1 + 0xd0);
    if (pLVar21 == (LabelStyle *)0x0) {
      pLVar21 = operator_new(200);
      agui::LabelStyle::LabelStyle(pLVar21,(LabelStyle *)0x0);
      plVar23 = *(long **)(param_1 + 0xd0);
      *(LabelStyle **)(param_1 + 0xd0) = pLVar21;
      if (plVar23 != (long *)0x0) {
        (**(code **)(*plVar23 + 8))();
        pLVar21 = *(LabelStyle **)(param_1 + 0xd0);
      }
    }
    LabelStyleSpecification::apply(pLVar20,pLVar21,(OptionalFundamentalBase *)0x0);
  }
  pLVar20 = *(LabelStyleSpecification **)(this + 0x128);
  if (pLVar20 != (LabelStyleSpecification *)0x0) {
    pLVar21 = *(LabelStyle **)(param_1 + 0xd8);
    if (pLVar21 == (LabelStyle *)0x0) {
      pLVar21 = operator_new(200);
      agui::LabelStyle::LabelStyle(pLVar21,(LabelStyle *)0x0);
      plVar23 = *(long **)(param_1 + 0xd8);
      *(LabelStyle **)(param_1 + 0xd8) = pLVar21;
      if (plVar23 != (long *)0x0) {
        (**(code **)(*plVar23 + 8))();
        pLVar21 = *(LabelStyle **)(param_1 + 0xd8);
      }
    }
    LabelStyleSpecification::apply(pLVar20,pLVar21,(OptionalFundamentalBase *)0x0);
  }
  if (this[0xd0] != (GraphStyleSpecification)0x0) {
    lVar24 = *(long *)(_global + 0x218);
    if (lVar24 == 0) {
      dVar25 = 1.0;
    }
    else {
      dVar25 = *(double *)(lVar24 + 0x20b0);
      if (dVar25 == 0.0) {
        cVar2 = *(char *)(lVar24 + 0x158);
        if (cVar2 == '\x02') {
          dVar25 = (double)(long)(*(double *)(lVar24 + 0x2a0) * *(double *)(lVar24 + 0x20c0) * 4.0)
                   * 0.25;
        }
        else if (cVar2 == '\x01') {
          dVar25 = *(double *)(lVar24 + 0x1f8);
        }
        else {
          if (cVar2 != '\0') {
                    /* WARNING: Subroutine does not return */
            Logging::logEnumAndAbortOrThrow<UIScaleMode::Enum>
                      ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/InterfaceSettings.cpp"
                       ,0x133,9);
          }
          dVar25 = *(double *)(lVar24 + 0x20b8);
        }
      }
    }
    *(double *)(param_1 + 0x78) = *(double *)(this + 200) * dVar25;
    param_1[0x80] = (GraphStyle)0x1;
  }
  if (this[0xdc] != (GraphStyleSpecification)0x0) {
    uVar11 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xd8));
    *(uint *)(param_1 + 0x88) = uVar11;
    param_1[0x8c] = (GraphStyle)0x1;
  }
  if (this[0xe4] != (GraphStyleSpecification)0x0) {
    uVar11 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xe0));
    *(uint *)(param_1 + 0x90) = uVar11;
    param_1[0x94] = (GraphStyle)0x1;
  }
  if (this[0xec] != (GraphStyleSpecification)0x0) {
    uVar11 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xe8));
    *(uint *)(param_1 + 0x98) = uVar11;
    param_1[0x9c] = (GraphStyle)0x1;
  }
  if (this[0xf4] != (GraphStyleSpecification)0x0) {
    uVar11 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xf0));
    *(uint *)(param_1 + 0xa0) = uVar11;
    param_1[0xa4] = (GraphStyle)0x1;
  }
  if (this[0xfc] != (GraphStyleSpecification)0x0) {
    uVar11 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0xf8));
    *(uint *)(param_1 + 0xa8) = uVar11;
    param_1[0xac] = (GraphStyle)0x1;
  }
  if (this[0x104] != (GraphStyleSpecification)0x0) {
    uVar11 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x100));
    *(uint *)(param_1 + 0xb0) = uVar11;
    param_1[0xb4] = (GraphStyle)0x1;
  }
  if (this[0x10c] != (GraphStyleSpecification)0x0) {
    uVar11 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x108));
    *(uint *)(param_1 + 0xb8) = uVar11;
    param_1[0xbc] = (GraphStyle)0x1;
  }
  pfVar15 = *(float **)(this + 0x110);
  if (pfVar15 != (float *)0x0) {
    agui::Color::Color((Color *)&local_b0,*pfVar15,pfVar15[1],pfVar15[2],pfVar15[3]);
    puVar5 = puStack_a8;
    puVar19 = local_b0;
    puVar12 = operator_new(0x10);
    puVar12[1] = puVar5;
    *puVar12 = puVar19;
    pvVar13 = *(void **)(param_1 + 0xc0);
    *(undefined8 **)(param_1 + 0xc0) = puVar12;
    if (pvVar13 != (void *)0x0) {
      operator_delete(pvVar13);
    }
  }
  pfVar15 = *(float **)(this + 0x118);
  if (pfVar15 != (float *)0x0) {
    agui::Color::Color((Color *)&local_b0,*pfVar15,pfVar15[1],pfVar15[2],pfVar15[3]);
    puVar5 = puStack_a8;
    puVar19 = local_b0;
    puVar12 = operator_new(0x10);
    puVar12[1] = puVar5;
    *puVar12 = puVar19;
    pvVar13 = *(void **)(param_1 + 200);
    *(undefined8 **)(param_1 + 200) = puVar12;
    if (pvVar13 != (void *)0x0) {
      operator_delete(pvVar13);
    }
  }
  puVar12 = *(undefined8 **)(this + 0x130);
  if (puVar12 != (undefined8 *)0x0) {
    bVar3 = *(byte *)((long)puVar12 + 0x17);
    puVar1 = (undefined8 *)*puVar12;
    if (-1 < (char)bVar3) {
      puVar1 = puVar12;
    }
    uVar4 = puVar12[1];
    if (-1 < (char)bVar3) {
      uVar4 = (ulong)bVar3;
    }
    uVar14 = FontBank::getFont(*(undefined8 *)(_global + 0x270),puVar1,uVar4,0);
    *(undefined8 *)(param_1 + 0xe0) = uVar14;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  return;
}



// ===== ScrollBarStyleSpecification::apply  @ 0x10115d2b8 =====

/* ScrollBarStyleSpecification::apply(agui::ScrollBarStyle&) const */

void __thiscall
ScrollBarStyleSpecification::apply(ScrollBarStyleSpecification *this,ScrollBarStyle *param_1)

{
  ElementImageSet *this_00;
  void *pvVar1;
  long *plVar2;
  undefined8 *puVar3;
  long lVar4;
  ButtonStyle *this_01;
  ElementImageSet *pEVar5;
  
  StyleSpecification::apply
            ((StyleSpecification *)this,(Style *)param_1,(OptionalFundamentalBase *)0x0);
  lVar4 = *(long *)(this + 0xb8);
  if (lVar4 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar4 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar4 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar4 + 0xd58));
    pEVar5 = (ElementImageSet *)**(undefined8 **)(this + 0xb8);
    this_00 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(this_00,pEVar5);
    pEVar5 = *(ElementImageSet **)(param_1 + 0x70);
    *(ElementImageSet **)(param_1 + 0x70) = this_00;
    if (pEVar5 != (ElementImageSet *)0x0) {
      pvVar1 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar5);
      operator_delete(pvVar1);
    }
  }
  if (*(long *)(this + 0xc0) != 0) {
    this_01 = *(ButtonStyle **)(param_1 + 0x68);
    if (this_01 == (ButtonStyle *)0x0) {
      this_01 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(this_01,(ButtonStyle *)0x0);
      plVar2 = *(long **)(param_1 + 0x68);
      *(ButtonStyle **)(param_1 + 0x68) = this_01;
      if (plVar2 != (long *)0x0) {
        (**(code **)(*plVar2 + 8))();
        this_01 = *(ButtonStyle **)(param_1 + 0x68);
      }
    }
    ButtonStyleSpecification::apply
              (*(ButtonStyleSpecification **)(this + 0xc0),this_01,(OptionalFundamentalBase *)0x0);
    puVar3 = *(undefined8 **)(this_01 + 0x18);
    if (puVar3 == (undefined8 *)0x0) {
      puVar3 = operator_new(0x20);
      puVar3[1] = 0;
      *puVar3 = 0;
      puVar3[3] = 0;
      puVar3[2] = 0;
      *(undefined8 **)(this_01 + 0x18) = puVar3;
    }
    puVar3[3] = param_1;
  }
  return;
}



// ===== DoubleSliderStyleSpecification::apply  @ 0x101162338 =====

/* DoubleSliderStyleSpecification::apply(agui::DoubleSliderStyle&, OptionalFundamentalBase*) */

void DoubleSliderStyleSpecification::apply
               (DoubleSliderStyle *param_1,OptionalFundamentalBase *param_2)

{
  ElementImageSet *pEVar1;
  void *pvVar2;
  long *plVar3;
  undefined8 *puVar4;
  OptionalFundamentalBase *in_x2;
  long lVar5;
  ButtonStyle *pBVar6;
  ElementImageSet *pEVar7;
  
  StyleSpecification::apply((StyleSpecification *)param_1,(Style *)param_2,in_x2);
  lVar5 = *(long *)(param_1 + 0xb8);
  if (lVar5 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0xd58));
    pEVar7 = (ElementImageSet *)**(undefined8 **)(param_1 + 0xb8);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar7);
    pEVar7 = *(ElementImageSet **)(param_2 + 0x68);
    *(ElementImageSet **)(param_2 + 0x68) = pEVar1;
    if (pEVar7 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar7);
      operator_delete(pvVar2);
    }
  }
  lVar5 = *(long *)(param_1 + 0xc0);
  if (lVar5 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0xd58));
    pEVar7 = (ElementImageSet *)**(undefined8 **)(param_1 + 0xc0);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar7);
    pEVar7 = *(ElementImageSet **)(param_2 + 0x70);
    *(ElementImageSet **)(param_2 + 0x70) = pEVar1;
    if (pEVar7 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar7);
      operator_delete(pvVar2);
    }
  }
  lVar5 = *(long *)(param_1 + 200);
  if (lVar5 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0xd58));
    pEVar7 = (ElementImageSet *)**(undefined8 **)(param_1 + 200);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar7);
    pEVar7 = *(ElementImageSet **)(param_2 + 0x78);
    *(ElementImageSet **)(param_2 + 0x78) = pEVar1;
    if (pEVar7 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar7);
      operator_delete(pvVar2);
    }
  }
  lVar5 = *(long *)(param_1 + 0xd0);
  if (lVar5 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0xd58));
    pEVar7 = (ElementImageSet *)**(undefined8 **)(param_1 + 0xd0);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar7);
    pEVar7 = *(ElementImageSet **)(param_2 + 0x80);
    *(ElementImageSet **)(param_2 + 0x80) = pEVar1;
    if (pEVar7 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar7);
      operator_delete(pvVar2);
    }
  }
  if (param_1[0xd9] != (DoubleSliderStyle)0x0) {
    *(ushort *)(param_2 + 0x88) = (byte)param_1[0xd8] | 0x100;
  }
  lVar5 = *(long *)(param_1 + 0xe0);
  if (lVar5 != 0) {
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 8));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0x6b0));
    ElementImageSet::Layer::preApply((Layer *)(lVar5 + 0xd58));
    pEVar7 = (ElementImageSet *)**(undefined8 **)(param_1 + 0xe0);
    pEVar1 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar1,pEVar7);
    pEVar7 = *(ElementImageSet **)(param_2 + 0x90);
    *(ElementImageSet **)(param_2 + 0x90) = pEVar1;
    if (pEVar7 != (ElementImageSet *)0x0) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar7);
      operator_delete(pvVar2);
    }
  }
  if (*(long *)(param_1 + 0xe8) != 0) {
    pBVar6 = *(ButtonStyle **)(param_2 + 0x98);
    if (pBVar6 == (ButtonStyle *)0x0) {
      pBVar6 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(pBVar6,(ButtonStyle *)0x0);
      plVar3 = *(long **)(param_2 + 0x98);
      *(ButtonStyle **)(param_2 + 0x98) = pBVar6;
      if (plVar3 != (long *)0x0) {
        (**(code **)(*plVar3 + 8))();
        pBVar6 = *(ButtonStyle **)(param_2 + 0x98);
      }
    }
    ButtonStyleSpecification::apply
              (*(ButtonStyleSpecification **)(param_1 + 0xe8),pBVar6,(OptionalFundamentalBase *)0x0)
    ;
    puVar4 = *(undefined8 **)(pBVar6 + 0x18);
    if (puVar4 == (undefined8 *)0x0) {
      puVar4 = operator_new(0x20);
      puVar4[1] = 0;
      *puVar4 = 0;
      puVar4[3] = 0;
      puVar4[2] = 0;
      *(undefined8 **)(pBVar6 + 0x18) = puVar4;
    }
    puVar4[3] = param_2;
  }
  if (*(long *)(param_1 + 0xf0) != 0) {
    pBVar6 = *(ButtonStyle **)(param_2 + 0xa0);
    if (pBVar6 == (ButtonStyle *)0x0) {
      pBVar6 = operator_new(0x118);
      agui::ButtonStyle::ButtonStyle(pBVar6,(ButtonStyle *)0x0);
      plVar3 = *(long **)(param_2 + 0xa0);
      *(ButtonStyle **)(param_2 + 0xa0) = pBVar6;
      if (plVar3 != (long *)0x0) {
        (**(code **)(*plVar3 + 8))();
        pBVar6 = *(ButtonStyle **)(param_2 + 0xa0);
      }
    }
    ButtonStyleSpecification::apply
              (*(ButtonStyleSpecification **)(param_1 + 0xf0),pBVar6,(OptionalFundamentalBase *)0x0)
    ;
    puVar4 = *(undefined8 **)(pBVar6 + 0x18);
    if (puVar4 == (undefined8 *)0x0) {
      puVar4 = operator_new(0x20);
      puVar4[1] = 0;
      *puVar4 = 0;
      puVar4[3] = 0;
      puVar4[2] = 0;
      *(undefined8 **)(pBVar6 + 0x18) = puVar4;
    }
    puVar4[3] = param_2;
  }
  return;
}



// ===== TechnologySlotStyleSpecification::apply  @ 0x101172300 =====

/* TechnologySlotStyleSpecification::apply(TechnologySlotStyle&, OptionalFundamentalBase*) const */

void __thiscall
TechnologySlotStyleSpecification::apply
          (TechnologySlotStyleSpecification *this,TechnologySlotStyle *param_1,
          OptionalFundamentalBase *param_2)

{
  TechnologySlotStyleSpecification *pTVar1;
  ulong uVar2;
  TechnologySlotStyleSpecification TVar3;
  undefined8 uVar4;
  int iVar5;
  uint uVar6;
  ElementImageSet *pEVar7;
  void *pvVar8;
  undefined8 uVar9;
  undefined8 *puVar10;
  long *plVar11;
  EmptyWidgetStyleSpecification *this_00;
  EmptyWidgetStyle *this_01;
  ElementImageSet *pEVar12;
  undefined8 local_40;
  undefined8 uStack_38;
  
  ButtonStyleSpecification::apply((ButtonStyleSpecification *)this,(ButtonStyle *)param_1,param_2);
  if (*(undefined8 **)(this + 0x178) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x178);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x118);
    *(ElementImageSet **)(param_1 + 0x118) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x180) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x180);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x120);
    *(ElementImageSet **)(param_1 + 0x120) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x188) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x188);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x128);
    *(ElementImageSet **)(param_1 + 0x128) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 400) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 400);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x130);
    *(ElementImageSet **)(param_1 + 0x130) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (this[0x19c] != (TechnologySlotStyleSpecification)0x0) {
    iVar5 = GuiConstants::getScaled<int>(*(int *)(this + 0x198));
    *(int *)(param_1 + 0x138) = iVar5;
    param_1[0x13c] = (TechnologySlotStyle)0x1;
  }
  if (this[0x1a4] != (TechnologySlotStyleSpecification)0x0) {
    iVar5 = GuiConstants::getScaled<int>(*(int *)(this + 0x1a0));
    *(int *)(param_1 + 0x140) = iVar5;
    param_1[0x144] = (TechnologySlotStyle)0x1;
  }
  if (this[0x1ac] != (TechnologySlotStyleSpecification)0x0) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x1a8));
    if (param_1[0x14c] == (TechnologySlotStyle)0x0) {
      param_1[0x14c] = (TechnologySlotStyle)0x1;
    }
    *(uint *)(param_1 + 0x148) = uVar6;
  }
  if (this[0x1b4] != (TechnologySlotStyleSpecification)0x0) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x1b0));
    if (param_1[0x154] == (TechnologySlotStyle)0x0) {
      param_1[0x154] = (TechnologySlotStyle)0x1;
    }
    *(uint *)(param_1 + 0x150) = uVar6;
  }
  if (this[0x1d0] != (TechnologySlotStyleSpecification)0x0) {
    TVar3 = this[0x1cf];
    pTVar1 = *(TechnologySlotStyleSpecification **)(this + 0x1b8);
    if (-1 < (char)TVar3) {
      pTVar1 = this + 0x1b8;
    }
    uVar2 = *(ulong *)(this + 0x1c0);
    if (-1 < (char)TVar3) {
      uVar2 = (ulong)(byte)TVar3;
    }
    uVar9 = FontBank::getFont(*(undefined8 *)(_global + 0x270),pTVar1,uVar2,0);
    *(undefined8 *)(param_1 + 0x158) = uVar9;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  if (this[0x1f0] != (TechnologySlotStyleSpecification)0x0) {
    TVar3 = this[0x1ef];
    pTVar1 = *(TechnologySlotStyleSpecification **)(this + 0x1d8);
    if (-1 < (char)TVar3) {
      pTVar1 = this + 0x1d8;
    }
    uVar2 = *(ulong *)(this + 0x1e0);
    if (-1 < (char)TVar3) {
      uVar2 = (ulong)(byte)TVar3;
    }
    uVar9 = FontBank::getFont(*(undefined8 *)(_global + 0x270),pTVar1,uVar2,0);
    *(undefined8 *)(param_1 + 0x160) = uVar9;
    if (*(Widget **)(param_1 + 0x10) != (Widget *)0x0) {
      agui::Widget::triggerResize(*(Widget **)(param_1 + 0x10));
    }
  }
  if (this[0x208] != (TechnologySlotStyleSpecification)0x0) {
    agui::Color::Color((Color *)&local_40,*(float *)(this + 0x1f8),*(float *)(this + 0x1fc),
                       *(float *)(this + 0x200),*(float *)(this + 0x204));
    uVar4 = uStack_38;
    uVar9 = local_40;
    puVar10 = operator_new(0x10);
    puVar10[1] = uVar4;
    *puVar10 = uVar9;
    pvVar8 = *(void **)(param_1 + 0x168);
    *(undefined8 **)(param_1 + 0x168) = puVar10;
    if (pvVar8 != (void *)0x0) {
      operator_delete(pvVar8);
    }
  }
  if (this[0x21c] != (TechnologySlotStyleSpecification)0x0) {
    agui::Color::Color((Color *)&local_40,*(float *)(this + 0x20c),*(float *)(this + 0x210),
                       *(float *)(this + 0x214),*(float *)(this + 0x218));
    uVar4 = uStack_38;
    uVar9 = local_40;
    puVar10 = operator_new(0x10);
    puVar10[1] = uVar4;
    *puVar10 = uVar9;
    pvVar8 = *(void **)(param_1 + 0x170);
    *(undefined8 **)(param_1 + 0x170) = puVar10;
    if (pvVar8 != (void *)0x0) {
      operator_delete(pvVar8);
    }
  }
  if (this[0x230] != (TechnologySlotStyleSpecification)0x0) {
    agui::Color::Color((Color *)&local_40,*(float *)(this + 0x220),*(float *)(this + 0x224),
                       *(float *)(this + 0x228),*(float *)(this + 0x22c));
    uVar4 = uStack_38;
    uVar9 = local_40;
    puVar10 = operator_new(0x10);
    puVar10[1] = uVar4;
    *puVar10 = uVar9;
    pvVar8 = *(void **)(param_1 + 0x178);
    *(undefined8 **)(param_1 + 0x178) = puVar10;
    if (pvVar8 != (void *)0x0) {
      operator_delete(pvVar8);
    }
  }
  if (this[0x244] != (TechnologySlotStyleSpecification)0x0) {
    agui::Color::Color((Color *)&local_40,*(float *)(this + 0x234),*(float *)(this + 0x238),
                       *(float *)(this + 0x23c),*(float *)(this + 0x240));
    uVar4 = uStack_38;
    uVar9 = local_40;
    puVar10 = operator_new(0x10);
    puVar10[1] = uVar4;
    *puVar10 = uVar9;
    pvVar8 = *(void **)(param_1 + 0x180);
    *(undefined8 **)(param_1 + 0x180) = puVar10;
    if (pvVar8 != (void *)0x0) {
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x248) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x248);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x188);
    *(ElementImageSet **)(param_1 + 0x188) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x250) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x250);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 400);
    *(ElementImageSet **)(param_1 + 400) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (this[0x25c] != (TechnologySlotStyleSpecification)0x0) {
    iVar5 = GuiConstants::getScaled<int>(*(int *)(this + 600));
    *(int *)(param_1 + 0x198) = iVar5;
    param_1[0x19c] = (TechnologySlotStyle)0x1;
  }
  if (this[0x264] != (TechnologySlotStyleSpecification)0x0) {
    iVar5 = GuiConstants::getScaled<int>(*(int *)(this + 0x260));
    *(int *)(param_1 + 0x1a0) = iVar5;
    param_1[0x1a4] = (TechnologySlotStyle)0x1;
  }
  if (this[0x26c] != (TechnologySlotStyleSpecification)0x0) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x268));
    if (param_1[0x1ac] == (TechnologySlotStyle)0x0) {
      param_1[0x1ac] = (TechnologySlotStyle)0x1;
    }
    *(uint *)(param_1 + 0x1a8) = uVar6;
  }
  if (*(undefined8 **)(this + 0x270) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x270);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x1b0);
    *(ElementImageSet **)(param_1 + 0x1b0) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x278) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x278);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x1b8);
    *(ElementImageSet **)(param_1 + 0x1b8) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x280) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x280);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x1c0);
    *(ElementImageSet **)(param_1 + 0x1c0) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x288) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x288);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x1c8);
    *(ElementImageSet **)(param_1 + 0x1c8) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x290) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x290);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x1d0);
    *(ElementImageSet **)(param_1 + 0x1d0) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (this[0x29c] != (TechnologySlotStyleSpecification)0x0) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x298));
    if (param_1[0x1dc] == (TechnologySlotStyle)0x0) {
      param_1[0x1dc] = (TechnologySlotStyle)0x1;
    }
    *(uint *)(param_1 + 0x1d8) = uVar6;
  }
  if (this[0x2a4] != (TechnologySlotStyleSpecification)0x0) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x2a0));
    if (param_1[0x1e4] == (TechnologySlotStyle)0x0) {
      param_1[0x1e4] = (TechnologySlotStyle)0x1;
    }
    *(uint *)(param_1 + 0x1e0) = uVar6;
  }
  if (this[0x2ac] != (TechnologySlotStyleSpecification)0x0) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x2a8));
    if (param_1[0x1ec] == (TechnologySlotStyle)0x0) {
      param_1[0x1ec] = (TechnologySlotStyle)0x1;
    }
    *(uint *)(param_1 + 0x1e8) = uVar6;
  }
  if (*(undefined8 **)(this + 0x2b0) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x2b0);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x1f0);
    *(ElementImageSet **)(param_1 + 0x1f0) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x2b8) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x2b8);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x1f8);
    *(ElementImageSet **)(param_1 + 0x1f8) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x2c0) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x2c0);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x200);
    *(ElementImageSet **)(param_1 + 0x200) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (*(undefined8 **)(this + 0x2c8) != (undefined8 *)0x0) {
    pEVar12 = (ElementImageSet *)**(undefined8 **)(this + 0x2c8);
    pEVar7 = operator_new(600);
    agui::ElementImageSet::ElementImageSet(pEVar7,pEVar12);
    pEVar12 = *(ElementImageSet **)(param_1 + 0x208);
    *(ElementImageSet **)(param_1 + 0x208) = pEVar7;
    if (pEVar12 != (ElementImageSet *)0x0) {
      pvVar8 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar12);
      operator_delete(pvVar8);
    }
  }
  if (this[0x2d4] != (TechnologySlotStyleSpecification)0x0) {
    uVar6 = GuiConstants::getScaled<unsigned_int>(*(uint *)(this + 0x2d0));
    *(uint *)(param_1 + 0x210) = uVar6;
    param_1[0x214] = (TechnologySlotStyle)0x1;
  }
  if (this[0x2e8] != (TechnologySlotStyleSpecification)0x0) {
    agui::Color::Color((Color *)&local_40,*(float *)(this + 0x2d8),*(float *)(this + 0x2dc),
                       *(float *)(this + 0x2e0),*(float *)(this + 0x2e4));
    puVar10 = operator_new(0x10);
    puVar10[1] = uStack_38;
    *puVar10 = local_40;
    pvVar8 = *(void **)(param_1 + 0x218);
    *(undefined8 **)(param_1 + 0x218) = puVar10;
    if (pvVar8 != (void *)0x0) {
      operator_delete(pvVar8);
    }
  }
  this_00 = *(EmptyWidgetStyleSpecification **)(this + 0x2f0);
  if (this_00 != (EmptyWidgetStyleSpecification *)0x0) {
    this_01 = *(EmptyWidgetStyle **)(param_1 + 0x220);
    if (this_01 == (EmptyWidgetStyle *)0x0) {
      this_01 = operator_new(0x70);
      agui::EmptyWidgetStyle::EmptyWidgetStyle(this_01,(EmptyWidgetStyle *)0x0);
      plVar11 = *(long **)(param_1 + 0x220);
      *(EmptyWidgetStyle **)(param_1 + 0x220) = this_01;
      if (plVar11 != (long *)0x0) {
        (**(code **)(*plVar11 + 8))();
        this_01 = *(EmptyWidgetStyle **)(param_1 + 0x220);
      }
    }
    EmptyWidgetStyleSpecification::apply(this_00,this_01,(OptionalFundamentalBase *)0x0);
  }
  return;
}



// ===== IDWithQuality<ID<ItemPrototype,unsigned_short>>::apply  @ 0x101205958 =====

/* IDWithQuality<ID<ItemPrototype, unsigned short> >::apply(IDWithQualityBackup&) */

void __thiscall
IDWithQuality<ID<ItemPrototype,unsigned_short>>::apply
          (IDWithQuality<ID<ItemPrototype,unsigned_short>> *this,IDWithQualityBackup *param_1)

{
  ulong uVar1;
  IDWithQualityBackup *pIVar2;
  IDWithQualityBackup IVar3;
  IDWithQuality<ID<ItemPrototype,unsigned_short>> IVar4;
  short sVar5;
  
  IVar3 = param_1[0x17];
  uVar1 = *(ulong *)(param_1 + 8);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)param_1;
    if (-1 < (char)IVar3) {
      pIVar2 = param_1;
    }
    sVar5 = PrototypeList<ItemPrototype>::parseSafe(pIVar2);
    if (sVar5 != 0) {
      *(short *)this = sVar5;
      if ((char)param_1[0x17] < '\0') {
        **(undefined1 **)param_1 = 0;
        *(undefined8 *)(param_1 + 8) = 0;
        IVar3 = param_1[0x2f];
        uVar1 = *(ulong *)(param_1 + 0x20);
        if (-1 < (char)IVar3) {
          uVar1 = (ulong)(byte)IVar3;
        }
        goto joined_r0x0001012059c4;
      }
      *param_1 = (IDWithQualityBackup)0x0;
      param_1[0x17] = (IDWithQualityBackup)0x0;
    }
  }
  IVar3 = param_1[0x2f];
  uVar1 = *(ulong *)(param_1 + 0x20);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
joined_r0x0001012059c4:
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)(param_1 + 0x18);
    if (-1 < (char)IVar3) {
      pIVar2 = param_1 + 0x18;
    }
    IVar4 = (IDWithQuality<ID<ItemPrototype,unsigned_short>>)
            PrototypeList<QualityPrototype>::parseSafe(pIVar2);
    if (IVar4 != (IDWithQuality<ID<ItemPrototype,unsigned_short>>)0x0) {
      this[2] = IVar4;
      if ((char)param_1[0x2f] < '\0') {
        **(undefined1 **)(param_1 + 0x18) = 0;
        *(undefined8 *)(param_1 + 0x20) = 0;
        return;
      }
      param_1[0x18] = (IDWithQualityBackup)0x0;
      param_1[0x2f] = (IDWithQualityBackup)0x0;
    }
  }
  return;
}



// ===== IDWithQuality<ID<EntityPrototype,unsigned_short>>::apply  @ 0x101206b8c =====

/* IDWithQuality<ID<EntityPrototype, unsigned short> >::apply(IDWithQualityBackup&) */

void __thiscall
IDWithQuality<ID<EntityPrototype,unsigned_short>>::apply
          (IDWithQuality<ID<EntityPrototype,unsigned_short>> *this,IDWithQualityBackup *param_1)

{
  ulong uVar1;
  IDWithQualityBackup *pIVar2;
  IDWithQualityBackup IVar3;
  IDWithQuality<ID<EntityPrototype,unsigned_short>> IVar4;
  short sVar5;
  
  IVar3 = param_1[0x17];
  uVar1 = *(ulong *)(param_1 + 8);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)param_1;
    if (-1 < (char)IVar3) {
      pIVar2 = param_1;
    }
    sVar5 = PrototypeList<EntityPrototype>::parseSafe(pIVar2);
    if (sVar5 != 0) {
      *(short *)this = sVar5;
      if ((char)param_1[0x17] < '\0') {
        **(undefined1 **)param_1 = 0;
        *(undefined8 *)(param_1 + 8) = 0;
        IVar3 = param_1[0x2f];
        uVar1 = *(ulong *)(param_1 + 0x20);
        if (-1 < (char)IVar3) {
          uVar1 = (ulong)(byte)IVar3;
        }
        goto joined_r0x000101206bf8;
      }
      *param_1 = (IDWithQualityBackup)0x0;
      param_1[0x17] = (IDWithQualityBackup)0x0;
    }
  }
  IVar3 = param_1[0x2f];
  uVar1 = *(ulong *)(param_1 + 0x20);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
joined_r0x000101206bf8:
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)(param_1 + 0x18);
    if (-1 < (char)IVar3) {
      pIVar2 = param_1 + 0x18;
    }
    IVar4 = (IDWithQuality<ID<EntityPrototype,unsigned_short>>)
            PrototypeList<QualityPrototype>::parseSafe(pIVar2);
    if (IVar4 != (IDWithQuality<ID<EntityPrototype,unsigned_short>>)0x0) {
      this[2] = IVar4;
      if ((char)param_1[0x2f] < '\0') {
        **(undefined1 **)(param_1 + 0x18) = 0;
        *(undefined8 *)(param_1 + 0x20) = 0;
        return;
      }
      param_1[0x18] = (IDWithQualityBackup)0x0;
      param_1[0x2f] = (IDWithQualityBackup)0x0;
    }
  }
  return;
}



// ===== IDWithQuality<ID<EquipmentPrototype,unsigned_short>>::apply  @ 0x101207dc8 =====

/* IDWithQuality<ID<EquipmentPrototype, unsigned short> >::apply(IDWithQualityBackup&) */

void __thiscall
IDWithQuality<ID<EquipmentPrototype,unsigned_short>>::apply
          (IDWithQuality<ID<EquipmentPrototype,unsigned_short>> *this,IDWithQualityBackup *param_1)

{
  ulong uVar1;
  IDWithQualityBackup *pIVar2;
  IDWithQualityBackup IVar3;
  IDWithQuality<ID<EquipmentPrototype,unsigned_short>> IVar4;
  short sVar5;
  
  IVar3 = param_1[0x17];
  uVar1 = *(ulong *)(param_1 + 8);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)param_1;
    if (-1 < (char)IVar3) {
      pIVar2 = param_1;
    }
    sVar5 = PrototypeList<EquipmentPrototype>::parseSafe(pIVar2);
    if (sVar5 != 0) {
      *(short *)this = sVar5;
      if ((char)param_1[0x17] < '\0') {
        **(undefined1 **)param_1 = 0;
        *(undefined8 *)(param_1 + 8) = 0;
        IVar3 = param_1[0x2f];
        uVar1 = *(ulong *)(param_1 + 0x20);
        if (-1 < (char)IVar3) {
          uVar1 = (ulong)(byte)IVar3;
        }
        goto joined_r0x000101207e34;
      }
      *param_1 = (IDWithQualityBackup)0x0;
      param_1[0x17] = (IDWithQualityBackup)0x0;
    }
  }
  IVar3 = param_1[0x2f];
  uVar1 = *(ulong *)(param_1 + 0x20);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
joined_r0x000101207e34:
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)(param_1 + 0x18);
    if (-1 < (char)IVar3) {
      pIVar2 = param_1 + 0x18;
    }
    IVar4 = (IDWithQuality<ID<EquipmentPrototype,unsigned_short>>)
            PrototypeList<QualityPrototype>::parseSafe(pIVar2);
    if (IVar4 != (IDWithQuality<ID<EquipmentPrototype,unsigned_short>>)0x0) {
      this[2] = IVar4;
      if ((char)param_1[0x2f] < '\0') {
        **(undefined1 **)(param_1 + 0x18) = 0;
        *(undefined8 *)(param_1 + 0x20) = 0;
        return;
      }
      param_1[0x18] = (IDWithQualityBackup)0x0;
      param_1[0x2f] = (IDWithQualityBackup)0x0;
    }
  }
  return;
}



// ===== IDWithQuality<ID<EquipmentGridPrototype,unsigned_char>>::apply  @ 0x101209a3c =====

/* IDWithQuality<ID<EquipmentGridPrototype, unsigned char> >::apply(IDWithQualityBackup&) */

void __thiscall
IDWithQuality<ID<EquipmentGridPrototype,unsigned_char>>::apply
          (IDWithQuality<ID<EquipmentGridPrototype,unsigned_char>> *this,
          IDWithQualityBackup *param_1)

{
  ulong uVar1;
  IDWithQualityBackup *pIVar2;
  IDWithQualityBackup IVar3;
  IDWithQuality<ID<EquipmentGridPrototype,unsigned_char>> IVar4;
  
  IVar3 = param_1[0x17];
  uVar1 = *(ulong *)(param_1 + 8);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)param_1;
    if (-1 < (char)IVar3) {
      pIVar2 = param_1;
    }
    IVar4 = (IDWithQuality<ID<EquipmentGridPrototype,unsigned_char>>)
            PrototypeList<EquipmentGridPrototype>::parseSafe(pIVar2);
    if (IVar4 != (IDWithQuality<ID<EquipmentGridPrototype,unsigned_char>>)0x0) {
      *this = IVar4;
      if ((char)param_1[0x17] < '\0') {
        **(undefined1 **)param_1 = 0;
        *(undefined8 *)(param_1 + 8) = 0;
        IVar3 = param_1[0x2f];
        uVar1 = *(ulong *)(param_1 + 0x20);
        if (-1 < (char)IVar3) {
          uVar1 = (ulong)(byte)IVar3;
        }
        goto joined_r0x000101209aa8;
      }
      *param_1 = (IDWithQualityBackup)0x0;
      param_1[0x17] = (IDWithQualityBackup)0x0;
    }
  }
  IVar3 = param_1[0x2f];
  uVar1 = *(ulong *)(param_1 + 0x20);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
joined_r0x000101209aa8:
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)(param_1 + 0x18);
    if (-1 < (char)IVar3) {
      pIVar2 = param_1 + 0x18;
    }
    IVar4 = (IDWithQuality<ID<EquipmentGridPrototype,unsigned_char>>)
            PrototypeList<QualityPrototype>::parseSafe(pIVar2);
    if (IVar4 != (IDWithQuality<ID<EquipmentGridPrototype,unsigned_char>>)0x0) {
      this[1] = IVar4;
      if ((char)param_1[0x2f] < '\0') {
        **(undefined1 **)(param_1 + 0x18) = 0;
        *(undefined8 *)(param_1 + 0x20) = 0;
        return;
      }
      param_1[0x18] = (IDWithQualityBackup)0x0;
      param_1[0x2f] = (IDWithQualityBackup)0x0;
    }
  }
  return;
}



// ===== IDWithQuality<ID<FluidPrototype,unsigned_short>>::apply  @ 0x10120b614 =====

/* IDWithQuality<ID<FluidPrototype, unsigned short> >::apply(IDWithQualityBackup&) */

void __thiscall
IDWithQuality<ID<FluidPrototype,unsigned_short>>::apply
          (IDWithQuality<ID<FluidPrototype,unsigned_short>> *this,IDWithQualityBackup *param_1)

{
  ulong uVar1;
  IDWithQualityBackup *pIVar2;
  IDWithQualityBackup IVar3;
  IDWithQuality<ID<FluidPrototype,unsigned_short>> IVar4;
  short sVar5;
  
  IVar3 = param_1[0x17];
  uVar1 = *(ulong *)(param_1 + 8);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)param_1;
    if (-1 < (char)IVar3) {
      pIVar2 = param_1;
    }
    sVar5 = PrototypeList<FluidPrototype>::parseSafe(pIVar2);
    if (sVar5 != 0) {
      *(short *)this = sVar5;
      if ((char)param_1[0x17] < '\0') {
        **(undefined1 **)param_1 = 0;
        *(undefined8 *)(param_1 + 8) = 0;
        IVar3 = param_1[0x2f];
        uVar1 = *(ulong *)(param_1 + 0x20);
        if (-1 < (char)IVar3) {
          uVar1 = (ulong)(byte)IVar3;
        }
        goto joined_r0x00010120b680;
      }
      *param_1 = (IDWithQualityBackup)0x0;
      param_1[0x17] = (IDWithQualityBackup)0x0;
    }
  }
  IVar3 = param_1[0x2f];
  uVar1 = *(ulong *)(param_1 + 0x20);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
joined_r0x00010120b680:
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)(param_1 + 0x18);
    if (-1 < (char)IVar3) {
      pIVar2 = param_1 + 0x18;
    }
    IVar4 = (IDWithQuality<ID<FluidPrototype,unsigned_short>>)
            PrototypeList<QualityPrototype>::parseSafe(pIVar2);
    if (IVar4 != (IDWithQuality<ID<FluidPrototype,unsigned_short>>)0x0) {
      this[2] = IVar4;
      if ((char)param_1[0x2f] < '\0') {
        **(undefined1 **)(param_1 + 0x18) = 0;
        *(undefined8 *)(param_1 + 0x20) = 0;
        return;
      }
      param_1[0x18] = (IDWithQualityBackup)0x0;
      param_1[0x2f] = (IDWithQualityBackup)0x0;
    }
  }
  return;
}



// ===== IDWithQuality<ID<RecipePrototype,unsigned_short>>::apply  @ 0x10120cbd4 =====

/* IDWithQuality<ID<RecipePrototype, unsigned short> >::apply(IDWithQualityBackup&) */

void __thiscall
IDWithQuality<ID<RecipePrototype,unsigned_short>>::apply
          (IDWithQuality<ID<RecipePrototype,unsigned_short>> *this,IDWithQualityBackup *param_1)

{
  ulong uVar1;
  IDWithQualityBackup *pIVar2;
  IDWithQualityBackup IVar3;
  IDWithQuality<ID<RecipePrototype,unsigned_short>> IVar4;
  short sVar5;
  
  IVar3 = param_1[0x17];
  uVar1 = *(ulong *)(param_1 + 8);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)param_1;
    if (-1 < (char)IVar3) {
      pIVar2 = param_1;
    }
    sVar5 = PrototypeList<RecipePrototype>::parseSafe(pIVar2);
    if (sVar5 != 0) {
      *(short *)this = sVar5;
      if ((char)param_1[0x17] < '\0') {
        **(undefined1 **)param_1 = 0;
        *(undefined8 *)(param_1 + 8) = 0;
        IVar3 = param_1[0x2f];
        uVar1 = *(ulong *)(param_1 + 0x20);
        if (-1 < (char)IVar3) {
          uVar1 = (ulong)(byte)IVar3;
        }
        goto joined_r0x00010120cc40;
      }
      *param_1 = (IDWithQualityBackup)0x0;
      param_1[0x17] = (IDWithQualityBackup)0x0;
    }
  }
  IVar3 = param_1[0x2f];
  uVar1 = *(ulong *)(param_1 + 0x20);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
joined_r0x00010120cc40:
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)(param_1 + 0x18);
    if (-1 < (char)IVar3) {
      pIVar2 = param_1 + 0x18;
    }
    IVar4 = (IDWithQuality<ID<RecipePrototype,unsigned_short>>)
            PrototypeList<QualityPrototype>::parseSafe(pIVar2);
    if (IVar4 != (IDWithQuality<ID<RecipePrototype,unsigned_short>>)0x0) {
      this[2] = IVar4;
      if ((char)param_1[0x2f] < '\0') {
        **(undefined1 **)(param_1 + 0x18) = 0;
        *(undefined8 *)(param_1 + 0x20) = 0;
        return;
      }
      param_1[0x18] = (IDWithQualityBackup)0x0;
      param_1[0x2f] = (IDWithQualityBackup)0x0;
    }
  }
  return;
}



// ===== IDWithQuality<ID<VirtualSignalPrototype,unsigned_short>>::apply  @ 0x10120efd8 =====

/* IDWithQuality<ID<VirtualSignalPrototype, unsigned short> >::apply(IDWithQualityBackup&) */

void __thiscall
IDWithQuality<ID<VirtualSignalPrototype,unsigned_short>>::apply
          (IDWithQuality<ID<VirtualSignalPrototype,unsigned_short>> *this,
          IDWithQualityBackup *param_1)

{
  ulong uVar1;
  IDWithQualityBackup *pIVar2;
  IDWithQualityBackup IVar3;
  IDWithQuality<ID<VirtualSignalPrototype,unsigned_short>> IVar4;
  short sVar5;
  
  IVar3 = param_1[0x17];
  uVar1 = *(ulong *)(param_1 + 8);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)param_1;
    if (-1 < (char)IVar3) {
      pIVar2 = param_1;
    }
    sVar5 = PrototypeList<VirtualSignalPrototype>::parseSafe(pIVar2);
    if (sVar5 != 0) {
      *(short *)this = sVar5;
      if ((char)param_1[0x17] < '\0') {
        **(undefined1 **)param_1 = 0;
        *(undefined8 *)(param_1 + 8) = 0;
        IVar3 = param_1[0x2f];
        uVar1 = *(ulong *)(param_1 + 0x20);
        if (-1 < (char)IVar3) {
          uVar1 = (ulong)(byte)IVar3;
        }
        goto joined_r0x00010120f044;
      }
      *param_1 = (IDWithQualityBackup)0x0;
      param_1[0x17] = (IDWithQualityBackup)0x0;
    }
  }
  IVar3 = param_1[0x2f];
  uVar1 = *(ulong *)(param_1 + 0x20);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
joined_r0x00010120f044:
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)(param_1 + 0x18);
    if (-1 < (char)IVar3) {
      pIVar2 = param_1 + 0x18;
    }
    IVar4 = (IDWithQuality<ID<VirtualSignalPrototype,unsigned_short>>)
            PrototypeList<QualityPrototype>::parseSafe(pIVar2);
    if (IVar4 != (IDWithQuality<ID<VirtualSignalPrototype,unsigned_short>>)0x0) {
      this[2] = IVar4;
      if ((char)param_1[0x2f] < '\0') {
        **(undefined1 **)(param_1 + 0x18) = 0;
        *(undefined8 *)(param_1 + 0x20) = 0;
        return;
      }
      param_1[0x18] = (IDWithQualityBackup)0x0;
      param_1[0x2f] = (IDWithQualityBackup)0x0;
    }
  }
  return;
}



// ===== IDWithQuality<UpgradeIDBase>::apply  @ 0x1012114dc =====

/* IDWithQuality<UpgradeIDBase>::apply(IDWithQualityBackup&) */

void __thiscall
IDWithQuality<UpgradeIDBase>::apply(IDWithQuality<UpgradeIDBase> *this,IDWithQualityBackup *param_1)

{
  ulong uVar1;
  IDWithQualityBackup *pIVar2;
  IDWithQualityBackup IVar3;
  IDWithQuality<UpgradeIDBase> IVar4;
  
  UpgradeIDBase::applyBackup((UpgradeIDBase *)this,(string *)param_1);
  IVar3 = param_1[0x2f];
  uVar1 = *(ulong *)(param_1 + 0x20);
  if (-1 < (char)IVar3) {
    uVar1 = (ulong)(byte)IVar3;
  }
  if (uVar1 != 0) {
    pIVar2 = *(IDWithQualityBackup **)(param_1 + 0x18);
    if (-1 < (char)IVar3) {
      pIVar2 = param_1 + 0x18;
    }
    IVar4 = (IDWithQuality<UpgradeIDBase>)PrototypeList<QualityPrototype>::parseSafe(pIVar2);
    if (IVar4 != (IDWithQuality<UpgradeIDBase>)0x0) {
      this[4] = IVar4;
      if ((char)param_1[0x2f] < '\0') {
        **(undefined1 **)(param_1 + 0x18) = 0;
        *(undefined8 *)(param_1 + 0x20) = 0;
        return;
      }
      param_1[0x18] = (IDWithQualityBackup)0x0;
      param_1[0x2f] = (IDWithQualityBackup)0x0;
    }
  }
  return;
}



// ===== PathMacroReplacer::apply  @ 0x1012cffdc =====

/* PathMacroReplacer::apply(re2::StringPiece const*) const */

void PathMacroReplacer::apply(StringPiece *param_1)

{
  StringUtil *this;
  char cVar1;
  undefined8 *puVar2;
  int iVar3;
  char *pcVar4;
  long *plVar5;
  Paths *this_00;
  undefined ***pppuVar6;
  RuntimeError *pRVar7;
  string *in_x1;
  string *extraout_x1;
  string *extraout_x1_00;
  string *extraout_x1_01;
  string *extraout_x1_02;
  string *extraout_x1_03;
  size_t sVar8;
  char *pcVar9;
  function *in_x3;
  long lVar10;
  void *local_180;
  undefined8 uStack_178;
  long local_170;
  void *local_168 [2];
  char local_151;
  undefined **local_150;
  string asStack_148 [200];
  undefined8 *local_80;
  void *local_70;
  char local_59;
  undefined **local_58;
  undefined ***pppuStack_50;
  undefined ***local_40;
  long local_38;
  
  local_38 = *(long *)PTR____stack_chk_guard_102d481b8;
  sVar8 = *(size_t *)(in_x1 + 8);
  switch(sVar8) {
  case 3:
    if ((*(char **)in_x1 != "bin") &&
       (iVar3 = _memcmp(*(char **)in_x1,"bin",sVar8), in_x1 = extraout_x1, iVar3 != 0))
    goto switchD_1012d0030_caseD_4;
    lVar10 = *(long *)(param_1 + 0xd0);
    if (lVar10 == 0 && *(long *)(param_1 + 0xd8) == 0) {
      pRVar7 = (RuntimeError *)___cxa_allocate_exception(0x10);
      RuntimeError::RuntimeError
                (pRVar7,"Cannot parse \"bin\" token, paths have not yet been initialized.");
LAB_1012d050c:
                    /* WARNING: Subroutine does not return */
      ___cxa_throw(pRVar7,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
    }
    if (lVar10 == 0) {
      if (*(long *)PTR____stack_chk_guard_102d481b8 == local_38) {
        StringUtil::narrow((StringUtil *)(*(long *)(param_1 + 0xd8) + 0x30),in_x1);
        return;
      }
      goto LAB_1012d0448;
    }
    break;
  default:
switchD_1012d0030_caseD_4:
    pRVar7 = (RuntimeError *)___cxa_allocate_exception(0x10);
    re2::StringPiece::ToString();
    ssprintf("Error while parsing path macro, \"%s\" is an unknown path specification",&local_150);
    RuntimeError::RuntimeError(pRVar7,(string *)&local_150);
                    /* WARNING: Subroutine does not return */
    ___cxa_throw(pRVar7,&RuntimeError::typeinfo,RuntimeError::~RuntimeError);
  case 9:
    if ((*(char **)in_x1 != "read-data") &&
       (iVar3 = _memcmp(*(char **)in_x1,"read-data",sVar8), in_x1 = extraout_x1_03, iVar3 != 0))
    goto switchD_1012d0030_caseD_4;
    this = *(StringUtil **)(param_1 + 0xd0);
    if (this == (StringUtil *)0x0 && *(StringUtil **)(param_1 + 0xd8) == (StringUtil *)0x0) {
      pRVar7 = (RuntimeError *)___cxa_allocate_exception(0x10);
      RuntimeError::RuntimeError
                (pRVar7,"Cannot parse \"read-data\" token, paths have not yet been initialized.");
      goto LAB_1012d050c;
    }
    if (this == (StringUtil *)0x0) {
      if (*(long *)PTR____stack_chk_guard_102d481b8 == local_38) {
        StringUtil::narrow(*(StringUtil **)(param_1 + 0xd8),in_x1);
        return;
      }
    }
    else if (*(long *)PTR____stack_chk_guard_102d481b8 == local_38) {
      StringUtil::narrow(this,in_x1);
      return;
    }
    goto LAB_1012d0448;
  case 10:
    plVar5 = *(long **)in_x1;
    if ((plVar5 == (long *)"executable") ||
       (*plVar5 == 0x6261747563657865 && (short)plVar5[1] == 0x656c)) {
      if (*(long *)PTR____stack_chk_guard_102d481b8 == local_38) {
        StringUtil::narrow((StringUtil *)(param_1 + 0xe0),in_x1);
        return;
      }
      goto LAB_1012d0448;
    }
    if ((plVar5 != (long *)"write-data") &&
       (iVar3 = _memcmp(plVar5,"write-data",sVar8), in_x1 = extraout_x1_01, iVar3 != 0))
    goto switchD_1012d0030_caseD_4;
    lVar10 = *(long *)(param_1 + 0xd8);
    if (lVar10 == 0) {
      pRVar7 = (RuntimeError *)___cxa_allocate_exception(0x10);
      RuntimeError::RuntimeError
                (pRVar7,"Cannot parse \"write-data\" token, paths have not yet been initialized.");
      goto LAB_1012d050c;
    }
    break;
  case 0x10:
    if ((*(char **)in_x1 != "system-read-data") &&
       (iVar3 = _memcmp(*(char **)in_x1,"system-read-data",sVar8), iVar3 != 0))
    goto switchD_1012d0030_caseD_4;
    this_00 = (Paths *)PathMacroReplacer((PathMacroReplacer *)&local_150,*(Paths **)(param_1 + 0xd8)
                                         ,(Path *)(param_1 + 0xe0));
    Paths::getSystemReadData(this_00);
    StringUtil::narrow((StringUtil *)&local_180,extraout_x1_02);
    pppuStack_50 = &local_150;
    local_58 = &PTR____func_1030502a0;
    local_40 = &local_58;
    RegexUtil::replace<2u>((RegexUtil *)local_168,asStack_148,(RE2 *)&local_58,in_x3);
    if (local_40 != &local_58) goto LAB_1012d027c;
LAB_1012d0150:
    lVar10 = 4;
    pppuVar6 = &local_58;
LAB_1012d0284:
    (*(code *)(*pppuVar6)[lVar10])();
    goto LAB_1012d0290;
  case 0x11:
    if ((*(char **)in_x1 != "system-write-data") &&
       (iVar3 = _memcmp(*(char **)in_x1,"system-write-data",sVar8), iVar3 != 0))
    goto switchD_1012d0030_caseD_4;
    PathMacroReplacer((PathMacroReplacer *)&local_150,*(Paths **)(param_1 + 0xd8),
                      (Path *)(param_1 + 0xe0));
    pcVar4 = (char *)_SDL_GetPrefPath("","factorio");
    local_180 = (void *)0x0;
    uStack_178 = 0;
    pcVar9 = pcVar4 + -1;
    local_170 = 0;
    do {
      pcVar9 = pcVar9 + 1;
    } while (*pcVar9 != '\0');
    std::string::append_abi_v160006_<char_const*>((string *)&local_180,pcVar4,pcVar9);
    StringUtil::narrow((StringUtil *)&local_180,extraout_x1_00);
    pppuStack_50 = &local_150;
    local_58 = &PTR____func_1030502a0;
    local_40 = &local_58;
    RegexUtil::replace<2u>((RegexUtil *)local_168,asStack_148,(RE2 *)&local_58,in_x3);
    if (local_40 == &local_58) goto LAB_1012d0150;
LAB_1012d027c:
    if (local_40 != (undefined ***)0x0) {
      lVar10 = 5;
      pppuVar6 = local_40;
      goto LAB_1012d0284;
    }
LAB_1012d0290:
    if (local_151 < '\0') {
      operator_delete(local_168[0]);
      if (local_170 < 0) goto LAB_1012d0338;
LAB_1012d02a0:
      if (-1 < local_59) goto LAB_1012d02b4;
LAB_1012d0354:
      local_150 = &PTR__PathMacroReplacer_102f77110;
      operator_delete(local_70);
      puVar2 = local_80;
    }
    else {
      if (-1 < local_170) goto LAB_1012d02a0;
LAB_1012d0338:
      operator_delete(local_180);
      if (local_59 < '\0') goto LAB_1012d0354;
LAB_1012d02b4:
      local_150 = &PTR__PathMacroReplacer_102f77110;
      puVar2 = local_80;
    }
    local_80 = (undefined8 *)0x0;
    if (puVar2 != (undefined8 *)0x0) {
      local_80 = (undefined8 *)0x0;
      if (*(char *)((long)puVar2 + 0x2f) < '\0') {
        operator_delete((void *)puVar2[3]);
        cVar1 = *(char *)((long)puVar2 + 0x17);
      }
      else {
        cVar1 = *(char *)((long)puVar2 + 0x17);
      }
      if (cVar1 < '\0') {
        operator_delete((void *)*puVar2);
      }
      operator_delete(puVar2);
    }
    local_150 = &PTR__MacroReplacer_102fc7b58;
    re2::RE2::~RE2((RE2 *)asStack_148);
    if (*(long *)PTR____stack_chk_guard_102d481b8 == local_38) {
      return;
    }
    goto LAB_1012d0448;
  }
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_38) {
    StringUtil::narrow((StringUtil *)(lVar10 + 0x18),in_x1);
    return;
  }
LAB_1012d0448:
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}



// ===== BasicTilesMapGenerationTask::apply  @ 0x1014b27b4 =====

/* BasicTilesMapGenerationTask::apply(Surface&) */

void __thiscall
BasicTilesMapGenerationTask::apply(BasicTilesMapGenerationTask *this,Surface *param_1)

{
  mutex *this_00;
  int iVar1;
  uint uVar2;
  long *plVar3;
  Chunk CVar4;
  bool bVar5;
  InfiniteVector<Chunk*> *this_01;
  undefined8 *puVar6;
  GameView *pGVar7;
  long lVar8;
  long lVar9;
  Chunk *this_02;
  long *plVar10;
  Tile *pTVar11;
  Chunk *pCVar12;
  long lVar13;
  Surface *local_78;
  ulong uStack_70;
  undefined8 local_68;
  long local_60;
  long local_58;
  
  local_60 = 0xd0;
  local_58 = std::chrono::steady_clock::now();
  this_01 = (InfiniteVector<Chunk*> *)
            InfiniteVector<InfiniteVector<Chunk*>>::operator[]
                      ((InfiniteVector<InfiniteVector<Chunk*>> *)(param_1 + 0x18),
                       *(int *)(this + 0x18));
  puVar6 = (undefined8 *)InfiniteVector<Chunk*>::operator[](this_01,*(int *)(this + 0x1c));
  this_02 = (Chunk *)*puVar6;
  if (this_02 == (Chunk *)0x0) {
    this_02 = operator_new(0x15f0);
    Chunk::Chunk(this_02,param_1,(ChunkPosition *)(this + 0x18));
    *puVar6 = this_02;
    if (this_02[0xc20] != (Chunk)0x0) goto LAB_1014b2814;
LAB_1014b28c0:
    _memcpy(this_02,this + 0x22,0xc00);
LAB_1014b28d0:
    *(int *)(*(long *)(param_1 + 0xb8) + 0x214) = *(int *)(*(long *)(param_1 + 0xb8) + 0x214) + 1;
  }
  else {
    if (this_02[0xc20] == (Chunk)0x0) goto LAB_1014b28c0;
LAB_1014b2814:
    uStack_70 = 0;
    local_68 = 0x7fffffff7fffffff;
    lVar9 = 0;
    pCVar12 = this_02;
    local_78 = param_1;
    do {
      lVar13 = 0;
      pTVar11 = (Tile *)pCVar12;
      do {
        Tile::breakupLargeTile
                  (pTVar11,&local_78,
                   CONCAT44((int)lVar13 + *(int *)(this + 0x1c) * 0x20,
                            (uint)lVar9 | *(int *)(this + 0x18) << 5),
                   *(long *)(param_1 + 0xb8) + 0x438);
        lVar13 = lVar13 + 1;
        pTVar11 = pTVar11 + 3;
      } while (lVar13 != 0x20);
      pCVar12 = pCVar12 + 0x60;
      bVar5 = lVar9 != 0x1f;
      lVar9 = lVar9 + 1;
    } while (bVar5);
    CVar4 = this_02[0xc20];
    _memcpy(this_02,this + 0x22,0xc00);
    if (CVar4 == (Chunk)0x0) goto LAB_1014b28d0;
    if (0x13 < (byte)CVar4) goto LAB_1014b28e8;
  }
  this_02[0xc20] = (Chunk)0x14;
LAB_1014b28e8:
  this_02[0x14c0] = (Chunk)0x1;
  *(undefined8 *)(this_02 + 0x14a8) =
       *(undefined8 *)(*(long *)(*(long *)(this_02 + 0xc40) + 0xb8) + 0x178);
  lVar9 = *(long *)(param_1 + 0xb8);
  if (*(long *)(lVar9 + 0x480) != 0) {
    plVar10 = *(long **)(lVar9 + 400);
    plVar3 = *(long **)(lVar9 + 0x198);
    if (plVar10 != plVar3) {
      iVar1 = *(int *)(this + 0x18);
      uVar2 = *(uint *)(this + 0x1c);
      do {
        lVar9 = *(long *)(*(long *)(*plVar10 + 0x20) + 0x480);
        if (((lVar9 != 0) && (pGVar7 = *(GameView **)(lVar9 + 0x230), pGVar7 != (GameView *)0x0)) &&
           (*(long *)(pGVar7 + 0x38) == *plVar10)) {
          local_68 = CONCAT44(local_68._4_4_,0x80010000);
          local_78 = (Surface *)((ulong)(uint)(iVar1 * 0x2000) | (ulong)uVar2 << 0x2d);
          uStack_70 = (ulong)(iVar1 * 0x2000 + 0x2000) |
                      (ulong)(uVar2 * 0x2000 + 0x2000 >> 0xd) << 0x2d;
          GameView::requestRedrawTiles(pGVar7,param_1,&local_78);
        }
        plVar10 = plVar10 + 1;
      } while (plVar10 != plVar3);
    }
  }
  lVar13 = local_58;
  lVar9 = local_60;
  this_00 = (mutex *)(*(long *)(_global + 0x1d0) + 0x18);
  std::mutex::lock(this_00);
  lVar8 = std::chrono::steady_clock::now();
  lVar9 = *(long *)(_global + 0x1d0) + lVar9;
  *(long *)(lVar9 + 0x58) = (lVar8 - lVar13) + *(long *)(lVar9 + 0x58);
  std::mutex::unlock(this_00);
  return;
}



// ===== EntityMapGenerationTask::apply  @ 0x1014cc32c =====

/* EntityMapGenerationTask::apply(Surface&) */

void __thiscall EntityMapGenerationTask::apply(EntityMapGenerationTask *this,Surface *param_1)

{
  mutex *this_00;
  long lVar1;
  InfiniteVector<Chunk*> *this_01;
  long *plVar2;
  long lVar3;
  Chunk *this_02;
  
  lVar1 = std::chrono::steady_clock::now();
  this_01 = (InfiniteVector<Chunk*> *)
            InfiniteVector<InfiniteVector<Chunk*>>::operator[]
                      ((InfiniteVector<InfiniteVector<Chunk*>> *)(param_1 + 0x18),
                       *(int *)(this + 0x60));
  plVar2 = (long *)InfiniteVector<Chunk*>::operator[](this_01,*(int *)(this + 100));
  this_02 = (Chunk *)*plVar2;
  if (this_02 == (Chunk *)0x0) {
    this_02 = operator_new(0x15f0);
    Chunk::Chunk(this_02,param_1,(ChunkPosition *)(this + 0x60));
    *plVar2 = (long)this_02;
  }
  applyCliffs(this,param_1);
  if (*(long *)(this + 0x48) != *(long *)(this + 0x50)) {
    applyDecoratives(this,param_1,this_02);
  }
  applyEntities(this,param_1);
  if (this[0x10] == (EntityMapGenerationTask)0x0) {
    if ((byte)this_02[0xc20] < 0x32) {
      *(int *)(*(long *)(param_1 + 0xb8) + 0x218) = *(int *)(*(long *)(param_1 + 0xb8) + 0x218) + 1;
      this_02[0xc20] = (Chunk)0x32;
    }
    Surface::onChunkGenerated((Surface *)param_1,this_02);
  }
  this_00 = (mutex *)(*(long *)(_global + 0x1d0) + 0x18);
  std::mutex::lock(this_00);
  lVar3 = std::chrono::steady_clock::now();
  *(long *)(*(long *)(_global + 0x1d0) + 0x160) =
       (lVar3 - lVar1) + *(long *)(*(long *)(_global + 0x1d0) + 0x160);
  std::mutex::unlock(this_00);
  return;
}



// ===== Surface::mapGeneratorWouldCollide  @ 0x1014cd130 =====

/* Surface::mapGeneratorWouldCollide(EntityPrototype const&, MapPosition const&, Direction const&)
   const */

bool __thiscall
Surface::mapGeneratorWouldCollide
          (Surface *this,EntityPrototype *param_1,MapPosition *param_2,Direction *param_3)

{
  int iVar1;
  int iVar2;
  int iVar3;
  bool bVar4;
  int iVar5;
  long *plVar6;
  ulong uVar7;
  int local_90;
  int iStack_8c;
  int local_88;
  int iStack_84;
  undefined1 local_78 [24];
  undefined8 local_60;
  undefined1 auStack_58 [24];
  undefined8 local_40;
  long local_38;
  
  local_38 = *(long *)PTR____stack_chk_guard_102d481b8;
  ::BoundingBox::BoundingBox((BoundingBox *)&local_90,param_1 + 0x244,*param_3);
  iVar5 = local_90 + *(int *)param_2;
  iVar1 = iStack_8c + *(int *)(param_2 + 4);
  iVar2 = local_88 + *(int *)param_2;
  iVar3 = iStack_84 + *(int *)(param_2 + 4);
  uVar7 = *(ulong *)(param_1 + 0x2a8);
  if ((local_90 == local_88) && (iStack_8c == iStack_84)) {
    bVar4 = false;
    local_90 = iVar5;
    iStack_8c = iVar1;
    local_88 = iVar2;
    iStack_84 = iVar3;
  }
  else {
    local_78[0] = 0;
    local_90 = iVar5;
    iStack_8c = iVar1;
    local_88 = iVar2;
    iStack_84 = iVar3;
    if ((uVar7 & Tile::sumOfAllCollisionMasks & 0xffffffffffffff) != 0) {
      if ((uVar7 >> 0x39 & 1) == 0) {
        ::BoundingBox::getAABB();
        iVar5 = checkTileCollisions(this,&local_90,auStack_58,uVar7,local_78,0,0,0,0);
      }
      else {
        ::BoundingBox::getAABB();
        iVar5 = collideBBWithTileWithTransitions(this,&local_90,auStack_58,uVar7);
      }
      if (iVar5 != 0) {
        bVar4 = true;
        goto LAB_1014cd264;
      }
    }
    local_40 = 0;
    local_60 = 0;
    plVar6 = (long *)collideWithEntity(this,&local_90,uVar7,0,auStack_58,local_78);
    bVar4 = plVar6 != (long *)0x0;
    if (plVar6 != (long *)0x0) {
      (**(code **)(*plVar6 + 0x220))();
    }
  }
LAB_1014cd264:
  if (*(long *)PTR____stack_chk_guard_102d481b8 != local_38) {
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail();
  }
  return bVar4;
}



// ===== TileCorrectionMapGenerationTask::apply  @ 0x1014f1adc =====

/* TileCorrectionMapGenerationTask::apply(Surface&) */

void __thiscall
TileCorrectionMapGenerationTask::apply(TileCorrectionMapGenerationTask *this,Surface *param_1)

{
  mutex *pmVar1;
  Chunk *pCVar2;
  long *plVar3;
  Chunk CVar4;
  short sVar5;
  short sVar6;
  int iVar7;
  int iVar8;
  uint uVar9;
  undefined8 uVar10;
  undefined8 uVar11;
  Surface *pSVar12;
  void *pvVar13;
  void *pvVar14;
  undefined8 *puVar15;
  int *piVar16;
  Tile *pTVar17;
  short *psVar18;
  InfiniteVector<Chunk*> *pIVar19;
  GameView *pGVar20;
  long lVar21;
  ulong extraout_x1;
  ulong *puVar22;
  int iVar23;
  uint uVar24;
  long lVar25;
  ulong *puVar26;
  ulong *puVar27;
  undefined2 *puVar28;
  ulong uVar29;
  ulong *puVar30;
  ulong uVar31;
  int iVar32;
  ChunkPosition *pCVar33;
  ulong uVar34;
  undefined8 *puVar35;
  int *piVar36;
  long *plVar37;
  int *piVar38;
  int *piVar39;
  Chunk *pCVar40;
  ulong uVar41;
  int iVar42;
  long lVar43;
  int *piVar44;
  uint uVar45;
  undefined8 uVar46;
  undefined8 uVar47;
  undefined1 auVar48 [16];
  uint local_110;
  undefined8 local_10c;
  ulong *local_100;
  ulong *local_f8;
  undefined8 local_f0;
  Surface *local_e8;
  Chunk *local_e0;
  undefined8 local_d8;
  undefined8 local_d0;
  void *local_c8;
  undefined8 local_c0;
  int *local_b8;
  int *local_b0;
  int *local_a8;
  long local_a0;
  long local_98;
  ulong local_90;
  ulong uStack_88;
  undefined4 local_80;
  
  local_b8 = (int *)0xe0;
  local_b0 = (int *)std::chrono::steady_clock::now();
  pCVar33 = (ChunkPosition *)(this + 0x10);
  iVar23 = *(int *)pCVar33;
  iVar42 = iVar23 + -1;
  local_d0 = (void *)CONCAT44(local_d0._4_4_,iVar42);
  if (iVar42 < iVar23 + 2) {
    iVar32 = *(int *)(this + 0x14);
    do {
      iVar8 = iVar32 + -1;
      local_d0._4_4_ = iVar8;
      if (iVar8 < iVar32 + 2) {
        do {
          iVar8 = local_d0._4_4_;
          iVar23 = *(int *)pCVar33;
          pvVar13 = operator_new(0x800);
          lVar43 = (ulong)((iVar42 - iVar23) + 1) * 0x18 + 0x4858;
          uVar34 = (ulong)((iVar8 - iVar32) + 1);
          _bzero(pvVar13,0x800);
          lVar25 = uVar34 * 8;
          pvVar14 = *(void **)(this + lVar25 + lVar43);
          *(void **)(this + lVar25 + lVar43) = pvVar13;
          if (pvVar14 != (void *)0x0) {
            operator_delete(pvVar14);
          }
          iVar23 = *(int *)(param_1 + 0x24);
          if (iVar42 < -iVar23) {
            iVar32 = iVar23 * 2;
            if (iVar23 * 2 <= -iVar42) {
              iVar32 = -iVar42;
            }
            iVar7 = *(int *)(param_1 + 0x20);
            uVar24 = (iVar7 + iVar32) - iVar23;
            uVar41 = -(ulong)(uVar24 >> 0x1f) & 0xfffffff000000000 | (ulong)uVar24 << 4;
            uVar29 = uVar41;
            if ((int)uVar24 < 0) {
              uVar29 = 0xffffffffffffffff;
            }
            pvVar13 = operator_new__(uVar29);
            if (iVar7 + iVar32 != iVar23) {
              _bzero(pvVar13,uVar41);
            }
            iVar23 = iVar7 + (iVar32 - iVar23);
            *(int *)(param_1 + 0x20) = iVar23;
            pvVar14 = *(void **)(param_1 + 0x18);
            if (pvVar14 != (void *)0x0) {
              _memmove((void *)((long)pvVar13 + (long)iVar7 * -0x10 + (long)iVar23 * 0x10),pvVar14,
                       (long)iVar7 * 0x10);
              operator_delete__(pvVar14);
            }
            *(void **)(param_1 + 0x18) = pvVar13;
            *(int *)(param_1 + 0x24) = iVar32;
            iVar23 = iVar32;
          }
          else {
            iVar32 = *(int *)(param_1 + 0x20);
            if (iVar23 + iVar42 < iVar32) {
              pvVar13 = *(void **)(param_1 + 0x18);
            }
            else {
              iVar7 = (iVar32 - iVar23) * 2;
              if (iVar32 - iVar23 == 0) {
                iVar7 = 1;
              }
              uVar24 = iVar7 + iVar23;
              if (iVar7 <= iVar42) {
                uVar24 = iVar23 + iVar42 + 1;
              }
              uVar41 = -(ulong)(uVar24 >> 0x1f) & 0xfffffff000000000 | (ulong)uVar24 << 4;
              uVar29 = uVar41;
              if ((int)uVar24 < 0) {
                uVar29 = 0xffffffffffffffff;
              }
              pvVar13 = operator_new__(uVar29);
              if (uVar24 != 0) {
                _bzero(pvVar13,uVar41);
              }
              pvVar14 = *(void **)(param_1 + 0x18);
              if (pvVar14 == (void *)0x0) {
                *(uint *)(param_1 + 0x20) = uVar24;
              }
              else {
                _memmove(pvVar13,pvVar14,(long)iVar32 << 4);
                *(uint *)(param_1 + 0x20) = uVar24;
                operator_delete__(pvVar14);
                iVar23 = *(int *)(param_1 + 0x24);
              }
              *(void **)(param_1 + 0x18) = pvVar13;
            }
          }
          puVar15 = (undefined8 *)
                    InfiniteVector<Chunk*>::operator[]
                              ((InfiniteVector<Chunk*> *)
                               ((long)pvVar13 + (long)(iVar23 + iVar42) * 0x10),iVar8);
          pCVar40 = (Chunk *)*puVar15;
          if (pCVar40 == (Chunk *)0x0) {
            pCVar40 = operator_new(0x15f0);
            Chunk::Chunk(pCVar40,param_1,(ChunkPosition *)&local_d0);
            *puVar15 = pCVar40;
          }
          lVar25 = 0;
          puVar28 = (undefined2 *)(*(long *)(this + uVar34 * 8 + lVar43) + 0x20);
          do {
            pCVar2 = pCVar40 + lVar25 + 0x30;
            puVar28[-0x10] = *(undefined2 *)(pCVar2 + -0x30);
            puVar28[-0xf] = *(undefined2 *)(pCVar2 + -0x2d);
            puVar28[-0xe] = *(undefined2 *)(pCVar2 + -0x2a);
            puVar28[-0xd] = *(undefined2 *)(pCVar2 + -0x27);
            puVar28[-0xc] = *(undefined2 *)(pCVar2 + -0x24);
            puVar28[-0xb] = *(undefined2 *)(pCVar2 + -0x21);
            puVar28[-10] = *(undefined2 *)(pCVar2 + -0x1e);
            puVar28[-9] = *(undefined2 *)(pCVar2 + -0x1b);
            puVar28[-8] = *(undefined2 *)(pCVar2 + -0x18);
            puVar28[-7] = *(undefined2 *)(pCVar2 + -0x15);
            puVar28[-6] = *(undefined2 *)(pCVar2 + -0x12);
            puVar28[-5] = *(undefined2 *)(pCVar2 + -0xf);
            puVar28[-4] = *(undefined2 *)(pCVar2 + -0xc);
            puVar28[-3] = *(undefined2 *)(pCVar2 + -9);
            puVar28[-2] = *(undefined2 *)(pCVar2 + -6);
            puVar28[-1] = *(undefined2 *)(pCVar2 + -3);
            *puVar28 = *(undefined2 *)pCVar2;
            puVar28[1] = *(undefined2 *)(pCVar2 + 3);
            puVar28[2] = *(undefined2 *)(pCVar2 + 6);
            puVar28[3] = *(undefined2 *)(pCVar2 + 9);
            puVar28[4] = *(undefined2 *)(pCVar2 + 0xc);
            puVar28[5] = *(undefined2 *)(pCVar2 + 0xf);
            puVar28[6] = *(undefined2 *)(pCVar2 + 0x12);
            puVar28[7] = *(undefined2 *)(pCVar2 + 0x15);
            puVar28[8] = *(undefined2 *)(pCVar2 + 0x18);
            puVar28[9] = *(undefined2 *)(pCVar2 + 0x1b);
            puVar28[10] = *(undefined2 *)(pCVar2 + 0x1e);
            puVar28[0xb] = *(undefined2 *)(pCVar2 + 0x21);
            puVar28[0xc] = *(undefined2 *)(pCVar2 + 0x24);
            puVar28[0xd] = *(undefined2 *)(pCVar2 + 0x27);
            puVar28[0xe] = *(undefined2 *)(pCVar2 + 0x2a);
            puVar28[0xf] = *(undefined2 *)(pCVar2 + 0x2d);
            lVar25 = lVar25 + 0x60;
            puVar28 = puVar28 + 0x20;
          } while (lVar25 != 0xc00);
          local_d0._4_4_ = iVar8 + 1;
          iVar32 = *(int *)(this + 0x14);
        } while (local_d0._4_4_ < iVar32 + 2);
        iVar23 = *(int *)pCVar33;
      }
      iVar42 = iVar42 + 1;
      local_d0 = (void *)CONCAT44(local_d0._4_4_,iVar42);
    } while (iVar42 < iVar23 + 2);
  }
  computeInternal(this);
  piVar16 = local_b0;
  piVar36 = local_b8;
  pmVar1 = (mutex *)(*(long *)(_global + 0x1d0) + 0x18);
  std::mutex::lock(pmVar1);
  lVar25 = std::chrono::steady_clock::now();
  lVar43 = *(long *)(_global + 0x1d0) + (long)piVar36;
  *(long *)(lVar43 + 0x58) = (lVar25 - (long)piVar16) + *(long *)(lVar43 + 0x58);
  std::mutex::unlock(pmVar1);
  local_a0 = 0xe8;
  local_98 = std::chrono::steady_clock::now();
  local_b8 = (int *)0x0;
  local_b0 = (int *)0x0;
  local_a8 = (int *)0x0;
  puVar35 = *(undefined8 **)(this + 0x4840);
  puVar15 = *(undefined8 **)(this + 0x4838);
  uVar34 = (long)puVar35 - (long)puVar15;
  piVar16 = local_b0;
  piVar36 = local_a8;
  if (uVar34 != 0) {
    if ((long)uVar34 < 0) {
                    /* WARNING: Subroutine does not return */
      std::vector<TilePosition,std::allocator<TilePosition>>::__throw_length_error_abi_v160006_();
    }
    piVar16 = operator_new(uVar34);
    piVar36 = piVar16 + ((long)uVar34 >> 3) * 2;
  }
  local_b8 = piVar16;
  local_e8 = param_1;
  local_a8 = piVar36;
  if (puVar15 == puVar35) {
    local_d0 = (void *)0x0;
    local_c8 = (void *)0x0;
    local_c0 = 0;
    local_e0 = (Chunk *)0x0;
    local_d8 = 0x7fffffff7fffffff;
    local_b0 = local_b8;
  }
  else {
    piVar38 = local_b8;
    piVar16 = local_b8;
    local_b0 = local_b8;
    do {
      while (uVar47 = CONCAT44((int)((ulong)*puVar15 >> 0x20) -
                               (int)((ulong)*(undefined8 *)(this + 0x4850) >> 0x20),
                               (int)*puVar15 - (int)*(undefined8 *)(this + 0x4850)),
            piVar38 < piVar36) {
        piVar39 = piVar38 + 2;
        *(undefined8 *)piVar38 = uVar47;
        puVar15 = puVar15 + 1;
        piVar38 = piVar39;
        local_b0 = piVar39;
        if (puVar15 == puVar35) goto LAB_1014f1ff8;
      }
      lVar43 = (long)piVar38 - (long)piVar16 >> 3;
      uVar34 = lVar43 + 1;
      if (uVar34 >> 0x3d != 0) {
                    /* WARNING: Subroutine does not return */
        std::vector<TilePosition,std::allocator<TilePosition>>::__throw_length_error_abi_v160006_();
      }
      uVar29 = (ulong)((long)piVar36 - (long)piVar16) >> 2;
      if (uVar29 <= uVar34) {
        uVar29 = uVar34;
      }
      if (0x7ffffffffffffff7 < (ulong)((long)piVar36 - (long)piVar16)) {
        uVar29 = 0x1fffffffffffffff;
      }
      if (uVar29 >> 0x3d != 0) {
                    /* WARNING: Subroutine does not return */
        std::__throw_bad_array_new_length_abi_v160006_();
      }
      pvVar13 = operator_new(uVar29 << 3);
      piVar44 = (int *)((long)pvVar13 + lVar43 * 8);
      piVar39 = piVar44 + 2;
      *(undefined8 *)piVar44 = uVar47;
      while (piVar38 != piVar16) {
        piVar38 = piVar38 + -2;
        piVar44 = piVar44 + -2;
        *(undefined8 *)piVar44 = *(undefined8 *)piVar38;
      }
      piVar36 = (int *)((long)pvVar13 + uVar29 * 8);
      local_b8 = piVar44;
      local_b0 = piVar39;
      local_a8 = piVar36;
      if (piVar16 != (int *)0x0) {
        operator_delete(piVar16);
      }
      puVar15 = puVar15 + 1;
      piVar38 = piVar39;
      piVar16 = piVar44;
    } while (puVar15 != puVar35);
LAB_1014f1ff8:
    local_d0 = (void *)0x0;
    local_c8 = (void *)0x0;
    local_c0 = 0;
    local_e0 = (Chunk *)0x0;
    local_d8 = 0x7fffffff7fffffff;
    piVar36 = piVar16;
    if (piVar16 != piVar39) {
      do {
        pTVar17 = (Tile *)TileProxy::getTile((TileProxy *)&local_e8,*(undefined8 *)piVar36);
        Tile::breakupLargeTileRaw(pTVar17,&local_e8,*(undefined8 *)piVar36,&local_d0);
        piVar36 = piVar36 + 2;
      } while (piVar36 != piVar39);
      for (; piVar16 != piVar39; piVar16 = piVar16 + 2) {
        psVar18 = (short *)TileProxy::getTile((TileProxy *)&local_e8,*(undefined8 *)piVar16);
        pSVar12 = local_e8;
        sVar6 = *(short *)(this + (ulong)(uint)(*(int *)(this + 0x4854) + piVar16[1]) * 2 +
                                  (ulong)(uint)(*(int *)(this + 0x4850) + *piVar16) * 0xc0 + 0x20);
        sVar5 = *psVar18;
        if (sVar6 != sVar5) {
          uVar24 = *piVar16 >> 5;
          uVar34 = (ulong)uVar24;
          iVar42 = piVar16[1] >> 5;
          local_100 = (ulong *)CONCAT44(iVar42,uVar24);
          if (((uint)local_d8 != uVar24) || (local_d8._4_4_ != iVar42)) {
            pIVar19 = (InfiniteVector<Chunk*> *)
                      InfiniteVector<InfiniteVector<Chunk*>>::operator[]
                                ((InfiniteVector<InfiniteVector<Chunk*>> *)(local_e8 + 0x18),uVar24)
            ;
            auVar48 = InfiniteVector<Chunk*>::operator[](pIVar19,iVar42);
            uVar34 = auVar48._8_8_;
            pCVar40 = (Chunk *)*auVar48._0_8_;
            if (pCVar40 == (Chunk *)0x0) {
              pCVar40 = operator_new(0x15f0);
              Chunk::Chunk(pCVar40,pSVar12,(ChunkPosition *)&local_100);
              *auVar48._0_8_ = pCVar40;
              uVar34 = extraout_x1;
            }
            local_d8 = *(undefined8 *)(pCVar40 + 0xc48);
            sVar5 = *psVar18;
            local_e0 = pCVar40;
          }
          *psVar18 = sVar6;
          Chunk::onTileIDChanged(local_e0,uVar34,sVar5,sVar6);
        }
      }
    }
  }
  local_100 = (ulong *)0x0;
  local_f8 = (ulong *)0x0;
  local_f0 = 0;
  MapGenerator::makeTransitiveClosure
            ((TileProxy *)&local_e8,(vector *)&local_d0,(vector *)&local_100);
  lVar43 = 0;
  if (local_f8 != local_100) {
    lVar43 = LZCOUNT((long)local_f8 - (long)local_100 >> 3) * -2 + 0x7e;
  }
  std::__introsort<std::_ClassicAlgPolicy,std::__less<TilePosition,TilePosition>&,TilePosition*>
            (local_100,local_f8,&local_90,lVar43);
  puVar22 = local_100;
  if (local_100 != local_f8) {
    puVar27 = local_100 + -1;
    do {
      puVar26 = puVar27;
      puVar22 = local_f8;
      if (puVar26 + 2 == local_f8) goto LAB_1014f2240;
      puVar27 = puVar26 + 1;
      uVar34 = (ulong)(uint)*puVar27;
    } while ((uint)*puVar27 != (uint)puVar26[2] ||
             *(uint *)((long)puVar26 + 0xc) != *(uint *)((long)puVar26 + 0x14));
    if (puVar27 != local_f8) {
      puVar30 = puVar26 + 3;
      if (puVar30 == local_f8) {
        puVar26 = puVar26 + 2;
      }
      else {
        do {
          if ((uint)uVar34 != (uint)*puVar30 ||
              *(uint *)((long)puVar27 + 4) != *(uint *)((long)puVar30 + 4)) {
            uVar34 = *puVar30;
            puVar27 = puVar27 + 1;
            *puVar27 = uVar34;
          }
          puVar30 = puVar30 + 1;
        } while (puVar30 != local_f8);
        puVar26 = puVar27 + 1;
      }
      if (puVar26 != local_f8) {
        _memmove(puVar26,local_f8,0);
        puVar22 = puVar26;
        local_f8 = puVar26;
      }
    }
  }
LAB_1014f2240:
  uVar34 = DAT_1029732e0;
  uVar11 = DAT_1029732d8;
  uVar10 = DAT_1029732d0;
  uVar47 = DAT_1029732c8;
  local_110 = *(int *)(this + 0x14) * 0x1ee3 + *(int *)(this + 0x10) * 0x1eef + 0x3fbe2c;
  if (local_110 < 0x156) {
    local_110 = 0x155;
  }
  local_10c = CONCAT44(local_110,local_110);
  if (local_100 != puVar22) {
    uVar29 = (ulong)((long)puVar22 - (long)local_100) >> 3;
    uVar24 = (int)uVar29 - 1;
    uVar41 = (ulong)uVar24;
    while (uVar24 != 0) {
      uVar24 = (uint)uVar29;
      if (uVar24 < 2) {
        uVar29 = 0;
      }
      else {
        local_110 = (local_110 & 0xffffe) << 0xc | (local_110 ^ local_110 << 0xd) >> 0x13;
        uVar46 = NEON_ushl(local_10c,uVar47,4);
        uVar46 = NEON_ushl(CONCAT17((byte)((ulong)uVar46 >> 0x38) ^ (byte)((ulong)local_10c >> 0x38)
                                    ,CONCAT16((byte)((ulong)uVar46 >> 0x30) ^
                                              (byte)((ulong)local_10c >> 0x30),
                                              CONCAT15((byte)((ulong)uVar46 >> 0x28) ^
                                                       (byte)((ulong)local_10c >> 0x28),
                                                       CONCAT14((byte)((ulong)uVar46 >> 0x20) ^
                                                                (byte)((ulong)local_10c >> 0x20),
                                                                CONCAT13((byte)((ulong)uVar46 >>
                                                                               0x18) ^
                                                                         (byte)((ulong)local_10c >>
                                                                               0x18),
                                                                         CONCAT12((byte)((ulong)
                                                  uVar46 >> 0x10) ^ (byte)((ulong)local_10c >> 0x10)
                                                  ,CONCAT11((byte)((ulong)uVar46 >> 8) ^
                                                            (byte)((ulong)local_10c >> 8),
                                                            (byte)uVar46 ^ (byte)local_10c))))))),
                           uVar10,4);
        uVar29 = NEON_ushl(local_10c,uVar11,4);
        uVar29 = uVar29 & uVar34;
        uVar45 = CONCAT13((byte)((ulong)uVar46 >> 0x18) | (byte)(uVar29 >> 0x18),
                          CONCAT12((byte)((ulong)uVar46 >> 0x10) | (byte)(uVar29 >> 0x10),
                                   CONCAT11((byte)((ulong)uVar46 >> 8) | (byte)(uVar29 >> 8),
                                            (byte)uVar46 | (byte)uVar29)));
        local_10c = CONCAT17((byte)((ulong)uVar46 >> 0x38) | (byte)(uVar29 >> 0x38),
                             CONCAT16((byte)((ulong)uVar46 >> 0x30) | (byte)(uVar29 >> 0x30),
                                      CONCAT15((byte)((ulong)uVar46 >> 0x28) |
                                               (byte)(uVar29 >> 0x28),
                                               CONCAT14((byte)((ulong)uVar46 >> 0x20) |
                                                        (byte)(uVar29 >> 0x20),uVar45))));
        uVar45 = uVar45 ^ local_110 ^ (uint)((ulong)local_10c >> 0x20);
        uVar9 = 0;
        if (uVar24 != 0) {
          uVar9 = uVar45 / uVar24;
        }
        uVar29 = (ulong)(uVar45 - uVar9 * uVar24);
      }
      uVar31 = local_100[uVar41];
      local_100[uVar41] = local_100[uVar29];
      local_100[uVar29] = uVar31;
      uVar29 = (ulong)(uVar24 - 1);
      uVar41 = uVar41 - 1;
      uVar24 = (uint)uVar41;
    }
  }
  MapGenerator::selectTileVariations<std::vector<TilePosition,std::allocator<TilePosition>>>
            (param_1,(TileProxy *)&local_e8,(vector *)&local_100,(RandomGenerator *)&local_110,
             (set *)0x0);
  pIVar19 = (InfiniteVector<Chunk*> *)
            InfiniteVector<InfiniteVector<Chunk*>>::operator[]
                      ((InfiniteVector<InfiniteVector<Chunk*>> *)(param_1 + 0x18),*(int *)pCVar33);
  puVar15 = (undefined8 *)InfiniteVector<Chunk*>::operator[](pIVar19,*(int *)(this + 0x14));
  pCVar40 = (Chunk *)*puVar15;
  if (pCVar40 == (Chunk *)0x0) {
    pCVar40 = operator_new(0x15f0);
    Chunk::Chunk(pCVar40,param_1,pCVar33);
    *puVar15 = pCVar40;
    CVar4 = pCVar40[0xc20];
  }
  else {
    CVar4 = pCVar40[0xc20];
  }
  if ((byte)CVar4 < 0x1e) {
    pCVar40[0xc20] = (Chunk)0x1e;
  }
  lVar43 = *(long *)(param_1 + 0xb8);
  if (*(long *)(lVar43 + 0x480) != 0) {
    plVar37 = *(long **)(lVar43 + 400);
    plVar3 = *(long **)(lVar43 + 0x198);
    if (plVar37 != plVar3) {
      iVar42 = *(int *)(this + 0x10);
      uVar24 = *(uint *)(this + 0x14);
      do {
        lVar43 = *(long *)(*(long *)(*plVar37 + 0x20) + 0x480);
        if (((lVar43 != 0) && (pGVar20 = *(GameView **)(lVar43 + 0x230), pGVar20 != (GameView *)0x0)
            ) && (*(long *)(pGVar20 + 0x38) == *plVar37)) {
          local_80 = 0x80010000;
          local_90 = (ulong)(uint)(iVar42 * 0x2000) | (ulong)uVar24 << 0x2d;
          uStack_88 = (ulong)(iVar42 * 0x2000 + 0x2000) |
                      (ulong)(uVar24 * 0x2000 + 0x2000 >> 0xd) << 0x2d;
          GameView::requestRedrawTiles(pGVar20,param_1,&local_90);
        }
        plVar37 = plVar37 + 1;
      } while (plVar37 != plVar3);
    }
  }
  if (local_100 != (ulong *)0x0) {
    local_f8 = local_100;
    operator_delete(local_100);
  }
  if (local_d0 != (void *)0x0) {
    local_c8 = local_d0;
    operator_delete(local_d0);
  }
  if (local_b8 != (int *)0x0) {
    local_b0 = local_b8;
    operator_delete(local_b8);
  }
  lVar25 = local_98;
  lVar43 = local_a0;
  pmVar1 = (mutex *)(*(long *)(_global + 0x1d0) + 0x18);
  std::mutex::lock(pmVar1);
  lVar21 = std::chrono::steady_clock::now();
  lVar43 = *(long *)(_global + 0x1d0) + lVar43;
  *(long *)(lVar43 + 0x58) = (lVar21 - lVar25) + *(long *)(lVar43 + 0x58);
  std::mutex::unlock(pmVar1);
  return;
}



// ===== VariationsMapGeneratorTask::apply  @ 0x1014f2674 =====

/* VariationsMapGeneratorTask::apply(Surface&) */

void __thiscall VariationsMapGeneratorTask::apply(VariationsMapGeneratorTask *this,Surface *param_1)

{
  mutex *this_00;
  int iVar1;
  uint uVar2;
  long *plVar3;
  long lVar4;
  InfiniteVector<Chunk*> *this_01;
  MapGenerator *pMVar5;
  MapGenerator *this_02;
  GameView *pGVar6;
  long lVar7;
  long lVar8;
  Chunk *this_03;
  long *plVar9;
  int *piVar10;
  Surface *local_90;
  undefined8 uStack_88;
  undefined8 local_80;
  uint local_78;
  uint uStack_74;
  uint local_70;
  long local_68;
  long local_60;
  ulong local_58;
  ulong uStack_50;
  undefined4 local_48;
  
  local_68 = 0xf0;
  local_60 = std::chrono::steady_clock::now();
  this_01 = (InfiniteVector<Chunk*> *)
            InfiniteVector<InfiniteVector<Chunk*>>::operator[]
                      ((InfiniteVector<InfiniteVector<Chunk*>> *)(param_1 + 0x18),
                       *(int *)(this + 0x10));
  pMVar5 = (MapGenerator *)InfiniteVector<Chunk*>::operator[](this_01,*(int *)(this + 0x14));
  this_03 = *(Chunk **)pMVar5;
  this_02 = pMVar5;
  if (this_03 == (Chunk *)0x0) {
    this_03 = operator_new(0x15f0);
    this_02 = (MapGenerator *)Chunk::Chunk(this_03,param_1,(ChunkPosition *)(this + 0x10));
    *(Chunk **)pMVar5 = this_03;
  }
  local_78 = *(int *)(this + 0x14) * 0x1ee3 + *(int *)(this + 0x10) * 0x1eef + 0x3fbe2c;
  if (local_78 < 0x156) {
    local_78 = 0x155;
  }
  uStack_88 = 0;
  local_80 = 0x7fffffff7fffffff;
  local_90 = param_1;
  uStack_74 = local_78;
  local_70 = local_78;
  MapGenerator::selectTileVariations
            (this_02,this_03,(TileProxy *)&local_90,(RandomGenerator *)&local_78);
  if (((byte)this_03[0xc20] < 0x28) && (this_03[0xc20] = (Chunk)0x28, this_03[0x1502] == (Chunk)0x0)
     ) {
    piVar10 = &Util::NEIGHBOR_COORDS;
    do {
      lVar8 = *(long *)(this_03 + 0xc40);
      if ((-*(int *)(lVar8 + 0x24) <= *(int *)(this_03 + 0xc48) + *piVar10) &&
         (iVar1 = *(int *)(lVar8 + 0x24) + *(int *)(this_03 + 0xc48) + *piVar10,
         iVar1 < *(int *)(lVar8 + 0x20))) {
        plVar9 = (long *)(*(long *)(lVar8 + 0x18) + (long)iVar1 * 0x10);
        if (plVar9 != (long *)0x0) {
          lVar8 = *(long *)(lVar8 + 0x18) + (long)iVar1 * 0x10;
          iVar1 = *(int *)(lVar8 + 0xc);
          if ((((-iVar1 <= *(int *)(this_03 + 0xc4c) + piVar10[1]) &&
               (iVar1 = iVar1 + *(int *)(this_03 + 0xc4c) + piVar10[1], iVar1 < *(int *)(lVar8 + 8))
               ) && (plVar9 = (long *)(*plVar9 + (long)iVar1 * 8), plVar9 != (long *)0x0)) &&
             (lVar8 = *plVar9, lVar8 != 0)) {
            ChunkComponents::onNeighborChunkTilesChanged((ChunkComponents *)(lVar8 + 0x1598));
          }
        }
      }
      piVar10 = piVar10 + 2;
    } while (piVar10 != (int *)&UNK_10297d214);
  }
  lVar8 = *(long *)(param_1 + 0xb8);
  if (*(long *)(lVar8 + 0x480) != 0) {
    plVar9 = *(long **)(lVar8 + 400);
    plVar3 = *(long **)(lVar8 + 0x198);
    if (plVar9 != plVar3) {
      iVar1 = *(int *)(this + 0x10);
      uVar2 = *(uint *)(this + 0x14);
      do {
        lVar8 = *(long *)(*(long *)(*plVar9 + 0x20) + 0x480);
        if (((lVar8 != 0) && (pGVar6 = *(GameView **)(lVar8 + 0x230), pGVar6 != (GameView *)0x0)) &&
           (*(long *)(pGVar6 + 0x38) == *plVar9)) {
          local_48 = 0x80010000;
          local_58 = (ulong)(uint)(iVar1 * 0x2000) | (ulong)uVar2 << 0x2d;
          uStack_50 = (ulong)(iVar1 * 0x2000 + 0x2000) |
                      (ulong)(uVar2 * 0x2000 + 0x2000 >> 0xd) << 0x2d;
          GameView::requestRedrawTiles(pGVar6,param_1,&local_58);
        }
        plVar9 = plVar9 + 1;
      } while (plVar9 != plVar3);
    }
  }
  lVar4 = local_60;
  lVar8 = local_68;
  this_00 = (mutex *)(*(long *)(_global + 0x1d0) + 0x18);
  std::mutex::lock(this_00);
  lVar7 = std::chrono::steady_clock::now();
  lVar8 = *(long *)(_global + 0x1d0) + lVar8;
  *(long *)(lVar8 + 0x58) = (lVar7 - lVar4) + *(long *)(lVar8 + 0x58);
  std::mutex::unlock(this_00);
  return;
}



// ===== SurfaceProperties::apply  @ 0x101559ca4 =====

/* SurfaceProperties::apply(Surface&, SurfacePropertiesPrototype const&) */

void __thiscall
SurfaceProperties::apply
          (SurfaceProperties *this,Surface *param_1,SurfacePropertiesPrototype *param_2)

{
  undefined8 *puVar1;
  long lVar2;
  undefined2 *puVar3;
  undefined2 *puVar4;
  void *pvVar5;
  long lVar6;
  long lVar7;
  long lVar8;
  void *pvVar9;
  void *pvVar10;
  ulong uVar11;
  undefined8 uVar12;
  undefined8 uVar13;
  
  lVar6 = *(long *)(param_2 + 8) - *(long *)param_2 >> 3;
  uVar11 = lVar6 * -0x5555555555555555;
  pvVar9 = *(void **)this;
  if ((ulong)((*(long *)(this + 0x10) - (long)pvVar9 >> 3) * -0x5555555555555555) < uVar11) {
    if (0xaaaaaaaaaaaaaaa < uVar11) {
                    /* WARNING: Subroutine does not return */
      std::
      vector<Pair<ID<SurfacePropertyPrototype,unsigned_short>,SurfaceProperties::Item>,std::allocator<Pair<ID<SurfacePropertyPrototype,unsigned_short>,SurfaceProperties::Item>>>
      ::__throw_length_error_abi_v160006_();
    }
    pvVar10 = *(void **)(this + 8);
    pvVar5 = operator_new(*(long *)(param_2 + 8) - *(long *)param_2);
    lVar2 = (long)pvVar5 + ((long)pvVar10 - (long)pvVar9);
    lVar7 = lVar2;
    lVar8 = lVar2;
    if ((long)pvVar10 - (long)pvVar9 != 0) {
      do {
        uVar13 = *(undefined8 *)((long)pvVar10 + -0x10);
        uVar12 = *(undefined8 *)((long)pvVar10 + -0x18);
        puVar1 = (undefined8 *)((long)pvVar10 + -8);
        pvVar10 = (void *)((long)pvVar10 + -0x18);
        lVar8 = lVar7 + -0x18;
        *(undefined8 *)(lVar7 + -8) = *puVar1;
        *(undefined8 *)(lVar7 + -0x10) = uVar13;
        *(undefined8 *)(lVar7 + -0x18) = uVar12;
        lVar7 = lVar8;
      } while (pvVar10 != pvVar9);
    }
    *(long *)this = lVar8;
    *(long *)(this + 8) = lVar2;
    *(void **)(this + 0x10) = (void *)((long)pvVar5 + lVar6 * 8);
    if (pvVar9 != (void *)0x0) {
      operator_delete(pvVar9);
    }
  }
  puVar4 = *(undefined2 **)(param_2 + 8);
  for (puVar3 = *(undefined2 **)param_2; puVar3 != puVar4; puVar3 = puVar3 + 0xc) {
    setValue(*(SurfaceProperties **)(puVar3 + 8),this,param_1,*puVar3,0);
  }
  return;
}



// ===== SpaceAgeFixUpMigrations::apply  @ 0x10165136c =====

/* SpaceAgeFixUpMigrations::apply(Scenario&) const */

void __thiscall SpaceAgeFixUpMigrations::apply(SpaceAgeFixUpMigrations *this,Scenario *param_1)

{
  undefined2 uVar1;
  uint uVar2;
  ForceData *this_00;
  bool bVar3;
  undefined8 *puVar4;
  long lVar5;
  long lVar6;
  long lVar7;
  ushort *puVar8;
  undefined8 *puVar9;
  long *plVar10;
  long *plVar11;
  long lVar12;
  uint *puVar13;
  ulong uVar14;
  uint uVar15;
  long *plVar16;
  long lVar17;
  long *plVar18;
  long *plVar19;
  undefined8 *puVar20;
  undefined8 *puVar21;
  undefined8 *puVar22;
  undefined8 *puVar23;
  undefined8 local_138;
  undefined8 uStack_130;
  undefined8 local_128;
  undefined4 uStack_120;
  undefined4 uStack_11c;
  undefined4 uStack_118;
  undefined8 uStack_114;
  undefined4 local_108 [12];
  undefined2 local_d8;
  undefined2 local_d6;
  undefined1 local_d4;
  undefined8 local_d3;
  undefined4 local_cb;
  undefined8 uStack_bc;
  undefined4 uStack_b4;
  undefined8 uStack_b0;
  undefined4 uStack_a8;
  undefined8 uStack_a4;
  undefined8 uStack_9c;
  undefined8 uStack_94;
  undefined8 uStack_8c;
  undefined8 uStack_84;
  undefined8 uStack_7c;
  undefined1 uStack_74;
  long local_70;
  
  local_70 = *(long *)PTR____stack_chk_guard_102d481b8;
  migrateItemsAndEntities(this,*(Map **)(param_1 + 0x5e8));
  plVar18 = *(long **)PTR_prototypes_102d4d138;
  plVar16 = *(long **)(PTR_prototypes_102d4d138 + 8);
  if (plVar18 != plVar16) {
    lVar6 = 0;
    puVar9 = (undefined8 *)((ulong)local_108 | 4);
    this_00 = *(ForceData **)(*(long *)(*(long *)(param_1 + 0x5e8) + 0x3c8) + 8);
    puVar4 = (undefined8 *)((ulong)&local_138 | 4);
    do {
      bVar3 = false;
LAB_101651454:
      lVar17 = *(long *)(*(long *)(this_00 + 0x50) + 8);
LAB_101651470:
      uVar14 = (ulong)*(ushort *)(*plVar18 + 0x188);
      plVar19 = (long *)(lVar17 + uVar14 * 0x28);
      puVar13 = (uint *)((long)plVar19 + 0x24);
      uVar2 = *puVar13;
      lVar7 = *plVar19;
      if ((*(int *)(lVar7 + 400) - *(int *)(lVar7 + 0x18c)) + 1U <= uVar2) {
        puVar8 = *(ushort **)(lVar7 + 0x198);
        if (puVar8 == *(ushort **)(lVar7 + 0x1a0)) goto LAB_101651464;
        puVar23 = (undefined8 *)(lVar17 + uVar14 * 0x28 + 8);
        plVar10 = (long *)*puVar23;
LAB_1016514bc:
        plVar11 = (long *)(*(long *)(plVar10[10] + 8) + (ulong)*puVar8 * 0x28);
        lVar12 = *plVar11;
        if ((*(int *)(lVar12 + 400) - *(int *)(lVar12 + 0x18c)) + 1U <=
            *(uint *)((long)plVar11 + 0x24)) goto code_r0x0001016514e4;
        if (uVar2 != 0) {
          lVar12 = *plVar10;
          if (*(long *)(lVar7 + 0x230) != *(long *)(lVar7 + 0x238)) {
            uVar15 = 0;
            do {
              puVar21 = *(undefined8 **)(*plVar19 + 0x230);
              puVar20 = *(undefined8 **)(*plVar19 + 0x238);
              if (puVar21 != puVar20) {
                do {
                  puVar22 = puVar21 + 1;
                  (**(code **)(*(long *)*puVar21 + 0x30))((long *)*puVar21,*puVar23);
                  puVar21 = puVar22;
                } while (puVar22 != puVar20);
                uVar2 = *puVar13;
              }
              uVar15 = uVar15 + 1;
            } while (uVar15 < uVar2);
          }
          *puVar13 = 0;
          lVar7 = *(long *)(lVar12 + 0x480);
          if ((lVar7 != 0) && (lVar5 = *(long *)(lVar7 + 0x230), lVar5 != 0)) {
            local_108[0] = 3;
            puVar9[1] = uStack_9c;
            *puVar9 = uStack_a4;
            puVar9[3] = uStack_8c;
            puVar9[2] = uStack_94;
            puVar9[5] = uStack_7c;
            puVar9[4] = uStack_84;
            *(undefined1 *)(puVar9 + 6) = uStack_74;
            local_d3 = uStack_b0;
            local_cb = uStack_a8;
            GameNotifications::queue((GameNotifications *)(lVar5 + 0x948),local_108);
            lVar7 = *(long *)(lVar12 + 0x480);
          }
          uVar1 = *(undefined2 *)(*plVar19 + 0x188);
          puVar4[1] = 0;
          *puVar4 = 0;
          puVar4[3] = 0;
          puVar4[2] = 0;
          puVar4[4] = 0;
          if ((lVar7 != 0) && (lVar7 = *(long *)(lVar7 + 0x230), lVar7 != 0)) {
            local_108[0] = 4;
            puVar9[1] = uStack_130;
            *puVar9 = local_138;
            puVar9[3] = CONCAT44(uStack_11c,uStack_120);
            puVar9[2] = local_128;
            *(undefined8 *)((long)puVar9 + 0x24) = uStack_114;
            *(ulong *)((long)puVar9 + 0x1c) = CONCAT44(uStack_118,uStack_11c);
            local_d6 = 0;
            local_d4 = 0;
            local_d3 = uStack_bc;
            local_cb = uStack_b4;
            local_d8 = uVar1;
            GameNotifications::queue((GameNotifications *)(lVar7 + 0x948),local_108);
          }
          lVar17 = *(long *)(lVar17 + uVar14 * 0x28 + 0x10);
          if (lVar17 != 0) {
            *(undefined1 *)(lVar17 + 0xb) = 0;
          }
        }
        plVar18 = plVar18 + 1;
        bVar3 = true;
        if (plVar18 == plVar16) goto LAB_101651418;
        goto LAB_101651454;
      }
LAB_101651464:
      plVar18 = plVar18 + 1;
      if (plVar18 != plVar16) goto LAB_101651470;
      if (!bVar3) goto LAB_101651674;
LAB_101651418:
      lVar6 = lVar6 + 1;
      plVar18 = *(long **)PTR_prototypes_102d4d138;
      plVar16 = *(long **)(PTR_prototypes_102d4d138 + 8);
      if (plVar18 == plVar16) goto LAB_101651674;
    } while( true );
  }
LAB_1016516a0:
  param_1[0xfc] = (Scenario)0x0;
  if (*(long *)PTR____stack_chk_guard_102d481b8 != local_70) {
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail();
  }
  return;
code_r0x0001016514e4:
  puVar8 = puVar8 + 8;
  if (puVar8 == *(ushort **)(lVar7 + 0x1a0)) goto LAB_101651464;
  goto LAB_1016514bc;
LAB_101651674:
  if (lVar6 != 0) {
    Recipes::reset(*(Recipes **)(this_00 + 0x48),2);
    Technologies::reset(*(Technologies **)(this_00 + 0x50),2);
    ForceData::updateUnlockedItems(this_00);
  }
  goto LAB_1016516a0;
}



// ===== ScenarioHistory::Step::apply  @ 0x101671fb4 =====

/* ScenarioHistory::Step::apply(ScenarioHistory::State&) const */

void __thiscall ScenarioHistory::Step::apply(Step *this,State *param_1)

{
  ChangeItem *this_00;
  ChangeItem *pCVar1;
  
  pCVar1 = *(ChangeItem **)(this + 8);
  for (this_00 = *(ChangeItem **)this; this_00 != pCVar1; this_00 = this_00 + 0x58) {
    ChangeItem::apply(this_00,param_1);
  }
  return;
}



// ===== ScenarioHistory::ChangeItem::apply  @ 0x101672518 =====

/* ScenarioHistory::ChangeItem::apply(ScenarioHistory::State&) const */

void __thiscall ScenarioHistory::ChangeItem::apply(ChangeItem *this,State *param_1)

{
  undefined8 *puVar1;
  ModID *pMVar2;
  ulong uVar3;
  ChangeItem *pCVar4;
  string *psVar5;
  ModID *pMVar6;
  size_t sVar7;
  void *pvVar8;
  string *psVar9;
  undefined4 uVar10;
  byte bVar11;
  string sVar12;
  ushort uVar13;
  size_t sVar14;
  bool bVar15;
  int iVar16;
  undefined8 *puVar17;
  undefined8 uVar18;
  ulong uVar19;
  string *this_00;
  undefined8 *puVar20;
  undefined8 *puVar21;
  undefined8 uVar22;
  void *local_98 [2];
  char local_81;
  void *local_80 [2];
  char local_69;
  void *local_68 [2];
  char local_51;
  
  switch(*this) {
  case (ChangeItem)0x0:
    uVar13 = *(ushort *)(this + 8);
    bVar15 = *(ushort *)param_1 < uVar13;
    if ((*(ushort *)param_1 == uVar13) &&
       (bVar15 = *(ushort *)(param_1 + 2) < *(ushort *)(this + 10),
       *(ushort *)(param_1 + 2) == *(ushort *)(this + 10))) {
      bVar15 = *(ushort *)(param_1 + 4) != *(ushort *)(this + 0xc) &&
               *(ushort *)(param_1 + 4) < *(ushort *)(this + 0xc);
    }
    if (!bVar15) {
      ssprintf("%u.%u.%u",local_68);
      ssprintf("%s (build %u)",local_80);
      if (local_51 < '\0') {
        operator_delete(local_68[0]);
      }
      ssprintf("%u.%u.%u",local_68);
      ssprintf("%s (build %u)",local_98);
      if (local_51 < '\0') {
        operator_delete(local_68[0]);
      }
      Logging::log("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Scenario/ScenarioHistory.cpp"
                   ,0x7b,8,"Scenario history is inconsistent: %s >= %s.");
      if (local_81 < '\0') {
        operator_delete(local_98[0]);
      }
      if (local_69 < '\0') {
        operator_delete(local_80[0]);
      }
    }
    uVar10 = *(undefined4 *)(this + 8);
    *(undefined2 *)(param_1 + 4) = *(undefined2 *)(this + 0xc);
    *(undefined4 *)param_1 = uVar10;
    *(undefined4 *)(param_1 + 8) = *(undefined4 *)(this + 0x10);
    std::string::operator=((string *)(param_1 + 0x10),(string *)(this + 0x18));
    break;
  case (ChangeItem)0x1:
    pMVar2 = (ModID *)(this + 0x30);
    puVar17 = *(undefined8 **)(param_1 + 0x28);
    puVar21 = *(undefined8 **)(param_1 + 0x30);
    if (puVar17 == puVar21) {
LAB_1016728e8:
      if (puVar17 != puVar21) {
                    /* WARNING: Subroutine does not return */
        Logging::logAndAbortOrThrow
                  ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Scenario/ScenarioHistory.cpp"
                   ,0x83,9,"Scenario history is inconsistent");
      }
    }
    else {
      sVar14 = *(size_t *)(this + 0x38);
      pMVar6 = *(ModID **)(this + 0x30);
      if (-1 < (char)this[0x47]) {
        sVar14 = (ulong)(byte)this[0x47];
        pMVar6 = pMVar2;
      }
      do {
        bVar11 = *(byte *)((long)puVar17 + 0x17);
        sVar7 = puVar17[1];
        if (-1 < (char)bVar11) {
          sVar7 = (ulong)bVar11;
        }
        if (sVar7 == sVar14) {
          if ((char)bVar11 < '\0') {
            if ((sVar14 == 0) || (iVar16 = _memcmp((void *)*puVar17,pMVar6,sVar14), iVar16 == 0))
            goto LAB_1016728e8;
          }
          else {
            if (bVar11 == 0) goto LAB_1016728e8;
            uVar19 = 0;
            while (*(ModID *)((long)puVar17 + uVar19) == pMVar6[uVar19]) {
              uVar19 = uVar19 + 1;
              if (bVar11 == uVar19) goto LAB_1016728e8;
            }
          }
        }
        puVar17 = puVar17 + 5;
      } while (puVar17 != puVar21);
    }
    if (puVar21 == *(undefined8 **)(param_1 + 0x38)) {
      std::vector<ModID,std::allocator<ModID>>::__push_back_slow_path<ModID_const&>
                ((vector<ModID,std::allocator<ModID>> *)(param_1 + 0x28),pMVar2);
      return;
    }
    if ((char)this[0x47] < '\0') {
      pvVar8 = *(void **)(this + 0x30);
      uVar19 = *(ulong *)(this + 0x38);
      if (uVar19 < 0x17) {
        *(char *)((long)puVar21 + 0x17) = (char)uVar19;
        puVar17 = puVar21;
      }
      else {
        if (0x7fffffffffffffef < uVar19) {
                    /* WARNING: Subroutine does not return */
          std::string::__throw_length_error_abi_v160006_();
        }
        uVar3 = (uVar19 | 0xf) + 1;
        puVar17 = operator_new(uVar3);
        puVar21[1] = uVar19;
        puVar21[2] = uVar3 | 0x8000000000000000;
        *puVar21 = puVar17;
      }
      _memmove(puVar17,pvVar8,uVar19 + 1);
    }
    else {
      uVar22 = *(undefined8 *)(this + 0x38);
      uVar18 = *(undefined8 *)pMVar2;
      puVar21[2] = *(undefined8 *)(this + 0x40);
      puVar21[1] = uVar22;
      *puVar21 = uVar18;
    }
    uVar18 = *(undefined8 *)(this + 0x48);
    *(undefined4 *)(puVar21 + 4) = *(undefined4 *)(this + 0x50);
    puVar21[3] = uVar18;
    *(undefined8 **)(param_1 + 0x30) = puVar21 + 5;
    break;
  case (ChangeItem)0x2:
    puVar17 = *(undefined8 **)(param_1 + 0x28);
    puVar21 = *(undefined8 **)(param_1 + 0x30);
    if (puVar17 != puVar21) {
      sVar14 = *(size_t *)(this + 0x38);
      pCVar4 = *(ChangeItem **)(this + 0x30);
      if (-1 < (char)this[0x47]) {
        sVar14 = (ulong)(byte)this[0x47];
        pCVar4 = this + 0x30;
      }
      do {
        bVar11 = *(byte *)((long)puVar17 + 0x17);
        sVar7 = puVar17[1];
        if (-1 < (char)bVar11) {
          sVar7 = (ulong)bVar11;
        }
        if (sVar7 == sVar14) {
          if ((char)bVar11 < '\0') {
            if ((sVar14 == 0) || (iVar16 = _memcmp((void *)*puVar17,pCVar4,sVar14), iVar16 == 0))
            goto LAB_1016727a0;
          }
          else {
            if (bVar11 == 0) goto LAB_1016727a0;
            uVar19 = 0;
            while (*(ChangeItem *)((long)puVar17 + uVar19) == pCVar4[uVar19]) {
              uVar19 = uVar19 + 1;
              if (bVar11 == uVar19) goto LAB_1016727a0;
            }
          }
        }
        puVar17 = puVar17 + 5;
      } while (puVar17 != puVar21);
LAB_101672ae0:
                    /* WARNING: Subroutine does not return */
      Logging::logAndAbortOrThrow
                ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Scenario/ScenarioHistory.cpp"
                 ,0x8b,9,"Scenario history is inconsistent");
    }
LAB_1016727a0:
    if (puVar17 == puVar21) goto LAB_101672ae0;
    puVar20 = puVar17;
    if (puVar17 + 5 == puVar21) {
      if (puVar21 != puVar17) {
LAB_101672994:
        do {
          puVar20 = puVar21 + -5;
          if (*(char *)((long)puVar21 + -0x11) < '\0') {
            operator_delete((void *)*puVar20);
          }
          puVar21 = puVar20;
        } while (puVar20 != puVar17);
      }
    }
    else {
      do {
        if (*(char *)((long)puVar20 + 0x17) < '\0') {
          operator_delete((void *)*puVar20);
        }
        puVar20[1] = puVar20[6];
        *puVar20 = puVar20[5];
        *(undefined1 *)((long)puVar20 + 0x3f) = 0;
        puVar17 = puVar20 + 5;
        *(undefined1 *)puVar17 = 0;
        puVar20[2] = puVar20[7];
        puVar20[3] = puVar20[8];
        *(undefined4 *)(puVar20 + 4) = *(undefined4 *)(puVar20 + 9);
        puVar1 = puVar20 + 10;
        puVar20 = puVar17;
      } while (puVar1 != puVar21);
      puVar21 = *(undefined8 **)(param_1 + 0x30);
      if (puVar21 != puVar17) goto LAB_101672994;
    }
    *(undefined8 **)(param_1 + 0x30) = puVar17;
    break;
  case (ChangeItem)0x3:
    this_00 = *(string **)(param_1 + 0x28);
    psVar9 = *(string **)(param_1 + 0x30);
    if (this_00 == psVar9) {
LAB_101672a14:
      if (this_00 != psVar9) {
        std::string::operator=(this_00,(string *)(this + 0x30));
        uVar10 = *(undefined4 *)(this + 0x50);
        *(undefined8 *)(this_00 + 0x18) = *(undefined8 *)(this + 0x48);
        *(undefined4 *)(this_00 + 0x20) = uVar10;
        return;
      }
    }
    else {
      psVar5 = *(string **)(this + 0x30);
      sVar14 = *(size_t *)(this + 0x38);
      if (-1 < (char)this[0x47]) {
        psVar5 = (string *)(this + 0x30);
        sVar14 = (ulong)(byte)this[0x47];
      }
      if (sVar14 == 0) {
        do {
          sVar12 = this_00[0x17];
          uVar19 = *(ulong *)(this_00 + 8);
          if (-1 < (char)sVar12) {
            uVar19 = (ulong)(byte)sVar12;
          }
          if (uVar19 == 0) {
            if ((char)sVar12 < '\x01') goto LAB_101672a14;
            uVar19 = 0;
            while (this_00[uVar19] == psVar5[uVar19]) {
              uVar19 = uVar19 + 1;
              if ((byte)sVar12 == uVar19) goto LAB_101672a14;
            }
          }
          this_00 = this_00 + 0x28;
        } while (this_00 != psVar9);
      }
      else {
        do {
          sVar12 = this_00[0x17];
          sVar7 = *(size_t *)(this_00 + 8);
          if (-1 < (char)sVar12) {
            sVar7 = (ulong)(byte)sVar12;
          }
          if (sVar7 == sVar14) {
            if ((char)sVar12 < '\0') {
              iVar16 = _memcmp(*(void **)this_00,psVar5,sVar14);
              if (iVar16 == 0) goto LAB_101672a14;
            }
            else {
              if (sVar12 == (string)0x0) goto LAB_101672a14;
              uVar19 = 0;
              while (this_00[uVar19] == psVar5[uVar19]) {
                uVar19 = uVar19 + 1;
                if ((byte)sVar12 == uVar19) goto LAB_101672a14;
              }
            }
          }
          this_00 = this_00 + 0x28;
        } while (this_00 != psVar9);
      }
    }
                    /* WARNING: Subroutine does not return */
    Logging::logAndAbortOrThrow
              ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Scenario/ScenarioHistory.cpp"
               ,0x93,9,"Scenario history is inconsistent");
  }
  return;
}



// ===== SettingsPresets::apply  @ 0x101914320 =====

/* SettingsPresets::apply(std::string const&, GlobalContext*) */

void SettingsPresets::apply(string *param_1,GlobalContext *param_2)

{
  string *psVar1;
  ulong uVar2;
  string sVar3;
  StorageConfigItem<ControlInputValue> local_50 [4];
  undefined4 local_4c;
  undefined1 local_48;
  void *local_40;
  undefined8 local_38;
  long lStack_30;
  undefined1 local_28;
  
  sVar3 = param_1[0x17];
  psVar1 = *(string **)param_1;
  if (-1 < (char)sVar3) {
    psVar1 = param_1;
  }
  uVar2 = *(ulong *)(param_1 + 8);
  if (-1 < (char)sVar3) {
    uVar2 = (ulong)(byte)sVar3;
  }
  if ((uVar2 == 6) && (*(int *)psVar1 == 0x6b736f62 && *(short *)(psVar1 + 4) == 0x6469)) {
    StorageConfigItem<unsigned_char>::setValue
              ((StorageConfigItem<unsigned_char> *)(*(long *)(param_2 + 0x240) + 0x3e0),'\x1e');
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x1ce0),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x1d80),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x1e20),true);
    StorageConfigItem<unsigned_char>::setValue
              ((StorageConfigItem<unsigned_char> *)(*(long *)(param_2 + 0x240) + 0x2000),'\0');
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x2568),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x26a8),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x2748),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x27e8),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x2888),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x2928),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x29c8),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x2a68),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0xc0),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x240) + 0x2d88),true);
    StorageConfigItem<ConsistencyCheckLevel>::setValue
              ((StorageConfigItem<ConsistencyCheckLevel> *)(*(long *)(param_2 + 0x240) + 0x2e28),2);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0xd98),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0xe38),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0xed8),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0xf78),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0x1018),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0x10b8),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0x1158),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0x11f8),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0x1298),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0x1338),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0x13d8),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0x1978),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0xcf8),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x220) + 0x2c0),true);
    StorageConfigItem<unsigned_char>::setValue
              ((StorageConfigItem<unsigned_char> *)(*(long *)(param_2 + 0x220) + 0x220),'\x03');
    local_50[0] = (StorageConfigItem<ControlInputValue>)0x2;
    local_4c = 4;
    local_48 = 0;
    local_38 = 0;
    lStack_30 = 0;
    local_40 = (void *)0x0;
    local_28 = 0;
    StorageConfigItem<ControlInputValue>::setValue
              (local_50,*(long *)(param_2 + 0x1f8) + 0x82b8,local_50);
    if (lStack_30 < 0) {
      operator_delete(local_40);
    }
    local_50[0] = (StorageConfigItem<ControlInputValue>)0x0;
    local_48 = 0;
    local_38 = 0;
    lStack_30 = 0;
    local_40 = (void *)0x0;
    local_28 = 0;
    StorageConfigItem<ControlInputValue>::setValue
              (local_50,*(long *)(param_2 + 0x1f8) + 0x25860,local_50);
    if (lStack_30 < 0) {
      operator_delete(local_40);
    }
    local_50[0] = (StorageConfigItem<ControlInputValue>)0x0;
    local_48 = 0;
    local_38 = 0;
    lStack_30 = 0;
    local_40 = (void *)0x0;
    local_28 = 0;
    StorageConfigItem<ControlInputValue>::setValue
              (local_50,*(long *)(param_2 + 0x1f8) + 0x25c88,local_50);
    if (lStack_30 < 0) {
      operator_delete(local_40);
    }
    local_50[0] = (StorageConfigItem<ControlInputValue>)0x1;
    local_4c = 8;
    local_48 = 8;
    local_38 = 0;
    lStack_30 = 0;
    local_40 = (void *)0x0;
    local_28 = 0;
    StorageConfigItem<ControlInputValue>::setValue
              (local_50,*(long *)(param_2 + 0x1f8) + 0x2ee00,local_50);
    if (lStack_30 < 0) {
      operator_delete(local_40);
    }
    local_50[0] = (StorageConfigItem<ControlInputValue>)0x1;
    local_4c = 0x15;
    local_48 = 8;
    local_38 = 0;
    lStack_30 = 0;
    local_40 = (void *)0x0;
    local_28 = 0;
    StorageConfigItem<ControlInputValue>::setValue
              (local_50,*(long *)(param_2 + 0x1f8) + 0x2f128,local_50);
    if (lStack_30 < 0) {
      operator_delete(local_40);
    }
    StorageConfigItem<DebugSettings::ItemLevel>::setValue
              ((StorageConfigItem<DebugSettings::ItemLevel> *)(*(long *)(param_2 + 0x208) + 0x300),0
              );
    StorageConfigItem<DebugSettings::ItemLevel>::setValue
              ((StorageConfigItem<DebugSettings::ItemLevel> *)(*(long *)(param_2 + 0x208) + 0x440),0
              );
    StorageConfigItem<DebugSettings::ItemLevel>::setValue
              ((StorageConfigItem<DebugSettings::ItemLevel> *)(*(long *)(param_2 + 0x208) + 0xda0),0
              );
    StorageConfigItem<DebugSettings::ItemLevel>::setValue
              ((StorageConfigItem<DebugSettings::ItemLevel> *)(*(long *)(param_2 + 0x208) + 0x1020),
               0);
    StorageConfigItem<DebugSettings::ItemLevel>::setValue
              ((StorageConfigItem<DebugSettings::ItemLevel> *)(*(long *)(param_2 + 0x208) + 0xbc0),0
              );
    StorageConfigItem<DebugSettings::ItemLevel>::setValue
              ((StorageConfigItem<DebugSettings::ItemLevel> *)(*(long *)(param_2 + 0x208) + 0x56c0),
               0);
    StorageConfigItem<DebugSettings::ItemLevel>::setValue
              ((StorageConfigItem<DebugSettings::ItemLevel> *)(*(long *)(param_2 + 0x208) + 0x4f40),
               1);
    StorageConfigItem<DebugSettings::ItemLevel>::setValue
              ((StorageConfigItem<DebugSettings::ItemLevel> *)(*(long *)(param_2 + 0x208) + 0x5d00),
               0);
    StorageConfigItem<DebugSettings::ItemLevel>::setValue
              ((StorageConfigItem<DebugSettings::ItemLevel> *)(*(long *)(param_2 + 0x208) + 0x5da0),
               1);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0x1070),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0x11b0),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0x16b0),false);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0x1750),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0x1890),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0x1a70),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0x1b10),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0xcb0),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0xd50),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0xdf0),true);
    StorageConfigItem<bool>::setValue
              ((StorageConfigItem<bool> *)(*(long *)(param_2 + 0x218) + 0xfd0),false);
    return;
  }
  return;
}



// ===== PollutionBuffer::apply  @ 0x1019afa74 =====

/* PollutionBuffer::apply(LazyCreatedStatistics<FlowStatistics<ID<EntityPrototype, unsigned short>,
   double, void> >&, Surface&) */

void __thiscall
PollutionBuffer::apply(PollutionBuffer *this,LazyCreatedStatistics *param_1,Surface *param_2)

{
  long lVar1;
  char cVar2;
  uint uVar3;
  FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void> *pFVar4;
  long *plVar5;
  ulong uVar6;
  void *pvVar7;
  long lVar8;
  float fVar9;
  
  uVar3 = (uint)(*(int *)(this + 8) - *(int *)this) >> 3 & 0xffff;
  if (1 < uVar3) {
    lVar8 = 0;
    uVar6 = 1;
    do {
      lVar1 = *(long *)this + lVar8;
      fVar9 = *(float *)(lVar1 + 8);
      if (fVar9 != 0.0) {
        pvVar7 = *(void **)param_1;
        if (pvVar7 == (void *)0x0) {
          pvVar7 = operator_new(0x4c8);
          FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void>::FlowStatistics();
          pFVar4 = *(FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void> **)param_1;
          *(void **)param_1 = pvVar7;
          if (pFVar4 != (FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void> *)0x0) {
            pvVar7 = (void *)FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void>::
                             ~FlowStatistics(pFVar4);
            operator_delete(pvVar7);
            pvVar7 = *(void **)param_1;
          }
        }
        FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void>::onFlow(fVar9,pvVar7,uVar6);
      }
      fVar9 = *(float *)(lVar1 + 0xc);
      if (fVar9 != 0.0) {
        pvVar7 = *(void **)param_1;
        if (pvVar7 == (void *)0x0) {
          pvVar7 = operator_new(0x4c8);
          FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void>::FlowStatistics();
          pFVar4 = *(FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void> **)param_1;
          *(void **)param_1 = pvVar7;
          if (pFVar4 != (FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void> *)0x0) {
            pvVar7 = (void *)FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void>::
                             ~FlowStatistics(pFVar4);
            operator_delete(pvVar7);
            pvVar7 = *(void **)param_1;
          }
        }
        FlowStatistics<ID<EntityPrototype,unsigned_short>,double,void>::onFlow(fVar9,pvVar7,uVar6);
      }
      *(undefined8 *)(lVar1 + 8) = 0;
      uVar6 = uVar6 + 1;
      lVar8 = lVar8 + 8;
    } while (uVar3 != uVar6);
  }
  if (0.0 < *(double *)(this + 0x18)) {
    plVar5 = (long *)(*(long *)(*(long *)(param_2 + 0xb8) + 0x200) + 0x1c8);
    cVar2 = *(char *)(*(long *)(*(long *)(param_2 + 0xb8) + 0x200) + 0x1d1);
    while (cVar2 == '\0') {
      plVar5 = (long *)*plVar5;
      cVar2 = *(char *)((long)plVar5 + 9);
    }
    if ((char)plVar5[1] != '\0') {
      if (*(long *)(param_2 + 0x38) == 0) {
        if (*(long *)(param_2 + 0x30) == 0) {
          cVar2 = *(char *)(*(long *)(*(long *)PTR_indexToPrototype_102d4db80 +
                                     (ulong)*(ushort *)(CorePrototypes::pollutionPrototype + 0x188)
                                     * 8) + 0x240);
        }
        else {
          cVar2 = *(char *)(*(long *)(*(long *)PTR_indexToPrototype_102d4db80 +
                                     (ulong)*(ushort *)
                                             (*(long *)(*(long *)(param_2 + 0x30) + 0x20) + 0x568) *
                                     8) + 0x240);
        }
      }
      else {
        cVar2 = *(char *)(**(long **)PTR_indexToPrototype_102d4db80 + 0x240);
      }
      if (cVar2 != '\0') {
        EvolutionFactorData::increaseEvolutionFactorByPollution
                  ((Surface *)param_2,*(double *)(this + 0x18));
      }
    }
    *(undefined8 *)(this + 0x18) = 0;
  }
  return;
}



// ===== TrainMover::RollbackData::apply  @ 0x1019ed86c =====

/* TrainMover::RollbackData::apply(TrainMover&, NamedBool<ExtenstionTag>) */

void __thiscall
TrainMover::RollbackData::apply(RollbackData *this,TrainMover *param_1,undefined1 param_3)

{
  long lVar1;
  long lVar2;
  
  if (*(long *)(this + 0x20) - *(long *)(this + 0x18) != 0) {
    for (lVar2 = *(long *)(this + 0x20) - *(long *)(this + 0x18) >> 3; lVar2 != 1;
        lVar2 = lVar2 + -1) {
      lVar1 = *(long *)(this + 0x18) + lVar2 * 8;
      onTrainEdgeRailTransition
                (param_1,*(undefined8 *)(lVar1 + -8),*(undefined8 *)(lVar1 + -0x10),param_3);
    }
  }
  return;
}



// ===== TriggerEffectItem::apply  @ 0x1019f21a8 =====

/* TriggerEffectItem::apply(TriggerContext const&) const */

void __thiscall TriggerEffectItem::apply(TriggerEffectItem *this,TriggerContext *param_1)

{
  ushort uVar1;
  ushort uVar2;
  undefined8 uVar3;
  int iVar4;
  undefined8 *puVar5;
  uint *puVar6;
  uint uVar7;
  uint uVar8;
  uint uVar9;
  float fVar10;
  undefined8 uVar11;
  ulong uVar12;
  byte bVar13;
  byte bVar17;
  byte bVar18;
  byte bVar19;
  byte bVar20;
  byte bVar21;
  byte bVar22;
  undefined8 uVar14;
  undefined8 uVar15;
  ulong uVar16;
  byte bVar23;
  undefined8 uVar24;
  
  if (((*(long *)(param_1 + 0xe8) == 0) ||
      (iVar4 = (**(code **)(*(long *)this + 0x68))(this), iVar4 != 0)) &&
     (iVar4 = (**(code **)(*(long *)this + 0x60))(this,param_1), iVar4 != 0)) {
    uVar1 = *(ushort *)(this + 8);
    uVar8 = (uint)uVar1;
    uVar2 = *(ushort *)(this + 10);
    if (uVar2 != 0) {
      if (*(long *)(param_1 + 0xe8) == 0) {
        puVar6 = (uint *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
      }
      else {
        puVar6 = *(uint **)(_global + 0x250);
      }
      uVar7 = (uint)uVar2 * 2;
      uVar8 = *puVar6;
      uVar8 = (uVar8 & 0xffffe) << 0xc | (uVar8 ^ uVar8 << 0xd) >> 0x13;
      *puVar6 = uVar8;
      uVar11 = *(undefined8 *)(puVar6 + 1);
      uVar14 = NEON_ushl(uVar11,DAT_1029732c8,4);
      uVar14 = NEON_ushl(CONCAT17((byte)((ulong)uVar14 >> 0x38) ^ (byte)((ulong)uVar11 >> 0x38),
                                  CONCAT16((byte)((ulong)uVar14 >> 0x30) ^
                                           (byte)((ulong)uVar11 >> 0x30),
                                           CONCAT15((byte)((ulong)uVar14 >> 0x28) ^
                                                    (byte)((ulong)uVar11 >> 0x28),
                                                    CONCAT14((byte)((ulong)uVar14 >> 0x20) ^
                                                             (byte)((ulong)uVar11 >> 0x20),
                                                             CONCAT13((byte)((ulong)uVar14 >> 0x18)
                                                                      ^ (byte)((ulong)uVar11 >> 0x18
                                                                              ),
                                                                      CONCAT12((byte)((ulong)uVar14
                                                                                     >> 0x10) ^
                                                                               (byte)((ulong)uVar11
                                                                                     >> 0x10),
                                                                               CONCAT11((byte)((
                                                  ulong)uVar14 >> 8) ^ (byte)((ulong)uVar11 >> 8),
                                                  (byte)uVar14 ^ (byte)uVar11))))))),DAT_1029732d0,4
                        );
      uVar12 = NEON_ushl(uVar11,DAT_1029732d8,4);
      uVar12 = uVar12 & DAT_1029732e0;
      uVar9 = CONCAT13((byte)((ulong)uVar14 >> 0x18) | (byte)(uVar12 >> 0x18),
                       CONCAT12((byte)((ulong)uVar14 >> 0x10) | (byte)(uVar12 >> 0x10),
                                CONCAT11((byte)((ulong)uVar14 >> 8) | (byte)(uVar12 >> 8),
                                         (byte)uVar14 | (byte)uVar12)));
      uVar11 = CONCAT17((byte)((ulong)uVar14 >> 0x38) | (byte)(uVar12 >> 0x38),
                        CONCAT16((byte)((ulong)uVar14 >> 0x30) | (byte)(uVar12 >> 0x30),
                                 CONCAT15((byte)((ulong)uVar14 >> 0x28) | (byte)(uVar12 >> 0x28),
                                          CONCAT14((byte)((ulong)uVar14 >> 0x20) |
                                                   (byte)(uVar12 >> 0x20),uVar9))));
      *(undefined8 *)(puVar6 + 1) = uVar11;
      uVar8 = uVar9 ^ uVar8 ^ (uint)((ulong)uVar11 >> 0x20);
      uVar9 = 0;
      if (uVar2 != 0) {
        uVar9 = uVar8 / uVar7;
      }
      uVar8 = ((uint)uVar1 - (uint)uVar2) + (uVar8 - uVar9 * uVar7);
    }
    uVar12 = DAT_1029732c0;
    uVar3 = DAT_1029732b8;
    uVar14 = DAT_1029732b0;
    uVar11 = DAT_1029732a8;
    if (0 < (int)uVar8) {
      do {
        fVar10 = *(float *)(this + 0xc);
        if (fVar10 == 1.0) {
LAB_1019f22e0:
          (**(code **)(*(long *)this + 0x70))(this,param_1);
        }
        else {
          if (*(long *)(param_1 + 0xe8) == 0) {
            puVar5 = (undefined8 *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
          }
          else {
            puVar5 = *(undefined8 **)(_global + 0x250);
          }
          uVar15 = *puVar5;
          uVar24 = NEON_ushl(uVar15,uVar11,4);
          uVar24 = NEON_ushl(CONCAT17((byte)((ulong)uVar24 >> 0x38) ^ (byte)((ulong)uVar15 >> 0x38),
                                      CONCAT16((byte)((ulong)uVar24 >> 0x30) ^
                                               (byte)((ulong)uVar15 >> 0x30),
                                               CONCAT15((byte)((ulong)uVar24 >> 0x28) ^
                                                        (byte)((ulong)uVar15 >> 0x28),
                                                        CONCAT14((byte)((ulong)uVar24 >> 0x20) ^
                                                                 (byte)((ulong)uVar15 >> 0x20),
                                                                 CONCAT13((byte)((ulong)uVar24 >>
                                                                                0x18) ^
                                                                          (byte)((ulong)uVar15 >>
                                                                                0x18),
                                                                          CONCAT12((byte)((ulong)
                                                  uVar24 >> 0x10) ^ (byte)((ulong)uVar15 >> 0x10),
                                                  CONCAT11((byte)((ulong)uVar24 >> 8) ^
                                                           (byte)((ulong)uVar15 >> 8),
                                                           (byte)uVar24 ^ (byte)uVar15))))))),uVar14
                             ,4);
          uVar16 = NEON_ushl(uVar15,uVar3,4);
          uVar16 = uVar16 & uVar12;
          bVar13 = (byte)uVar24 | (byte)uVar16;
          bVar17 = (byte)((ulong)uVar24 >> 8) | (byte)(uVar16 >> 8);
          bVar18 = (byte)((ulong)uVar24 >> 0x10) | (byte)(uVar16 >> 0x10);
          bVar19 = (byte)((ulong)uVar24 >> 0x18) | (byte)(uVar16 >> 0x18);
          bVar20 = (byte)((ulong)uVar24 >> 0x20) | (byte)(uVar16 >> 0x20);
          bVar21 = (byte)((ulong)uVar24 >> 0x28) | (byte)(uVar16 >> 0x28);
          bVar22 = (byte)((ulong)uVar24 >> 0x30) | (byte)(uVar16 >> 0x30);
          bVar23 = (byte)((ulong)uVar24 >> 0x38) | (byte)(uVar16 >> 0x38);
          *puVar5 = CONCAT17(bVar23,CONCAT16(bVar22,CONCAT15(bVar21,CONCAT14(bVar20,CONCAT13(bVar19,
                                                  CONCAT12(bVar18,CONCAT11(bVar17,bVar13)))))));
          uVar9 = *(uint *)(puVar5 + 1);
          uVar9 = (uVar9 & 0x7ff0) << 0x11 | (uVar9 ^ uVar9 << 3) >> 0xb;
          *(uint *)(puVar5 + 1) = uVar9;
          if ((double)(CONCAT13(bVar23 ^ bVar19,
                                CONCAT12(bVar22 ^ bVar18,CONCAT11(bVar21 ^ bVar17,bVar20 ^ bVar13)))
                      ^ uVar9) * 2.3283064365386963e-10 <= (double)fVar10) goto LAB_1019f22e0;
        }
        uVar8 = uVar8 - 1;
      } while (uVar8 != 0);
    }
  }
  return;
}



// ===== AreaTriggerItem::apply  @ 0x1019f40a8 =====

/* AreaTriggerItem::apply(TriggerContext const&) const */

void __thiscall AreaTriggerItem::apply(AreaTriggerItem *this,TriggerContext *param_1)

{
  TriggerContext *pTVar1;
  int iVar2;
  uint uVar3;
  int iVar4;
  TriggerContext *pTVar5;
  int iVar6;
  int iVar7;
  uint uVar8;
  uint uVar9;
  long lVar10;
  undefined8 *puVar11;
  undefined8 *puVar12;
  undefined8 *puVar13;
  code *pcVar14;
  bool bVar15;
  bool bVar16;
  int iVar17;
  BoundingBox *this_00;
  TriggerContext *pTVar18;
  int *piVar19;
  void *pvVar20;
  undefined8 *puVar21;
  long lVar22;
  long lVar23;
  ulong uVar24;
  long lVar25;
  int iVar26;
  ulong uVar27;
  ulong uVar28;
  ulong uVar29;
  int iVar30;
  int iVar31;
  undefined8 *puVar32;
  ulong uVar33;
  undefined8 *puVar34;
  int iVar35;
  uint uVar36;
  long *plVar37;
  uint uVar38;
  int iVar39;
  long *plVar40;
  int iVar41;
  undefined8 *puVar42;
  long *plVar43;
  float fVar44;
  float fVar45;
  double dVar46;
  double dVar47;
  byte bVar48;
  byte bVar54;
  byte bVar55;
  byte bVar56;
  byte bVar57;
  byte bVar58;
  byte bVar59;
  undefined8 uVar49;
  ulong uVar50;
  byte bVar60;
  undefined1 *puVar51;
  double dVar52;
  double dVar53;
  undefined8 uVar61;
  double dVar62;
  double dVar63;
  double dVar64;
  double dVar65;
  double dVar66;
  double dVar67;
  float fVar68;
  float fVar69;
  undefined8 *local_288;
  undefined8 *local_220;
  long local_210;
  undefined8 *local_1f0;
  undefined8 *local_1e0;
  TriggerContext *local_1d8;
  AreaTriggerItem *pAStack_1d0;
  TriggerContext *local_1c8;
  AreaTriggerItem *local_1c0;
  undefined8 uStack_1b8;
  undefined8 *local_1b0;
  undefined8 uStack_1a8;
  undefined8 local_1a0;
  undefined8 local_198;
  long local_190;
  long *plStack_188;
  long local_180;
  undefined8 uStack_178;
  long local_170;
  long lStack_168;
  long local_160;
  undefined8 uStack_158;
  undefined8 local_150;
  undefined8 uStack_148;
  undefined8 local_140;
  ulong uStack_138;
  undefined8 uStack_130;
  undefined8 uStack_128;
  undefined8 local_120;
  undefined8 uStack_118;
  undefined8 local_110;
  long local_108 [3];
  long *local_f0;
  undefined8 local_e8;
  undefined8 uStack_e0;
  undefined8 uStack_d8;
  undefined8 uStack_d0;
  undefined8 local_c8;
  long local_b8;
  
  local_b8 = *(long *)PTR____stack_chk_guard_102d481b8;
  pTVar5 = param_1 + 0x40;
  if (this[0x68] != (AreaTriggerItem)0x0) {
    pTVar5 = param_1 + 0x60;
  }
  if (*(int *)(this + 0x50) == 0) {
LAB_1019f53cc:
    if (*(long *)PTR____stack_chk_guard_102d481b8 == local_b8) {
      return;
    }
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail();
  }
  uVar38 = 0;
  pTVar1 = param_1 + 0xa8;
LAB_1019f4178:
  fVar44 = *(float *)(this + 0x54);
  if (fVar44 == 1.0) {
LAB_1019f4228:
    pTVar18 = param_1 + 0x68;
    if (*(int *)(param_1 + 0x68) == 0x7fffffff) {
      lVar22 = *(long *)(param_1 + 0x60);
      if (lVar22 == 0) {
                    /* WARNING: Subroutine does not return */
        Logging::logAndAbortOrThrow
                  ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/ShootingTarget.cpp"
                   ,0xc,9,"Unset shooting target");
      }
      pTVar18 = (TriggerContext *)(lVar22 + 0x50);
    }
    uVar49 = *(undefined8 *)pTVar18;
    if (this[0x69] == (AreaTriggerItem)0x0) {
      if (*(long *)(param_1 + 0xe8) == 0) {
        uVar49 = selectTargetPosition(this,uVar49,*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
        puVar21 = *(undefined8 **)(this + 8);
        puVar32 = *(undefined8 **)(this + 0x10);
        if (puVar21 != puVar32) goto LAB_1019f49bc;
      }
      else {
        uVar49 = selectTargetPosition(this,uVar49,*(undefined8 *)(_global + 0x250));
        puVar21 = *(undefined8 **)(this + 8);
        puVar32 = *(undefined8 **)(this + 0x10);
        if (puVar21 != puVar32) {
LAB_1019f49bc:
          do {
            plVar40 = (long *)*puVar21;
            uStack_128 = *(undefined8 *)(param_1 + 0x88);
            uStack_130 = *(undefined8 *)(param_1 + 0x80);
            uStack_118 = *(undefined8 *)(param_1 + 0x98);
            local_120 = *(undefined8 *)(param_1 + 0x90);
            uStack_148 = *(undefined8 *)(param_1 + 0x68);
            local_150 = *(undefined8 *)(param_1 + 0x60);
            uStack_138 = *(ulong *)(param_1 + 0x78);
            local_140 = *(undefined8 *)(param_1 + 0x70);
            lStack_168 = *(long *)(param_1 + 0x48);
            local_170 = *(long *)(param_1 + 0x40);
            uStack_158 = *(undefined8 *)(param_1 + 0x58);
            local_160 = *(long *)(param_1 + 0x50);
            plStack_188 = *(long **)(param_1 + 0x28);
            local_190 = *(long *)(param_1 + 0x20);
            uStack_178 = *(undefined8 *)(param_1 + 0x38);
            local_180 = *(long *)(param_1 + 0x30);
            uStack_1a8 = *(undefined8 **)(param_1 + 8);
            local_1b0 = *(undefined8 **)param_1;
            local_198 = *(ulong *)(param_1 + 0x18);
            local_1a0 = *(undefined8 **)(param_1 + 0x10);
            local_110 = *(undefined8 *)(param_1 + 0xa0);
            pTVar18 = *(TriggerContext **)(param_1 + 0xc0);
            if (pTVar18 == (TriggerContext *)0x0) {
              local_f0 = (long *)0x0;
            }
            else if (pTVar18 == pTVar1) {
              local_f0 = local_108;
              (**(code **)(*(long *)pTVar1 + 0x18))(pTVar1,local_108);
            }
            else {
              local_f0 = (long *)(**(code **)(*(long *)pTVar18 + 0x10))();
            }
            uStack_e0 = *(undefined8 *)(param_1 + 0xd0);
            local_e8 = *(undefined8 *)(param_1 + 200);
            uStack_d0 = *(undefined8 *)(param_1 + 0xe0);
            uStack_d8 = *(undefined8 *)(param_1 + 0xd8);
            local_c8 = *(undefined8 *)(param_1 + 0xe8);
            if ((TriggerContext *)&local_170 != pTVar5) {
              local_170 = *(long *)pTVar5;
              if ((local_170 != 0) && ((*(ushort *)(local_170 + 0x58) & 0x10) != 0)) {
                local_170 = 0;
              }
              local_160 = *(long *)(pTVar5 + 0x10);
              lStack_168 = *(long *)(pTVar5 + 8);
              uStack_158 = CONCAT35(uStack_158._5_3_,*(undefined5 *)(pTVar5 + 0x18));
            }
            local_150 = 0;
            uStack_138 = uStack_138 & 0xffffff0000000000;
            uStack_148 = uVar49;
            local_140 = uVar49;
            (**(code **)(*plVar40 + 0x18))(plVar40,&local_1b0);
            if (local_f0 == local_108) {
              lVar22 = 4;
              plVar40 = local_108;
LAB_1019f49a4:
              (**(code **)(*plVar40 + lVar22 * 8))();
            }
            else if (local_f0 != (long *)0x0) {
              lVar22 = 5;
              plVar40 = local_f0;
              goto LAB_1019f49a4;
            }
            puVar21 = puVar21 + 1;
          } while (puVar21 != puVar32);
        }
      }
    }
    else {
      iVar31 = (int)((ulong)uVar49 >> 0x20);
      iVar35 = (int)uVar49;
      local_1d8 = param_1;
      pAStack_1d0 = this;
      local_1c8 = pTVar5;
      if ((this[0x6a] == (AreaTriggerItem)0x0) || (uVar50 = (ulong)(byte)param_1[0x10], uVar50 == 0)
         ) {
        puVar51 = (undefined1 *)(*(double *)(this + 0x58) * 256.0);
        bVar15 = true;
        if ((!NAN((double)puVar51)) && (bVar15 = false, !NAN((double)puVar51))) {
          bVar15 = (double)puVar51 == INFINITY;
        }
        bVar16 = true;
        if ((!bVar15) && (bVar16 = false, !NAN((double)puVar51))) {
          bVar16 = (double)puVar51 == -INFINITY;
        }
        if (bVar16) {
                    /* WARNING: Subroutine does not return */
          Logging::logAndAbortOrThrow
                    ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Util/FixedPointNumber.hpp"
                     ,0x1f,9,"double value not in range for fixed point number: %f");
        }
        if ((double)puVar51 <= -2147483648.0) {
          puVar51 = &DAT_c1e0000000000000;
        }
        NEON_fminnm(puVar51,0x41dfffffffc00000);
        local_1e0 = (undefined8 *)0x0;
        local_1f0 = (undefined8 *)0x0;
        local_1c0 = this;
        uStack_1b8 = uVar49;
        HeuristicEntityIterator<Surface>::HeuristicEntityIterator
                  ((Surface *)&local_1b0,*(BoundingBox **)(param_1 + 8));
        puVar32 = uStack_1a8;
        puVar21 = local_1b0;
        if (plStack_188 != (long *)0x0) {
          puVar42 = (undefined8 *)0x0;
          iVar26 = (int)uStack_1a8;
          uVar29 = (ulong)uStack_1a8 & 0xffffffff;
          uVar8 = uStack_1a8._4_4_;
          iVar7 = (int)local_1a0;
          uVar9 = local_1a0._4_4_;
          local_210 = local_190;
          uVar50 = local_198 & 0xffffffff;
          iVar30 = (int)uStack_1a8 >> 4;
          uVar28 = (ulong)uStack_1a8 & 0xf;
          plVar40 = plStack_188;
          lVar23 = local_180;
          uVar36 = local_198._4_4_;
          lVar22 = local_210;
          do {
            local_210 = lVar22;
            lVar22 = (**(code **)(*plVar40 + 0xc60))(plVar40);
            lVar25 = local_210;
            if (lVar22 != 0) {
              if (this[0x6c] == (AreaTriggerItem)0x1) {
                iVar41 = (int)plVar40[0xc];
                if (*(short *)((long)plVar40 + 0x6c) == 0) {
                  iVar2 = iVar35;
                  if (iVar35 <= *(int *)((long)plVar40 + 0x5c)) {
                    iVar2 = *(int *)((long)plVar40 + 0x5c);
                  }
                  if (*(int *)((long)plVar40 + 100) <= iVar2) {
                    iVar2 = *(int *)((long)plVar40 + 100);
                  }
                  iVar39 = iVar31;
                  if (iVar31 <= iVar41) {
                    iVar39 = iVar41;
                  }
                  if ((int)plVar40[0xd] <= iVar39) {
                    iVar39 = (int)plVar40[0xd];
                  }
                  if (*(double *)(this + 0x60) <
                      (double)((long)(iVar31 - iVar39) * (long)(iVar31 - iVar39) +
                              (long)(iVar35 - iVar2) * (long)(iVar35 - iVar2)) * 1.52587890625e-05)
                  goto LAB_1019f4588;
                }
                else {
                  dVar47 = (double)(*(int *)((long)plVar40 + 100) - *(int *)((long)plVar40 + 0x5c));
                  dVar53 = (double)((int)plVar40[0xd] - iVar41);
                  dVar46 = ((double)iVar35 + (double)iVar35) -
                           (double)(*(int *)((long)plVar40 + 0x5c) + *(int *)((long)plVar40 + 100));
                  dVar52 = ((double)iVar31 + (double)iVar31) - (double)(iVar41 + (int)plVar40[0xd]);
                  dVar67 = (double)((float)(int)*(short *)((long)plVar40 + 0x6c) * 3.051851e-05);
                  dVar64 = (double)((float)-(int)*(short *)((long)plVar40 + 0x6e) * 3.051851e-05);
                  dVar65 = ABS(dVar52 * dVar67 + dVar46 * dVar64);
                  dVar46 = ABS(dVar46 * dVar67 - dVar52 * dVar64);
                  dVar67 = dVar65 - dVar47;
                  dVar64 = dVar67 * dVar67;
                  dVar52 = dVar46 - dVar53;
                  if (dVar67 <= 0.0) {
                    dVar67 = 0.0;
                  }
                  dVar64 = dVar64 + dVar52 * dVar52;
                  if (dVar46 < dVar53) {
                    dVar64 = dVar67 * dVar67;
                  }
                  if (dVar52 <= 0.0) {
                    dVar52 = 0.0;
                  }
                  if (dVar65 < dVar47) {
                    dVar64 = dVar52 * dVar52;
                  }
                  if (*(double *)(this + 0x60) < dVar64 * 3.814697265625e-06) {
LAB_1019f4588:
                    this_00 = (BoundingBox *)(**(code **)(*plVar40 + 0x648))(plVar40);
                    if ((this_00 == (BoundingBox *)0x0) ||
                       (dVar46 = (double)::BoundingBox::distanceFromPointSquared
                                                   (this_00,(MapPosition *)&uStack_1b8),
                       *(double *)(this + 0x60) < dVar46)) goto LAB_1019f46a0;
                  }
                }
LAB_1019f45bc:
                if (puVar42 == local_1e0) {
                  uVar24 = (long)puVar42 - (long)local_1f0;
                  lVar22 = (long)uVar24 >> 3;
                  uVar33 = lVar22 + 1;
                  if (uVar33 >> 0x3d != 0) {
                    /* WARNING: Subroutine does not return */
                    std::vector<Entity*,std::allocator<Entity*>>::__throw_length_error_abi_v160006_
                              ();
                  }
                  uVar27 = uVar24 >> 2;
                  if (uVar24 >> 2 <= uVar33) {
                    uVar27 = uVar33;
                  }
                  if (0x7ffffffffffffff7 < uVar24) {
                    uVar27 = 0x1fffffffffffffff;
                  }
                  if (uVar27 == 0) {
                    pvVar20 = (void *)0x0;
                    puVar34 = (undefined8 *)(lVar22 * 8);
                    *puVar34 = plVar40;
                  }
                  else {
                    if (uVar27 >> 0x3d != 0) {
                    /* WARNING: Subroutine does not return */
                      std::__throw_bad_array_new_length_abi_v160006_();
                    }
                    pvVar20 = operator_new(uVar27 << 3);
                    puVar34 = (undefined8 *)((long)pvVar20 + lVar22 * 8);
                    *puVar34 = plVar40;
                  }
                  puVar11 = puVar34 + 1;
                  puVar12 = puVar42;
                  while (puVar42 != local_1f0) {
                    puVar42 = puVar42 + -1;
                    puVar34 = puVar34 + -1;
                    *puVar34 = *puVar42;
                    puVar12 = local_1f0;
                  }
                  local_1e0 = (undefined8 *)((long)pvVar20 + uVar27 * 8);
                  local_1f0 = puVar34;
                  puVar42 = puVar11;
                  if (puVar12 != (undefined8 *)0x0) {
                    operator_delete(puVar12);
                  }
                }
                else {
                  *puVar42 = plVar40;
                  puVar42 = puVar42 + 1;
                }
              }
              else {
                if (this[0x6c] != (AreaTriggerItem)0x0) {
                    /* WARNING: Subroutine does not return */
                  Logging::logEnumAndAbortOrThrow<AreaTriggerItem::CollisionMode>
                            ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/AreaTriggerItem.cpp"
                             ,0x96,9);
                }
                dVar46 = (double)((int)plVar40[10] - iVar35) * 0.00390625;
                dVar52 = (double)(*(int *)((long)plVar40 + 0x54) - iVar31) * 0.00390625;
                if (dVar46 * dVar46 + dVar52 * dVar52 <= *(double *)(this + 0x60))
                goto LAB_1019f45bc;
              }
            }
LAB_1019f46a0:
            do {
              lVar22 = lVar25;
              iVar41 = (int)uVar50;
              if (lVar23 == 0) {
                if (iVar41 < iVar7) {
                  uVar3 = iVar41 + 1;
                  iVar41 = (int)uVar3 >> 4;
                  iVar2 = (int)uVar36 >> 4;
                  if ((local_210 == 0) ||
                     (*(int *)(local_210 + 0xc48) != iVar41 || *(int *)(local_210 + 0xc4c) != iVar2)
                     ) {
                    if ((-*(int *)((long)puVar21 + 0x24) <= iVar41) &&
                       (iVar41 = *(int *)((long)puVar21 + 0x24) + iVar41,
                       iVar41 < *(int *)(puVar21 + 4))) {
                      plVar40 = (long *)(puVar21[3] + (long)iVar41 * 0x10);
                      if (plVar40 != (long *)0x0) {
                        lVar22 = puVar21[3] + (long)iVar41 * 0x10;
                        iVar41 = *(int *)(lVar22 + 0xc);
                        if ((((-iVar41 <= iVar2) &&
                             (iVar41 = iVar41 + iVar2, iVar41 < *(int *)(lVar22 + 8))) &&
                            (plVar40 = (long *)(*plVar40 + (long)iVar41 * 8), plVar40 != (long *)0x0
                            )) && (local_210 = *plVar40, lVar22 = local_210, local_210 != 0))
                        goto LAB_1019f4780;
                      }
                    }
                    local_210 = 0;
                    lVar23 = 0;
                    lVar25 = 0;
                    uVar50 = (ulong)(uVar3 | 0xf);
                  }
                  else {
LAB_1019f4780:
                    lVar23 = *(long *)(local_210 + (ulong)(uVar3 & 0xf) * 0x80 +
                                       (ulong)(uVar36 & 0xf) * 8 + 0xc50);
                    lVar25 = lVar22;
                    uVar50 = (ulong)uVar3;
                  }
                  goto LAB_1019f46a0;
                }
                puVar34 = local_1f0;
                if ((int)uVar9 <= (int)uVar36) goto joined_r0x0001019f493c;
                uVar36 = uVar36 + 1;
                iVar41 = (int)uVar36 >> 4;
                if (((local_210 == 0) || (*(int *)(local_210 + 0xc48) != iVar30)) ||
                   (lVar10 = local_210, *(int *)(local_210 + 0xc4c) != iVar41)) {
                  local_210 = 0;
                  lVar23 = 0;
                  uVar50 = (ulong)puVar32 & 0xffffffff | 0xf;
                  lVar25 = 0;
                  if (iVar30 < -*(int *)((long)puVar21 + 0x24)) goto LAB_1019f46a0;
                  local_210 = 0;
                  lVar23 = 0;
                  iVar2 = *(int *)((long)puVar21 + 0x24) + iVar30;
                  uVar50 = (ulong)puVar32 & 0xffffffff | 0xf;
                  lVar25 = 0;
                  if (*(int *)(puVar21 + 4) <= iVar2) goto LAB_1019f46a0;
                  local_210 = 0;
                  lVar23 = 0;
                  plVar40 = (long *)(puVar21[3] + (long)iVar2 * 0x10);
                  uVar50 = (ulong)puVar32 & 0xffffffff | 0xf;
                  lVar25 = 0;
                  if (plVar40 == (long *)0x0) goto LAB_1019f46a0;
                  local_210 = 0;
                  lVar23 = 0;
                  lVar22 = puVar21[3] + (long)iVar2 * 0x10;
                  iVar2 = *(int *)(lVar22 + 0xc);
                  uVar50 = (ulong)puVar32 & 0xffffffff | 0xf;
                  lVar25 = 0;
                  if (iVar41 < -iVar2) goto LAB_1019f46a0;
                  local_210 = 0;
                  lVar23 = 0;
                  iVar2 = iVar2 + iVar41;
                  uVar50 = (ulong)puVar32 & 0xffffffff | 0xf;
                  lVar25 = 0;
                  if (*(int *)(lVar22 + 8) <= iVar2) goto LAB_1019f46a0;
                  local_210 = 0;
                  lVar23 = 0;
                  plVar40 = (long *)(*plVar40 + (long)iVar2 * 8);
                  uVar50 = (ulong)puVar32 & 0xffffffff | 0xf;
                  lVar25 = 0;
                  if (plVar40 == (long *)0x0) goto LAB_1019f46a0;
                  local_210 = 0;
                  lVar23 = 0;
                  lVar22 = *plVar40;
                  uVar50 = (ulong)puVar32 & 0xffffffff | 0xf;
                  lVar10 = lVar22;
                  lVar25 = 0;
                  if (lVar22 == 0) goto LAB_1019f46a0;
                }
                local_210 = lVar10;
                lVar23 = *(long *)(local_210 + uVar28 * 0x80 + (ulong)(uVar36 & 0xf) * 8 + 0xc50);
                lVar25 = lVar22;
                uVar50 = uVar29;
                goto LAB_1019f46a0;
              }
              plVar40 = *(long **)(lVar23 + 0x20);
              lVar23 = *(long *)(lVar23 + 8);
              iVar2 = (int)plVar40[10] >> 9;
              uVar3 = *(int *)((long)plVar40 + 0x54) >> 9;
              if (iVar2 <= iVar26) {
                iVar2 = iVar26;
              }
              if (iVar7 <= iVar2) {
                iVar2 = iVar7;
              }
              if ((int)uVar3 <= (int)uVar8) {
                uVar3 = uVar8;
              }
              if ((int)uVar9 <= (int)uVar3) {
                uVar3 = uVar9;
              }
              lVar25 = lVar22;
            } while (iVar2 != iVar41 || uVar3 != uVar36);
          } while( true );
        }
      }
      else {
        lVar22 = *(long *)(param_1 + 8);
        dVar46 = *(double *)(this + 0x58);
        uStack_1a8 = (undefined8 *)0x0;
        local_1a0 = (undefined8 *)0x0;
        local_1b0 = (undefined8 *)0x0;
        puVar51 = (undefined1 *)(dVar46 * 256.0);
        bVar15 = true;
        if ((!NAN((double)puVar51)) && (bVar15 = false, !NAN((double)puVar51))) {
          bVar15 = (double)puVar51 == INFINITY;
        }
        bVar16 = true;
        if ((!bVar15) && (bVar16 = false, !NAN((double)puVar51))) {
          bVar16 = (double)puVar51 == -INFINITY;
        }
        if (bVar16) {
                    /* WARNING: Subroutine does not return */
          Logging::logAndAbortOrThrow
                    ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Util/FixedPointNumber.hpp"
                     ,0x1f,9,"double value not in range for fixed point number: %f");
        }
        lVar23 = *(long *)(lVar22 + 0xb8);
        if (uVar50 < (ulong)(*(long *)(lVar23 + 0x3d0) - *(long *)(lVar23 + 0x3c8) >> 3)) {
          lVar25 = *(long *)(*(long *)(lVar23 + 0x3c8) + uVar50 * 8);
        }
        else {
          lVar25 = 0;
        }
        if ((double)puVar51 <= -2147483648.0) {
          puVar51 = &DAT_c1e0000000000000;
        }
        dVar52 = (double)NEON_fminnm(puVar51,0x41dfffffffc00000);
        iVar26 = (int)dVar52;
        iVar30 = iVar35 - iVar26 >> 0xd;
        if (*(byte *)(lVar25 + 8) == 3) {
          uVar29 = 0;
          uVar28 = *(ulong *)(lVar25 + 0x6e0);
        }
        else {
          uVar28 = *(ulong *)(lVar25 + 0x6e0);
          uVar29 = ((uVar28 | 1L << ((ulong)(*(byte *)(lVar25 + 8) - 1) & 0x3f)) ^
                   0xffffffffffffffff) & 0xfffffffffffffffb;
        }
        iVar7 = iVar26 + iVar35 >> 0xd;
        if (iVar30 <= iVar7) {
          iVar41 = iVar31 - iVar26 >> 0xd;
          iVar26 = iVar26 + iVar31 >> 0xd;
          if (iVar41 <= iVar26) {
            puVar34 = (undefined8 *)0x0;
            puVar42 = (undefined8 *)0x0;
            puVar32 = (undefined8 *)0x0;
            uVar28 = uVar29 & ((*(ulong *)(lVar25 + 0x6d8) | uVar28) ^ 0xffffffffffffffff) &
                     *(ulong *)(lVar23 + 0x3f0);
            local_288 = (undefined8 *)0x0;
            dVar52 = (double)iVar35 + (double)iVar35;
            dVar67 = (double)iVar31 + (double)iVar31;
            puVar21 = (undefined8 *)0x0;
            local_220 = (undefined8 *)0x0;
            do {
              iVar39 = iVar30 * 0x2000;
              iVar2 = iVar35;
              if (iVar35 <= iVar39) {
                iVar2 = iVar39;
              }
              if (iVar39 + 0x2000 <= iVar2) {
                iVar2 = iVar39 + 0x2000;
              }
              if (uVar28 != 0) {
                iVar39 = iVar41;
                do {
                  iVar6 = iVar39 * 0x2000;
                  iVar17 = iVar31;
                  if (iVar31 <= iVar6) {
                    iVar17 = iVar6;
                  }
                  if (iVar6 + 0x2000 <= iVar17) {
                    iVar17 = iVar6 + 0x2000;
                  }
                  puVar11 = puVar21;
                  if ((((double)((long)(iVar35 - iVar2) * (long)(iVar35 - iVar2) +
                                (long)(iVar31 - iVar17) * (long)(iVar31 - iVar17)) *
                        1.52587890625e-05 <= dVar46 * dVar46) &&
                      (-*(int *)(lVar22 + 0x24) <= iVar30)) &&
                     (iVar17 = *(int *)(lVar22 + 0x24) + iVar30, iVar17 < *(int *)(lVar22 + 0x20)))
                  {
                    plVar40 = (long *)(*(long *)(lVar22 + 0x18) + (long)iVar17 * 0x10);
                    if (plVar40 != (long *)0x0) {
                      lVar23 = *(long *)(lVar22 + 0x18) + (long)iVar17 * 0x10;
                      iVar17 = *(int *)(lVar23 + 0xc);
                      if (((-iVar17 <= iVar39) &&
                          (iVar17 = iVar17 + iVar39, iVar17 < *(int *)(lVar23 + 8))) &&
                         ((plVar40 = (long *)(*plVar40 + (long)iVar17 * 8), plVar40 != (long *)0x0
                          && (lVar23 = *plVar40, lVar23 != 0)))) {
                        uVar33 = (ulong)*(byte *)((long)&ForceSet::Iterator::findFirstSet()::index +
                                                 ((uVar28 & -uVar28) * 0x3f79d71b4cb0a89 >> 0x3a) *
                                                 4);
                        uVar29 = uVar28;
                        local_220 = puVar42;
                        do {
                          uVar24 = (ulong)(((int)uVar33 + 1U & 0xff) - 1);
                          plVar40 = (long *)(*(long *)(lVar23 + 0x1518) + uVar24 * 0x10);
                          puVar42 = puVar34;
                          if (uVar24 < (ulong)(*(long *)(lVar23 + 0x1520) -
                                               *(long *)(lVar23 + 0x1518) >> 4) &&
                              plVar40 != (long *)0x0) {
                            puVar11 = local_220;
                            for (plVar37 = (long *)*plVar40; local_220 = puVar11, plVar37 != plVar40
                                ; plVar37 = (long *)*plVar37) {
                              plVar43 = (long *)plVar37[2];
                              fVar44 = *(float *)(plVar43 + 0x11);
                              if ((((0.0 < fVar44) &&
                                   ((fVar68 = *(float *)((long)plVar43 + 0x94), fVar68 == 0.0 ||
                                    (fVar69 = *(float *)(plVar43[9] + 0x5b4),
                                    fVar45 = (float)(**(code **)(*plVar43 + 0x11c8))(plVar43),
                                    fVar68 < (fVar44 + fVar69) * fVar45)))) &&
                                  ((*(ushort *)(plVar43 + 0xb) >> 8 & 1) == 0)) &&
                                 (iVar17 = (**(code **)(*plVar43 + 0x698))(plVar43,uVar50),
                                 iVar17 != 0)) {
                                iVar17 = (int)plVar43[0xc];
                                if (*(short *)((long)plVar43 + 0x6c) == 0) {
                                  iVar6 = iVar35;
                                  if (iVar35 <= *(int *)((long)plVar43 + 0x5c)) {
                                    iVar6 = *(int *)((long)plVar43 + 0x5c);
                                  }
                                  if (*(int *)((long)plVar43 + 100) <= iVar6) {
                                    iVar6 = *(int *)((long)plVar43 + 100);
                                  }
                                  iVar4 = iVar31;
                                  if (iVar31 <= iVar17) {
                                    iVar4 = iVar17;
                                  }
                                  if ((int)plVar43[0xd] <= iVar4) {
                                    iVar4 = (int)plVar43[0xd];
                                  }
                                  dVar47 = (double)((long)(iVar31 - iVar4) * (long)(iVar31 - iVar4)
                                                   + (long)(iVar35 - iVar6) * (long)(iVar35 - iVar6)
                                                   ) * 1.52587890625e-05;
                                }
                                else {
                                  dVar62 = (double)(*(int *)((long)plVar43 + 100) -
                                                   *(int *)((long)plVar43 + 0x5c));
                                  dVar63 = (double)((int)plVar43[0xd] - iVar17);
                                  dVar47 = dVar52 - (double)(*(int *)((long)plVar43 + 0x5c) +
                                                            *(int *)((long)plVar43 + 100));
                                  dVar53 = dVar67 - (double)(iVar17 + (int)plVar43[0xd]);
                                  dVar64 = (double)((float)(int)*(short *)((long)plVar43 + 0x6c) *
                                                   3.051851e-05);
                                  dVar65 = (double)((float)-(int)*(short *)((long)plVar43 + 0x6e) *
                                                   3.051851e-05);
                                  dVar66 = ABS(dVar53 * dVar64 + dVar47 * dVar65);
                                  dVar53 = ABS(dVar47 * dVar64 - dVar53 * dVar65);
                                  dVar65 = dVar66 - dVar62;
                                  dVar47 = dVar65 * dVar65;
                                  dVar64 = dVar53 - dVar63;
                                  if (dVar65 <= 0.0) {
                                    dVar65 = 0.0;
                                  }
                                  dVar47 = dVar47 + dVar64 * dVar64;
                                  if (dVar53 < dVar63) {
                                    dVar47 = dVar65 * dVar65;
                                  }
                                  if (dVar64 <= 0.0) {
                                    dVar64 = 0.0;
                                  }
                                  if (dVar66 < dVar62) {
                                    dVar47 = dVar64 * dVar64;
                                  }
                                  dVar47 = dVar47 * 3.814697265625e-06;
                                }
                                if (((dVar47 <= dVar46 * dVar46) &&
                                    ((((lVar25 = (**(code **)(*plVar43 + 0xb38))(plVar43),
                                       lVar25 == 0 || (*(long *)(lVar25 + 0x568) == 0)) ||
                                      (lVar25 = (**(code **)(**(long **)(*(long *)(lVar25 + 0x568) +
                                                                        0x28) + 0xb18))(),
                                      lVar25 == 0)) ||
                                     ((*(long *)(lVar25 + 0x218) != 0 &&
                                      (*(long *)(*(long *)(lVar25 + 0x218) + 0x140) != 0)))))) &&
                                   (lVar25 = (**(code **)(*plVar43 + 0xc60))(plVar43), lVar25 != 0))
                                {
                                  if (this[0x6c] == (AreaTriggerItem)0x1) {
                                    iVar17 = (int)plVar43[0xc];
                                    if (*(short *)((long)plVar43 + 0x6c) == 0) {
                                      iVar6 = iVar35;
                                      if (iVar35 <= *(int *)((long)plVar43 + 0x5c)) {
                                        iVar6 = *(int *)((long)plVar43 + 0x5c);
                                      }
                                      if (*(int *)((long)plVar43 + 100) <= iVar6) {
                                        iVar6 = *(int *)((long)plVar43 + 100);
                                      }
                                      iVar4 = iVar31;
                                      if (iVar31 <= iVar17) {
                                        iVar4 = iVar17;
                                      }
                                      if ((int)plVar43[0xd] <= iVar4) {
                                        iVar4 = (int)plVar43[0xd];
                                      }
                                      if (*(double *)(this + 0x60) <
                                          (double)((long)(iVar31 - iVar4) * (long)(iVar31 - iVar4) +
                                                  (long)(iVar35 - iVar6) * (long)(iVar35 - iVar6)) *
                                          1.52587890625e-05) goto LAB_1019f5154;
                                    }
                                    else {
                                      dVar65 = (double)(*(int *)((long)plVar43 + 100) -
                                                       *(int *)((long)plVar43 + 0x5c));
                                      dVar62 = (double)((int)plVar43[0xd] - iVar17);
                                      dVar47 = dVar52 - (double)(*(int *)((long)plVar43 + 0x5c) +
                                                                *(int *)((long)plVar43 + 100));
                                      dVar53 = dVar67 - (double)(iVar17 + (int)plVar43[0xd]);
                                      dVar64 = (double)((float)(int)*(short *)((long)plVar43 + 0x6c)
                                                       * 3.051851e-05);
                                      dVar63 = (double)((float)-(int)*(short *)((long)plVar43 + 0x6e
                                                                               ) * 3.051851e-05);
                                      dVar66 = ABS(dVar53 * dVar64 + dVar47 * dVar63);
                                      dVar47 = ABS(dVar47 * dVar64 - dVar53 * dVar63);
                                      dVar64 = dVar66 - dVar65;
                                      dVar63 = dVar64 * dVar64;
                                      dVar53 = dVar47 - dVar62;
                                      if (dVar64 <= 0.0) {
                                        dVar64 = 0.0;
                                      }
                                      dVar63 = dVar63 + dVar53 * dVar53;
                                      if (dVar47 < dVar62) {
                                        dVar63 = dVar64 * dVar64;
                                      }
                                      if (dVar53 <= 0.0) {
                                        dVar53 = 0.0;
                                      }
                                      if (dVar66 < dVar65) {
                                        dVar63 = dVar53 * dVar53;
                                      }
                                      if (*(double *)(this + 0x60) < dVar63 * 3.814697265625e-06) {
LAB_1019f5154:
                                        piVar19 = (int *)(**(code **)(*plVar43 + 0x648))(plVar43);
                                        if (piVar19 != (int *)0x0) {
                                          iVar17 = piVar19[1];
                                          if ((short)piVar19[4] == 0) {
                                            iVar6 = iVar35;
                                            if (iVar35 <= *piVar19) {
                                              iVar6 = *piVar19;
                                            }
                                            if (piVar19[2] <= iVar6) {
                                              iVar6 = piVar19[2];
                                            }
                                            iVar4 = iVar31;
                                            if (iVar31 <= iVar17) {
                                              iVar4 = iVar17;
                                            }
                                            if (piVar19[3] <= iVar4) {
                                              iVar4 = piVar19[3];
                                            }
                                            if ((double)((long)(iVar31 - iVar4) *
                                                         (long)(iVar31 - iVar4) +
                                                        (long)(iVar35 - iVar6) *
                                                        (long)(iVar35 - iVar6)) * 1.52587890625e-05
                                                <= *(double *)(this + 0x60)) goto LAB_1019f52a4;
                                          }
                                          else {
                                            dVar65 = (double)(piVar19[2] - *piVar19);
                                            dVar62 = (double)(piVar19[3] - iVar17);
                                            dVar47 = dVar52 - (double)(*piVar19 + piVar19[2]);
                                            dVar53 = dVar67 - (double)(iVar17 + piVar19[3]);
                                            dVar64 = (double)((float)(int)(short)piVar19[4] *
                                                             3.051851e-05);
                                            dVar63 = (double)((float)-(int)*(short *)((long)piVar19
                                                                                     + 0x12) *
                                                             3.051851e-05);
                                            dVar66 = ABS(dVar53 * dVar64 + dVar47 * dVar63);
                                            dVar47 = ABS(dVar47 * dVar64 - dVar53 * dVar63);
                                            dVar64 = dVar66 - dVar65;
                                            dVar63 = dVar64 * dVar64;
                                            dVar53 = dVar47 - dVar62;
                                            if (dVar64 <= 0.0) {
                                              dVar64 = 0.0;
                                            }
                                            dVar63 = dVar63 + dVar53 * dVar53;
                                            if (dVar47 < dVar62) {
                                              dVar63 = dVar64 * dVar64;
                                            }
                                            if (dVar53 <= 0.0) {
                                              dVar53 = 0.0;
                                            }
                                            if (dVar66 < dVar65) {
                                              dVar63 = dVar53 * dVar53;
                                            }
                                            if (dVar63 * 3.814697265625e-06 <=
                                                *(double *)(this + 0x60)) goto LAB_1019f52a4;
                                          }
                                        }
                                        goto LAB_1019f4dd4;
                                      }
                                    }
LAB_1019f52a4:
                                    if (puVar32 < local_288) {
                                      puVar42 = puVar32 + 1;
                                      *puVar32 = plVar43;
                                      puVar32 = puVar42;
                                    }
                                    else {
                                      lVar25 = (long)puVar32 - (long)puVar11 >> 3;
                                      uVar24 = lVar25 + 1;
                                      if (uVar24 >> 0x3d != 0) {
                                        local_1b0 = puVar11;
                                        uStack_1a8 = puVar42;
                                        local_1a0 = local_288;
                                        std::
                                        vector<EntityWithOwner*,std::allocator<EntityWithOwner*>>::
                                        __throw_length_error_abi_v160006_();
                    /* WARNING: Does not return */
                                        pcVar14 = (code *)SoftwareBreakpoint(1,0x1019f54fc);
                                        (*pcVar14)();
                                      }
                                      uVar27 = (ulong)((long)local_288 - (long)puVar11) >> 2;
                                      if (uVar27 <= uVar24) {
                                        uVar27 = uVar24;
                                      }
                                      if (0x7ffffffffffffff7 <
                                          (ulong)((long)local_288 - (long)puVar11)) {
                                        uVar27 = 0x1fffffffffffffff;
                                      }
                                      if (uVar27 == 0) {
                                        pvVar20 = (void *)0x0;
                                        local_220 = (undefined8 *)(lVar25 * 8);
                                        puVar42 = local_220 + 1;
                                        *local_220 = plVar43;
                                        if (puVar32 == puVar11) goto LAB_1019f5370;
LAB_1019f5324:
                                        do {
                                          puVar32 = puVar32 + -1;
                                          local_220 = local_220 + -1;
                                          *local_220 = *puVar32;
                                        } while (puVar32 != puVar11);
                                        local_288 = (undefined8 *)((long)pvVar20 + uVar27 * 8);
                                        puVar32 = puVar42;
                                      }
                                      else {
                                        if (uVar27 >> 0x3d != 0) {
                                          local_1b0 = puVar11;
                                          uStack_1a8 = puVar34;
                                          local_1a0 = local_288;
                    /* WARNING: Subroutine does not return */
                                          std::__throw_bad_array_new_length_abi_v160006_();
                                        }
                                        pvVar20 = operator_new(uVar27 << 3);
                                        local_220 = (undefined8 *)((long)pvVar20 + lVar25 * 8);
                                        puVar42 = local_220 + 1;
                                        *local_220 = plVar43;
                                        if (puVar32 != puVar11) goto LAB_1019f5324;
LAB_1019f5370:
                                        local_288 = (undefined8 *)((long)pvVar20 + uVar27 * 8);
                                        puVar32 = puVar42;
                                      }
                                      puVar42 = puVar32;
                                      if (puVar11 != (undefined8 *)0x0) {
                                        operator_delete(puVar11);
                                      }
                                    }
                                  }
                                  else {
                                    if (this[0x6c] != (AreaTriggerItem)0x0) {
                                      local_1b0 = puVar11;
                                      uStack_1a8 = puVar21;
                                      local_1a0 = local_288;
                    /* WARNING: Subroutine does not return */
                                      Logging::
                                      logEnumAndAbortOrThrow<AreaTriggerItem::CollisionMode>
                                                ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/AreaTriggerItem.cpp"
                                                 ,0x96,9);
                                    }
                                    dVar47 = (double)((int)plVar43[10] - iVar35) * 0.00390625;
                                    dVar53 = (double)(*(int *)((long)plVar43 + 0x54) - iVar31) *
                                             0.00390625;
                                    if (dVar47 * dVar47 + dVar53 * dVar53 <=
                                        *(double *)(this + 0x60)) goto LAB_1019f52a4;
                                  }
                                }
                              }
LAB_1019f4dd4:
                              puVar11 = local_220;
                            }
                          }
                          puVar34 = puVar42;
                          uVar29 = -2L << (uVar33 & 0x3f) & uVar29;
                          if (uVar29 == 0) {
                            uVar33 = 0;
                          }
                          else {
                            uVar33 = (ulong)*(uint *)((long)&ForceSet::Iterator::findFirstSet()::
                                                             index +
                                                     ((uVar29 & -uVar29) * 0x3f79d71b4cb0a89 >> 0x38
                                                     & 0xfc));
                          }
                          uVar33 = uVar33 & 0xff;
                          puVar11 = puVar34;
                          puVar42 = local_220;
                        } while (uVar33 != 0 || uVar29 != 0);
                      }
                    }
                  }
                  puVar21 = puVar11;
                  bVar15 = iVar39 != iVar26;
                  iVar39 = iVar39 + 1;
                } while (bVar15);
              }
              bVar15 = iVar30 != iVar7;
              iVar30 = iVar30 + 1;
              puVar11 = puVar42;
              puVar12 = local_220;
              puVar13 = local_288;
            } while (bVar15);
            for (; local_1a0 = puVar13, local_1b0 = puVar12, uStack_1a8 = puVar21,
                puVar11 != puVar34; puVar11 = puVar11 + 1) {
              ::const::$_1::operator()((__1 *)&local_1d8,(Entity *)*puVar11);
              puVar21 = uStack_1a8;
              puVar12 = local_1b0;
              puVar13 = local_1a0;
            }
            if (puVar42 != (undefined8 *)0x0) {
              operator_delete(puVar42);
            }
          }
        }
      }
    }
  }
  else {
    if (*(long *)(param_1 + 0xe8) == 0) {
      puVar21 = (undefined8 *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
    }
    else {
      puVar21 = *(undefined8 **)(_global + 0x250);
    }
    uVar49 = *puVar21;
    uVar61 = NEON_ushl(uVar49,DAT_1029732a8,4);
    uVar61 = NEON_ushl(CONCAT17((byte)((ulong)uVar61 >> 0x38) ^ (byte)((ulong)uVar49 >> 0x38),
                                CONCAT16((byte)((ulong)uVar61 >> 0x30) ^
                                         (byte)((ulong)uVar49 >> 0x30),
                                         CONCAT15((byte)((ulong)uVar61 >> 0x28) ^
                                                  (byte)((ulong)uVar49 >> 0x28),
                                                  CONCAT14((byte)((ulong)uVar61 >> 0x20) ^
                                                           (byte)((ulong)uVar49 >> 0x20),
                                                           CONCAT13((byte)((ulong)uVar61 >> 0x18) ^
                                                                    (byte)((ulong)uVar49 >> 0x18),
                                                                    CONCAT12((byte)((ulong)uVar61 >>
                                                                                   0x10) ^
                                                                             (byte)((ulong)uVar49 >>
                                                                                   0x10),
                                                                             CONCAT11((byte)((ulong)
                                                  uVar61 >> 8) ^ (byte)((ulong)uVar49 >> 8),
                                                  (byte)uVar61 ^ (byte)uVar49))))))),DAT_1029732b0,4
                      );
    uVar50 = NEON_ushl(uVar49,DAT_1029732b8,4);
    uVar50 = uVar50 & DAT_1029732c0;
    bVar48 = (byte)uVar61 | (byte)uVar50;
    bVar54 = (byte)((ulong)uVar61 >> 8) | (byte)(uVar50 >> 8);
    bVar55 = (byte)((ulong)uVar61 >> 0x10) | (byte)(uVar50 >> 0x10);
    bVar56 = (byte)((ulong)uVar61 >> 0x18) | (byte)(uVar50 >> 0x18);
    bVar57 = (byte)((ulong)uVar61 >> 0x20) | (byte)(uVar50 >> 0x20);
    bVar58 = (byte)((ulong)uVar61 >> 0x28) | (byte)(uVar50 >> 0x28);
    bVar59 = (byte)((ulong)uVar61 >> 0x30) | (byte)(uVar50 >> 0x30);
    bVar60 = (byte)((ulong)uVar61 >> 0x38) | (byte)(uVar50 >> 0x38);
    *puVar21 = CONCAT17(bVar60,CONCAT16(bVar59,CONCAT15(bVar58,CONCAT14(bVar57,CONCAT13(bVar56,
                                                  CONCAT12(bVar55,CONCAT11(bVar54,bVar48)))))));
    uVar36 = *(uint *)(puVar21 + 1);
    uVar36 = (uVar36 & 0x7ff0) << 0x11 | (uVar36 ^ uVar36 << 3) >> 0xb;
    *(uint *)(puVar21 + 1) = uVar36;
    if ((double)(CONCAT13(bVar60 ^ bVar56,
                          CONCAT12(bVar59 ^ bVar55,CONCAT11(bVar58 ^ bVar54,bVar57 ^ bVar48))) ^
                uVar36) * 2.3283064365386963e-10 <= (double)fVar44) goto LAB_1019f4228;
  }
  goto LAB_1019f4164;
joined_r0x0001019f493c:
  for (; puVar34 != puVar42; puVar34 = puVar34 + 1) {
    ::const::$_1::operator()((__1 *)&local_1d8,(Entity *)*puVar34);
  }
  if (local_1f0 != (undefined8 *)0x0) {
    operator_delete(local_1f0);
  }
LAB_1019f4164:
  uVar38 = uVar38 + 1;
  if (*(uint *)(this + 0x50) <= uVar38) goto LAB_1019f53cc;
  goto LAB_1019f4178;
}



// ===== ArtilleryTriggerDelivery::apply  @ 0x1019f6f58 =====

/* ArtilleryTriggerDelivery::apply(TriggerContext const&) const */

void __thiscall
ArtilleryTriggerDelivery::apply(ArtilleryTriggerDelivery *this,TriggerContext *param_1)

{
  undefined8 *puVar1;
  undefined8 *puVar2;
  uint uVar3;
  undefined8 uVar4;
  RandomGenerator *pRVar5;
  ArtilleryProjectile *this_00;
  uint *puVar6;
  undefined1 *puVar7;
  int iVar8;
  TriggerContext *pTVar9;
  TriggerContext *pTVar10;
  long *plVar11;
  long lVar12;
  undefined4 uVar13;
  TriggerContext *pTVar14;
  TriggerContext TVar15;
  undefined8 uVar16;
  undefined8 uVar17;
  float fVar18;
  double dVar19;
  float fVar20;
  int iVar21;
  uint uVar22;
  ulong uVar23;
  undefined1 auVar24 [16];
  undefined1 auVar25 [16];
  undefined8 local_210;
  undefined8 uStack_208;
  undefined8 local_200;
  undefined1 local_1f8;
  undefined1 local_1f7;
  undefined1 local_1f6;
  long local_1f0;
  undefined8 uStack_1e8;
  undefined8 uStack_1e0;
  undefined8 uStack_1d8;
  undefined8 local_1d0;
  undefined8 uStack_1c8;
  undefined8 uStack_1c0;
  undefined8 uStack_1b8;
  long local_1b0;
  undefined8 uStack_1a8;
  undefined8 local_1a0;
  undefined4 uStack_198;
  undefined3 uStack_194;
  undefined1 local_191;
  undefined8 local_190;
  undefined1 local_188;
  undefined8 local_180;
  undefined8 uStack_178;
  double local_170;
  ArtilleryProjectile *pAStack_168;
  long local_160;
  undefined8 uStack_158;
  undefined8 local_150;
  undefined8 uStack_148;
  undefined8 uStack_140;
  undefined8 uStack_138;
  undefined8 local_130;
  undefined8 uStack_128;
  undefined8 uStack_120;
  undefined8 uStack_118;
  long local_110;
  undefined8 uStack_108;
  undefined8 uStack_100;
  undefined8 local_f8;
  undefined8 local_f0;
  undefined8 uStack_e8;
  undefined8 uStack_e0;
  undefined8 uStack_d8;
  undefined8 local_d0;
  long local_c8 [3];
  long *local_b0;
  undefined8 local_a8;
  undefined8 uStack_a0;
  undefined8 local_98;
  undefined8 uStack_90;
  undefined8 local_88;
  long local_78;
  
  local_78 = *(long *)PTR____stack_chk_guard_102d481b8;
  pTVar10 = param_1 + 0x48;
  if (((*(int *)pTVar10 == 0x7fffffff) &&
      ((*(long *)(param_1 + 0x40) == 0 ||
       ((*(ushort *)(*(long *)(param_1 + 0x40) + 0x58) >> 4 & 1) != 0)))) ||
     ((pTVar14 = param_1 + 0x68, *(int *)pTVar14 == 0x7fffffff &&
      ((*(long *)(param_1 + 0x60) == 0 ||
       ((*(ushort *)(*(long *)(param_1 + 0x60) + 0x58) >> 4 & 1) != 0)))))) goto LAB_1019f7494;
  TriggerDelivery::apply((TriggerDelivery *)this,param_1);
  iVar21 = *(int *)(param_1 + 0x48);
  if ((iVar21 == 0x7fffffff) &&
     ((*(long *)(param_1 + 0x40) == 0 ||
      ((*(ushort *)(*(long *)(param_1 + 0x40) + 0x58) >> 4 & 1) != 0)))) goto LAB_1019f7494;
  lVar12 = *(long *)(param_1 + 0x60);
  if ((*(int *)(param_1 + 0x68) == 0x7fffffff) &&
     ((lVar12 == 0 || ((*(ushort *)(lVar12 + 0x58) >> 4 & 1) != 0)))) goto LAB_1019f7494;
  auVar25 = *(undefined1 (*) [16])(param_1 + 0x68);
  fVar20 = *(float *)(this + 0x50);
  fVar18 = *(float *)(this + 0x54);
  if ((fVar20 == 0.0) && (fVar18 == 0.0)) {
    uVar13 = *(undefined4 *)(param_1 + 0x78);
    TVar15 = param_1[0x7c];
  }
  else {
    iVar8 = *(int *)(param_1 + 0x50);
    pTVar9 = param_1 + 0x50;
    if (iVar8 == 0x7fffffff) {
      pTVar9 = pTVar10;
    }
    if ((iVar21 == 0x7fffffff) && (iVar8 == 0x7fffffff)) {
      if (*(long *)(param_1 + 0x40) == 0) {
                    /* WARNING: Subroutine does not return */
        Logging::logAndAbortOrThrow
                  ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/ShootingTarget.cpp"
                   ,0x58,9,"Unset shooting target");
      }
      pTVar9 = (TriggerContext *)(*(long *)(param_1 + 0x40) + 0x50);
    }
    if (*(int *)(param_1 + 0x68) == 0x7fffffff) {
      if (lVar12 == 0) goto LAB_1019f74f0;
      pTVar14 = (TriggerContext *)(lVar12 + 0x50);
      iVar21 = *(int *)pTVar14;
    }
    else {
      iVar21 = auVar25._0_4_;
    }
    auVar24._0_8_ = (long)(iVar21 - (int)*(undefined8 *)pTVar9);
    auVar24._8_8_ = (long)(*(int *)(pTVar14 + 4) - (int)((ulong)*(undefined8 *)pTVar9 >> 0x20));
    auVar25 = NEON_scvtf(auVar24,8);
    local_170 = auVar25._0_8_ * 0.00390625;
    pAStack_168 = (ArtilleryProjectile *)(auVar25._8_8_ * 0.00390625);
    if (fVar20 != 0.0) {
      if (*(long *)(param_1 + 0xe8) == 0) {
        pRVar5 = (RandomGenerator *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
      }
      else {
        pRVar5 = *(RandomGenerator **)(_global + 0x250);
      }
      dVar19 = (double)RandomGenerator::uniformDouble(pRVar5);
      Vector2<double,Vector>::rotate((dVar19 + -0.5) * (double)fVar20);
      fVar18 = *(float *)(this + 0x54);
    }
    if (fVar18 != 0.0) {
      if (*(long *)(param_1 + 0xe8) == 0) {
        pRVar5 = (RandomGenerator *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
      }
      else {
        pRVar5 = *(RandomGenerator **)(_global + 0x250);
      }
      dVar19 = (double)RandomGenerator::uniformDouble(pRVar5);
      dVar19 = (dVar19 + -0.5) * (double)fVar18 + 1.0;
      local_170 = local_170 * dVar19;
      pAStack_168 = (ArtilleryProjectile *)((double)pAStack_168 * dVar19);
    }
    iVar21 = *(int *)pTVar10;
    pTVar14 = pTVar10;
    iVar8 = iVar21;
    if (iVar21 == 0x7fffffff) {
      if (*(long *)(param_1 + 0x40) == 0) goto LAB_1019f74f0;
      pTVar14 = (TriggerContext *)(*(long *)(param_1 + 0x40) + 0x50);
      iVar8 = *(int *)pTVar14;
    }
    lVar12 = 0;
    uVar13 = 0;
    TVar15 = (TriggerContext)0x0;
    uVar16 = CONCAT44(*(int *)(pTVar14 + 4) + (int)((double)pAStack_168 * 256.0),
                      iVar8 + (int)(local_170 * 256.0));
    auVar25._8_8_ = uVar16;
    auVar25._0_8_ = uVar16;
  }
  uVar16 = *(undefined8 *)
            (*(long *)PTR_indexToPrototype_102d4c840 + (ulong)*(ushort *)(this + 0x38) * 8);
  if (iVar21 == 0x7fffffff) {
    if (*(long *)(param_1 + 0x40) == 0) {
LAB_1019f74f0:
                    /* WARNING: Subroutine does not return */
      Logging::logAndAbortOrThrow
                ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/ShootingTarget.cpp"
                 ,0xc,9,"Unset shooting target");
    }
    pTVar10 = (TriggerContext *)(*(long *)(param_1 + 0x40) + 0x50);
  }
  uVar17 = *(undefined8 *)pTVar10;
  uStack_e8 = *(undefined8 *)(param_1 + 0x88);
  local_f0 = *(undefined8 *)(param_1 + 0x80);
  uStack_d8 = *(undefined8 *)(param_1 + 0x98);
  uStack_e0 = *(undefined8 *)(param_1 + 0x90);
  local_d0 = *(undefined8 *)(param_1 + 0xa0);
  uStack_128 = *(undefined8 *)(param_1 + 0x48);
  local_130 = *(undefined8 *)(param_1 + 0x40);
  uStack_118 = *(undefined8 *)(param_1 + 0x58);
  uStack_120 = *(undefined8 *)(param_1 + 0x50);
  uStack_108 = *(undefined8 *)(param_1 + 0x68);
  local_110 = *(long *)(param_1 + 0x60);
  local_f8 = *(undefined8 *)(param_1 + 0x78);
  uStack_100 = *(undefined8 *)(param_1 + 0x70);
  pAStack_168 = *(ArtilleryProjectile **)(param_1 + 8);
  local_170 = *(double *)param_1;
  uStack_158 = *(undefined8 *)(param_1 + 0x18);
  local_160 = *(long *)(param_1 + 0x10);
  uStack_148 = *(undefined8 *)(param_1 + 0x28);
  local_150 = *(undefined8 *)(param_1 + 0x20);
  uStack_138 = *(undefined8 *)(param_1 + 0x38);
  uStack_140 = *(undefined8 *)(param_1 + 0x30);
  plVar11 = local_c8;
  pTVar10 = *(TriggerContext **)(param_1 + 0xc0);
  if (pTVar10 == (TriggerContext *)0x0) {
    local_b0 = (long *)0x0;
  }
  else if (pTVar10 == param_1 + 0xa8) {
    local_b0 = plVar11;
    (**(code **)(*(long *)pTVar10 + 0x18))(pTVar10,plVar11);
  }
  else {
    local_b0 = (long *)(**(code **)(*(long *)pTVar10 + 0x10))();
  }
  uStack_a0 = *(undefined8 *)(param_1 + 0xd0);
  local_a8 = *(undefined8 *)(param_1 + 200);
  uStack_90 = *(undefined8 *)(param_1 + 0xe0);
  local_98 = *(undefined8 *)(param_1 + 0xd8);
  uVar4 = local_98;
  local_88 = *(undefined8 *)(param_1 + 0xe8);
  if (lVar12 == 0) {
    lVar12 = 0;
  }
  else if ((*(ushort *)(lVar12 + 0x58) & 0x10) != 0) {
    lVar12 = 0;
  }
  uStack_1e0 = auVar25._8_8_;
  uStack_1e8 = auVar25._0_8_;
  local_f8._0_5_ = CONCAT14(TVar15,uVar13);
  uStack_208 = *(undefined8 *)(pAStack_168 + 0xb8);
  local_98._5_1_ = (undefined1)((ulong)*(undefined8 *)(param_1 + 0xd8) >> 0x28);
  uStack_1d8 = local_f8;
  uStack_1c8 = uStack_128;
  local_1d0 = local_130;
  uStack_1b8 = uStack_118;
  uStack_1c0 = uStack_120;
  local_1a0 = local_150;
  uStack_1a8 = uStack_158;
  local_1b0 = local_160;
  local_1f8 = 0;
  local_1f7 = (undefined1)local_160;
  local_1f6 = local_98._5_1_;
  uStack_194 = 0;
  uStack_198 = 0;
  local_191 = 0x14;
  local_190 = 0x10000ff00000000;
  local_188 = 0;
  local_180 = 0;
  uStack_178 = 0;
  local_210 = uVar16;
  local_200 = uVar17;
  local_1f0 = lVar12;
  local_110 = lVar12;
  uStack_108 = uStack_1e8;
  uStack_100 = uStack_1e0;
  local_98 = uVar4;
  if (local_b0 == plVar11) {
    lVar12 = 4;
LAB_1019f7334:
    (**(code **)(*plVar11 + lVar12 * 8))(plVar11);
  }
  else if (local_b0 != (long *)0x0) {
    lVar12 = 5;
    plVar11 = local_b0;
    goto LAB_1019f7334;
  }
  this_00 = operator_new(0x1d8);
  if (*(long *)(param_1 + 0xe8) == 0) {
    puVar6 = (uint *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
    fVar18 = *(float *)(this + 0x48);
    fVar20 = *(float *)(this + 0x4c);
  }
  else {
    puVar6 = *(uint **)(_global + 0x250);
    fVar18 = *(float *)(this + 0x48);
    fVar20 = *(float *)(this + 0x4c);
  }
  if (fVar20 != 0.0) {
    uVar3 = *puVar6;
    uVar3 = (uVar3 & 0xffffe) << 0xc | (uVar3 ^ uVar3 << 0xd) >> 0x13;
    *puVar6 = uVar3;
    uVar16 = *(undefined8 *)(puVar6 + 1);
    uVar17 = NEON_ushl(uVar16,DAT_1029732c8,4);
    uVar17 = NEON_ushl(CONCAT17((byte)((ulong)uVar17 >> 0x38) ^ (byte)((ulong)uVar16 >> 0x38),
                                CONCAT16((byte)((ulong)uVar17 >> 0x30) ^
                                         (byte)((ulong)uVar16 >> 0x30),
                                         CONCAT15((byte)((ulong)uVar17 >> 0x28) ^
                                                  (byte)((ulong)uVar16 >> 0x28),
                                                  CONCAT14((byte)((ulong)uVar17 >> 0x20) ^
                                                           (byte)((ulong)uVar16 >> 0x20),
                                                           CONCAT13((byte)((ulong)uVar17 >> 0x18) ^
                                                                    (byte)((ulong)uVar16 >> 0x18),
                                                                    CONCAT12((byte)((ulong)uVar17 >>
                                                                                   0x10) ^
                                                                             (byte)((ulong)uVar16 >>
                                                                                   0x10),
                                                                             CONCAT11((byte)((ulong)
                                                  uVar17 >> 8) ^ (byte)((ulong)uVar16 >> 8),
                                                  (byte)uVar17 ^ (byte)uVar16))))))),DAT_1029732d0,4
                      );
    uVar23 = NEON_ushl(uVar16,DAT_1029732d8,4);
    uVar23 = uVar23 & DAT_1029732e0;
    uVar22 = CONCAT13((byte)((ulong)uVar17 >> 0x18) | (byte)(uVar23 >> 0x18),
                      CONCAT12((byte)((ulong)uVar17 >> 0x10) | (byte)(uVar23 >> 0x10),
                               CONCAT11((byte)((ulong)uVar17 >> 8) | (byte)(uVar23 >> 8),
                                        (byte)uVar17 | (byte)uVar23)));
    uVar16 = CONCAT17((byte)((ulong)uVar17 >> 0x38) | (byte)(uVar23 >> 0x38),
                      CONCAT16((byte)((ulong)uVar17 >> 0x30) | (byte)(uVar23 >> 0x30),
                               CONCAT15((byte)((ulong)uVar17 >> 0x28) | (byte)(uVar23 >> 0x28),
                                        CONCAT14((byte)((ulong)uVar17 >> 0x20) |
                                                 (byte)(uVar23 >> 0x20),uVar22))));
    *(undefined8 *)(puVar6 + 1) = uVar16;
    fVar18 = fVar18 + fVar20 * -0.5 +
             fVar20 * (float)((double)(uVar22 ^ uVar3 ^ (uint)((ulong)uVar16 >> 0x20)) *
                             2.3283064365386963e-10);
  }
  ArtilleryProjectile::ArtilleryProjectile
            (this_00,(EntityCreationParameters *)&local_210,(TriggerModifier *)(param_1 + 0x80),
             (double)fVar18);
  TriggerContext::addEntity(param_1,(Entity *)this_00);
  if (this[0x58] != (ArtilleryTriggerDelivery)0x0) {
    local_160 = *(long *)(param_1 + 0x40);
    if ((local_160 != 0) && ((*(ushort *)(local_160 + 0x58) & 0x10) != 0)) {
      local_160 = 0;
    }
    local_170 = (double)CONCAT71(local_170._1_7_,0x5f);
    lVar12 = *(long *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x480);
    pAStack_168 = this_00;
    if (lVar12 != 0) {
      puVar7 = *(undefined1 **)(lVar12 + 0x210);
      *puVar7 = 1;
      puVar2 = *(undefined8 **)(puVar7 + 0x10);
      for (puVar1 = *(undefined8 **)(puVar7 + 8); puVar1 != puVar2; puVar1 = puVar1 + 1) {
        (**(code **)(*(long *)*puVar1 + 0x10))((long *)*puVar1,&local_170);
      }
    }
    GameAction::destroyValue((GameAction *)&local_170);
  }
LAB_1019f7494:
  if (*(long *)PTR____stack_chk_guard_102d481b8 != local_78) {
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail();
  }
  return;
}



// ===== TriggerDelivery::apply  @ 0x1019f7554 =====

/* TriggerDelivery::apply(TriggerContext const&) const */

void __thiscall TriggerDelivery::apply(TriggerDelivery *this,TriggerContext *param_1)

{
  TriggerContext *pTVar1;
  long lVar2;
  long *plVar3;
  undefined8 local_140;
  undefined8 uStack_138;
  undefined8 uStack_130;
  undefined8 uStack_128;
  undefined8 local_120;
  undefined8 uStack_118;
  undefined8 uStack_110;
  undefined8 uStack_108;
  undefined8 local_100;
  undefined8 uStack_f8;
  undefined8 uStack_f0;
  undefined8 uStack_e8;
  long local_e0;
  undefined8 uStack_d8;
  undefined8 uStack_d0;
  undefined8 local_c8;
  undefined8 local_c0;
  undefined8 uStack_b8;
  undefined8 uStack_b0;
  undefined8 uStack_a8;
  undefined8 local_a0;
  long local_98 [3];
  long *local_80;
  undefined8 local_78;
  undefined8 uStack_70;
  undefined8 local_68;
  undefined8 uStack_60;
  undefined8 local_58;
  long local_48;
  
  local_48 = *(long *)PTR____stack_chk_guard_102d481b8;
  uStack_b8 = *(undefined8 *)(param_1 + 0x88);
  local_c0 = *(undefined8 *)(param_1 + 0x80);
  uStack_a8 = *(undefined8 *)(param_1 + 0x98);
  uStack_b0 = *(undefined8 *)(param_1 + 0x90);
  local_a0 = *(undefined8 *)(param_1 + 0xa0);
  uStack_f8 = *(undefined8 *)(param_1 + 0x48);
  local_100 = *(undefined8 *)(param_1 + 0x40);
  uStack_e8 = *(undefined8 *)(param_1 + 0x58);
  uStack_f0 = *(undefined8 *)(param_1 + 0x50);
  uStack_d8 = *(undefined8 *)(param_1 + 0x68);
  local_e0 = *(long *)(param_1 + 0x60);
  local_c8 = *(undefined8 *)(param_1 + 0x78);
  uStack_d0 = *(undefined8 *)(param_1 + 0x70);
  uStack_138 = *(undefined8 *)(param_1 + 8);
  local_140 = *(undefined8 *)param_1;
  uStack_128 = *(undefined8 *)(param_1 + 0x18);
  uStack_130 = *(undefined8 *)(param_1 + 0x10);
  uStack_118 = *(undefined8 *)(param_1 + 0x28);
  local_120 = *(undefined8 *)(param_1 + 0x20);
  uStack_108 = *(undefined8 *)(param_1 + 0x38);
  uStack_110 = *(undefined8 *)(param_1 + 0x30);
  plVar3 = local_98;
  pTVar1 = *(TriggerContext **)(param_1 + 0xc0);
  if (pTVar1 == (TriggerContext *)0x0) {
    local_80 = (long *)0x0;
  }
  else if (pTVar1 == param_1 + 0xa8) {
    local_80 = plVar3;
    (**(code **)(*(long *)pTVar1 + 0x18))(pTVar1,plVar3);
  }
  else {
    local_80 = (long *)(**(code **)(*(long *)pTVar1 + 0x10))();
  }
  uStack_70 = *(undefined8 *)(param_1 + 0xd0);
  local_78 = *(undefined8 *)(param_1 + 200);
  uStack_60 = *(undefined8 *)(param_1 + 0xe0);
  local_68 = *(undefined8 *)(param_1 + 0xd8);
  local_58 = *(undefined8 *)(param_1 + 0xe8);
  if ((TriggerContext *)&local_e0 != param_1 + 0x40) {
    local_e0 = *(long *)(param_1 + 0x40);
    if ((local_e0 != 0) && ((*(ushort *)(local_e0 + 0x58) & 0x10) != 0)) {
      local_e0 = 0;
    }
    uStack_d0 = *(undefined8 *)(param_1 + 0x50);
    uStack_d8 = *(undefined8 *)(param_1 + 0x48);
    local_c8 = CONCAT35(local_c8._5_3_,*(undefined5 *)(param_1 + 0x58));
  }
  TriggerEffect::apply((TriggerEffect *)(this + 8),(TriggerContext *)&local_140);
  if (local_80 == plVar3) {
    lVar2 = 4;
  }
  else {
    if (local_80 == (long *)0x0) goto LAB_1019f7698;
    lVar2 = 5;
    plVar3 = local_80;
  }
  (**(code **)(*plVar3 + lVar2 * 8))(plVar3);
LAB_1019f7698:
  TriggerEffect::apply((TriggerEffect *)(this + 0x20),param_1);
  if (*(long *)PTR____stack_chk_guard_102d481b8 != local_48) {
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail();
  }
  return;
}



// ===== AttackReactionItem::apply  @ 0x1019fba24 =====

/* AttackReactionItem::apply(TriggerContext const&, DamageHit const&) const */

void __thiscall
AttackReactionItem::apply(AttackReactionItem *this,TriggerContext *param_1,DamageHit *param_2)

{
  undefined8 *puVar1;
  undefined8 *puVar2;
  TriggerContext *pTVar3;
  long lVar4;
  TriggerContext *pTVar5;
  int iVar6;
  long *plVar7;
  float fVar8;
  float fVar9;
  float fVar10;
  undefined4 uVar11;
  undefined8 local_170;
  undefined8 uStack_168;
  undefined8 uStack_160;
  undefined8 uStack_158;
  undefined8 local_150;
  undefined8 uStack_148;
  undefined8 uStack_140;
  undefined8 uStack_138;
  undefined8 local_130;
  undefined8 uStack_128;
  undefined8 uStack_120;
  undefined8 uStack_118;
  undefined8 local_110;
  undefined8 uStack_108;
  undefined8 uStack_100;
  undefined8 uStack_f8;
  undefined8 local_f0;
  undefined8 uStack_e8;
  undefined8 uStack_e0;
  undefined8 local_d8;
  undefined8 uStack_d0;
  long local_c8 [3];
  long *local_b0;
  undefined8 local_a8;
  undefined8 uStack_a0;
  undefined8 local_98;
  undefined8 uStack_90;
  undefined8 local_88;
  undefined8 local_80;
  undefined8 uStack_78;
  undefined8 uStack_70;
  undefined8 uStack_68;
  long local_58;
  
  local_58 = *(long *)PTR____stack_chk_guard_102d481b8;
  pTVar3 = param_1 + 0x48;
  if (*(int *)pTVar3 == 0x7fffffff) {
    if (*(long *)(param_1 + 0x40) == 0) goto LAB_1019fbc48;
    pTVar3 = (TriggerContext *)(*(long *)(param_1 + 0x40) + 0x50);
  }
  pTVar5 = param_1 + 0x68;
  iVar6 = *(int *)pTVar5;
  if (iVar6 == 0x7fffffff) {
    if (*(long *)(param_1 + 0x60) == 0) {
LAB_1019fbc48:
                    /* WARNING: Subroutine does not return */
      Logging::logAndAbortOrThrow
                ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/ShootingTarget.cpp"
                 ,0xc,9,"Unset shooting target");
    }
    pTVar5 = (TriggerContext *)(*(long *)(param_1 + 0x60) + 0x50);
    iVar6 = *(int *)pTVar5;
  }
  fVar9 = (float)(*(int *)pTVar3 - iVar6) * 0.00390625;
  fVar8 = (float)(*(int *)(pTVar3 + 4) - *(int *)(pTVar5 + 4)) * 0.00390625;
  if ((fVar9 * fVar9 + fVar8 * fVar8 <= *(float *)(this + 0x18) * *(float *)(this + 0x18)) &&
     ((this[0x20] == (AttackReactionItem)0x0 || (*(AttackReactionItem *)(param_2 + 4) == this[0x20])
      ))) {
    uVar11 = *(undefined4 *)(param_1 + 0x80);
    fVar8 = *(float *)(param_1 + 0x84);
    uStack_78 = *(undefined8 *)(param_1 + 0x90);
    local_80 = *(undefined8 *)(param_1 + 0x88);
    uStack_68 = *(undefined8 *)(param_1 + 0xa0);
    uStack_70 = *(undefined8 *)(param_1 + 0x98);
    fVar9 = *(float *)(this + 0x1c);
    fVar10 = *(float *)param_2;
    uStack_e8 = *(undefined8 *)(param_1 + 0x88);
    local_f0 = *(undefined8 *)(param_1 + 0x80);
    local_d8 = *(undefined8 *)(param_1 + 0x98);
    uStack_e0 = *(undefined8 *)(param_1 + 0x90);
    uStack_d0 = *(undefined8 *)(param_1 + 0xa0);
    uStack_128 = *(undefined8 *)(param_1 + 0x48);
    local_130 = *(undefined8 *)(param_1 + 0x40);
    uStack_118 = *(undefined8 *)(param_1 + 0x58);
    uStack_120 = *(undefined8 *)(param_1 + 0x50);
    uStack_108 = *(undefined8 *)(param_1 + 0x68);
    local_110 = *(undefined8 *)(param_1 + 0x60);
    uStack_f8 = *(undefined8 *)(param_1 + 0x78);
    uStack_100 = *(undefined8 *)(param_1 + 0x70);
    uStack_168 = *(undefined8 *)(param_1 + 8);
    local_170 = *(undefined8 *)param_1;
    uStack_158 = *(undefined8 *)(param_1 + 0x18);
    uStack_160 = *(undefined8 *)(param_1 + 0x10);
    uStack_148 = *(undefined8 *)(param_1 + 0x28);
    local_150 = *(undefined8 *)(param_1 + 0x20);
    uStack_138 = *(undefined8 *)(param_1 + 0x38);
    uStack_140 = *(undefined8 *)(param_1 + 0x30);
    plVar7 = local_c8;
    pTVar3 = *(TriggerContext **)(param_1 + 0xc0);
    if (pTVar3 == (TriggerContext *)0x0) {
      local_b0 = (long *)0x0;
    }
    else if (pTVar3 == param_1 + 0xa8) {
      local_b0 = plVar7;
      (**(code **)(*(long *)pTVar3 + 0x18))(pTVar3,plVar7);
    }
    else {
      local_b0 = (long *)(**(code **)(*(long *)pTVar3 + 0x10))();
    }
    uStack_a0 = *(undefined8 *)(param_1 + 0xd0);
    local_a8 = *(undefined8 *)(param_1 + 200);
    uStack_90 = *(undefined8 *)(param_1 + 0xe0);
    local_98 = *(undefined8 *)(param_1 + 0xd8);
    local_88 = *(undefined8 *)(param_1 + 0xe8);
    local_f0 = CONCAT44(fVar8 + fVar9 * fVar10,uVar11);
    puVar2 = *(undefined8 **)(this + 8);
    uStack_e0 = uStack_78;
    uStack_e8 = local_80;
    uStack_d0 = uStack_68;
    local_d8 = uStack_70;
    for (puVar1 = *(undefined8 **)this; puVar1 != puVar2; puVar1 = puVar1 + 1) {
      (**(code **)(*(long *)*puVar1 + 0x20))((long *)*puVar1,&local_170);
    }
    if (local_b0 == plVar7) {
      lVar4 = 4;
    }
    else {
      if (local_b0 == (long *)0x0) goto LAB_1019fbc14;
      lVar4 = 5;
      plVar7 = local_b0;
    }
    (**(code **)(*plVar7 + lVar4 * 8))(plVar7);
  }
LAB_1019fbc14:
  if (*(long *)PTR____stack_chk_guard_102d481b8 != local_58) {
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail();
  }
  return;
}



// ===== BeamTriggerDelivery::apply  @ 0x1019fc628 =====

/* BeamTriggerDelivery::apply(TriggerContext const&) const */

void __thiscall BeamTriggerDelivery::apply(BeamTriggerDelivery *this,TriggerContext *param_1)

{
  undefined *puVar1;
  long lVar2;
  char *pcVar3;
  TriggerContext *pTVar4;
  undefined ***pppuVar5;
  Entity *pEVar6;
  int iVar7;
  long lVar8;
  undefined8 uVar9;
  undefined **ppuVar10;
  long *plVar11;
  undefined *puVar12;
  long lVar13;
  undefined **ppuVar14;
  TriggerContext *pTVar15;
  TriggerContext *pTVar16;
  TriggerContext *pTVar17;
  TriggerContext *pTVar18;
  TriggerContext *pTVar19;
  double dVar20;
  double dVar21;
  double dVar22;
  double dVar23;
  uint uVar24;
  undefined8 local_1b8;
  undefined **local_1b0;
  long local_1a8;
  long local_1a0;
  undefined1 local_198;
  TriggerContext TStack_197;
  TriggerContext TStack_196;
  undefined5 uStack_195;
  long local_190;
  undefined8 uStack_188;
  undefined8 uStack_180;
  long *local_178;
  undefined8 local_170;
  undefined8 uStack_168;
  undefined8 local_160;
  undefined8 local_158;
  undefined8 uStack_150;
  undefined8 uStack_148;
  undefined8 local_140;
  undefined4 local_138;
  undefined3 uStack_134;
  undefined1 local_131;
  undefined8 local_130;
  undefined1 local_128;
  undefined8 local_120;
  undefined8 uStack_118;
  undefined **local_110;
  undefined ***local_108;
  undefined **local_100;
  undefined ***local_f8;
  long local_f0 [3];
  long *local_d8;
  undefined **local_d0;
  undefined8 local_c8;
  undefined8 uStack_c0;
  undefined4 local_b8;
  bool local_b4;
  undefined **local_b0;
  undefined ***pppuStack_a8;
  undefined4 local_a0;
  undefined ***local_98;
  long local_88;
  
  local_88 = *(long *)PTR____stack_chk_guard_102d481b8;
  pTVar15 = param_1 + 0x48;
  pTVar16 = param_1 + 0x40;
  if ((*(int *)pTVar15 == 0x7fffffff) &&
     ((*(long *)pTVar16 == 0 || ((*(ushort *)(*(long *)pTVar16 + 0x58) >> 4 & 1) != 0))))
  goto LAB_1019fcc4c;
  pTVar18 = param_1 + 0x68;
  pTVar17 = param_1 + 0x60;
  if ((((*(int *)pTVar18 == 0x7fffffff) &&
       ((*(long *)pTVar17 == 0 || ((*(ushort *)(*(long *)pTVar17 + 0x58) >> 4 & 1) != 0)))) ||
      ((TriggerDelivery::apply((TriggerDelivery *)this,param_1),
       *(int *)(param_1 + 0x48) == 0x7fffffff &&
       ((*(long *)pTVar16 == 0 || ((*(ushort *)(*(long *)pTVar16 + 0x58) >> 4 & 1) != 0)))))) ||
     ((*(int *)pTVar18 == 0x7fffffff &&
      ((*(long *)pTVar17 == 0 || ((*(ushort *)(*(long *)pTVar17 + 0x58) >> 4 & 1) != 0))))))
  goto LAB_1019fcc4c;
  lVar8 = *(long *)(param_1 + 0x40);
  if (lVar8 == 0) {
    lVar8 = 0;
  }
  else if ((*(ushort *)(lVar8 + 0x58) & 0x10) != 0) {
    lVar8 = 0;
  }
  uVar24 = *(uint *)(this + 0x4c);
  dVar23 = *(double *)(param_1 + 0xa0);
  local_108 = &local_1b0;
  local_110 = &PTR____func_103079838;
  local_f8 = &local_110;
  TargeterWithCallback<Entity,(TargeterType)0,(TargeterFlags)0>::TargeterWithCallback
            ((TargeterWithCallback<Entity,(TargeterType)0,(TargeterFlags)0> *)&local_1b0,lVar8,
             &local_110);
  if (local_f8 == &local_110) {
    lVar8 = 4;
    pppuVar5 = &local_110;
LAB_1019fc764:
    (*(code *)(*pppuVar5)[lVar8])();
  }
  else if (local_f8 != (undefined ***)0x0) {
    lVar8 = 5;
    pppuVar5 = local_f8;
    goto LAB_1019fc764;
  }
  local_170 = *(undefined8 *)pTVar15;
  uStack_168 = 0;
  local_160 = 0;
  local_158._0_5_ = CONCAT14(local_1a8 != 0,0x80010000);
  lVar8 = *(long *)pTVar17;
  if (lVar8 == 0) {
    lVar8 = 0;
  }
  else if ((*(ushort *)(lVar8 + 0x58) & 0x10) != 0) {
    lVar8 = 0;
  }
  pppuStack_a8 = &local_110;
  local_b0 = &PTR____func_103079838;
  local_98 = &local_b0;
  TargeterWithCallback<Entity,(TargeterType)0,(TargeterFlags)0>::TargeterWithCallback
            ((TargeterWithCallback<Entity,(TargeterType)0,(TargeterFlags)0> *)&local_110,lVar8,
             &local_b0);
  if (local_98 == &local_b0) {
    lVar8 = 4;
    pppuVar5 = &local_b0;
LAB_1019fc7ec:
    (*(code *)(*pppuVar5)[lVar8])();
  }
  else if (local_98 != (undefined ***)0x0) {
    lVar8 = 5;
    pppuVar5 = local_98;
    goto LAB_1019fc7ec;
  }
  local_d0 = *(undefined ***)pTVar18;
  local_c8 = 0;
  uStack_c0 = 0;
  local_b8 = 0x80010000;
  local_b4 = local_108 != (undefined ***)0x0;
  if (local_1a8 == 0) {
    uVar9 = 0;
    if ((int)local_170 != 0x7fffffff) {
      uVar9 = local_170;
    }
    if (local_108 != (undefined ***)0x0) goto LAB_1019fc830;
LAB_1019fc878:
    ppuVar10 = (undefined **)0x0;
    if ((int)local_d0 != 0x7fffffff) {
      ppuVar10 = local_d0;
    }
LAB_1019fc884:
    dVar20 = (double)((int)((ulong)ppuVar10 >> 0x20) - (int)((ulong)uVar9 >> 0x20)) * 0.00390625;
    dVar22 = (double)((int)ppuVar10 - (int)uVar9) * 0.00390625;
    dVar20 = dVar22 * dVar22 + dVar20 * dVar20;
  }
  else {
    uVar9 = *(undefined8 *)(local_1a8 + 0x50);
    if (local_108 == (undefined ***)0x0) goto LAB_1019fc878;
LAB_1019fc830:
    ppuVar10 = local_108[10];
    if ((local_158._4_1_ == '\0') || (local_108 == (undefined ***)0x0)) goto LAB_1019fc884;
    pppuStack_a8 = *(undefined ****)((long)local_108 + 100);
    local_b0 = *(undefined ***)((long)local_108 + 0x5c);
    local_a0 = *(undefined4 *)((long)local_108 + 0x6c);
    if (local_1a8 == 0) {
      local_1b8 = 0;
      if ((int)local_170 != 0x7fffffff) {
        local_1b8 = local_170;
      }
    }
    else {
      local_1b8 = *(undefined8 *)(local_1a8 + 0x50);
    }
    dVar20 = (double)::BoundingBox::distanceFromPointSquared
                               ((BoundingBox *)&local_b0,(MapPosition *)&local_1b8);
  }
  local_110 = &PTR__TargeterWithCallback_102fbdf40;
  plVar11 = local_f0;
  if (local_d8 == plVar11) {
    lVar8 = 4;
LAB_1019fc91c:
    (**(code **)(*plVar11 + lVar8 * 8))();
  }
  else if (local_d8 != (long *)0x0) {
    lVar8 = 5;
    plVar11 = local_d8;
    goto LAB_1019fc91c;
  }
  pppuVar5 = local_f8;
  if (local_100 == (undefined **)0xfe) {
    if (*(char *)local_f8 == '\x02') {
      ppuVar10 = local_f8[1];
LAB_1019fc9c4:
      *ppuVar10 = (undefined *)0x0;
    }
    else if (*(char *)local_f8 == '\x01') {
      local_f8[1][2] = (undefined *)0x0;
      local_f8[1][3] = (undefined *)0x0;
      ppuVar14 = local_f8[1];
      ppuVar10 = ppuVar14 + 1;
      if (*ppuVar10 != (undefined *)0x0) {
        puVar12 = ppuVar14[2];
        puVar1 = ppuVar14[3];
        if (puVar1 == (undefined *)0x0) {
          *(undefined **)(*ppuVar10 + 8) = puVar12;
        }
        else {
          *(undefined **)(puVar1 + 0x10) = puVar12;
          puVar12 = ppuVar14[2];
        }
        if (puVar12 != (undefined *)0x0) {
          *(undefined **)(puVar12 + 0x18) = puVar1;
        }
        goto LAB_1019fc9c4;
      }
    }
    *(char *)local_f8 = '\0';
  }
  else if (local_108 != (undefined ***)0x0) {
    if (local_f8 == (undefined ***)0x0) {
      local_108[1] = local_100;
    }
    else {
      local_f8[2] = local_100;
    }
    if (local_100 != (undefined **)0x0) {
      local_100[3] = (undefined *)pppuVar5;
    }
  }
  local_1b0 = &PTR__TargeterWithCallback_102fbdf40;
  plVar11 = &local_190;
  if (local_178 == plVar11) {
    lVar8 = 4;
LAB_1019fc9fc:
    (**(code **)(*plVar11 + lVar8 * 8))();
  }
  else if (local_178 != (long *)0x0) {
    lVar8 = 5;
    plVar11 = local_178;
    goto LAB_1019fc9fc;
  }
  if (local_1a0 == 0xfe) {
    pcVar3 = (char *)CONCAT53(uStack_195,CONCAT12(TStack_196,CONCAT11(TStack_197,local_198)));
    if (*pcVar3 == '\x02') {
      plVar11 = *(long **)(pcVar3 + 8);
LAB_1019fcacc:
      *plVar11 = 0;
    }
    else if (*pcVar3 == '\x01') {
      *(undefined8 *)(*(long *)(pcVar3 + 8) + 0x10) = 0;
      *(undefined8 *)(*(long *)(pcVar3 + 8) + 0x18) = 0;
      lVar8 = *(long *)(pcVar3 + 8);
      plVar11 = (long *)(lVar8 + 8);
      if (*plVar11 != 0) {
        lVar13 = *(long *)(lVar8 + 0x10);
        lVar2 = *(long *)(lVar8 + 0x18);
        if (lVar2 == 0) {
          *(long *)(*plVar11 + 8) = lVar13;
        }
        else {
          *(long *)(lVar2 + 0x10) = lVar13;
          lVar13 = *(long *)(lVar8 + 0x10);
        }
        if (lVar13 != 0) {
          *(long *)(lVar13 + 0x18) = lVar2;
        }
        goto LAB_1019fcacc;
      }
    }
    *pcVar3 = '\0';
    if (*(int *)pTVar15 == 0x7fffffff) goto LAB_1019fca44;
LAB_1019fcae4:
    iVar7 = *(int *)pTVar18;
    pTVar4 = pTVar15;
  }
  else {
    if (local_1a8 != 0) {
      lVar8 = CONCAT53(uStack_195,CONCAT12(TStack_196,CONCAT11(TStack_197,local_198)));
      if (lVar8 == 0) {
        *(long *)(local_1a8 + 8) = local_1a0;
      }
      else {
        *(long *)(lVar8 + 0x10) = local_1a0;
      }
      if (local_1a0 != 0) {
        *(long *)(local_1a0 + 0x18) = lVar8;
      }
    }
    if (*(int *)pTVar15 != 0x7fffffff) goto LAB_1019fcae4;
LAB_1019fca44:
    if (*(long *)pTVar16 == 0) goto LAB_1019fcc90;
    iVar7 = *(int *)pTVar18;
    pTVar4 = (TriggerContext *)(*(long *)pTVar16 + 0x50);
  }
  pTVar19 = pTVar18;
  if (iVar7 == 0x7fffffff) {
    if (*(long *)pTVar17 == 0) {
LAB_1019fcc90:
                    /* WARNING: Subroutine does not return */
      Logging::logAndAbortOrThrow
                ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/ShootingTarget.cpp"
                 ,0xc,9,"Unset shooting target");
    }
    pTVar19 = (TriggerContext *)(*(long *)pTVar17 + 0x50);
    iVar7 = *(int *)pTVar19;
  }
  dVar21 = (double)NEON_ucvtf((ulong)uVar24);
  local_1a0 = CONCAT44(*(int *)(pTVar4 + 4) +
                       (int)((double)(*(int *)(pTVar19 + 4) - *(int *)(pTVar4 + 4)) * 0.00390625 *
                             0.5 * 256.0),
                       *(int *)pTVar4 +
                       (int)((double)(iVar7 - *(int *)pTVar4) * 0.00390625 * 0.5 * 256.0));
  local_1b0 = *(undefined ***)
               (*(long *)PTR_indexToPrototype_102d4c840 + (ulong)*(ushort *)(this + 0x38) * 8);
  local_1a8 = *(long *)(*(long *)(param_1 + 8) + 0xb8);
  TStack_197 = param_1[0x10];
  TStack_196 = param_1[0xdd];
  uStack_188 = *(undefined8 *)pTVar18;
  local_190 = *(long *)pTVar17;
  local_178 = *(long **)(param_1 + 0x78);
  uStack_180 = *(undefined8 *)(param_1 + 0x70);
  uStack_168 = *(undefined8 *)pTVar15;
  local_170 = *(undefined8 *)pTVar16;
  local_158 = *(undefined8 *)(param_1 + 0x58);
  local_160 = *(undefined8 *)(param_1 + 0x50);
  local_140 = *(undefined8 *)(param_1 + 0x20);
  uStack_148 = *(undefined8 *)(param_1 + 0x18);
  uStack_150 = *(undefined8 *)(param_1 + 0x10);
  local_198 = 0;
  local_138 = 0;
  uStack_134 = 0;
  local_131 = 0x14;
  local_130 = 0x10000ff00000000;
  local_128 = 0;
  local_120 = 0;
  uStack_118 = 0;
  pEVar6 = operator_new(0x228);
  dVar22 = dVar23 * dVar21;
  if (dVar23 * dVar21 <= SQRT(dVar20)) {
    dVar22 = SQRT(dVar20);
  }
  dVar23 = (double)(long)dVar22;
  if (NAN(dVar23)) {
LAB_1019fcc1c:
    iVar7 = 0;
  }
  else if (4294967295.0 <= dVar23) {
    iVar7 = -1;
  }
  else {
    if (dVar23 <= 0.0) goto LAB_1019fcc1c;
    iVar7 = (int)dVar23;
  }
  Beam::Beam(*(Beam **)(this + 0x58),*(undefined8 *)(this + 0x60),pEVar6,&local_1b0,param_1 + 0x80,
             iVar7,*(undefined4 *)(this + 0x50),this[0x48],this[0x68]);
  TriggerContext::addEntity(param_1,pEVar6);
LAB_1019fcc4c:
  if (*(long *)PTR____stack_chk_guard_102d481b8 != local_88) {
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail();
  }
  return;
}



// ===== ChainActiveTrigger::apply  @ 0x1019ffbe4 =====

/* ChainActiveTrigger::apply(ChainActiveTriggerPrototype const*, TriggerContext const&) */

ChainActiveTrigger *
ChainActiveTrigger::apply(ChainActiveTriggerPrototype *param_1,TriggerContext *param_2)

{
  undefined8 *puVar1;
  ChainActiveTrigger *this;
  undefined8 *puVar2;
  ChainActiveTrigger aCStack_1c8 [336];
  char local_78;
  undefined8 *local_70;
  undefined8 *local_68;
  PersistentShootingTarget *local_58;
  PersistentShootingTarget *pPStack_50;
  uint local_3c;
  long local_38;
  
  local_38 = *(long *)PTR____stack_chk_guard_102d481b8;
  if (*(long *)(param_1 + 0x1c0) == 0) {
    ChainActiveTrigger(aCStack_1c8,param_1,param_2);
    while (((local_78 != '\0' && ((uint)((ulong)((long)local_68 - (long)local_70) >> 5) < local_3c))
           && (local_58 != pPStack_50))) {
      update(aCStack_1c8);
    }
    if (local_58 != (PersistentShootingTarget *)0x0) {
      std::vector<PersistentShootingTarget,std::allocator<PersistentShootingTarget>>::
      __base_destruct_at_end_abi_v160006_
                ((vector<PersistentShootingTarget,std::allocator<PersistentShootingTarget>> *)
                 &local_58,local_58);
      operator_delete(local_58);
    }
    puVar1 = local_70;
    if (local_70 != (undefined8 *)0x0) {
      while (local_68 != puVar1) {
        puVar2 = local_68 + -4;
        (**(code **)*puVar2)(puVar2);
        local_68 = puVar2;
      }
      local_68 = puVar1;
      operator_delete(local_70);
    }
    ActiveTrigger::~ActiveTrigger((ActiveTrigger *)aCStack_1c8);
    this = (ChainActiveTrigger *)0x0;
    if (*(long *)PTR____stack_chk_guard_102d481b8 != local_38) goto LAB_1019ffd34;
  }
  else {
    this = operator_new(400);
    ChainActiveTrigger(this,param_1,param_2);
    if (*(long *)PTR____stack_chk_guard_102d481b8 != local_38) {
LAB_1019ffd34:
                    /* WARNING: Subroutine does not return */
      ___stack_chk_fail();
    }
  }
  return this;
}



// ===== ChainActiveTriggerPrototype::apply  @ 0x101a01600 =====

/* ChainActiveTriggerPrototype::apply(TriggerContext const&) const */

void __thiscall
ChainActiveTriggerPrototype::apply(ChainActiveTriggerPrototype *this,TriggerContext *param_1)

{
  long lVar1;
  long *plVar2;
  undefined8 *puVar3;
  
  lVar1 = ChainActiveTrigger::apply(this,param_1);
  if (lVar1 != 0) {
    puVar3 = *(undefined8 **)(*(long *)(param_1 + 8) + 0x2e68);
    plVar2 = (long *)(lVar1 + 8);
    *plVar2 = *(long *)(param_1 + 8) + 0x2e60;
    *(undefined8 **)(lVar1 + 0x10) = puVar3;
    *puVar3 = plVar2;
    *(long **)(*plVar2 + 8) = plVar2;
  }
  return;
}



// ===== ChainTriggerDelivery::apply  @ 0x101a019c8 =====

/* ChainTriggerDelivery::apply(TriggerContext const&) const */

void __thiscall ChainTriggerDelivery::apply(ChainTriggerDelivery *this,TriggerContext *param_1)

{
  long lVar1;
  long *plVar2;
  undefined8 *puVar3;
  
  lVar1 = ChainActiveTrigger::apply
                    (*(ChainActiveTriggerPrototype **)
                      (*(long *)PTR_indexToPrototype_102d4d630 + (ulong)*(ushort *)(this + 0x38) * 8
                      ),param_1);
  if (lVar1 != 0) {
    puVar3 = *(undefined8 **)(*(long *)(param_1 + 8) + 0x2e68);
    plVar2 = (long *)(lVar1 + 8);
    *plVar2 = *(long *)(param_1 + 8) + 0x2e60;
    *(undefined8 **)(lVar1 + 0x10) = puVar3;
    *puVar3 = plVar2;
    *(long **)(*plVar2 + 8) = plVar2;
  }
  return;
}



// ===== ClusterTriggerItem::apply  @ 0x101a022ec =====

/* ClusterTriggerItem::apply(TriggerContext const&) const */

void __thiscall ClusterTriggerItem::apply(ClusterTriggerItem *this,TriggerContext *param_1)

{
  TriggerContext *pTVar1;
  TriggerContext *pTVar2;
  undefined8 *puVar3;
  uint uVar4;
  float fVar5;
  float fVar6;
  float fVar7;
  float fVar8;
  float fVar9;
  undefined8 uVar10;
  undefined8 uVar11;
  undefined8 uVar12;
  ulong uVar13;
  TriggerContext *pTVar14;
  uint uVar15;
  long lVar16;
  uint *puVar17;
  undefined8 *puVar18;
  long *plVar19;
  float fVar20;
  uint uVar21;
  float fVar22;
  double dVar23;
  byte bVar24;
  byte bVar30;
  float fVar25;
  byte bVar28;
  byte bVar29;
  byte bVar31;
  byte bVar32;
  byte bVar33;
  undefined8 uVar26;
  ulong uVar27;
  byte bVar34;
  uint uVar35;
  undefined8 uVar36;
  uint local_1dc;
  undefined8 local_1a0;
  undefined8 uStack_198;
  undefined8 uStack_190;
  undefined8 uStack_188;
  undefined8 local_180;
  undefined8 uStack_178;
  undefined8 uStack_170;
  undefined8 uStack_168;
  long local_160;
  undefined8 uStack_158;
  undefined8 uStack_150;
  undefined8 local_148;
  undefined8 local_140;
  undefined8 uStack_138;
  undefined8 local_130;
  ulong local_128;
  undefined8 local_120;
  undefined8 uStack_118;
  undefined8 uStack_110;
  undefined8 uStack_108;
  undefined8 local_100;
  long local_f8 [3];
  long *local_e0;
  undefined8 local_d8;
  undefined8 uStack_d0;
  undefined8 uStack_c8;
  undefined8 uStack_c0;
  undefined8 local_b8;
  long local_b0;
  
  uVar13 = DAT_1029732e0;
  uVar12 = DAT_1029732d8;
  uVar11 = DAT_1029732d0;
  uVar10 = DAT_1029732c8;
  local_b0 = *(long *)PTR____stack_chk_guard_102d481b8;
  uVar15 = *(uint *)(this + 0x50);
  if (uVar15 != 0) {
    local_1dc = 0;
    pTVar1 = param_1 + 0x60;
    pTVar2 = param_1 + 0xa8;
    do {
      fVar20 = *(float *)(this + 0x54);
      lVar16 = *(long *)(param_1 + 0xe8);
      if (fVar20 == 1.0) {
LAB_101a02474:
        if (lVar16 == 0) {
          puVar17 = (uint *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
        }
        else {
          puVar17 = *(uint **)(_global + 0x250);
        }
        uVar4 = *puVar17;
        uVar4 = (uVar4 & 0xffffe) << 0xc | (uVar4 ^ uVar4 << 0xd) >> 0x13;
        *puVar17 = uVar4;
        uVar26 = *(undefined8 *)(puVar17 + 1);
        uVar36 = NEON_ushl(uVar26,uVar10,4);
        uVar36 = NEON_ushl(CONCAT17((byte)((ulong)uVar36 >> 0x38) ^ (byte)((ulong)uVar26 >> 0x38),
                                    CONCAT16((byte)((ulong)uVar36 >> 0x30) ^
                                             (byte)((ulong)uVar26 >> 0x30),
                                             CONCAT15((byte)((ulong)uVar36 >> 0x28) ^
                                                      (byte)((ulong)uVar26 >> 0x28),
                                                      CONCAT14((byte)((ulong)uVar36 >> 0x20) ^
                                                               (byte)((ulong)uVar26 >> 0x20),
                                                               CONCAT13((byte)((ulong)uVar36 >> 0x18
                                                                              ) ^ (byte)((ulong)
                                                  uVar26 >> 0x18),
                                                  CONCAT12((byte)((ulong)uVar36 >> 0x10) ^
                                                           (byte)((ulong)uVar26 >> 0x10),
                                                           CONCAT11((byte)((ulong)uVar36 >> 8) ^
                                                                    (byte)((ulong)uVar26 >> 8),
                                                                    (byte)uVar36 ^ (byte)uVar26)))))
                                            )),uVar11,4);
        uVar27 = NEON_ushl(uVar26,uVar12,4);
        uVar27 = uVar27 & uVar13;
        uVar21 = CONCAT13((byte)((ulong)uVar36 >> 0x18) | (byte)(uVar27 >> 0x18),
                          CONCAT12((byte)((ulong)uVar36 >> 0x10) | (byte)(uVar27 >> 0x10),
                                   CONCAT11((byte)((ulong)uVar36 >> 8) | (byte)(uVar27 >> 8),
                                            (byte)uVar36 | (byte)uVar27)));
        uVar26 = CONCAT17((byte)((ulong)uVar36 >> 0x38) | (byte)(uVar27 >> 0x38),
                          CONCAT16((byte)((ulong)uVar36 >> 0x30) | (byte)(uVar27 >> 0x30),
                                   CONCAT15((byte)((ulong)uVar36 >> 0x28) | (byte)(uVar27 >> 0x28),
                                            CONCAT14((byte)((ulong)uVar36 >> 0x20) |
                                                     (byte)(uVar27 >> 0x20),uVar21))));
        *(undefined8 *)(puVar17 + 1) = uVar26;
        dVar23 = (double)(uVar21 ^ uVar4 ^ (uint)((ulong)uVar26 >> 0x20)) * 2.3283064365386963e-10;
        fVar20 = (float)dVar23;
        if (1.0 <= fVar20) {
          fVar20 = (fVar20 - (float)(int)dVar23) + 1.0;
          fVar20 = fVar20 - (float)(int)fVar20;
        }
        uVar4 = *(uint *)(this + 0x58);
        if (uVar4 != 0) {
          uVar15 = 0;
          do {
            pTVar14 = param_1 + 0x68;
            if (*(int *)(param_1 + 0x68) == 0x7fffffff) {
              if (*(long *)pTVar1 == 0) {
                    /* WARNING: Subroutine does not return */
                Logging::logAndAbortOrThrow
                          ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/ShootingTarget.cpp"
                           ,0xc,9,"Unset shooting target");
              }
              pTVar14 = (TriggerContext *)(*(long *)pTVar1 + 0x50);
            }
            if (*(long *)(param_1 + 0xe8) == 0) {
              puVar17 = (uint *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
              fVar22 = *(float *)(this + 0x5c);
              fVar25 = *(float *)(this + 0x60);
            }
            else {
              puVar17 = *(uint **)(_global + 0x250);
              fVar22 = *(float *)(this + 0x5c);
              fVar25 = *(float *)(this + 0x60);
            }
            if (fVar25 != 0.0) {
              uVar21 = *puVar17;
              uVar21 = (uVar21 & 0xffffe) << 0xc | (uVar21 ^ uVar21 << 0xd) >> 0x13;
              uVar26 = *(undefined8 *)(puVar17 + 1);
              uVar36 = NEON_ushl(uVar26,uVar10,4);
              uVar36 = NEON_ushl(CONCAT17((byte)((ulong)uVar36 >> 0x38) ^
                                          (byte)((ulong)uVar26 >> 0x38),
                                          CONCAT16((byte)((ulong)uVar36 >> 0x30) ^
                                                   (byte)((ulong)uVar26 >> 0x30),
                                                   CONCAT15((byte)((ulong)uVar36 >> 0x28) ^
                                                            (byte)((ulong)uVar26 >> 0x28),
                                                            CONCAT14((byte)((ulong)uVar36 >> 0x20) ^
                                                                     (byte)((ulong)uVar26 >> 0x20),
                                                                     CONCAT13((byte)((ulong)uVar36
                                                                                    >> 0x18) ^
                                                                              (byte)((ulong)uVar26
                                                                                    >> 0x18),
                                                                              CONCAT12((byte)((ulong
                                                  )uVar36 >> 0x10) ^ (byte)((ulong)uVar26 >> 0x10),
                                                  CONCAT11((byte)((ulong)uVar36 >> 8) ^
                                                           (byte)((ulong)uVar26 >> 8),
                                                           (byte)uVar36 ^ (byte)uVar26))))))),uVar11
                                 ,4);
              uVar27 = NEON_ushl(uVar26,uVar12,4);
              uVar27 = uVar27 & uVar13;
              uVar35 = CONCAT13((byte)((ulong)uVar36 >> 0x18) | (byte)(uVar27 >> 0x18),
                                CONCAT12((byte)((ulong)uVar36 >> 0x10) | (byte)(uVar27 >> 0x10),
                                         CONCAT11((byte)((ulong)uVar36 >> 8) | (byte)(uVar27 >> 8),
                                                  (byte)uVar36 | (byte)uVar27)));
              uVar26 = CONCAT17((byte)((ulong)uVar36 >> 0x38) | (byte)(uVar27 >> 0x38),
                                CONCAT16((byte)((ulong)uVar36 >> 0x30) | (byte)(uVar27 >> 0x30),
                                         CONCAT15((byte)((ulong)uVar36 >> 0x28) |
                                                  (byte)(uVar27 >> 0x28),
                                                  CONCAT14((byte)((ulong)uVar36 >> 0x20) |
                                                           (byte)(uVar27 >> 0x20),uVar35))));
              *(undefined8 *)(puVar17 + 1) = uVar26;
              *puVar17 = uVar21;
              fVar22 = fVar22 + fVar25 * -0.5 +
                       fVar25 * (float)((double)(uVar35 ^ uVar21 ^ (uint)((ulong)uVar26 >> 0x20)) *
                                       2.3283064365386963e-10);
            }
            fVar25 = fVar20 + -0.25;
            fVar5 = 0.5;
            if (fVar25 <= 0.0) {
              fVar5 = -0.5;
            }
            fVar6 = 0.5;
            if (fVar20 <= 0.0) {
              fVar6 = -0.5;
            }
            puVar18 = *(undefined8 **)(this + 8);
            puVar3 = *(undefined8 **)(this + 0x10);
            if (puVar18 != puVar3) {
              fVar8 = 0.25 - ABS(fVar25 - (float)(long)(fVar25 + fVar5));
              fVar25 = 0.25 - ABS(fVar20 - (float)(long)(fVar6 + fVar20));
              fVar6 = fVar8 * fVar8;
              fVar7 = fVar6 * fVar6;
              fVar5 = fVar25 * fVar25;
              fVar9 = fVar5 * fVar5;
              uVar26 = CONCAT44(*(int *)(pTVar14 + 4) +
                                (int)(-(fVar25 * (fVar9 * fVar9 * 39.657356 +
                                                 (6.2831855 - fVar5 * 41.341675) +
                                                 fVar9 * (81.60201 - fVar5 * 76.56888))) * fVar22 *
                                     256.0),
                                *(int *)pTVar14 +
                                (int)(fVar8 * (fVar7 * fVar7 * 39.657356 +
                                              (6.2831855 - fVar6 * 41.341675) +
                                              fVar7 * (81.60201 - fVar6 * 76.56888)) * fVar22 *
                                     256.0));
              do {
                plVar19 = (long *)*puVar18;
                uStack_118 = *(undefined8 *)(param_1 + 0x88);
                local_120 = *(undefined8 *)(param_1 + 0x80);
                uStack_108 = *(undefined8 *)(param_1 + 0x98);
                uStack_110 = *(undefined8 *)(param_1 + 0x90);
                local_100 = *(undefined8 *)(param_1 + 0xa0);
                uStack_158 = *(undefined8 *)(param_1 + 0x48);
                local_160 = *(long *)(param_1 + 0x40);
                local_148 = *(undefined8 *)(param_1 + 0x58);
                uStack_150 = *(undefined8 *)(param_1 + 0x50);
                uStack_138 = *(undefined8 *)(param_1 + 0x68);
                local_140 = *(undefined8 *)(param_1 + 0x60);
                local_128 = *(ulong *)(param_1 + 0x78);
                local_130 = *(undefined8 *)(param_1 + 0x70);
                uStack_198 = *(undefined8 *)(param_1 + 8);
                local_1a0 = *(undefined8 *)param_1;
                uStack_188 = *(undefined8 *)(param_1 + 0x18);
                uStack_190 = *(undefined8 *)(param_1 + 0x10);
                uStack_178 = *(undefined8 *)(param_1 + 0x28);
                local_180 = *(undefined8 *)(param_1 + 0x20);
                uStack_168 = *(undefined8 *)(param_1 + 0x38);
                uStack_170 = *(undefined8 *)(param_1 + 0x30);
                pTVar14 = *(TriggerContext **)(param_1 + 0xc0);
                if (pTVar14 == (TriggerContext *)0x0) {
                  local_e0 = (long *)0x0;
                }
                else if (pTVar14 == pTVar2) {
                  local_e0 = local_f8;
                  (**(code **)(*(long *)pTVar2 + 0x18))(pTVar2,local_f8);
                }
                else {
                  local_e0 = (long *)(**(code **)(*(long *)pTVar14 + 0x10))();
                }
                uStack_d0 = *(undefined8 *)(param_1 + 0xd0);
                local_d8 = *(undefined8 *)(param_1 + 200);
                uStack_c0 = *(undefined8 *)(param_1 + 0xe0);
                uStack_c8 = *(undefined8 *)(param_1 + 0xd8);
                local_b8 = *(undefined8 *)(param_1 + 0xe8);
                if ((TriggerContext *)&local_160 != pTVar1) {
                  local_160 = *(long *)pTVar1;
                  if ((local_160 != 0) && ((*(ushort *)(local_160 + 0x58) & 0x10) != 0)) {
                    local_160 = 0;
                  }
                  uStack_150 = *(undefined8 *)(param_1 + 0x70);
                  uStack_158 = *(undefined8 *)(param_1 + 0x68);
                  local_148 = CONCAT35(local_148._5_3_,*(undefined5 *)(param_1 + 0x78));
                }
                local_140 = 0;
                local_128 = local_128 & 0xffffff0000000000;
                uStack_138 = uVar26;
                local_130 = uVar26;
                (**(code **)(*plVar19 + 0x18))(plVar19,&local_1a0);
                if (local_e0 == local_f8) {
                  lVar16 = 4;
                  plVar19 = local_f8;
LAB_101a0275c:
                  (**(code **)(*plVar19 + lVar16 * 8))();
                }
                else if (local_e0 != (long *)0x0) {
                  lVar16 = 5;
                  plVar19 = local_e0;
                  goto LAB_101a0275c;
                }
                puVar18 = puVar18 + 1;
              } while (puVar18 != puVar3);
            }
            fVar20 = 1.0 / (float)uVar4 + fVar20;
            if ((fVar20 < 0.0) || (1.0 <= fVar20)) {
              fVar20 = (fVar20 - (float)(int)fVar20) + 1.0;
              fVar20 = fVar20 - (float)(int)fVar20;
            }
            uVar15 = uVar15 + 1;
          } while (uVar15 < *(uint *)(this + 0x58));
          uVar15 = *(uint *)(this + 0x50);
        }
      }
      else {
        if (lVar16 == 0) {
          puVar18 = (undefined8 *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
        }
        else {
          puVar18 = *(undefined8 **)(_global + 0x250);
        }
        uVar26 = *puVar18;
        uVar36 = NEON_ushl(uVar26,DAT_1029732a8,4);
        uVar36 = NEON_ushl(CONCAT17((byte)((ulong)uVar36 >> 0x38) ^ (byte)((ulong)uVar26 >> 0x38),
                                    CONCAT16((byte)((ulong)uVar36 >> 0x30) ^
                                             (byte)((ulong)uVar26 >> 0x30),
                                             CONCAT15((byte)((ulong)uVar36 >> 0x28) ^
                                                      (byte)((ulong)uVar26 >> 0x28),
                                                      CONCAT14((byte)((ulong)uVar36 >> 0x20) ^
                                                               (byte)((ulong)uVar26 >> 0x20),
                                                               CONCAT13((byte)((ulong)uVar36 >> 0x18
                                                                              ) ^ (byte)((ulong)
                                                  uVar26 >> 0x18),
                                                  CONCAT12((byte)((ulong)uVar36 >> 0x10) ^
                                                           (byte)((ulong)uVar26 >> 0x10),
                                                           CONCAT11((byte)((ulong)uVar36 >> 8) ^
                                                                    (byte)((ulong)uVar26 >> 8),
                                                                    (byte)uVar36 ^ (byte)uVar26)))))
                                            )),DAT_1029732b0,4);
        uVar27 = NEON_ushl(uVar26,DAT_1029732b8,4);
        uVar27 = uVar27 & DAT_1029732c0;
        bVar24 = (byte)uVar36 | (byte)uVar27;
        bVar28 = (byte)((ulong)uVar36 >> 8) | (byte)(uVar27 >> 8);
        bVar29 = (byte)((ulong)uVar36 >> 0x10) | (byte)(uVar27 >> 0x10);
        bVar30 = (byte)((ulong)uVar36 >> 0x18) | (byte)(uVar27 >> 0x18);
        bVar31 = (byte)((ulong)uVar36 >> 0x20) | (byte)(uVar27 >> 0x20);
        bVar32 = (byte)((ulong)uVar36 >> 0x28) | (byte)(uVar27 >> 0x28);
        bVar33 = (byte)((ulong)uVar36 >> 0x30) | (byte)(uVar27 >> 0x30);
        bVar34 = (byte)((ulong)uVar36 >> 0x38) | (byte)(uVar27 >> 0x38);
        *puVar18 = CONCAT17(bVar34,CONCAT16(bVar33,CONCAT15(bVar32,CONCAT14(bVar31,CONCAT13(bVar30,
                                                  CONCAT12(bVar29,CONCAT11(bVar28,bVar24)))))));
        uVar4 = *(uint *)(puVar18 + 1);
        uVar4 = (uVar4 & 0x7ff0) << 0x11 | (uVar4 ^ uVar4 << 3) >> 0xb;
        *(uint *)(puVar18 + 1) = uVar4;
        if ((double)(CONCAT13(bVar34 ^ bVar30,
                              CONCAT12(bVar33 ^ bVar29,CONCAT11(bVar32 ^ bVar28,bVar31 ^ bVar24))) ^
                    uVar4) * 2.3283064365386963e-10 <= (double)fVar20) goto LAB_101a02474;
      }
      local_1dc = local_1dc + 1;
    } while (local_1dc < uVar15);
  }
  if (*(long *)PTR____stack_chk_guard_102d481b8 == local_b0) {
    return;
  }
                    /* WARNING: Subroutine does not return */
  ___stack_chk_fail();
}



// ===== DelayedActiveTrigger::apply  @ 0x101a10970 =====

/* DelayedActiveTrigger::apply(DelayedActiveTriggerPrototype const*, TriggerContext const&) */

ActiveTrigger *
DelayedActiveTrigger::apply(DelayedActiveTriggerPrototype *param_1,TriggerContext *param_2)

{
  ActiveTrigger *this;
  
  this = operator_new(0x160);
  ActiveTrigger::ActiveTrigger(this,(ActiveTriggerPrototype *)param_1,param_2);
  *(undefined ***)this = &PTR__DelayedActiveTrigger_102f92748;
  *(undefined4 *)(this + 0x150) = 0;
  *(undefined8 *)(this + 0x158) = 0;
  return this;
}



// ===== DelayedActiveTriggerPrototype::apply  @ 0x101a115b8 =====

/* DelayedActiveTriggerPrototype::apply(TriggerContext const&) const */

void __thiscall
DelayedActiveTriggerPrototype::apply(DelayedActiveTriggerPrototype *this,TriggerContext *param_1)

{
  ActiveTrigger *pAVar1;
  long lVar2;
  undefined8 *puVar3;
  
  pAVar1 = operator_new(0x160);
  ActiveTrigger::ActiveTrigger(pAVar1,(ActiveTriggerPrototype *)this,param_1);
  *(undefined ***)pAVar1 = &PTR__DelayedActiveTrigger_102f92748;
  *(undefined4 *)(pAVar1 + 0x150) = 0;
  *(undefined8 *)(pAVar1 + 0x158) = 0;
  lVar2 = *(long *)(param_1 + 8);
  puVar3 = *(undefined8 **)(lVar2 + 0x2e68);
  *(undefined8 **)(pAVar1 + 0x10) = puVar3;
  pAVar1 = pAVar1 + 8;
  *(long *)pAVar1 = lVar2 + 0x2e60;
  *puVar3 = pAVar1;
  *(ActiveTrigger **)(*(long *)pAVar1 + 8) = pAVar1;
  return;
}



// ===== DelayedTriggerDelivery::apply  @ 0x101a119c8 =====

/* DelayedTriggerDelivery::apply(TriggerContext const&) const */

void __thiscall DelayedTriggerDelivery::apply(DelayedTriggerDelivery *this,TriggerContext *param_1)

{
  ActiveTrigger *pAVar1;
  long lVar2;
  undefined8 *puVar3;
  ActiveTriggerPrototype *pAVar4;
  
  pAVar4 = *(ActiveTriggerPrototype **)
            (*(long *)PTR_indexToPrototype_102d4d630 + (ulong)*(ushort *)(this + 0x38) * 8);
  pAVar1 = operator_new(0x160);
  ActiveTrigger::ActiveTrigger(pAVar1,pAVar4,param_1);
  *(undefined ***)pAVar1 = &PTR__DelayedActiveTrigger_102f92748;
  *(undefined4 *)(pAVar1 + 0x150) = 0;
  *(undefined8 *)(pAVar1 + 0x158) = 0;
  lVar2 = *(long *)(param_1 + 8);
  puVar3 = *(undefined8 **)(lVar2 + 0x2e68);
  *(undefined8 **)(pAVar1 + 0x10) = puVar3;
  pAVar1 = pAVar1 + 8;
  *(long *)pAVar1 = lVar2 + 0x2e60;
  *puVar3 = pAVar1;
  *(ActiveTrigger **)(*(long *)pAVar1 + 8) = pAVar1;
  return;
}



// ===== DirectTriggerItem::apply  @ 0x101a13fe4 =====

/* DirectTriggerItem::apply(TriggerContext const&) const */

void __thiscall DirectTriggerItem::apply(DirectTriggerItem *this,TriggerContext *param_1)

{
  uint uVar1;
  DirectTriggerItem DVar2;
  undefined8 uVar3;
  undefined8 uVar4;
  undefined1 uVar5;
  int iVar6;
  long lVar7;
  uint uVar8;
  undefined8 *puVar9;
  ulong uVar10;
  uint uVar11;
  long *plVar12;
  undefined8 uVar13;
  undefined8 *puVar14;
  float fVar16;
  byte bVar17;
  byte bVar20;
  byte bVar21;
  byte bVar22;
  byte bVar23;
  byte bVar24;
  byte bVar25;
  undefined8 uVar18;
  ulong uVar19;
  byte bVar26;
  undefined8 uVar27;
  undefined8 *puVar15;
  
  if ((((this[0x58] != (DirectTriggerItem)0x0) &&
       (plVar12 = *(long **)(param_1 + 0x60), plVar12 != (long *)0x0)) &&
      ((*(ushort *)(plVar12 + 0xb) >> 4 & 1) == 0)) &&
     (lVar7 = (**(code **)(*plVar12 + 0xc60))(plVar12), lVar7 != 0)) {
    uVar8 = *(uint *)(plVar12[9] + 0x2b8);
    if (((*(uint *)(this + 0x20) & uVar8) == 0) &&
       (uVar8 != 0 || *(uint *)(this + 0x20) != 0xfffffff)) {
      return;
    }
    if (this[0x39] == (DirectTriggerItem)0x0) {
      uVar10 = plVar12[0xe];
      uVar19 = *(ulong *)(this + 0x28);
      if ((uVar10 & 0xffffffffffffff & uVar19) == 0) {
        return;
      }
      bVar17 = (byte)(uVar19 >> 0x38) & 1;
      if ((uVar19 & 0xffffffffffffff) != (uVar10 & 0xffffffffffffff)) {
        bVar17 = 1;
      }
      if (((bVar17 | (byte)(uVar10 >> 0x38) & 1) != 1 || (uVar19 & 0x400000000000000) != 0) ||
          (uVar10 & 0x400000000000000) != 0) {
        return;
      }
    }
    if ((*(ulong *)(this + 0x48) & *(ulong *)(plVar12[9] + 0x2a0)) == 0) {
      return;
    }
    DVar2 = this[0x38];
    uVar13 = *(undefined8 *)(*(long *)(plVar12[0x10] + 0x3c8) + (ulong)(byte)param_1[0x10] * 8);
    uVar5 = (**(code **)(*plVar12 + 0x220))(plVar12);
    iVar6 = ForceCondition::forceConditionFullfilled(DVar2,uVar13,uVar5);
    if (iVar6 == 0) {
      return;
    }
  }
  uVar10 = DAT_1029732c0;
  uVar4 = DAT_1029732b8;
  uVar3 = DAT_1029732b0;
  uVar13 = DAT_1029732a8;
  uVar8 = *(uint *)(this + 0x50);
  if (uVar8 != 0) {
    uVar11 = 0;
    do {
      fVar16 = *(float *)(this + 0x54);
      if (fVar16 == 1.0) {
LAB_101a14180:
        puVar9 = *(undefined8 **)(this + 0x10);
        puVar14 = *(undefined8 **)(this + 8);
        if (*(undefined8 **)(this + 8) != puVar9) {
          do {
            puVar15 = puVar14 + 1;
            (**(code **)(*(long *)*puVar14 + 0x18))((long *)*puVar14,param_1);
            puVar14 = puVar15;
          } while (puVar15 != puVar9);
          uVar8 = *(uint *)(this + 0x50);
        }
      }
      else {
        if (*(long *)(param_1 + 0xe8) == 0) {
          puVar9 = (undefined8 *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
        }
        else {
          puVar9 = *(undefined8 **)(_global + 0x250);
        }
        uVar18 = *puVar9;
        uVar27 = NEON_ushl(uVar18,uVar13,4);
        uVar27 = NEON_ushl(CONCAT17((byte)((ulong)uVar27 >> 0x38) ^ (byte)((ulong)uVar18 >> 0x38),
                                    CONCAT16((byte)((ulong)uVar27 >> 0x30) ^
                                             (byte)((ulong)uVar18 >> 0x30),
                                             CONCAT15((byte)((ulong)uVar27 >> 0x28) ^
                                                      (byte)((ulong)uVar18 >> 0x28),
                                                      CONCAT14((byte)((ulong)uVar27 >> 0x20) ^
                                                               (byte)((ulong)uVar18 >> 0x20),
                                                               CONCAT13((byte)((ulong)uVar27 >> 0x18
                                                                              ) ^ (byte)((ulong)
                                                  uVar18 >> 0x18),
                                                  CONCAT12((byte)((ulong)uVar27 >> 0x10) ^
                                                           (byte)((ulong)uVar18 >> 0x10),
                                                           CONCAT11((byte)((ulong)uVar27 >> 8) ^
                                                                    (byte)((ulong)uVar18 >> 8),
                                                                    (byte)uVar27 ^ (byte)uVar18)))))
                                            )),uVar3,4);
        uVar19 = NEON_ushl(uVar18,uVar4,4);
        uVar19 = uVar19 & uVar10;
        bVar17 = (byte)uVar27 | (byte)uVar19;
        bVar20 = (byte)((ulong)uVar27 >> 8) | (byte)(uVar19 >> 8);
        bVar21 = (byte)((ulong)uVar27 >> 0x10) | (byte)(uVar19 >> 0x10);
        bVar22 = (byte)((ulong)uVar27 >> 0x18) | (byte)(uVar19 >> 0x18);
        bVar23 = (byte)((ulong)uVar27 >> 0x20) | (byte)(uVar19 >> 0x20);
        bVar24 = (byte)((ulong)uVar27 >> 0x28) | (byte)(uVar19 >> 0x28);
        bVar25 = (byte)((ulong)uVar27 >> 0x30) | (byte)(uVar19 >> 0x30);
        bVar26 = (byte)((ulong)uVar27 >> 0x38) | (byte)(uVar19 >> 0x38);
        *puVar9 = CONCAT17(bVar26,CONCAT16(bVar25,CONCAT15(bVar24,CONCAT14(bVar23,CONCAT13(bVar22,
                                                  CONCAT12(bVar21,CONCAT11(bVar20,bVar17)))))));
        uVar1 = *(uint *)(puVar9 + 1);
        uVar1 = (uVar1 & 0x7ff0) << 0x11 | (uVar1 ^ uVar1 << 3) >> 0xb;
        *(uint *)(puVar9 + 1) = uVar1;
        if ((double)(CONCAT13(bVar26 ^ bVar22,
                              CONCAT12(bVar25 ^ bVar21,CONCAT11(bVar24 ^ bVar20,bVar23 ^ bVar17))) ^
                    uVar1) * 2.3283064365386963e-10 <= (double)fVar16) goto LAB_101a14180;
      }
      uVar11 = uVar11 + 1;
    } while (uVar11 < uVar8);
  }
  return;
}



// ===== LineTriggerItem::apply  @ 0x101a16fc8 =====

/* LineTriggerItem::apply(TriggerContext const&) const */

void __thiscall LineTriggerItem::apply(LineTriggerItem *this,TriggerContext *param_1)

{
  ulong uVar1;
  uint uVar2;
  uint uVar3;
  ulong uVar4;
  undefined8 *puVar5;
  LineTriggerItem LVar6;
  uint uVar7;
  int iVar8;
  int iVar9;
  short sVar10;
  short sVar11;
  undefined8 uVar12;
  undefined8 uVar13;
  undefined8 uVar14;
  ulong uVar15;
  uint uVar16;
  uint uVar17;
  uint uVar18;
  uint uVar19;
  long lVar20;
  long lVar21;
  bool bVar22;
  bool bVar23;
  bool bVar24;
  bool bVar25;
  undefined1 uVar26;
  int iVar27;
  int iVar28;
  void *pvVar29;
  TriggerContext *pTVar30;
  undefined8 *puVar31;
  long lVar32;
  ulong uVar33;
  ulong uVar34;
  undefined8 *puVar35;
  TriggerContext *pTVar36;
  long *plVar37;
  undefined8 *puVar38;
  int iVar39;
  uint uVar40;
  ulong uVar41;
  long lVar42;
  uint uVar43;
  TriggerContext *pTVar44;
  TriggerContext *pTVar45;
  uint uVar46;
  long *plVar47;
  TriggerContext *pTVar48;
  float fVar49;
  double dVar50;
  undefined1 *puVar51;
  byte bVar52;
  float fVar53;
  byte bVar58;
  byte bVar59;
  byte bVar61;
  byte bVar62;
  byte bVar63;
  undefined8 uVar54;
  ulong uVar55;
  byte bVar60;
  byte bVar64;
  double dVar56;
  undefined1 *puVar57;
  float fVar65;
  undefined8 uVar66;
  double dVar67;
  double dVar68;
  double dVar69;
  int local_228;
  long local_1d8;
  undefined8 *local_1d0;
  undefined8 *local_1c0;
  undefined8 local_1b8;
  undefined8 local_1b0;
  undefined4 local_1a8;
  undefined8 local_1a0;
  undefined8 uStack_198;
  undefined8 local_190;
  undefined8 local_188;
  long local_180;
  long *plStack_178;
  long local_170;
  undefined8 uStack_168;
  undefined8 local_160;
  undefined8 uStack_158;
  undefined8 local_150;
  ulong local_148;
  long *local_140;
  undefined8 uStack_138;
  undefined8 local_130;
  ulong local_128;
  undefined8 local_120;
  undefined8 uStack_118;
  undefined8 uStack_110;
  undefined8 uStack_108;
  undefined8 local_100;
  long local_f8 [3];
  long *local_e0;
  undefined8 local_d8;
  undefined8 uStack_d0;
  undefined8 uStack_c8;
  undefined8 uStack_c0;
  undefined8 local_b8;
  long local_b0;
  
  uVar15 = DAT_1029732c0;
  uVar14 = DAT_1029732b8;
  uVar13 = DAT_1029732b0;
  uVar12 = DAT_1029732a8;
  local_b0 = *(long *)PTR____stack_chk_guard_102d481b8;
  pTVar30 = param_1 + 0x68;
  if (*(int *)pTVar30 == 0x7fffffff) {
    if (*(long *)(param_1 + 0x60) == 0) goto LAB_101a17c50;
    pTVar30 = (TriggerContext *)(*(long *)(param_1 + 0x60) + 0x50);
  }
  pTVar36 = param_1 + 0x48;
  iVar28 = *(int *)pTVar36;
  iVar39 = *(int *)pTVar30;
  local_228 = *(int *)(pTVar30 + 4);
  pTVar48 = param_1 + 0x40;
  pTVar30 = param_1 + 0x50;
  if (*(int *)pTVar30 == 0x7fffffff) {
    if (iVar28 == 0x7fffffff) {
      plVar37 = *(long **)pTVar48;
      if (plVar37 == (long *)0x0) {
                    /* WARNING: Subroutine does not return */
        Logging::logAndAbortOrThrow
                  ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/ShootingTarget.cpp"
                   ,0x58,9,"Unset shooting target");
      }
      pTVar36 = (TriggerContext *)(plVar37 + 10);
      goto LAB_101a1708c;
    }
LAB_101a170ac:
    pTVar44 = param_1 + 0x48;
    bVar22 = false;
  }
  else {
    pTVar36 = pTVar30;
    if (iVar28 != 0x7fffffff) goto LAB_101a170ac;
    plVar37 = *(long **)pTVar48;
    if (plVar37 == (long *)0x0) goto LAB_101a17c50;
LAB_101a1708c:
    pTVar44 = (TriggerContext *)(plVar37 + 10);
    bVar22 = true;
  }
  pTVar45 = param_1 + 0x48;
  iVar28 = *(int *)pTVar36 - iVar39;
  iVar27 = *(int *)(pTVar36 + 4) - local_228;
  iVar8 = *(int *)pTVar36 - *(int *)pTVar44;
  iVar9 = *(int *)(pTVar36 + 4) - *(int *)(pTVar44 + 4);
  if ((long)iVar27 * (long)iVar27 + (long)iVar28 * (long)iVar28 <
      (long)iVar9 * (long)iVar9 + (long)iVar8 * (long)iVar8) {
    pTVar36 = pTVar45;
    if (bVar22) {
      if (*(long **)pTVar48 == (long *)0x0) {
LAB_101a17c50:
                    /* WARNING: Subroutine does not return */
        Logging::logAndAbortOrThrow
                  ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/ShootingTarget.cpp"
                   ,0xc,9,"Unset shooting target");
      }
      pTVar36 = (TriggerContext *)(*(long **)pTVar48 + 10);
    }
    pTVar44 = pTVar36;
    if (*(int *)pTVar30 != 0x7fffffff) {
      pTVar44 = pTVar30;
    }
    iVar39 = (iVar39 - *(int *)pTVar44) + *(int *)pTVar36;
    local_228 = (local_228 - *(int *)(pTVar44 + 4)) + *(int *)(pTVar36 + 4);
  }
  if (*(int *)(this + 0x50) == 0) {
LAB_101a17bcc:
    if (*(long *)PTR____stack_chk_guard_102d481b8 == local_b0) {
      return;
    }
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail();
  }
  uVar46 = 0;
  pTVar30 = param_1 + 0xa8;
LAB_101a171bc:
  fVar49 = *(float *)(this + 0x54);
  if (fVar49 != 1.0) {
    if (*(long *)(param_1 + 0xe8) == 0) {
      puVar31 = (undefined8 *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
    }
    else {
      puVar31 = *(undefined8 **)(_global + 0x250);
    }
    uVar54 = *puVar31;
    uVar66 = NEON_ushl(uVar54,uVar12,4);
    uVar66 = NEON_ushl(CONCAT17((byte)((ulong)uVar66 >> 0x38) ^ (byte)((ulong)uVar54 >> 0x38),
                                CONCAT16((byte)((ulong)uVar66 >> 0x30) ^
                                         (byte)((ulong)uVar54 >> 0x30),
                                         CONCAT15((byte)((ulong)uVar66 >> 0x28) ^
                                                  (byte)((ulong)uVar54 >> 0x28),
                                                  CONCAT14((byte)((ulong)uVar66 >> 0x20) ^
                                                           (byte)((ulong)uVar54 >> 0x20),
                                                           CONCAT13((byte)((ulong)uVar66 >> 0x18) ^
                                                                    (byte)((ulong)uVar54 >> 0x18),
                                                                    CONCAT12((byte)((ulong)uVar66 >>
                                                                                   0x10) ^
                                                                             (byte)((ulong)uVar54 >>
                                                                                   0x10),
                                                                             CONCAT11((byte)((ulong)
                                                  uVar66 >> 8) ^ (byte)((ulong)uVar54 >> 8),
                                                  (byte)uVar66 ^ (byte)uVar54))))))),uVar13,4);
    uVar55 = NEON_ushl(uVar54,uVar14,4);
    uVar55 = uVar55 & uVar15;
    bVar52 = (byte)uVar66 | (byte)uVar55;
    bVar58 = (byte)((ulong)uVar66 >> 8) | (byte)(uVar55 >> 8);
    bVar59 = (byte)((ulong)uVar66 >> 0x10) | (byte)(uVar55 >> 0x10);
    bVar60 = (byte)((ulong)uVar66 >> 0x18) | (byte)(uVar55 >> 0x18);
    bVar61 = (byte)((ulong)uVar66 >> 0x20) | (byte)(uVar55 >> 0x20);
    bVar62 = (byte)((ulong)uVar66 >> 0x28) | (byte)(uVar55 >> 0x28);
    bVar63 = (byte)((ulong)uVar66 >> 0x30) | (byte)(uVar55 >> 0x30);
    bVar64 = (byte)((ulong)uVar66 >> 0x38) | (byte)(uVar55 >> 0x38);
    *puVar31 = CONCAT17(bVar64,CONCAT16(bVar63,CONCAT15(bVar62,CONCAT14(bVar61,CONCAT13(bVar60,
                                                  CONCAT12(bVar59,CONCAT11(bVar58,bVar52)))))));
    uVar43 = *(uint *)(puVar31 + 1);
    uVar43 = (uVar43 & 0x7ff0) << 0x11 | (uVar43 ^ uVar43 << 3) >> 0xb;
    *(uint *)(puVar31 + 1) = uVar43;
    if ((double)(CONCAT13(bVar64 ^ bVar60,
                          CONCAT12(bVar63 ^ bVar59,CONCAT11(bVar62 ^ bVar58,bVar61 ^ bVar52))) ^
                uVar43) * 2.3283064365386963e-10 <= (double)fVar49) goto LAB_101a17254;
    goto LAB_101a171ac;
  }
LAB_101a17254:
  pTVar36 = pTVar45;
  if (*(int *)pTVar45 == 0x7fffffff) {
    if (*(long **)pTVar48 == (long *)0x0) goto LAB_101a17c50;
    pTVar36 = (TriggerContext *)(*(long **)pTVar48 + 10);
  }
  iVar28 = *(int *)pTVar36;
  iVar27 = *(int *)(pTVar36 + 4);
  dVar50 = (double)(iVar39 - iVar28) * 0.00390625;
  dVar56 = (double)(local_228 - iVar27) * 0.00390625;
  bVar22 = false;
  bVar24 = true;
  bVar25 = false;
  if (dVar50 < 1e-09) {
    bVar22 = false;
    bVar24 = false;
    bVar25 = true;
    if (!NAN(dVar50)) {
      bVar22 = dVar50 < -1e-09;
      bVar24 = dVar50 == -1e-09;
      bVar25 = false;
    }
  }
  bVar23 = false;
  if ((!bVar24 && bVar22 == bVar25) && (bVar23 = false, !NAN(dVar56))) {
    bVar23 = dVar56 < 1e-09;
  }
  bVar22 = false;
  bVar24 = true;
  bVar25 = false;
  if (bVar23) {
    bVar22 = false;
    bVar24 = false;
    bVar25 = true;
    if (!NAN(dVar56)) {
      bVar22 = dVar56 < -1e-09;
      bVar24 = dVar56 == -1e-09;
      bVar25 = false;
    }
  }
  if (bVar24 || bVar22 != bVar25) {
    dVar67 = (*(double *)(this + 0x58) * *(double *)(param_1 + 0xa0)) /
             SQRT(dVar50 * dVar50 + dVar56 * dVar56);
    dVar50 = dVar50 * dVar67;
    dVar56 = dVar56 * dVar67;
  }
  else {
    dVar56 = 0.0;
    dVar50 = 0.0;
  }
  uStack_118 = *(undefined8 *)(param_1 + 0x88);
  local_120 = *(undefined8 *)(param_1 + 0x80);
  uStack_108 = *(undefined8 *)(param_1 + 0x98);
  uStack_110 = *(undefined8 *)(param_1 + 0x90);
  local_100 = *(undefined8 *)(param_1 + 0xa0);
  uStack_158 = *(undefined8 *)(param_1 + 0x48);
  local_160 = *(undefined8 *)(param_1 + 0x40);
  local_148 = *(ulong *)(param_1 + 0x58);
  local_150 = *(undefined8 *)(param_1 + 0x50);
  uStack_138 = *(undefined8 *)(param_1 + 0x68);
  local_140 = *(long **)(param_1 + 0x60);
  local_128 = *(ulong *)(param_1 + 0x78);
  local_130 = *(undefined8 *)(param_1 + 0x70);
  uStack_198 = *(ulong *)(param_1 + 8);
  local_1a0 = *(long **)param_1;
  local_188 = *(ulong *)(param_1 + 0x18);
  local_190 = *(undefined8 *)(param_1 + 0x10);
  plStack_178 = *(long **)(param_1 + 0x28);
  local_180 = *(long *)(param_1 + 0x20);
  uStack_168 = *(undefined8 *)(param_1 + 0x38);
  local_170 = *(long *)(param_1 + 0x30);
  pTVar36 = *(TriggerContext **)(param_1 + 0xc0);
  if (pTVar36 == (TriggerContext *)0x0) {
    local_e0 = (long *)0x0;
  }
  else if (pTVar36 == pTVar30) {
    local_e0 = local_f8;
    (**(code **)(*(long *)pTVar30 + 0x18))(pTVar30,local_f8);
  }
  else {
    local_e0 = (long *)(**(code **)(*(long *)pTVar36 + 0x10))();
  }
  uStack_d0 = *(undefined8 *)(param_1 + 0xd0);
  local_d8 = *(undefined8 *)(param_1 + 200);
  uStack_c0 = *(undefined8 *)(param_1 + 0xe0);
  uStack_c8 = *(undefined8 *)(param_1 + 0xd8);
  local_b8 = *(undefined8 *)(param_1 + 0xe8);
  uStack_158 = CONCAT44((int)(dVar56 * 256.0) + iVar27,(int)(dVar50 * 256.0) + iVar28);
  local_160 = 0;
  local_148 = local_148 & 0xffffff0000000000;
  if ((TriggerContext *)&local_140 != pTVar48) {
    local_140 = *(long **)pTVar48;
    if ((local_140 != (long *)0x0) && ((*(ushort *)(local_140 + 0xb) & 0x10) != 0)) {
      local_140 = (long *)0x0;
    }
    uStack_138 = *(undefined8 *)(param_1 + 0x48);
    local_130 = *(undefined8 *)(param_1 + 0x50);
    local_128 = CONCAT35(local_128._5_3_,*(undefined5 *)(param_1 + 0x58));
  }
  local_150 = uStack_158;
  TriggerEffect::apply((TriggerEffect *)(this + 0x68),(TriggerContext *)&local_1a0);
  if (local_e0 == local_f8) {
    lVar32 = 4;
    plVar37 = local_f8;
LAB_101a17420:
    (**(code **)(*plVar37 + lVar32 * 8))();
  }
  else if (local_e0 != (long *)0x0) {
    lVar32 = 5;
    plVar37 = local_e0;
    goto LAB_101a17420;
  }
  if (*(long *)(this + 8) != *(long *)(this + 0x10)) {
    dVar67 = *(double *)(this + 0x58);
    dVar69 = *(double *)(this + 0x60);
    dVar68 = *(double *)(param_1 + 0xa0);
    local_1a0 = (long *)CONCAT44(local_1a0._4_4_,0x80010000);
    fVar49 = (float)dVar50;
    fVar53 = (float)dVar56;
    if ((fVar49 == 0.0) || (fVar53 == 0.0)) {
      sVar10 = ((ushort)(fVar49 != 0.0 && fVar49 >= 0.0) - (ushort)(fVar49 < 0.0)) * 0x7fff;
      sVar11 = ((ushort)(fVar53 != 0.0 && fVar53 >= 0.0) - (ushort)(fVar53 < 0.0)) * 0x7fff;
      local_1a0._0_4_ = CONCAT22(sVar11,sVar10);
      if (sVar10 == 0 && sVar11 == 0) {
        local_1a0 = (long *)CONCAT62(local_1a0._2_6_,0x7fff);
      }
    }
    else {
      fVar65 = SQRT(fVar53 * fVar53 + fVar49 * fVar49);
      construct((VectorOrientation *)&local_1a0,fVar49 / fVar65,fVar53 / fVar65);
    }
    local_1b8 = 0;
    local_1b0 = 0;
    local_1a8 = 0x80010000;
    puVar51 = (undefined1 *)(dVar69 * 0.5 * 256.0);
    if (((((double)puVar51 == INFINITY) || ((double)puVar51 == -INFINITY)) ||
        (puVar57 = (undefined1 *)(dVar67 * dVar68 * 0.5 * 256.0), (double)puVar57 == INFINITY)) ||
       ((double)puVar57 == -INFINITY)) {
                    /* WARNING: Subroutine does not return */
      Logging::logAndAbortOrThrow
                ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Util/FixedPointNumber.hpp"
                 ,0x1f,9,"double value not in range for fixed point number: %f");
    }
    if ((double)puVar51 <= -2147483648.0) {
      puVar51 = &DAT_c1e0000000000000;
    }
    dVar67 = (double)NEON_fminnm(puVar51,0x41dfffffffc00000);
    if ((double)puVar57 <= -2147483648.0) {
      puVar57 = &DAT_c1e0000000000000;
    }
    dVar68 = (double)NEON_fminnm(puVar57,0x41dfffffffc00000);
    iVar28 = (int)(dVar50 * 0.5 * 256.0) + iVar28;
    iVar27 = (int)(dVar56 * 0.5 * 256.0) + iVar27;
    local_1b8 = CONCAT44(iVar27 - (int)dVar68,iVar28 - (int)dVar67);
    local_1b0 = CONCAT44(iVar27 + (int)dVar68,iVar28 + (int)dVar67);
    local_1a8 = (undefined4)local_1a0;
    local_1c0 = (undefined8 *)0x0;
    local_1d0 = (undefined8 *)0x0;
    HeuristicEntityIterator<Surface>::HeuristicEntityIterator
              ((Surface *)&local_1a0,*(BoundingBox **)(param_1 + 8));
    plVar37 = local_1a0;
    if (plStack_178 != (long *)0x0) {
      puVar31 = (undefined8 *)0x0;
      uVar16 = (uint)uStack_198;
      uVar55 = uStack_198 & 0xffffffff;
      uVar17 = uStack_198._4_4_;
      uVar18 = (uint)local_190;
      uVar19 = local_190._4_4_;
      local_1d8 = local_180;
      uVar41 = local_188 & 0xffffffff;
      iVar28 = (int)(uint)uStack_198 >> 4;
      uVar33 = uStack_198 & 0xf;
      uVar7 = (uint)uStack_198 | 0xf;
      lVar42 = local_170;
      plVar47 = plStack_178;
      uVar43 = local_188._4_4_;
      lVar32 = local_1d8;
      do {
        local_1d8 = lVar32;
        iVar27 = (**(code **)(*plVar47 + 600))(plVar47,&local_1b8);
        lVar21 = local_1d8;
        if (iVar27 != 0) {
          if (puVar31 == local_1c0) {
            uVar34 = (long)puVar31 - (long)local_1d0;
            lVar32 = (long)uVar34 >> 3;
            uVar1 = lVar32 + 1;
            if (uVar1 >> 0x3d != 0) {
                    /* WARNING: Subroutine does not return */
              std::vector<Entity*,std::allocator<Entity*>>::__throw_length_error_abi_v160006_();
            }
            uVar4 = uVar34 >> 2;
            if (uVar34 >> 2 <= uVar1) {
              uVar4 = uVar1;
            }
            if (0x7ffffffffffffff7 < uVar34) {
              uVar4 = 0x1fffffffffffffff;
            }
            if (uVar4 == 0) {
              pvVar29 = (void *)0x0;
              puVar35 = (undefined8 *)(lVar32 * 8);
              *puVar35 = plVar47;
            }
            else {
              if (uVar4 >> 0x3d != 0) {
                    /* WARNING: Subroutine does not return */
                std::__throw_bad_array_new_length_abi_v160006_();
              }
              pvVar29 = operator_new(uVar4 << 3);
              puVar35 = (undefined8 *)((long)pvVar29 + lVar32 * 8);
              *puVar35 = plVar47;
            }
            puVar38 = puVar35 + 1;
            puVar5 = puVar31;
            while (puVar31 != local_1d0) {
              puVar31 = puVar31 + -1;
              puVar35 = puVar35 + -1;
              *puVar35 = *puVar31;
              puVar5 = local_1d0;
            }
            local_1c0 = (undefined8 *)((long)pvVar29 + uVar4 * 8);
            local_1d0 = puVar35;
            puVar31 = puVar38;
            if (puVar5 != (undefined8 *)0x0) {
              operator_delete(puVar5);
            }
          }
          else {
            *puVar31 = plVar47;
            puVar31 = puVar31 + 1;
          }
        }
LAB_101a17654:
        do {
          lVar32 = lVar21;
          uVar40 = (uint)uVar41;
          if (lVar42 == 0) {
            if ((int)uVar40 < (int)uVar18) {
              uVar40 = uVar40 + 1;
              iVar27 = (int)uVar40 >> 4;
              iVar8 = (int)uVar43 >> 4;
              if ((local_1d8 == 0) ||
                 (*(int *)(local_1d8 + 0xc48) != iVar27 || *(int *)(local_1d8 + 0xc4c) != iVar8)) {
                if ((-*(int *)((long)plVar37 + 0x24) <= iVar27) &&
                   (iVar27 = *(int *)((long)plVar37 + 0x24) + iVar27, iVar27 < (int)plVar37[4])) {
                  plVar47 = (long *)(plVar37[3] + (long)iVar27 * 0x10);
                  if (plVar47 != (long *)0x0) {
                    lVar32 = plVar37[3] + (long)iVar27 * 0x10;
                    iVar27 = *(int *)(lVar32 + 0xc);
                    if (((-iVar27 <= iVar8) &&
                        (iVar27 = iVar27 + iVar8, iVar27 < *(int *)(lVar32 + 8))) &&
                       ((plVar47 = (long *)(*plVar47 + (long)iVar27 * 8), plVar47 != (long *)0x0 &&
                        (local_1d8 = *plVar47, lVar32 = local_1d8, local_1d8 != 0))))
                    goto LAB_101a17734;
                  }
                }
                local_1d8 = 0;
                lVar42 = 0;
                lVar21 = 0;
                uVar41 = (ulong)(uVar40 | 0xf);
              }
              else {
LAB_101a17734:
                lVar42 = *(long *)(local_1d8 + (ulong)(uVar40 & 0xf) * 0x80 +
                                   (ulong)(uVar43 & 0xf) * 8 + 0xc50);
                lVar21 = lVar32;
                uVar41 = (ulong)uVar40;
              }
              goto LAB_101a17654;
            }
            puVar35 = local_1d0;
            if ((int)uVar19 <= (int)uVar43) goto joined_r0x000101a1797c;
            uVar43 = uVar43 + 1;
            iVar27 = (int)uVar43 >> 4;
            if (((local_1d8 == 0) || (*(int *)(local_1d8 + 0xc48) != iVar28)) ||
               (lVar20 = local_1d8, *(int *)(local_1d8 + 0xc4c) != iVar27)) {
              local_1d8 = 0;
              lVar42 = 0;
              uVar41 = (ulong)uVar7;
              lVar21 = 0;
              if (iVar28 < -*(int *)((long)plVar37 + 0x24)) goto LAB_101a17654;
              local_1d8 = 0;
              lVar42 = 0;
              uVar41 = (ulong)uVar7;
              iVar8 = *(int *)((long)plVar37 + 0x24) + iVar28;
              lVar21 = 0;
              if ((int)plVar37[4] <= iVar8) goto LAB_101a17654;
              local_1d8 = 0;
              lVar42 = 0;
              plVar47 = (long *)(plVar37[3] + (long)iVar8 * 0x10);
              uVar41 = (ulong)uVar7;
              lVar21 = 0;
              if (plVar47 == (long *)0x0) goto LAB_101a17654;
              local_1d8 = 0;
              lVar42 = 0;
              lVar32 = plVar37[3] + (long)iVar8 * 0x10;
              iVar8 = *(int *)(lVar32 + 0xc);
              uVar41 = (ulong)uVar7;
              lVar21 = 0;
              if (iVar27 < -iVar8) goto LAB_101a17654;
              local_1d8 = 0;
              lVar42 = 0;
              iVar8 = iVar8 + iVar27;
              uVar41 = (ulong)uVar7;
              lVar21 = 0;
              if (*(int *)(lVar32 + 8) <= iVar8) goto LAB_101a17654;
              local_1d8 = 0;
              lVar42 = 0;
              plVar47 = (long *)(*plVar47 + (long)iVar8 * 8);
              uVar41 = (ulong)uVar7;
              lVar21 = 0;
              if (plVar47 == (long *)0x0) goto LAB_101a17654;
              local_1d8 = 0;
              lVar42 = 0;
              lVar32 = *plVar47;
              uVar41 = (ulong)uVar7;
              lVar20 = lVar32;
              lVar21 = 0;
              if (lVar32 == 0) goto LAB_101a17654;
            }
            local_1d8 = lVar20;
            lVar42 = *(long *)(local_1d8 + uVar33 * 0x80 + (ulong)(uVar43 & 0xf) * 8 + 0xc50);
            lVar21 = lVar32;
            uVar41 = uVar55;
            goto LAB_101a17654;
          }
          plVar47 = *(long **)(lVar42 + 0x20);
          lVar42 = *(long *)(lVar42 + 8);
          uVar2 = (int)plVar47[10] >> 9;
          uVar3 = *(int *)((long)plVar47 + 0x54) >> 9;
          if ((int)uVar2 <= (int)uVar16) {
            uVar2 = uVar16;
          }
          if ((int)uVar18 <= (int)uVar2) {
            uVar2 = uVar18;
          }
          if ((int)uVar3 <= (int)uVar17) {
            uVar3 = uVar17;
          }
          if ((int)uVar19 <= (int)uVar3) {
            uVar3 = uVar19;
          }
          lVar21 = lVar32;
        } while (uVar2 != uVar40 || uVar3 != uVar43);
      } while( true );
    }
  }
LAB_101a171ac:
  uVar46 = uVar46 + 1;
  if (*(uint *)(this + 0x50) <= uVar46) goto LAB_101a17bcc;
  goto LAB_101a171bc;
joined_r0x000101a1797c:
  if (puVar35 == puVar31) goto LAB_101a17980;
  plVar37 = (long *)*puVar35;
  if (((((*(ushort *)(plVar37 + 0xb) >> 4 & 1) == 0) &&
       (lVar32 = (**(code **)(*plVar37 + 0xc58))(plVar37),
       lVar32 != 0 && plVar37 != *(long **)pTVar48)) &&
      (iVar28 = ::BoundingBox::collide
                          ((BoundingBox *)((long)plVar37 + 0x5c),(BoundingBox *)&local_1b8),
      iVar28 != 0)) &&
     ((plVar47 = *(long **)(param_1 + 0xc0), plVar47 == (long *)0x0 ||
      (local_1a0 = plVar37, iVar28 = (**(code **)(*plVar47 + 0x30))(plVar47,&local_1a0), iVar28 != 0
      )))) {
    uVar43 = *(uint *)(plVar37[9] + 0x2b8);
    if (((*(uint *)(this + 0x20) & uVar43) != 0) ||
       (uVar43 == 0 && *(uint *)(this + 0x20) == 0xfffffff)) {
      if (this[0x39] == (LineTriggerItem)0x0) {
        uVar55 = plVar37[0xe];
        uVar41 = *(ulong *)(this + 0x28);
        if ((uVar55 & 0xffffffffffffff & uVar41) != 0) {
          bVar52 = (byte)(uVar41 >> 0x38) & 1;
          if ((uVar41 & 0xffffffffffffff) != (uVar55 & 0xffffffffffffff)) {
            bVar52 = 1;
          }
          if (((bVar52 | (byte)(uVar55 >> 0x38) & 1) == 1 && (uVar41 & 0x400000000000000) == 0) &&
              (uVar55 & 0x400000000000000) == 0) goto LAB_101a17a30;
        }
      }
      else {
LAB_101a17a30:
        if ((*(ulong *)(this + 0x48) & *(ulong *)(plVar37[9] + 0x2a0)) != 0) {
          LVar6 = this[0x38];
          uVar54 = *(undefined8 *)
                    (*(long *)(plVar37[0x10] + 0x3c8) + (ulong)(byte)param_1[0x10] * 8);
          uVar26 = (**(code **)(*plVar37 + 0x220))(plVar37);
          iVar28 = ForceCondition::forceConditionFullfilled(LVar6,uVar54,uVar26);
          if (iVar28 != 0) {
            puVar5 = *(undefined8 **)(this + 0x10);
            for (puVar38 = *(undefined8 **)(this + 8); puVar38 != puVar5; puVar38 = puVar38 + 1) {
              plVar47 = (long *)*puVar38;
              uStack_118 = *(undefined8 *)(param_1 + 0x88);
              local_120 = *(undefined8 *)(param_1 + 0x80);
              uStack_108 = *(undefined8 *)(param_1 + 0x98);
              uStack_110 = *(undefined8 *)(param_1 + 0x90);
              local_100 = *(undefined8 *)(param_1 + 0xa0);
              uStack_158 = *(undefined8 *)(param_1 + 0x48);
              local_160 = *(undefined8 *)(param_1 + 0x40);
              local_148 = *(ulong *)(param_1 + 0x58);
              local_150 = *(undefined8 *)(param_1 + 0x50);
              uStack_138 = *(undefined8 *)(param_1 + 0x68);
              local_140 = *(long **)(param_1 + 0x60);
              local_128 = *(ulong *)(param_1 + 0x78);
              local_130 = *(undefined8 *)(param_1 + 0x70);
              uStack_198 = *(ulong *)(param_1 + 8);
              local_1a0 = *(long **)param_1;
              local_188 = *(ulong *)(param_1 + 0x18);
              local_190 = *(undefined8 *)(param_1 + 0x10);
              plStack_178 = *(long **)(param_1 + 0x28);
              local_180 = *(long *)(param_1 + 0x20);
              uStack_168 = *(undefined8 *)(param_1 + 0x38);
              local_170 = *(long *)(param_1 + 0x30);
              pTVar36 = *(TriggerContext **)(param_1 + 0xc0);
              if (pTVar36 == (TriggerContext *)0x0) {
                local_e0 = (long *)0x0;
              }
              else if (pTVar36 == pTVar30) {
                local_e0 = local_f8;
                (**(code **)(*(long *)pTVar30 + 0x18))(pTVar30,local_f8);
              }
              else {
                local_e0 = (long *)(**(code **)(*(long *)pTVar36 + 0x10))();
              }
              uStack_d0 = *(undefined8 *)(param_1 + 0xd0);
              local_d8 = *(undefined8 *)(param_1 + 200);
              uStack_c0 = *(undefined8 *)(param_1 + 0xe0);
              uStack_c8 = *(undefined8 *)(param_1 + 0xd8);
              local_b8 = *(undefined8 *)(param_1 + 0xe8);
              local_140 = plVar37;
              if ((*(ushort *)(plVar37 + 0xb) & 0x10) != 0) {
                local_140 = (long *)0x0;
              }
              local_130 = 0x7fffffff7fffffff;
              uStack_138 = 0x7fffffff7fffffff;
              local_128 = local_128 & 0xffffff0000000000;
              (**(code **)(*plVar47 + 0x18))(plVar47,&local_1a0);
              if (local_e0 == local_f8) {
                lVar32 = 4;
                plVar47 = local_f8;
LAB_101a17a88:
                (**(code **)(*plVar47 + lVar32 * 8))();
              }
              else if (local_e0 != (long *)0x0) {
                lVar32 = 5;
                plVar47 = local_e0;
                goto LAB_101a17a88;
              }
            }
          }
        }
      }
    }
  }
  puVar35 = puVar35 + 1;
  goto joined_r0x000101a1797c;
LAB_101a17980:
  if (local_1d0 != (undefined8 *)0x0) {
    operator_delete(local_1d0);
  }
  goto LAB_101a171ac;
}



// ===== ProjectileTriggerDelivery::apply  @ 0x101a1a804 =====

/* ProjectileTriggerDelivery::apply(TriggerContext const&) const */

void __thiscall
ProjectileTriggerDelivery::apply(ProjectileTriggerDelivery *this,TriggerContext *param_1)

{
  uint uVar1;
  TriggerContext TVar2;
  char cVar3;
  undefined1 auVar4 [16];
  undefined1 auVar5 [16];
  long lVar6;
  undefined8 *puVar7;
  undefined8 *puVar8;
  Projectile *this_00;
  uint *puVar9;
  undefined8 uVar10;
  long *plVar11;
  ShootingTarget *this_01;
  ShootingTarget *this_02;
  TriggerContext *pTVar12;
  ulong uVar13;
  ulong uVar14;
  long lVar15;
  TriggerContext *pTVar16;
  undefined4 uVar17;
  float fVar18;
  float fVar19;
  double dVar20;
  double dVar21;
  undefined1 auVar22 [16];
  double dVar24;
  undefined1 auVar23 [16];
  byte bVar25;
  byte bVar33;
  byte bVar34;
  int iVar26;
  uint uVar27;
  byte bVar36;
  byte bVar38;
  byte bVar39;
  int iVar37;
  ulong uVar28;
  byte bVar35;
  byte bVar40;
  double dVar29;
  double dVar30;
  undefined1 auVar31 [16];
  undefined1 auVar32 [16];
  double dVar41;
  undefined8 uVar42;
  double dVar43;
  double dVar44;
  undefined1 auVar45 [16];
  undefined8 uVar46;
  double dVar47;
  double local_240;
  double dStack_238;
  undefined8 local_230;
  undefined1 local_228;
  undefined1 local_227;
  undefined1 local_226;
  long local_220;
  ulong uStack_218;
  ulong uStack_210;
  undefined8 uStack_208;
  undefined8 local_200;
  undefined8 uStack_1f8;
  undefined8 uStack_1f0;
  undefined8 uStack_1e8;
  undefined8 local_1e0;
  undefined8 uStack_1d8;
  undefined8 local_1d0;
  undefined4 uStack_1c8;
  undefined3 uStack_1c4;
  undefined1 local_1c1;
  undefined8 local_1c0;
  undefined1 local_1b8;
  undefined8 local_1b0;
  undefined8 uStack_1a8;
  undefined4 local_198 [2];
  double local_190;
  double dStack_188;
  undefined1 local_180;
  undefined7 uStack_17f;
  undefined8 uStack_178;
  undefined8 local_170;
  undefined8 uStack_168;
  undefined8 uStack_160;
  undefined8 uStack_158;
  undefined8 local_150;
  undefined8 uStack_148;
  undefined8 uStack_140;
  undefined8 uStack_138;
  long local_130;
  ulong uStack_128;
  ulong local_120;
  undefined8 local_118;
  undefined8 local_110;
  undefined8 uStack_108;
  undefined8 uStack_100;
  undefined8 uStack_f8;
  undefined8 local_f0;
  long local_e8 [3];
  long *local_d0;
  undefined8 local_c8;
  undefined8 uStack_c0;
  undefined8 local_b8;
  undefined8 uStack_b0;
  undefined8 local_a8;
  long local_98;
  
  local_98 = *(long *)PTR____stack_chk_guard_102d481b8;
  pTVar16 = param_1 + 0x48;
  this_02 = (ShootingTarget *)(param_1 + 0x40);
  if ((*(int *)pTVar16 == 0x7fffffff) &&
     ((*(long *)this_02 == 0 || ((*(ushort *)(*(long *)this_02 + 0x58) >> 4 & 1) != 0))))
  goto LAB_101a1afd4;
  pTVar12 = param_1 + 0x68;
  this_01 = (ShootingTarget *)(param_1 + 0x60);
  if ((*(uint *)pTVar12 == 0x7fffffff) &&
     ((*(long *)this_01 == 0 || ((*(ushort *)(*(long *)this_01 + 0x58) >> 4 & 1) != 0))))
  goto LAB_101a1afd4;
  TriggerDelivery::apply((TriggerDelivery *)this,param_1);
  if ((*(int *)(param_1 + 0x48) == 0x7fffffff) &&
     ((*(long *)this_02 == 0 || ((*(ushort *)(*(long *)this_02 + 0x58) >> 4 & 1) != 0))))
  goto LAB_101a1afd4;
  lVar15 = *(long *)this_01;
  if ((*(uint *)pTVar12 == 0x7fffffff) &&
     ((lVar15 == 0 || ((*(ushort *)(lVar15 + 0x58) >> 4 & 1) != 0)))) goto LAB_101a1afd4;
  uVar13 = *(ulong *)(param_1 + 0x68);
  uVar14 = *(ulong *)(param_1 + 0x70);
  uVar17 = *(undefined4 *)(param_1 + 0x78);
  TVar2 = param_1[0x7c];
  if (*(int *)(param_1 + 0x48) == 0x7fffffff) {
    if (*(long *)this_02 == 0) goto LAB_101a1b038;
    pTVar16 = (TriggerContext *)(*(long *)this_02 + 0x50);
  }
  uVar10 = *(undefined8 *)pTVar16;
  uVar28 = uVar13;
  if (*(uint *)pTVar12 == 0x7fffffff) {
    if (lVar15 == 0) {
LAB_101a1b038:
                    /* WARNING: Subroutine does not return */
      Logging::logAndAbortOrThrow
                ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/ShootingTarget.cpp"
                 ,0xc,9,"Unset shooting target");
    }
    pTVar12 = (TriggerContext *)(lVar15 + 0x50);
    uVar28 = (ulong)*(uint *)pTVar12;
  }
  iVar26 = (int)uVar10;
  iVar37 = (int)((ulong)uVar10 >> 0x20);
  auVar22._0_8_ = (long)((int)uVar28 - iVar26);
  auVar22._8_8_ = (long)(int)(*(uint *)(pTVar12 + 4) - iVar37);
  auVar22 = NEON_scvtf(auVar22,8);
  dVar20 = auVar22._0_8_ * 0.00390625;
  dVar24 = auVar22._8_8_ * 0.00390625;
  lVar6 = (**(code **)(**(long **)(*(long *)PTR_indexToPrototype_102d4c840 +
                                  (ulong)*(ushort *)(this + 0x38) * 8) + 0x460))();
  cVar3 = *(char *)(lVar6 + 0x5c2);
  if (((cVar3 == '\0') && (*(long *)this_01 != 0)) &&
     ((*(ushort *)(*(long *)this_01 + 0x58) >> 4 & 1) == 0)) {
    fVar18 = *(float *)(this + 0x54);
joined_r0x000101a1aa3c:
    if (fVar18 != 0.0) goto LAB_101a1aa58;
LAB_101a1aa90:
    dVar21 = 1.0;
    if (cVar3 != '\0') goto LAB_101a1ab78;
LAB_101a1aa98:
    plVar11 = (long *)PTR_indexToPrototype_102d4c840;
    if (((*(long *)this_01 == 0) || ((*(ushort *)(*(long *)this_01 + 0x58) >> 4 & 1) != 0)) &&
       ((fVar18 = *(float *)(this + 0x50), fVar18 != 0.0 || (*(float *)(this + 0x54) != 0.0))))
    goto LAB_101a1ab84;
  }
  else {
    dVar21 = *(double *)(this + 0x60);
    if ((0.0 < dVar21) && (SQRT(dVar20 * dVar20 + dVar24 * dVar24) < dVar21)) {
      puVar7 = (undefined8 *)ShootingTarget::targetCenterPosition(this_02);
      puVar8 = (undefined8 *)ShootingTarget::targetPosition(this_01);
      auVar45._0_8_ = (long)((int)*puVar8 - (int)*puVar7);
      auVar45._8_8_ = (long)((int)((ulong)*puVar8 >> 0x20) - (int)((ulong)*puVar7 >> 0x20));
      auVar22 = NEON_scvtf(auVar45,8);
      local_190 = auVar22._0_8_ * 0.00390625;
      dStack_188 = auVar22._8_8_ * 0.00390625;
      local_198[0] = Vector::getOrientation((Vector *)&local_190);
      Vector::Vector((Vector *)&local_240,(double *)(this + 0x60),(RealOrientation *)local_198);
      lVar15 = 0;
      uVar17 = 0;
      TVar2 = (TriggerContext)0x0;
      uVar13 = CONCAT44(iVar37 + (int)(dStack_238 * 256.0),iVar26 + (int)(local_240 * 256.0));
      fVar18 = *(float *)(this + 0x54);
      uVar14 = uVar13;
      dVar20 = local_240;
      dVar24 = dStack_238;
      goto joined_r0x000101a1aa3c;
    }
    fVar18 = *(float *)(this + 0x54);
    if (fVar18 == 0.0) goto LAB_101a1aa90;
LAB_101a1aa58:
    if (*(long *)(param_1 + 0xe8) == 0) {
      puVar9 = (uint *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
    }
    else {
      puVar9 = *(uint **)(_global + 0x250);
    }
    uVar1 = *puVar9;
    uVar1 = (uVar1 & 0xffffe) << 0xc | (uVar1 ^ uVar1 << 0xd) >> 0x13;
    *puVar9 = uVar1;
    uVar46 = *(undefined8 *)(puVar9 + 1);
    uVar42 = NEON_ushl(uVar46,DAT_1029732c8,4);
    uVar42 = NEON_ushl(CONCAT17((byte)((ulong)uVar42 >> 0x38) ^ (byte)((ulong)uVar46 >> 0x38),
                                CONCAT16((byte)((ulong)uVar42 >> 0x30) ^
                                         (byte)((ulong)uVar46 >> 0x30),
                                         CONCAT15((byte)((ulong)uVar42 >> 0x28) ^
                                                  (byte)((ulong)uVar46 >> 0x28),
                                                  CONCAT14((byte)((ulong)uVar42 >> 0x20) ^
                                                           (byte)((ulong)uVar46 >> 0x20),
                                                           CONCAT13((byte)((ulong)uVar42 >> 0x18) ^
                                                                    (byte)((ulong)uVar46 >> 0x18),
                                                                    CONCAT12((byte)((ulong)uVar42 >>
                                                                                   0x10) ^
                                                                             (byte)((ulong)uVar46 >>
                                                                                   0x10),
                                                                             CONCAT11((byte)((ulong)
                                                  uVar42 >> 8) ^ (byte)((ulong)uVar46 >> 8),
                                                  (byte)uVar42 ^ (byte)uVar46))))))),DAT_1029732d0,4
                      );
    uVar28 = NEON_ushl(uVar46,DAT_1029732d8,4);
    uVar28 = uVar28 & DAT_1029732e0;
    uVar27 = CONCAT13((byte)((ulong)uVar42 >> 0x18) | (byte)(uVar28 >> 0x18),
                      CONCAT12((byte)((ulong)uVar42 >> 0x10) | (byte)(uVar28 >> 0x10),
                               CONCAT11((byte)((ulong)uVar42 >> 8) | (byte)(uVar28 >> 8),
                                        (byte)uVar42 | (byte)uVar28)));
    uVar46 = CONCAT17((byte)((ulong)uVar42 >> 0x38) | (byte)(uVar28 >> 0x38),
                      CONCAT16((byte)((ulong)uVar42 >> 0x30) | (byte)(uVar28 >> 0x30),
                               CONCAT15((byte)((ulong)uVar42 >> 0x28) | (byte)(uVar28 >> 0x28),
                                        CONCAT14((byte)((ulong)uVar42 >> 0x20) |
                                                 (byte)(uVar28 >> 0x20),uVar27))));
    *(undefined8 *)(puVar9 + 1) = uVar46;
    dVar21 = (double)(fVar18 * ((float)((double)(uVar27 ^ uVar1 ^ (uint)((ulong)uVar46 >> 0x20)) *
                                       2.3283064365386963e-10) + -0.5) + 1.0);
    if (cVar3 == '\0') goto LAB_101a1aa98;
LAB_101a1ab78:
    fVar18 = *(float *)(this + 0x50);
LAB_101a1ab84:
    plVar11 = (long *)PTR_indexToPrototype_102d4c840;
    if (fVar18 != 0.0) {
      if (*(long *)(param_1 + 0xe8) == 0) {
        puVar7 = (undefined8 *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
      }
      else {
        puVar7 = *(undefined8 **)(_global + 0x250);
      }
      uVar46 = *puVar7;
      uVar42 = NEON_ushl(uVar46,DAT_1029732a8,4);
      uVar42 = NEON_ushl(CONCAT17((byte)((ulong)uVar42 >> 0x38) ^ (byte)((ulong)uVar46 >> 0x38),
                                  CONCAT16((byte)((ulong)uVar42 >> 0x30) ^
                                           (byte)((ulong)uVar46 >> 0x30),
                                           CONCAT15((byte)((ulong)uVar42 >> 0x28) ^
                                                    (byte)((ulong)uVar46 >> 0x28),
                                                    CONCAT14((byte)((ulong)uVar42 >> 0x20) ^
                                                             (byte)((ulong)uVar46 >> 0x20),
                                                             CONCAT13((byte)((ulong)uVar42 >> 0x18)
                                                                      ^ (byte)((ulong)uVar46 >> 0x18
                                                                              ),
                                                                      CONCAT12((byte)((ulong)uVar42
                                                                                     >> 0x10) ^
                                                                               (byte)((ulong)uVar46
                                                                                     >> 0x10),
                                                                               CONCAT11((byte)((
                                                  ulong)uVar42 >> 8) ^ (byte)((ulong)uVar46 >> 8),
                                                  (byte)uVar42 ^ (byte)uVar46))))))),DAT_1029732b0,4
                        );
      uVar13 = NEON_ushl(uVar46,DAT_1029732b8,4);
      uVar13 = uVar13 & DAT_1029732c0;
      bVar25 = (byte)uVar42 | (byte)uVar13;
      bVar33 = (byte)((ulong)uVar42 >> 8) | (byte)(uVar13 >> 8);
      bVar34 = (byte)((ulong)uVar42 >> 0x10) | (byte)(uVar13 >> 0x10);
      bVar35 = (byte)((ulong)uVar42 >> 0x18) | (byte)(uVar13 >> 0x18);
      bVar36 = (byte)((ulong)uVar42 >> 0x20) | (byte)(uVar13 >> 0x20);
      bVar38 = (byte)((ulong)uVar42 >> 0x28) | (byte)(uVar13 >> 0x28);
      bVar39 = (byte)((ulong)uVar42 >> 0x30) | (byte)(uVar13 >> 0x30);
      bVar40 = (byte)((ulong)uVar42 >> 0x38) | (byte)(uVar13 >> 0x38);
      *puVar7 = CONCAT17(bVar40,CONCAT16(bVar39,CONCAT15(bVar38,CONCAT14(bVar36,CONCAT13(bVar35,
                                                  CONCAT12(bVar34,CONCAT11(bVar33,bVar25)))))));
      uVar1 = *(uint *)(puVar7 + 1);
      uVar1 = (uVar1 & 0x7ff0) << 0x11 | (uVar1 ^ uVar1 << 3) >> 0xb;
      *(uint *)(puVar7 + 1) = uVar1;
      dVar47 = ((double)(CONCAT13(bVar40 ^ bVar35,
                                  CONCAT12(bVar39 ^ bVar34,CONCAT11(bVar38 ^ bVar33,bVar36 ^ bVar25)
                                          )) ^ uVar1) * 2.3283064365386963e-10 + -0.5) *
               (double)fVar18 * 0.15915494309189535;
      dVar29 = dVar47 + -0.25;
      auVar31._0_8_ = -(ulong)(0.0 < dVar47);
      auVar31._8_8_ = -(ulong)(0.0 < dVar29);
      auVar22 = NEON_fmov(0xbfe0000000000000,8);
      auVar45 = NEON_fmov(0x3fe0000000000000,8);
      auVar22 = auVar22 ^ (auVar22 ^ auVar45) & auVar31;
      auVar32._0_8_ = (long)(dVar47 + auVar22._0_8_);
      auVar32._8_8_ = (long)(dVar29 + auVar22._8_8_);
      auVar22 = NEON_scvtf(auVar32,8);
      dVar29 = dVar29 - auVar22._8_8_;
      auVar23._0_8_ = ABS(dVar47 - auVar22._0_8_);
      auVar23[8] = SUB81(dVar29,0);
      auVar23[9] = (undefined1)((ulong)dVar29 >> 8);
      auVar23[10] = (undefined1)((ulong)dVar29 >> 0x10);
      auVar23[0xb] = (undefined1)((ulong)dVar29 >> 0x18);
      auVar23[0xc] = (undefined1)((ulong)dVar29 >> 0x20);
      auVar23[0xd] = (undefined1)((ulong)dVar29 >> 0x28);
      auVar23[0xe] = (undefined1)((ulong)dVar29 >> 0x30);
      auVar23[0xf] = (byte)((ulong)dVar29 >> 0x38) & 0x7f;
      auVar22 = NEON_fmov(0x3fd0000000000000,8);
      dVar47 = auVar22._0_8_ - auVar23._0_8_;
      dVar29 = auVar22._8_8_ - auVar23._8_8_;
      dVar30 = dVar47 * dVar47;
      dVar41 = dVar29 * dVar29;
      dVar43 = dVar30 * dVar30;
      dVar44 = dVar41 * dVar41;
      dVar47 = dVar47 * (dVar43 * dVar43 * 39.65735524898863 +
                        dVar30 * -41.34167506665737 + 6.283185269630412 +
                        dVar43 * (dVar30 * -76.56887678023256 + 81.60201529595571));
      dVar29 = dVar29 * (dVar44 * dVar44 * 39.65735524898863 +
                        dVar41 * -41.34167506665737 + 6.283185269630412 +
                        dVar44 * (dVar41 * -76.56887678023256 + 81.60201529595571));
      dVar30 = dVar24 * dVar29;
      auVar4._8_8_ = dVar24;
      auVar4._0_8_ = dVar20;
      auVar5._8_8_ = dVar24;
      auVar5._0_8_ = dVar20;
      auVar22 = NEON_ext(auVar4,auVar5,8,1);
      dVar24 = auVar22._0_8_ * dVar47 + auVar22._8_8_ * dVar29;
      dVar20 = dVar20 * dVar47 - dVar30;
    }
    lVar15 = 0;
    uVar17 = 0;
    TVar2 = (TriggerContext)0x0;
    uVar14 = CONCAT44(iVar37 + (int)(dVar21 * dVar24 * 256.0),
                      iVar26 + (int)(dVar21 * dVar20 * 256.0));
    uVar13 = uVar14;
  }
  dVar47 = *(double *)(this + 0x58);
  dVar20 = *(double *)(param_1 + 0xa0);
  dVar24 = *(double *)(*plVar11 + (ulong)*(ushort *)(this + 0x38) * 8);
  local_110 = *(undefined8 *)(param_1 + 0x80);
  uStack_108 = *(undefined8 *)(param_1 + 0x88);
  uStack_100 = *(undefined8 *)(param_1 + 0x90);
  uStack_f8 = *(undefined8 *)(param_1 + 0x98);
  local_f0 = *(undefined8 *)(param_1 + 0xa0);
  local_150 = *(undefined8 *)(param_1 + 0x40);
  uStack_148 = *(undefined8 *)(param_1 + 0x48);
  uStack_140 = *(undefined8 *)(param_1 + 0x50);
  uStack_138 = *(undefined8 *)(param_1 + 0x58);
  local_130 = *(long *)(param_1 + 0x60);
  uStack_128 = *(ulong *)(param_1 + 0x68);
  local_120 = *(ulong *)(param_1 + 0x70);
  local_118 = *(undefined8 *)(param_1 + 0x78);
  local_190 = *(double *)param_1;
  dStack_188 = *(double *)(param_1 + 8);
  uStack_178 = *(undefined8 *)(param_1 + 0x18);
  local_180 = (undefined1)*(undefined8 *)(param_1 + 0x10);
  uStack_17f = (undefined7)((ulong)*(undefined8 *)(param_1 + 0x10) >> 8);
  uStack_160 = SUB168(*(undefined1 (*) [16])(param_1 + 0x30),0);
  uStack_168 = SUB168(*(undefined1 (*) [16])(param_1 + 0x20),8);
  local_170 = SUB168(*(undefined1 (*) [16])(param_1 + 0x20),0);
  uStack_158 = SUB168(*(undefined1 (*) [16])(param_1 + 0x30),8);
  plVar11 = local_e8;
  pTVar16 = *(TriggerContext **)(param_1 + 0xc0);
  if (pTVar16 == (TriggerContext *)0x0) {
    local_d0 = (long *)0x0;
  }
  else if (pTVar16 == param_1 + 0xa8) {
    local_d0 = plVar11;
    (**(code **)(*(long *)pTVar16 + 0x18))(pTVar16,plVar11);
  }
  else {
    local_d0 = (long *)(**(code **)(*(long *)pTVar16 + 0x10))();
  }
  uStack_c0 = *(undefined8 *)(param_1 + 0xd0);
  local_c8 = *(undefined8 *)(param_1 + 200);
  uStack_b0 = *(undefined8 *)(param_1 + 0xe0);
  local_b8 = *(undefined8 *)(param_1 + 0xd8);
  uVar46 = local_b8;
  local_a8 = *(undefined8 *)(param_1 + 0xe8);
  if (lVar15 == 0) {
    lVar15 = 0;
  }
  else if ((*(ushort *)(lVar15 + 0x58) & 0x10) != 0) {
    lVar15 = 0;
  }
  local_118._0_5_ = CONCAT14(TVar2,uVar17);
  dStack_238 = *(double *)((long)dStack_188 + 0xb8);
  local_b8._5_1_ = (undefined1)((ulong)*(undefined8 *)(param_1 + 0xd8) >> 0x28);
  uStack_208 = local_118;
  uStack_1f8 = uStack_148;
  local_200 = local_150;
  uStack_1e8 = uStack_138;
  uStack_1f0 = uStack_140;
  local_1e0 = CONCAT71(uStack_17f,local_180);
  local_1d0 = local_170;
  uStack_1d8 = uStack_178;
  local_228 = 0;
  local_227 = local_180;
  local_226 = local_b8._5_1_;
  uStack_1c4 = 0;
  uStack_1c8 = 0;
  local_1c1 = 0x14;
  local_1c0 = 0x10000ff00000000;
  local_1b8 = 0;
  local_1b0 = 0;
  uStack_1a8 = 0;
  local_240 = dVar24;
  local_230 = uVar10;
  local_220 = lVar15;
  uStack_218 = uVar13;
  uStack_210 = uVar14;
  local_130 = lVar15;
  uStack_128 = uVar13;
  local_120 = uVar14;
  local_b8 = uVar46;
  if (local_d0 == plVar11) {
    lVar15 = 4;
LAB_101a1aee4:
    (**(code **)(*plVar11 + lVar15 * 8))(plVar11);
  }
  else if (local_d0 != (long *)0x0) {
    lVar15 = 5;
    plVar11 = local_d0;
    goto LAB_101a1aee4;
  }
  this_00 = operator_new(0x218);
  if (*(long *)(param_1 + 0xe8) == 0) {
    puVar9 = (uint *)(*(long *)(*(long *)(param_1 + 8) + 0xb8) + 0x444);
    fVar18 = *(float *)(this + 0x48);
    fVar19 = *(float *)(this + 0x4c);
  }
  else {
    puVar9 = *(uint **)(_global + 0x250);
    fVar18 = *(float *)(this + 0x48);
    fVar19 = *(float *)(this + 0x4c);
  }
  if (fVar19 != 0.0) {
    uVar1 = *puVar9;
    uVar1 = (uVar1 & 0xffffe) << 0xc | (uVar1 ^ uVar1 << 0xd) >> 0x13;
    *puVar9 = uVar1;
    uVar10 = *(undefined8 *)(puVar9 + 1);
    uVar46 = NEON_ushl(uVar10,DAT_1029732c8,4);
    uVar46 = NEON_ushl(CONCAT17((byte)((ulong)uVar46 >> 0x38) ^ (byte)((ulong)uVar10 >> 0x38),
                                CONCAT16((byte)((ulong)uVar46 >> 0x30) ^
                                         (byte)((ulong)uVar10 >> 0x30),
                                         CONCAT15((byte)((ulong)uVar46 >> 0x28) ^
                                                  (byte)((ulong)uVar10 >> 0x28),
                                                  CONCAT14((byte)((ulong)uVar46 >> 0x20) ^
                                                           (byte)((ulong)uVar10 >> 0x20),
                                                           CONCAT13((byte)((ulong)uVar46 >> 0x18) ^
                                                                    (byte)((ulong)uVar10 >> 0x18),
                                                                    CONCAT12((byte)((ulong)uVar46 >>
                                                                                   0x10) ^
                                                                             (byte)((ulong)uVar10 >>
                                                                                   0x10),
                                                                             CONCAT11((byte)((ulong)
                                                  uVar46 >> 8) ^ (byte)((ulong)uVar10 >> 8),
                                                  (byte)uVar46 ^ (byte)uVar10))))))),DAT_1029732d0,4
                      );
    uVar13 = NEON_ushl(uVar10,DAT_1029732d8,4);
    uVar13 = uVar13 & DAT_1029732e0;
    uVar27 = CONCAT13((byte)((ulong)uVar46 >> 0x18) | (byte)(uVar13 >> 0x18),
                      CONCAT12((byte)((ulong)uVar46 >> 0x10) | (byte)(uVar13 >> 0x10),
                               CONCAT11((byte)((ulong)uVar46 >> 8) | (byte)(uVar13 >> 8),
                                        (byte)uVar46 | (byte)uVar13)));
    uVar10 = CONCAT17((byte)((ulong)uVar46 >> 0x38) | (byte)(uVar13 >> 0x38),
                      CONCAT16((byte)((ulong)uVar46 >> 0x30) | (byte)(uVar13 >> 0x30),
                               CONCAT15((byte)((ulong)uVar46 >> 0x28) | (byte)(uVar13 >> 0x28),
                                        CONCAT14((byte)((ulong)uVar46 >> 0x20) |
                                                 (byte)(uVar13 >> 0x20),uVar27))));
    *(undefined8 *)(puVar9 + 1) = uVar10;
    fVar18 = fVar18 + fVar19 * -0.5 +
             fVar19 * (float)((double)(uVar27 ^ uVar1 ^ (uint)((ulong)uVar10 >> 0x20)) *
                             2.3283064365386963e-10);
  }
  Projectile::Projectile
            (this_00,(EntityCreationParameters *)&local_240,(TriggerModifier *)(param_1 + 0x80),
             (double)fVar18,dVar21 * dVar47 * dVar20);
  TriggerContext::addEntity(param_1,(Entity *)this_00);
LAB_101a1afd4:
  if (*(long *)PTR____stack_chk_guard_102d481b8 != local_98) {
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail();
  }
  return;
}



// ===== StreamTriggerDelivery::apply  @ 0x101a2299c =====

/* StreamTriggerDelivery::apply(TriggerContext const&) const */

void __thiscall StreamTriggerDelivery::apply(StreamTriggerDelivery *this,TriggerContext *param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  Entity *pEVar4;
  int iVar5;
  TriggerContext *pTVar6;
  TriggerContext *pTVar7;
  TriggerContext *pTVar8;
  TriggerContext *pTVar9;
  TriggerContext *pTVar10;
  TriggerContext *pTVar11;
  undefined8 local_e0;
  undefined8 uStack_d8;
  undefined8 local_d0;
  undefined1 local_c8;
  TriggerContext local_c7;
  TriggerContext local_c6;
  undefined8 local_c0;
  undefined8 uStack_b8;
  undefined8 uStack_b0;
  undefined8 uStack_a8;
  undefined8 local_a0;
  undefined8 uStack_98;
  undefined8 uStack_90;
  undefined8 uStack_88;
  undefined8 local_80;
  undefined8 uStack_78;
  undefined8 local_70;
  undefined4 local_68;
  undefined3 uStack_64;
  undefined1 local_61;
  undefined8 local_60;
  undefined1 local_58;
  undefined8 local_50;
  undefined8 uStack_48;
  
  pTVar6 = param_1 + 0x48;
  pTVar8 = param_1 + 0x40;
  if ((*(int *)pTVar6 == 0x7fffffff) &&
     ((*(long *)pTVar8 == 0 || ((*(ushort *)(*(long *)pTVar8 + 0x58) >> 4 & 1) != 0)))) {
    return;
  }
  pTVar10 = param_1 + 0x68;
  pTVar9 = param_1 + 0x60;
  if (*(int *)pTVar10 == 0x7fffffff) {
    if (*(long *)pTVar9 == 0) {
      return;
    }
    if ((*(ushort *)(*(long *)pTVar9 + 0x58) >> 4 & 1) != 0) {
      return;
    }
  }
  TriggerDelivery::apply((TriggerDelivery *)this,param_1);
  if (*(int *)(param_1 + 0x48) == 0x7fffffff) {
    if (*(long *)pTVar8 == 0) {
      return;
    }
    if ((*(ushort *)(*(long *)pTVar8 + 0x58) >> 4 & 1) != 0) {
      return;
    }
  }
  iVar5 = *(int *)pTVar10;
  if (iVar5 == 0x7fffffff) {
    if (*(long *)pTVar9 == 0) {
      return;
    }
    if ((*(ushort *)(*(long *)pTVar9 + 0x58) >> 4 & 1) != 0) {
      return;
    }
  }
  pTVar7 = pTVar6;
  if (*(int *)(param_1 + 0x48) == 0x7fffffff) {
    if (*(long *)pTVar8 == 0) goto LAB_101a22b94;
    pTVar7 = (TriggerContext *)(*(long *)pTVar8 + 0x50);
  }
  pTVar11 = pTVar10;
  if (iVar5 == 0x7fffffff) {
    if (*(long *)pTVar9 == 0) {
LAB_101a22b94:
                    /* WARNING: Subroutine does not return */
      Logging::logAndAbortOrThrow
                ("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Trigger/ShootingTarget.cpp"
                 ,0xc,9,"Unset shooting target");
    }
    pTVar11 = (TriggerContext *)(*(long *)pTVar9 + 0x50);
    iVar5 = *(int *)pTVar11;
  }
  iVar1 = *(int *)pTVar7;
  iVar2 = *(int *)(pTVar7 + 4);
  iVar3 = *(int *)(pTVar11 + 4);
  pEVar4 = operator_new(0x210);
  local_e0 = *(undefined8 *)
              (*(long *)PTR_indexToPrototype_102d4c840 + (ulong)*(ushort *)(this + 0x38) * 8);
  uStack_d8 = *(undefined8 *)(*(long *)(param_1 + 8) + 0xb8);
  local_c7 = param_1[0x10];
  local_c6 = param_1[0xdd];
  uStack_b8 = *(undefined8 *)pTVar10;
  local_c0 = *(undefined8 *)pTVar9;
  uStack_a8 = *(undefined8 *)(param_1 + 0x78);
  uStack_b0 = *(undefined8 *)(param_1 + 0x70);
  uStack_98 = *(undefined8 *)pTVar6;
  local_a0 = *(undefined8 *)pTVar8;
  uStack_88 = *(undefined8 *)(param_1 + 0x58);
  uStack_90 = *(undefined8 *)(param_1 + 0x50);
  local_70 = *(undefined8 *)(param_1 + 0x20);
  uStack_78 = *(undefined8 *)(param_1 + 0x18);
  local_80 = *(undefined8 *)(param_1 + 0x10);
  local_c8 = 0;
  local_68 = 0;
  uStack_64 = 0;
  local_61 = 0x14;
  local_60 = 0x10000ff00000000;
  local_58 = 0;
  local_50 = 0;
  uStack_48 = 0;
  local_d0 = CONCAT44(iVar2 + (int)((double)(iVar3 - iVar2) * 0.00390625 * 0.5 * 256.0),
                      iVar1 + (int)((double)(iVar5 - iVar1) * 0.00390625 * 0.5 * 256.0));
  FluidStream::FluidStream((FluidStream *)pEVar4,&local_e0,param_1 + 0x80,1);
  TriggerContext::addEntity(param_1,pEVar4);
  return;
}



// ===== BuiltEntityUndoAction::apply  @ 0x101a34774 =====

/* BuiltEntityUndoAction::apply(UndoApplyContext const&, UndoItem&) */

void __thiscall
BuiltEntityUndoAction::apply
          (BuiltEntityUndoAction *this,UndoApplyContext *param_1,UndoItem *param_2)

{
  undefined8 *puVar1;
  undefined8 *puVar2;
  undefined1 uVar3;
  char cVar4;
  char cVar5;
  int iVar6;
  undefined8 uVar7;
  undefined8 uVar8;
  undefined1 *puVar9;
  long lVar10;
  long lVar11;
  long *plVar12;
  GameAction local_e8 [8];
  undefined8 local_e0;
  undefined8 uStack_d8;
  long local_58;
  
  local_58 = *(long *)PTR____stack_chk_guard_102d481b8;
  lVar11 = *(long *)(this + 0x18);
  if (((lVar11 == 0) || (*(long *)(lVar11 + 0x78) == 0)) ||
     ((*(ushort *)(lVar11 + 0x58) >> 9 & 1) != 0)) {
    uVar7 = 0;
    goto LAB_101a348d4;
  }
  plVar12 = *(long **)param_1;
  uVar3 = (**(code **)(*plVar12 + 0x68))(plVar12);
  uVar7 = (**(code **)(*plVar12 + 0x30))(plVar12);
  uVar8 = (**(code **)(*plVar12 + 0x48))(plVar12);
  UndoItem::entityRemoved(param_2,lVar11,uVar3,uVar7,uVar8);
  lVar11 = (**(code **)(**(long **)(this + 0x18) + 0xc48))();
  if (lVar11 == 0) {
    iVar6 = (**(code **)(**(long **)(this + 0x18) + 0x210))();
    if (iVar6 != 0) {
      cVar4 = (**(code **)(**(long **)(this + 0x18) + 0x220))();
      cVar5 = (**(code **)(**(long **)param_1 + 0x60))();
      if (cVar4 != cVar5) goto LAB_101a349c0;
    }
    cVar4 = (**(code **)(**(long **)param_1 + 0x68))();
    if (cVar4 != '\0') {
      uVar7 = *(undefined8 *)(this + 0x18);
      uVar3 = (**(code **)(**(long **)param_1 + 0x60))();
      uVar7 = DeconstructionData::acceptableForDeconstruction(uVar7,uVar3,1);
      if ((int)uVar7 == 0) goto LAB_101a348d4;
    }
    lVar11 = (**(code **)(**(long **)(this + 0x18) + 0xda8))();
    lVar10 = **(long **)param_1;
    if (lVar11 == 0) {
      (**(code **)(lVar10 + 0xf8))(*(long **)param_1,*(undefined8 *)(this + 0x18));
    }
    else {
      (**(code **)(lVar10 + 0xd0))();
    }
  }
  else {
    cVar4 = (**(code **)(**(long **)param_1 + 0x68))();
    if (cVar4 != '\0') {
      lVar11 = *(long *)(this + 0x18);
      local_e0 = (**(code **)(**(long **)param_1 + 0x48))();
      uStack_d8 = *(undefined8 *)(this + 0x18);
      local_e8[0] = (GameAction)0x5c;
      lVar11 = *(long *)(*(long *)(lVar11 + 0x80) + 0x480);
      if (lVar11 != 0) {
        puVar9 = *(undefined1 **)(lVar11 + 0x210);
        *puVar9 = 1;
        puVar2 = *(undefined8 **)(puVar9 + 0x10);
        for (puVar1 = *(undefined8 **)(puVar9 + 8); puVar1 != puVar2; puVar1 = puVar1 + 1) {
          (**(code **)(*(long *)*puVar1 + 0x10))((long *)*puVar1,local_e8);
        }
      }
      GameAction::destroyValue(local_e8);
    }
    if (*(long *)(this + 0x18) != 0) {
      (**(code **)(**(long **)param_1 + 0xd0))();
    }
  }
LAB_101a349c0:
  uVar7 = 1;
LAB_101a348d4:
  if (*(long *)PTR____stack_chk_guard_102d481b8 != local_58) {
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail(uVar7);
  }
  return;
}



// ===== BuiltTileUndoAction::apply  @ 0x101a35518 =====

/* BuiltTileUndoAction::apply(UndoApplyContext const&, UndoItem&) */

void __thiscall
BuiltTileUndoAction::apply(BuiltTileUndoAction *this,UndoApplyContext *param_1,UndoItem *param_2)

{
  undefined8 *puVar1;
  undefined8 *puVar2;
  TileGhost TVar3;
  undefined *puVar4;
  Surface *pSVar5;
  char cVar6;
  TileGhost TVar7;
  undefined1 uVar8;
  ushort uVar9;
  ushort uVar10;
  long lVar11;
  undefined8 uVar12;
  TileGhost *pTVar13;
  ulong uVar14;
  undefined8 uVar15;
  Surface *pSVar16;
  Player *pPVar17;
  undefined1 *puVar18;
  Surface *pSVar19;
  TileGhost *pTVar20;
  undefined8 uVar21;
  long *plVar22;
  long lVar23;
  Surface *pSVar24;
  TilePosition *pTVar25;
  int iVar26;
  uint uVar27;
  int iVar28;
  uint uVar29;
  ulong local_188;
  Surface *local_180;
  Surface *pSStack_178;
  Surface *local_170;
  Surface *pSStack_168;
  long lStack_160;
  long *local_158;
  undefined8 local_150;
  undefined8 local_140;
  undefined8 uStack_138;
  undefined8 uStack_130;
  undefined8 auStack_128 [2];
  Surface *local_118;
  Surface *pSStack_110;
  Surface *local_108;
  Surface *pSStack_100;
  long local_f8;
  long *plStack_f0;
  undefined8 local_e8;
  undefined8 local_e0;
  undefined8 uStack_d8;
  undefined8 local_d0;
  undefined8 uStack_c8;
  undefined8 local_c0;
  undefined8 uStack_b8;
  undefined8 local_b0;
  undefined8 uStack_a8;
  undefined1 local_a0;
  undefined2 uStack_9f;
  undefined4 uStack_9d;
  undefined1 local_99;
  undefined8 local_98;
  undefined1 local_90;
  undefined8 local_88;
  undefined8 uStack_80;
  long local_78;
  
  local_78 = *(long *)PTR____stack_chk_guard_102d481b8;
  lVar11 = (**(code **)(**(long **)param_1 + 0x40))();
  if (((ulong)(*(long *)(lVar11 + 0x2a8) - *(long *)(lVar11 + 0x2a0) >> 3) <=
       (ulong)*(uint *)(this + 0x30)) ||
     (pSVar19 = *(Surface **)(*(long *)(lVar11 + 0x2a0) + (ulong)*(uint *)(this + 0x30) * 8),
     pSVar19 == (Surface *)0x0)) {
    uVar12 = 0;
    goto LAB_101a35638;
  }
  pTVar20 = *(TileGhost **)(this + 0x18);
  if (pTVar20 != (TileGhost *)0x0) {
LAB_101a3558c:
    UndoItem::tileRemoved(param_2,pTVar20);
    cVar6 = (**(code **)(**(long **)param_1 + 0x68))();
    if (cVar6 != '\0') {
      pSStack_110 = (Surface *)(**(code **)(**(long **)param_1 + 0x48))();
      local_118 = (Surface *)CONCAT71(local_118._1_7_,0x5c);
      local_108 = (Surface *)pTVar20;
      if (*(long *)(*(long *)(pTVar20 + 0x80) + 0x480) != 0) {
        puVar18 = *(undefined1 **)(*(long *)(*(long *)(pTVar20 + 0x80) + 0x480) + 0x210);
        *puVar18 = 1;
        puVar2 = *(undefined8 **)(puVar18 + 0x10);
        for (puVar1 = *(undefined8 **)(puVar18 + 8); puVar1 != puVar2; puVar1 = puVar1 + 1) {
          (**(code **)(*(long *)*puVar1 + 0x10))((long *)*puVar1,&local_118);
        }
      }
      GameAction::destroyValue((GameAction *)&local_118);
    }
    (**(code **)(**(long **)param_1 + 0xd0))(*(long **)param_1,pTVar20);
    uVar12 = 1;
    goto LAB_101a35638;
  }
  pTVar25 = (TilePosition *)(this + 0x34);
  iVar26 = (int)*(undefined8 *)pTVar25 << 8;
  iVar28 = (int)((ulong)*(undefined8 *)pTVar25 >> 0x20) << 8;
  uVar27 = iVar26 >> 9;
  uVar29 = iVar28 >> 9;
  pSStack_110 = (Surface *)CONCAT44(uVar29,uVar27);
  iVar26 = iVar26 >> 0xd;
  plStack_f0 = (long *)0x0;
  local_e8 = 0;
  local_f8 = 0;
  if ((iVar26 < -*(int *)(pSVar19 + 0x24)) ||
     (iVar26 = *(int *)(pSVar19 + 0x24) + iVar26, *(int *)(pSVar19 + 0x20) <= iVar26)) {
LAB_101a35738:
    pSStack_100 = (Surface *)(CONCAT44(uVar29,uVar27) | 0xf);
  }
  else {
    plVar22 = (long *)(*(long *)(pSVar19 + 0x18) + (long)iVar26 * 0x10);
    if (plVar22 == (long *)0x0) goto LAB_101a35738;
    iVar28 = iVar28 >> 0xd;
    lVar11 = *(long *)(pSVar19 + 0x18) + (long)iVar26 * 0x10;
    iVar26 = *(int *)(lVar11 + 0xc);
    if ((((iVar28 < -iVar26) || (iVar26 = iVar26 + iVar28, *(int *)(lVar11 + 8) <= iVar26)) ||
        (plVar22 = (long *)(*plVar22 + (long)iVar26 * 8), plVar22 == (long *)0x0)) ||
       (local_f8 = *plVar22, local_f8 == 0)) goto LAB_101a35738;
    local_e8 = *(undefined8 *)
                (local_f8 + ((ulong)uVar27 & 0xf) * 0x80 + ((ulong)uVar29 & 0xf) * 8 + 0xc50);
    pSStack_100 = pSStack_110;
  }
  local_118 = pSVar19;
  local_108 = pSStack_110;
  HeuristicEntityIterator<Surface>::moveUntilEntityFound();
  pSStack_178 = pSStack_110;
  local_180 = local_118;
  pSStack_168 = pSStack_100;
  local_170 = local_108;
  local_158 = plStack_f0;
  lStack_160 = local_f8;
  local_150 = local_e8;
  if (plStack_f0 != (long *)0x0) {
    pTVar20 = (TileGhost *)0x0;
    do {
      pTVar13 = (TileGhost *)(**(code **)(*local_158 + 0x1108))();
      if (((pTVar13 != (TileGhost *)0x0) && (*(short *)(pTVar13 + 0xaa) == *(short *)(this + 0x3e)))
         && (TVar3 = pTVar13[0xac], TVar7 = (TileGhost)(**(code **)(**(long **)param_1 + 0x60))(),
            TVar3 == TVar7)) {
        uVar27 = *(int *)(this + 0x34) << 8 | 0x80;
        uVar29 = *(int *)(this + 0x38) << 8 | 0x80;
        local_188 = (ulong)uVar27 | (ulong)(uVar29 >> 7) << 0x27;
        iVar26 = *(int *)(pTVar13 + 0x5c);
        if (iVar26 != *(int *)(pTVar13 + 100) ||
            *(int *)(pTVar13 + 0x60) != *(int *)(pTVar13 + 0x68)) {
          if (*(short *)(pTVar13 + 0x6c) == 0) {
            if ((iVar26 <= (int)uVar27) &&
               (((int)uVar29 <= *(int *)(pTVar13 + 0x68) && (int)uVar27 <= *(int *)(pTVar13 + 100))
                && *(int *)(pTVar13 + 0x60) <= (int)uVar29)) goto LAB_101a3578c;
          }
          else {
            uStack_138 = 0;
            local_140 = 0;
            auStack_128[0] = 0;
            uStack_130 = 0;
            ::BoundingBox::getRotatedVertices
                      ((BoundingBox *)(pTVar13 + 0x5c),(MapPosition *)&local_140,
                       (MapPosition *)&uStack_138,(MapPosition *)&uStack_130,
                       (MapPosition *)auStack_128);
            uVar14 = RotatedBoundingBox::collide
                               ((RotatedBoundingBox *)&local_140,(MapPosition *)&local_188);
            if ((uVar14 & 1) != 0) {
LAB_101a3578c:
              pTVar20 = pTVar13;
            }
          }
        }
      }
      HeuristicEntityIterator<Surface>::moveUntilEntityFound();
    } while (local_158 != (long *)0x0);
    if (pTVar20 != (TileGhost *)0x0) goto LAB_101a3558c;
  }
  uVar21 = *(undefined8 *)(this + 0x34);
  plVar22 = *(long **)param_1;
  uVar8 = (**(code **)(*plVar22 + 0x60))(plVar22);
  uVar12 = (**(code **)(*plVar22 + 0x30))(plVar22);
  uVar15 = (**(code **)(*plVar22 + 0x38))(plVar22);
  uVar9 = Surface::getEffectiveTileID(pSVar19,uVar21,1,uVar8,uVar12,0,uVar15,0);
  puVar4 = PTR_indexToPrototype_102d4c598;
  uVar14 = (ulong)*(ushort *)(this + 0x3c);
  if (uVar14 == 0) {
LAB_101a35ab0:
    if (uVar9 != 0) {
      lVar23 = *(long *)PTR_indexToPrototype_102d4c598;
      goto LAB_101a35ac0;
    }
  }
  else {
    lVar23 = *(long *)PTR_indexToPrototype_102d4c598;
    lVar11 = *(long *)(lVar23 + uVar14 * 8);
    if (((*(long *)(lVar11 + 0x1b98) == *(long *)(lVar11 + 0x1ba0)) ||
        (*(char *)(lVar11 + 0x1bb0) == '\0')) || (*(char *)(lVar11 + 0x1b10) == '\0'))
    goto LAB_101a35ab0;
    if ((uVar9 == 0) ||
       (uVar14 = TerrainBuildingLogic::areTilesCompatibleForReplacement(uVar14,uVar9),
       (uVar14 & 1) != 0)) {
      pSVar24 = CorePrototypes::tileGhost;
      pSVar16 = (Surface *)(**(code **)(**(long **)param_1 + 0x40))();
      iVar26 = *(int *)(this + 0x34);
      iVar28 = *(int *)(this + 0x38);
      uVar8 = (**(code **)(**(long **)param_1 + 0x60))();
      local_118 = pSVar24;
      pSStack_100 = (Surface *)
                    ((ulong)CONCAT52((int5)((ulong)pSStack_100 >> 0x18),
                                     CONCAT11(CorePrototypes::normalQuality,uVar8)) << 8);
      local_e8 = 0x7fffffff7fffffff;
      plStack_f0 = (long *)0x7fffffff7fffffff;
      local_f8 = 0;
      local_e0 = 0;
      uStack_d8 = 0;
      uStack_c8 = 0x7fffffff7fffffff;
      local_d0 = 0x7fffffff7fffffff;
      local_c0 = 0;
      uStack_b8 = 0;
      local_b0 = 0;
      uStack_a8 = 0x7fffffff7fffffff;
      local_a0 = 0;
      uStack_9f = 0;
      uStack_9d = 0;
      local_99 = 0x14;
      local_98 = 0x10000ff00000000;
      local_90 = 0;
      local_88 = 0;
      uStack_80 = 0;
      pSStack_110 = pSVar16;
      local_108 = (Surface *)
                  ((ulong)(iVar26 << 8 | 0x80) | (ulong)((iVar28 << 8 | 0x80U) >> 7) << 0x27);
      cVar6 = (**(code **)(**(long **)param_1 + 0x68))();
      local_a0 = cVar6 == '\0';
      pTVar20 = operator_new(0xb0);
      TileGhost::TileGhost(pTVar20,&local_118,*(undefined2 *)(this + 0x3c));
      (**(code **)(**(long **)param_1 + 0x110))(*(long **)param_1,pSVar19,pTVar20,0,0);
      cVar6 = (**(code **)(**(long **)param_1 + 0x68))();
      if (cVar6 != '\0') {
        pPVar17 = (Player *)(**(code **)(**(long **)param_1 + 0x48))();
        local_180 = (Surface *)&PTR__InventoryBuffer_102f7b7a0;
        local_170 = (Surface *)0x0;
        pSStack_178 = (Surface *)0x0;
        lStack_160 = 0;
        pSStack_168 = (Surface *)0x0;
        local_140 = 0;
        Player::sendBuildEventForEntity(pPVar17,pTVar20,&local_180,&local_140,0);
        EntityTags::~EntityTags((EntityTags *)&local_140);
        InventoryBuffer::~InventoryBuffer((InventoryBuffer *)&local_180);
      }
      UndoItem::tileBuilt(param_2,pTVar20,pSVar19);
      uVar12 = 1;
      goto LAB_101a35638;
    }
LAB_101a35ac0:
    if (*(char *)(*(long *)(lVar23 + (ulong)uVar9 * 8) + 0x1b10) != '\0') {
      uVar21 = *(undefined8 *)pTVar25;
      plVar22 = *(long **)param_1;
      uVar8 = (**(code **)(*plVar22 + 0x60))(plVar22);
      uVar12 = (**(code **)(*plVar22 + 0x30))(plVar22);
      uVar15 = (**(code **)(*plVar22 + 0x38))(plVar22);
      uVar10 = Surface::getEffectiveTileID(pSVar19,uVar21,1,uVar8,uVar12,0,uVar15,1);
      if ((uVar10 == 0) ||
         (*(char *)(*(long *)(*(long *)puVar4 + (ulong)uVar10 * 8) + 0x1c80) != '\0')) {
        uVar8 = (**(code **)(**(long **)param_1 + 0x60))();
        uVar12 = (**(code **)(**(long **)param_1 + 0x30))();
        Surface::getEntitiesPreventingTileOrTileGhostDeconstruction
                  (&local_118,pSVar19,pTVar25,uVar8,uVar12,0);
        pSVar5 = pSStack_110;
        pSVar16 = local_118;
        for (pSVar24 = local_118; pSVar24 != pSVar5; pSVar24 = pSVar24 + 8) {
          plVar22 = *(long **)pSVar24;
          lVar11 = (**(code **)(*plVar22 + 0xae0))(plVar22);
          if ((lVar11 != 0) || (lVar11 = (**(code **)(*plVar22 + 0x10b0))(plVar22), lVar11 != 0)) {
            pSVar16 = pSVar24;
            if (pSVar24 != pSVar5) {
              while (pSVar24 = pSVar24 + 8, pSVar24 != pSVar5) {
                plVar22 = *(long **)pSVar24;
                lVar11 = (**(code **)(*plVar22 + 0xae0))(plVar22);
                if ((lVar11 == 0) &&
                   (lVar11 = (**(code **)(*plVar22 + 0x10b0))(plVar22), lVar11 == 0)) {
                  *(undefined8 *)pSVar16 = *(undefined8 *)pSVar24;
                  pSVar16 = pSVar16 + 8;
                }
              }
            }
            break;
          }
          pSVar16 = pSVar5;
        }
        if (pSVar16 != pSStack_110) {
          _memmove(pSVar16,pSStack_110,0);
        }
        pSVar24 = local_118;
        if (local_118 != (Surface *)0x0) {
          pSStack_110 = local_118;
          operator_delete(local_118);
        }
        if (pSVar24 != pSVar16) goto LAB_101a35c8c;
      }
      uVar12 = DeconstructibleTileProxy::createProxy(pTVar25,pSVar19,*(GameAdapter **)param_1);
      UndoItem::tileRemoved(param_2,uVar12,(ulong)uVar9,pSVar19);
    }
  }
LAB_101a35c8c:
  uVar12 = 1;
LAB_101a35638:
  if (*(long *)PTR____stack_chk_guard_102d481b8 != local_78) {
                    /* WARNING: Subroutine does not return */
    ___stack_chk_fail(uVar12);
  }
  return;
}



// ===== CopyEntitySettingsUndoAction::apply  @ 0x101a3721c =====

/* CopyEntitySettingsUndoAction::apply(UndoApplyContext const&, UndoItem&) */

bool __thiscall
CopyEntitySettingsUndoAction::apply
          (CopyEntitySettingsUndoAction *this,UndoApplyContext *param_1,UndoItem *param_2)

{
  long *plVar1;
  undefined ***pppuVar2;
  bool bVar3;
  char cVar4;
  int iVar5;
  long *plVar6;
  undefined8 uVar7;
  undefined8 uVar8;
  long lVar9;
  undefined8 *puVar10;
  Surface *pSVar11;
  undefined8 local_b0;
  undefined8 local_a8;
  undefined8 uStack_a0;
  undefined4 local_98;
  undefined1 local_94;
  undefined8 local_90;
  undefined8 uStack_88;
  undefined1 local_80;
  undefined8 local_78;
  undefined **local_70;
  undefined8 local_68;
  long *plStack_60;
  long *local_58;
  undefined8 uStack_50;
  undefined ***local_48;
  
  plVar6 = *(long **)(this + 0x20);
  if (plVar6 != (long *)0x0) {
    plVar6 = (long *)(**(code **)(*plVar6 + 0x108))(plVar6,0);
    uVar7 = (**(code **)(**(long **)(this + 0x10) + 0x108))(*(long **)(this + 0x10),0);
    cVar4 = (**(code **)(*plVar6 + 0x588))(plVar6,uVar7);
    if (cVar4 == '\0') {
      cVar4 = (**(code **)(**(long **)param_1 + 0x68))();
      if (cVar4 != '\0') {
        uVar7 = (**(code **)(**(long **)(this + 0x10) + 0x108))(*(long **)(this + 0x10),0);
        uStack_a0 = (**(code **)(**(long **)param_1 + 0x48))();
        local_48 = &local_70;
        local_94 = 0;
        local_90 = 0;
        uStack_88 = 0;
        local_80 = 0;
        local_78 = 0;
        local_70 = &PTR__InventoryBuffer_102f7b7a0;
        plStack_60 = (long *)0x0;
        local_68 = 0;
        uStack_50 = 0;
        local_58 = (long *)0x0;
        local_98 = 1;
        local_a8 = uVar7;
        uVar7 = (**(code **)(**(long **)(this + 0x20) + 0x108))(*(long **)(this + 0x20),0);
        uVar8 = (**(code **)(**(long **)param_1 + 0x48))();
        UndoItem::entitySettingsCopied(param_2,uVar7,0,uVar8);
        plVar6 = (long *)(**(code **)(**(long **)(this + 0x20) + 0x108))(*(long **)(this + 0x20),0);
        iVar5 = (**(code **)(*plVar6 + 0x5c0))(plVar6,&local_a8);
        bVar3 = iVar5 == 0 || iVar5 == 0x11;
        lVar9 = (**(code **)(**(long **)param_1 + 0x48))();
        if (((lVar9 != 0) &&
            (iVar5 = (**(code **)(**(long **)(lVar9 + 0x600) + 0x140))
                               (*(long **)(lVar9 + 0x600),*(undefined8 *)(this + 0x20),0),
            iVar5 != 0)) &&
           (iVar5 = (**(code **)(**(long **)(lVar9 + 0x600) + 0x3a8))(), pppuVar2 = local_48,
           iVar5 != 0)) {
          plVar6 = *(long **)(lVar9 + 0x600);
          puVar10 = (undefined8 *)(**(code **)(*plVar6 + 0xd8))(plVar6);
          local_b0 = (**(code **)*puVar10)();
          (**(code **)(*plVar6 + 0x788))(plVar6,pppuVar2,&local_b0,0);
        }
        pSVar11 = *(Surface **)(*(long *)(this + 0x20) + 0x78);
        if (pSVar11 != (Surface *)0x0) {
          Surface::dropItemStacksAround(pSVar11,local_48,*(long *)(this + 0x20) + 0x50,0,0,0,0);
        }
        plVar1 = local_58;
        local_70 = &PTR__InventoryBuffer_102f7b7a0;
        for (plVar6 = plStack_60; plVar6 != plVar1; plVar6 = plVar6 + 1) {
          if ((long *)*plVar6 != (long *)0x0) {
            (**(code **)(*(long *)*plVar6 + 200))();
          }
        }
        if (plStack_60 == (long *)0x0) {
          return bVar3;
        }
        local_58 = plStack_60;
        operator_delete(plStack_60);
        return bVar3;
      }
      (**(code **)(**(long **)param_1 + 0x40))();
      (**(code **)(**(long **)param_1 + 0x30))();
      plVar6 = *(long **)(this + 0x20);
      if (plVar6 == (long *)0x0) {
        return false;
      }
      if (*(long *)(this + 0x10) == 0) {
        return false;
      }
      plVar6 = (long *)(**(code **)(*plVar6 + 0x108))(plVar6,0);
      uVar7 = (**(code **)(**(long **)(this + 0x10) + 0x108))(*(long **)(this + 0x10),0);
      cVar4 = (**(code **)(*plVar6 + 0x588))(plVar6,uVar7);
      return cVar4 == '\0';
    }
  }
  return false;
}



// ===== LatencyMergedUndoItem::apply  @ 0x101a37904 =====

/* LatencyMergedUndoItem::apply(GameAdapter const&, UndoItem&, UndoMode) const */

void __thiscall
LatencyMergedUndoItem::apply
          (LatencyMergedUndoItem *this,undefined8 param_1,undefined8 param_2,undefined4 param_4)

{
  bool bVar1;
  ulong uVar2;
  LatencyMergedUndoItem *pLVar3;
  long lVar4;
  LatencyMergedUndoItem *pLVar5;
  long lVar6;
  LatencyMergedUndoItem *pLVar7;
  long lVar8;
  ulong uVar9;
  long *plVar10;
  long lVar11;
  ulong local_a0;
  undefined4 uStack_98;
  undefined4 uStack_94;
  undefined1 uStack_90;
  undefined8 uStack_8f;
  ulong local_80;
  undefined4 uStack_78;
  undefined4 uStack_74;
  undefined4 uStack_70;
  undefined8 uStack_6c;
  
  lVar8 = *(long *)(*(long *)(this + 0x48) + 8);
  uVar9 = (ulong)*(uint *)(*(long *)(this + 0x48) + 0x560);
  if (uVar9 < *(ulong *)(lVar8 + 0x368)) {
    uVar2 = *(long *)(lVar8 + 0x360) + *(ulong *)(lVar8 + 0x368);
    lVar4 = *(long *)(lVar8 + 0x348);
    plVar10 = (long *)(lVar4 + (uVar2 / 0x38) * 8);
    lVar6 = *(long *)(lVar8 + 0x350);
    if (lVar6 == lVar4) {
      lVar11 = 0;
    }
    else {
      lVar11 = *plVar10 + (uVar2 % 0x38) * 0x48;
    }
    while( true ) {
      if (lVar6 == lVar4) {
        if (lVar11 == 0) goto LAB_101a37ab0;
      }
      else if (lVar11 == *(long *)(lVar4 + (*(ulong *)(lVar8 + 0x360) / 0x38) * 8) +
                         (*(ulong *)(lVar8 + 0x360) % 0x38) * 0x48) goto LAB_101a37ab0;
      if (uVar9 == 0) break;
      lVar4 = lVar11;
      if (lVar11 == *plVar10) {
        lVar4 = plVar10[-1] + 0xfc0;
      }
      uVar2 = (**(code **)(*(long *)(lVar4 + -0x48) + 0x18))
                        ((long *)(lVar4 + -0x48),*(undefined8 *)(*(long *)(lVar8 + 0x370) + 0x20),
                         *(undefined8 *)(lVar8 + 0x378));
      uVar9 = uVar9 - (uVar2 & 0xffffffff);
      if (lVar11 == *plVar10) {
        plVar10 = plVar10 + -1;
        lVar11 = *plVar10 + 0xfc0;
      }
      lVar11 = lVar11 + -0x48;
      lVar4 = *(long *)(lVar8 + 0x348);
      lVar6 = *(long *)(lVar8 + 0x350);
    }
    if (lVar11 == *plVar10) {
      lVar11 = plVar10[-1] + 0xfc0;
      pLVar5 = (LatencyMergedUndoItem *)(plVar10[-1] + 0xf78);
    }
    else {
      pLVar5 = (LatencyMergedUndoItem *)(lVar11 + -0x48);
    }
    if (pLVar5 == (LatencyMergedUndoItem *)0x0) goto LAB_101a37ab0;
    pLVar3 = this + 8;
    local_80 = *(ulong *)(lVar11 + -0x20);
    uStack_8f = *(ulong *)(lVar11 + -0xf);
    uVar9 = uStack_8f;
    uStack_90 = (undefined1)((ulong)*(undefined8 *)(lVar11 + -0x17) >> 0x38);
    uStack_98 = (undefined4)*(undefined8 *)(lVar11 + -0x18);
    uStack_94 = (undefined4)((ulong)*(undefined8 *)(lVar11 + -0x18) >> 0x20);
    local_a0 = local_80;
    uStack_8f._7_1_ = (char)(*(ulong *)(lVar11 + -0xf) >> 0x38);
    uStack_8f = uVar9;
    if ((uStack_8f._7_1_ != '\0') && (this[0x40] != (LatencyMergedUndoItem)0x0)) {
      uStack_78 = uStack_98;
      uStack_74 = (undefined4)*(undefined8 *)(this + 0x34);
      uStack_70 = (undefined4)((ulong)*(undefined8 *)(this + 0x34) >> 0x20);
      uStack_6c._0_5_ = CONCAT14(1,*(undefined4 *)(this + 0x3c));
      goto LAB_101a37ad4;
    }
    bVar1 = uStack_8f._7_1_ == '\0';
    pLVar7 = (LatencyMergedUndoItem *)&local_a0;
    if (bVar1) {
      pLVar7 = this + 0x28;
    }
  }
  else {
LAB_101a37ab0:
    pLVar3 = (LatencyMergedUndoItem *)0x0;
    local_a0 = local_a0 & 0xffffffffffffff00;
    uStack_8f = uStack_8f & 0xffffffffffffff;
    pLVar5 = this;
    pLVar7 = this + 0x28;
  }
  uStack_78 = (undefined4)*(ulong *)(pLVar7 + 8);
  uStack_74 = (undefined4)(*(ulong *)(pLVar7 + 8) >> 0x20);
  local_80 = *(ulong *)pLVar7;
  uStack_6c = *(undefined8 *)(pLVar7 + 0x14);
  uStack_74 = (undefined4)*(undefined8 *)(pLVar7 + 0xc);
  uStack_70 = (undefined4)((ulong)*(undefined8 *)(pLVar7 + 0xc) >> 0x20);
LAB_101a37ad4:
  UndoItem::apply(pLVar5 + 8,pLVar3,&local_80,param_1,param_2,param_4);
  return;
}



// ===== UndoItem::apply  @ 0x101a37c88 =====

/* UndoItem::apply(std::vector<std::unique_ptr<UndoAction, std::default_delete<UndoAction> >,
   std::allocator<std::unique_ptr<UndoAction, std::default_delete<UndoAction> > > > const&,
   std::vector<std::unique_ptr<UndoAction, std::default_delete<UndoAction> >,
   std::allocator<std::unique_ptr<UndoAction, std::default_delete<UndoAction> > > > const*,
   std::optional<UndoItem::NonGameStateRailPlannerUndo>, GameAdapter const&, UndoItem&, UndoMode) */

uint UndoItem::apply(long *param_1,long *param_2,undefined8 *param_3,GameAdapter *param_4,
                    long param_5,undefined8 param_6)

{
  undefined8 *puVar1;
  undefined4 uVar2;
  char cVar3;
  int iVar4;
  uint uVar5;
  undefined8 uVar6;
  undefined8 uVar7;
  long lVar8;
  undefined4 uVar9;
  long lVar10;
  undefined8 *puVar11;
  uint uVar12;
  undefined4 local_c0;
  undefined4 uStack_bc;
  char local_a9;
  __tree_node **local_a8;
  __tree_node *local_a0;
  undefined8 local_98;
  GameAdapter *pGStack_90;
  undefined4 local_88;
  void **local_80;
  void *local_78;
  void *local_70;
  undefined8 local_68;
  
  uVar9 = (undefined4)param_6;
  local_78 = (void *)0x0;
  local_70 = (void *)0x0;
  local_68 = 0;
  local_98 = 0;
  local_80 = &local_78;
  local_a8 = &local_a0;
  local_a0 = (__tree_node *)0x0;
  pGStack_90 = param_4;
  local_88 = uVar9;
  uVar6 = (**(code **)(*(long *)param_4 + 0x40))(param_4);
  uVar7 = (**(code **)(*(long *)param_4 + 0x30))(param_4);
  puVar1 = (undefined8 *)param_1[1];
  local_c0 = uVar9;
  for (puVar11 = (undefined8 *)*param_1; puVar11 != puVar1; puVar11 = puVar11 + 1) {
    iVar4 = (**(code **)(*(long *)*puVar11 + 0x30))((long *)*puVar11,uVar6,uVar7);
    if (iVar4 != 0) {
      (**(code **)(*(long *)*puVar11 + 0x38))((long *)*puVar11,&local_a8,&local_c0,uVar7);
    }
  }
  if (param_2 != (long *)0x0) {
    uVar6 = (**(code **)(*(long *)param_4 + 0x40))(param_4);
    uVar7 = (**(code **)(*(long *)param_4 + 0x30))(param_4);
    puVar1 = (undefined8 *)param_2[1];
    local_c0 = uVar9;
    for (puVar11 = (undefined8 *)*param_2; puVar11 != puVar1; puVar11 = puVar11 + 1) {
      iVar4 = (**(code **)(*(long *)*puVar11 + 0x30))((long *)*puVar11,uVar6,uVar7);
      if (iVar4 != 0) {
        (**(code **)(*(long *)*puVar11 + 0x38))((long *)*puVar11,&local_a8,&local_c0,uVar7);
      }
    }
  }
  getFlyingTextDescription((UndoItem *)&local_c0,&local_a8,param_4,param_6);
  (**(code **)(*(long *)param_4 + 0x518))(param_4,&local_c0);
  if (local_a9 < '\0') {
    operator_delete((void *)CONCAT44(uStack_bc,local_c0));
    std::
    __tree<std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>,std::__map_value_compare<UndoActionDescription::Type,std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>,std::less<UndoActionDescription::Type>,true>,std::allocator<std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>>>
    ::destroy((__tree<std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>,std::__map_value_compare<UndoActionDescription::Type,std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>,std::less<UndoActionDescription::Type>,true>,std::allocator<std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>>>
               *)&local_a8,local_a0);
    if (param_2 == (long *)0x0) goto LAB_101a37fc4;
LAB_101a37e30:
    puVar11 = (undefined8 *)param_2[1];
    if (puVar11 == (undefined8 *)*param_2) {
      uVar12 = 0;
      puVar11 = (undefined8 *)param_1[1];
      if (puVar11 == (undefined8 *)*param_1) goto LAB_101a37e9c;
    }
    else {
      uVar12 = 0;
      do {
        puVar11 = puVar11 + -1;
        uVar5 = (**(code **)(*(long *)*puVar11 + 0x18))((long *)*puVar11,&pGStack_90,param_5);
        uVar12 = uVar12 | uVar5;
      } while (puVar11 != (undefined8 *)*param_2);
      puVar11 = (undefined8 *)param_1[1];
      if (puVar11 == (undefined8 *)*param_1) goto LAB_101a37e9c;
    }
  }
  else {
    std::
    __tree<std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>,std::__map_value_compare<UndoActionDescription::Type,std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>,std::less<UndoActionDescription::Type>,true>,std::allocator<std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>>>
    ::destroy((__tree<std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>,std::__map_value_compare<UndoActionDescription::Type,std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>,std::less<UndoActionDescription::Type>,true>,std::allocator<std::__value_type<UndoActionDescription::Type,std::map<UndoActionDescription,unsigned_int,std::less<UndoActionDescription>,std::allocator<std::pair<UndoActionDescription_const,unsigned_int>>>>>>
               *)&local_a8,local_a0);
    if (param_2 != (long *)0x0) goto LAB_101a37e30;
LAB_101a37fc4:
    uVar12 = 0;
    puVar11 = (undefined8 *)param_1[1];
    if (puVar11 == (undefined8 *)*param_1) goto LAB_101a37e9c;
  }
  do {
    puVar11 = puVar11 + -1;
    uVar5 = (**(code **)(*(long *)*puVar11 + 0x18))((long *)*puVar11,&pGStack_90,param_5);
    uVar12 = uVar12 | uVar5;
  } while (puVar11 != (undefined8 *)*param_1);
LAB_101a37e9c:
  tryReviveGhosts(param_4,(vector *)&local_78);
  if (*(char *)(param_3 + 3) != '\0') {
    cVar3 = (**(code **)(*(long *)param_4 + 0x68))(param_4);
    if (((((cVar3 != '\0') && (lVar8 = (**(code **)(*(long *)param_4 + 0x48))(param_4), lVar8 != 0))
         && (lVar10 = *(long *)(*(long *)(lVar8 + 0x20) + 0x480), lVar10 != 0)) &&
        ((lVar10 = *(long *)(lVar10 + 0x230), lVar10 != 0 && (*(long *)(lVar10 + 0x38) == lVar8))))
       && ((*(int *)(lVar10 + 0x70) == *(int *)((long)param_3 + 0xc) &&
            *(int *)(lVar10 + 0x74) == *(int *)(param_3 + 2) &&
           ((*(char *)(lVar10 + 0x78) == *(char *)((long)param_3 + 0x14) &&
            (*(char *)(lVar10 + 0x79) == *(char *)((long)param_3 + 0x15))))))) {
      uVar6 = *param_3;
      *(undefined2 *)(lVar10 + 0x78) = *(undefined2 *)(param_3 + 1);
      *(undefined8 *)(lVar10 + 0x70) = uVar6;
    }
    if (*(char *)(param_5 + 0x40) != '\0') {
      *(undefined1 *)(param_5 + 0x40) = 0;
    }
    uVar9 = *(undefined4 *)((long)param_3 + 0x14);
    uVar6 = *param_3;
    uVar2 = *(undefined4 *)(param_3 + 1);
    *(undefined8 *)(param_5 + 0x28) = *(undefined8 *)((long)param_3 + 0xc);
    *(undefined4 *)(param_5 + 0x30) = uVar9;
    *(undefined8 *)(param_5 + 0x34) = uVar6;
    *(undefined4 *)(param_5 + 0x3c) = uVar2;
    *(undefined1 *)(param_5 + 0x40) = 1;
  }
  if (local_78 != (void *)0x0) {
    local_70 = local_78;
    operator_delete(local_78);
  }
  return uVar12 & 1;
}



// ===== RemovedEntityUndoAction::apply  @ 0x101a3afe0 =====

/* WARNING: Type propagation algorithm not settling */
/* RemovedEntityUndoAction::apply(UndoApplyContext const&, UndoItem&) */

bool __thiscall
RemovedEntityUndoAction::apply
          (RemovedEntityUndoAction *this,UndoApplyContext *param_1,UndoItem *param_2)

{
  undefined1 uVar1;
  undefined1 uVar2;
  ushort uVar3;
  ulong uVar4;
  Ghost *pGVar5;
  char cVar6;
  char cVar7;
  bool bVar8;
  int iVar9;
  uint uVar10;
  long *plVar11;
  long lVar12;
  undefined8 uVar13;
  EntityGhost *this_00;
  undefined8 uVar14;
  LatencyState *this_01;
  Player *pPVar15;
  undefined2 uVar16;
  Entity *pEVar17;
  long lVar18;
  Surface *pSVar19;
  long *plVar20;
  __tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
  *p_Var21;
  EntityGhost *pEVar22;
  Ghost *local_1f8;
  undefined8 local_1f0;
  long *plStack_1e8;
  long *local_1e0;
  undefined8 uStack_1d8;
  __tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
  *local_1d0;
  Entity *local_1c8;
  undefined1 auStack_1b8 [8];
  ulong local_1b0;
  long lStack_1a8;
  long local_1a0;
  undefined1 local_198;
  undefined1 local_197;
  undefined1 local_196;
  undefined8 local_190;
  undefined8 local_188;
  undefined8 uStack_180;
  undefined8 local_178;
  undefined8 uStack_170;
  undefined8 local_168;
  undefined8 uStack_160;
  undefined8 local_158;
  undefined8 uStack_150;
  undefined8 local_148;
  undefined8 uStack_140;
  undefined1 local_138;
  undefined2 uStack_137;
  undefined4 uStack_135;
  undefined1 local_131;
  undefined8 local_130;
  undefined1 local_128;
  undefined8 local_120;
  undefined8 uStack_118;
  undefined2 local_110;
  undefined1 local_10e;
  undefined8 local_10c;
  undefined4 local_104;
  undefined8 local_100;
  undefined4 local_f8;
  undefined2 local_f4;
  undefined8 local_f0;
  undefined1 local_e8;
  undefined8 local_e0;
  undefined8 uStack_d8;
  undefined8 local_d0;
  undefined8 uStack_c8;
  undefined8 local_c0;
  undefined4 local_b8;
  undefined8 local_b0;
  int local_a8 [12];
  uint local_78;
  undefined4 uStack_74;
  undefined4 uStack_70;
  
  plVar11 = *(long **)(this + 0x40);
  if (plVar11 != (long *)0x0) {
    uVar10 = (uint)*(ushort *)(plVar11 + 0xb);
    if (((*(ushort *)(plVar11 + 0xb) >> 0xd & 1) != 0) && (plVar11[0xf] != 0)) {
      lVar12 = (**(code **)(**(long **)param_1 + 0x30))();
      plVar11 = *(long **)(this + 0x40);
      if ((lVar12 == 0) || ((*(byte *)((long)plVar11 + 0x14) & 1) == 0)) {
        iVar9 = (**(code **)(*plVar11 + 0x210))();
        if (iVar9 != 0) {
          cVar6 = (**(code **)(**(long **)param_1 + 0x60))();
          cVar7 = (**(code **)(**(long **)(this + 0x40) + 0x220))();
          if (cVar6 != cVar7) {
            return false;
          }
        }
        cVar6 = (**(code **)(**(long **)param_1 + 0x68))();
        if ((cVar6 != '\0') && (*(long *)(this + 0x18) != *(long *)(this + 0x20))) {
          if (*(long *)(this + 0x10) == 0) {
                    /* WARNING: Subroutine does not return */
            ReleaseAssertFailed("/var/folders/j9/cc3g_4dn313285y_n7wm5jhm0000gn/T/factorio-build-XXXXXX.TTVcnf4dcW/src/Undo/RemovedEntityUndoAction.cpp"
                                ,0x6e,"this->entityCopy.get()");
          }
          pEVar17 = *(Entity **)(this + 0x40);
          std::
          vector<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>,std::allocator<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>>>
          ::vector((vector<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>,std::allocator<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>>>
                    *)&local_1b0,(vector *)(this + 0x18));
          ItemRequestProxy::checkCreateProxyForEntity
                    (pEVar17,(InsertPlan *)&local_1b0,(ItemRequestProxy *)0x0);
          InsertPlan::~InsertPlan((InsertPlan *)&local_1b0);
        }
        lVar18 = *(long *)(this + 0x40);
        lVar12 = (**(code **)(**(long **)param_1 + 0x30))();
        uVar3 = *(ushort *)(lVar18 + 0x58);
        if (lVar12 == 0) {
          if ((uVar3 >> 0xe & 1) == 0) goto LAB_101a3b238;
        }
        else {
          uVar10 = *(uint *)(lVar18 + 0x14);
          if (((ushort)((ushort)((uVar10 & 0x20) == 0) & uVar3 >> 0xe) == 0) &&
             ((uVar10 >> 4 & 1) == 0)) goto LAB_101a3b238;
        }
        (**(code **)(**(long **)param_1 + 0x100))
                  (*(long **)param_1,*(undefined8 *)(this + 0x40),param_2);
LAB_101a3b238:
        UndoItem::entityBuilt
                  (param_2,*(Entity **)(this + 0x40),*(Surface **)(*(Entity **)(this + 0x40) + 0x78)
                  );
        return true;
      }
      uVar10 = (uint)*(ushort *)(plVar11 + 0xb);
    }
    if ((uVar10 >> 0xd & 1) == 0) {
      if (plVar11 == *(long **)(this + 0x10)) goto LAB_101a3b17c;
    }
    else if (plVar11[0xf] != 0 || plVar11 == *(long **)(this + 0x10)) goto LAB_101a3b17c;
    lVar12 = (**(code **)(**(long **)param_1 + 0x30))();
    if (lVar12 == 0) {
      takeOverAsPrimaryEntityCopyOwner(this);
      if (*(long *)(this + 0x40) != 0) {
        lVar12 = *(long *)(this + 0x48);
        lVar18 = *(long *)(this + 0x50);
        if (lVar18 == 0) {
          *(long *)(*(long *)(this + 0x40) + 8) = lVar12;
        }
        else {
          *(long *)(lVar18 + 0x10) = lVar12;
          lVar12 = *(long *)(this + 0x48);
        }
        if (lVar12 != 0) {
          *(long *)(lVar12 + 0x18) = lVar18;
        }
        *(undefined8 *)(this + 0x40) = 0;
      }
    }
  }
LAB_101a3b17c:
  if (*(long *)(this + 0x10) != 0) {
    lVar12 = (**(code **)(**(long **)param_1 + 0x40))();
    if (((ulong)*(uint *)(this + 0x30) <
         (ulong)(*(long *)(lVar12 + 0x2a8) - *(long *)(lVar12 + 0x2a0) >> 3)) &&
       (pSVar19 = *(Surface **)(*(long *)(lVar12 + 0x2a0) + (ulong)*(uint *)(this + 0x30) * 8),
       pSVar19 != (Surface *)0x0)) {
      plVar11 = *(long **)(this + 0x10);
      plVar11[0xf] = (long)pSVar19;
      plVar11 = (long *)(**(code **)(*plVar11 + 0x3f0))();
      if (plVar11 != (long *)0x0) {
        if (*(long *)(pSVar19 + 0x38) == 0) {
          if (*(long *)(pSVar19 + 0x30) == 0) {
            uVar16 = *(undefined2 *)(CorePrototypes::pollutionPrototype + 0x188);
          }
          else {
            uVar16 = *(undefined2 *)(*(long *)(*(long *)(pSVar19 + 0x30) + 0x20) + 0x568);
          }
        }
        else {
          uVar16 = 0;
        }
        local_1b0 = CONCAT62(local_1b0._2_6_,uVar16);
        (**(code **)(*plVar11 + 0x160))(plVar11,&local_1b0);
      }
      (**(code **)(**(long **)(this + 0x10) + 0x6c8))();
      local_78 = local_78 & 0xffffff00;
      uStack_74 = 0x7fffffff;
      uStack_70 = 0x7fffffff;
      uVar14 = CONCAT44(0x7fffffff,local_78);
      uVar13 = (**(code **)(**(long **)param_1 + 0x30))();
      local_e0 = (**(code **)(**(long **)param_1 + 0x48))();
      local_110 = 4;
      local_10e = 0;
      local_104 = 0x7fffffff;
      local_100 = 0x7fffffff7fffffff;
      local_f8 = 0x1000000;
      local_f4 = 0x100;
      local_f0 = 0;
      local_e8 = 0;
      local_d0 = 0;
      uStack_c8 = 0;
      local_b8 = 0x80010000;
      local_c0 = 0;
      local_b0 = 0;
      local_10c = uVar14;
      uStack_d8 = uVar13;
      (**(code **)(**(long **)(this + 0x10) + 0x270))(local_a8,*(long **)(this + 0x10),&local_110);
      (**(code **)(**(long **)(this + 0x10) + 0x6d0))();
      plVar11 = *(long **)(this + 0x10);
      plVar11[0xf] = 0;
      plVar11 = (long *)(**(code **)(*plVar11 + 0x3f0))();
      if (plVar11 != (long *)0x0) {
        local_1b0 = local_1b0 & 0xffffffffffff0000;
        (**(code **)(*plVar11 + 0x160))(plVar11,&local_1b0);
      }
      uVar4 = CorePrototypes::entityGhost;
      if (local_a8[0] != 0) {
        return local_a8[0] == 0;
      }
      plVar11 = *(long **)(this + 0x10);
      lVar12 = plVar11[0x10];
      local_198 = (**(code **)(*plVar11 + 0x4d8))(plVar11);
      local_1b0 = uVar4;
      local_1a0 = plVar11[10];
      local_197 = 2;
      local_196 = CorePrototypes::normalQuality;
      local_190 = 0;
      uStack_180 = 0x7fffffff7fffffff;
      local_188 = 0x7fffffff7fffffff;
      local_178 = 0;
      uStack_170 = 0;
      uStack_160 = 0x7fffffff7fffffff;
      local_168 = 0x7fffffff7fffffff;
      local_158 = 0;
      uStack_150 = 0;
      local_148 = 0;
      uStack_140 = 0x7fffffff7fffffff;
      local_138 = 0;
      uStack_137 = 0;
      uStack_135 = 0;
      local_131 = 0x14;
      local_130 = 0x10000ff00000000;
      local_128 = 0;
      local_120 = 0;
      uStack_118 = 0;
      lStack_1a8 = lVar12;
      cVar6 = (**(code **)(**(long **)param_1 + 0x68))();
      local_138 = cVar6 == '\0';
      this_00 = operator_new(0x130);
      pEVar17 = (Entity *)getEntityForInnerGhost(this,param_1);
      EntityGhost::EntityGhost(this_00,(EntityCreationParameters *)&local_1b0,pEVar17);
      cVar6 = (**(code **)(**(long **)param_1 + 0x68))();
      if ((cVar6 != '\0') &&
         (plVar11 = *(long **)(*(long *)(this_00 + 0xb0) + 8),
         *(long **)(*(long *)(this_00 + 0xb0) + 8) != (long *)0x0)) {
        do {
          plVar20 = plVar11;
          plVar11 = (long *)plVar20[2];
        } while ((long *)plVar20[2] != (long *)0x0);
        do {
          plVar11 = (long *)plVar20[3];
          uVar10 = (**(code **)(*plVar20 + 0x10))(plVar20);
          if ((uVar10 >> 5 & 1) != 0) {
            if (plVar20[1] != 0) {
              lVar12 = plVar20[2];
              lVar18 = plVar20[3];
              if (lVar18 == 0) {
                *(long *)(plVar20[1] + 8) = lVar12;
              }
              else {
                *(long *)(lVar18 + 0x10) = lVar12;
                lVar12 = plVar20[2];
              }
              if (lVar12 != 0) {
                *(long *)(lVar12 + 0x18) = lVar18;
              }
            }
            plVar20[1] = (long)this_00;
            lVar12 = *(long *)(this_00 + 8);
            plVar20[2] = lVar12;
            plVar20[3] = 0;
            if (lVar12 != 0) {
              *(long **)(lVar12 + 0x18) = plVar20;
            }
            *(long **)(this_00 + 8) = plVar20;
          }
          plVar20 = plVar11;
        } while (plVar11 != (long *)0x0);
      }
      if ((vector<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>,std::allocator<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>>>
           *)(this_00 + 0xd8) !=
          (vector<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>,std::allocator<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>>>
           *)(this + 0x18)) {
        std::
        vector<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>,std::allocator<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>>>
        ::assign<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>*,0>
                  ((vector<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>,std::allocator<Pair<IDWithQuality<ID<ItemPrototype,unsigned_short>>,ItemInventoryPositions>>>
                    *)(this_00 + 0xd8),*(Pair **)(this + 0x18),*(Pair **)(this + 0x20));
      }
      EntityTags::EntityTags((EntityTags *)&local_1f8,(EntityTags *)(this + 8));
      pGVar5 = local_1f8;
      local_1f8 = (Ghost *)0x0;
      p_Var21 = *(__tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
                  **)(this_00 + 0x128);
      *(Ghost **)(this_00 + 0x128) = pGVar5;
      if (p_Var21 !=
          (__tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
           *)0x0) {
        std::
        __tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
        ::destroy(p_Var21,*(__tree_node **)(p_Var21 + 8));
        operator_delete(p_Var21);
        pGVar5 = local_1f8;
        local_1f8 = (Ghost *)0x0;
        if (pGVar5 != (Ghost *)0x0) {
          std::
          __tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
          ::destroy((__tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
                     *)pGVar5,*(__tree_node **)(pGVar5 + 8));
          operator_delete(pGVar5);
        }
      }
      plVar11 = (long *)(**(code **)(**(long **)param_1 + 0x4d0))();
      lVar18 = *(long *)(this + 0x70);
      for (lVar12 = *(long *)(this + 0x68); lVar12 != lVar18; lVar12 = lVar12 + 0x30) {
        pEVar22 = *(EntityGhost **)(lVar12 + 8);
        if ((pEVar22 != (EntityGhost *)0x0) &&
           (*(long *)(pEVar22 + 0x78) != 0 || pEVar22 == this_00)) {
          uVar1 = *(undefined1 *)(lVar12 + 0x28);
          uVar2 = *(undefined1 *)(lVar12 + 0x20);
          local_1f8 = (Ghost *)(**(code **)(*(long *)this_00 + 0x108))(this_00,0);
          local_1f0 = CONCAT71(local_1f0._1_7_,uVar1);
          plStack_1e8 = (long *)(**(code **)(*(long *)pEVar22 + 0x108))(pEVar22,0);
          local_1e0 = (long *)CONCAT71(local_1e0._1_7_,uVar2);
          (**(code **)(*plVar11 + 0x18))(plVar11,&local_1f8,0);
        }
      }
      uVar14 = (**(code **)(**(long **)param_1 + 0x48))();
      (**(code **)(**(long **)(this_00 + 0xb0) + 0x2e0))(*(long **)(this_00 + 0xb0),uVar14,0);
      ConsistencyScraper::queueEntity
                (*(ConsistencyScraper **)(*(long *)(this_00 + 0x80) + 0x718),(Entity *)this_00);
      this_01 = (LatencyState *)(**(code **)(**(long **)param_1 + 0x30))();
      if (this_01 == (LatencyState *)0x0) {
        (**(code **)(**(long **)param_1 + 0x110))(*(long **)param_1,pSVar19,this_00,1,0);
        cVar6 = (**(code **)(**(long **)param_1 + 0x68))();
        if (cVar6 != '\0') {
          if (*(long *)(this + 0x40) != 0) {
            lVar12 = *(long *)(this + 0x48);
            lVar18 = *(long *)(this + 0x50);
            if (lVar18 == 0) {
              *(long *)(*(long *)(this + 0x40) + 8) = lVar12;
            }
            else {
              *(long *)(lVar18 + 0x10) = lVar12;
              lVar12 = *(long *)(this + 0x48);
            }
            if (lVar12 != 0) {
              *(long *)(lVar12 + 0x18) = lVar18;
            }
            *(undefined8 *)(this + 0x40) = 0;
          }
          if ((*(long *)(this + 0x80) != 0) &&
             (lVar12 = (**(code **)(**(long **)(this_00 + 0xb0) + 0xfd8))(), lVar12 != 0)) {
            UniquePointer<TrainGhostData,SimpleDeleter<TrainGhostData>,true>::operator=
                      ((UniquePointer<TrainGhostData,SimpleDeleter<TrainGhostData>,true> *)
                       (this_00 + 0x120),(UniquePointer *)(this + 0x80));
          }
          if (this[0x88] == (RemovedEntityUndoAction)0x0) {
            plVar11 = (long *)(**(code **)(**(long **)param_1 + 0x58))();
            iVar9 = (**(code **)(*plVar11 + 0x588))();
            if (iVar9 != 0) {
              bVar8 = (bool)(**(code **)(**(long **)param_1 + 0x48))();
              EntityGhost::silentRevive((Player *)this_00,bVar8);
              if ((int)local_1d0 == 0) {
                UndoItem::entityBuilt(param_2,local_1c8,*(Surface **)(local_1c8 + 0x78));
                pPVar15 = (Player *)(**(code **)(**(long **)param_1 + 0x48))();
                local_1f8 = (Ghost *)&PTR__InventoryBuffer_102f7b7a0;
                plStack_1e8 = (long *)0x0;
                local_1f0 = 0;
                uStack_1d8 = 0;
                local_1e0 = (long *)0x0;
                Player::sendBuildEventForEntity(pPVar15,local_1c8,&local_1f8,auStack_1b8,0);
                InventoryBuffer::~InventoryBuffer((InventoryBuffer *)&local_1f8);
                ReviveResult::~ReviveResult((ReviveResult *)&local_1d0);
                return true;
              }
              ReviveResult::~ReviveResult((ReviveResult *)&local_1d0);
              if (*(vector<Ghost*,std::allocator<Ghost*>> **)(param_1 + 0x10) !=
                  (vector<Ghost*,std::allocator<Ghost*>> *)0x0) {
                local_1f8 = (Ghost *)this_00;
                std::vector<Ghost*,std::allocator<Ghost*>>::push_back_abi_v160006_
                          (*(vector<Ghost*,std::allocator<Ghost*>> **)(param_1 + 0x10),&local_1f8);
              }
            }
          }
          EntityTags::EntityTags((EntityTags *)&local_1d0,(EntityTags *)(this + 8));
          UndoItem::entityBuilt(param_2,(Entity *)this_00,pSVar19);
          pPVar15 = (Player *)(**(code **)(**(long **)param_1 + 0x48))();
          local_1f8 = (Ghost *)&PTR__InventoryBuffer_102f7b7a0;
          plStack_1e8 = (long *)0x0;
          local_1f0 = 0;
          uStack_1d8 = 0;
          local_1e0 = (long *)0x0;
          Player::sendBuildEventForEntity(pPVar15,this_00,&local_1f8,&local_1d0,0);
          plVar20 = local_1e0;
          local_1f8 = (Ghost *)&PTR__InventoryBuffer_102f7b7a0;
          for (plVar11 = plStack_1e8; plVar11 != plVar20; plVar11 = plVar11 + 1) {
            if ((long *)*plVar11 != (long *)0x0) {
              (**(code **)(*(long *)*plVar11 + 200))();
            }
          }
          if (plStack_1e8 != (long *)0x0) {
            local_1e0 = plStack_1e8;
            operator_delete(plStack_1e8);
          }
          p_Var21 = local_1d0;
          local_1d0 = (__tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
                       *)0x0;
          if (p_Var21 !=
              (__tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
               *)0x0) {
            std::
            __tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
            ::destroy(p_Var21,*(__tree_node **)(p_Var21 + 8));
            operator_delete(p_Var21);
            return true;
          }
          return true;
        }
      }
      else {
        *(Surface **)(this_00 + 0x78) = pSVar19;
        plVar11 = (long *)(**(code **)(*(long *)this_00 + 0x3f0))(this_00);
        if (plVar11 != (long *)0x0) {
          if (*(long *)(pSVar19 + 0x38) == 0) {
            if (*(long *)(pSVar19 + 0x30) == 0) {
              uVar16 = *(undefined2 *)(CorePrototypes::pollutionPrototype + 0x188);
            }
            else {
              uVar16 = *(undefined2 *)(*(long *)(*(long *)(pSVar19 + 0x30) + 0x20) + 0x568);
            }
          }
          else {
            uVar16 = 0;
          }
          local_1f8 = (Ghost *)CONCAT62(local_1f8._2_6_,uVar16);
          (**(code **)(*plVar11 + 0x160))(plVar11,&local_1f8);
        }
        (**(code **)(**(long **)(this_00 + 0xb0) + 0x6d8))(*(long **)(this_00 + 0xb0),pSVar19);
        *(undefined8 *)(this_00 + 0x50) = *(undefined8 *)(*(long *)(this_00 + 0xb0) + 0x50);
        LatencyState::addToEntitiesToBeBuilt(this_01,(Entity *)this_00);
      }
      UndoItem::entityBuilt(param_2,(Entity *)this_00,pSVar19);
      return true;
    }
  }
  return false;
}



// ===== RemovedTileUndoAction::apply  @ 0x101a3cab8 =====

/* WARNING: Type propagation algorithm not settling */
/* RemovedTileUndoAction::apply(UndoApplyContext const&, UndoItem&) */

bool __thiscall
RemovedTileUndoAction::apply
          (RemovedTileUndoAction *this,UndoApplyContext *param_1,UndoItem *param_2)

{
  long *plVar1;
  undefined *puVar2;
  __tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
  *this_00;
  long *plVar3;
  char cVar4;
  undefined1 uVar5;
  char cVar6;
  short sVar7;
  long lVar8;
  DeconstructibleTileProxy *pDVar9;
  ulong uVar10;
  undefined8 uVar11;
  TileGhost *pTVar12;
  Player *pPVar13;
  long *plVar14;
  DeconstructibleTileProxy *pDVar15;
  bool bVar16;
  int iVar17;
  uint uVar18;
  int iVar19;
  uint uVar20;
  __tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
  *local_1a0;
  undefined **local_198;
  undefined8 local_190;
  long *plStack_188;
  long *local_180;
  undefined8 uStack_178;
  long *local_170;
  ulong uStack_168;
  ulong local_160;
  ulong uStack_158;
  long local_150;
  long *local_148;
  undefined8 uStack_140;
  undefined8 local_138;
  undefined8 uStack_130;
  undefined8 local_128;
  undefined8 uStack_120;
  undefined8 local_118;
  undefined8 uStack_110;
  undefined8 local_108;
  undefined8 uStack_100;
  undefined1 local_f8;
  undefined2 uStack_f7;
  undefined4 uStack_f5;
  undefined1 local_f1;
  undefined8 local_f0;
  undefined1 local_e8;
  undefined8 local_e0;
  undefined8 uStack_d8;
  undefined8 local_d0;
  undefined8 uStack_c8;
  undefined8 uStack_c0;
  undefined8 auStack_b8 [3];
  long *local_a0;
  ulong uStack_98;
  long *local_90;
  ulong uStack_88;
  long lStack_80;
  long *local_78;
  undefined8 local_70;
  
  lVar8 = (**(code **)(**(long **)param_1 + 0x40))();
  if ((ulong)(*(long *)(lVar8 + 0x2a8) - *(long *)(lVar8 + 0x2a0) >> 3) <=
      (ulong)*(uint *)(this + 0x30)) {
    return false;
  }
  plVar14 = *(long **)(*(long *)(lVar8 + 0x2a0) + (ulong)*(uint *)(this + 0x30) * 8);
  if (plVar14 == (long *)0x0) {
    return false;
  }
  pDVar15 = *(DeconstructibleTileProxy **)(this + 0x18);
  if (pDVar15 == (DeconstructibleTileProxy *)0x0) {
    iVar17 = (int)*(undefined8 *)(this + 0x34) << 8;
    iVar19 = (int)((ulong)*(undefined8 *)(this + 0x34) >> 0x20) << 8;
    uVar18 = iVar17 >> 9;
    uVar20 = iVar19 >> 9;
    uStack_168 = CONCAT44(uVar20,uVar18);
    iVar17 = iVar17 >> 0xd;
    local_148 = (long *)0x0;
    uStack_140 = 0;
    local_150 = 0;
    if ((iVar17 < -*(int *)((long)plVar14 + 0x24)) ||
       (iVar17 = *(int *)((long)plVar14 + 0x24) + iVar17, (int)plVar14[4] <= iVar17)) {
LAB_101a3cc38:
      uStack_158 = CONCAT44(uVar20,uVar18) | 0xf;
    }
    else {
      plVar1 = (long *)(plVar14[3] + (long)iVar17 * 0x10);
      if (plVar1 == (long *)0x0) goto LAB_101a3cc38;
      iVar19 = iVar19 >> 0xd;
      lVar8 = plVar14[3] + (long)iVar17 * 0x10;
      iVar17 = *(int *)(lVar8 + 0xc);
      if ((((iVar19 < -iVar17) || (iVar17 = iVar17 + iVar19, *(int *)(lVar8 + 8) <= iVar17)) ||
          (plVar1 = (long *)(*plVar1 + (long)iVar17 * 8), plVar1 == (long *)0x0)) ||
         (local_150 = *plVar1, local_150 == 0)) goto LAB_101a3cc38;
      uStack_140 = *(undefined8 *)
                    (local_150 + ((ulong)uVar18 & 0xf) * 0x80 + ((ulong)uVar20 & 0xf) * 8 + 0xc50);
      uStack_158 = uStack_168;
    }
    local_170 = plVar14;
    local_160 = uStack_168;
    HeuristicEntityIterator<Surface>::moveUntilEntityFound();
    puVar2 = PTR_indexToPrototype_102d4c598;
    uStack_88 = uStack_158;
    local_90 = (long *)local_160;
    local_78 = local_148;
    lStack_80 = local_150;
    uStack_98 = uStack_168;
    local_a0 = local_170;
    local_70 = uStack_140;
    if (local_148 == (long *)0x0) {
      pDVar15 = (DeconstructibleTileProxy *)0x0;
    }
    else {
      pDVar15 = (DeconstructibleTileProxy *)0x0;
      do {
        plVar1 = local_78;
        pDVar9 = (DeconstructibleTileProxy *)(**(code **)(*local_78 + 0xbf8))(local_78);
        if (pDVar9 != (DeconstructibleTileProxy *)0x0) {
          cVar6 = (**(code **)(*plVar1 + 0x220))(plVar1);
          cVar4 = (**(code **)(**(long **)param_1 + 0x60))();
          if (((cVar6 == cVar4) &&
              (lVar8 = *(long *)(*(long *)puVar2 + (ulong)*(ushort *)(this + 0x3c) * 8),
              *(char *)(lVar8 + 0x1b10) != '\0')) &&
             ((bool)*(char *)(lVar8 + 0x1bb1) == (pDVar9[0x8c] == (DeconstructibleTileProxy)0x1))) {
            uVar18 = *(int *)(this + 0x34) << 8 | 0x80;
            uVar20 = *(int *)(this + 0x38) << 8 | 0x80;
            local_198 = (undefined **)((ulong)uVar18 | (ulong)(uVar20 >> 7) << 0x27);
            iVar17 = *(int *)(pDVar9 + 0x5c);
            if (iVar17 != *(int *)(pDVar9 + 100) ||
                *(int *)(pDVar9 + 0x60) != *(int *)(pDVar9 + 0x68)) {
              if (*(short *)(pDVar9 + 0x6c) == 0) {
                if ((iVar17 <= (int)uVar18) &&
                   (((int)uVar20 <= *(int *)(pDVar9 + 0x68) && (int)uVar18 <= *(int *)(pDVar9 + 100)
                    ) && *(int *)(pDVar9 + 0x60) <= (int)uVar20)) goto LAB_101a3cc98;
              }
              else {
                uStack_c8 = 0;
                local_d0 = 0;
                auStack_b8[0] = 0;
                uStack_c0 = 0;
                ::BoundingBox::getRotatedVertices
                          ((BoundingBox *)(pDVar9 + 0x5c),(MapPosition *)&local_d0,
                           (MapPosition *)&uStack_c8,(MapPosition *)&uStack_c0,
                           (MapPosition *)auStack_b8);
                uVar10 = RotatedBoundingBox::collide
                                   ((RotatedBoundingBox *)&local_d0,(MapPosition *)&local_198);
                if ((uVar10 & 1) != 0) {
LAB_101a3cc98:
                  pDVar15 = pDVar9;
                }
              }
            }
          }
        }
        HeuristicEntityIterator<Surface>::moveUntilEntityFound();
      } while (local_78 != (long *)0x0);
      if (pDVar15 != (DeconstructibleTileProxy *)0x0) goto LAB_101a3cb1c;
    }
    bVar16 = true;
  }
  else {
LAB_101a3cb1c:
    sVar7 = DeconstructibleTileProxy::getTileID(pDVar15,0);
    bVar16 = false;
    if ((sVar7 != 0) && (*(short *)(this + 0x3c) == sVar7)) {
      UndoItem::tileBuilt(param_2,sVar7,0,*(undefined4 *)(this + 0x30),*(undefined8 *)(this + 0x34))
      ;
      (**(code **)(**(long **)param_1 + 0xd0))(*(long **)param_1,pDVar15);
      return true;
    }
  }
  local_a0 = *(long **)param_1;
  uStack_98 = (**(code **)(*local_a0 + 0x30))();
  uStack_88 = 0;
  lStack_80 = 0x7fffffff7fffffff;
  local_78 = (long *)0x0;
  local_70 = 0;
  lVar8 = *(long *)(*(long *)PTR_indexToPrototype_102d4c598 + (ulong)*(ushort *)(this + 0x3c) * 8);
  if (*(ushort **)(lVar8 + 0x1b98) == *(ushort **)(lVar8 + 0x1ba0)) {
    return false;
  }
  local_90 = plVar14;
  TileCheckData::checkBuildability
            (&local_d0,&local_a0,lVar8,
             *(long *)(*(long *)PTR_indexToPrototype_102d4c4e8 +
                      (ulong)**(ushort **)(lVar8 + 0x1b98) * 8) + 0x278,this + 0x34,1,0,0,1);
  if ((int)local_d0 != 0) {
    if ((int)local_d0 == 2) {
      removeTileRemoversOnThisSpot(this,param_1);
      return false;
    }
    return (int)local_d0 == 0;
  }
  if (!bVar16) {
    (**(code **)(**(long **)param_1 + 0xd0))(*(long **)param_1,pDVar15);
  }
  plVar1 = CorePrototypes::tileGhost;
  uVar11 = (**(code **)(**(long **)param_1 + 0x40))();
  iVar17 = *(int *)(this + 0x34);
  iVar19 = *(int *)(this + 0x38);
  uVar5 = (**(code **)(**(long **)param_1 + 0x60))();
  local_170 = plVar1;
  uStack_158 = (ulong)CONCAT52((int5)(uStack_158 >> 0x18),
                               CONCAT11(CorePrototypes::normalQuality,uVar5)) << 8;
  local_150 = 0;
  uStack_140 = 0x7fffffff7fffffff;
  local_148 = (long *)0x7fffffff7fffffff;
  local_138 = 0;
  uStack_130 = 0;
  uStack_120 = 0x7fffffff7fffffff;
  local_128 = 0x7fffffff7fffffff;
  local_118 = 0;
  uStack_110 = 0;
  local_108 = 0;
  uStack_100 = 0x7fffffff7fffffff;
  local_f8 = 0;
  uStack_f7 = 0;
  uStack_f5 = 0;
  local_f1 = 0x14;
  local_f0 = 0x10000ff00000000;
  local_e8 = 0;
  local_e0 = 0;
  uStack_d8 = 0;
  uStack_168 = uVar11;
  local_160 = (ulong)(iVar17 << 8 | 0x80) | (ulong)((iVar19 << 8 | 0x80U) >> 7) << 0x27;
  cVar6 = (**(code **)(**(long **)param_1 + 0x68))();
  local_f8 = cVar6 == '\0';
  pTVar12 = operator_new(0xb0);
  TileGhost::TileGhost(pTVar12,&local_170,*(undefined2 *)(this + 0x3c));
  lVar8 = (**(code **)(**(long **)param_1 + 0x48))();
  if (lVar8 != 0) {
    *(undefined2 *)(pTVar12 + 0xae) = *(undefined2 *)(lVar8 + 0x28);
  }
  (**(code **)(**(long **)param_1 + 0x110))(*(long **)param_1,plVar14,pTVar12,0,0);
  cVar6 = (**(code **)(**(long **)param_1 + 0x68))();
  if (cVar6 != '\0') {
    pPVar13 = (Player *)(**(code **)(**(long **)param_1 + 0x48))();
    local_1a0 = (__tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
                 *)0x0;
    local_198 = &PTR__InventoryBuffer_102f7b7a0;
    plStack_188 = (long *)0x0;
    local_190 = 0;
    uStack_178 = 0;
    local_180 = (long *)0x0;
    Player::sendBuildEventForEntity(pPVar13,pTVar12,&local_198,&local_1a0,0);
    this_00 = local_1a0;
    local_1a0 = (__tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
                 *)0x0;
    if (this_00 !=
        (__tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
         *)0x0) {
      std::
      __tree<std::__value_type<std::string,PropertyTree>,std::__map_value_compare<std::string,std::__value_type<std::string,PropertyTree>,std::less<void>,true>,std::allocator<std::__value_type<std::string,PropertyTree>>>
      ::destroy(this_00,*(__tree_node **)(this_00 + 8));
      operator_delete(this_00);
    }
    plVar3 = local_180;
    local_198 = &PTR__InventoryBuffer_102f7b7a0;
    for (plVar1 = plStack_188; plVar1 != plVar3; plVar1 = plVar1 + 1) {
      if ((long *)*plVar1 != (long *)0x0) {
        (**(code **)(*(long *)*plVar1 + 200))();
      }
    }
    if (plStack_188 != (long *)0x0) {
      local_180 = plStack_188;
      operator_delete(plStack_188);
    }
  }
  UndoItem::tileBuilt(param_2,pTVar12,(Surface *)plVar14);
  return true;
}



// ===== RotatedEntityUndoAction::apply  @ 0x101a3d9fc =====

/* RotatedEntityUndoAction::apply(UndoApplyContext const&, UndoItem&) */

undefined8 __thiscall
RotatedEntityUndoAction::apply
          (RotatedEntityUndoAction *this,UndoApplyContext *param_1,UndoItem *param_2)

{
  char cVar1;
  char cVar2;
  RotatedEntityUndoAction RVar3;
  RotatedEntityUndoAction RVar4;
  int iVar5;
  long *plVar6;
  CraftingMachine *pCVar7;
  undefined8 uVar8;
  
  plVar6 = *(long **)(this + 0x18);
  if ((plVar6 != (long *)0x0) && (plVar6[0xf] != 0)) {
    iVar5 = (**(code **)(*plVar6 + 0x210))();
    if (iVar5 != 0) {
      cVar1 = (**(code **)(**(long **)(this + 0x18) + 0x220))();
      cVar2 = (**(code **)(**(long **)param_1 + 0x60))();
      if (cVar1 != cVar2) {
        return 0;
      }
    }
    plVar6 = (long *)(**(code **)(**(long **)(this + 0x18) + 0x108))(*(long **)(this + 0x18),0);
    RVar3 = (RotatedEntityUndoAction)(**(code **)(*plVar6 + 0x4d8))();
    RVar4 = (RotatedEntityUndoAction)(**(code **)(*plVar6 + 0x4e0))(plVar6);
    UndoItem::entityRotated(param_2,*(undefined8 *)(this + 0x18),RVar3,RVar4);
    if (((this[0x31] == RVar4) ||
        (cVar1 = (**(code **)(**(long **)param_1 + 0x68))(), cVar1 == '\0')) ||
       (pCVar7 = (CraftingMachine *)(**(code **)(*plVar6 + 0xa78))(plVar6),
       pCVar7 == (CraftingMachine *)0x0)) {
      if (this[0x30] != RVar3) {
        plVar6 = *(long **)param_1;
        uVar8 = Entity::getOuterEntity(*(Entity **)(this + 0x18));
        (**(code **)(*plVar6 + 0x4e8))(plVar6,uVar8,this[0x30]);
      }
    }
    else {
      CraftingMachine::setDirectionAndMirroring(pCVar7,this[0x30],this[0x31]);
    }
    return 1;
  }
  return 0;
}



// ===== UndoItem::apply  @ 0x101a41d34 =====

/* UndoItem::apply(GameAdapter const&, UndoItem&, UndoMode) const */

void __thiscall
UndoItem::apply(UndoItem *this,undefined8 param_1,undefined8 param_2,undefined8 param_4)

{
  undefined8 local_30;
  undefined4 uStack_28;
  undefined4 uStack_24;
  undefined4 uStack_20;
  undefined8 uStack_1c;
  
  local_30 = *(undefined8 *)(this + 0x28);
  uStack_28 = (undefined4)*(undefined8 *)(this + 0x30);
  uStack_1c = *(undefined8 *)(this + 0x3c);
  uStack_24 = (undefined4)*(undefined8 *)(this + 0x34);
  uStack_20 = (undefined4)((ulong)*(undefined8 *)(this + 0x34) >> 0x20);
  apply(this + 8,0,&local_30,param_1,param_2,param_4);
  return;
}



// ===== UpgradedEntityUndoAction::apply  @ 0x101a44b54 =====

/* UpgradedEntityUndoAction::apply(UndoApplyContext const&, UndoItem&) */

undefined8 __thiscall
UpgradedEntityUndoAction::apply
          (UpgradedEntityUndoAction *this,UndoApplyContext *param_1,UndoItem *param_2)

{
  ulong uVar1;
  ushort uVar2;
  char cVar3;
  char cVar4;
  undefined1 uVar5;
  int iVar6;
  uint uVar7;
  uint uVar8;
  long *plVar9;
  LatencyState *this_00;
  long lVar10;
  undefined8 uVar11;
  Entity *this_01;
  uint uVar12;
  long *plVar13;
  
  plVar9 = *(long **)(this + 0x18);
  if (plVar9 == (long *)0x0) {
    return 0;
  }
  if (plVar9[0xf] == 0) {
    return 0;
  }
  iVar6 = (**(code **)(*plVar9 + 0x210))();
  if (iVar6 != 0) {
    cVar3 = (**(code **)(**(long **)(this + 0x18) + 0x220))();
    cVar4 = (**(code **)(**(long **)param_1 + 0x60))();
    if (cVar3 != cVar4) {
      return 0;
    }
  }
  iVar6 = (**(code **)(**(long **)(this + 0x18) + 0x5a8))();
  if (iVar6 == 0) {
    return 0;
  }
  this_00 = (LatencyState *)(**(code **)(**(long **)param_1 + 0x30))();
  if (iVar6 == 2) {
    if (this_00 == (LatencyState *)0x0) {
      uVar8 = EntityGhost::getCurrentState((EntityGhost *)this_01);
    }
    else {
LAB_101a44c34:
      uVar8 = LatencyState::getUpgradeTargetWithFallback(this_00,this_01);
    }
  }
  else {
    if (iVar6 != 1) {
      uVar12 = 0;
      uVar7 = 0;
      uVar8 = 0;
      goto LAB_101a44c64;
    }
    if (this_00 != (LatencyState *)0x0) goto LAB_101a44c34;
    if (*(short *)(this_01 + 0x8e) == 0) {
      uVar2 = *(ushort *)(*(long *)(this_01 + 0x48) + 0x188);
      uVar8 = (**(code **)(*(long *)this_01 + 0x758))(this_01);
      uVar8 = (uint)uVar2 | (uVar8 & 0xff) << 0x10;
    }
    else {
      uVar8 = *(uint *)(this_01 + 0x8e);
    }
  }
  uVar7 = uVar8 & 0xffff0000;
  uVar12 = uVar8 & 0xff000000;
LAB_101a44c64:
  UndoItem::entityToBeUpgraded
            (param_2,*(undefined8 *)(this + 0x18),uVar7 & 0xff0000 | uVar12 | uVar8 & 0xffff);
  if (((uint)*(ushort *)(this + 0x30) != (uVar8 & 0xffff)) ||
     ((uint)(byte)this[0x32] != (uVar7 >> 0x10 & 0xff))) {
    if (iVar6 == 2) {
      uVar11 = EntityGhost::getCurrentState((EntityGhost *)this_01);
      uVar8 = (uint)uVar11;
      uVar7 = (uint)((ulong)uVar11 >> 0x10) & 0xffff;
    }
    else if (iVar6 == 1) {
      uVar8 = (uint)*(ushort *)(*(long *)(this_01 + 0x48) + 0x188);
      uVar7 = (**(code **)(*(long *)this_01 + 0x758))(this_01);
    }
    else {
      uVar7 = 0;
      uVar8 = 0;
    }
    plVar9 = *(long **)(this + 0x18);
    if (((uint)*(ushort *)(this + 0x30) == (uVar8 & 0xffff)) &&
       ((uint)(byte)this[0x32] == (uVar7 & 0xff))) {
      lVar10 = (**(code **)(*plVar9 + 0xc58))(plVar9);
      if (lVar10 != 0) {
        plVar9 = *(long **)param_1;
        uVar11 = (**(code **)(**(long **)(this + 0x18) + 0xc58))();
        (**(code **)(*plVar9 + 0x28))(plVar9,uVar11);
      }
    }
    else {
      uVar5 = (**(code **)(**(long **)param_1 + 0x60))();
      if (*(ushort *)(this + 0x30) == 0) {
        return 0;
      }
      plVar13 = *(long **)(*(long *)PTR_indexToPrototype_102d4c840 +
                          (ulong)*(ushort *)(this + 0x30) * 8);
      uVar11 = UpgradeData::acceptableForUpgrade(plVar9,uVar5);
      if ((int)uVar11 == 0) {
        return uVar11;
      }
      if (CorePrototypes::unknownEntity != plVar13) {
        uVar11 = (**(code **)(*plVar13 + 0x5e0))(plVar13);
        if ((int)uVar11 == 0) {
          return uVar11;
        }
        uVar1 = plVar13[0xa1];
        if (-1 < (char)*(byte *)((long)plVar13 + 0x517)) {
          uVar1 = (ulong)*(byte *)((long)plVar13 + 0x517);
        }
        if (uVar1 == 0) {
          return 0;
        }
        if ((ushort *)plVar13[0x6e] == (ushort *)plVar13[0x6f]) {
          return 0;
        }
        if (*(char *)(*(long *)(*(long *)PTR_indexToPrototype_102d4c4e8 +
                               (ulong)*(ushort *)plVar13[0x6e] * 8) + 0x158) != '\0') {
          return 0;
        }
      }
      (**(code **)(**(long **)param_1 + 0x18))
                (*(long **)param_1,*(undefined8 *)(this + 0x18),*(undefined4 *)(this + 0x30),0);
    }
  }
  return 1;
}



// ===== UpgradedModulesUndoAction::apply  @ 0x101a45700 =====

/* UpgradedModulesUndoAction::apply(UndoApplyContext const&, UndoItem&) */

undefined8 __thiscall
UpgradedModulesUndoAction::apply
          (UpgradedModulesUndoAction *this,UndoApplyContext *param_1,UndoItem *param_2)

{
  void *pvVar1;
  void *pvVar2;
  char cVar3;
  char cVar4;
  int iVar5;
  long *plVar6;
  undefined8 uVar7;
  long lVar8;
  void *pvVar9;
  void *local_48;
  void *local_40;
  
  plVar6 = *(long **)(this + 0x18);
  if ((plVar6 != (long *)0x0) && (plVar6[0xf] != 0)) {
    iVar5 = (**(code **)(*plVar6 + 0x210))();
    if (iVar5 != 0) {
      cVar3 = (**(code **)(**(long **)(this + 0x18) + 0x220))();
      cVar4 = (**(code **)(**(long **)param_1 + 0x60))();
      if (cVar3 != cVar4) {
        return 0;
      }
    }
    plVar6 = (long *)(**(code **)(**(long **)(this + 0x18) + 0x108))(*(long **)(this + 0x18),0);
    uVar7 = (**(code **)(*(long *)plVar6[9] + 0x130))();
    if ((int)uVar7 == 0xff) {
      return 0;
    }
    lVar8 = (**(code **)(*plVar6 + 0x368))(plVar6,uVar7);
    if (lVar8 != 0) {
      getCurrentInsertPlanOfTarget();
      (**(code **)(**(long **)param_1 + 0x128))
                (*(long **)param_1,*(undefined8 *)(this + 0x18),this + 0x30);
      UndoItem::modulesReplaced(param_2,*(Entity **)(this + 0x18),(InsertPlan *)&local_48);
      pvVar2 = local_48;
      if (local_48 != (void *)0x0) {
        while (pvVar1 = local_40, pvVar1 != pvVar2) {
          pvVar9 = *(void **)((long)pvVar1 + -0x18);
          local_40 = (void *)((long)pvVar1 + -0x28);
          if (pvVar9 != (void *)0x0) {
            *(void **)((long)pvVar1 + -0x10) = pvVar9;
            operator_delete(pvVar9);
          }
        }
        local_40 = pvVar2;
        operator_delete(local_48);
      }
      return 1;
    }
  }
  return 0;
}



// ===== WireAddedUndoAction::apply  @ 0x101a46a98 =====

/* WireAddedUndoAction::apply(UndoApplyContext const&, UndoItem&) */

undefined8 __thiscall
WireAddedUndoAction::apply(WireAddedUndoAction *this,UndoApplyContext *param_1,UndoItem *param_2)

{
  long *plVar1;
  undefined8 uVar2;
  Wire aWStack_58 [32];
  char local_38;
  
  getWire();
  if (((local_38 != '\0') && (*(long *)(*(long *)(this + 0x18) + 0x78) != 0)) &&
     (*(long *)(*(long *)(this + 0x40) + 0x78) != 0)) {
    plVar1 = (long *)(**(code **)(**(long **)param_1 + 0x4d0))();
    uVar2 = (**(code **)(*plVar1 + 0x20))(plVar1,aWStack_58);
    if ((int)uVar2 != 0) {
      UndoItem::wireRemoved(param_2,aWStack_58);
      uVar2 = 1;
    }
    return uVar2;
  }
  return 0;
}



// ===== WireRemovedUndoAction::apply  @ 0x101a47a6c =====

/* WireRemovedUndoAction::apply(UndoApplyContext const&, UndoItem&) */

bool __thiscall
WireRemovedUndoAction::apply
          (WireRemovedUndoAction *this,UndoApplyContext *param_1,UndoItem *param_2)

{
  int iVar1;
  long *plVar2;
  Wire aWStack_58 [32];
  char local_38;
  
  getWire();
  if (((local_38 != '\0') && (*(long *)(*(long *)(this + 0x18) + 0x78) != 0)) &&
     (*(long *)(*(long *)(this + 0x40) + 0x78) != 0)) {
    plVar2 = (long *)(**(code **)(**(long **)param_1 + 0x4d0))();
    iVar1 = (**(code **)(*plVar2 + 0x18))(plVar2,aWStack_58,0);
    if (iVar1 == 0x11 || iVar1 == 0) {
      UndoItem::wireAdded(param_2,aWStack_58);
    }
    return iVar1 == 0 || iVar1 == 0x11;
  }
  return false;
}



// ===== Transform3D::apply  @ 0x101ac29ac =====

/* Transform3D::apply(float, float, float, float) const */

void Transform3D::apply(float param_1,float param_2,float param_3,float param_4)

{
  return;
}



// ===== InstantTriggerDelivery::apply  @ 0x101b433c4 =====

/* InstantTriggerDelivery::apply(TriggerContext const&) const */

void __thiscall InstantTriggerDelivery::apply(InstantTriggerDelivery *this,TriggerContext *param_1)

{
  TriggerDelivery::apply((TriggerDelivery *)this,param_1);
  return;
}



// ===== IntegratedStyle<ButtonStyleSpecification>::apply  @ 0x102029610 =====

/* IntegratedStyle<ButtonStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<ButtonStyleSpecification>::apply(set *param_1)

{
  ButtonStyleSpecification::apply
            ((ButtonStyleSpecification *)(param_1 + 8),(ButtonStyle *)(param_1 + 0x180),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<CheckBoxStyleSpecification>::apply  @ 0x102029d7c =====

/* IntegratedStyle<CheckBoxStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<CheckBoxStyleSpecification>::apply(set *param_1)

{
  CheckBoxStyleSpecification::apply
            ((CheckBoxStyleSpecification *)(param_1 + 8),(CheckBoxStyle *)(param_1 + 0x150),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<DropDownStyleSpecification>::apply  @ 0x10202a1ec =====

/* IntegratedStyle<DropDownStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<DropDownStyleSpecification>::apply(set *param_1)

{
  DropDownStyleSpecification::apply
            ((DropDownStyleSpecification *)(param_1 + 8),(DropDownStyle *)(param_1 + 0xf8),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<DoubleSliderStyleSpecification>::apply  @ 0x10202a898 =====

/* IntegratedStyle<DoubleSliderStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<DoubleSliderStyleSpecification>::apply(set *param_1)

{
  SliderStyleSpecification::apply
            ((SliderStyleSpecification *)(param_1 + 8),(SliderStyle *)(param_1 + 0x100),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<FlowStyleSpecification>::apply  @ 0x10202ae18 =====

/* IntegratedStyle<FlowStyleSpecification>::apply(std::set<agui::Style const*, std::less<agui::Style
   const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<FlowStyleSpecification>::apply(set *param_1)

{
  int iVar1;
  
  StyleSpecification::apply
            ((StyleSpecification *)(param_1 + 8),(Style *)(param_1 + 0xd8),
             (OptionalFundamentalBase *)0x0);
  if (param_1[0xc0] != (set)0x0) {
    *(undefined4 *)(param_1 + 0x140) = *(undefined4 *)(param_1 + 0xbc);
    param_1[0x144] = (set)0x1;
  }
  if (param_1[200] != (set)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(param_1 + 0xc4));
    *(int *)(param_1 + 0x148) = iVar1;
    param_1[0x14c] = (set)0x1;
  }
  if (param_1[0xd0] != (set)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(param_1 + 0xcc));
    *(int *)(param_1 + 0x150) = iVar1;
    param_1[0x154] = (set)0x1;
  }
  return;
}



// ===== IntegratedStyle<FrameStyleSpecification>::apply  @ 0x10202b3bc =====

/* IntegratedStyle<FrameStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<FrameStyleSpecification>::apply(set *param_1)

{
  FrameStyleSpecification::apply
            ((FrameStyleSpecification *)(param_1 + 8),(FrameStyle *)(param_1 + 0x110),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<GraphStyleSpecification>::apply  @ 0x10202b854 =====

/* IntegratedStyle<GraphStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<GraphStyleSpecification>::apply(set *param_1)

{
  GraphStyleSpecification::apply
            ((GraphStyleSpecification *)(param_1 + 8),(GraphStyle *)(param_1 + 0x140));
  return;
}



// ===== IntegratedStyle<LabelStyleSpecification>::apply  @ 0x10202bdcc =====

/* IntegratedStyle<LabelStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<LabelStyleSpecification>::apply(set *param_1)

{
  LabelStyleSpecification::apply
            ((LabelStyleSpecification *)(param_1 + 8),(LabelStyle *)(param_1 + 0x120),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<ListBoxStyleSpecification>::apply  @ 0x10202c3e4 =====

/* IntegratedStyle<ListBoxStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<ListBoxStyleSpecification>::apply(set *param_1)

{
  ListBoxStyleSpecification::apply
            ((ListBoxStyleSpecification *)(param_1 + 8),(ListBoxStyle *)(param_1 + 0xd0),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<ProgressBarStyleSpecification>::apply  @ 0x10202c9c0 =====

/* IntegratedStyle<ProgressBarStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<ProgressBarStyleSpecification>::apply(set *param_1)

{
  ProgressBarStyleSpecification::apply
            ((ProgressBarStyleSpecification *)(param_1 + 8),(ProgressBarStyle *)(param_1 + 0x110),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<RadioButtonStyleSpecification>::apply  @ 0x10202cdc4 =====

/* IntegratedStyle<RadioButtonStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<RadioButtonStyleSpecification>::apply(set *param_1)

{
  RadioButtonStyleSpecification::apply
            ((RadioButtonStyleSpecification *)(param_1 + 8),(RadioButtonStyle *)(param_1 + 0x138),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<HorizontalScrollBarStyleSpecification>::apply  @ 0x10202d418 =====

/* IntegratedStyle<HorizontalScrollBarStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<HorizontalScrollBarStyleSpecification>::apply(set *param_1)

{
  ScrollBarStyleSpecification::apply
            ((ScrollBarStyleSpecification *)(param_1 + 8),(ScrollBarStyle *)(param_1 + 0xd0));
  return;
}



// ===== IntegratedStyle<VerticalScrollBarStyleSpecification>::apply  @ 0x10202da4c =====

/* IntegratedStyle<VerticalScrollBarStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<VerticalScrollBarStyleSpecification>::apply(set *param_1)

{
  ScrollBarStyleSpecification::apply
            ((ScrollBarStyleSpecification *)(param_1 + 8),(ScrollBarStyle *)(param_1 + 0xd0));
  return;
}



// ===== IntegratedStyle<SliderStyleSpecification>::apply  @ 0x10202dec0 =====

/* IntegratedStyle<SliderStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<SliderStyleSpecification>::apply(set *param_1)

{
  SliderStyleSpecification::apply
            ((SliderStyleSpecification *)(param_1 + 8),(SliderStyle *)(param_1 + 0x100),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<TabStyleSpecification>::apply  @ 0x10202e334 =====

/* IntegratedStyle<TabStyleSpecification>::apply(std::set<agui::Style const*, std::less<agui::Style
   const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<TabStyleSpecification>::apply(set *param_1)

{
  TabStyleSpecification::apply
            ((TabStyleSpecification *)(param_1 + 8),(TabStyle *)(param_1 + 0x1a8),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<TableStyleSpecification>::apply  @ 0x10202e8c4 =====

/* IntegratedStyle<TableStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<TableStyleSpecification>::apply(set *param_1)

{
  TableStyleSpecification::apply
            ((TableStyleSpecification *)(param_1 + 8),(TableStyle *)(param_1 + 400),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<TextBoxStyleSpecification>::apply  @ 0x10202f028 =====

/* IntegratedStyle<TextBoxStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<TextBoxStyleSpecification>::apply(set *param_1)

{
  TextBoxStyleSpecification::apply
            ((TextBoxStyleSpecification *)(param_1 + 8),(TextBoxStyle *)(param_1 + 0x138),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<ScrollPaneStyleSpecification>::apply  @ 0x10202f650 =====

/* IntegratedStyle<ScrollPaneStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<ScrollPaneStyleSpecification>::apply(set *param_1)

{
  ScrollPaneStyleSpecification::apply
            ((ScrollPaneStyleSpecification *)(param_1 + 8),(ScrollPaneStyle *)(param_1 + 0x130),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<ImageStyleSpecification>::apply  @ 0x10202fbf0 =====

/* IntegratedStyle<ImageStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<ImageStyleSpecification>::apply(set *param_1)

{
  ImageStyleSpecification::apply
            ((ImageStyleSpecification *)(param_1 + 8),(ImageStyle *)(param_1 + 0xd0),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<ActivityBarStyleSpecification>::apply  @ 0x10203027c =====

/* IntegratedStyle<ActivityBarStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<ActivityBarStyleSpecification>::apply(set *param_1)

{
  ActivityBarStyleSpecification::apply
            ((ActivityBarStyleSpecification *)(param_1 + 8),(ActivityBarStyle *)(param_1 + 0xf0));
  return;
}



// ===== IntegratedStyle<CameraStyleSpecification>::apply  @ 0x102030684 =====

/* IntegratedStyle<CameraStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<CameraStyleSpecification>::apply(set *param_1)

{
  EmptyWidgetStyleSpecification::apply
            ((EmptyWidgetStyleSpecification *)(param_1 + 8),(EmptyWidgetStyle *)(param_1 + 200),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<MinimapStyleSpecification>::apply  @ 0x102030b9c =====

/* IntegratedStyle<MinimapStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<MinimapStyleSpecification>::apply(set *param_1)

{
  EmptyWidgetStyleSpecification::apply
            ((EmptyWidgetStyleSpecification *)(param_1 + 8),(EmptyWidgetStyle *)(param_1 + 200),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<HorizontalFlowStyleSpecification>::apply  @ 0x1020311b0 =====

/* IntegratedStyle<HorizontalFlowStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<HorizontalFlowStyleSpecification>::apply(set *param_1)

{
  int iVar1;
  
  StyleSpecification::apply
            ((StyleSpecification *)(param_1 + 8),(Style *)(param_1 + 200),
             (OptionalFundamentalBase *)0x0);
  if (param_1[0xc0] != (set)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(param_1 + 0xbc));
    *(int *)(param_1 + 0x130) = iVar1;
    param_1[0x134] = (set)0x1;
  }
  return;
}



// ===== IntegratedStyle<VerticalFlowStyleSpecification>::apply  @ 0x1020316ec =====

/* IntegratedStyle<VerticalFlowStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<VerticalFlowStyleSpecification>::apply(set *param_1)

{
  int iVar1;
  
  StyleSpecification::apply
            ((StyleSpecification *)(param_1 + 8),(Style *)(param_1 + 200),
             (OptionalFundamentalBase *)0x0);
  if (param_1[0xc0] != (set)0x0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(param_1 + 0xbc));
    *(int *)(param_1 + 0x130) = iVar1;
    param_1[0x134] = (set)0x1;
  }
  return;
}



// ===== IntegratedStyle<SwitchStyleSpecification>::apply  @ 0x102031bb4 =====

/* IntegratedStyle<SwitchStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<SwitchStyleSpecification>::apply(set *param_1)

{
  SwitchStyleSpecification::apply
            ((SwitchStyleSpecification *)(param_1 + 8),(SwitchStyle *)(param_1 + 0x108),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<TabbedPaneStyleSpecification>::apply  @ 0x102032180 =====

/* IntegratedStyle<TabbedPaneStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<TabbedPaneStyleSpecification>::apply(set *param_1)

{
  TabbedPaneStyleSpecification::apply
            ((TabbedPaneStyleSpecification *)(param_1 + 8),(TabbedPaneStyle *)(param_1 + 0xd8),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<EmptyWidgetStyleSpecification>::apply  @ 0x10203269c =====

/* IntegratedStyle<EmptyWidgetStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<EmptyWidgetStyleSpecification>::apply(set *param_1)

{
  EmptyWidgetStyleSpecification::apply
            ((EmptyWidgetStyleSpecification *)(param_1 + 8),(EmptyWidgetStyle *)(param_1 + 200),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<LineStyleSpecification>::apply  @ 0x102032bb4 =====

/* IntegratedStyle<LineStyleSpecification>::apply(std::set<agui::Style const*, std::less<agui::Style
   const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<LineStyleSpecification>::apply(set *param_1)

{
  int iVar1;
  long lVar2;
  
  StyleSpecification::apply
            ((StyleSpecification *)(param_1 + 8),(Style *)(param_1 + 200),
             (OptionalFundamentalBase *)0x0);
  lVar2 = *(long *)(param_1 + 0xc0);
  if (lVar2 != 0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(lVar2 + 4));
    *(int *)(*(long *)(lVar2 + 0x968) + 4) = iVar1;
    agui::LineStyle::setBorder
              ((LineStyle *)(param_1 + 200),*(BorderImageSet **)(*(long *)(param_1 + 0xc0) + 0x968))
    ;
    return;
  }
  return;
}



// ===== IntegratedStyle<TechnologySlotStyleSpecification>::apply  @ 0x1020331f0 =====

/* IntegratedStyle<TechnologySlotStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<TechnologySlotStyleSpecification>::apply(set *param_1)

{
  TechnologySlotStyleSpecification::apply
            ((TechnologySlotStyleSpecification *)(param_1 + 8),
             (TechnologySlotStyle *)(param_1 + 0x300),(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedStyle<GlowStyleSpecification>::apply  @ 0x10203360c =====

/* IntegratedStyle<GlowStyleSpecification>::apply(std::set<agui::Style const*, std::less<agui::Style
   const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<GlowStyleSpecification>::apply(set *param_1)

{
  ElementImageSet *this;
  void *pvVar1;
  ElementImageSet *pEVar2;
  
  StyleSpecification::apply
            ((StyleSpecification *)(param_1 + 8),(Style *)(param_1 + 200),
             (OptionalFundamentalBase *)0x0);
  if (*(undefined8 **)(param_1 + 0xc0) != (undefined8 *)0x0) {
    pEVar2 = (ElementImageSet *)**(undefined8 **)(param_1 + 0xc0);
    this = operator_new(600);
    agui::ElementImageSet::ElementImageSet(this,pEVar2);
    pEVar2 = *(ElementImageSet **)(param_1 + 0x130);
    *(ElementImageSet **)(param_1 + 0x130) = this;
    if (pEVar2 != (ElementImageSet *)0x0) {
      pvVar1 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar2);
      operator_delete(pvVar1);
      return;
    }
  }
  return;
}



// ===== IntegratedStyle<SpeechBubbleStyleSpecification>::apply  @ 0x102033c24 =====

/* IntegratedStyle<SpeechBubbleStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedStyle<SpeechBubbleStyleSpecification>::apply(set *param_1)

{
  SpeechBubbleStyleSpecification::apply
            ((SpeechBubbleStyleSpecification *)(param_1 + 8),(SpeechBubbleStyle *)(param_1 + 0xf8),
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<ButtonStyleSpecification>::apply  @ 0x102033ff0 =====

/* IntegratedRootStyle<ButtonStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<ButtonStyleSpecification>::apply(set *param_1)

{
  ButtonStyleSpecification::apply
            ((ButtonStyleSpecification *)(param_1 + 8),(ButtonStyle *)&agui::Button::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<CheckBoxStyleSpecification>::apply  @ 0x102034440 =====

/* IntegratedRootStyle<CheckBoxStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<CheckBoxStyleSpecification>::apply(set *param_1)

{
  CheckBoxStyleSpecification::apply
            ((CheckBoxStyleSpecification *)(param_1 + 8),
             (CheckBoxStyle *)&agui::CheckBox::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<DropDownStyleSpecification>::apply  @ 0x1020347ac =====

/* IntegratedRootStyle<DropDownStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<DropDownStyleSpecification>::apply(set *param_1)

{
  DropDownStyleSpecification::apply
            ((DropDownStyleSpecification *)(param_1 + 8),
             (DropDownStyle *)&agui::DropDown::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<DoubleSliderStyleSpecification>::apply  @ 0x102034c6c =====

/* IntegratedRootStyle<DoubleSliderStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<DoubleSliderStyleSpecification>::apply(set *param_1)

{
  SliderStyleSpecification::apply
            ((SliderStyleSpecification *)(param_1 + 8),
             (SliderStyle *)&agui::DoubleSlider::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<FlowStyleSpecification>::apply  @ 0x102035038 =====

/* IntegratedRootStyle<FlowStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<FlowStyleSpecification>::apply(set *param_1)

{
  StyleSpecification::apply
            ((StyleSpecification *)(param_1 + 8),(Style *)&agui::Flow::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  if (param_1[0xc0] != (set)0x0) {
    DAT_1033513a8 = *(undefined4 *)(param_1 + 0xbc);
    DAT_1033513ac = 1;
  }
  if (param_1[200] != (set)0x0) {
    DAT_1033513b0 = GuiConstants::getScaled<int>(*(int *)(param_1 + 0xc4));
    DAT_1033513b4 = 1;
  }
  if (param_1[0xd0] != (set)0x0) {
    DAT_1033513b8 = GuiConstants::getScaled<int>(*(int *)(param_1 + 0xcc));
    DAT_1033513bc = 1;
  }
  return;
}



// ===== IntegratedRootStyle<FrameStyleSpecification>::apply  @ 0x1020354d8 =====

/* IntegratedRootStyle<FrameStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<FrameStyleSpecification>::apply(set *param_1)

{
  FrameStyleSpecification::apply
            ((FrameStyleSpecification *)(param_1 + 8),(FrameStyle *)&agui::Frame::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<GraphStyleSpecification>::apply  @ 0x1020358a4 =====

/* IntegratedRootStyle<GraphStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<GraphStyleSpecification>::apply(set *param_1)

{
  GraphStyleSpecification::apply
            ((GraphStyleSpecification *)(param_1 + 8),(GraphStyle *)&agui::Graph::defaultStyle);
  return;
}



// ===== IntegratedRootStyle<LabelStyleSpecification>::apply  @ 0x102035c6c =====

/* IntegratedRootStyle<LabelStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<LabelStyleSpecification>::apply(set *param_1)

{
  LabelStyleSpecification::apply
            ((LabelStyleSpecification *)(param_1 + 8),(LabelStyle *)&agui::Label::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<ListBoxStyleSpecification>::apply  @ 0x1020360c8 =====

/* IntegratedRootStyle<ListBoxStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<ListBoxStyleSpecification>::apply(set *param_1)

{
  ListBoxStyleSpecification::apply
            ((ListBoxStyleSpecification *)(param_1 + 8),(ListBoxStyle *)&agui::ListBox::defaultStyle
             ,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<ProgressBarStyleSpecification>::apply  @ 0x1020364f0 =====

/* IntegratedRootStyle<ProgressBarStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<ProgressBarStyleSpecification>::apply(set *param_1)

{
  ProgressBarStyleSpecification::apply
            ((ProgressBarStyleSpecification *)(param_1 + 8),
             (ProgressBarStyle *)&agui::ProgressBar::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<RadioButtonStyleSpecification>::apply  @ 0x1020367f0 =====

/* IntegratedRootStyle<RadioButtonStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<RadioButtonStyleSpecification>::apply(set *param_1)

{
  RadioButtonStyleSpecification::apply
            ((RadioButtonStyleSpecification *)(param_1 + 8),
             (RadioButtonStyle *)&agui::RadioButton::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<HorizontalScrollBarStyleSpecification>::apply  @ 0x102036d60 =====

/* IntegratedRootStyle<HorizontalScrollBarStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<HorizontalScrollBarStyleSpecification>::apply(set *param_1)

{
  ScrollBarStyleSpecification::apply
            ((ScrollBarStyleSpecification *)(param_1 + 8),
             (ScrollBarStyle *)&agui::HorizontalPolicy::defaultStyle);
  return;
}



// ===== IntegratedRootStyle<VerticalScrollBarStyleSpecification>::apply  @ 0x102037210 =====

/* IntegratedRootStyle<VerticalScrollBarStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<VerticalScrollBarStyleSpecification>::apply(set *param_1)

{
  ScrollBarStyleSpecification::apply
            ((ScrollBarStyleSpecification *)(param_1 + 8),
             (ScrollBarStyle *)&agui::VerticalPolicy::defaultStyle);
  return;
}



// ===== IntegratedRootStyle<SliderStyleSpecification>::apply  @ 0x1020375e0 =====

/* IntegratedRootStyle<SliderStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<SliderStyleSpecification>::apply(set *param_1)

{
  SliderStyleSpecification::apply
            ((SliderStyleSpecification *)(param_1 + 8),(SliderStyle *)&agui::Slider::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<TabStyleSpecification>::apply  @ 0x1020379b0 =====

/* IntegratedRootStyle<TabStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<TabStyleSpecification>::apply(set *param_1)

{
  TabStyleSpecification::apply
            ((TabStyleSpecification *)(param_1 + 8),(TabStyle *)&agui::Tab::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<TableStyleSpecification>::apply  @ 0x102037d80 =====

/* IntegratedRootStyle<TableStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<TableStyleSpecification>::apply(set *param_1)

{
  TableStyleSpecification::apply
            ((TableStyleSpecification *)(param_1 + 8),(TableStyle *)&agui::Table::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<TextBoxStyleSpecification>::apply  @ 0x10203819c =====

/* IntegratedRootStyle<TextBoxStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<TextBoxStyleSpecification>::apply(set *param_1)

{
  TextBoxStyleSpecification::apply
            ((TextBoxStyleSpecification *)(param_1 + 8),(TextBoxStyle *)&agui::TextBox::defaultStyle
             ,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<ScrollPaneStyleSpecification>::apply  @ 0x10203856c =====

/* IntegratedRootStyle<ScrollPaneStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<ScrollPaneStyleSpecification>::apply(set *param_1)

{
  ScrollPaneStyleSpecification::apply
            ((ScrollPaneStyleSpecification *)(param_1 + 8),
             (ScrollPaneStyle *)&agui::ScrollPane::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<ImageStyleSpecification>::apply  @ 0x102038874 =====

/* IntegratedRootStyle<ImageStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<ImageStyleSpecification>::apply(set *param_1)

{
  ImageStyleSpecification::apply
            ((ImageStyleSpecification *)(param_1 + 8),(ImageStyle *)&agui::ImageWidget::defaultStyle
             ,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<ActivityBarStyleSpecification>::apply  @ 0x102038d30 =====

/* IntegratedRootStyle<ActivityBarStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<ActivityBarStyleSpecification>::apply(set *param_1)

{
  ActivityBarStyleSpecification::apply
            ((ActivityBarStyleSpecification *)(param_1 + 8),
             (ActivityBarStyle *)&agui::ActivityBar::defaultStyle);
  return;
}



// ===== IntegratedRootStyle<CameraStyleSpecification>::apply  @ 0x102039034 =====

/* IntegratedRootStyle<CameraStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<CameraStyleSpecification>::apply(set *param_1)

{
  EmptyWidgetStyleSpecification::apply
            ((EmptyWidgetStyleSpecification *)(param_1 + 8),
             (EmptyWidgetStyle *)&CameraBase::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<MinimapStyleSpecification>::apply  @ 0x1020393f4 =====

/* IntegratedRootStyle<MinimapStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<MinimapStyleSpecification>::apply(set *param_1)

{
  EmptyWidgetStyleSpecification::apply
            ((EmptyWidgetStyleSpecification *)(param_1 + 8),
             (EmptyWidgetStyle *)&MinimapBase::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<HorizontalFlowStyleSpecification>::apply  @ 0x102039878 =====

/* IntegratedRootStyle<HorizontalFlowStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<HorizontalFlowStyleSpecification>::apply(set *param_1)

{
  StyleSpecification::apply
            ((StyleSpecification *)(param_1 + 8),(Style *)&agui::HorizontalFlow::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  if (param_1[0xc0] != (set)0x0) {
    DAT_1033515c8 = GuiConstants::getScaled<int>(*(int *)(param_1 + 0xbc));
    DAT_1033515cc = 1;
  }
  return;
}



// ===== IntegratedRootStyle<VerticalFlowStyleSpecification>::apply  @ 0x102039c80 =====

/* IntegratedRootStyle<VerticalFlowStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<VerticalFlowStyleSpecification>::apply(set *param_1)

{
  StyleSpecification::apply
            ((StyleSpecification *)(param_1 + 8),(Style *)&agui::VerticalFlow::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  if (param_1[0xc0] != (set)0x0) {
    DAT_1033523e8 = GuiConstants::getScaled<int>(*(int *)(param_1 + 0xbc));
    DAT_1033523ec = 1;
  }
  return;
}



// ===== IntegratedRootStyle<SwitchStyleSpecification>::apply  @ 0x10203a11c =====

/* IntegratedRootStyle<SwitchStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<SwitchStyleSpecification>::apply(set *param_1)

{
  SwitchStyleSpecification::apply
            ((SwitchStyleSpecification *)(param_1 + 8),(SwitchStyle *)&agui::Switch::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<TabbedPaneStyleSpecification>::apply  @ 0x10203a544 =====

/* IntegratedRootStyle<TabbedPaneStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<TabbedPaneStyleSpecification>::apply(set *param_1)

{
  TabbedPaneStyleSpecification::apply
            ((TabbedPaneStyleSpecification *)(param_1 + 8),
             (TabbedPaneStyle *)&agui::TabbedPane::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<EmptyWidgetStyleSpecification>::apply  @ 0x10203a84c =====

/* IntegratedRootStyle<EmptyWidgetStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<EmptyWidgetStyleSpecification>::apply(set *param_1)

{
  EmptyWidgetStyleSpecification::apply
            ((EmptyWidgetStyleSpecification *)(param_1 + 8),
             (EmptyWidgetStyle *)&agui::EmptyWidget::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<LineStyleSpecification>::apply  @ 0x10203acfc =====

/* IntegratedRootStyle<LineStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<LineStyleSpecification>::apply(set *param_1)

{
  int iVar1;
  long lVar2;
  
  StyleSpecification::apply
            ((StyleSpecification *)(param_1 + 8),(Style *)&agui::Line::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  lVar2 = *(long *)(param_1 + 0xc0);
  if (lVar2 != 0) {
    iVar1 = GuiConstants::getScaled<int>(*(int *)(lVar2 + 4));
    *(int *)(*(long *)(lVar2 + 0x968) + 4) = iVar1;
    agui::LineStyle::setBorder
              ((LineStyle *)&agui::Line::defaultStyle,
               *(BorderImageSet **)(*(long *)(param_1 + 0xc0) + 0x968));
    return;
  }
  return;
}



// ===== IntegratedRootStyle<TechnologySlotStyleSpecification>::apply  @ 0x10203b11c =====

/* IntegratedRootStyle<TechnologySlotStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<TechnologySlotStyleSpecification>::apply(set *param_1)

{
  TechnologySlotStyleSpecification::apply
            ((TechnologySlotStyleSpecification *)(param_1 + 8),
             (TechnologySlotStyle *)&TechnologySlotStyleSpecification::defaultStyle,
             (OptionalFundamentalBase *)0x0);
  return;
}



// ===== IntegratedRootStyle<GlowStyleSpecification>::apply  @ 0x10203b424 =====

/* IntegratedRootStyle<GlowStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<GlowStyleSpecification>::apply(set *param_1)

{
  bool bVar1;
  ElementImageSet *this;
  void *pvVar2;
  ElementImageSet *pEVar3;
  
  StyleSpecification::apply
            ((StyleSpecification *)(param_1 + 8),(Style *)&GlowStyle::rootStyle,
             (OptionalFundamentalBase *)0x0);
  if (*(undefined8 **)(param_1 + 0xc0) != (undefined8 *)0x0) {
    pEVar3 = (ElementImageSet *)**(undefined8 **)(param_1 + 0xc0);
    this = operator_new(600);
    agui::ElementImageSet::ElementImageSet(this,pEVar3);
    pEVar3 = DAT_1032c9cc0;
    bVar1 = DAT_1032c9cc0 != (ElementImageSet *)0x0;
    DAT_1032c9cc0 = this;
    if (bVar1) {
      pvVar2 = (void *)agui::ElementImageSet::~ElementImageSet(pEVar3);
      operator_delete(pvVar2);
      return;
    }
  }
  return;
}



// ===== IntegratedRootStyle<SpeechBubbleStyleSpecification>::apply  @ 0x10203b91c =====

/* IntegratedRootStyle<SpeechBubbleStyleSpecification>::apply(std::set<agui::Style const*,
   std::less<agui::Style const*>, std::allocator<agui::Style const*> >&) */

void IntegratedRootStyle<SpeechBubbleStyleSpecification>::apply(set *param_1)

{
  SpeechBubbleStyleSpecification::apply
            ((SpeechBubbleStyleSpecification *)(param_1 + 8),
             (SpeechBubbleStyle *)&SpeechBubbleGui::defaultStyle,(OptionalFundamentalBase *)0x0);
  return;
}



