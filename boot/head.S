//

#include "../platform.h"

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
.extern kpg // kpg:
entry:
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
        pa = i << 29;
        pte = pa & 0xcf;
        q = p << 3;
        w = p + q;
        *w = pte;
        w = w + 256;
        *w = pte;
     }
     */

    la      t0, kpg     // 页表基地址
    li      t1, 0xcf    // 表项标志位
    li      t2, 0x0     // 物理原地映射的表项
    li      t3, 256     // 虚拟映射到物理的表项
    sd
    

    

    //所有的地址加载都是pc相关
    //所以现在实际运行在物理地址加载出来的也都是物理实际地址
    //所以要手动加上偏移
    la      sp, user_stack
    li      t0, V_P_DIFF
    add     sp, sp, t0
    
    la      t1, test

    j       after_page_tables

    

    

.align 12
.extern ipg2 // ipg2:
.skip 4096

.extern ipg1 // ipg1:
.skip 4096

.extern ipg0 // ipg0:
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
//先死循环
    nop
    //.extern main
    j main


