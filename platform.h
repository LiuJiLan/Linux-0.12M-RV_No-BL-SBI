#ifndef platform_h
#define platform_h

#define RAM_START   0x80000000UL    // QEMU的内存起点
#define RAM_SIZE    0x08000000UL    // 比赛要求的QEMU大小为128M

// 不再使用rCore的0xFFFFFFFF40000000U,
// 而是改用将0x0映射到Sv39高地址的最低值
// 注意, rCore内存映射示意图中的0xFFFFFF8000000000
// 为最低的高地址是错误的, 由于要求最高位扩展
// 虚拟地址L2段的最高必须要是1
#define V_P_DIFF    0xFFFFFFC000000000U


// 还是沿用xv6-riscv的宏
#define V2P(a) (((unsigned long) (a)) - V_P_DIFF)   //  64位下改了数据类型
#define P2V(a) ((void *)(((unsigned char *) (a)) + V_P_DIFF))

//  纯数值的转换
#define V2P_WO(x) ((x) - V_P_DIFF)    // same as V2P, but without casts //  不带类型转换
#define P2V_WO(x) ((x) + V_P_DIFF)    // same as P2V, but without casts


// 我们把一些预处理的警告也放在这里
// 说实话我不知道该把他们放在哪
// 但是我希望我尽量不去改动Linux 0.12的结构
#if __riscv_xlen != 64
#error "This code does not support situations other than RISC-V 64."
#endif

#define REGBYTES 8
#define REG_S       sd
#define REG_L       ld

//extern unsigned long LD_RAM_START
//#if LD_RAM_START != RAM_START
//#error "Link script conflicts with RAM START in platfrom!"
//#endif



#endif /* platform_h */
