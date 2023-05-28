# Linux-0.12M-RV_No-BL-SBI
Linux 0.12M for RISC-V architecture, without bootloader and SBI.



**开发过程中, 我会随意用方便的语言书写README, 完成后会重新整理出双语版本。**

*部分用词更多是为了记录开发, 我也实在没有精神去像写一个教程一样精挑细选用词了。所以, 如果有任何你觉得更好的表达, 可以联系我。*



# 介绍

This repository is a modified version of the Linux kernel 0.12 for the RISC-V architecture. The "RV" at the end of the name refers to the RISC-V architecture. The "M" in "0.12M" stands for "modified", reflecting the changes made to the original kernel to make it compatible with RISC-V architecture. Specifically, the original kernel uses a segment-based memory management mechanism, which is not present in the RISC-V hardware structure. "No-BL" represents "without bootloader," indicating that the code for bootloader is not included in this version of the kernel. Similarly, "No-SBI" indicates that the code for Supervisor Binary Interface is not included. At present, a pre-existing bootloader and SBI implementation are being used, and after the exams, there are plans to write a new implementation from scratch.

在本README后面的部分中, 我们将我们的系统称为RetroLinuxRV。



# 未实现功能



## 由于体系结构/硬件设备而未实现

- 数学协处理器
- 软盘驱动
  - 如果要上实体板子, 软盘驱动的主设备号可能留给SD卡
