#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>

static Context* (*user_handler)(Event, Context*) = NULL;

Context* __am_irq_handle(Context *c) {
  if (user_handler) {
    Event ev = {0};
    //printf("in npc/cte mcause is:%d\n",c->mcause);
    switch (c->mcause) {
      case 0xb:
      {ev.event = EVENT_YIELD;c->mepc += 4;}break;
      default: ev.event = EVENT_ERROR; break;
    }
    //printf("in npc/cte event is:%d\n",ev.event);
    c = user_handler(ev, c);
    assert(c != NULL);
  }

  return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context*(*handler)(Event, Context*)) {
  // initialize exception entry
  asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

  // register event handler
  user_handler = handler;

  return true;
}

Context *kcontext(Area kstack, void (*entry)(void *), void *arg) 
{
  //return NULL;
  Context *c = (Context*)kstack.end-1;
  c->mstatus = 0x1800;
  c->mepc = (uintptr_t)entry;
  c->gpr[10] = (uintptr_t)arg;//a0
  //c->pdir = NULL;
  return c;
}

void yield() {
#ifdef __riscv_e
  asm volatile("li a5, 0xb; ecall");//-1
#else
  asm volatile("li a7, 0xb; ecall");//-1
#endif
}

bool ienabled() {
  return false;
}

void iset(bool enable) {
}
