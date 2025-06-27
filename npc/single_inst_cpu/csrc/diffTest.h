#include "common.h"

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
extern int finish_flag;

void init_difftest(char *ref_so_file, long img_size, int port);
void difftest_step(uint32_t pc, uint32_t npc);
void difftest_skip_ref();
