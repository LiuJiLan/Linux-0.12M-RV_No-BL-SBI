#include <linux/config.h>

/*
 head中需要注意物理地址和虚拟地址。
 首先是注意暂时是pc是物理的地址,
 能正常转跳是因为是相对地址转跳。
 然后就是加载时, 编译器认为你是虚拟地址。
 例如, 现在位于0x80200000, 你想加载一个绝对地址
 0x802000008, 但是编译器认为你现在在虚拟地址。
 就会出现转跳过远不让编译的警告。
 */

.text

.global _start
_start = V2P_WO(entry)

// 用于指引GDB, 让其能正确度过使用物理地址的那一小段
.global for_gdb_physical
for_gdb_physical = V2P_WO(for_gdb_virtual)

.global entry
// RISC-V体系结构不允许在text段中插入data段
// 为了更近一步复刻, 我从链接脚本中强行取出这个值来用
// 这是一种行为艺术, 并不推荐使用

/*
 为什么在链接脚本中,
 */

entry:
kpg:
    // 沿用过去的代码, 真的需要这样做吗?
    csrw    sie, zero
    csrci   sie, 0x1 << 1   //  关SIE
    li      t0, 0x0222
    csrs    sie, t0

    mv      tp, a0
    mv      s1, a1

setup_temporary_paging:
    // 我们先用task 0的第一级页表做内核的临时页表,
    // 临时是因为这个页表中同时做了物理的原地映射和虚拟的映射
    
    // risc-v不能用三个寄存器来处理存取
    // 所以只能使指针+8bytes

    /*
     i取小于20是因为VisionFive2开发板的外设最高是
     0x09_CFFF_FFFF, 要用20个2GiB来覆盖
     p = ipg2;
     for(int i = 0; i < 20; i++) {
        pte = i << 28;   //每2GiB
        pte = pte & 0x0f;
        n = i << 3;
        m = i + 256;
        m = m << 3;
        *(p+n) = pte;
        *(p+m) = pte;
     }
     */

    la      t0, ipg2
    addi    t1, t0, 512
1:  sd      zero, 0(t0)
    addi    t0, t0, 8
    blt     t1, s2, 1b
    

    la      t0, ipg2        // 页表基地址
    li      t1, 0
    li      s2, 4           //  临时给4, 方便调试
1:
    slli    t2, t1, 28      // t2 = pte
    ori     t2, t2, 0x0f
    
    slli    t3, t1, 3
    addi    t4, t1, 256
    slli    t4, t4, 3

    add     t3, t0, t3
    sd      t2, 0(t3)
    add     t4, t0, t4
    sd      t2, 0(t4)
    addi    t1, t1, 1
    blt     t1, s2, 1b

    //所有的地址加载都是pc相关
    //所以现在实际运行在物理地址加载出来的也都是物理实际地址
    //所以要手动加上偏移
//    la      sp, user_stack
//    li      t0, V_P_DIFF
//    add     sp, sp, t0

    csrr    t0, sstatus
    li      t1, 0x1 << 18   //  SUM
    or      t0, t0, t1
    csrw    sstatus, t0

    la      t0, ipg2
    srli    t0, t0, 12      //  右移, 空位填0
    li      t1, 0x8 << 60   //  8代表Sv39分页模式
    or      t0, t0, t1
    csrw    satp, t0        //  启动分页
    sfence.vma              //  刷新快表

    la      t4, kpg //  把物理地址的kpg放进t2

for_gdb_virtual:
    //  用于调试

    la      t0, after_page_tables
    li      t1, V_P_DIFF
    add     t0, t0, t1

    jr      t0

    

.align 12
ipg2:
.skip 4096

ipg1:
.skip 4096
//  有一个可以优化的点,
//  就是其实可以把after_page_tables放在这里
//  反正到用户态才会真正的用到小页表

ipg0:
.skip 4096

/*
 可能会有更多的, task 0的第三级页表。
 对于Linux0.12来说, 内核代码同时也是0号进程的代码。
 我们有以下逻辑:
 1. task 1和后面所有的进程将通过写时复制来获得自己的空间。
    所以, task 0在用户态中的映射必须用4KiB的页表。
 2. Linux中内核程序和task 0的代码和数据其实是同一份。
    由于Linux 0.12使用段为主的机制,
    只需要保证内核总代码小于16MiB。
 3. Sv39的三级页表只能保证2MiB
 所以要时刻紧盯整个内核代码的容量, 如果超过现有的页表能力, 就要添加。
 */

after_page_tables:
setup_paging:
    mv      t0, t4
    la      t2, ipg2
    mv      t1, zero
    li      s2, 256
1:  sd      zero, 0(t0)
    addi    t0, t0, 8
    addi    t2, t2, 8
    addi    t1, t1, 1
    blt     t1, s2, 1b

    li      s2, 512
1:  ld      t3, 0(t2)
    sd      t3, 0(t0)
    addi    t0, t0, 8
    addi    t2, t2, 8
    addi    t1, t1, 1
    blt     t1, s2, 1b

    srli    t0, t4, 12      //  右移, 空位填0
    li      t1, 0x8 << 60   //  8代表Sv39分页模式
    or      t0, t0, t1
    csrw    satp, t0        //  启动分页
    sfence.vma              //  刷新快表
    // 这个时候使用的才是去除原地映射真正的内核页表
    
    la      sp, user_stack
    li      t0, 0x1
    slli    t0, t0, 12
    add     sp, sp, t0
    addi    sp, sp, -24
    //  因为有空间用于scratch

    //  本不应该在此处设置内核栈sscratch,
    //  而应该在创建task 0响应数据结构的时候来处理
    //  但是为了handle trap就必须设置好sscratch
    csrw    sscratch, sp
    //  sscratch对于我们的系统是必须的
    //  它在模拟80386的硬件中断控制流程起到重要作用
    //  (同时也是它的设计用途)
    
    //  注意, 不是真的trap_vector
    //  只是沿用tvec的含义而已
    la      t0, trap_vector
    csrw    stvec, t0

    call main
1:  nop //永远不应该返回
    j       1b



//我们在asm.S和traps.c中详细介绍中断处理时究竟发生了什么
//int_msg:
//    .asciz "Unknown interrupt\n\r"
//.align 2
//ignore_int:
//    pushl %eax
//    pushl %ecx
//    pushl %edx
//    push %ds
//    push %es
//    push %fs
//    movl $0x10,%eax
//    mov %ax,%ds
//    mov %ax,%es
//    mov %ax,%fs
//    pushl $int_msg
//    call _printk
//    popl %eax
//    pop %fs
//    pop %es
//    pop %ds
//    popl %edx
//    popl %ecx
//    popl %eax
//    iret

