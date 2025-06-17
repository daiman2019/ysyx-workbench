#include <am.h>
#include "../riscv.h"
#define KEYDOWN_MASK 0x8000
#define KBD_ADDR     0xa0000060
void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd)
{
  uint32_t k = inl(KBD_ADDR);
  kbd->keydown = (k & KEYDOWN_MASK ? true : false);
  kbd->keycode = k & ~KEYDOWN_MASK;
}