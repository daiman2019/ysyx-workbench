#include <cstdint>
void npc_trace(uint32_t pc,uint32_t instruction);
#define NPC_ITRACE 1
typedef uint32_t paddr_t;

void ftrace_elf_read(const char* elf_file);