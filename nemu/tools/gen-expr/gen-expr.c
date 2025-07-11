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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";
int pos;
static void gen(char c) 
{
  if(pos >= sizeof(buf) - 1) {
    fprintf(stderr, "Buffer overflow\n");
    exit(1);
  }
  buf[pos++] = c;
  buf[pos] = '\0';
}
static int choose(int n) {
  return rand() % n;
}
static void gen_rand_op() {
  switch(choose(4))
  {
    case 0:gen('+');break;
    case 1:gen('-');break;
    case 2:gen('*');break;
    default:gen('/');break;
  }
}
static void gen_num()
{
  gen('0' + choose(10));
}

static void gen_space()
{
  int i = choose(3);
  for(int j=0;j<i;j++)
    gen(' ');
}

static void gen_rand_expr(int depth) {
  if (depth == 0) {
    gen_num();
    return;
  }
  switch(choose(3))
  {
    case 0:gen_num();gen_space();break;
    case 1: gen('(');gen_rand_expr(depth-1);gen(')');break;
    default:gen_rand_expr(depth-1);gen_rand_op();gen_rand_expr(depth-1);break;
  }
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
    pos = 0;
    gen_rand_expr(100);//control the length of buf

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -Wall -Werror -o /tmp/.expr");//
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%u %s\n", result, buf);
  }
  return 0;
}



