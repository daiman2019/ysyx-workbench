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

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
#include <stdbool.h>

enum {
  TK_NOTYPE = 256, TK_EQ,

  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", '+'},         // plus
  {"==", TK_EQ},        // equal
  {"\\*",'*'},       // multiply
  {"-", '-'},         // minus
  {"\\/", '/'},         // slash
  {"\\(", '('},         // left parenthesis
  {"\\)", ')'},         // right parenthesis
  {"[0-9]+", '0'},      // decimal number
  {"[a-zA-Z_][a-zA-Z0-9_]*", '1'}, // identifier
  {"0x[0-9a-fA-F]+", '2'}, // hex number  
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[32] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;
int find_main_operator(int p, int q);
int check_parentheses(int p,int q);
static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;
  int copy_len = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        if (nr_token >= 32) {
          printf("Too many tokens : %d\n",nr_token);
          return false;
        }
        copy_len = substr_len > 31 ? 31 : substr_len;
        switch (rules[i].token_type) {
          case TK_NOTYPE: break;
          case '+':
            tokens[nr_token].type = '+';
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case '-':
            tokens[nr_token].type = '-';
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case '*':
            tokens[nr_token].type = '*';
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case '/':
            tokens[nr_token].type = '/';
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case '(':
            tokens[nr_token].type = '(';
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case ')':
            tokens[nr_token].type = ')';
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case '0'://decimal number
            tokens[nr_token].type = '0';
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          default: break;
        }
        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

int eval(int p, int q) //p and q are the start and end index of tokens
{
  int state = 0;
  if (p > q) //wrong position
  {
    printf("p > q\n");
    return 0;
  }
  else if (p == q) //must be a number
  {
    return atoi(tokens[p].str);
  }
  else
  {
    state = check_parentheses(p, q);
    printf("state=%d\n", state);
    if(state==2) 
    {
      printf("wrong parentheses\n");
      assert(0);
    }
    else if(state==1)
    {
      return eval(p+1,q-1);
    }
    else
    {
      int op = find_main_operator(p, q);
      printf ("op = %d,p=%d,q=%d\n", op,p,q);
      printf("main operater:%c\n",tokens[op].type);
      if (op == -1) //no operator
      {
        printf("no right operator\n");
        assert(0);
      }

      int val1 = eval(p, op - 1);
      int val2 = eval(op + 1, q);
    
      printf("val1 = %d, val2 = %d\n", val1, val2);
    
      switch (tokens[op].type) {
      case '+': return val1 + val2;
      case '-': return val1 - val2;
      case '*': return val1 * val2;
      case '/': return val1 / val2;
      default: printf("wrong main operater:%d\n",tokens[op].type);return 0;
     }
    }
  }
}
int find_main_operator(int p, int q) //find the main operator
{
  int i;
  int op = -1;
  int level = 0;
  for (i = q; i >= p; i--)
  {
    if (tokens[i].type == ')')
    {
      level++;
    }
    else if (tokens[i].type == '(')
    {
      level--;
    }
    else if (level == 0)
    {
      if (tokens[i].type == '+' || tokens[i].type == '-')
      {
        return i;
      }
      else if (tokens[i].type == '*' || tokens[i].type == '/')
      {
        op = i;
      }
    }
  }
  return op;
}
int check_parentheses(int p,int q) //check if there are matched parentheses
{
  int state=0,num=0,max=0;
  for(int i=p;i<=q;i++)
  {
    if (tokens[i].type == '(')
    {
      state++;
      max = state>max?state:max;
    }
    else if (tokens[i].type == ')')
    {
      state--;
      if(state<0)
      {
        printf("state=%d,max=%d\n",state,num);
        return 2; //stop to calculate
      }
      num = state==0?num+1:num;
    }
  }
  return (state==0)&&(num<=1)&&(max>=1);
}


word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* Insert codes to evaluate the expression. */
  *success = true;
  return eval(0, nr_token-1);

}
