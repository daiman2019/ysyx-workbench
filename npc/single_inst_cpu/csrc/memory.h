#include "common.h"
#define MEM_START 0x80000000
#define MEM_END   0X8fffffff

void init_mem();
bool in_pmem(uint32_t addr);
extern "C"{int pmem_read(int raddr,int len,int flag);}
extern "C"{void pmem_write(int waddr,int wdata,int len);}
uint8_t* guest_to_host(uint32_t paddr);
uint32_t host_to_guest(uint8_t* vaddr);
static inline uint32_t host_read(void* addr,int len)
{
    switch(len)
    {
        case 1:return *(uint8_t *)addr;
        case 2:return *(uint16_t *)addr;
        case 4:return *(uint32_t *)addr;
        default:printf("host_read:wrong read len\n");assert(0);
    }
}

static inline void host_write(void* addr,int len,uint32_t data)
{
    switch(len)
    {
        case 1:*(uint8_t *)addr = data;return;
        case 2:*(uint16_t *)addr = data;return;
        case 4:*(uint32_t *)addr = data;return;
        default:printf("host_write:wrong write len\n");assert(0);
    }
}

