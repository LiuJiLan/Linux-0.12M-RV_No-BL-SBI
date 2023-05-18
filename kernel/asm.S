#include <linux/config.h>

//  保存所有寄存器
//  除了sp
.macro  SAVE_REGS
    //  除x0之外的31个, 另外还有
    //  sstatus, sepc, scause, stavl
    addi    sp, sp, -35*REGBYTES
    REG_S    x1, 0*REGBYTES(sp)
    //  栈是连续的, 不应该由(trap的)上下文来维护
    //  但如果是进程切换的上下文中的栈, 是需要维护的
    //  REG_S    x2, 1*REGBYTES(sp)
    REG_S    x3, 2*REGBYTES(sp)
    REG_S    x4, 3*REGBYTES(sp)
    REG_S    x5, 3*REGBYTES(sp)
    //  t1、t2在sscratch的栈中
    //  REG_S    x6, 5*REGBYTES(sp)
    //  REG_S    x7, 6*REGBYTES(sp)
    REG_S    x8, 7*REGBYTES(sp)
    REG_S    x9, 8*REGBYTES(sp)
    REG_S    x10, 9*REGBYTES(sp)
    REG_S    x11, 10*REGBYTES(sp)
    REG_S    x12, 11*REGBYTES(sp)
    REG_S    x13, 12*REGBYTES(sp)
    REG_S    x14, 13*REGBYTES(sp)
    REG_S    x15, 14*REGBYTES(sp)
    REG_S    x16, 15*REGBYTES(sp)
    REG_S    x17, 16*REGBYTES(sp)
    REG_S    x18, 17*REGBYTES(sp)
    REG_S    x19, 18*REGBYTES(sp)
    REG_S    x20, 19*REGBYTES(sp)
    REG_S    x21, 20*REGBYTES(sp)
    REG_S    x22, 21*REGBYTES(sp)
    REG_S    x23, 22*REGBYTES(sp)
    REG_S    x24, 23*REGBYTES(sp)
    REG_S    x25, 24*REGBYTES(sp)
    REG_S    x26, 25*REGBYTES(sp)
    REG_S    x27, 26*REGBYTES(sp)
    REG_S    x28, 27*REGBYTES(sp)
    REG_S    x29, 28*REGBYTES(sp)
    REG_S    x30, 29*REGBYTES(sp)
    REG_S    x31, 30*REGBYTES(sp)
    
    csrr     t0, sscratch
    ld       t1, 0*REGBYTES(t0)
    ld       t2, 1*REGBYTES(t0)
    REG_S    t1, 5*REGBYTES(sp)
    REG_S    t2, 6*REGBYTES(sp)

    csrr     t0, sstatus
    REG_S    t0, 31*REGBYTES(sp)
    csrr     t0, sepc
    REG_S    t0, 32*REGBYTES(sp)
    csrr     t0, scause
    REG_S    t0, 33*REGBYTES(sp)
    csrr     t0, stval
    REG_S    t0, 34*REGBYTES(sp)
.endm

//  恢复所有的寄存器, 除了sp
.macro  RESTORE_REGS
    REG_L    x1, 0*REGBYTES(sp)
    //REG_L    x2, 1*REGBYTES(sp) // sp本身
    REG_L    x3, 2*REGBYTES(sp)
    REG_L    x4, 3*REGBYTES(sp)
    //  t0用于存取csr, 稍后保存
    //REG_L    x5, 4*REGBYTES(sp)
    REG_L    x6, 5*REGBYTES(sp)
    REG_L    x7, 6*REGBYTES(sp)
    REG_L    x8, 7*REGBYTES(sp)
    REG_L    x9, 8*REGBYTES(sp)
    REG_L    x10, 9*REGBYTES(sp)
    REG_L    x11, 10*REGBYTES(sp)
    REG_L    x12, 11*REGBYTES(sp)
    REG_L    x13, 12*REGBYTES(sp)
    REG_L    x14, 13*REGBYTES(sp)
    REG_L    x15, 14*REGBYTES(sp)
    REG_L    x16, 15*REGBYTES(sp)
    REG_L    x17, 16*REGBYTES(sp)
    REG_L    x18, 17*REGBYTES(sp)
    REG_L    x19, 18*REGBYTES(sp)
    REG_L    x20, 19*REGBYTES(sp)
    REG_L    x21, 20*REGBYTES(sp)
    REG_L    x22, 21*REGBYTES(sp)
    REG_L    x23, 22*REGBYTES(sp)
    REG_L    x24, 23*REGBYTES(sp)
    REG_L    x25, 24*REGBYTES(sp)
    REG_L    x26, 25*REGBYTES(sp)
    REG_L    x27, 26*REGBYTES(sp)
    REG_L    x28, 27*REGBYTES(sp)
    REG_L    x29, 28*REGBYTES(sp)
    REG_L    x30, 29*REGBYTES(sp)
    REG_L    x31, 30*REGBYTES(sp)

    REG_L    t0, 31*REGBYTES(sp)
    csrw     sstatus, t0
    REG_L    t0, 32*REGBYTES(sp)
    csrw     sepc, t0
    REG_L    t0, 33*REGBYTES(sp)
    csrw     scause, t0
    REG_L    t0, 34*REGBYTES(sp)
    csrw     stval, t0
    
    REG_L    x5, 4*REGBYTES(sp)
