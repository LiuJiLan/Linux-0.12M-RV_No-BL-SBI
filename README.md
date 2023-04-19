# Linux-0.12M-RV_No-BL-SBI
Linux 0.12M for RISC-V architecture, without bootloader and SBI.



**开发过程中, 我会随意用方便的语言书写README, 完成后会重新整理出双语版本。**

*部分用词更多是为了记录开发, 我也实在没有精神去像写一个教程一样精挑细选用词了。所以, 如果有任何你觉得更好的表达, 可以联系我。*



# 介绍

This repository is a modified version of the Linux kernel 0.12 for the RISC-V architecture. The "RV" at the end of the name refers to the RISC-V architecture. The "M" in "0.12M" stands for "modified", reflecting the changes made to the original kernel to make it compatible with RISC-V architecture. Specifically, the original kernel uses a segment-based memory management mechanism, which is not present in the RISC-V hardware structure. "No-BL" represents "without bootloader," indicating that the code for bootloader is not included in this version of the kernel. Similarly, "No-SBI" indicates that the code for Supervisor Binary Interface is not included. At present, a pre-existing bootloader and SBI implementation are being used, and after the exams, there are plans to write a new implementation from scratch.

在本README后面的部分中, 我们将我们的系统称为RetroLinuxRV。



# x86 ISA相应问题



## 有关x86下内存地址空间的概念

在此处我不讨论段选择符的具体使用。我习惯于将段选择符的概念与8086架构下的CS段寄存器做抽象的对应关系。

下面我们就CLK-5.0中153页的内存地址相关概念进行个人理解的说明:

*如有错误请指出*

|                  x86中的称呼                   |    对应现代ISA的概念     |                             解释                             |
| :--------------------------------------------: | :----------------------: | :----------------------------------------------------------: |
|           虚拟地址(Virtual Address)            |    CPU用来寻址的地址     | 段机制与段内偏移共同确定一个地址; <br />个人觉得同“线性地址” |
|           逻辑地址(Logical Address)            | ABI使用的Program Counter |            段内偏移; <br />用户态程序员关注的地址            |
|            线性地址(Linear Address)            |    CPU用来寻址的地址     |              段机制与段内偏移共同确定一个地址;               |
| 线性地址(Linear Address)<br />(未使用分页机制) |         物理地址         |                   地址直接用于寻址物理地址                   |
|  线性地址(Linear Address)<br />(使用分页机制)  |         虚拟地址         |                地址经页表转换后映射为物理地址                |

x86移植到使用单寄存器管理“指令计数器”的ISA中一大困难就是, 后者没有分段系统(Segmentation System)的概念, 而往往只有分页系统(Paging System)的概念。

在x86的ABI中, 也就是用户态程序员能接触的部分中, x86 ISA的指令指针由EIP寄存器管理。EIP寄存器存储了即将执行的下一条指令的地址。当一条指令执行完毕时，EIP会自动更新以指向下一条指令。

0.12版本中使用分段机制和分页机制共同管理内存(此处尤其关注用户态进程的内存)。在这种段页式内存管理的机制下, 系统将线性地址分为一个个16MiB的空间给进程。此过程同时使用了页表, 因为按照设计, 这个线性空间可以达到4GiB(方便内核态管理寻址)。但当时实际的物理内存不超过16MiB。

从 Linux 0.99 版本开始，内核逐渐放弃了段式内存管理，转而更多地依赖分页机制。此时, 分段机制仍然存在，但它们的作用主要是为了满足 x86 架构的要求，实现对分页内存模型的最低限度支持。



但是对x86 ISA而言, 无论使用哪种机制, 只是用户态进程能使用的空间发生了变化而已。内存管理上的变化对于书写用户态应用的程序员而言并无什么影响。因为他们只用关心逻辑地址。

在x86的ABI中, 也就是用户态程序员能接触的部分中, x86 ISA的指令指针由EIP寄存器管理。EIP寄存器存储了即将执行的下一条指令的地址。当一条指令执行完毕时，EIP会自动更新以指向下一条指令。

对于用户态程序而言, 他们所处的地址空间都是从0x0开始偏移的。(注意: 此处并不是想表示`.entry`位于0x0处)



