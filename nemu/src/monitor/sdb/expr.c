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
#include <memory/vaddr.h>
#include "sdb.h"

enum {
  TK_NOTYPE = 256, TK_EQ,TK_NEQ,TK_AND,TK_DEREF,TK_MINUS,TK_ADD,TK_SUB,TK_MUL,TK_DIV,TK_LEFT,TK_RIGHT,TK_DIGIT,TK_VAR,TK_HEX,TK_REG
};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", TK_ADD},         // plus
  {"==", TK_EQ},        // equal
  {"!=", TK_NEQ},       //not equal
  {"&&", TK_AND},       //and 
  {"\\*",TK_MUL},       // multiply
  {"-", TK_SUB},         // minus
  {"\\/", TK_DIV},         // slash
  {"\\(", TK_LEFT},         // left parenthesis
  {"\\)", TK_RIGHT},         // right parenthesis
  {"0x[0-9a-fA-F]+", TK_HEX}, // hex number  
  {"[0-9]+", TK_DIGIT},      // decimal number
  {"[a-zA-Z_][a-zA-Z0-9_]*", TK_VAR}, // identifier
  {"\\$\\w+", TK_REG}, // register
};

#define NR_REGEX ARRLEN(rules)
#define max_token 65535

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
  char str[max_token_len];
} Token;

