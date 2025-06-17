//#include <cstddef>
#include <dlfcn.h>
#include "diffTest.h"
#include "verilator_sim.h"
#include "memory.h"


void (*ref_difftest_memcpy)(uint32_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

static bool is_skip_ref = false;
static int skip_dut_nr_inst = 0;
CPU_state ref_r;
// this is used to let ref skip instructions which
// can not produce consistent behavior with NEMU
void difftest_skip_ref() {
  is_skip_ref = true;
  // If such an instruction is one of the instruction packing in QEMU
  // (see below), we end the process of catching up with QEMU's pc to
  // keep the consistent behavior in our best.
  // Note that this is still not perfect: if the packed instructions
  // already write some memory, and the incoming instruction in NEMU
  // will load that memory, we will encounter false negative. But such
  // situation is infrequent.
  skip_dut_nr_inst = 0;
}

void difftest_skip_dut(int nr_ref, int nr_dut) {
    skip_dut_nr_inst += nr_dut;
  
    while (nr_ref -- > 0) {
      ref_difftest_exec(1);
    }
}

void init_difftest(char *ref_so_file, long img_size, int port) {
    
    assert(ref_so_file != NULL);
  
    void *handle;
    handle = dlopen(ref_so_file, RTLD_LAZY);
    assert(handle);
  
    ref_difftest_memcpy = (void (*)(uint32_t addr, void *buf, size_t n, bool direction))dlsym(handle, "difftest_memcpy");
    assert(ref_difftest_memcpy);
  
    ref_difftest_regcpy = (void(*)(void *, bool))dlsym(handle, "difftest_regcpy");
    assert(ref_difftest_regcpy);
  
    ref_difftest_exec = (void(*)(uint64_t))dlsym(handle, "difftest_exec");
    assert(ref_difftest_exec);
  
    ref_difftest_raise_intr = (void(*)(uint64_t))dlsym(handle, "difftest_raise_intr");
    assert(ref_difftest_raise_intr);
  
    void (*ref_difftest_init)(int) = (void(*)(int))dlsym(handle, "difftest_init");
    assert(ref_difftest_init);

    ref_difftest_init(port);
    ref_r.pc = MEM_START;
    ref_difftest_memcpy(MEM_START, guest_to_host(MEM_START), img_size, DIFFTEST_TO_REF);
    npc_cpu_reg.pc = MEM_START;
    ref_difftest_regcpy(&npc_cpu_reg, DIFFTEST_TO_REF);
}


bool isa_difftest_checkregs(CPU_state *ref_r, uint32_t pc) //ref is nemu dut is npc
{
    if(ref_r->pc != npc_cpu_reg.pc) {
      log_write("DIFFTEST:PC is different after executing instruction at pc = 0x%08x, right = 0x%08x,wrong = 0x%08x\n",pc, ref_r->pc,npc_cpu_reg.pc);
      return false;
    }
    for (int i = 0; i < 32; i++) {
      if (ref_r->gpr[i]!=npc_cpu_reg.gpr[i]) {
        log_write("DIFFTEST:reg[%d] is different after executing instruction at pc = 0x%08x, right = 0x%08x,wrong = 0x%08x\n",i,pc, ref_r->gpr[i],npc_cpu_reg.gpr[i]);
        return false;
      }
    }
    return true;
}

static void checkregs(CPU_state *ref, uint32_t pc) {
  if (!isa_difftest_checkregs(ref, pc))
    //finish_sim();
    finish_flag=1;
    npc_state.state = NPC_ABORT;
}

void difftest_step(uint32_t pc, uint32_t npc) {
    if (skip_dut_nr_inst > 0) {
      ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
      if (ref_r.pc == npc) {
        skip_dut_nr_inst = 0;
        checkregs(&ref_r, npc);
        return;
      }
      skip_dut_nr_inst --;
      if (skip_dut_nr_inst == 0)
        log_write("DIFFTEST:can not catch up with ref.pc = 0x%08x at pc = 0x%08x\n", ref_r.pc, pc);
      return;
    }
  
    if (is_skip_ref) {
      // to skip the checking of an instruction, just copy the reg state to reference design
      ref_difftest_regcpy(&npc_cpu_reg, DIFFTEST_TO_REF);
      is_skip_ref = false;
      return;
    }
    ref_difftest_exec(1);
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT);
    checkregs(&ref_r, pc);
}
