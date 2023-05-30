//这个本应放在sched.h里, 临时放这里
#include <linux/sys.h>
typedef long (*fn_ptr)();
//注意我们更改了typedef int (*fn_ptr)();为long


fn_ptr sys_call_table[NR_SYS_CALL] = {0
    
};

