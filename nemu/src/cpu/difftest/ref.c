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
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>
//DUT buf REF addr
__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if (direction == DIFFTEST_TO_REF) //RFE is NEMU,DUT is NPC
  {
    memcpy(guest_to_host(addr),buf,n);
  }
  else if (direction == DIFFTEST_TO_DUT){
      paddr_read(addr,n);
  } 
  else
    assert(0);
}

__EXPORT void difftest_regcpy(CPU_state *dut, bool direction) {
  if (direction == DIFFTEST_TO_REF) //RFE is NEMU,DUT is NPC
  {
    for(int i=0;i<32;i++)
    {
      cpu.gpr[i]=dut->gpr[i];
    }
    cpu.pc = dut->pc;
  }
  else if (direction == DIFFTEST_TO_DUT)
  {
    for(int i=0;i<32;i++)
    {
      dut->gpr[i] = cpu.gpr[i];
    }
    dut->pc = cpu.pc;
  }
  else
    assert(0);
}


__EXPORT void difftest_exec(uint64_t n) {
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {

  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
}
