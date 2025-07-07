#include "sdb.h"
#include "memory.h"
#include "device.h"
#include "svdpi.h"
#include "Vtop__Dpi.h"

static uint8_t* pmem = NULL;
uint8_t* guest_to_host(uint32_t paddr) {return pmem + paddr- MEM_START;}
uint32_t host_to_guest(uint8_t* vaddr) {return vaddr - pmem + MEM_START;}
void init_mem()
{
    log_write("initializing pmem\n");
    pmem = (uint8_t*)malloc(MEM_END-MEM_START+1);
    assert(pmem);
    return;
}

bool in_pmem(uint32_t addr)
{
    return (addr>=MEM_START)&&(addr<=MEM_END);
}
extern "C" {
int pmem_read(int raddr,int len,int flag)
{
//log_write("mtrace flag = %d,",flag);
    if(in_pmem(raddr))
    {
        uint32_t pmem_ret = host_read(guest_to_host(raddr),len);
#if NPC_MTRACE
        log_write("mtrace in mem read addr = 0x%08x,len=%d,data=0x%08x\n",raddr,len,pmem_ret);
#endif
        return pmem_ret;
    }
    else
    {
        uint32_t mmio_ret = mmio_read(raddr,len);
#if NPC_MTRACE
        log_write("mtrace in mmio_read addr = 0x%08x,len=%d,data=0x%08x\n",raddr,len,mmio_ret);
#endif
        return mmio_ret;
    }
}
}

extern "C" {
void pmem_write(int waddr,int wdata,int len)
{
#if NPC_MTRACE
    log_write("mtrace:mem write waddr = 0x%08x,wdata=0x%08x,len=%d\n",waddr,wdata,len);
#endif
    if(in_pmem(waddr))
    {
        host_write(guest_to_host(waddr),len,wdata);
    }
    else
    {
        mmio_write(waddr,len,wdata);
    }
#if NPC_MTRACE
    uint32_t write_data = pmem_read(waddr,len,4);
    log_write("mtrace:after pmem write read data is %08x\n",write_data);
#endif
    
}
}



// void pmem_write(uint32_t waddr,int wdata,char wmask)
// {
//     uint32_t offset,index,paddr,ret,rowdata,new_data;
//     uint8_t byte;
// #if NPC_MTRACE
//     log_write("mtrace:mem write waddr = 0x%08x,wdata=0x%08x,wmask=%d\n",waddr,wdata,wmask);
// #endif
    
//     paddr = (waddr-0x80000000);
//     offset = paddr%sizeof(uint32_t);
//     index = paddr/sizeof(uint32_t);
//     rowdata = pmem[index];
//     new_data = rowdata;
// #if NPC_MTRACE
//     log_write("mtrace:mem write paddr = 0x%08x,rowdata=0x%08x\n",paddr,rowdata);
// #endif
//     uint32_t final_mask = 0;
//     for(int i=0;i<4;i++)
//     {
//         if(wmask &(1<<i))
//         {
//             byte = (wdata>>(i*8))&0xff;
//             new_data &= ~(0xff<<((offset+i)*8));
//             new_data |= byte<<((offset+i)*8);
//         }
//     }
//     pmem[index] = new_data;
// #if NPC_MTRACE
//     log_write("mtrace:write_data=0x%08x\n",new_data);
// #endif
// }