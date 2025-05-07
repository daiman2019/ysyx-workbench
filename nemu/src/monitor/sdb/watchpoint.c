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

  /* TODO: Add more members if necessary */

} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

/* Implement the functionality of watchpoint */
WP* new_wp() //return a free watchpoint
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

//delete a watchpoint
void delete_wp(int NO) 
{
  WP delete_number;
  delete_number.NO = NO;
  free_wp(&delete_number);
}