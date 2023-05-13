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

.align 12
.extern ipg2 // ipg2:
.skip 4096

.extern ipg1 // ipg1:
.skip 4096

.extern ipg0 // ipg0:
.skip 4096

after_page_tables:
//先死循环
    nop
    j after_page_tables

