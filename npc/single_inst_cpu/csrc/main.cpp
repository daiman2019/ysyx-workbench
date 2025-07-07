#include "verilator_sim.h"
#include <getopt.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include "sdb.h"
#include "trace.h"
#include "device.h"
//#include "diffTest.h"
#include "memory.h"


static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static char *elf_file = NULL;
static int difftest_port = 1234;
FILE *log_fp = NULL;

VerilatedContext* contextp=NULL;
VerilatedVcdC* tfp = NULL;

static Vtop* top;
static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME* name);

CPU_state npc_cpu_reg = {0};

int finish_flag = 0;
void finish_sim()
{
  finish_flag = 1;
}
static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"log"      , required_argument, NULL, 'l'},
    {"port"     , required_argument, NULL, 'p'},
    {"elf"      , required_argument, NULL, 'e'},
    {"img"      , required_argument, NULL, 'i'},
    {"diff"     , required_argument, NULL, 'd'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "hl:p:d:e:i:", table, NULL)) != -1) {
    switch (o) {
      case 'l': log_file = optarg; break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      case 'd': diff_so_file = optarg; break;
      case 'i': img_file = optarg; break;
      case 'e': elf_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-i,--img=FILE           input bin file\n");
        printf("\t-e,--elf=FILE           input elf file\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

void init_log(const char *log_file) {
  log_fp = stdout;
  if (log_file != NULL) {
    FILE *fp = fopen(log_file, "w");
    if(fp==NULL)
      printf("Can not open '%s'\n", log_file);
    log_fp = fp;
  }
  log_write("Log is written to %s\n", log_file ? log_file : "stdout");
}
static long load_img(const char *img_file) {
  if (img_file == NULL) {
    log_write("No image is given. Use the default build-in image.\n");
    return 1; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  if(fp==NULL)
    log_write("Can not open '%s'\n", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  printf("The image is %s, size = %ld\n", img_file, size);
  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(MEM_START), size, 1, fp);
  //int ret = fread(pmem, size, 1, fp);
  assert(ret == 1);
  // for(int i=0;i<size;i++)
  // {
  //   printf("%08x\n",pmem[i]);
  // }
  fclose(fp);
  return size;
}

void step_and_dump_wave()
{
    top->clk=0;top->eval();
    contextp->timeInc(1);
#if vcd_on
    tfp->dump(contextp->time());
#endif
    top->clk=1;top->eval();
    contextp->timeInc(1);
#if vcd_on
    tfp->dump(contextp->time());
#endif
}
void sim_init()
{
    contextp = new VerilatedContext;
    top = new Vtop;//update
#if vcd_on
    tfp = new VerilatedVcdC;
    contextp->traceEverOn(true);
    top->trace(tfp,0);
    tfp->open("single_core_test.vcd");//.vcd
#endif
}

void sim_exit()
{
#if vcd_on
    tfp->close();
    delete tfp;
#endif
    delete top;
    delete contextp;
}
void reset(int n)
{
    top->rst = 1;
    while(n-->0)
        step_and_dump_wave();
    top->rst = 0;
}
void update_npc_regs()
{
  for(int i=0;i<32;i++)
  {
    npc_cpu_reg.gpr[i] = reg_lists[i];
  }
}
int sim_steps = 0;
int cur_pc,next_pc;
void execute_step(uint32_t n)
{
  for(uint32_t i=0;i<n;i++)
  {
    if(finish_flag==0)
    {
      top->clk=0;    
      top->eval();contextp->timeInc(1);
#if vcd_on
      tfp->dump(contextp->time());
#endif
      top->clk = 1;top->eval();
      if(top->difftest_en_t)
      {
        update_npc_regs();
        npc_cpu_reg.pc = next_pc;
#ifdef DIFFTEST_ENABLE
        difftest_step(cur_pc, next_pc);
#endif
#if NPC_ITRACE
      npc_trace(cur_pc,top->instruction);
#endif
        sim_steps++;
      }
      //top->instruction = pmem_read(top->pc,4,0);
      //top->eval();
      contextp->timeInc(1);
#if vcd_on
      tfp->dump(contextp->time());
#endif
      next_pc = top->npc;
      cur_pc=top->pc;
#ifdef CONFIG_DEVICE
      device_update();
#endif
    }
    else
      return;
  }
}
void sim_run()
{
    reset(2);
    while(finish_flag == 0)
    {
      sdb_npc();
    }
}

int main(int argc, char *argv[]) //for verilator to check vcd waveform
{
    // printf("argc=%d\n",argc);
    // for(int i=0;i<argc;i++)
    // {
    //     printf("argv[%d]=%s\n",i,argv[i]);
    // }
    parse_args(argc, argv);
    init_log(log_file);
    init_mem();
#ifdef CONFIG_DEVICE
    init_device();
#endif
    long img_size = load_img(img_file);
#if NPC_FTRACE
    ftrace_elf_read(elf_file);
    printf("load_elf finish\n");
#endif
#ifdef DIFFTEST_ENABLE
    diff_so_file ="/home/daiman/Documents/dm/ysyx_gitcode/ysyx-workbench/npc/single_inst_cpu/riscv32-nemu-interpreter-so";//riscv32-nemu-interpreter-so
    init_difftest(diff_so_file, img_size, difftest_port);
#endif
    //printf("in main sizeof pmem is %lx,pmem_addr %08x\n",sizeof(pmem),pmem);
    //printf("in main end is %08x\n",pmem[CONFIG_MSIZE-4]);
    sim_init();
    sim_run();
    sim_exit();
    printf("exec %d steps\n",sim_steps);
    printf("npc: %s \n",top->halt_ret==0? "HIT GOOD TRAP" :"HIT BAD TRAP");
    return top->halt_ret;
}

/*int main() // for nvboard test
{
  nvboard_bind_all_pins(&dut);
  nvboard_init();
  
  while(1) {
    nvboard_update();
    dut.eval();
  }
  nvboard_quit();
  return 0;
}*/
