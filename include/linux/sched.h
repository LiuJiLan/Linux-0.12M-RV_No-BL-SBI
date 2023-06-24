
#ifndef sched_h
#define sched_h

#define HZ 100

#define NR_TASKS    64

//  由于我们改进了进城的空间,
//  我们不再有那么多限制

//  关于lib, 说实话我没搞懂这种调用方式,
//  所以直接忽略实现

//  我们还是保证10ms触发一次时钟中断
//  所以这块不变
#define CT_TO_SECS(x)    ((x) / HZ)
#define CT_TO_USECS(x)    (((x) % HZ) * 1000000/HZ)

#define FIRST_TASK task[0]
#define LAST_TASK task[NR_TASKS-1]


//  稍后补上
#include <arch/types.h>

#define TASK_RUNNING        0
#define TASK_INTERRUPTIBLE    1
#define TASK_UNINTERRUPTIBLE    2
#define TASK_ZOMBIE        3
#define TASK_STOPPED        4


typedef long (*fn_ptr)();
//注意我们更改了typedef int (*fn_ptr)();为long

//  相当于原来的struct tss_struct
//  只保存了callee, 所以如果switch_to
//  需要用C语言来保存一些东西
struct context {
    size_t sp;
    size_t s0;
    size_t s1;
    size_t s2;
    size_t s3;
    size_t s4;
    size_t s5;
    size_t s6;
    size_t s7;
    size_t s8;
    size_t s9;
    size_t s10;
    size_t s11;
    size_t sepc;
    size_t sscratch;
    //  sscratch理应放在这里,
    //  因为context本质上代替了TSS
    //  而存放内核态栈的ESP0正是放在TSS中
    //  这与sscratch的作用相同
    
    //注意, 只存储了pgtbl的物理地址
    //mode需要在其他程序里手动加上去
    //可以看作原来的ldt, 因为它实现了内存的隔离
    //放在这是为了方便switch_to来处理
    size_t * pgtbl;
};

struct task_struct {
    //  以下几个变量在汇编里定死了偏移, 不要改变顺序
    int32 state;    /* -1 unrunnable, 0 runnable, >0 stopped */
    int32 counter;
    int32 priority;
    int32 signal;
    //struct sigaction sigaction[32];
    int32 blocked;    /* bitmap of masked signals */
    
    //  从此处开始随意
    int exit_code;
    size_t start_code,end_code,end_data,brk,start_stack;
    long pid,pgrp,session,leader;
    //int  groups[NGROUPS];
    
    unsigned short uid,euid,suid;
    unsigned short gid,egid,sgid;
    
    uint64 timeout,alarm;
    int64 utime,stime,cutime,cstime,start_time;
    
    //struct rlimit rlim[RLIM_NLIMITS];
    
    /* file system info */
    int tty;        /* -1 if no tty, so it must be signed */
//    unsigned short umask;
//    struct m_inode * pwd;
//    struct m_inode * root;
//    struct m_inode * executable;
//    struct m_inode * library;
//    unsigned long close_on_exec;
//    struct file * filp[NR_OPEN];
    
    struct context context;
};

#define INIT_TASK {}

extern struct task_struct * task[NR_TASKS];
//extern struct task_struct * last_task_used_math;
extern struct task_struct * current;
extern uint64 volatile jiffies;
extern uint64 startup_time;
extern int jiffies_offset;

#define CURRENT_TIME (startup_time+(jiffies+jiffies_offset)/HZ)

//extern void add_timer(long jiffies, void (*fn)(void));
//extern void sleep_on(struct task_struct ** p);
//extern void interruptible_sleep_on(struct task_struct ** p);
//extern void wake_up(struct task_struct ** p);
//extern int in_group_p(gid_t grp);

//  由于要对结构体做访问, 但是结构体的偏移不知道,
//  只能先用C语言
//  又不太能像原版一样用内联汇编, 因为代码量和宏的问题
static inline void switch_to(int n) {
    if (current != task[n]) {
        extern void switch_to_asm(struct context*, struct context*);
        switch_to_asm(&current->context, &task[n]->context);
    }
}

#endif /* sched_h */
