#include <linux/sys.h>

nr_system_calls = NR_syscalls

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
 16:    orig_a0 // 见详细说明
 17:    sepc
 */

/*
 关于a0与orig_a0(也是关于original %eax)说明
 我们首先明确, 这个栈情况适用于中断与系统调用的情况。
 所以保存caller寄存器是无争议的。
 
 然后我们从寄存器的还原说起:
 还原寄存器还原所有的caller和sepc,
 并跳过orig。
 
 现在我们来解释为什么要额外保存一份orig
 因为在系统调用结束后, 在do_signal中,
 我们可能让系统调用重新开始(相当于这个调用没有发生)。
 
 x86中eax本身用于保存系统调用号, 同时被用来存返回值。
 如果不额外存, 那么, 存放的调用号就回被覆盖。
 
 对于RISC-V来说, 虽然传调用号的是a7,
 但是也是同样的思路:
 a0用于传递参数, 同时被用于存放返回值,
 如果不保存一份存着参数的a0,
 重新调用的时候就会被返回值覆盖。
 */

/*
 另外注意一点:
 如果用man syscall查看,
 会发现其实有Retval1和Retval2,
 man syscall的第六条补充:
 “Other architectures do not use the
 second return value register in the system call interface,
 even if it is defined in the System V ABI.”
 x86和RISCV都不使用第二个寄存器返回数据
 */
 



//  注意, 系统调用的这一部分与这个宏稍有不同
//  考虑到代码复用性, 我们只为中断书写宏
.macro  SAVE_CALLER_REGS
    addi     sp, sp, -18*REGBYTES
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
    
    li       t1, -1
    REG_S    t1, 16*REGBYTES(sp)    //orig_a0

    csrr     t2, sepc
    REG_S    t2, 17*REGBYTES(sp)
    
    csrr     t0, sscratch
    ld       t1, 0*REGBYTES(t0)
    ld       t2, 1*REGBYTES(t0)
    REG_S    t1, 10*REGBYTES(sp)
    REG_S    t2, 11*REGBYTES(sp)
.endm

//  restore的宏是系统调用和中断通用的
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
    //REG_L    t1, 10*REGBYTES(sp)
    REG_L    t2, 11*REGBYTES(sp)
    REG_L    t3, 12*REGBYTES(sp)
    REG_L    t4, 13*REGBYTES(sp)
    REG_L    t5, 14*REGBYTES(sp)
    REG_L    t6, 15*REGBYTES(sp)

    //  Ignore orig_a0
    //  因为它只被do_signal需要
    //  而restore在do_signal之后
    
    ld       t1, 17*REGBYTES(sp)
    csrw     sepc, t1

    REG_L    t1, 10*REGBYTES(sp)
    addi     sp, sp, 18*REGBYTES
.endm



//  注意进入system_call的时候, t1和t2存在sscartch里


.global ecall_from_u
ecall_from_u:
    //模拟x86的情况, 因为x86中属于软中断
    //指向下一条
    //另外我们选择保存回sepc中, 而不是栈中
    //为了防止可能的错误
    //(如果写到最后都不冲突, 那我就直接存栈了)
    csrr     t1, sepc
    addi     t1, t1, 4
    csrw     sepc, t1
    j        system_call


.align 2
bad_sys_call:
    li      t1, -ENOSYS
    ld      t1, 0*REGBYTES(sp)
    j       ret_from_sys_call
.align 2
reschedule:
    la      ra, ret_from_sys_call
    j       schedule
.align 2
system_call:
    SAVE_CALLER_REGS
    ld      t1, 16*REGBYTES(sp) //orig_a0
    //  偷懒复用一下代码
    li      t0, nr_system_calls
    bge     a7, t0, bad_sys_call
    la      t1, sys_call_table
    slli    t2, a7, 3
    add     t1, t1, t2
    ld      t2, 0(t1)//sys_call_table[a7]
    beqz    bad_sys_call
    jalr    t2
    ld      a0, 0(sp)
2:
    //...对current进行一些处理, 暂时省略
ret_from_sys_call:
    //一些处理, 信号的处理
    //暂时留白
3:  RESTORE_CALLER_REGS
    j       all_trap_return


