# Linux-0.12M-RV_No-BL-SBI
Linux 0.12M for RISC-V architecture, without bootloader and SBI.



**开发过程中, 我会随意用方便的语言书写README, 完成后会重新整理出双语版本。**



# 介绍

This repository is a modified version of the Linux kernel 0.12 for the RISC-V architecture. The "RV" at the end of the name refers to the RISC-V architecture. The "M" in "0.12M" stands for "modified," reflecting the changes made to the original kernel to make it compatible with RISC-V architecture. Specifically, the original kernel uses a segment-based memory management mechanism, which is not present in the RISC-V hardware structure. "No-BL" represents "without bootloader," indicating that the code for bootloader is not included in this version of the kernel. Similarly, "No-SBI" indicates that the code for Supervisor Binary Interface is not included. At present, a pre-existing bootloader and SBI implementation are being used, and after the exams, there are plans to write a new implementation from scratch.
