#include <verilated.h>
#include <nvboard.h>
#include <Vmux41.h>
#include <verilated_vcd_c.h> //vcd waveform trace

VerilatedContext* contextp=NULL;
VerilatedVcdC* tfp = NULL;
static Vmux41* top;
static TOP_NAME mux41;
void nvboard_bind_all_pins(TOP_NAME* mux41);

void step_and_dump_wave()
{
    top->eval();
    contextp->timeInc(1);
    tfp->dump(contextp->time());
}

void sim_init()
{
    contextp = new VerilatedContext;
    tfp = new VerilatedVcdC;
    top = new Vmux41;
    contextp->traceEverOn(true);
    top->trace(tfp,0);
    tfp->open("mux41_waveform.vcd");//.vcd
}

void sim_exit()
{
    step_and_dump_wave();
    tfp->close();
}
void sim_run()
{
    top->Y=0;top->X0=0;top->X1=0;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=0;top->X0=1;top->X1=0;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=0;top->X0=0;top->X1=1;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=0;top->X0=0;top->X1=0;top->X2=1;top->X3=0;step_and_dump_wave();
    top->Y=0;top->X0=0;top->X1=0;top->X2=0;top->X3=1;step_and_dump_wave();
    
    top->Y=1;top->X0=0;top->X1=0;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=1;top->X0=0;top->X1=0;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=1;top->X0=0;top->X1=1;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=1;top->X0=0;top->X1=0;top->X2=1;top->X3=0;step_and_dump_wave();
    top->Y=1;top->X0=0;top->X1=0;top->X2=0;top->X3=1;step_and_dump_wave();
    
    top->Y=2;top->X0=0;top->X1=0;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=2;top->X0=1;top->X1=0;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=2;top->X0=0;top->X1=1;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=2;top->X0=0;top->X1=0;top->X2=1;top->X3=0;step_and_dump_wave();
    top->Y=2;top->X0=0;top->X1=0;top->X2=0;top->X3=1;step_and_dump_wave();
    
    top->Y=3;top->X0=0;top->X1=0;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=3;top->X0=1;top->X1=0;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=3;top->X0=0;top->X1=1;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=3;top->X0=0;top->X1=0;top->X2=1;top->X3=0;step_and_dump_wave();
    top->Y=3;top->X0=0;top->X1=0;top->X2=0;top->X3=1;step_and_dump_wave();
    
    top->Y=4;top->X0=0;top->X1=0;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=4;top->X0=1;top->X1=0;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=4;top->X0=0;top->X1=1;top->X2=0;top->X3=0;step_and_dump_wave();
    top->Y=4;top->X0=0;top->X1=0;top->X2=1;top->X3=0;step_and_dump_wave();
    top->Y=4;top->X0=0;top->X1=0;top->X2=0;top->X3=1;step_and_dump_wave();
}

/*int main() //for verilator to check vcd waveform
{
    sim_init();
    sim_run();
    sim_exit();
    return 0;
}*/
void single_cycle() {
  mux41.clk = 0; dut.eval();
  mux41.clk = 1; dut.eval();
}

static void reset(int n) {
  mux41.rst = 1;
  while (n -- > 0) single_cycle();
  mux41.rst = 0;
}

int main() {
  nvboard_bind_all_pins(&dut);
  nvboard_init();
  reset(10000);
  
  while(1) {
    nvboard_update();
    single_cycle();
  }
  nvboard_quit();
  return 0;
}
