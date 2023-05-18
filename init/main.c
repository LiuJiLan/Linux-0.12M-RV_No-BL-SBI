#include <arch/types.h>

#include <asm/system.h>

// 临时放置在这里
extern void trap_init(void);

// 临时使用
#define PAGE_SIZE PGSIZE
// 注意, 我们用这种方式完成了64bits的对齐
// 不要使用uint8 user_stack[PAGE_SIZE]来替代
// 另外, 如果非gcc编译器以及编译优化后是不保证对齐的
// Linux 0.12中是PAGE_SIZE>>2, 注意是保证4KiB大小
size_t user_stack [ PAGE_SIZE>>3 ] ;

// ssize_t hartid, ssize_t dtb_addr
int main(void){
    trap_init();
    ebreak();
    while (1) {
        
    }
}
