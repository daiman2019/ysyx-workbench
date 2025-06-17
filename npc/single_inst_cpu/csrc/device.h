#include "common.h"
#include <assert.h>
#include "diffTest.h"

#define CONFIG_DEVICE
#ifdef CONFIG_DEVICE
#define CONFIG_RTC_MMIO 0xa0000048
#define CONFIG_SERIAL_MMIO 0xa00003f8
#define CONFIG_VGA_CTL_MMIO 0xa0000100
#define CONFIG_I8042_DATA_MMIO 0xa0000060
#define CONFIG_FB_ADDR 0xa1000000
#endif
typedef void(*io_callback_t)(uint32_t, int, bool);
uint8_t* new_space(int size);

typedef struct {
  const char *name;
  uint32_t low;
  uint32_t high;
  void *space;
  io_callback_t callback;
}IOMap;

static inline bool map_inside(IOMap *map, uint32_t addr) {
  return (addr >= map->low && addr <= map->high);
}

static inline int find_mapid_by_addr(IOMap *maps, int size, uint32_t addr) {
  int i;
  for (i = 0; i < size; i ++) {
    if (map_inside(maps + i, addr)) {
      difftest_skip_ref();
      return i;
    }
  }
  return -1;
}

void add_mmio_map(const char *name, uint32_t addr,void *space, uint32_t len, io_callback_t callback);

uint32_t map_read(uint32_t addr, int len, IOMap *map);
void map_write(uint32_t addr, int len, uint32_t data, IOMap *map);

uint32_t mmio_read(uint32_t addr, int len);
void mmio_write(uint32_t addr, int len, uint32_t data);

void init_device();
void sdl_clear_event_queue();
void device_update();
