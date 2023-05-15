#include "../platform.h"

.text
.global trap_vector
.align 2    //  4 bytes 对齐
trap_vector:

//  模拟80386设置栈
set_correct_sp:
    //  sscratch位于内核栈-3*size_t处
    csrrw   t0, sscratch, t0
    sd      t1, 0*REGBYTES(t0)
    sd      t2, 1*REGBYTES(t0)
    sd      sp, 2*REGBYTES(t0)
    mv      t1, t0
    mv      t2, sp
    //  可能会有些浪费寄存器,
    //  可能需要优化

    csrr    sp, sstatus
    srl     sp, sp, 11
    andi    sp, sp, 0b01
    slti    sp, sp, 0b01
    addi    sp, sp, -1
    xor     t2, t2, t1
    and     sp, sp, t2
    xor     t2, t2, t1
    xor     sp, t1, sp

    //  这个部分模拟了80386栈的选择
    //  运行到这里, sp处于正确的栈顶
    //  t1存着sscratch, t2存着过去的sp
    //  此时用t0维护着3个值

//  模拟80386的中断向量
//  外设中断在其C语言代码中处理
jump_to_trap_vector:
    csrr    t1, scause
    li      t2, 0xfff
    not     t2, t2
    srli    t2, t2, 1       // t2 = 0x0ff...ff00
    and     t1, t1, t2
    bnez    t1, unknown_trap
    csrr    t1, scause
    li      t2, 0xff
    not     t2, t2      // t2 = 0xff..f00
    and     t1, t1, t2
    beqz    t1, exception
interrupt:
    csrr    t1, scause
    li      t2, 0xff
    and     t2, t1, t2
    la      t1, interrupts_vec
    slli    t2, t2, 3       // interrupts_vec[num]
    add     t1, t1, t2
    ld      t2, 0(t1)   // target function
    jr      t2
exception:
    csrr    t1, scause
    slli    t2, t1, 3
    la      t1, exceptions_vec
    add     t1, t1, t2
    ld      t2, 0(t1)   // target function
    jr      t2
unknown_trap:
    nop
    j       unknown_trap
    
    
    
    
    
