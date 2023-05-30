#include <arch/types.h>
#include <linux/mm.h>
#include <linux/sched.h>

#include <signal.h>

#define _S(nr) (1<<((nr)-1))
#define _BLOCKABLE (~(_S(SIGKILL) | _S(SIGSTOP)))

union task_union {
    struct task_struct task;
    char stack[PAGE_SIZE];
};

static union task_union init_task = {INIT_TASK,};

uint64 volatile jiffies;
uint64 startup_time;
int jiffies_offset;

struct task_struct *current = &(init_task.task);
//struct task_struct *last_task_used_math = NULL;

struct task_struct * task[NR_TASKS] = {&(init_task.task), };


// 注意, 我们用这种方式完成了64bits的对齐
// 不要使用uint8 user_stack[PAGE_SIZE]来替代
// 另外, 如果非gcc编译器以及编译优化后是不保证对齐的
// Linux 0.12中是PAGE_SIZE>>2, 注意是保证4KiB大小
size_t user_stack [ PAGE_SIZE>>3 ] ;



void schedule(void) {
    int i, next, c;
    struct task_struct ** p;
    
    /* check alarm, wake up any interruptible tasks that have got a signal */
    for (p = &LAST_TASK; p > &FIRST_TASK; --p) {
        if (*p) {
            if ((*p)->timeout && (*p)->timeout < jiffies) {
                (*p)->timeout = 0;
                if ((*p)->state == TASK_INTERRUPTIBLE) {
                    (*p)->state = TASK_RUNNING;
                }
            }
            if ((*p)->alarm && (*p)->alarm < jiffies) {
                (*p)->signal |= (1<<(SIGALRM-1));
                (*p)->alarm = 0;
            }
            if (((*p)->signal & ~(_BLOCKABLE & (*p)->blocked)) &&
                (*p)->state==TASK_INTERRUPTIBLE) {
                (*p)->state=TASK_RUNNING;
            }
        }
    }
    
    while (1) {
        c = -1;
        next = 0;
        i = NR_TASKS;
        p = &task[NR_TASKS];
        while (--i) {
            if (!*--p) {
                continue;
            }
            if ((*p)->state == TASK_RUNNING && (*p)->counter > c) {
                c = (*p)->counter;
                next = i;
            }
        }
        if (c) {
            break;
        }
        for (p = &LAST_TASK; p > &FIRST_TASK; --p) {
            if (*p) {
                (*p)->counter = ((*p)->counter >> 1) +(*p)->priority;
            }
        }
        switch_to(next);
    }
}
