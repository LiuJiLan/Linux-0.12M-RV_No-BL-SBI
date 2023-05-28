#include <linux/config.h>

nr_system_calls = NR_SYS_CALL

ENOSYS = 38

/*
 栈情况:(index为偏移)
 0:     a0      // 见详细说明
 1-7:   a1-a7
 8:     ra
 9:     t0
 10:    t1
 11:    t2
 12:    t3
 13:    t4
 14:    t5
 15:    t6
 */

/*
 caller保存栈的设计:
 首先, 尽管RISC-V大部分使用寄存器传值,
 但是我们还是要把所有caller寄存器入栈。
 原因: 因为我们都用的同一套代码, 无论多少参数。
 在用户态的ABI中, 只保存了对应系统调用参数个数的寄存器。
 而我们处理的时候是统一当作最大调用寄存器数量来调用的。
 其他寄存器则是由于caller and callee为标准去处理的。
 可能让读者有疑惑的是a7寄存器,
 a7是因为我们可以在中断的处理中复用代码。
 
 另外栈的设计没有按照寄存器x?的命名顺序排列,
 a0-a7处于栈的顶(栈顶? 反正是0偏移的位置, 错了请纠正)
 放在那个地方为了方便系统调用访问(方便我记)。
 */

/*
 a0需要额外说明:
 a0在其他caller保存期间, 是需要保存的
 与x86的ABI不同, RISC-V使用a7存储调用号
 a0存储返回值
 */

.macro  SAVE_CALLER_REGS
    addi     sp, sp, -16*REGBYTES
    REG_S    a0, 0*REGBYTES(sp)
    REG_S    a1, 1*REGBYTES(sp)
    REG_S    a2, 2*REGBYTES(sp)
    REG_S    a3, 3*REGBYTES(sp)
    REG_S    a4, 4*REGBYTES(sp)
    REG_S    a5, 5*REGBYTES(sp)
    REG_S    a6, 6*REGBYTES(sp)
    REG_S    a7, 7*REGBYTES(sp)
    REG_S    ra, 8*REGBYTES(sp)
    REG_S    t0, 9*REGBYTES(sp)
    //REG_S    t1, 10*REGBYTES(sp)
    //REG_S    t2, 11*REGBYTES(sp)
    REG_S    t3, 12*REGBYTES(sp)
    REG_S    t4, 13*REGBYTES(sp)
    REG_S    t5, 14*REGBYTES(sp)
    REG_S    t6, 15*REGBYTES(sp)
    
    csrr     t0, sscratch
    ld       t1, 0*REGBYTES(t0)
    ld       t2, 1*REGBYTES(t0)
    REG_S    t1, 10*REGBYTES(sp)
    REG_S    t2, 11*REGBYTES(sp)
.endm

.macro  RESTORE_CALLER_REGS
    REG_L    a0, 0*REGBYTES(sp)
    REG_L    a1, 1*REGBYTES(sp)
    REG_L    a2, 2*REGBYTES(sp)
    REG_L    a3, 3*REGBYTES(sp)
    REG_L    a4, 4*REGBYTES(sp)
    REG_L    a5, 5*REGBYTES(sp)
    REG_L    a6, 6*REGBYTES(sp)
    REG_L    a7, 7*REGBYTES(sp)
    REG_L    ra, 8*REGBYTES(sp)
    REG_L    t0, 9*REGBYTES(sp)
    REG_L    t1, 10*REGBYTES(sp)
    REG_L    t2, 11*REGBYTES(sp)
    REG_L    t3, 12*REGBYTES(sp)
    REG_L    t4, 13*REGBYTES(sp)
    REG_L    t5, 14*REGBYTES(sp)
    REG_L    t6, 15*REGBYTES(sp)
    addi     sp, sp, 16*REGBYTES
.endm



//  注意进入system_call的时候, t1和t2存在sscartch里

//  声明一个全局变量, 如果那个系统调用不存在(注意不是为实现)
//  转跳到这
.global bad_sys_call

.align 2
bad_sys_call:
    ld      a0, 0*REGBYTES(sp)
    j       ret_from_sys_call

.align 2
reschedule:
    la      ra, ret_from_sys_call
    j       schedule

.align 2
system_call:
    SAVE_CALLER_REGS
    li      t0, nr_system_calls
    bge     a7, t0, bad_sys_call

