#include "verilated.h"
#include <nvboard.h>
#include <Vtop.h>
#include "verilated_vcd_c.h" //vcd waveform trace
#include "svdpi.h"
#include "Vtop__Dpi.h"

struct CPU_state{
    uint32_t gpr[32];
    uint32_t pc;
};
extern CPU_state npc_cpu_reg;


typedef struct{
    int state;
    uint32_t halt_pc;
    uint32_t halt_ret;
}NPC_state;

extern NPC_state npc_state;
void execute_step(uint32_t n);