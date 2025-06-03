#include <verilated.h>
#include <nvboard.h>
#include <Vtop.h>
#include <verilated_vcd_c.h> //vcd waveform trace
#include <getopt.h>
#include "svdpi.h"
#include "Vtop__Dpi.h"
#include "sdb.h"
#include "trace.h"

static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static char *elf_file = NULL;
FILE *log_fp = NULL;

VerilatedContext* contextp=NULL;
VerilatedVcdC* tfp = NULL;

static Vtop* top;
static TOP_NAME dut;

void nvboard_bind_all_pins(TOP_NAME* name);
int finish_flag = 0;
void ebreak ()
{
  finish_flag = 1;
}
static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"log"      , required_argument, NULL, 'l'},
    {"elf"      , required_argument, NULL, 'e'},
    {"img"      , required_argument, NULL, 'i'},
    {"diff"     , required_argument, NULL, 'd'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "hl:d:e:i:", table, NULL)) != -1) {
    switch (o) {
      case 'l': log_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      case 'i': img_file = optarg; break;
      case 'e': elf_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-i,--img=FILE           input bin file\n");
        printf("\t-e,--elf=FILE           input elf file\n");
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

  //printf("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(pmem, size, 1, fp);
  assert(ret == 1);
  // for(int i=0;i<size;i++)
  // {
  //   printf("%08x\n",pmem[i]);
  // }
  //printf("read file close\n");
  fclose(fp);
  return size;
}

static uint32_t pmem_read(uint32_t addr) {
    //log_write("addr = %08x\n",addr);
    if(addr>=0x80000000)
    {
      uint32_t ret = pmem[(addr-0x80000000)>>2];
      //log_write("inst = %08x\n",ret);
      return ret;
    }  
    else 
      return 0;
}

void step_and_dump_wave()
{
    top->clk=0;top->eval();
    contextp->timeInc(1);
    tfp->dump(contextp->time());
    top->clk=1;top->eval();
    contextp->timeInc(1);
    tfp->dump(contextp->time());
}
void sim_init()
{
    contextp = new VerilatedContext;
    tfp = new VerilatedVcdC;
    top = new Vtop;//update
    contextp->traceEverOn(true);
    top->trace(tfp,0);
    tfp->open("single_core_test.vcd");//.vcd
}

void sim_exit()
{
    tfp->close();
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
void execute_step(uint32_t n)
{
  for(uint32_t i=0;i<n;i++)
  {
    top->clk=0;
    top->eval();contextp->timeInc(1);
    tfp->dump(contextp->time());
    top->clk = 1;top->eval();
    top->instruction = pmem_read(top->pc);
    top->eval();
    contextp->timeInc(1);
    tfp->dump(contextp->time());
    //printf("top->result=%d\n",top->result);
#ifdef NPC_ITRACE
    npc_trace(top->pc,top->instruction);
#endif
  }
}
void sim_run()
{
    reset(2);
    while(finish_flag == 0)
    {
      //execute_step(1);
      sdb_npc();
    }
}

int main(int argc, char *argv[]) //for verilator to check vcd waveform
{
    printf("argc=%d\n",argc);
    for(int i=0;i<argc;i++)
    {
        printf("argv[%d]=%s\n",i,argv[i]);
    }
    parse_args(argc, argv);
    init_log(log_file);
    load_img(img_file);
    ftrace_elf_read(elf_file);
    sim_init();
    sim_run();
    sim_exit();
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
