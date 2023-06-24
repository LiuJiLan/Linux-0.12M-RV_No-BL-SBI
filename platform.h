#ifndef platform_h
#define platform_h

#define V_P_DIFF    0xFFFFFFC000000000U

// 还是沿用xv6-riscv的宏
#define V2P(a) (((unsigned long) (a)) - V_P_DIFF)   //  64位下改了数据类型
#define P2V(a) ((void *)(((unsigned char *) (a)) + V_P_DIFF))

//  纯数值的转换
#define V2P_WO(x) ((x) - V_P_DIFF)    // same as V2P, but without casts //  不带类型转换
#define P2V_WO(x) ((x) + V_P_DIFF)    // same as P2V, but without casts


//  ### //
//  这块放置不同平台相关的数值
#define RAM_START   0x80000000UL    // QEMU的内存起点
#define RAM_SIZE    0x08000000UL    // 128MiB 比赛要求的QEMU大小为128M

//  由于要给qemu和vf2同时用,
//  vf2的0号核是没有S态的, 所以寄存器安排上我们只写启动核的
#define BOOT_HART_ID 0


//  注意给SBI的时钟中断间隔应该为
//  TIMEBASE_FREQUENCY / HZ
#define TIMEBASE_FREQUENCY 10000000UL
//#define TIMEBASE_FREQUENCY 4000000UL


#define PLIC                    0x0c000000UL
#define PLIC_V                  P2V_WO(PLIC)
//  这里的数量不要带上用于标识无中断的0号
#define NR_PLIC_SOURCE          53
#define BOOT_HART_PLIC_SCLAIM   PLIC_V + 0x201004UL + 0x2000UL

/* copy from xv6-k210
#define PLIC_PRIORITY           (PLIC_V + 0x0)
#define PLIC_PENDING            (PLIC_V + 0x1000)
#define PLIC_MENABLE(hart)      (PLIC_V + 0x2000 + (hart) * 0x100)
#define PLIC_SENABLE(hart)      (PLIC_V + 0x2080 + (hart) * 0x100)
#define PLIC_MPRIORITY(hart)    (PLIC_V + 0x200000 + (hart) * 0x2000)
#define PLIC_SPRIORITY(hart)    (PLIC_V + 0x201000 + (hart) * 0x2000)
#define PLIC_MCLAIM(hart)       (PLIC_V + 0x200004 + (hart) * 0x2000)
#define PLIC_SCLAIM(hart)       (PLIC_V + 0x201004 + (hart) * 0x2000)
 */

//  ### //

// 不再使用rCore的0xFFFFFFFF40000000U,
// 而是改用将0x0映射到Sv39高地址的最低值
// 注意, rCore内存映射示意图中的0xFFFFFF8000000000
// 为最低的高地址是错误的, 由于要求最高位扩展
// 虚拟地址L2段的最高必须要是1








// 我们把一些预处理的警告也放在这里
// 说实话我不知道该把他们放在哪
// 但是我希望我尽量不去改动Linux 0.12的结构
// 我发现这个警告也能让我很好的在Xcode中
// 不小心按到command+B时防止编译, :-)
// 但是它其实是用来防止用RV32编译的
#if __riscv_xlen != 64
#error "This code does not support situations other than RISC-V 64."
#endif

#define REGBYTES    8
#define REG_S       sd
#define REG_L       ld

//extern unsigned long LD_RAM_START
//#if LD_RAM_START != RAM_START
//#error "Link script conflicts with RAM START in platform!"
//#endif



#endif /* platform_h */
