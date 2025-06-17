#include "sdb.h"
#include <readline/readline.h>
#include <readline/history.h>
#include "verilator_sim.h"
#include "device.h"
#include "memory.h"

int reg_lists[regs_number];
const char *regs[] = {
    "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};
static char* rl_gets() {
    static char *line_read = NULL;
    if (line_read) {
      free(line_read);
      line_read = NULL;
    }
    line_read = readline("(npc) ");
    if (line_read && *line_read) {
      add_history(line_read);
    }
    return line_read;
}

static int cmd_help(char *args) {
    /* extract the first argument */
    char *arg = strtok(NULL, " ");
    int i;
  
    if (arg == NULL) {
      /* no argument given */
      for (i = 0; i < NR_CMD; i ++) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
      }
    }
    else {
      for (i = 0; i < NR_CMD; i ++) {
        if (strcmp(arg, cmd_table[i].name) == 0) {
          printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
          return 0;
        }
      }
      printf("Unknown command '%s'\n", arg);
    }
    return 0;
}
//execute step by step
void reg_values(int i,int reg_v)
{
    reg_lists[i]=reg_v;
    //printf("idx=%d,val=0x%08x\n",i,reg_v);
}
static int cmd_si(char *args) {
    if (args == NULL) 
    {   execute_step(1);
    }
    else
    {
      execute_step(atoi(args));
    }    
    return 0;
}
static int cmd_c(char *args) {
    execute_step(-1);
    return 0;
}

void reg_display()
{
    for(int i=0;i<regs_number;i++)
    {
      printf("reg %s is 0x%08x\n",regs[i],reg_lists[i]);
    }
}
//print registers
static int cmd_info(char *args) {
    printf("info: %s\n", args);
    if (args == NULL) {
      return -1;
    }
    if(strcmp(args, "r") == 0) {
        reg_display();
    }
    else {
        printf("Unknown command '%s'\n", args);
    }
    return 0;
}
static int cmd_q(char *args) {
  printf("q: %s\n", args);
  npc_state.state = NPC_QUIT;
  return -1;
}
//scan memory
static int cmd_x(char *args) {
    printf("x: %s\n", args);
    if (args == NULL) {
      return -1;
    }
    char *value_numbers = strtok(args, " ");
    char *expr = strtok(NULL, " ");
    if (value_numbers == NULL || expr == NULL) {
      return -1;
    }
    int n_bytes = atoi(value_numbers);
    uint32_t start_addr = (uint32_t)strtoul(expr,NULL,16);//0xdata->addr
    // if(start_addr<0x80000000)
    // {
    //     printf("wrong start addr\n");
    //     return 0;
    // }
    for(uint32_t addr = start_addr; addr < start_addr+n_bytes; addr = addr +4) {
      log_write("addr is 0x%08x , value is 0x%08x\n", addr,pmem_read(addr,4));
    }
    return 0;
}
  
void sdb_npc() {
  for (char *str; (str = rl_gets()) != NULL; ) {
  
    char *str_end = str + strlen(str);
    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }
#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif
    int i;
    for (i = 0; i < NR_CMD; i ++) 
    {
      if (strcmp(cmd, cmd_table[i].name) == 0) 
      {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}


