#include <stdlib.h>
#include <cstdint>

#define CONFIG_MSIZE 0x8000000
static uint32_t pmem[CONFIG_MSIZE] = {
 0x00100093, //addi x1,x0,1;
 0x00508093,//addi x1,x0,5;0x00508093 addi x1,x1,5
 0x00200093,//addi x1,x0,2;
 0x02500093,//addi x1,x0,25;
 0x01000093,//addi x1,x0,10;
 0x00100073,//ebreak
};
static int cmd_help(char *args);
static int cmd_si(char *args);
static int cmd_info(char *args) ;
static int cmd_x(char *args);
static int cmd_c(char *args);
void sdb_npc();
static struct {
    const char *name;
    const char *description;
    int (*handler) (char *);
  } cmd_table [] = {
    { "help", "Display information about all supported commands", cmd_help },
    { "c", "continue", cmd_c },
    { "si", "si or si:N:execute N instructions step by step then pause,when N is not provided,the default is 1", cmd_si },
    { "info", "info r/w:print the information of registers or watchpoints", cmd_info },
    { "x", "x number start_addr:examine memory and print the value",cmd_x }
};
#define log_write(...) \
  do {\
    extern FILE* log_fp; \
    if (log_fp != NULL) { \
      fprintf(log_fp, __VA_ARGS__); \
      fflush(log_fp); \
    } \
  } while (0)

