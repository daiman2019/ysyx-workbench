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

#include "common.h"
#include "device.h"
#include "verilator_sim.h"
#include <SDL2/SDL.h>

NPC_state npc_state;

void init_map();
void init_serial();
void init_timer();
void init_vga();
void init_i8042();

void send_key(uint8_t, bool);
void vga_update_screen();

void device_update() 
{
  static uint64_t last = 0;
  uint64_t now = get_time();
  if (now - last < 1000000 / 60) {
    return;
  }
  last = now;
#ifdef CONFIG_VGA_CTL_MMIO
   vga_update_screen();
#endif
  SDL_Event event;
  while (SDL_PollEvent(&event)) {
    switch (event.type) {
      case SDL_QUIT:
        npc_state.state = NPC_QUIT;
        break;
      // If a key was pressed
      case SDL_KEYDOWN:
      case SDL_KEYUP: {
#ifdef CONFIG_I8042_DATA_MMIO
        uint8_t k = event.key.keysym.scancode;
        bool is_keydown = (event.key.type == SDL_KEYDOWN);
        send_key(k, is_keydown);
        break;
#else
        break;
#endif
      }
      default: break;
    }
  }
}

void sdl_clear_event_queue() {
  SDL_Event event;
  while (SDL_PollEvent(&event));
}

void init_device() 
{
  init_map();
#ifdef CONFIG_SERIAL_MMIO
    init_serial();
#endif
#ifdef CONFIG_RTC_MMIO
    init_timer();
#endif
#ifdef CONFIG_VGA_CTL_MMIO
    init_vga();
#endif
#ifdef CONFIG_I8042_DATA_MMIO
    init_i8042();
#endif
    log_write("device initialize success!\n");
    return;
}
