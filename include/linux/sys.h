#ifndef sys_h
#define sys_h

#include <linux/config.h>

//  我们调整了这个sys_call_table数组的位置
//  因为如果我们要把这个数组放在这里,
//  这是个.h文件, 想让.S访问就要引入这个.h
//  但是.S不认typedef, 所以只能把它放到sys.c中了

int NR_syscalls = NR_SYS_CALL;

#endif /* sys_h */