综上所述, 由于x86 ISA的ABI中的指令指针(EIP)与CPU实际用于寻址的指令指针(分段机制与EIP共同作用)有所不同, 在移植0.12内核时必须对其中的进程内存管理机制进行大的改动。这也是本项目标题中M所代表的"modified"所主要修改的部分。



## x86中断硬件处理与RISC-V的对应

CLK-5.0中122页的文字描述与280页的图8-2。

我在此并不详细讨论LDT、GDT与其中存储的TSS的具体概念和关系。我只抽象出几个结论:1、TSS位于内存中, CPU能用某种方式硬件的定位、读/写TSS中的内容。2、不严谨地认为, Linux内核只使用了TSS的ESP0和I/O权限位。

- 权级不变时, 会向原栈中压入EFLAGS、CS、EIP。



# RetroLinuxRV的设计



## 内存管理

1. 首先是内存管理模型:

   虽说Linux 0.12中的内存管理模式被称为段页式。但其本质上是以段机制为主, 页表为辅的形式。我们可以从每个进程都拥有其各自私有的段管理结构, 而共用一份页表可以看出这一点。
   所以, 在Linux 0.12中Copy-On-Write机制的实现的时候, 使用的参数是与两进程的线性地址。

   由于我们的RetroLinuxRV是RISC-V体系结构, 没有分段机制。所以我们的设计是, 每个进程都拥有自己的页表(虚拟地址最高位为0部分为私有)。

2. 物理内存的情况

   Linux 0.12中物理内存前1MiB的部分详见CLK-5.0中22页的文字描述与280页的图2-4。

   这段内存在Linux 0.12中是特殊处理的, 在代码中被标注为`LOW_MEM`, 在内存管理代码中有很多例子, 例:

   ```c
   void free_page(unsigned long addr)
   {
   	if (addr < LOW_MEM) return;
   	if (addr >= HIGH_MEMORY)
   		panic("trying to free nonexistent page");
   	addr -= LOW_MEM;
   	addr >>= 12;
   	if (mem_map[addr]--) return;
   	mem_map[addr]=0;
   	panic("trying to free free page");
   }
   ```

   在RISC-V体系结构下, 物理内存一般不是从0x0处起始的。同时, 物理内存的前2MiB用于存放M态的运行时SBI。

   对于我们之后想要支持的目标板的8GiB, 如果采用Linux0.12的管理模式, 需要约2MiB的内存用于管理。而其启动分区仅有100M, 我们需要这个地方的处理。但早期我们只考虑qemu的默认内存大小, 倒是无需担心这一点。

3. 页表设置

   之前提到了Linux0.12只有一份页表, 而且它处于内存的最前端(0x0)。在代码中默认设置了1份页表目录与4份页表, 用于管理16MiB的内存。

   这个页表是所有内核和进程都可以使用的页表。

   为了方便管理, RetroLinuxRV中我们打算采用的设计是, 内核位于高虚拟地址空间, 进程位于低地址空间。由于Sv39页表要求, 64位的虚拟地址中的最高几位要求同为0或1。即: 0-512GiB处是进程空间, 高地址的最小值为0xFFFFFF80_00000000。有关内核的整体偏移, 我们将参考我上一个系统的整体偏移量。

   除此之外, 由于Linux使用的部分页表是静态设置的, 我也会在内核运行地址的最前端设置1页大小的一份页表。出于尽量小的改动Linux 0.12的想法, 内核使用的页表将会使用大页表的形式存在。这是由于 Linux 0.12中: 每个表项占4Bytes, 4KiB的页可以管理4MiB的空间; 而Sv39中, 每个表项占8Bytes, 4KiB的页仅可以管理2MiB的空间。(对于这个问题的解决方案是先使用临时页表, 再动态管理, 就像xv6-riscv那样, 但是为了尽量小的改动, 直接用大页来映射)而采用大页方案, Sv39中的表项, 最大可以映射2GiB的空间。同时由于RISC-V允许大小页同时存在, 我们也可以放心的在进程页表中同时使两者并存。

   总的而言, 内核页表的设计只是为了让进程能找到S态的内核而已。

