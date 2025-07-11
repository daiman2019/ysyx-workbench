/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <memory/vaddr.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  return -1;
}

static int cmd_help(char *args);

static int cmd_si(char *args) {
  printf("si: %s\n", args);
  if (args == NULL) 
    cpu_exec(1);
  else
    cpu_exec(atoi(args));
  return 0;
}

static int cmd_info(char *args) {
  printf("info: %s\n", args);
  if (args == NULL) {
    return -1;
  }
  if(strcmp(args, "r") == 0) {
    isa_reg_display();
  }
  else if(strcmp(args, "w") == 0) {
    print_all_wp();
  }
  else {
    printf("Unknown command '%s'\n", args);
  }
  return 0;
}

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
  int n = atoi(value_numbers);
  uint32_t address = (uint32_t)strtoul(expr,NULL,16);//0xdata->addr
  for(int i = 0; i < n; i++) {
    printf("addr is 0x%08x , value is 0x%08x\n", address + i * 4,vaddr_read(address + i * 4, 4));
  }
  return 0;
}

static int cmd_p(char *args) {
  printf("p: %s\n", args);
  bool success;
  word_t result = 0;
  if (args == NULL) {
    return -1;
  }
  char *exprarg = strtok(args, " ");
  if (exprarg == NULL) {
    return -1;
  }
  result = expr(exprarg, &success);
  if (success) {
    printf("result = %u,%d\n",result,result);
    return 0;
  }
  return -1;
}

static int cmd_w(char *args) {
  printf("w: %s\n", args);
  if (args == NULL) {
    return -1;
  }
  char *exprarg = strtok(args, " ");
  if (exprarg == NULL) {
    return -1;
  }
  set_wp(exprarg);
  return 0;
}
static int cmd_d(char *args) {
  printf("d: %s\n", args);
  if (args == NULL) {
    return -1;
  }
  char *value_numbers = strtok(args, " ");
  if (value_numbers == NULL ) {
    return -1;
  }
  int n = atoi(value_numbers);
  //delete watchpoint n
  delete_wp(n);
  return 0;
}

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },

  /* Add more commands */
  { "si", "si or si:N:execute N instructions step by step then pause,when N is not provided,the default is 1", cmd_si },
  { "info", "info r/w:print the information of registers or watchpoints", cmd_info },
  { "x", "x number start_addr:examine memory and print the value",cmd_x },
  { "p", "p expr:evaluate the expression", cmd_p },
  { "w", "w expr : set watchpoint", cmd_w },
  { "d", "d N:delete number N watchpoint", cmd_d },
 // { NULL, NULL, NULL }

};

#define NR_CMD ARRLEN(cmd_table)

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

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }
  for (char *str; (str = rl_gets()) != NULL; ) 
  {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
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

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}

void test_expr()
{
    FILE *fp = fopen("/home/daiman/Documents/dm/ysyx_gitcode/ysyx-workbench/nemu/tools/gen-expr/build/input", "r");
    assert(fp != NULL);
    char* e=NULL;
    bool success;
    word_t correct_result,result;
    size_t len;
    ssize_t read;
    int count=0;
    while(1)
    {
      if(fscanf(fp,"%u",&correct_result)==-1) break;
      read = getline(&e, &len, fp);
      if (read == -1) break;// if failt to read or no more line
      e[read-1] = '\0';
      result = expr(e, &success);
      if(success)
      {
        count++;
        printf("result = %u,correct_result = %u\n",result,correct_result);
        assert(result == correct_result);
      }
    }
    fclose(fp);
    free(e);
    printf("count=%d,test expr success\n",count);
}

