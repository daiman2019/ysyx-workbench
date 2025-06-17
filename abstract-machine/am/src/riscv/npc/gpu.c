#include <am.h>
#include "../riscv.h"

#define VGACTL_ADDR     0xa0000100
#define SYNC_ADDR      (VGACTL_ADDR + 4)
#define FB_ADDR         0xa1000000

void __am_gpu_init() {
  // int i;
  // int w = io_read(AM_GPU_CONFIG).width;
  // int h = io_read(AM_GPU_CONFIG).height;
  // uint32_t *fb = (uint32_t*)(uintptr_t)FB_ADDR;
  // for(i=0;i<w*h;i++)
  //   fb[i]=i;
  // outl(SYNC_ADDR,1);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  uint32_t screen_size = inl(VGACTL_ADDR);
  uint32_t width = screen_size>>16;
  uint32_t height = screen_size&0xffff;
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = width, .height = height,
    .vmemsz = 0
  };
}
void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  int x = ctl->x;
  int y = ctl->y;
  int w = ctl->w;
  int h = ctl->h;
  uint32_t screen_w = inl(VGACTL_ADDR)>>16;
  uint32_t* fb = (uint32_t*)(uintptr_t)FB_ADDR;
  uint32_t* pixels = ctl->pixels;
  for(int i=y;i<y+h;i++)
  {
    for(int j=x;j<x+w;j++)
    {
      fb[screen_w*i+j] = pixels[(i-y)*w+(j-x)];
    }
  }
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
