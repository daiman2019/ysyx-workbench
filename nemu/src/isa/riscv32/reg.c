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
#include "local-include/reg.h"

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};
#define regs_number 32
void isa_reg_display() {
    int i=0;
    for(i=0;i<regs_number;i++)
    {
        printf("%s:hex is %08x(dec is %u)\n",reg_name(i),gpr(i),gpr(i));
    }
    printf("%s:hex is %08x(dec is %u)\n","mstatus",cpu.CRSs.mstatus,cpu.CRSs.mstatus);
    printf("%s:hex is %08x(dec is %u)\n","mtvec",cpu.CRSs.mtvec,cpu.CRSs.mtvec);
    printf("%s:hex is %08x(dec is %u)\n","mepc",cpu.CRSs.mepc,cpu.CRSs.mepc);
    printf("%s:hex is %08x(dec is %u)\n","mcause",cpu.CRSs.mcause,cpu.CRSs.mcause);
}

word_t isa_reg_str2val(const char *s, bool *success) {
  for(int i=0;i<regs_number;i++)
  {
    if(strcmp(s,reg_name(i))==0)
    {
      *success = true;
      return gpr(i);
    }
  }
  *success = false;
  return 0;
}
