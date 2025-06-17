#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <cstring>
#include <cstdint>

//#define NPC_ITRACE 
//#define NPC_MTRACE 
//#define NPC_FTRACE 
//#define vcd_on 

#define NPC_RUNNING 0
#define NPC_STOP    1
#define NPC_END     2
#define NPC_ABORT   3
#define NPC_QUIT    4

uint64_t get_time();

#define log_write(...) \
  do {\
    extern FILE* log_fp; \
    if (log_fp != NULL) { \
      fprintf(log_fp, __VA_ARGS__); \
      fflush(log_fp); \
    } \
  } while (0)


