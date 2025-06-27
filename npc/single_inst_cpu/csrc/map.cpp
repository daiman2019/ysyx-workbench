#include "device.h"
#include "memory.h"

#define IO_SPACE_MAX (32 * 1024 * 1024)

#define PAGE_SHIFT        12
#define PAGE_SIZE         (1ul << PAGE_SHIFT)
#define PAGE_MASK         (PAGE_SIZE - 1)

static uint8_t *io_space = NULL;
static uint8_t *p_space = NULL;

uint8_t* new_space(int size) 
{
  uint8_t *p = p_space;
  // page aligned;
  size = (size + (PAGE_SIZE - 1)) & ~PAGE_MASK;
  p_space += size;
  assert(p_space - io_space < IO_SPACE_MAX);
  return p;
}

static bool check_bound(IOMap *map, uint32_t addr) 
{
  if (map == NULL) 
  {
#if NPC_MTRACE
    log_write("address (0x%08x) is out of bound\n", addr);
#endif
    return false;
  } 
  else 
  {
    if(addr <= map->high && addr >= map->low)
    {
      return true;
    }
    else
    {
#if NPC_MTRACE
      log_write("address (0x%08x) is out of bound {%s} [0x%08x, 0x%08x]\n",addr, map->name, map->low, map->high);
#endif
      return false;
    }
  }
}

static void invoke_callback(io_callback_t c, uint32_t offset, int len, bool is_write) {
  if (c != NULL) { c(offset, len, is_write); }
}

void init_map() {
  io_space = (uint8_t*)malloc(IO_SPACE_MAX);
  assert(io_space);
  p_space = io_space;
}

uint32_t map_read(uint32_t addr, int len, IOMap *map) 
{
  assert(len >= 1 && len <= 8);
  if(check_bound(map, addr))
  {
    uint32_t offset = addr - map->low;
    invoke_callback(map->callback, offset, len, false); // prepare data to read
    uint32_t ret = host_read(map->space + offset, len);
    return ret;
  }
  return 0;
}

void map_write(uint32_t addr, int len, uint32_t data, IOMap *map) 
{
  assert(len >= 1 && len <= 8);
  if(check_bound(map, addr))
  {
    uint32_t offset = addr - map->low;
    host_write(map->space + offset, len, data);
    invoke_callback(map->callback, offset, len, true);
  }
}
