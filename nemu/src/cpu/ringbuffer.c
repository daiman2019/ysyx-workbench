#include <common.h>
#include <debug.h>
#include <utils.h>

#define RINGBUF_LEN 20

typedef struct ringbuf{
    vaddr_t pc[RINGBUF_LEN];
    uint32_t inst[RINGBUF_LEN];
    uint32_t writen_len;
    uint32_t write_point;
}ringbuf;
ringbuf ring_trace;
void ringbuf_init()
{
    ring_trace.write_point = 0;
    ring_trace.writen_len = 0;
}

void ringbuf_write(vaddr_t pc,uint32_t inst)
{
    ring_trace.pc[ring_trace.write_point] = pc;
    ring_trace.inst[ring_trace.write_point] = inst;
    ring_trace.write_point = (ring_trace.write_point+1)%RINGBUF_LEN;
    ring_trace.writen_len++;
    ring_trace.writen_len = ring_trace.writen_len>RINGBUF_LEN?RINGBUF_LEN:(ring_trace.writen_len);
}

void ringbuf_show()
{
  size_t start;
  char buf[256];
  char* p;
 // log_write("writen_len=%d,write_point=%d\n", ring_trace.writen_len,ring_trace.write_point);
  for(start = 0;start<ring_trace.writen_len;start++)
  {
    p = buf;
    if(start == (ring_trace.write_point+RINGBUF_LEN-1)%RINGBUF_LEN)
        p += sprintf(p, "%s", "--->");
    else
        p += sprintf(p, "%s", "    ");
    //pc
    p += snprintf(p, buf + sizeof(buf) - p, FMT_WORD ":", ring_trace.pc[start]);
    //inst
    p += snprintf(p, buf + sizeof(buf) - p,"%08x", ring_trace.inst[start]);
    memset(p, ' ', 4);
    p += 4;
    //asm
    //log_write("in ringbuf_show pc=%08x,ilen = %d,index=%ld\n", ring_trace.pc[start],4,start);
    void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
    //log_write("index=%ld,size=%ld,pc=%08x,inst=%08x\n", start,buf + sizeof(buf) - p,ring_trace.pc[start],ring_trace.inst[start]);
    disassemble(p, buf + sizeof(buf) - p,ring_trace.pc[start], (uint8_t *)&ring_trace.inst[start], 4);
    log_write("%s\n", buf);
    
  }
}
