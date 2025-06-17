#include "common.h"
#define NR_CMD 6
#define regs_number 32

static int cmd_help(char *args);
static int cmd_si(char *args);
static int cmd_info(char *args) ;
static int cmd_x(char *args);
static int cmd_c(char *args);
static int cmd_q(char *args);
void sdb_npc();


extern int reg_lists[regs_number];
static struct {
    const char *name;
    const char *description;
    int (*handler) (char *);
  } cmd_table [] = {
    { "help", "Display information about all supported commands", cmd_help },
    { "c", "continue", cmd_c },
    { "si", "si or si:N:execute N instructions step by step then pause,when N is not provided,the default is 1", cmd_si },
    { "info", "info r/w:print the information of registers or watchpoints", cmd_info },
    { "x", "x number start_addr:examine memory and print the value",cmd_x },
    { "q", "quit sdb",cmd_q }
};


