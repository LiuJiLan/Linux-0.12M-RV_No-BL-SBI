#include <arch/types.h>
#include <asm/system.h>
#include <linux/config.h>
#include <debug.h>

size_t clint_vec[16];   //  core interrupt from CLINT
size_t except_vec[16];  //  exceptions
//+1表示用于无中断的0号
//0号也作为数组中一个可以加载的函数
size_t plic_vec[NR_PLIC_SOURCE+1];

//  Linux 0.12的错误处理中要保存所有的寄存器
//  为了让错误处理程序能打印出错误
struct trap_regs {
    size_t ra;
    size_t sp;
    size_t gp;
    size_t tp;
    size_t t0;
    size_t t1;
    size_t t2;
    size_t s0;
    size_t s1;
    size_t a0;
    size_t a1;
    size_t a2;
    size_t a3;
    size_t a4;
    size_t a5;
    size_t a6;
    size_t a7;
    size_t s2;
    size_t s3;
    size_t s4;
    size_t s5;
    size_t s6;
    size_t s7;
    size_t s8;
    size_t s9;
    size_t s10;
    size_t s11;
    size_t t3;
    size_t t4;
    size_t t5;
    size_t t6;
    size_t sstatus;
    size_t sepc;
    size_t scause;
    size_t stval;
};

void default_trap_handler(void);

void do_bad_CLINT_trap(struct trap_regs * sp) {
    //  要使用0x1UL, 否则会产生警告
    // printk("Should happen from CLINT ")
    size_t musk = 0x1UL << (sizeof(size_t)*8-1);
    if (sp->scause & musk) {    //  中断
        gdb_print("Impossible trap from CLINT.");
    } else {
        sp->sepc += 4;
    }
}

void do_default_trap_handler(struct trap_regs * sp) {
    //  要使用0x1UL, 否则会产生警告
    size_t musk = 0x1UL << (sizeof(size_t)*8-1);
    if (sp->scause & musk) {    //  中断
        //printf("");
    } else {
        sp->sepc += 4;
    }
}

void set(int n, size_t* addr){
    clint_vec[n] = (size_t)addr;
}

void trap_init(void) {
    int i;
    
    for (i = 0; i < 16; i++) {
        set_clint_vec(i, &do_bad_CLINT_trap);
    }
    //时钟中断与核间中断, 其他不可能发生或已提前转跳(外部中断)
    set_clint_vec(1, &default_trap_handler);
    //set_clint_vec(5, &do_bad_CLINT_trap);
    for (i = 0; i < 16; i++) {
        set_except_vec(i, &default_trap_handler);
    }
}