- SMP支持
  - Linux0.12没有用于处理多核的锁
  - 我也没时间折腾(如果有朋友感兴趣可以试试)
  - 改写代码中用于外部中断(PLIC)的部分是对启动核写死的, 如果改写要改为一个与启动核有关的函数(见我[RVOS在VF2上的移植](https://github.com/LiuJiLan/RVOS_On_VisionFive2))
  



## 由于时间紧未实现

- [ ] 硬件探查(bootsect和setup里部分实现了从BIOS获取参数, 而我们应该从dtb中获取, 能做到, 但没时间)
- [ ] RAMDISK



## 由于Linux 0.12的时代限制没有实现

- [ ] GPT分区表 (由于目标板子就已经使用了4个分区(MBR分区表的上限), 如果想单独开分区就只能使用GPT分区表), 暂时只做一个识别, 表示当前是否使用MBR分区/GPT分区
- [ ] 仅使用Minix文件系统, 在0.95(0.13)的VFS中来解决这个问题



# RetroLinuxRV的设计



# boot

在boot文件夹中我们舍去了bootsect.S和setup.S。

这两个文件分别负责设置从实模式到保护模式、将内核加载到正确的位置。

我们的内核一进入就处于S态, 不存在模式转换。加载工作也由其他部分实现。QEMU中由QEMU来实现(严谨的说是配合SBI一起实现), 目标的开发板VF2这一块则是由U-Boot来实现。总之, 由于我们不必再操心, 我也废弃了这两个文件。

## head.S

我们在head.S中放置了4个页表用的页(可能会更多)。代码部分看注释好了。

- [ ] 将注释转移到文档中来。



# kernel

## asm.S

在asm.S中我们做了两件事情:

1、对x86的“切换不同权级的栈”与“转跳到正确的中断向量”的硬件过程进行模拟, 由于代码实现的问题, 在软件的模拟结束后, 所有的trap应该注意: **`t1`与`t2`寄存器存在sscratch维护着的临时结构中, 任何接在这之后的操作都应该正确的将这两个值**; **跳转到`all_trap_return`返回**。

2、各种异常的处理的代码。

### x86中断硬件处理与RISC-V的对应

简单而言, Linux0.12的中断/异常处理的开始可以分成3个阶段: 

1、硬件地对栈进行处理, 并且保存部分需要的返回地址; 2、硬件地转跳到中断向量表中; 3、一些Linux的汇编语言。这些步骤完成后将转跳到C语言来处理。

对于RISC-V而言, trap的处理有几点不同。

首先, 即使使用中断向量表, 使用的形式也不同。80386的中断表若以表头为base, vector为index, 则转跳形式为`pc = base[vector] `; 而RISC-V中, 首先中断向量表是可选项(不是所有硬件都支持), 其次转跳形式为`pc = base + vector `; 最后RISC-V只有真正意义的中断能使用中断向量表(如果可选)。

对于中断的前处理, 我采取以下步骤: 1、软件地模拟对栈的选择; 2、软件的实现trap向量表; 3、Linux汇编语言部分做部分适配。

**注意: 我的做法为了防止大改导致牵一发而动全身, 代码的质量还有待静下来好好思考。**



### 对栈的选择

CLK-5.0中122页的文字描述与280页的图8-2。

我在此并不详细讨论LDT、GDT与其中存储的TSS的具体概念和关系。我只抽象出几个结论:1、TSS位于内存中, CPU能用某种方式硬件的定位、读/写TSS中的内容。2、不严谨地认为, Linux内核只使用了TSS的ESP0和I/O权限位。

- 权级不变时, 会向原栈中压入EFLAGS、CS、EIP。
- 权级改变时, 会向ESP0中压入原SS、原ESP、EFLAGS、CS、EIP。

以上步骤被硬件地发生。如果有阅读过openSBI源码, 应该能反应过来, RISC-V中用scratch(对于内核而言是sscratch)寄存器来做的一个置换操作。(EFLAG相当于xstatus寄存器; CS+EIP相当于xret寄存器; 原SS+ESP相当于sp; ESP0相当于xscratch)

在UnnamedOS中, 我借鉴openSBI的同时, 由于使用每个核仅一个内核栈的形式, 是把权级改变时的指针直接放在sscratch。这次重看openSBI的代码, 发现openSBI的代码有所改变。openSBI中使用了每HART一个的`sbi_scratch`空间来存储一些信息:

```c
struct sbi_scratch {
	/** Start (or base) address of firmware linked to OpenSBI library */
	unsigned long fw_start;
	/** Size (in bytes) of firmware linked to OpenSBI library */
	unsigned long fw_size;
	/** Offset (in bytes) of the R/W section */
	unsigned long fw_rw_offset;
	/** Arg1 (or 'a1' register) of next booting stage for this HART */
	unsigned long next_arg1;
	/** Address of next booting stage for this HART */
	unsigned long next_addr;
	/** Privilege mode of next booting stage for this HART */
	unsigned long next_mode;
	/** Warm boot entry point address for this HART */
	unsigned long warmboot_addr;
	/** Address of sbi_platform */
	unsigned long platform_addr;
	/** Address of HART ID to sbi_scratch conversion function */
	unsigned long hartid_to_scratch;
	/** Address of trap exit function */
	unsigned long trap_exit;
	/** Temporary storage */
	unsigned long tmp0;
	/** Options for OpenSBI library */
	unsigned long options;
};
```

但, 有无必要进行这种改进, 另说。



### 中断向量的实现

我考虑过几种方案: 1、`kernel_scratch`中保存更多的临时变量, 然后用纯汇编语言实现中断向量表的转跳; 2、寄存器压栈, C语言处理所有trap, 寄存器弹出, 实现中断向量的转跳。

这两个方案, 前者实现麻烦; 后者有一个问题, RISC-V并没有真的将数据压到栈中, 而是使用CSR寄存器硬件地保存了相应的值。而C语言依赖栈(sp), 如果trap本身与sp相关, 采用C语言做转跳将有陷入死循环的可能。

所以我打算采取结合这两者:

首先对于所有的trap先用汇编处理, 1、对于异常, 直接转跳到为异常(软件设置的)向量表; 2、对于中断, 分别处理: 2.1其中对于外部中断, 使用保存所有寄存器然后用C语言处理PLIC问题。2.2其他中断使用使用任然使用汇编处理。

对于PLIC的外部中断, 再给其分配一个与芯片PLIC能处理外设大小的中断向量表(这个值应该在platform.h中定义)。



### 有关Trap的一些区别

我们不严谨的简单说明:

我认为Linux 0.12区分了3种trap: 中断门、陷阱门和系统门。

|             | x86是否自动清除标志位? | x86保存的返回点 | RISC-V中对应 | RISC-V的返回点 |
| ----------- | ---------------------- | --------------- | ------------ | -------------- |
| intr_gate   | 是                     | 下一条指令      | 中断         | 下一条指令     |
| trap_gate   | 否                     | 基本都是原指令  | 异常         | 返回到当前指令 |
| system_gate | 否                     | 下一条指令      | 异常         | 返回到当前指令 |

在x86架构中，中断门、陷阱门和系统门是用于处理中断和异常的机制。它们都是在IDT（中断描述符表）中定义的门描述符。这些门的主要区别在于它们的行为和用途。

1. 中断门（Interrupt Gate）: 当发生中断时，处理器通过中断门转到中断处理程序。此时，处理器会自动清除EFLAGS寄存器中的IF（中断标志位），从而在中断处理期间禁止其他中断。
2. 陷阱门（Trap Gate）: 与中断门类似，陷阱门也用于处理中断和异常。不过，陷阱门在跳转到中断处理程序后并不会自动清除IF标志位，所以在陷阱门处理期间仍然可以响应其他中断。
3. 调用门（Call Gate，也称为系统门）: 这种门用于从较低的特权级跳转到较高的特权级，例如从用户模式（CPL 3）跳转到内核模式（CPL 0）。这种跳转通常用于系统调用。调用门并不会影响EFLAGS寄存器。

至于你提到的错误发生地址，一般来说，当中断或异常发生时，处理器会将错误发生的地址（也就是发生中断或异常的指令的地址）存储在一个特殊的寄存器（例如EIP）中。这样，中断处理程序可以知道哪条指令导致了中断或异常。然而，具体的行为可能会因中断或异常的类型而异。例如，在某些情况下（例如页面错误），处理器可能会存储下一条指令的地址，而不是导致错误的指令的地址。



### 中断中汇编的作用

Linux 0.12的asm.S文件中会保存所有的寄存器, 这是为了让后面的C语言能打印出信息。而中断与系统调用则不需要这样做, 他们只需要保存caller寄存器, cellee寄存器则由C语言本身保存。



## trap.c

施工中...



---



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



