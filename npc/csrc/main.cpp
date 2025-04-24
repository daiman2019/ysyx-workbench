#include <verilated.h>
#include <nvboard.h>
#include <Vmux41.h>
#include <verilated_vcd_c.h> //vcd waveform trace

VerilatedContext* contextp=NULL;
VerilatedVcdC* tfp = NULL;
static Vmux41* top;

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
    top->Y=0;step_and_dump_wave();
    top->Y=1;step_and_dump_wave();
    top->Y=2;step_and_dump_wave();
    top->Y=3;step_and_dump_wave();
}

int main()
{
    sim_init();
    sim_run();
    sim_exit();
    return 0;
}
/*void single_cycle() {
  dut.clk = 0; dut.eval();
  dut.clk = 1; dut.eval();
}

static void reset(int n) {
  dut.rst = 1;
  while (n -- > 0) single_cycle();
  dut.rst = 0;
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
}*/
