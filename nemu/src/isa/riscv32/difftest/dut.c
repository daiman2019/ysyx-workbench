/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/difftest.h>
#include "../local-include/reg.h"

bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  //check pc
  if(ref_r->pc != cpu.pc) {
    Log("PC is different after executing instruction at pc = " FMT_WORD", right = " FMT_WORD ",wrong = " FMT_WORD,pc, ref_r->pc,cpu.pc);
    return false;
  }
  //check gpr
  for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
    if (!difftest_check_reg(reg_name(i), pc, ref_r->gpr[i], gpr(i))) {
      return false;
    }
  }
  //check crs 
  if(check_crs(ref_r, pc)==false)
  {
    return false;
  }
  return true;
}

void isa_difftest_attach() {
}

bool check_crs(CPU_state *ref_r, vaddr_t pc)
{
  if (ref_r->CRSs.mcause!=cpu.CRSs.mcause)
  {
    Log("mcause is different after executing instruction at pc = " FMT_WORD", right = " FMT_WORD ",wrong = " FMT_WORD,pc, ref_r->CRSs.mcause,cpu.CRSs.mcause);
    return false;
  }
  if (ref_r->CRSs.mtvec!=cpu.CRSs.mtvec)
  {
    Log("mtvec is different after executing instruction at pc = " FMT_WORD", right = " FMT_WORD ",wrong = " FMT_WORD,pc, ref_r->CRSs.mtvec,cpu.CRSs.mtvec);
    return false;
  }
  if (ref_r->CRSs.mstatus!=cpu.CRSs.mstatus)
  {
    Log("mstatus is different after executing instruction at pc = " FMT_WORD", right = " FMT_WORD ",wrong = " FMT_WORD,pc, ref_r->CRSs.mstatus,cpu.CRSs.mstatus);
    return false;
  }
  if (ref_r->CRSs.mepc!=cpu.CRSs.mepc)
  {
    Log("mepc is different after executing instruction at pc = " FMT_WORD", right = " FMT_WORD ",wrong = " FMT_WORD,pc, ref_r->CRSs.mepc,cpu.CRSs.mepc);
    return false;
  }
  return true;
}