.endm

.macro  RESTORE_SP_AND_SRET
    csrrw    t0, sscratch, t0
    sd       t1, 0*REGBYTES(t0)
    sd       t2, 1*REGBYTES(t0)
    csrr     t1, sstatus
    srli     t1, t1, 8
    andi     t1, t1, 0b01
    bnez     t1, 1f
    ld       sp, 2*REGBYTES(t0)
1:  ld       t1, 0*REGBYTES(t0)
    ld       t2, 1*REGBYTES(t0)
    csrrw    t0, sscratch, t0
    sret
.endm




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
    mv      t1, t0
    mv      t2, sp
    //  可能会有些浪费寄存器,
    //  可能需要优化

    csrr    sp, sstatus
    srli    sp, sp, 8
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
    
    //  当sp==t2, 意味着权级没有改变
    beq     sp, t2, 1f
    sd      sp, 2*REGBYTES(t0)
    //  注意, sp的保存的含义与t0、t1、t2不一样
    //  他们的作用是作为临时变量
    //  而sp的保存是为了对于x86对原(用户态)栈的保存
    //  这是是为了在恢复上下文的时候有切实的依据
    
    //  选择在此处将sscratch换回来
    //  因为理论上之前模拟的是硬件过程
    //  是有可能再次遇到异常的
    //  sscratch应该在正确的值保证处理
1:
    csrrw t0, sscratch, t0

//  模拟80386的中断向量
//  外设中断在其C语言代码中处理
jump_to_trap_vector:
    csrr    t1, scause
    li      t2, 0xff
    not     t2, t2
    srli    t2, t2, 1       // t2 = 0x0ff...ff00
    and     t1, t1, t2
    bnez    t1, unknown_trap
    csrr    t1, scause
    li      t2, 0xf
    not     t2, t2      // t2 = 0xff..f00
    and     t1, t1, t2
    beqz    t1, exception
interrupt:
    csrr    t1, scause
    li      t2, 0xf
    and     t2, t1, t2
    la      t1, clint_vec
    slli    t2, t2, 3       // clint_vec[num]
    add     t1, t1, t2
    ld      t2, 0(t1)   // target function
    jr      t2
exception:
    csrr    t1, scause
    slli    t2, t1, 3
    la      t1, except_vec
    add     t1, t1, t2
    ld      t2, 0(t1)   // target function
    jr      t2
unknown_trap:
    j       unknown_trap_handler

unknown_trap_handler:
    
    // 以上代码模拟了80386的中断过程
    // sscratch的栈中存着t1、t2、原sp


//  Linux 0.12中所有的错误处理流程如下
//  保存所有寄存器
//  调用C语言, 打印以下内容:
//  trap前地址(EIP), 状态寄存器(EFLAGS)
//  trap前栈指针(ESP), 栈内容(如果是用户栈)
//  打印当前进程号与错误代码
//  打印用户栈
//  (但是如果是双错误也能打印吗?)
//  (我们实现的时候, 做一个权级的判断)
//  调用do_exit(11) 发送信号

//  暂时放这里, 之后汇总集中声明
.global reversed_trap
reversed_trap:
    la      t1, do_reversed_trap
    sd      t1, -36*REGBYTES(sp)
general_trap_handle:
    SAVE_REGS
    mv      a0, sp              // 参数
    ld      t0, -REGBYTES(sp)
    jalr    t0
    RESTORE_REGS
    RESTORE_SP_AND_SRET
    
