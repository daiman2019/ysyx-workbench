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

#include "sdb.h"

#define NR_WP 32

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;
  char expr[max_token_len];
  word_t old_value;
  bool is_active;
} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].old_value = 0;
    wp_pool[i].is_active = false;
  }
  head = NULL;
  free_ = wp_pool;
}

/* Implement the functionality of watchpoint */
WP* new_wp() //return a free watchpoint to use
{
  if (free_ == NULL) {
    printf("No free watchpoint!\n");
    return NULL;
  }
  WP *free_wp = free_;
  free_ = free_->next;
  free_wp->next = head;
  head = free_wp;
  return free_wp;
}

void free_wp(WP *wp) //return a watchpoint to the free list
{
  if (wp == NULL) 
  {
    return;
  }
  WP *prev = NULL, *curr = head;
  while (curr != NULL && curr->NO != wp->NO) //find wp in the head list
  {
    prev = curr;
    curr = curr->next;
  }
  if (curr == NULL) 
  {
    printf("Watchpoint not found!\n");
    return;
  }
  if (prev == NULL) 
  {
    head = curr->next;
  } 
  else 
  {
    prev->next = curr->next;
  }
  curr->next = free_;
  free_ = curr;
}
//set a new watchpoint
void set_wp(char *expression) 
{
  WP *new_watchpoint = new_wp();
  if (new_watchpoint == NULL) 
  {
    return;
  }
  strcpy(new_watchpoint->expr, expression);
  new_watchpoint->old_value = expr(expression, &new_watchpoint->is_active);
  if (new_watchpoint->is_active) 
  {
    printf("Watchpoint %d: %s\n", new_watchpoint->NO, new_watchpoint->expr);
  } 
  else 
  {
    printf("Invalid watchpoint expression!\n");
    free_wp(new_watchpoint);
  }
}

//delete a watchpoint
void delete_wp(int NO) 
{
  WP delete_number;
  delete_number.NO = NO;
  free_wp(&delete_number);
}
//scan all watchpoints
int scan_wp() 
{
  WP *curr = head;
  int val = 0;
  while (curr != NULL) 
  {
    if (curr->is_active) 
    {
      word_t new_value = expr(curr->expr, &curr->is_active);
      if (curr->is_active && new_value != curr->old_value) 
      {
        printf("Watchpoint %d: %s\n", curr->NO, curr->expr);
        printf("Old value: %08x, New value: %08x\n", curr->old_value, new_value);
        curr->old_value = new_value; //update the old value
        val = 1;
        nemu_state.state = NEMU_STOP;
        break;
      }
    }
    curr = curr->next;
  }
  return val; //return 0 if there is no watchpoint hit,return 1 if there is a watchpoint hit
}
//print all watchpoints
void print_all_wp() 
{
  WP *curr = head;//all used watchpoints
  if(curr == NULL) 
  {
    printf("No watchpoints set!\n");
    return;
  }
  printf("       num      active       expr\n");
  printf("====================================\n");
  while (curr != NULL) 
  {
    printf("Watchpoint %d     %d        %s\n", curr->NO, curr->is_active,curr->expr);
    curr = curr->next;
  }
}