#ifndef sys_h
#define sys_h

#include <linux/config.h>

//这个本应放在sched.h里, 临时放这里
typedef int (*fn_ptr)();

fn_ptr sys_call_table[NR_syscalls] = {
    
}


#endif /* sys_h */
