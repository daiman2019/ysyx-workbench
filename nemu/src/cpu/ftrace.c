#include <common.h>
#include <elf.h>
#include <unistd.h> //for lseek
#include <fcntl.h> //for open
#include <utils.h>
typedef struct {
    char      name[20];
    paddr_t   addr;
    uint32_t  size;
    unsigned char info;
} mySym;
mySym* symb_tab =  NULL;
int symb_num=0;
int call_depth = 0;
//read elf header
static void read_elf_header(int fd,Elf32_Ehdr* elf_header)
{
    assert(lseek(fd,0,SEEK_SET)==0);//文件指针设置到文件开头
    assert(read(fd,(void*)elf_header,sizeof(Elf32_Ehdr)) == sizeof(Elf32_Ehdr));//读取elf_header内容到*elf_header
}
//read section header table
static void read_elf_section_headers(int fd,Elf32_Ehdr* elf_header,Elf32_Shdr* sh_tbl)
{
    assert(lseek(fd,elf_header->e_shoff,SEEK_SET)==elf_header->e_shoff);//找到段表开始地址
    for(int i=0;i<elf_header->e_shnum;i++)
    {
        assert(read(fd,(void*)&sh_tbl[i],elf_header->e_shentsize)==elf_header->e_shentsize);//逐项读入段表
    }
}
//read section
static void read_section(int fd,Elf32_Shdr section_header,void* dst)
{
    assert(dst!=NULL);
    assert(lseek(fd,section_header.sh_offset,SEEK_SET)==section_header.sh_offset);
    assert(read(fd,dst,section_header.sh_size)==section_header.sh_size);//读入段
}
//read symbol table
static void read_elf_symbol_table(int fd,Elf32_Ehdr* elf_header,Elf32_Shdr sh_tbl[])
{
    int strtab_index;
    for(int i=0;i<elf_header->e_shnum;i++)
    {
        if(sh_tbl[i].sh_type == SHT_SYMTAB || sh_tbl[i].sh_type == SHT_DYNSYM)
        {
            Elf32_Sym symb_tbl[sh_tbl[i].sh_size];//获取symtab段的大小
            read_section(fd,sh_tbl[i],symb_tbl);//读入symtab段
            symb_num = sh_tbl[i].sh_size/sizeof(Elf32_Sym);
            strtab_index = sh_tbl[i].sh_link;//和symtab关联的strtab索引
            char strtab[sh_tbl[strtab_index].sh_size];
            read_section(fd,sh_tbl[strtab_index],strtab);//读入和symtab对应的strtab
            symb_tab = malloc(symb_num*sizeof(mySym));
            for(int j=0;j<symb_num;j++)
            {
                
                strcpy(symb_tab[j].name,strtab+symb_tbl[j].st_name);
                symb_tab[j].addr = symb_tbl[j].st_value;
                symb_tab[j].size = symb_tbl[j].st_size;
                symb_tab[j].info = symb_tbl[j].st_info;
                //log_write("symbtab[%d] is func:addr %08x,size:%d,info:%d\n",j,symb_tab[j].addr,symb_tab[j].size,ELF32_ST_TYPE(symb_tab[j].info));
            }
        }
    }
}
//从elf文件中提取符号表和字符串表
void ftrace_elf_read(const char* elf_file)
{
    Elf32_Ehdr elf_header;
    if(elf_file == NULL) return;
    Log("elf file:%s\n",elf_file);
    int fd = open(elf_file,O_RDONLY);//只读模式打开
    if(fd<0) {perror("fail to read this elf file!");return;}  
    read_elf_header(fd,&elf_header);
    Elf32_Shdr section_hd_tbl[elf_header.e_shentsize* elf_header.e_shnum];
    read_elf_section_headers(fd,&elf_header,section_hd_tbl);
    read_elf_symbol_table(fd,&elf_header,section_hd_tbl);
    close(fd);
}
//追踪函数调用和函数返回
//根据pc查找调用的函数是否在symtab中，根据地址判断是否合理，返回在symtab中的索引
static int find_symb_func(vaddr_t target,bool is_call)
{
    int i;
    for(i=0;i<symb_num;i++)
    {
        if(ELF32_ST_TYPE(symb_tab[i].info) == STT_FUNC)
        {
            if(is_call && symb_tab[i].addr == target)
                break;
            else if(symb_tab[i].addr <= target && (symb_tab[i].addr+symb_tab[i].size)>target) 
                break;
        }
    }
    return i<symb_num?i:-1;
}
//
void trace_func_call(vaddr_t pc,vaddr_t target_addr)
{
    if(symb_tab==NULL) return;
    int symb_index = find_symb_func(target_addr,true);
    call_depth++;
    log_write(FMT_PADDR "%*s:call[%s@" FMT_PADDR "]\n", pc,call_depth," ",symb_index>0?symb_tab[symb_index].name:"???",target_addr);
}
//
void trace_func_ret(vaddr_t pc)
{
    if(symb_tab==NULL) return;
    int symb_index;
    symb_index = find_symb_func(pc,false);
    char* name = symb_index>0?symb_tab[symb_index].name:"???"
    log_write(FMT_PADDR "%*s :ret[%s]\n", pc,call_depth," ",name);
    call_depth--;
}
