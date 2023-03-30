# Linux-0.12M-RV_No-BL-SBI
Linux 0.12M for RISC-V architecture, without bootloader and SBI.



**开发过程中, 我会随意用方便的语言书写README, 完成后会重新整理出双语版本。**

*部分用词更多是为了记录开发, 我也实在没有精神去像写一个教程一样精挑细选用词了。所以, 如果有任何你觉得更好的表达, 可以联系我。*



# 介绍

This repository is a modified version of the Linux kernel 0.12 for the RISC-V architecture. The "RV" at the end of the name refers to the RISC-V architecture. The "M" in "0.12M" stands for "modified", reflecting the changes made to the original kernel to make it compatible with RISC-V architecture. Specifically, the original kernel uses a segment-based memory management mechanism, which is not present in the RISC-V hardware structure. "No-BL" represents "without bootloader," indicating that the code for bootloader is not included in this version of the kernel. Similarly, "No-SBI" indicates that the code for Supervisor Binary Interface is not included. At present, a pre-existing bootloader and SBI implementation are being used, and after the exams, there are plans to write a new implementation from scratch.



# x86 ISA相应问题



## 有关x86下内存地址空间的概念

在此处笔者我不讨论段选择符的具体使用。笔者习惯于将段选择符的概念与8086架构下的CS段寄存器做抽象的对应关系。

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

0.12版本中使用分段机制和分页机制共同管理内存(此处尤其关注用户态进程的内存)。在这种段页式内存管理的机制下, 系统将线性地址分为一个个16MiB的空间给进程。此过程同时使用了页表, 因为按照设计, 这个线性空间可以达到4GB(方便内核态管理寻址)。但当时实际的物理内存不超过16MB。

从 Linux 0.99 版本开始，内核逐渐放弃了段式内存管理，转而更多地依赖分页机制。此时, 分段机制仍然存在，但它们的作用主要是为了满足 x86 架构的要求，实现对分页内存模型的最低限度支持。



但是对x86 ISA而言, 无论使用哪种机制, 只是用户态进程能使用的空间发生了变化而已。内存管理上的变化对于书写用户态应用的程序员而言并无什么影响。因为他们只用关心逻辑地址。

在x86的ABI中, 也就是用户态程序员能接触的部分中, x86 ISA的指令指针由EIP寄存器管理。EIP寄存器存储了即将执行的下一条指令的地址。当一条指令执行完毕时，EIP会自动更新以指向下一条指令。

对于用户态程序而言, 他们所处的地址空间都是从0x0开始偏移的。(注意: 此处并不是想表示`.entry`位于0x0处)



综上所述, 由于x86 ISA的ABI中的指令指针(EIP)与CPU实际用于寻址的指令指针(分段机制与EIP共同作用)有所不同, 在移植0.12内核时必须对其中的进程内存管理机制进行大的改动。这也是本项目标题中M所代表的"modified"

所主要修改的部分。
