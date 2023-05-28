#include <arch/types.h>
#include <linux/mm.h>   //  被放在<linux/sched.h>里
#include <asm/system.h>
#include <linux/config.h>
#include <debug.h>

// 临时放置在这里
extern void trap_init(void);
extern void mem_init(size_t start_mem, size_t end_mem);
extern void blk_dev_init(void);
extern void chr_dev_init(void);


// 注意, 我们用这种方式完成了64bits的对齐
// 不要使用uint8 user_stack[PAGE_SIZE]来替代
// 另外, 如果非gcc编译器以及编译优化后是不保证对齐的
// Linux 0.12中是PAGE_SIZE>>2, 注意是保证4KiB大小
size_t user_stack [ PAGE_SIZE>>3 ] ;

//  都使用物理地址
static size_t memory_start = 0;
static size_t memory_end = 0;
static size_t buffer_memory_end = 0;
static size_t main_memory_start = 0;

// ssize_t hartid, ssize_t dtb_addr
int main(void){
    memory_start = RAM_START;
    memory_end = RAM_START + RAM_SIZE;
    //  起点+SBI+4MiB
    buffer_memory_end = RAM_START + (2UL << 20) + (8UL << 20);
    main_memory_start = buffer_memory_end;

//  我们的系统暂不支持RAMDISK, 不要使用RAMDISK编译参数!!!
#ifdef RAMDISK
    main_memory_start += rd_init(main_memory_start, RAMDISK*1024);
#endif
    mem_init(main_memory_start,memory_end);
    trap_init();
    blk_dev_init();
    chr_dev_init();
    ebreak();
    ebreak();
    reach_here("About to spin!");
    while (1) {
        
    }
}