static Token tokens[max_token] __attribute__((used)) = {};
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
        if (nr_token >= max_token) {
          printf("Too many tokens : %d\n",nr_token);
          return false;
        }
        copy_len = substr_len > max_token_len-1 ? max_token_len-1 : substr_len;
        switch (rules[i].token_type) {
          case TK_NOTYPE: break;
          case TK_ADD:
            tokens[nr_token].type = TK_ADD;
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case TK_SUB:
            if(nr_token>0 && ((tokens[nr_token-1].type == TK_DIGIT)||(tokens[nr_token-1].type == TK_HEX)||(tokens[nr_token-1].type == TK_RIGHT)||(tokens[nr_token-1].type == TK_REG)))
            {
              tokens[nr_token].type = TK_SUB;
              strncpy(tokens[nr_token].str, substr_start, copy_len);
              tokens[nr_token].str[copy_len] = '\0';
              nr_token++;
            }
            else
            {
              tokens[nr_token].type = TK_MINUS;
              strncpy(tokens[nr_token].str, substr_start, copy_len);
              tokens[nr_token].str[copy_len] = '\0';
              nr_token++;
            }
            break;
          case TK_MUL://mul or dereference
            if(nr_token>0 && ((tokens[nr_token-1].type == TK_DIGIT)||(tokens[nr_token-1].type == TK_HEX)||(tokens[nr_token-1].type == TK_RIGHT)||(tokens[nr_token-1].type == TK_REG)))
            {
              tokens[nr_token].type = TK_MUL;
              strncpy(tokens[nr_token].str, substr_start, copy_len);
              tokens[nr_token].str[copy_len] = '\0';
              nr_token++;
            }
            else
            {
              tokens[nr_token].type = TK_DEREF;
              strncpy(tokens[nr_token].str, substr_start, copy_len);
              tokens[nr_token].str[copy_len] = '\0';
              nr_token++;
            }
            break;
          case TK_DIV:
            tokens[nr_token].type = TK_DIV;
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case TK_LEFT:
            tokens[nr_token].type = TK_LEFT;
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case TK_RIGHT:
            tokens[nr_token].type = TK_RIGHT;
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case TK_DIGIT://decimal number
            tokens[nr_token].type = TK_DIGIT;
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case TK_HEX://hex number
            tokens[nr_token].type = TK_HEX;
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case TK_EQ:
            tokens[nr_token].type = TK_EQ;
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case TK_NEQ:
            tokens[nr_token].type = TK_NEQ;
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case TK_AND:
            tokens[nr_token].type = TK_AND;
            strncpy(tokens[nr_token].str, substr_start, copy_len);
            tokens[nr_token].str[copy_len] = '\0';
            nr_token++;
            break;
          case TK_REG:
            tokens[nr_token].type = TK_REG;
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
uint32_t value_compute(int token_type,char* token_str,bool* success)
{
  uint32_t value = 0;
  *success = true;
  switch (token_type) {
    case TK_DIGIT:
      value = atoi(token_str);
      break;
    case TK_HEX:
      value = strtoul(token_str, NULL, 16);
      break;
    case TK_REG:
      value = isa_reg_str2val(&token_str[1], success);
      if(*success) 
      {
        return value;
      }
      else
      {
        printf("wrong register name:%s\n",token_str);
        return 0;
      }
      break;
    default:
     *success = false;
      printf("wrong token type:%d\n", token_type);
      return 0;
  }
  return value;
}

word_t eval(int p, int q,bool* success) //p and q are the start and end index of tokens
{
  //int state = 0;
  word_t val1=0,val2=0,val=0;
  bool success1 = false,success2 = false;
  if (p > q) //wrong position
  {
    printf("p > q\n");
    *success = false;
    return 0;
  }
  else if (p == q) //must be a decimal number or a hex number or a register
  {
    val = value_compute(tokens[p].type,tokens[p].str,success);
    if(*success) return val;
    else return 0;
  }
  else if(check_parentheses(p, q))
  {
    return eval(p+1,q-1,success);//去掉最外层括号
  }
  else
  {
    int op = find_main_operator(p, q);
    *success = true;
    printf ("op = %d,p=%d,q=%d\n", op,p,q);
    printf("main operater:%d\n",tokens[op].type);
    if (op == -1) //no operator
    {
      printf("no right operator\n");
      *success = false;
      return 0;
    }
    val1 = eval(p, op - 1,&success1);
    val2 = eval(op + 1, q,&success2);  
    if(!success2) 
    {
      *success=false;
      return 0;
    }
    if(success1)
    {
      switch(tokens[op].type)
      {
        case TK_ADD:return val1 + val2;
        case TK_SUB:return val1 - val2;
        case TK_MUL:return val1 * val2;
        case TK_DIV:return (sword_t)val1 / (sword_t)val2;
        case TK_EQ: return val1 == val2;
        case TK_NEQ: return val1 != val2;
        case TK_AND: return val1 && val2;
        default: printf("wrong main operater:%d\n",tokens[op].type);*success = false;return 0;
      }
    }
    else
    {
      switch(tokens[op].type)
      {
        case TK_DEREF: return vaddr_read(val2,4);
        case TK_MINUS: return 0-val2;
        default: printf("wrong main operater:%d\n",tokens[op].type);*success = false;return 0;
      }
    }
  }
}
int find_main_operator(int p, int q) //find the main operator
{
  int i;
  int op = -1;
  int level = 0;
  int main_op = 0, cur_op = 0;
  for (i = q; i >= p; i--)
  {
    if (tokens[i].type == TK_RIGHT)
    {
      level++;
    }
    else if (tokens[i].type == TK_LEFT)
    {
      level--;
    }
    else if (level == 0)
    {
      if (tokens[i].type == TK_ADD || tokens[i].type == TK_SUB)
      {
        cur_op = 3;
      }
      else if (tokens[i].type == TK_MUL || tokens[i].type == TK_DIV)
      {
        //printf("tokens[%d].type = %c\n", i, tokens[i].type);
        cur_op = 2;
      }
      else if(tokens[i].type == TK_MINUS || tokens[i].type == TK_DEREF)
      {
        cur_op = 1;
      }
      else if(tokens[i].type == TK_EQ || tokens[i].type == TK_NEQ)
      {
        cur_op = 4;
      }
      else if(tokens[i].type == TK_AND)
      {
        cur_op = 5;
      }
      if(cur_op > main_op)
      {
        main_op = cur_op;
        op = i;
      }
    }
  }
  return op;
}
int check_parentheses(int p,int q) //check if there are matched parentheses
{
  int state=0;
  if(tokens[p].type != TK_LEFT || tokens[q].type != TK_RIGHT)
  {
    return 0; //not matched
  }
  for(int i=p;i<=q;i++)
  {
    if (tokens[i].type == TK_LEFT)
    {
      state++;
    }
    else if (tokens[i].type == TK_RIGHT)
    {
      state--;
    }
    if (state==0) //matched parentheses
    {
      return i==q; //the leftmost ( and the rightmost ) are matched
    }
  }
  return 0;
}


word_t expr(char *e, bool *success) {
  word_t result;
  if (!make_token(e)) {
    *success = false;
    return 0;
  }
  /* Insert codes to evaluate the expression. */
  result =  eval(0, nr_token-1,success);
  if(*success)
  {
    return result;
  }
  else
  {
    printf("wrong expression\n");
    return 0;
  }
}


