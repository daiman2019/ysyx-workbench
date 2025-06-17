#include "trace.h"
char logbuf[128];
void npc_trace(uint32_t pc,uint32_t instruction)
{
  char *p = logbuf;
  p += snprintf(p, sizeof(logbuf), "0x%08x:", pc);
  int i;
  uint8_t *inst = (uint8_t *)&instruction;
  for (i = 3; i >= 0; i --) {
    p += snprintf(p, 4, " %02x", inst[i]);
  }
//   void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
//   disassemble(p, logbuf + sizeof(logbuf) - p,pc, (uint8_t *)&instruction, 4);
  log_write("itrace:%s\n", logbuf);
}