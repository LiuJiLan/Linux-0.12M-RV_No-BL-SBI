#include <../platform.h>

.text

.global _start
_start = V2P_WO(entry)

// 用于指引GDB, 让其能正确度过使用物理地址的那一小段
.global for_gdb_physical
for_gdb_physical = V2P_WO(for_gdb_virtual)

.global entry
entry:
    // 沿用过去的代码, 真的需要这样做吗?
    csrw    sie, zero
    csrci   sie, 0x1 << 1   //  关SIE
    li      t0, 0x0222
    csrs    sie, t0

